import 'package:flutter/material.dart';

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
  
  // List to store chat messages (mock data)
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Emergency Team Alpha has joined the network',
      isFromCurrentUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      senderName: 'Emergency Team Alpha',
      isSystemMessage: true,
    ),
    ChatMessage(
      text: 'We need immediate medical assistance at location 3B',
      isFromCurrentUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      senderName: 'Rescue Unit Bravo',
      isSystemMessage: false,
    ),
    ChatMessage(
      text: 'Medical Team Charlie is en route to location 3B',
      isFromCurrentUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
      senderName: 'Medical Team Charlie',
      isSystemMessage: false,
    ),
    ChatMessage(
      text: 'Thank you! We have 3 injured people here',
      isFromCurrentUser: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      senderName: 'You',
      isSystemMessage: false,
    ),
    ChatMessage(
      text: 'ETA 5 minutes. Please prepare the injured for transport',
      isFromCurrentUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      senderName: 'Medical Team Charlie',
      isSystemMessage: false,
    ),
  ];

  @override
  void dispose() {
    // Clean up the text controller when the widget is disposed
    _messageController.dispose();
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
          // Chat messages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          // Message input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
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
                
                // Send button
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: Colors.red,
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

  /// Builds a message bubble widget for each chat message
  Widget _buildMessageBubble(ChatMessage message) {
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
              backgroundColor: message.isSystemMessage
                  ? Colors.orange
                  : Colors.blue,
              child: Icon(
                message.isSystemMessage
                    ? Icons.info
                    : Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: message.isFromCurrentUser
                    ? Colors.red
                    : message.isSystemMessage
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
                border: message.isSystemMessage
                    ? Border.all(color: Colors.orange, width: 1)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!message.isFromCurrentUser && !message.isSystemMessage)
                    Text(
                      message.senderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  if (!message.isFromCurrentUser && !message.isSystemMessage)
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
          ),
          
          if (message.isFromCurrentUser) ...[
            const SizedBox(width: 8),
            // Avatar for current user
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.red,
              child: Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Sends a new message
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: text,
            isFromCurrentUser: true,
            timestamp: DateTime.now(),
            senderName: 'You',
            isSystemMessage: false,
          ),
        );
      });
      _messageController.clear();
      
      // Simulate receiving a response after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                text: 'Message received. Emergency team responding.',
                isFromCurrentUser: false,
                timestamp: DateTime.now(),
                senderName: 'Emergency Team Alpha',
                isSystemMessage: false,
              ),
            );
          });
        }
      });
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
        title: const Text('Voice Command'),
        content: const Text(
          'Voice command feature would allow you to:\n\n'
          '• Send voice messages\n'
          '• Use voice-to-text for typing\n'
          '• Send emergency alerts with voice\n\n'
          'This feature would be especially useful during emergencies when typing might be difficult.',
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
}

/// Data model for chat messages
class ChatMessage {
  final String text;
  final bool isFromCurrentUser;
  final DateTime timestamp;
  final String senderName;
  final bool isSystemMessage;

  ChatMessage({
    required this.text,
    required this.isFromCurrentUser,
    required this.timestamp,
    required this.senderName,
    required this.isSystemMessage,
  });
}
