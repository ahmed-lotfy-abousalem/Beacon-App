import 'dart:async';

import '../data/models.dart';
import 'wifi_direct_service.dart';

/// Peer-to-peer service that uses WiFi Direct for device discovery and communication.
/// This service integrates with the native WiFi Direct implementation to discover
/// and connect to nearby devices without requiring internet connectivity.
class P2PService {
  final WiFiDirectService _wifiDirectService = WiFiDirectService();
  final _peersController = StreamController<List<ConnectedDevice>>.broadcast();

  StreamSubscription<WiFiDirectEvent>? _eventSubscription;
  List<ConnectedDevice> _currentPeers = [];
  bool _isInitialized = false;
  String? _connectedDeviceAddress;
  bool _isConnected = false;

  Stream<List<ConnectedDevice>> get peersStream => _peersController.stream;

  bool get isDiscovering => _wifiDirectService.isDiscovering;

  /// Initialize WiFi Direct and set up event listeners
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Check if WiFi Direct is supported
    final isSupported = await _wifiDirectService.isSupported();
    if (!isSupported) {
      print('WiFi Direct is not supported on this device');
      return;
    }
    
    // Initialize the service
    final initialized = await _wifiDirectService.initialize();
    if (!initialized) {
      print('Failed to initialize WiFi Direct');
      return;
    }
    
    // Listen to WiFi Direct events
    _eventSubscription = _wifiDirectService.eventStream.listen(_handleWiFiDirectEvent);
    
