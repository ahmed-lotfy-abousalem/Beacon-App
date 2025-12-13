import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../data/models.dart';
import '../providers/beacon_provider.dart';
import '../services/wifi_direct_service.dart' show WiFiDirectService, WiFiDirectEvent;
import '../services/messaging_service.dart';
import 'chat_page.dart';

/// Network Dashboard Page - shows connected devices and provides communication options
/// This is the main hub where users can see who's connected and start communications
class NetworkDashboardPage extends StatefulWidget {
  const NetworkDashboardPage({super.key});

  @override
  State<NetworkDashboardPage> createState() => _NetworkDashboardPageState();
}

class _NetworkDashboardPageState extends State<NetworkDashboardPage> {
  late final WiFiDirectService _wifiDirectService;
  late final MessagingService _messagingService;
  StreamSubscription<WiFiDirectEvent>? _socketEventSubscription;
  bool _isSocketConnected = false;
  
  @override
  void initState() {
    super.initState();
    _wifiDirectService = WiFiDirectService();
    _messagingService = MessagingService();
    _messagingService.initialize();
    _initializeSocketMonitoring();
  }
  
  void _initializeSocketMonitoring() {
    // Check initial socket state
    _isSocketConnected = _wifiDirectService.isSocketConnected;
    
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
  }
  
  @override
  void dispose() {
    _socketEventSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final beaconProvider = context.watch<BeaconProvider>();
    final devices = beaconProvider.connectedDevices;

    return Scaffold(
      // App bar with dashboard title and voice command button
      appBar: AppBar(
        title: const Text('Network Dashboard'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          // Voice command button (UI only, no functionality)
          IconButton(
            onPressed: () {
              _showVoiceCommandDialog(context);
            },
            icon: const Icon(Icons.mic),
            tooltip: 'Voice Command',
          ),
        ],
      ),

      body: Column(
        children: [
          // Network status header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.red.withValues(alpha: 0.1),
            child: Column(
              children: [
                const Text(
                  'Emergency Network Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                beaconProvider.isLoading
                    ? const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: CircularProgressIndicator(),
                      )
                    : Column(
                        children: [
                          Text(
                            '${devices.length} devices connected',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Socket status indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isSocketConnected
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isSocketConnected ? Colors.green : Colors.orange,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isSocketConnected ? Icons.check_circle : Icons.pending,
                                  size: 16,
                                  color: _isSocketConnected ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isSocketConnected ? 'Messaging Ready' : 'Connecting...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _isSocketConnected ? Colors.green.shade700 : Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),

          // Action buttons section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showPredefinedMessages(context),
                    icon: const Icon(Icons.message),
                    label: const Text('Send Predefined\nMessage'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToChat(context),
                    icon: const Icon(Icons.chat),
                    label: const Text('Start Private\nChat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Connected devices list
          Expanded(
            child: beaconProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => context.read<BeaconProvider>().refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        return _buildDeviceCard(device);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Builds a card widget for each connected device
  Widget _buildDeviceCard(ConnectedDevice device) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: device.isEmergency ? Colors.red : Colors.blue,
          child: Icon(
            device.isEmergency ? Icons.emergency : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${device.status}'),
            Text('Last seen: ${_formatLastSeen(device.lastSeen)}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Signal strength indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                return Container(
                  width: 3,
                  height: 8 + (i * 2),
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: i < device.signalStrength
                        ? Colors.green
                        : Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            // Voice command button for each device
            IconButton(
              onPressed: () => _showVoiceCommandDialog(context),
              icon: const Icon(Icons.mic, size: 16),
              tooltip: 'Voice Command',
            ),
          ],
        ),
        onTap: () => _navigateToChat(context),
      ),
    );
  }

  /// Shows predefined messages dialog
  void _showPredefinedMessages(BuildContext context) {
    final predefinedMessages = [
      'Need immediate medical assistance',
      'Evacuation required in my area',
      'Food and water supplies needed',
      'Shelter required for 5 people',
      'All safe, no assistance needed',
      'Emergency supplies available',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Predefined Messages'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: predefinedMessages.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.send, color: Colors.red),
                title: Text(predefinedMessages[index]),
                onTap: () async {
                  print('Predefined message selected: ${predefinedMessages[index]}');
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  final message = '⚠️ ' + predefinedMessages[index];
                  
                  print('Sending predefined message: $message');
                  // Send via WiFi Direct
                  final success = await _messagingService.sendMessage(message);
                  
                  print('Predefined message send result: $success');
                  if (success) {
                    _showMessageSentDialog(messenger, message);
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Failed to send. Check WiFi Direct connection.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Shows message sent confirmation
  void _showMessageSentDialog(
    ScaffoldMessengerState messenger,
    String message,
  ) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Message sent: "$message"'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Shows voice command dialog (UI only)
  void _showVoiceCommandDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Command'),
        content: const Text(
          'Voice command feature would be implemented here.\n\n'
          'This would allow users to send voice messages or use voice-to-text for emergency communications.',
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

  /// Navigates to chat page
  void _navigateToChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatPage()),
    );
  }

  String _formatLastSeen(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hrs ago';
    return '${difference.inDays} days ago';
  }
}
