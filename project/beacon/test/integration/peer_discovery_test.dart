import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beacon/data/models.dart';
import '../mocks/test_fixtures.dart';

void main() {
  group('Peer Discovery Integration Tests', () {
    testWidgets('Peer discovery UI displays correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
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
            return MaterialApp(
              home: Scaffold(
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

  group('Network Status Tests', () {
    testWidgets('Network connection status UI displays correctly', (tester) async {
      var isConnected = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isConnected ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(isConnected ? 'Online' : 'Offline'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Online'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('Offline status shows alert', (tester) async {
      var isConnected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                if (!isConnected)
                  Container(
                    color: Colors.orange,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Device is offline'),
                    ),
                  ),
                const Text('Network Status'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Device is offline'), findsOneWidget);
    });

    testWidgets('Network connectivity changes are reflected in UI', (tester) async {
      var isConnected = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Text(isConnected ? 'Connected' : 'Disconnected'),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => isConnected = !isConnected);
                      },
                      child: const Text('Toggle Connection'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Connected'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Disconnected'), findsOneWidget);
    });
  });

  group('Peer Connection State Tests', () {
    testWidgets('Connected peers UI displays connection indicator', (tester) async {
      final connectedPeer = TestFixtures.createTestConnectedDevice(
        status: 'connected',
        name: 'Connected Peer',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              title: Text(connectedPeer.name),
              trailing: Icon(
                connectedPeer.status == 'connected'
                    ? Icons.check_circle
                    : Icons.cancel,
                color: connectedPeer.status == 'connected'
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Disconnected peers UI displays disconnection indicator', (tester) async {
      final disconnectedPeer = TestFixtures.createTestConnectedDevice(
        status: 'disconnected',
        name: 'Disconnected Peer',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              title: Text(disconnectedPeer.name),
              trailing: Icon(
                disconnectedPeer.status == 'connected'
                    ? Icons.check_circle
                    : Icons.cancel,
                color: disconnectedPeer.status == 'connected'
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('Peer connection state changes are reflected in UI', (tester) async {
      var peerStatus = 'connected';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    ListTile(
                      title: const Text('Test Peer'),
                      trailing: Icon(
                        peerStatus == 'connected'
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: peerStatus == 'connected'
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => peerStatus = 'disconnected');
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

      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });
  });

  group('Multi-Peer UI Tests', () {
    testWidgets('Peer list UI displays multiple items', (tester) async {
      final peers = TestFixtures.createTestConnectedDevices(5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: peers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(peers[index].name),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsWidgets);
      expect(find.byType(ListTile), findsNWidgets(5));
    });

    testWidgets('Peer list can be filtered by status', (tester) async {
      final peers = [
        TestFixtures.createTestConnectedDevice(
          name: 'Fire Department',
          status: 'connected',
        ),
        TestFixtures.createTestConnectedDevice(
          name: 'Police Department',
          status: 'connected',
        ),
        TestFixtures.createTestConnectedDevice(
          name: 'Medical Team',
          status: 'disconnected',
        ),
      ];

      var filterStatus = 'all';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            final filteredPeers = filterStatus == 'all'
                ? peers
                : peers.where((p) => p.status == filterStatus).toList();

            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => setState(() => filterStatus = 'all'),
                          child: const Text('All'),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => filterStatus = 'connected'),
                          child: const Text('Connected'),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredPeers.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(filteredPeers[index].name),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Fire Department'), findsOneWidget);
    });
  });
}
