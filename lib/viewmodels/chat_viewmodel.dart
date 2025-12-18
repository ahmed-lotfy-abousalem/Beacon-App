import 'dart:async';
import 'package:flutter/material.dart';
import '../services/messaging_service.dart' show MessagingService, ChatMessage;
import '../services/wifi_direct_service.dart' show WiFiDirectService, WiFiDirectEvent;
import 'base_viewmodel.dart';

/// ViewModel for the Chat Page
/// Manages chat messages, connection status, and messaging operations
class ChatViewModel extends BaseViewModel {
  final MessagingService _messagingService = MessagingService();
  final WiFiDirectService _wifiDirectService = WiFiDirectService();

  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<WiFiDirectEvent>? _socketEventSubscription;

  bool _isConnected = false;
  bool _isSocketConnected = false;

  bool get isConnected => _isConnected;
  bool get isSocketConnected => _isSocketConnected;
  List<ChatMessage> get messages => _messagingService.messages;
  Stream<ChatMessage>? get messageStream => _messagingService.messageStream;

  @override
  Future<void> dispose() async {
    await _messageSubscription?.cancel();
    await _socketEventSubscription?.cancel();
    super.dispose();
  }

  /// Initialize messaging service and set up listeners
  Future<void> initialize() async {
    setLoading(true);
    try {
      await _messagingService.initialize();

      // Listen for incoming messages
      _messageSubscription = _messagingService.messageStream.listen((message) {
        notifyListeners();
      });

      // Listen for socket connection events
      _socketEventSubscription = _wifiDirectService.eventStream.listen((event) {
        if (event.type == 'socketConnected') {
          _isSocketConnected = true;
          notifyListeners();
        } else if (event.type == 'socketDisconnected') {
          _isSocketConnected = false;
          notifyListeners();
        }
      });

      // Check initial socket state
      _isSocketConnected = _wifiDirectService.isSocketConnected;
      _isConnected = true;
    } catch (e) {
      setError('Failed to initialize messaging: $e');
    } finally {
      setLoading(false);
    }
  }

  /// Send a message
  Future<bool> sendMessage(String text) async {
    if (text.trim().isEmpty) {
      setError('Message cannot be empty');
      return false;
    }

    if (!_isConnected) {
      setError('Not connected to WiFi Direct. Please wait for connection.');
      return false;
    }

    clearError();
    final success = await _messagingService.sendMessage(text);

    if (!success) {
      setError('Failed to send message. WiFi Direct is connected but socket communication is not ready. Please wait a few seconds and try again.');
    }

    return success;
  }

  /// Format timestamp for display
  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Get color for a specific user based on their senderId
  Color getUserColor(String senderId) {
    // System messages
    if (senderId == 'system') return Colors.orange;

    // Current user
    if (senderId == _wifiDirectService.deviceId || senderId == 'local') {
      return Colors.red;
    }

    // Generate consistent color for other users based on their ID
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.deepOrange,
      Colors.amber,
      Colors.deepPurple,
    ];

    final index = senderId.hashCode.abs() % colors.length;
    return colors[index];
  }
}

