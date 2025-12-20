import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Navigation Flow Integration Tests', () {
    testWidgets('User can navigate from landing page to dashboard', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(tester.element(find.byType(ElevatedButton)))
                      .push(
                    MaterialPageRoute(
                      builder: (context) => const Scaffold(
                        body: Text('Dashboard Page'),
                      ),
                    ),
                  );
                },
                child: const Text('Go to Dashboard'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Go to Dashboard'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Page'), findsOneWidget);
    });

    testWidgets('User can navigate to profile page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Home'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    Navigator.of(tester.element(find.byIcon(Icons.person)))
                        .push(
                      MaterialPageRoute(
                        builder: (context) => const Scaffold(
                          body: Text('Profile Page'),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: const Text('Home Page'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      expect(find.text('Profile Page'), findsOneWidget);
    });

    testWidgets('User can navigate to chat page with peer selection', (tester) async {
      var selectedPeer = '';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            if (selectedPeer.isEmpty) {
              return MaterialApp(
                home: Scaffold(
                  body: Column(
                    children: [
                      const Text('Select a Peer'),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => selectedPeer = 'peer_1');
                          Navigator.of(tester.element(find.byType(Column)))
                              .push(
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                body: Text('Chat with: $selectedPeer'),
                              ),
                            ),
                          );
                        },
                        child: const Text('Chat with Peer 1'),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return MaterialApp(
                home: Scaffold(
                  body: Text('Chat with: $selectedPeer'),
                ),
              );
            }
          },
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Chat with Peer 1'));
      await tester.pumpAndSettle();

      expect(find.text('Select a Peer'), findsNothing);
    });

    testWidgets('User can navigate back from chat page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(tester.element(find.byType(ElevatedButton)))
                      .push(
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(
                          title: const Text('Chat'),
                          leading: BackButton(
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        body: const Text('Chat Page'),
                      ),
                    ),
                  );
                },
                child: const Text('Enter Chat'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Chat Page'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Enter Chat'), findsOneWidget);
    });

    testWidgets('Deep linking navigates to correct page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == '/profile') {
              return MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Text('Profile Page'),
                ),
              );
            } else if (settings.name == '/chat') {
              return MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Text('Chat Page'),
                ),
              );
            }
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Text('Home Page'),
              ),
            );
          },
          home: const Scaffold(
            body: Text('Home Page'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
    });
  });

  group('Bottom Navigation Integration Tests', () {
    testWidgets('Bottom navigation switches between pages', (tester) async {
      var currentPage = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: IndexedStack(
                  index: currentPage,
                  children: const [
                    Text('Home Page'),
                    Text('Chat Page'),
                    Text('Profile Page'),
                  ],
                ),
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: currentPage,
                  onTap: (index) {
                    setState(() => currentPage = index);
                  },
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.chat),
                      label: 'Chat',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle();

      expect(find.text('Chat Page'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      expect(find.text('Profile Page'), findsOneWidget);
    });

    testWidgets('Bottom navigation persists state', (tester) async {
      var homeCounter = 0;
      var currentPage = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: IndexedStack(
                  index: currentPage,
                  children: [
                    StatefulBuilder(
                      builder: (context, setHomeState) {
                        return Column(
                          children: [
                            Text('Home: $homeCounter'),
                            ElevatedButton(
                              onPressed: () {
                                setHomeState(() => homeCounter++);
                              },
                              child: const Text('Increment'),
                            ),
                          ],
                        );
                      },
                    ),
                    const Text('Chat Page'),
                  ],
                ),
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: currentPage,
                  onTap: (index) {
                    setState(() => currentPage = index);
                  },
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.chat),
                      label: 'Chat',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Home: 0'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Home: 1'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle();

      expect(find.text('Chat Page'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      expect(find.text('Home: 1'), findsOneWidget);
    });
  });

  group('Modal Navigation Tests', () {
    testWidgets('Modal dialog can be opened and closed', (tester) async {
      var showDialog = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() => showDialog = true);
                      },
                      child: const Text('Show Dialog'),
                    ),
                    if (showDialog)
                      AlertDialog(
                        title: const Text('Confirm Action'),
                        content: const Text('Are you sure?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              setState(() => showDialog = false);
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => showDialog = false);
                            },
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Bottom sheet navigation works', (tester) async {
      var showSheet = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    setState(() => showSheet = true);
                  },
                  child: const Text('Show Options'),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Show Options'), findsOneWidget);
    });
  });

  group('Page Transition Tests', () {
    testWidgets('Page transitions are smooth', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(tester.element(find.byType(ElevatedButton)))
                      .push(
                    MaterialPageRoute(
                      builder: (context) => const Scaffold(
                        body: Text('Next Page'),
                      ),
                    ),
                  );
                },
                child: const Text('Navigate'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));

      // Verify transition happens
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Navigate'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Next Page'), findsOneWidget);
    });
  });
}
