import 'package:flutter/material.dart';
import '../main.dart';

/// Landing page - the first screen users see when opening the app
/// Provides two main options: Join existing emergency communication or start new one
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with BEACON title
      appBar: AppBar(
        title: const Text(
          'BEACON',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      // Main content area
      body: Container(
        // Add a subtle background gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF5F5), // Light red tint
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo/icon section
                const Icon(Icons.emergency, size: 80, color: Colors.red),
                const SizedBox(height: 20),

                // App title and description
                const Text(
                  'BEACON',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 10),

                const Text(
                  'Disaster Response Communication',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),

                // Main action buttons
                _buildActionButton(
                  context: context,
                  title: 'Join Emergency Communication',
                  subtitle: 'Connect to existing emergency network',
                  icon: Icons.group_add,
                  onPressed: () => _navigateToDashboard(context),
                ),
                const SizedBox(height: 20),

                _buildActionButton(
                  context: context,
                  title: 'Start New Communication',
                  subtitle: 'Create a new emergency network',
                  icon: Icons.add_circle_outline,
                  onPressed: () => _navigateToDashboard(context),
                ),
                const SizedBox(height: 40),

                // Additional info text
                const Text(
                  'Stay connected during emergencies',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a styled action button for the landing page
  Widget _buildActionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.red, size: 28),
              ),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigates to the main dashboard (both buttons lead to the same place)
  void _navigateToDashboard(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationPage()),
    );
  }
}
