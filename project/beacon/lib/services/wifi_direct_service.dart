import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that handles WiFi Direct communication through platform channels
class WiFiDirectService {
  // Singleton pattern
  static final WiFiDirectService _instance = WiFiDirectService._internal();
  factory WiFiDirectService() => _instance;
  WiFiDirectService._internal();
  
  static const MethodChannel _channel = MethodChannel('com.example.beacon/wifi_direct');
  
  final _eventController = StreamController<WiFiDirectEvent>.broadcast();
  Stream<WiFiDirectEvent> get eventStream => _eventController.stream;
  
  bool _isInitialized = false;
  bool _isDiscovering = false;
  bool _isSocketConnected = false;
  String? _thisDeviceAddress;
  String? _thisDeviceName;
  String? _uniqueDeviceId;
  
  bool get isDiscovering => _isDiscovering;
  bool get isSocketConnected => _isSocketConnected;
  String get deviceId => _uniqueDeviceId ?? 'unknown';
  String get deviceName => _thisDeviceName ?? 'Device ${_uniqueDeviceId?.substring(0, 6) ?? 'Unknown'}';

  /// Initialize WiFi Direct service
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Generate or load unique device ID
      await _initializeDeviceId();
      
      // Set up event listener
      _channel.setMethodCallHandler(_handleMethodCall);
      
      final result = await _channel.invokeMethod<bool>('initialize');
      _isInitialized = result ?? false;
      return _isInitialized;
    } catch (e) {
      print('Error initializing WiFi Direct: $e');
      return false;
    }
  }
  
  /// Generate or retrieve persistent device ID
  Future<void> _initializeDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    _uniqueDeviceId = prefs.getString('device_id');
    
    if (_uniqueDeviceId == null) {
      // Generate new unique ID
      final random = Random();
      final chars = 'abcdef0123456789';
      _uniqueDeviceId = List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
      await prefs.setString('device_id', _uniqueDeviceId!);
      print('🆔 Generated new device ID: $_uniqueDeviceId');
    } else {
      print('🆔 Loaded device ID: $_uniqueDeviceId');
    }
  }

  /// Check if WiFi Direct is supported on this device
  Future<bool> isSupported() async {
    try {
      final result = await _channel.invokeMethod<bool>('isWifiDirectSupported');
      return result ?? false;
    } catch (e) {
      print('Error checking WiFi Direct support: $e');
      return false;
    }
  }

  /// Start discovering peers
  Future<bool> startDiscovery() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }
    
    if (_isDiscovering) return true;
    
    try {
      final result = await _channel.invokeMethod<bool>('startDiscovery');
      _isDiscovering = result ?? false;
      return _isDiscovering;
    } catch (e) {
      print('Error starting discovery: $e');
      return false;
    }
  }

  /// Stop discovering peers
  Future<bool> stopDiscovery() async {
    if (!_isDiscovering) return true;
    
    try {
      final result = await _channel.invokeMethod<bool>('stopDiscovery');
      _isDiscovering = !(result ?? false);
      return !_isDiscovering;
    } catch (e) {
      print('Error stopping discovery: $e');
      return false;
    }
  }

  /// Connect to a peer device
  Future<bool> connectToPeer(String deviceAddress) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }
    
    try {
      final result = await _channel.invokeMethod<bool>(
        'connectToPeer',
        {'deviceAddress': deviceAddress},
      );
      return result ?? false;
    } catch (e) {
      print('Error connecting to peer: $e');
      return false;
    }
  }

  /// Disconnect from current peer
  Future<bool> disconnect() async {
    try {
      final result = await _channel.invokeMethod<bool>('disconnect');
      return result ?? false;
    } catch (e) {
      print('Error disconnecting: $e');
      return false;
    }
  }

  /// Get list of discovered peers
  Future<List<WiFiDirectPeer>> getDiscoveredPeers() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getDiscoveredPeers');
      if (result == null) return [];
      
      return result.map((peer) => WiFiDirectPeer.fromMap(
        Map<String, dynamic>.from(peer as Map),
      )).toList();
    } catch (e) {
      print('Error getting discovered peers: $e');
      return [];
    }
  }

  /// Start socket server (for group owner)
  Future<bool> startSocketServer() async {
    try {
      final result = await _channel.invokeMethod<bool>('startSocketServer');
      _isSocketConnected = result ?? false;
      if (_isSocketConnected) {
        print('Socket server started successfully');
      }
      return _isSocketConnected;
    } catch (e) {
      print('Error starting socket server: $e');
      _isSocketConnected = false;
      return false;
    }
  }

  /// Connect to socket server (for client)
  Future<bool> connectToSocket(String address) async {
    try {
      print('Attempting to connect to socket at: $address');
      final result = await _channel.invokeMethod<bool>(
        'connectToSocket',
        {'address': address},
      );
      _isSocketConnected = result ?? false;
      if (_isSocketConnected) {
        print('Socket connected successfully to $address');
      } else {
        print('Failed to connect to socket at $address');
      }
      return _isSocketConnected;
    } catch (e) {
      print('Error connecting to socket: $e');
      _isSocketConnected = false;
      return false;
    }
  }

  /// Send a message over the socket connection
  Future<bool> sendMessage(String message) async {
    if (!_isSocketConnected) {
      print('Cannot send message: Socket not connected');
      return false;
    }
    
    try {
      print('Sending message over socket: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');
      final result = await _channel.invokeMethod<bool>(
        'sendMessage',
        {'message': message},
      );
      if (result == true) {
        print('Message sent successfully');
      } else {
        print('Failed to send message - native returned false');
      }
      return result ?? false;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  /// Stop socket communication
  Future<bool> stopSocketCommunication() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopSocketCommunication');
      _isSocketConnected = false;
      return result ?? false;
    } catch (e) {
      print('Error stopping socket communication: $e');
      _isSocketConnected = false;
      return false;
    }
  }

  /// Handle method calls from native side
  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onEvent') {
      final Map<String, dynamic> args = Map<String, dynamic>.from(call.arguments as Map);
      final String event = args['event'] as String;
      final Map<String, dynamic> data = Map<String, dynamic>.from(args['data'] as Map);
      
      // Track socket connection state from native events
      if (event == 'socketConnected') {
        _isSocketConnected = true;
        print('Socket connection established (from native event)');
      } else if (event == 'socketDisconnected') {
        _isSocketConnected = false;
        print('Socket connection lost (from native event)');
      } else if (event == 'thisDeviceChanged') {
        _thisDeviceAddress = data['deviceAddress'] as String?;
        _thisDeviceName = data['deviceName'] as String?;
        print('📱 This device: $_thisDeviceName ($_thisDeviceAddress)');
      }
      
      _eventController.add(WiFiDirectEvent(
        type: event,
        data: data,
      ));
    }
  }

  /// Stream of received messages
  Stream<String> get messageStream => _eventController.stream
      .where((event) => event.type == 'messageReceived')
      .map((event) => event.data['message'] as String? ?? '');

  /// Dispose resources
  Future<void> dispose() async {
    await stopDiscovery();
    await _eventController.close();
  }
}

