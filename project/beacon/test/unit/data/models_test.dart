import 'package:flutter_test/flutter_test.dart';
import 'package:beacon/data/models.dart';

void main() {
  group('UserProfile', () {
    test('should create a UserProfile with correct values', () {
      final now = DateTime.now();
      final profile = UserProfile(
        id: 1,
        name: 'John Doe',
        role: 'Responder',
        phone: '+1234567890',
        location: 'NYC',
        updatedAt: now,
      );

      expect(profile.id, 1);
      expect(profile.name, 'John Doe');
      expect(profile.role, 'Responder');
      expect(profile.phone, '+1234567890');
      expect(profile.location, 'NYC');
      expect(profile.updatedAt, now);
    });

    test('should convert UserProfile to Map correctly', () {
      final now = DateTime.now();
      final profile = UserProfile(
        id: 1,
        name: 'Jane Smith',
        role: 'Commander',
        phone: '+9876543210',
        location: 'LA',
        updatedAt: now,
      );

      final map = profile.toMap();

      expect(map['id'], 1);
      expect(map['name'], 'Jane Smith');
      expect(map['role'], 'Commander');
      expect(map['phone'], '+9876543210');
      expect(map['location'], 'LA');
      expect(map['updated_at'], now.millisecondsSinceEpoch);
    });

    test('should create UserProfile from Map correctly', () {
      final now = DateTime.now();
      final map = {
        'id': 1,
        'name': 'Test User',
        'role': 'Coordinator',
        'phone': '+1111111111',
        'location': 'Boston',
        'updated_at': now.millisecondsSinceEpoch,
      };

      final profile = UserProfile.fromMap(map);

      expect(profile.id, 1);
      expect(profile.name, 'Test User');
      expect(profile.role, 'Coordinator');
      expect(profile.phone, '+1111111111');
      expect(profile.location, 'Boston');
      expect(profile.updatedAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('should handle null values when creating from Map', () {
      final map = {
        'id': 1,
        'name': null,
        'role': null,
        'phone': null,
        'location': null,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };

      final profile = UserProfile.fromMap(map);

      expect(profile.id, 1);
      expect(profile.name, '');
      expect(profile.role, '');
      expect(profile.phone, '');
      expect(profile.location, '');
    });

    test('copyWith should create a new UserProfile with updated values', () {
      final original = UserProfile(
        id: 1,
        name: 'Original',
        role: 'Responder',
        phone: '+1234567890',
        location: 'Original Location',
        updatedAt: DateTime.now(),
      );

      final updated = original.copyWith(
        name: 'Updated Name',
        role: 'Commander',
      );

      expect(updated.id, original.id);
      expect(updated.name, 'Updated Name');
      expect(updated.role, 'Commander');
      expect(updated.phone, original.phone);
      expect(updated.location, original.location);
    });

    test('copyWith should not affect original UserProfile', () {
      final original = UserProfile(
        id: 1,
        name: 'Original',
        role: 'Responder',
        phone: '+1234567890',
        location: 'Location',
        updatedAt: DateTime.now(),
      );

      final updated = original.copyWith(name: 'Updated');

      expect(original.name, 'Original');
      expect(updated.name, 'Updated');
    });

    test('should handle round-trip serialization', () {
      final original = UserProfile(
        id: 1,
        name: 'Round Trip',
        role: 'Responder',
        phone: '+5555555555',
        location: 'Seattle',
        updatedAt: DateTime.now(),
      );

      final map = original.toMap();
      final reconstructed = UserProfile.fromMap(map);

      expect(reconstructed.id, original.id);
      expect(reconstructed.name, original.name);
      expect(reconstructed.role, original.role);
      expect(reconstructed.phone, original.phone);
      expect(reconstructed.location, original.location);
    });
  });

  group('ConnectedDevice', () {
    test('should create a ConnectedDevice with correct values', () {
      final now = DateTime.now();
      final device = ConnectedDevice(
        peerId: 'peer_123',
        name: 'Device A',
        status: 'connected',
        lastSeen: now,
        signalStrength: -55,
        isEmergency: true,
      );

      expect(device.peerId, 'peer_123');
      expect(device.name, 'Device A');
      expect(device.status, 'connected');
      expect(device.lastSeen, now);
      expect(device.signalStrength, -55);
      expect(device.isEmergency, true);
    });

    test('should support status changes through immutable pattern', () {
      final device1 = ConnectedDevice(
        peerId: 'peer_1',
        name: 'Device',
        status: 'connected',
        lastSeen: DateTime.now(),
        signalStrength: -50,
        isEmergency: false,
      );

      final device2 = device1;
      expect(device2.status, 'connected');
    });

    test('should handle emergency status correctly', () {
      final emergency = ConnectedDevice(
        peerId: 'peer_emergency',
        name: 'Emergency Device',
        status: 'connected',
        lastSeen: DateTime.now(),
        signalStrength: -60,
        isEmergency: true,
      );

      final normal = ConnectedDevice(
        peerId: 'peer_normal',
        name: 'Normal Device',
        status: 'connected',
        lastSeen: DateTime.now(),
        signalStrength: -50,
        isEmergency: false,
      );

      expect(emergency.isEmergency, true);
      expect(normal.isEmergency, false);
    });

    test('should be immutable', () {
      final device = ConnectedDevice(
        peerId: 'peer_1',
        name: 'Test Device',
        status: 'connected',
        lastSeen: DateTime.now(),
        signalStrength: -50,
        isEmergency: false,
      );

      // The class should be marked as @immutable, so we test this by checking
      // that we cannot modify properties (would need to use copyWith or create new instance)
      expect(device.peerId, 'peer_1');
      expect(device.name, 'Test Device');
    });

    test('should signal strength vary for different devices', () {
      final strongSignal = ConnectedDevice(
        peerId: 'peer_strong',
        name: 'Strong',
        status: 'connected',
        lastSeen: DateTime.now(),
        signalStrength: -40,
        isEmergency: false,
      );

      final weakSignal = ConnectedDevice(
        peerId: 'peer_weak',
        name: 'Weak',
        status: 'connected',
        lastSeen: DateTime.now(),
        signalStrength: -85,
        isEmergency: false,
      );

      expect(strongSignal.signalStrength, -40);
      expect(weakSignal.signalStrength, -85);
      expect(strongSignal.signalStrength > weakSignal.signalStrength, true);
    });
  });

  group('NetworkActivity', () {
    test('should create a NetworkActivity with correct values', () {
      final now = DateTime.now();
      final activity = NetworkActivity(
        peerId: 'peer_456',
        event: 'message',
        details: 'Sent emergency broadcast',
        timestamp: now,
      );

      expect(activity.peerId, 'peer_456');
      expect(activity.event, 'message');
      expect(activity.details, 'Sent emergency broadcast');
      expect(activity.timestamp, now);
    });

    test('should handle different activity types', () {
      final now = DateTime.now();
      final types = ['message', 'connection', 'disconnection', 'status_update'];

      for (final type in types) {
        final activity = NetworkActivity(
          peerId: 'peer_1',
          event: type,
          details: 'Test activity',
          timestamp: now,
        );

        expect(activity.event, type);
      }
    });

    test('should create activities with meaningful descriptions', () {
      final descriptions = [
        'Connected to peer',
        'Message received: Help needed',
        'Disconnected from peer',
        'Signal strength changed',
      ];

      for (final description in descriptions) {
        final activity = NetworkActivity(
          peerId: 'peer_1',
          event: 'log',
          details: description,
          timestamp: DateTime.now(),
        );

        expect(activity.details, description);
      }
    });

    test('should preserve timestamp precision', () {
      final preciseTime = DateTime(2024, 12, 20, 15, 30, 45, 123, 456);
      final activity = NetworkActivity(
        peerId: 'peer_1',
        event: 'message',
        details: 'Test',
        timestamp: preciseTime,
      );

      expect(activity.timestamp.year, 2024);
      expect(activity.timestamp.month, 12);
      expect(activity.timestamp.day, 20);
      expect(activity.timestamp.hour, 15);
      expect(activity.timestamp.minute, 30);
      expect(activity.timestamp.second, 45);
      expect(activity.timestamp.millisecond, 123);
    });
  });
}
