package com.example.beacon

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.wifi.WpsInfo
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pDeviceList
import android.net.wifi.p2p.WifiP2pInfo
import android.net.wifi.p2p.WifiP2pManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.PrintWriter
import kotlinx.coroutines.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.beacon/wifi_direct"
    private var methodChannel: MethodChannel? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    
    private var manager: WifiP2pManager? = null
    private var channel: WifiP2pManager.Channel? = null
    private var receiver: BroadcastReceiver? = null
    private var intentFilter: IntentFilter? = null
    
    private val REQUEST_PERMISSIONS = 1
    private val requiredPermissions: Array<String> = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        arrayOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_WIFI_STATE,
            Manifest.permission.CHANGE_WIFI_STATE,
            Manifest.permission.NEARBY_WIFI_DEVICES
        )
    } else {
        arrayOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_WIFI_STATE,
            Manifest.permission.CHANGE_WIFI_STATE
        )
    }
    
    private var isDiscovering = false
    private var discoveredPeers = mutableListOf<WifiP2pDevice>()
    private var connectedDevice: WifiP2pDevice? = null
    private var groupOwnerAddress: InetAddress? = null
    private var isGroupOwner = false
    
    // Socket communication
    private val SERVER_PORT = 8888
    private var serverSocket: ServerSocket? = null
    private var clientSocket: Socket? = null
    private var serverJob: Job? = null
    private var clientReaderJob: Job? = null
    private var printWriter: PrintWriter? = null
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    initializeWifiDirect(result)
                }
                "startDiscovery" -> {
                    startDiscovery(result)
                }
                "stopDiscovery" -> {
                    stopDiscovery(result)
                }
                "connectToPeer" -> {
                    val deviceAddress = call.argument<String>("deviceAddress")
                    if (deviceAddress != null) {
                        connectToPeer(deviceAddress, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Device address is required", null)
                    }
                }
                "disconnect" -> {
                    disconnect(result)
                }
                "getDiscoveredPeers" -> {
                    getDiscoveredPeers(result)
                }
                "isWifiDirectSupported" -> {
                    result.success(isWifiDirectSupported())
                }
                "startSocketServer" -> {
                    startSocketServer(result)
                }
                "connectToSocket" -> {
                    val address = call.argument<String>("address")
                    if (address != null) {
                        connectToSocket(address, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Address is required", null)
                    }
                }
                "sendMessage" -> {
                    val message = call.argument<String>("message")
                    if (message != null) {
                        sendMessage(message, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Message is required", null)
                    }
                }
                "stopSocketCommunication" -> {
                    stopSocketCommunication(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestPermissions()
    }

    private fun requestPermissions() {
        val permissionsToRequest = requiredPermissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        
        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                permissionsToRequest.toTypedArray(),
                REQUEST_PERMISSIONS
            )
        }
    }

    private fun initializeWifiDirect(result: MethodChannel.Result) {
        try {
            manager = getSystemService(Context.WIFI_P2P_SERVICE) as? WifiP2pManager
            if (manager == null) {
                result.error("NOT_SUPPORTED", "WiFi Direct is not supported on this device", null)
                return
            }
            
            channel = manager?.initialize(this, mainLooper, null)
            
            intentFilter = IntentFilter().apply {
                addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
                addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
                addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
                addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)
            }
            
            receiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    when (intent?.action) {
                        WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION -> {
                            val state = intent.getIntExtra(WifiP2pManager.EXTRA_WIFI_STATE, -1)
                            val isEnabled = state == WifiP2pManager.WIFI_P2P_STATE_ENABLED
                            sendEventToFlutter("wifiStateChanged", mapOf("enabled" to isEnabled))
                        }
                        WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> {
                            requestPeers()
                        }
                        WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
                            val networkInfo = intent.getParcelableExtra<android.net.NetworkInfo>(
                                WifiP2pManager.EXTRA_NETWORK_INFO
                            )
                            val wifiP2pInfo = intent.getParcelableExtra<WifiP2pInfo>(
                                WifiP2pManager.EXTRA_WIFI_P2P_INFO
                            )
                            
                            if (networkInfo?.isConnected == true && wifiP2pInfo != null) {
                                groupOwnerAddress = wifiP2pInfo.groupOwnerAddress
                                isGroupOwner = wifiP2pInfo.isGroupOwner
                                
                                // Request connection info to get peer device details
                                manager?.requestConnectionInfo(channel) { info ->
                                    sendEventToFlutter("connectionChanged", mapOf(
                                        "connected" to true,
                                        "isGroupOwner" to info.isGroupOwner,
                                        "groupOwnerAddress" to (info.groupOwnerAddress?.hostAddress ?: ""),
                                        "peerDeviceAddress" to (connectedDevice?.deviceAddress ?: "")
                                    ))
                                }
                                
                                // Also send connection info event
                                sendEventToFlutter("connectionInfo", mapOf(
                                    "isGroupOwner" to wifiP2pInfo.isGroupOwner,
                                    "groupOwnerAddress" to (wifiP2pInfo.groupOwnerAddress?.hostAddress ?: "")
                                ))
                                
                                // Request peers to update their connection status
                                requestPeers()
                                
                                // Start socket communication after a short delay to ensure network is ready
                                scope.launch {
                                    delay(1000) // Wait 1 second for network to be ready
                                    if (isGroupOwner) {
                                        // Group owner starts server
                                        startSocketServer(null)
                                    } else {
                                        // Client connects to group owner
                                        val goAddress = wifiP2pInfo.groupOwnerAddress?.hostAddress
                                        if (goAddress != null) {
                                            connectToSocket(goAddress, null)
                                        }
                                    }
                                }
                            } else {
                                stopSocketCommunication(null)
                                sendEventToFlutter("connectionChanged", mapOf("connected" to false))
                                // Request peers after disconnection to update their status
                                requestPeers()
                            }
                        }
                        WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION -> {
                            val device = intent.getParcelableExtra<WifiP2pDevice>(
                                WifiP2pManager.EXTRA_WIFI_P2P_DEVICE
                            )
                            device?.let {
                                sendEventToFlutter("thisDeviceChanged", deviceToMap(it))
                            }
                        }
                    }
                }
            }
            
            registerReceiver(receiver, intentFilter)
            result.success(true)
        } catch (e: Exception) {
            Log.e("WiFiDirect", "Error initializing WiFi Direct", e)
            result.error("INIT_ERROR", e.message, null)
        }
    }

    private fun startDiscovery(result: MethodChannel.Result) {
        if (manager == null || channel == null) {
            result.error("NOT_INITIALIZED", "WiFi Direct not initialized", null)
            return
        }
        
        if (isDiscovering) {
            result.success(true)
            return
        }
        
        if (hasPermissions()) {
            manager?.discoverPeers(channel, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    isDiscovering = true
                    result.success(true)
                    sendEventToFlutter("discoveryStarted", emptyMap())
                }
                
                override fun onFailure(reason: Int) {
                    result.error("DISCOVERY_FAILED", "Failed to start discovery: $reason", null)
                }
            })
        } else {
            result.error("PERMISSION_DENIED", "Location permissions required", null)
        }
    }

    private fun stopDiscovery(result: MethodChannel.Result) {
        if (manager == null || channel == null) {
            result.error("NOT_INITIALIZED", "WiFi Direct not initialized", null)
            return
        }
        
        manager?.stopPeerDiscovery(channel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                isDiscovering = false
                result.success(true)
                sendEventToFlutter("discoveryStopped", emptyMap())
            }
            
            override fun onFailure(reason: Int) {
                isDiscovering = false
                result.error("STOP_DISCOVERY_FAILED", "Failed to stop discovery: $reason", null)
            }
        })
    }

    private fun requestPeers() {
        if (manager == null || channel == null || !hasPermissions()) return
        
        manager?.requestPeers(channel) { peers: WifiP2pDeviceList? ->
            peers?.deviceList?.let { deviceList ->
                discoveredPeers.clear()
                discoveredPeers.addAll(deviceList)
                
                val peersList = deviceList.map { deviceToMap(it) }
                sendEventToFlutter("peersUpdated", mapOf("peers" to peersList))
            }
        }
    }

    private fun connectToPeer(deviceAddress: String, result: MethodChannel.Result) {
        if (manager == null || channel == null) {
            result.error("NOT_INITIALIZED", "WiFi Direct not initialized", null)
            return
        }
        
        val device = discoveredPeers.find { it.deviceAddress == deviceAddress }
        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "Device not found in discovered peers", null)
            return
        }
        
        val config = WifiP2pConfig().apply {
            this.deviceAddress = deviceAddress
            wps.setup = WpsInfo.PBC
        }
        
        if (hasPermissions()) {
            manager?.connect(channel, config, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    connectedDevice = device
                    result.success(true)
                    sendEventToFlutter("connectionInitiated", deviceToMap(device))
                }
                
                override fun onFailure(reason: Int) {
                    result.error("CONNECTION_FAILED", "Failed to connect: $reason", null)
                }
            })
        } else {
            result.error("PERMISSION_DENIED", "Location permissions required", null)
        }
    }

    private fun disconnect(result: MethodChannel.Result) {
        if (manager == null || channel == null) {
            result.error("NOT_INITIALIZED", "WiFi Direct not initialized", null)
            return
        }
        
        manager?.removeGroup(channel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                connectedDevice = null
                groupOwnerAddress = null
                result.success(true)
                sendEventToFlutter("disconnected", emptyMap())
            }
            
            override fun onFailure(reason: Int) {
                result.error("DISCONNECT_FAILED", "Failed to disconnect: $reason", null)
            }
        })
    }

    private fun getDiscoveredPeers(result: MethodChannel.Result) {
        val peersList = discoveredPeers.map { deviceToMap(it) }
        result.success(peersList)
    }

    private fun isWifiDirectSupported(): Boolean {
        return packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI_DIRECT)
    }

    private fun deviceToMap(device: WifiP2pDevice): Map<String, Any> {
        return mapOf(
            "deviceAddress" to (device.deviceAddress ?: ""),
            "deviceName" to (device.deviceName ?: "Unknown"),
            "status" to getDeviceStatus(device.status),
            "isServiceDiscoveryCapable" to device.isServiceDiscoveryCapable,
            "primaryDeviceType" to (device.primaryDeviceType ?: ""),
            "secondaryDeviceType" to (device.secondaryDeviceType ?: "")
        )
    }

    private fun getDeviceStatus(status: Int): String {
        return when (status) {
            WifiP2pDevice.AVAILABLE -> "Available"
            WifiP2pDevice.INVITED -> "Invited"
            WifiP2pDevice.CONNECTED -> "Connected"
            WifiP2pDevice.FAILED -> "Failed"
            WifiP2pDevice.UNAVAILABLE -> "Unavailable"
            else -> "Unknown"
        }
    }

    private fun hasPermissions(): Boolean {
        return requiredPermissions.all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun sendEventToFlutter(event: String, data: Map<String, Any>) {
        mainHandler.post {
            methodChannel?.invokeMethod("onEvent", mapOf("event" to event, "data" to data))
        }
    }

    private fun startSocketServer(result: MethodChannel.Result?) {
        if (serverSocket != null) {
            Log.d("WiFiDirect", "Socket server already running, sending connected event")
            sendEventToFlutter("socketConnected", emptyMap())
            result?.success(true)
            return
        }
        
        serverJob = scope.launch {
            try {
                serverSocket = ServerSocket(SERVER_PORT)
                Log.d("WiFiDirect", "Socket server started on port $SERVER_PORT")
                sendEventToFlutter("socketConnected", emptyMap())
                result?.success(true)
                
                while (serverSocket != null && !serverSocket!!.isClosed) {
                    try {
                        val client = serverSocket!!.accept()
                        Log.d("WiFiDirect", "Client connected: ${client.remoteSocketAddress}")
                        
                        // Handle client connection
                        launch {
                            handleClientConnection(client)
                        }
                    } catch (e: Exception) {
                        if (!serverSocket!!.isClosed) {
                            Log.e("WiFiDirect", "Error accepting client", e)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e("WiFiDirect", "Error starting socket server", e)
                sendEventToFlutter("socketDisconnected", emptyMap())
                result?.error("SERVER_ERROR", e.message, null)
            }
        }
    }

    private fun handleClientConnection(client: Socket) {
        try {
            val reader = BufferedReader(InputStreamReader(client.getInputStream()))
            val writer = PrintWriter(client.getOutputStream(), true)
            
            // Store writer for sending messages
            printWriter = writer
            
            // Read messages from client
            clientReaderJob = scope.launch {
                try {
                    var line: String?
                    while (reader.readLine().also { line = it } != null) {
                        line?.let { message ->
                            Log.d("WiFiDirect", "Received message: $message")
                            sendEventToFlutter("messageReceived", mapOf(
                                "message" to message,
                                "sender" to client.remoteSocketAddress.toString()
                            ))
                        }
                    }
                } catch (e: Exception) {
                    Log.e("WiFiDirect", "Error reading from client", e)
                } finally {
                    client.close()
                    printWriter = null
                }
            }
        } catch (e: Exception) {
            Log.e("WiFiDirect", "Error handling client connection", e)
            client.close()
        }
    }

    private fun connectToSocket(address: String, result: MethodChannel.Result?) {
        if (clientSocket != null && clientSocket!!.isConnected) {
            Log.d("WiFiDirect", "Client socket already connected, sending connected event")
            sendEventToFlutter("socketConnected", emptyMap())
            result?.success(true)
            return
        }
        
        scope.launch {
            try {
                Log.d("WiFiDirect", "Attempting to connect to $address:$SERVER_PORT")
                clientSocket = Socket(address, SERVER_PORT)
                val writer = PrintWriter(clientSocket!!.getOutputStream(), true)
                val reader = BufferedReader(InputStreamReader(clientSocket!!.getInputStream()))
                
                printWriter = writer
                Log.d("WiFiDirect", "Connected to server at $address:$SERVER_PORT")
                sendEventToFlutter("socketConnected", emptyMap())
                result?.success(true)
                
                // Read messages from server
                clientReaderJob = launch {
                    try {
                        var line: String?
                        while (reader.readLine().also { line = it } != null) {
                            line?.let { message ->
                                Log.d("WiFiDirect", "Received message: $message")
                                sendEventToFlutter("messageReceived", mapOf(
                                    "message" to message,
                                    "sender" to address
                                ))
                            }
                        }
                    } catch (e: Exception) {
                        Log.e("WiFiDirect", "Error reading from server", e)
                    } finally {
                        clientSocket?.close()
                        clientSocket = null
                        printWriter = null
                        withContext(Dispatchers.Main) {
                            sendEventToFlutter("socketDisconnected", emptyMap())
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e("WiFiDirect", "Error connecting to socket", e)
                withContext(Dispatchers.Main) {
                    sendEventToFlutter("socketDisconnected", emptyMap())
                }
                result?.error("CONNECTION_ERROR", e.message, null)
            }
        }
    }

    private fun sendMessage(message: String, result: MethodChannel.Result?) {
        scope.launch {
            try {
                val writer = printWriter
                if (writer != null) {
                    writer.println(message)
                    writer.flush()
                    Log.d("WiFiDirect", "Message sent: $message")
                    result?.success(true)
                } else {
                    Log.e("WiFiDirect", "Writer is null, socket not connected")
                    result?.error("NOT_CONNECTED", "Socket not connected", null)
                }
            } catch (e: Exception) {
                Log.e("WiFiDirect", "Error sending message", e)
                result?.error("SEND_ERROR", e.message, null)
            }
        }
    }

    private fun stopSocketCommunication(result: MethodChannel.Result?) {
        scope.launch {
            try {
                serverJob?.cancel()
                clientReaderJob?.cancel()
                
                printWriter?.close()
                printWriter = null
                
                serverSocket?.close()
                serverSocket = null
                
                clientSocket?.close()
                clientSocket = null
                
                Log.d("WiFiDirect", "Socket communication stopped")
                sendEventToFlutter("socketDisconnected", emptyMap())
                result?.success(true)
            } catch (e: Exception) {
                Log.e("WiFiDirect", "Error stopping socket communication", e)
                result?.error("STOP_ERROR", e.message, null)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        receiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: Exception) {
                Log.e("WiFiDirect", "Error unregistering receiver", e)
            }
        }
        stopSocketCommunication(null)
        scope.cancel()
    }
}
