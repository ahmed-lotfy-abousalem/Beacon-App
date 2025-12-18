import 'dart:async';
import 'dart:convert';
import 'wifi_direct_service.dart';

/// Service that handles messaging over WiFi Direct connections
class MessagingService {
  // Singleton pattern
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();
  
  final WiFiDirectService _wifiDirectService = WiFiDirectService();
  
  final _messageController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messageStream => _messageController.stream;
  
  // Persistent message storage
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  
  StreamSubscription<WiFiDirectEvent>? _eventSubscription;
  bool _isInitialized = false;

  /// Initialize the messaging service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize WiFi Direct service
    await _wifiDirectService.initialize();
    
    // Listen for incoming messages
    _eventSubscription = _wifiDirectService.eventStream.listen((event) {
      if (event.type == 'messageReceived') {
        final messageText = event.data['message'] as String? ?? '';
        final sender = event.data['sender'] as String? ?? 'Unknown';
        
        try {
          // Try to parse as JSON message envelope
          final jsonData = jsonDecode(messageText);
          // Override isFromCurrentUser based on sender ID comparison
          final senderId = jsonData['senderId'] as String? ?? 'unknown';
          final isFromMe = senderId == _wifiDirectService.deviceId;
          
          final message = ChatMessage(
            text: jsonData['text'] as String? ?? '',
            senderId: senderId,
            senderName: jsonData['senderName'] as String? ?? 'Unknown',
            timestamp: jsonData['timestamp'] != null
                ? DateTime.parse(jsonData['timestamp'] as String)
                : DateTime.now(),
            isFromCurrentUser: isFromMe,
          );
          _messages.add(message);
          _messageController.add(message);
          print('📥 Message received from $senderId (isFromMe: $isFromMe): ${message.text.substring(0, message.text.length > 30 ? 30 : message.text.length)}...');
        } catch (e) {
          // If not JSON, treat as plain text
          final message = ChatMessage(
            text: messageText,
            senderId: sender,
            senderName: _extractDeviceName(sender),
            timestamp: DateTime.now(),
            isFromCurrentUser: false,
          );
          _messages.add(message);
          _messageController.add(message);
          print('📥 Plain message received and stored: ${message.text.substring(0, message.text.length > 30 ? 30 : message.text.length)}...');
        }
      }
    });
    
    _isInitialized = true;
  }

  /// Send a message to connected peers
  Future<bool> sendMessage(String text, {String? senderId, String? senderName}) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // Check if socket is connected
    if (!_wifiDirectService.isSocketConnected) {
      print('Cannot send message: Socket not connected. WiFi Direct may be connected but socket communication is not established.');
      return false;
    }
    
    try {
      // Create message envelope with actual device ID
      final deviceId = _wifiDirectService.deviceId;
      final deviceName = _wifiDirectService.deviceName;
      print('📤 Sending message with deviceId: $deviceId, deviceName: $deviceName');
      
      final message = ChatMessage(
        text: text,
        senderId: senderId ?? deviceId,
        senderName: senderName ?? deviceName,
        timestamp: DateTime.now(),
        isFromCurrentUser: true,
      );
      
      // Convert to JSON
      final jsonMessage = jsonEncode(message.toJson());
      print('Attempting to send message: $text');
      
      // Send over socket
      final success = await _wifiDirectService.sendMessage(jsonMessage);
      
      if (success) {
        print('📤 Message sent successfully: ${text.substring(0, text.length > 30 ? 30 : text.length)}...');
        // Store in persistent list and broadcast
        _messages.add(message);
        _messageController.add(message);
      } else {
        print('❌ Failed to send message - socket send returned false');
      }
      
      return success;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  /// Extract device name from sender address
  String _extractDeviceName(String sender) {
    // Try to extract a readable name from the sender address
    if (sender.contains('/')) {
      return sender.split('/').last;
    }
    return sender.length > 8 ? 'Device ${sender.substring(0, 8)}' : 'Unknown Device';
  }

  /// Clear all messages
  void clearMessages() {
    _messages.clear();
    print('🗑️ All messages cleared');
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    await _messageController.close();
  }
}

/// Chat message model
class ChatMessage {
  final String text;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final bool isFromCurrentUser;

  ChatMessage({
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    required this.isFromCurrentUser,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String? ?? json['payload']?['text'] as String? ?? '',
      senderId: json['senderId'] as String? ?? 'unknown',
      senderName: json['senderName'] as String? ?? json['payload']?['senderName'] as String? ?? 'Unknown',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isFromCurrentUser: json['isFromCurrentUser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'chat',
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': timestamp.toIso8601String(),
      'text': text,
      'isFromCurrentUser': isFromCurrentUser,
    };
  }
}

