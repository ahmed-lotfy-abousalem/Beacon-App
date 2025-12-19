import 'package:flutter/material.dart';
import 'dart:async';
import '../services/messaging_service.dart' show MessagingService, ChatMessage;
import '../services/wifi_direct_service.dart' show WiFiDirectService, WiFiDirectEvent;
import '../services/speech_to_text_service.dart';
import '../services/text_to_speech_service.dart';

/// Chat Page - Simple messaging interface for emergency communications
/// Allows users to send and receive messages in real-time during emergencies
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Text editing controller for the message input field
  final TextEditingController _messageController = TextEditingController();
  late final MessagingService _messagingService;
  late final WiFiDirectService _wifiDirectService;
  late final SpeechToTextService _speechToTextService;
  late final TextToSpeechService _textToSpeechService;
  
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<WiFiDirectEvent>? _socketEventSubscription;
  bool _isConnected = false;
  bool _isSocketConnected = false;
  bool _isSpeechListening = false;
  bool _isTTSSpeaking = false;
  String _currentSpeakingMessageId = '';

  @override
  void initState() {
    super.initState();
    _messagingService = MessagingService();
    _wifiDirectService = WiFiDirectService();
    _speechToTextService = SpeechToTextService();
    _textToSpeechService = TextToSpeechService();
    _initializeMessaging();
    _initializeSpeechToText();
    _initializeTextToSpeech();
  }

  Future<void> _initializeMessaging() async {
    await _messagingService.initialize();
    
    // Listen for incoming messages to trigger UI updates
    _messageSubscription = _messagingService.messageStream.listen((message) {
      if (mounted) {
        setState(() {
          // Messages are already stored in MessagingService, just trigger rebuild
        });
        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
    
    // Listen for socket connection events
    _socketEventSubscription = _wifiDirectService.eventStream.listen((event) {
      if (mounted) {
        if (event.type == 'socketConnected') {
          setState(() {
            _isSocketConnected = true;
          });
        } else if (event.type == 'socketDisconnected') {
          setState(() {
            _isSocketConnected = false;
          });
        }
      }
    });
    
    // Check initial socket state
    _isSocketConnected = _wifiDirectService.isSocketConnected;
    
    setState(() {
      _isConnected = true;
    });
  }

  /// Initialize speech-to-text service
  Future<void> _initializeSpeechToText() async {
    try {
      await _speechToTextService.initialize();
      
      // Set up callbacks
      _speechToTextService.setOnTextRecognized((text) {
        if (mounted) {
          setState(() {
            _messageController.text = text;
          });
        }
      });
      
      _speechToTextService.setOnListeningStatusChanged((isListening) {
        if (mounted) {
          setState(() {
            _isSpeechListening = isListening;
          });
        }
      });
      
      _speechToTextService.setOnError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Speech recognition error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      print('Error initializing speech-to-text: $e');
    }
  }

  /// Initialize text-to-speech service
  Future<void> _initializeTextToSpeech() async {
    try {
      await _textToSpeechService.initialize();
      
      // Set up callbacks
      _textToSpeechService.setOnSpeakingStatusChanged((isSpeaking) {
        if (mounted) {
          setState(() {
            _isTTSSpeaking = isSpeaking;
          });
        }
      });
      
      _textToSpeechService.setOnError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Text-to-speech error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      print('Error initializing text-to-speech: $e');
    }
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    // Clean up the text controller when the widget is disposed
    _messageController.dispose();
    _messageSubscription?.cancel();
    _socketEventSubscription?.cancel();
    _speechToTextService.dispose();
    _textToSpeechService.dispose();
    // Don't dispose singleton service, just cancel subscriptions
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with chat title and voice command button
      appBar: AppBar(
        title: const Text('Emergency Chat'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          // Voice command button
          IconButton(
            onPressed: _showVoiceCommandDialog,
            icon: const Icon(Icons.mic),
            tooltip: 'Voice Command',
          ),
        ],
      ),

      body: Column(
        children: [
          // Socket connection status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isSocketConnected 
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: _isSocketConnected ? Colors.green : Colors.orange,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isSocketConnected ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isSocketConnected
                        ? 'Socket Ready - You can send messages'
                        : 'Waiting for socket connection...',
                    style: TextStyle(
                      color: _isSocketConnected ? Colors.green.shade800 : Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (!_isSocketConnected)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
              ],
            ),
          ),
          
          // Chat messages list
          Expanded(
            child: _messagingService.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSocketConnected ? Icons.check_circle : (_isConnected ? Icons.pending : Icons.wifi_off),
                          size: 64,
                          color: _isSocketConnected ? Colors.green : (_isConnected ? Colors.orange : Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSocketConnected
                              ? 'Socket ready! Start a conversation.'
                              : (_isConnected
                                  ? 'Waiting for socket connection...'
                                  : 'Connecting to WiFi Direct...'),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messagingService.messages.length,
                    itemBuilder: (context, index) {
                      final message = _messagingService.messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),

          // Message input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                // Text input field
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null, // Allow multiple lines
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),

                // Microphone button for speech-to-text
                FloatingActionButton(
                  onPressed: _isSpeechListening ? _stopSpeechListening : _startSpeechListening,
                  backgroundColor: _isSpeechListening ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                  mini: true,
                  tooltip: _isSpeechListening ? 'Stop listening' : 'Start speech-to-text',
                  child: Icon(_isSpeechListening ? Icons.mic : Icons.mic_none),
                ),
                const SizedBox(width: 8),

                // Send button
                FloatingActionButton(
                  onPressed: _isSocketConnected ? _sendMessage : null,
                  backgroundColor: _isSocketConnected ? Colors.red : Colors.grey,
                  foregroundColor: Colors.white,
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get color for a specific user based on their senderId
  Color _getUserColor(String senderId) {
    // System messages
    if (senderId == 'system') return Colors.orange;
    
    // Current user - check against actual device ID
    if (senderId == _wifiDirectService.deviceId || senderId == 'local') return Colors.red;
    
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
    
    // Use hash code to pick a consistent color for each user
    final index = senderId.hashCode.abs() % colors.length;
    return colors[index];
  }

  /// Builds a message bubble widget for each chat message
  Widget _buildMessageBubble(ChatMessage message) {
    final userColor = _getUserColor(message.senderId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: message.isFromCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isFromCurrentUser) ...[
            // Avatar for other users
            CircleAvatar(
              radius: 16,
              backgroundColor: userColor,
              child: Icon(
                message.senderId == 'system' ? Icons.info : Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: message.isFromCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isFromCurrentUser
                        ? Colors.red
                        : message.senderId == 'system'
                        ? Colors.orange.withValues(alpha: 0.1)
                        : userColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: message.senderId == 'system'
                        ? Border.all(color: Colors.orange, width: 1)
                        : Border.all(color: userColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!message.isFromCurrentUser && message.senderId != 'system')
                        Text(
                          message.senderName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: userColor,
                          ),
                        ),
                      if (!message.isFromCurrentUser && message.senderId != 'system')
                        const SizedBox(height: 2),
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.isFromCurrentUser
                              ? Colors.white
                              : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(message.timestamp),
                        style: TextStyle(
                          color: message.isFromCurrentUser
                              ? Colors.white70
                              : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // Text-to-Speech button
                SizedBox(
                  height: 28,
                  child: IconButton(
                    onPressed: () => _speakMessage(message),
                    icon: Icon(
                      _isTTSSpeaking && _currentSpeakingMessageId == message.text
                          ? Icons.pause_circle
                          : Icons.volume_up,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: message.isFromCurrentUser ? Colors.red : userColor,
                    tooltip: 'Play text-to-speech',
                  ),
                ),
              ],
            ),
          ),

          if (message.isFromCurrentUser) ...[
            const SizedBox(width: 8),
            // Avatar for current user
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.red,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  /// Speaks a message using text-to-speech
  Future<void> _speakMessage(ChatMessage message) async {
    try {
      if (_isTTSSpeaking && _currentSpeakingMessageId == message.text) {
        // Stop if currently speaking this message
        await _textToSpeechService.stop();
        setState(() {
          _currentSpeakingMessageId = '';
        });
      } else {
        // Start speaking the message
        setState(() {
          _currentSpeakingMessageId = message.text;
        });
        await _textToSpeechService.speak(message.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Sends a new message
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty && _isConnected) {
      _messageController.clear();
      
      // Send message via messaging service
      final success = await _messagingService.sendMessage(text);
      
      if (!success && mounted) {
        // Show error if message failed to send
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. WiFi Direct is connected but socket communication is not ready. Please wait a few seconds and try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } else if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to WiFi Direct. Please wait for connection.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Formats timestamp for display
  String _formatTimestamp(DateTime timestamp) {
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

  /// Shows voice command dialog (UI only)
  void _showVoiceCommandDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Speech-to-Text Guide'),
        content: const Text(
          'How to use speech-to-text:\n\n'
          '• Tap the microphone button to start speaking\n'
          '• Speak clearly and loudly\n'
          '• The app will recognize your speech and fill the text field\n'
          '• Review the text and tap Send to transmit\n\n'
          'This feature is especially useful during emergencies when typing might be difficult.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Start speech-to-text listening
  Future<void> _startSpeechListening() async {
    try {
      // Check if already initialized
      if (!_speechToTextService.isInitialized) {
        final initialized = await _speechToTextService.initialize();
        if (!initialized) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Speech recognition is not available on this device'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
      
      await _speechToTextService.startListening();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting speech recognition: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Stop speech-to-text listening
  Future<void> _stopSpeechListening() async {
    try {
      await _speechToTextService.stopListening();
      if (mounted) {
        // Auto-send if message was recognized
        if (_messageController.text.trim().isNotEmpty && _isSocketConnected) {
          await Future.delayed(const Duration(milliseconds: 500));
          _sendMessage();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping speech recognition: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