    _isInitialized = true;
  }

  /// Starts WiFi Direct peer discovery
  Future<void> startDiscovery() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (!_isInitialized) {
      print('Cannot start discovery: WiFi Direct not initialized');
      return;
    }
    
    await _wifiDirectService.startDiscovery();
    
    // Also periodically refresh the peer list
    _refreshPeersPeriodically();
  }

  /// Stops WiFi Direct peer discovery
  Future<void> stopDiscovery() async {
    await _wifiDirectService.stopDiscovery();
    _currentPeers = [];
    _peersController.add(_currentPeers);
  }

  /// Connect to a peer device
  Future<bool> connectToPeer(String deviceAddress) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    return await _wifiDirectService.connectToPeer(deviceAddress);
  }

  /// Disconnect from current peer
  Future<bool> disconnect() async {
    return await _wifiDirectService.disconnect();
  }

  /// Handle WiFi Direct events from native side
  void _handleWiFiDirectEvent(WiFiDirectEvent event) {
    switch (event.type) {
      case 'peersUpdated':
        _handlePeersUpdated(event.data);
        break;
      case 'connectionChanged':
        _handleConnectionChanged(event.data);
        break;
      case 'connectionInfo':
        // Additional connection info update
        _handleConnectionChanged(event.data);
        break;
      case 'discoveryStarted':
        print('WiFi Direct discovery started');
        break;
      case 'discoveryStopped':
        print('WiFi Direct discovery stopped');
        break;
      case 'wifiStateChanged':
        final enabled = event.data['enabled'] as bool? ?? false;
        if (!enabled) {
          print('WiFi Direct is disabled');
        }
        break;
      case 'socketConnected':
        print('Socket connection ready for messaging');
        break;
      case 'socketDisconnected':
        print('Socket connection closed');
        break;
      case 'thisDeviceChanged':
        // Device info changed, can be ignored
        break;
      case 'messageReceived':
        // Message received - this is handled by MessagingService
        // Just log it here for awareness
        final message = event.data['message'] as String? ?? '';
        print('Message received in P2P Service: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');
        break;
      default:
        print('Unknown WiFi Direct event: ${event.type}');
    }
  }

  /// Handle peer list updates
  void _handlePeersUpdated(Map<String, dynamic> data) {
    final peersList = data['peers'] as List<dynamic>?;
    if (peersList == null) return;
    
    final now = DateTime.now();
    final discoveredPeers = peersList.map((peerData) {
      final peer = WiFiDirectPeer.fromMap(
        Map<String, dynamic>.from(peerData as Map),
      );
      
      // Convert WiFi Direct peer to ConnectedDevice
      return ConnectedDevice(
        peerId: peer.deviceAddress,
        name: peer.deviceName.isNotEmpty ? peer.deviceName : 'Unknown Device',
        status: _mapStatus(peer.status),
        lastSeen: now,
        signalStrength: _estimateSignalStrength(peer),
        isEmergency: _isEmergencyDevice(peer),
      );
    }).toList();
    
    // If we have a connected device, make sure it's in the list
    if (_isConnected && _connectedDeviceAddress != null) {
      // Check if connected device is already in discovered peers
      final connectedDeviceIndex = discoveredPeers.indexWhere(
        (device) => device.peerId == _connectedDeviceAddress,
      );
      
      if (connectedDeviceIndex == -1) {
        // Connected device not in discovered list, add it from current peers
        final existingDevice = _currentPeers.firstWhere(
          (device) => device.peerId == _connectedDeviceAddress,
          orElse: () => ConnectedDevice(
            peerId: _connectedDeviceAddress!,
            name: 'Connected Device',
            status: 'Connected',
            lastSeen: now,
            signalStrength: 5,
            isEmergency: false,
          ),
        );
        // Update status to Connected and add to list
        discoveredPeers.add(existingDevice.copyWith(
          status: 'Connected',
          lastSeen: now,
        ));
      } else {
        // Update the connected device's status
        discoveredPeers[connectedDeviceIndex] = discoveredPeers[connectedDeviceIndex].copyWith(
          status: 'Connected',
          lastSeen: now,
        );
      }
    }
    
    _currentPeers = discoveredPeers;
    _peersController.add(_currentPeers);
  }

  /// Handle connection state changes
  void _handleConnectionChanged(Map<String, dynamic> data) async {
    final connected = data['connected'] as bool? ?? false;
    final now = DateTime.now();
    
    if (connected) {
      final isGroupOwner = data['isGroupOwner'] as bool? ?? false;
      final groupOwnerAddress = data['groupOwnerAddress'] as String?;
      final peerDeviceAddress = data['peerDeviceAddress'] as String?;
      
      // Track the connected device
      _isConnected = true;
      _connectedDeviceAddress = peerDeviceAddress ?? groupOwnerAddress;
      
      print('Connected to peer. Group Owner: $isGroupOwner, Address: $groupOwnerAddress, Peer: $peerDeviceAddress');
      
      // Update the device status in our list immediately
      if (_connectedDeviceAddress != null) {
        final deviceIndex = _currentPeers.indexWhere(
          (device) => device.peerId == _connectedDeviceAddress,
        );
        
        if (deviceIndex != -1) {
          _currentPeers[deviceIndex] = _currentPeers[deviceIndex].copyWith(
            status: 'Connected',
            lastSeen: now,
            signalStrength: 5,
          );
        } else {
          // Device not in list, add it
          _currentPeers.add(ConnectedDevice(
            peerId: _connectedDeviceAddress!,
            name: 'Connected Device',
            status: 'Connected',
            lastSeen: now,
            signalStrength: 5,
            isEmergency: false,
          ));
        }
        _peersController.add(_currentPeers);
      }
      
      // Give WiFi Direct connection time to stabilize
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Start socket communication
      if (isGroupOwner) {
        // Group owner starts server
        print('Starting socket server as group owner...');
        final success = await _wifiDirectService.startSocketServer();
        if (!success) {
          print('Failed to start socket server, retrying...');
          await Future.delayed(const Duration(seconds: 1));
          await _wifiDirectService.startSocketServer();
        }
      } else if (groupOwnerAddress != null && groupOwnerAddress.isNotEmpty) {
        // Client connects to group owner with retry logic
        print('Connecting to group owner at $groupOwnerAddress...');
        bool success = false;
        for (int i = 0; i < 3 && !success; i++) {
          if (i > 0) {
            print('Retry attempt $i to connect to socket...');
            await Future.delayed(Duration(seconds: i));
          }
          success = await _wifiDirectService.connectToSocket(groupOwnerAddress);
          if (success) {
            print('Successfully connected to socket on attempt ${i + 1}');
            break;
          }
        }
        if (!success) {
          print('Failed to connect to socket after 3 attempts');
        }
      }
    } else {
      print('Disconnected from peer');
      _isConnected = false;
      
      // Update device status to Available or remove it
      if (_connectedDeviceAddress != null) {
        final deviceIndex = _currentPeers.indexWhere(
          (device) => device.peerId == _connectedDeviceAddress,
        );
        
        if (deviceIndex != -1) {
          _currentPeers[deviceIndex] = _currentPeers[deviceIndex].copyWith(
            status: 'Available',
            lastSeen: now,
          );
          _peersController.add(_currentPeers);
        }
      }
      
      _connectedDeviceAddress = null;
      await _wifiDirectService.stopSocketCommunication();
    }
  }

  /// Periodically refresh the peer list
  void _refreshPeersPeriodically() {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!isDiscovering) {
        timer.cancel();
        return;
      }
      
      final peers = await _wifiDirectService.getDiscoveredPeers();
      if (peers.isNotEmpty) {
        _handlePeersUpdated({'peers': peers.map((p) => p.toMap()).toList()});
      }
    });
  }

  /// Map WiFi Direct status to app status
  String _mapStatus(String wifiStatus) {
    switch (wifiStatus) {
      case 'Available':
        return 'Available';
      case 'Connected':
        return 'Connected';
      case 'Invited':
        return 'Connecting';
      case 'Failed':
        return 'Failed';
      case 'Unavailable':
        return 'Unavailable';
      default:
        return 'Unknown';
    }
  }

  /// Estimate signal strength based on device type and status
  int _estimateSignalStrength(WiFiDirectPeer peer) {
    // Simple heuristic: connected devices have better signal
    if (peer.status == 'Connected') return 5;
    if (peer.status == 'Available') return 3;
    return 1;
  }

  /// Determine if device is an emergency device based on name/type
  bool _isEmergencyDevice(WiFiDirectPeer peer) {
    final name = peer.deviceName.toLowerCase();
    final type = peer.primaryDeviceType.toLowerCase();
    
    return name.contains('emergency') ||
           name.contains('rescue') ||
           name.contains('medical') ||
           type.contains('emergency');
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    await stopDiscovery();
    await _wifiDirectService.dispose();
    await _peersController.close();
  }
}
