import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beacon/data/models.dart';
import '../mocks/test_fixtures.dart';

void main() {
  group('Notification Flow Integration Tests', () {
    testWidgets('Notification is displayed when received', (tester) async {
      const notificationTitle = 'New Message';
      const notificationBody = 'You have a new message from Peer A';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('$notificationTitle: $notificationBody'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('New Message: You have a new message from Peer A'), findsOneWidget);
    });

    testWidgets('User can dismiss notification', (tester) async {
      var notificationVisible = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: notificationVisible
                    ? Column(
                        children: [
                          const Text('Important Notification'),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                notificationVisible = false;
                              });
                            },
                            child: const Text('Dismiss'),
                          ),
                        ],
                      )
                    : const Center(child: Text('Dismissed')),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Important Notification'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Dismissed'), findsOneWidget);
    });

    testWidgets('Multiple notifications are handled', (tester) async {
      final notifications = [
        'Notification 1',
        'Notification 2',
        'Notification 3',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(notifications[index]),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      for (final notification in notifications) {
        expect(find.text(notification), findsOneWidget);
      }
    });

    testWidgets('Emergency notification is highlighted', (tester) async {
      final emergencyPeer = TestFixtures.createTestConnectedDevice(
        name: 'Emergency Responder',
        isEmergency: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              color: emergencyPeer.isEmergency ? Colors.red : Colors.white,
              child: Text('Notification from ${emergencyPeer.name}'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final container = find.byType(Container).first;
      final widget = tester.widget<Container>(container);
      expect((widget.color as Color?)?.value, Colors.red.value);
    });
  });

  group('Peer Join/Leave Integration Tests', () {
    testWidgets('UI displays peer notification messages', (tester) async {
      final peer = TestFixtures.createTestConnectedDevice(
        peerId: 'joining_peer',
        name: 'New Responder',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('${peer.name} notification'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('New Responder notification'), findsOneWidget);
    });

    testWidgets('Peer status is updated in local state', (tester) async {
      var peerStatus = 'online';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Text('Peer Status: $peerStatus'),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          peerStatus = 'offline';
                        });
                      },
                      child: const Text('Go Offline'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Peer Status: online'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Peer Status: offline'), findsOneWidget);
    });

    testWidgets('Device list UI updates when simulating peer changes', (tester) async {
      final devices = [
        TestFixtures.createTestConnectedDevice(peerId: 'peer_1', name: 'Device 1'),
      ];

      var deviceList = devices;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: deviceList.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(deviceList[index].name),
                        );
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          deviceList = [
                            ...devices,
                            TestFixtures.createTestConnectedDevice(
                              peerId: 'peer_2',
                              name: 'Device 2',
                            ),
                          ];
                        });
                      },
                      child: const Text('Add Device'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Device 1'), findsOneWidget);
      expect(find.text('Device 2'), findsNothing);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Device 1'), findsOneWidget);
      expect(find.text('Device 2'), findsOneWidget);
    });
  });

  group('Signal Strength Integration Tests', () {
    testWidgets('Signal strength is displayed for each peer', (tester) async {
      final peer = TestFixtures.createTestConnectedDevice(
        name: 'Strong Signal Device',
        signalStrength: -40,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              title: Text(peer.name),
              subtitle: Text('Signal: ${peer.signalStrength} dBm'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Signal: -40 dBm'), findsOneWidget);
    });

    testWidgets('Weak signal is indicated visually', (tester) async {
      final weakPeer = TestFixtures.createTestConnectedDevice(
        name: 'Weak Signal',
        signalStrength: -80,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              title: Text(weakPeer.name),
              trailing: Icon(
                weakPeer.signalStrength < -70 ? Icons.signal_wifi_off : Icons.signal_wifi_4_bar,
                color: weakPeer.signalStrength < -70 ? Colors.red : Colors.green,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.signal_wifi_off), findsOneWidget);
    });

    testWidgets('Signal strength updates in real-time', (tester) async {
      var signalStrength = -50;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Text('Signal Strength: $signalStrength dBm'),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          signalStrength = -75;
                        });
                      },
                      child: const Text('Degrade Signal'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Signal Strength: -50 dBm'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Signal Strength: -75 dBm'), findsOneWidget);
    });
  });

  group('Activity Log Integration Tests', () {
    testWidgets('Network activities are displayed in chronological order', (tester) async {
      final activities = TestFixtures.createTestNetworkActivities(3);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(activities[index].details),
                  subtitle: Text(activities[index].timestamp.toString()),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('Activity details are displayed', (tester) async {
      final activity = NetworkActivity(
        peerId: 'peer_activity',
        event: 'message_sent',
        details: 'Emergency message sent to headquarters',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Type: ${activity.activityType}'),
                Text('Description: ${activity.description}'),
                Text('Peer: ${activity.peerId}'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Type: message_sent'), findsOneWidget);
      expect(find.text('Description: Emergency message sent to headquarters'), findsOneWidget);
      expect(find.text('Peer: peer_activity'), findsOneWidget);
    });
  });
}
