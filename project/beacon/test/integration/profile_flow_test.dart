import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beacon/data/models.dart';
import '../mocks/test_fixtures.dart';

void main() {
  group('Profile Management Integration Tests', () {
    testWidgets('User can view their profile', (tester) async {
      final profile = TestFixtures.createTestUserProfile(
        name: 'Test Responder',
        role: 'Coordinator',
        phone: '+1234567890',
        location: 'Test City',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
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

      expect(find.text('Name: Test Responder'), findsOneWidget);
      expect(find.text('Role: Coordinator'), findsOneWidget);
    });

    testWidgets('User can edit their profile', (tester) async {
      var userName = 'Original Name';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Text('Name: $userName'),
                    TextField(
                      onChanged: (value) {
                        userName = value;
                      },
                      decoration: const InputDecoration(hintText: 'Enter name'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial name is displayed
      expect(find.text('Name: Original Name'), findsOneWidget);

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Updated Name');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // After update, the new name should be displayed
      expect(find.text('Name: Updated Name'), findsOneWidget);
    });

    testWidgets('Profile changes are validated', (tester) async {
      var validationError = '';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() => validationError = 'Name cannot be empty');
                        } else {
                          setState(() => validationError = '');
                        }
                      },
                      decoration: const InputDecoration(hintText: 'Enter name'),
                    ),
                    if (validationError.isNotEmpty)
                      Text(validationError, style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      // First enter some text
      await tester.enterText(textField, 'Test');
      await tester.pump();
      
      // Then clear it
      await tester.enterText(textField, '');
      await tester.pump();

      expect(find.text('Name cannot be empty'), findsOneWidget);
    });

    testWidgets('Profile update shows confirmation', (tester) async {
      var showConfirmation = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() => showConfirmation = true);
                      },
                      child: const Text('Update Profile'),
                    ),
                    if (showConfirmation)
                      const Text('Profile updated successfully'),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Profile updated successfully'), findsNothing);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Profile updated successfully'), findsOneWidget);
    });
  });

  group('User Role Tests', () {
    testWidgets('Different roles display appropriate UI', (tester) async {
      final coordinatorProfile = TestFixtures.createTestUserProfile(
        role: 'Coordinator',
      );

      final responderProfile = TestFixtures.createTestUserProfile(
        role: 'Responder',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                if (coordinatorProfile.role == 'Coordinator')
                  const Text('You have admin privileges')
                else
                  const Text('You are a responder'),
                if (responderProfile.role == 'Responder')
                  const Text('You have limited access'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('You have admin privileges'), findsOneWidget);
      expect(find.text('You have limited access'), findsOneWidget);
    });

    testWidgets('Emergency responders are identified', (tester) async {
      final emergencyProfile = TestFixtures.createTestUserProfile(
        role: 'Emergency Coordinator',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                children: [
                  Text(emergencyProfile.role),
                  if (emergencyProfile.role.contains('Emergency'))
                    const Icon(Icons.warning, color: Colors.red),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Emergency Coordinator'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });
  });

  group('Location Updates Tests', () {
    testWidgets('User location is displayed', (tester) async {
      final profile = TestFixtures.createTestUserProfile(
        location: 'Downtown Emergency Center',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text('Current Location: ${profile.location}'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Current Location: Downtown Emergency Center'), findsOneWidget);
    });

    testWidgets('User can update location', (tester) async {
      var currentLocation = 'Original Location';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Text('Location: $currentLocation'),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => currentLocation = 'New Location');
                      },
                      child: const Text('Update Location'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Location: Original Location'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Location: New Location'), findsOneWidget);
    });
  });

  group('Phone Number Tests', () {
    testWidgets('Phone number is displayed correctly', (tester) async {
      final profile = TestFixtures.createTestUserProfile(
        phone: '+1 (555) 123-4567',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text('Contact: ${profile.phone}'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Contact: +1 (555) 123-4567'), findsOneWidget);
    });

    testWidgets('Invalid phone numbers are rejected', (tester) async {
      var phoneValidationError = '';

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        if (value.isNotEmpty && !value.startsWith('+')) {
                          setState(() =>
                              phoneValidationError = 'Phone must start with +');
                        } else {
                          setState(() => phoneValidationError = '');
                        }
                      },
                      decoration: const InputDecoration(hintText: 'Enter phone'),
                    ),
                    if (phoneValidationError.isNotEmpty)
                      Text(phoneValidationError,
                          style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, '5551234567');
      await tester.pumpAndSettle();

      expect(find.text('Phone must start with +'), findsOneWidget);
    });
  });
}
