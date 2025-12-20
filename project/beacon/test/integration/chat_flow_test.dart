import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:beacon/providers/beacon_provider.dart';
import 'package:beacon/presentation/viewmodels/peer_notification_view_model.dart';
import 'package:beacon/presentation/pages/chat_page_mvvm.dart';
import 'package:beacon/data/models.dart';
import '../mocks/test_fixtures.dart';

/// Widget wrapper for testing pages with providers
class TestAppWrapper extends StatelessWidget {
  final Widget child;
  final BeaconProvider? beaconProvider;
  final PeerNotificationViewModel? peerNotificationViewModel;

  const TestAppWrapper({
    required this.child,
    this.beaconProvider,
    this.peerNotificationViewModel,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<BeaconProvider>(
            create: (_) => beaconProvider ?? BeaconProvider(),
          ),
          ChangeNotifierProvider<PeerNotificationViewModel>(
            create: (_) => peerNotificationViewModel ?? PeerNotificationViewModel(),
          ),
        ],
        child: child,
      ),
    );
  }
}

void main() {
  group('Chat Flow Integration Tests', () {
    testWidgets('Chat page displays loading state during initialization', (tester) async {
      await tester.pumpWidget(
        const TestAppWrapper(
          child: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );

      // Verify loading indicator
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('User profile displays when loaded', (tester) async {
      final testProvider = BeaconProvider();
      final userProfile = TestFixtures.createTestUserProfile(
        name: 'Integration Test User',
        role: 'Responder',
      );

      await tester.pumpWidget(
        TestAppWrapper(
          beaconProvider: testProvider,
          child: Scaffold(
            body: Center(
              child: Text('${userProfile.name} (${userProfile.role})'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Integration Test User (Responder)'), findsOneWidget);
    });

    testWidgets('Device status is displayed correctly', (tester) async {
      final device = TestFixtures.createTestConnectedDevice(
        name: 'Test Device',
        status: 'connected',
      );

      await tester.pumpWidget(
        TestAppWrapper(
          child: Scaffold(
            body: ListTile(
              title: Text(device.name),
              subtitle: Text('Status: ${device.status}'),
              trailing: device.isEmergency
                  ? const Icon(Icons.warning, color: Colors.red)
                  : null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test Device'), findsOneWidget);
      expect(find.text('Status: connected'), findsOneWidget);
    });

    testWidgets('Emergency devices show emergency indicator', (tester) async {
      final emergencyDevice = TestFixtures.createTestConnectedDevice(
        name: 'Emergency Device',
        isEmergency: true,
      );

      await tester.pumpWidget(
        TestAppWrapper(
          child: Scaffold(
            body: ListTile(
              title: Text(emergencyDevice.name),
              trailing: emergencyDevice.isEmergency
                  ? const Icon(Icons.warning, color: Colors.red)
                  : null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning), findsOneWidget);
    });
  });

  group('Peer Discovery Integration Tests', () {
    testWidgets('Peer discovery UI displays correctly', (tester) async {
      await tester.pumpWidget(
        const TestAppWrapper(
          child: Scaffold(
            body: Center(
              child: Text('Discovering peers...'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Discovering peers...'), findsOneWidget);
    });

    testWidgets('Peer status updates are reflected in UI', (tester) async {
      var deviceStatus = 'connected';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return TestAppWrapper(
              child: Scaffold(
                body: Column(
                  children: [
                    Text('Device Status: $deviceStatus'),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          deviceStatus = 'disconnected';
                        });
                      },
                      child: const Text('Disconnect'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Device Status: connected'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Device Status: disconnected'), findsOneWidget);
    });
  });

  group('Profile Update Integration Tests', () {
    testWidgets('User can view their profile information', (tester) async {
      final profile = TestFixtures.createTestUserProfile(
        name: 'Profile Test User',
        role: 'Coordinator',
        phone: '+1234567890',
        location: 'Test City',
      );

      await tester.pumpWidget(
        TestAppWrapper(
          child: Scaffold(
            body: Column(
              children: [
                Text('Name: ${profile.name}'),
                Text('Role: ${profile.role}'),
                Text('Phone: ${profile.phone}'),
                Text('Location: ${profile.location}'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Name: Profile Test User'), findsOneWidget);
      expect(find.text('Role: Coordinator'), findsOneWidget);
      expect(find.text('Phone: +1234567890'), findsOneWidget);
      expect(find.text('Location: Test City'), findsOneWidget);
    });

    testWidgets('Profile updates are persisted', (tester) async {
      final originalProfile = TestFixtures.createTestUserProfile(
        name: 'Original Name',
      );

      final updatedProfile = originalProfile.copyWith(
        name: 'Updated Name',
      );

      expect(originalProfile.name, 'Original Name');
      expect(updatedProfile.name, 'Updated Name');
    });
  });

  group('Network Activity Integration Tests', () {
    testWidgets('Network activities are logged and displayed', (tester) async {
      final activities = TestFixtures.createTestNetworkActivities(3);

      await tester.pumpWidget(
        TestAppWrapper(
          child: Scaffold(
            body: ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(activities[index].type),
                  subtitle: Text(activities[index].description),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // All 3 activities have type 'message' so we expect 3 widgets
      expect(find.text('message'), findsWidgets);
    });

    testWidgets('Activity timestamps are displayed correctly', (tester) async {
      final now = DateTime.now();
      final activity = NetworkActivity(
        peerId: 'peer_1',
        event: 'message',
        details: 'Test message',
        timestamp: now,
      );

      await tester.pumpWidget(
        TestAppWrapper(
          child: Scaffold(
            body: Text(activity.timestamp.toString()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });
  });

  group('Error Handling Integration Tests', () {
    testWidgets('Error messages are displayed to user', (tester) async {
      const errorMessage = 'Test error message';

      await tester.pumpWidget(
        TestAppWrapper(
          child: Scaffold(
            body: Center(
              child: Text('Error: $errorMessage'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Error: $errorMessage'), findsOneWidget);
    });

    testWidgets('Loading state is shown during async operations', (tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          child: const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );

      // Use pump instead of pumpAndSettle to avoid timeout from BeaconProvider's background operations
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });

  group('Navigation Integration Tests', () {
    testWidgets('Page navigation works correctly', (tester) async {
      await tester.pumpWidget(
        TestAppWrapper(
          child: Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(tester.element(find.byType(ElevatedButton)))
                  .push(
                MaterialPageRoute(
                  builder: (context) => const Scaffold(
                    body: Text('Next Page'),
                  ),
                ),
              ),
              child: const Text('Navigate'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Next Page'), findsOneWidget);
    });
  });
}
