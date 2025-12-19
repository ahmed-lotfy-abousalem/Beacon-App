import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/messaging_service.dart';
import '../viewmodels/chat_view_model.dart';
import '../viewmodels/peer_notification_view_model.dart';

/// MVVM Refactored Chat Page
/// 
/// This is a simplified, clean version of the chat page using MVVM architecture.
/// All business logic is moved to ChatViewModel, leaving the UI layer clean.
/// Integrates peer notifications for join/leave events.
/// 
/// Benefits:
/// - Easy to test (ViewModel logic is separate from UI)
/// - Easy to maintain (clear separation of concerns)
/// - Easy to reuse (ViewModel can be used with different UIs)
/// - More readable (UI only handles rendering)
class ChatPageMVVM extends StatefulWidget {
  const ChatPageMVVM({super.key});

  @override
  State<ChatPageMVVM> createState() => _ChatPageMVVMState();
}

class _ChatPageMVVMState extends State<ChatPageMVVM> {
  late ChatViewModel _viewModel;
  late PeerNotificationViewModel _peerNotificationViewModel;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = ChatViewModel();
    _peerNotificationViewModel = PeerNotificationViewModel();
    
    print('🚀 ChatPageMVVM initState: Initializing ViewModels');
    
    // Set error callback for chat view model
    _viewModel.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    };

    // Set callbacks for peer notification view model
    _peerNotificationViewModel.onPeerJoined = (device) {
      print('✅ ChatPageMVVM: onPeerJoined callback triggered for ${device.name}');
      if (mounted) {
        _showPeerNotification(
          'Peer Joined',
          '${device.name} has joined the network',
          Icons.login,
          Colors.green,
        );
      }
    };

    _peerNotificationViewModel.onPeerLeft = (device) {
      print('❌ ChatPageMVVM: onPeerLeft callback triggered for ${device.name}');
      if (mounted) {
        _showPeerNotification(
          'Peer Left',
          '${device.name} has left the network',
          Icons.logout,
          Colors.red,
        );
      }
    };
    
    // Initialize both ViewModels
    print('📱 ChatPageMVVM: Initializing ChatViewModel');
    _viewModel.initialize().then((_) {
      if (mounted) {
        _scrollToBottom();
      }
    });

    print('📡 ChatPageMVVM: Initializing PeerNotificationViewModel');
    _peerNotificationViewModel.initialize().then((_) {
      print('✅ ChatPageMVVM: PeerNotificationViewModel initialized');
    }).catchError((error) {
      print('❌ ChatPageMVVM: Error initializing PeerNotificationViewModel: $error');
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _viewModel.dispose();
    _peerNotificationViewModel.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
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

  /// Show peer notification in a styled snackbar
  void _showPeerNotification(
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatViewModel>.value(
      value: _viewModel,
      child: ChangeNotifierProvider<PeerNotificationViewModel>.value(
        value: _peerNotificationViewModel,
        child: Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Emergency Chat'),
                Consumer<PeerNotificationViewModel>(
                  builder: (context, peerViewModel, _) {
                    return Text(
                      peerViewModel.peersDisplayText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    );
                  },
                ),
              ],
            ),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            actions: [
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
              _buildConnectionStatusBar(),

              // Chat messages list
              Expanded(
                child: Consumer<ChatViewModel>(
                  builder: (context, viewModel, _) {
                    if (viewModel.isLoading && viewModel.messages.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (viewModel.messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                            viewModel.isSocketConnected
                                ? Icons.check_circle
                                : Icons.pending,
                            size: 64,
                            color: viewModel.isSocketConnected
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            viewModel.isSocketConnected
                                ? 'Socket ready! Start a conversation.'
                                : 'Waiting for socket connection...',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: viewModel.messages.length,
                    itemBuilder: (context, index) {
                      final message = viewModel.messages[index];
                      return _buildMessageBubble(message, viewModel);
                    },
                  );
                },
              ),
            ),

              // Message input area
              _buildMessageInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build connection status bar
  Widget _buildConnectionStatusBar() {
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, _) {
        final isConnected = viewModel.isSocketConnected;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isConnected
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: isConnected ? Colors.green : Colors.orange,
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
                  color: isConnected ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isConnected
                      ? 'Socket Ready - You can send messages'
                      : 'Waiting for socket connection...',
                  style: TextStyle(
                    color: isConnected
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (!isConnected)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Build message input area
  Widget _buildMessageInputArea() {
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, _) {
        return Container(
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
                  controller: viewModel.messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),

              // Microphone button for speech-to-text
              FloatingActionButton(
                onPressed: viewModel.isSpeechListening
                    ? () => viewModel.stopSpeechListening()
                    : () => viewModel.startSpeechListening(),
                backgroundColor:
                    viewModel.isSpeechListening ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
                mini: true,
                tooltip: viewModel.isSpeechListening
                    ? 'Stop listening'
                    : 'Start speech-to-text',
                child: Icon(viewModel.isSpeechListening
                    ? Icons.mic
                    : Icons.mic_none),
              ),
              const SizedBox(width: 8),

              // Send button
              FloatingActionButton(
                onPressed: viewModel.isSocketConnected
                    ? () => viewModel.sendMessage()
                    : null,
                backgroundColor:
                    viewModel.isSocketConnected ? Colors.red : Colors.grey,
                foregroundColor: Colors.white,
                mini: true,
                child: const Icon(Icons.send),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build a message bubble with TTS button
  Widget _buildMessageBubble(ChatMessage message, ChatViewModel viewModel) {
    final userColor = _getUserColor(message.senderId, viewModel);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: message.isFromCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isFromCurrentUser) ...[
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
              crossAxisAlignment: message.isFromCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isFromCurrentUser
                        ? Colors.red
                        : message.senderId == 'system'
                            ? Colors.orange.withValues(alpha: 0.1)
                            : userColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: message.senderId == 'system'
                        ? Border.all(color: Colors.orange, width: 1)
                        : Border.all(
                            color: userColor.withValues(alpha: 0.3),
                            width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!message.isFromCurrentUser &&
                          message.senderId != 'system')
                        Text(
                          message.senderName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: userColor,
                          ),
                        ),
                      if (!message.isFromCurrentUser &&
                          message.senderId != 'system')
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
                Consumer<ChatViewModel>(
                  builder: (context, vm, _) => SizedBox(
                    height: 28,
                    child: IconButton(
                      onPressed: () => vm.speakMessage(message),
                      icon: Icon(
                        vm.isTTSSpeaking &&
                                vm.currentSpeakingMessageId == message.text
                            ? Icons.pause_circle
                            : Icons.volume_up,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: message.isFromCurrentUser
                          ? Colors.red
                          : userColor,
                      tooltip: 'Play text-to-speech',
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (message.isFromCurrentUser) ...[
            const SizedBox(width: 8),
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

  Color _getUserColor(String senderId, ChatViewModel viewModel) {
    if (senderId == 'system') return Colors.orange;
    if (senderId == viewModel.wifiDirectService.deviceId ||
        senderId == 'local') {
      return Colors.red;
    }

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
}
