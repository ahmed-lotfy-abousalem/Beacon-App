import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beacon/data/database_service.dart';
import 'package:beacon/data/models.dart';

/// Mock implementation of DatabaseService for testing
class MockDatabaseService extends Mock implements DatabaseService {
  final Map<String, UserProfile> _profiles = {};
  final List<ConnectedDevice> _devices = [];
  final List<NetworkActivity> _activities = [];
  
  bool _isOpen = false;
  bool _isLocked = false;

  @override
  Future<void> open() async {
    _isOpen = true;
  }

  @override
  Future<void> close() async {
    _isOpen = false;
  }

  @override
  Future<UserProfile?> getUserProfile(int id) async {
    return _profiles[id.toString()];
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    _profiles[profile.id.toString()] = profile;
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    _profiles[profile.id.toString()] = profile;
  }

  @override
  Future<List<ConnectedDevice>> getConnectedDevices() async {
    return _devices;
  }

  @override
  Future<void> saveConnectedDevice(ConnectedDevice device) async {
    _devices.removeWhere((d) => d.peerId == device.peerId);
    _devices.add(device);
  }

  @override
  Future<void> removeConnectedDevice(String peerId) async {
    _devices.removeWhere((d) => d.peerId == peerId);
  }

  @override
  Future<List<NetworkActivity>> getNetworkActivity([int limit = 50]) async {
    return _activities.take(limit).toList();
  }

  @override
  Future<void> logNetworkActivity(NetworkActivity activity) async {
    _activities.insert(0, activity);
  }

  @override
  bool get isDatabaseLocked => _isLocked;

  void setLocked(bool locked) {
    _isLocked = locked;
  }

  bool get isOpen => _isOpen;
}

/// Fake DatabaseService for integration tests
class FakeDatabaseService implements DatabaseService {
  final Map<String, UserProfile> _profiles = {};
  final List<ConnectedDevice> _devices = [];
  final List<NetworkActivity> _activities = [];
  
  bool _isOpen = false;
  bool _isDatabaseLocked = false;

  @override
  Future<void> open() async {
    _isOpen = true;
  }

  @override
  Future<void> close() async {
    _isOpen = false;
  }

  @override
  Future<UserProfile?> fetchUserProfile() async {
    if (_profiles.isEmpty) return null;
    return _profiles.values.first;
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    if (!_isOpen) throw StateError('Database not open');
    _profiles[profile.id.toString()] = profile;
  }

  @override
  Future<List<ConnectedDevice>> fetchConnectedDevices() async {
    return List.from(_devices);
  }

  @override
  Future<void> upsertDevice(ConnectedDevice device) async {
    if (!_isOpen) throw StateError('Database not open');
    _devices.removeWhere((d) => d.peerId == device.peerId);
    _devices.add(device);
  }

  @override
  Future<void> removeDevice(String peerId) async {
    if (!_isOpen) throw StateError('Database not open');
    _devices.removeWhere((d) => d.peerId == peerId);
  }

  @override
  Future<List<NetworkActivity>> fetchNetworkActivity({int limit = 50}) async {
    return _activities.take(limit).toList();
  }

  @override
  Future<void> logActivity(NetworkActivity activity) async {
    if (!_isOpen) throw StateError('Database not open');
    _activities.insert(0, activity);
  }

  @override
  bool get isDatabaseLocked => _isDatabaseLocked;

  // Test helpers
  void setLocked(bool locked) {
    _isDatabaseLocked = locked;
  }

  bool get isOpen => _isOpen;

  void clear() {
    _profiles.clear();
    _devices.clear();
    _activities.clear();
  }
}
