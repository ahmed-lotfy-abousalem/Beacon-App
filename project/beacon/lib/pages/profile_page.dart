import 'package:flutter/material.dart';

/// Profile Page - User profile management and emergency contact setup
/// Allows users to view and edit their profile information and emergency contacts
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Mock user data
  final String _userName = 'John Doe';
  final String _userEmail = 'john.doe@example.com';
  final String _userPhone = '+1 (555) 123-4567';
  final String _userLocation = 'Emergency Zone Alpha';
  final String _userRole = 'Civilian';
  
  // Mock emergency contacts
  final List<EmergencyContact> _emergencyContacts = [
    EmergencyContact(
      name: 'Jane Doe',
      relationship: 'Spouse',
      phone: '+1 (555) 987-6543',
      isPrimary: true,
    ),
    EmergencyContact(
      name: 'Dr. Smith',
      relationship: 'Family Doctor',
      phone: '+1 (555) 456-7890',
      isPrimary: false,
    ),
    EmergencyContact(
      name: 'Emergency Services',
      relationship: 'Emergency Contact',
      phone: '911',
      isPrimary: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with profile title and voice command button
      appBar: AppBar(
        title: const Text('Profile'),
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
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header section
            _buildProfileHeader(),
            const SizedBox(height: 24),
            
            // Personal information section
            _buildPersonalInfoSection(),
            const SizedBox(height: 24),
            
            // Emergency contacts section
            _buildEmergencyContactsSection(),
            const SizedBox(height: 24),
            
            // Emergency settings section
            _buildEmergencySettingsSection(),
            const SizedBox(height: 24),
            
            // App settings section
            _buildAppSettingsSection(),
          ],
        ),
      ),
    );
  }

  /// Builds the profile header with user avatar and basic info
  Widget _buildProfileHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.red,
              child: Text(
                _userName.split(' ').map((name) => name[0]).join(''),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // User name and role
            Text(
              _userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Text(
                _userRole,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Edit profile button
            ElevatedButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the personal information section
  Widget _buildPersonalInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(Icons.person, 'Name', _userName),
            _buildInfoRow(Icons.email, 'Email', _userEmail),
            _buildInfoRow(Icons.phone, 'Phone', _userPhone),
            _buildInfoRow(Icons.location_on, 'Location', _userLocation),
          ],
        ),
      ),
    );
  }

  /// Builds the emergency contacts section
  Widget _buildEmergencyContactsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addEmergencyContact,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // List of emergency contacts
            ..._emergencyContacts.map((contact) => _buildContactCard(contact)),
          ],
        ),
      ),
    );
  }

  /// Builds the emergency settings section
  Widget _buildEmergencySettingsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildSettingSwitch(
              'Auto-share location during emergencies',
              true,
              Icons.location_on,
            ),
            _buildSettingSwitch(
              'Send emergency alerts to contacts',
              true,
              Icons.notifications,
            ),
            _buildSettingSwitch(
              'Enable voice commands',
              false,
              Icons.mic,
            ),
            _buildSettingSwitch(
              'Share medical information with responders',
              false,
              Icons.medical_services,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the app settings section
  Widget _buildAppSettingsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              subtitle: const Text('Manage notification preferences'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showNotificationSettings,
            ),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Privacy & Security'),
              subtitle: const Text('Manage your privacy settings'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showPrivacySettings,
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              subtitle: const Text('Get help and contact support'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showHelpSupport,
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About BEACON'),
              subtitle: const Text('App version and information'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showAboutApp,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an information row with icon, label, and value
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a contact card for emergency contacts
  Widget _buildContactCard(EmergencyContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: contact.isPrimary ? Colors.red.withOpacity(0.1) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: contact.isPrimary ? Colors.red : Colors.blue,
          child: Icon(
            contact.isPrimary ? Icons.star : Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          contact.name,
          style: TextStyle(
            fontWeight: contact.isPrimary ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.relationship),
            Text(contact.phone),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contact.isPrimary)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'PRIMARY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            IconButton(
              onPressed: () => _editEmergencyContact(contact),
              icon: const Icon(Icons.edit, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a setting switch row
  Widget _buildSettingSwitch(String title, bool value, IconData icon) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      value: value,
      onChanged: (newValue) {
        // In a real app, this would save the setting
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title setting updated'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }

  /// Shows edit profile dialog
  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Name'),
              controller: TextEditingController(text: _userName),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Email'),
              controller: TextEditingController(text: _userEmail),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Phone'),
              controller: TextEditingController(text: _userPhone),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Location'),
              controller: TextEditingController(text: _userLocation),
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
              _showSuccessMessage('Profile updated successfully!');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Shows add emergency contact dialog
  void _addEmergencyContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Relationship'),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Phone Number'),
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
              _showSuccessMessage('Emergency contact added!');
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Shows edit emergency contact dialog
  void _editEmergencyContact(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Name'),
              controller: TextEditingController(text: contact.name),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Relationship'),
              controller: TextEditingController(text: contact.relationship),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Phone Number'),
              controller: TextEditingController(text: contact.phone),
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
              _showSuccessMessage('Emergency contact updated!');
            },
            child: const Text('Save'),
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
          '• Update profile information using voice\n'
          '• Add emergency contacts with voice\n'
          '• Change emergency settings with voice commands\n\n'
          'This would be especially useful for accessibility and hands-free operation.',
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

  /// Shows various settings dialogs (placeholder implementations)
  void _showNotificationSettings() {
    _showPlaceholderDialog('Notification Settings', 'Manage your notification preferences here.');
  }

  void _showPrivacySettings() {
    _showPlaceholderDialog('Privacy & Security', 'Manage your privacy and security settings here.');
  }

  void _showHelpSupport() {
    _showPlaceholderDialog('Help & Support', 'Get help and contact support here.');
  }

  void _showAboutApp() {
    _showPlaceholderDialog('About BEACON', 'BEACON v1.0.0\nDisaster Response Communication App');
  }

  /// Shows a placeholder dialog for settings
  void _showPlaceholderDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
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

/// Data model for emergency contacts
class EmergencyContact {
  final String name;
  final String relationship;
  final String phone;
  final bool isPrimary;

  EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
    required this.isPrimary,
  });
}
