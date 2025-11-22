import 'package:flutter/material.dart';
import 'chat_page.dart';

/// Network Dashboard Pag - shows connected devices and provides communication options
/// This is the main hub where users can see who's connected and start communications
class NetworkDashboardPage extends StatefulWidget {
  const NetworkDashboardPage({super.key});

  @override
  State<NetworkDashboardPage> createState() => _NetworkDashboardPageState();
}

class _NetworkDashboardPageState extends State<NetworkDashboardPage> {
  // Mock data for connected devices
  final List<ConnectedDevice> _connectedDevices = [
    ConnectedDevice(
      name: 'Emergency Team Alpha',
      status: 'Active',
      lastSeen: '2 min ago',
      signalStrength: 4,
      isEmergency: true,
    ),
    ConnectedDevice(
      name: 'Rescue Unit Bravo',
      status: 'Active',
      lastSeen: '5 min ago',
      signalStrength: 3,
      isEmergency: true,
    ),
    ConnectedDevice(
      name: 'Medical Team Charlie',
      status: 'Active',
      lastSeen: '1 min ago',
      signalStrength: 5,
      isEmergency: true,
    ),
    ConnectedDevice(
      name: 'Civilian Group Delta',
      status: 'Active',
      lastSeen: '3 min ago',
      signalStrength: 2,
      isEmergency: false,
    ),
    ConnectedDevice(
      name: 'Volunteer Team Echo',
      status: 'Standby',
      lastSeen: '10 min ago',
      signalStrength: 1,
      isEmergency: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
            color: Colors.red.withOpacity(0.1),
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
                Text(
                  '${_connectedDevices.length} devices connected',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _connectedDevices.length,
              itemBuilder: (context, index) {
                final device = _connectedDevices[index];
                return _buildDeviceCard(device);
              },
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
            Text('Last seen: ${device.lastSeen}'),
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
                        : Colors.grey.withOpacity(0.3),
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
                title: Text(predefinedMessages[index]),
                onTap: () {
                  Navigator.pop(context);
                  _showMessageSentDialog(context, predefinedMessages[index]);
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
  void _showMessageSentDialog(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
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
      MaterialPageRoute(
        builder: (context) => const ChatPage(),
      ),
    );
  }
}

/// Data model for connected devices
class ConnectedDevice {
  final String name;
  final String status;
  final String lastSeen;
  final int signalStrength; // 1-5 scale
  final bool isEmergency; // true for emergency teams, false for civilians

  ConnectedDevice({
    required this.name,
    required this.status,
    required this.lastSeen,
    required this.signalStrength,
    required this.isEmergency,
  });
}
