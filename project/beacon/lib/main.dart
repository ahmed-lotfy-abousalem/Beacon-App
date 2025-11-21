import 'package:flutter/material.dart';
import 'pages/landing_page.dart';
import 'pages/network_dashboard_page.dart';
import 'pages/chat_page.dart';
import 'pages/resource_page.dart';
import 'pages/profile_page.dart';

void main() {
  runApp(const BeaconApp());
}

/// Main application widget for BEACON disaster response communication app
class BeaconApp extends StatelessWidget {
  const BeaconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BEACON',
      theme: ThemeData(
        // Using a red color scheme to represent emergency/disaster response
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // Custom app bar theme for consistent styling
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      // Start with the landing page
      home: const LandingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Main navigation widget that handles bottom navigation between main sections
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  // Current selected index for bottom navigation
  int _currentIndex = 0;

  // List of main pages accessible via bottom navigation
  final List<Widget> _pages = [
    const NetworkDashboardPage(),
    const ResourcePage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Display the current page based on selected bottom navigation index
      body: _pages[_currentIndex],
      // Bottom navigation bar for switching between main sections
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        // Define the three main sections
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Resources',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        // Use red theme to match emergency/disaster response theme
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}