/// Represents a WiFi Direct event
class WiFiDirectEvent {
  final String type;
  final Map<String, dynamic> data;

  WiFiDirectEvent({
    required this.type,
    required this.data,
  });
}

/// Represents a WiFi Direct peer device
class WiFiDirectPeer {
  final String deviceAddress;
  final String deviceName;
  final String status;
  final bool isServiceDiscoveryCapable;
  final String primaryDeviceType;
  final String secondaryDeviceType;

  WiFiDirectPeer({
    required this.deviceAddress,
    required this.deviceName,
    required this.status,
    required this.isServiceDiscoveryCapable,
    required this.primaryDeviceType,
    required this.secondaryDeviceType,
  });

  factory WiFiDirectPeer.fromMap(Map<String, dynamic> map) {
    return WiFiDirectPeer(
      deviceAddress: map['deviceAddress'] as String? ?? '',
      deviceName: map['deviceName'] as String? ?? 'Unknown',
      status: map['status'] as String? ?? 'Unknown',
      isServiceDiscoveryCapable: map['isServiceDiscoveryCapable'] as bool? ?? false,
      primaryDeviceType: map['primaryDeviceType'] as String? ?? '',
      secondaryDeviceType: map['secondaryDeviceType'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceAddress': deviceAddress,
      'deviceName': deviceName,
      'status': status,
      'isServiceDiscoveryCapable': isServiceDiscoveryCapable,
      'primaryDeviceType': primaryDeviceType,
      'secondaryDeviceType': secondaryDeviceType,
    };
  }
}

