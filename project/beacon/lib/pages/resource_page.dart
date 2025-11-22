import 'package:flutter/material.dart';

/// Resource  - Shows resource sharing options for emergency situations
/// Allows users to share and request essential resources like medical supplies, shelter, and food
class ResourcePage extends StatefulWidget {
  const ResourcePage({super.key});

  @override
  State<ResourcePage> createState() => _ResourcePageState();
}

class _ResourcePageState extends State<ResourcePage> {
  // Mock data for available resources
  final List<ResourceItem> _availableResources = [
    ResourceItem(
      name: 'Medical Supplies',
      description: 'First aid kits, bandages, medications',
      availableCount: 15,
      requestedCount: 8,
      icon: Icons.medical_services,
      color: Colors.red,
    ),
    ResourceItem(
      name: 'Shelter',
      description: 'Temporary housing, tents, blankets',
      availableCount: 12,
      requestedCount: 20,
      icon: Icons.home,
      color: Colors.blue,
    ),
    ResourceItem(
      name: 'Food',
      description: 'Emergency rations, water, canned goods',
      availableCount: 25,
      requestedCount: 15,
      icon: Icons.restaurant,
      color: Colors.green,
    ),
    ResourceItem(
      name: 'Transportation',
      description: 'Vehicles, fuel, evacuation assistance',
      availableCount: 8,
      requestedCount: 12,
      icon: Icons.directions_car,
      color: Colors.orange,
    ),
    ResourceItem(
      name: 'Communication',
      description: 'Radios, batteries, charging stations',
      availableCount: 6,
      requestedCount: 10,
      icon: Icons.radio,
      color: Colors.purple,
    ),
    ResourceItem(
      name: 'Tools & Equipment',
      description: 'Generators, flashlights, rescue tools',
      availableCount: 10,
      requestedCount: 7,
      icon: Icons.build,
      color: Colors.brown,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with resources title and voice command button
      appBar: AppBar(
        title: const Text('Emergency Resources'),
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
          // Header section with emergency info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.red.withValues(alpha: 0.1),
            child: Column(
              children: [
                const Text(
                  'Resource Sharing Network',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share and request essential resources during emergencies',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Quick action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showShareResourceDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Share\nResource'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showRequestResourceDialog,
                    icon: const Icon(Icons.request_quote),
                    label: const Text('Request\nResource'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Resources list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _availableResources.length,
              itemBuilder: (context, index) {
                final resource = _availableResources[index];
                return _buildResourceCard(resource);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a card widget for each resource category
  Widget _buildResourceCard(ResourceItem resource) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resource header with icon and name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: resource.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(resource.icon, color: resource.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        resource.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Resource statistics
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Available',
                    resource.availableCount.toString(),
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Requested',
                    resource.requestedCount.toString(),
                    Colors.orange,
                    Icons.pending,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareResource(resource),
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _requestResource(resource),
                    icon: const Icon(Icons.request_quote, size: 16),
                    label: const Text('Request'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a small stat card for displaying numbers
  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  /// Shows dialog for sharing a resource
  void _shareResource(ResourceItem resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share ${resource.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How many ${resource.name.toLowerCase()} do you want to share?',
            ),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Location (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('Resource shared successfully!');
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  /// Shows dialog for requesting a resource
  void _requestResource(ResourceItem resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request ${resource.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How many ${resource.name.toLowerCase()} do you need?'),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity Needed',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Your Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Urgency Level',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('Resource request sent!');
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  /// Shows general share resource dialog
  void _showShareResourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Resource'),
        content: const Text(
          'Select the type of resource you want to share with the emergency network.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('Resource sharing options displayed!');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  /// Shows general request resource dialog
  void _showRequestResourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Resource'),
        content: const Text(
          'Select the type of resource you need from the emergency network.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('Resource request options displayed!');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  /// Shows voice command dialog (UI only)
  void _showVoiceCommandDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Command'),
        content: const Text(
          'Voice command feature would allow you to:\n\n'
          '• Request resources using voice\n'
          '• Share available resources with voice\n'
          '• Get resource status updates\n\n'
          'This would be especially useful when hands-free operation is needed during emergencies.',
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

  /// Shows success message
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Data model for resource items
class ResourceItem {
  final String name;
  final String description;
  final int availableCount;
  final int requestedCount;
  final IconData icon;
  final Color color;

  ResourceItem({
    required this.name,
    required this.description,
    required this.availableCount,
    required this.requestedCount,
    required this.icon,
    required this.color,
  });
}
