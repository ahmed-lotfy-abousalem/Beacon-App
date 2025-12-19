import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/landing_page.dart';
import 'pages/network_dashboard_page.dart';
import 'pages/resource_page.dart';
import 'pages/profile_page.dart';
import 'providers/beacon_provider.dart';
import 'presentation/viewmodels/peer_notification_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BeaconApp());
}

/// Main application widget for BEACON disaster response communication app
class BeaconApp extends StatelessWidget {
  const BeaconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BeaconProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => PeerNotificationViewModel()..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'BEACON',
        theme: ThemeData(
          // Using a red color scheme to represent emergency/disaster response
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.red,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          // Custom app bar theme for consistent styling
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
        ),
        // Start with the landing page
        home: const _NotificationListener(child: LandingPage()),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Wrapper widget to listen for peer notifications globally
class _NotificationListener extends StatefulWidget {
  final Widget child;

  const _NotificationListener({required this.child});

  @override
  State<_NotificationListener> createState() => _NotificationListenerState();
}

class _NotificationListenerState extends State<_NotificationListener> {
  late PeerNotificationViewModel _notificationViewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('🌐 _NotificationListener.didChangeDependencies() called');
    _notificationViewModel =
        Provider.of<PeerNotificationViewModel>(context, listen: false);

    print('✅ Got PeerNotificationViewModel: ${_notificationViewModel.hashCode}');

    // Set up the callback to show snackbars
    _notificationViewModel.onPeerJoined = (device) {
      print('🔔 _NotificationListener.onPeerJoined callback triggered: ${device.name}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${device.name} has joined the network'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        print('✅ Global: Showed snackbar for peer joined: ${device.name}');
      }
    };

    _notificationViewModel.onPeerLeft = (device) {
      print('🔔 _NotificationListener.onPeerLeft callback triggered: ${device.name}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${device.name} has left the network'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        print('✅ Global: Showed snackbar for peer left: ${device.name}');
      }
    };
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        // Use red theme to match emergency/disaster response theme
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
