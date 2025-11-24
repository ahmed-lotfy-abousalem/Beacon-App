import 'dart:async';
import 'package:flutter/services.dart';

/// Service that handles WiFi Direct communication through platform channels
class WiFiDirectService {
  static const MethodChannel _channel = MethodChannel('com.example.beacon/wifi_direct');
  
  final _eventController = StreamController<WiFiDirectEvent>.broadcast();
  Stream<WiFiDirectEvent> get eventStream => _eventController.stream;
  
  bool _isInitialized = false;
  bool _isDiscovering = false;
  
  bool get isDiscovering => _isDiscovering;

  /// Initialize WiFi Direct service
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
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

  /// Handle method calls from native side
  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onEvent') {
      final Map<String, dynamic> args = Map<String, dynamic>.from(call.arguments as Map);
      final String event = args['event'] as String;
      final Map<String, dynamic> data = Map<String, dynamic>.from(args['data'] as Map);
      
      _eventController.add(WiFiDirectEvent(
        type: event,
        data: data,
      ));
    }
  }

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

