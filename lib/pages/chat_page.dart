import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../viewmodels/chat_viewmodel.dart';
import '../services/messaging_service.dart' show ChatMessage;

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
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _viewModelSubscription;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<ChatViewModel>(context, listen: false);
    viewModel.initialize();
    
    // Listen to ViewModel changes to scroll to bottom when new messages arrive
    _viewModelSubscription = viewModel.messageStream?.listen((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _viewModelSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ChatViewModel>(context);
    final isSocketConnected = viewModel.isSocketConnected;
    final isConnected = viewModel.isConnected;
    final messages = viewModel.messages;

    return Scaffold(
      // App bar with chat title and voice command button
      appBar: AppBar(
        title: const Text('Emergency Chat'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          // Voice command button
          IconButton(
            onPressed: () => _showVoiceCommandDialog(context),
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
              color: isSocketConnected 
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: isSocketConnected ? Colors.green : Colors.orange,
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
                    color: isSocketConnected ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isSocketConnected
                        ? 'Socket Ready - You can send messages'
                        : 'Waiting for socket connection...',
                    style: TextStyle(
                      color: isSocketConnected ? Colors.green.shade800 : Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (!isSocketConnected)
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
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSocketConnected ? Icons.check_circle : (isConnected ? Icons.pending : Icons.wifi_off),
                          size: 64,
                          color: isSocketConnected ? Colors.green : (isConnected ? Colors.orange : Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isSocketConnected
                              ? 'Socket ready! Start a conversation.'
                              : (isConnected
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
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _buildMessageBubble(context, viewModel, message);
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

                // Send button
                FloatingActionButton(
                  onPressed: isSocketConnected ? () => _sendMessage(context, viewModel) : null,
                  backgroundColor: isSocketConnected ? Colors.red : Colors.grey,
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
  Widget _buildMessageBubble(BuildContext context, ChatViewModel viewModel, ChatMessage message) {
    final userColor = viewModel.getUserColor(message.senderId);
    
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
            child: Container(
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
                    viewModel.formatTimestamp(message.timestamp),
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
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  /// Sends a new message
  Future<void> _sendMessage(BuildContext context, ChatViewModel viewModel) async {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _messageController.clear();
      
      final success = await viewModel.sendMessage(text);
      
      if (!success && mounted) {
        final errorMessage = viewModel.errorMessage ?? 'Failed to send message';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Shows voice command dialog (UI only)
  void _showVoiceCommandDialog(BuildContext context) {
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

