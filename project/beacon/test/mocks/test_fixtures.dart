import 'package:beacon/data/models.dart';

/// Test fixtures for creating test data
class TestFixtures {
  /// Create a test UserProfile
  static UserProfile createTestUserProfile({
    int id = 1,
    String name = 'Test User',
    String role = 'Responder',
    String phone = '+1234567890',
    String location = 'Test Location',
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      name: name,
      role: role,
      phone: phone,
      location: location,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Create a test ConnectedDevice
  static ConnectedDevice createTestConnectedDevice({
    String peerId = 'test_peer_1',
    String name = 'Test Peer',
    String status = 'connected',
    DateTime? lastSeen,
    int signalStrength = -50,
    bool isEmergency = false,
  }) {
    return ConnectedDevice(
      peerId: peerId,
      name: name,
      status: status,
      lastSeen: lastSeen ?? DateTime.now(),
      signalStrength: signalStrength,
      isEmergency: isEmergency,
    );
  }

  /// Create a test NetworkActivity
  static NetworkActivity createTestNetworkActivity({
    String peerId = 'test_peer_1',
    String event = 'message',
    String details = 'Test activity',
    DateTime? timestamp,
  }) {
    return NetworkActivity(
      peerId: peerId,
      event: event,
      details: details,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  /// Create multiple test ConnectedDevices
  static List<ConnectedDevice> createTestConnectedDevices(int count) {
    return List.generate(
      count,
      (index) => createTestConnectedDevice(
        peerId: 'peer_$index',
        name: 'Peer $index',
      ),
    );
  }

  /// Create multiple test NetworkActivities
  static List<NetworkActivity> createTestNetworkActivities(int count) {
    return List.generate(
      count,
      (index) => createTestNetworkActivity(
        peerId: 'peer_$index',
        details: 'Activity $index',
      ),
    );
  }
}

/// Extension methods for testing
extension DateTimeTestExtension on DateTime {
  /// Get a DateTime string in ISO format for testing
  String toIsoString() => toIso8601String();

  /// Check if two DateTimes are close enough (within 1 second)
  bool isCloseTo(DateTime other, {Duration tolerance = const Duration(seconds: 1)}) {
    return (difference(other).abs()) <= tolerance;
  }
}

/// Helper function to create a map from a UserProfile
Map<String, dynamic> userProfileToMap(UserProfile profile) {
  return profile.toMap();
}

/// Helper function to create a UserProfile from a map
UserProfile mapToUserProfile(Map<String, dynamic> map) {
  return UserProfile.fromMap(map);
}
