import 'dart:async';

import 'package:flutter/material.dart';

import '../data/database_service.dart';
import '../data/models.dart';
import '../services/p2p_service.dart';

/// Central state holder that wires together the encrypted database,
/// peer discovery service, and UI.
class BeaconProvider extends ChangeNotifier with WidgetsBindingObserver {
  BeaconProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  final DatabaseService _database = DatabaseService.instance;
  final P2PService _p2pService = P2PService();

  StreamSubscription<List<ConnectedDevice>>? _peerSubscription;

  bool _isLoading = true;
  bool _isDatabaseLocked = false;
  UserProfile? _userProfile;
  List<ConnectedDevice> _connectedDevices = [];
  List<NetworkActivity> _recentActivity = [];

  bool get isLoading => _isLoading;
  bool get isDatabaseLocked => _isDatabaseLocked;
  UserProfile? get userProfile => _userProfile;
  List<ConnectedDevice> get connectedDevices => _connectedDevices;
  List<NetworkActivity> get recentActivity => _recentActivity;

  /// Opens the DB, loads cached data, and starts discovery.
  Future<void> initialize() async {
    await _database.open();
    await _loadFromDatabase();
    _p2pService.startDiscovery();
    _peerSubscription = _p2pService.peersStream.listen(_handlePeerUpdate);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_isDatabaseLocked) return;
    await _loadFromDatabase();
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _database.saveUserProfile(profile);
    _userProfile = profile;
    await _database.logActivity(
      NetworkActivity(
        peerId: profile.id.toString(),
        event: 'profile_update',
        details: 'Profile updated for ${profile.name}',
        timestamp: DateTime.now(),
      ),
    );
    await refresh();
  }

  Future<void> sendQuickMessage(String peerId, String message) async {
    await _database.logActivity(
      NetworkActivity(
        peerId: peerId,
        event: 'message',
        details: message,
        timestamp: DateTime.now(),
      ),
    );
    await refresh();
  }

  Future<void> removeDevice(String peerId) async {
    await _database.removeDevice(peerId);
    await refresh();
  }

  Future<void> lockDatabase() async {
    await _database.close();
    _isDatabaseLocked = true;
    notifyListeners();
  }

  Future<void> unlockDatabase() async {
    await _database.open();
    await _loadFromDatabase();
    _isDatabaseLocked = false;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        lockDatabase();
        _p2pService.stopDiscovery();
        break;
      case AppLifecycleState.resumed:
        unlockDatabase();
        _p2pService.startDiscovery();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _loadFromDatabase() async {
    _userProfile = await _database.fetchUserProfile();
    _connectedDevices = await _database.fetchConnectedDevices();
    _recentActivity = await _database.fetchNetworkActivity();
  }

  Future<void> _handlePeerUpdate(List<ConnectedDevice> peers) async {
    if (_isDatabaseLocked) return;

    // Create a copy of the peers list to avoid concurrent modification
    final peersCopy = peers.toList();
    
    for (final peer in peersCopy) {
      await _database.upsertDevice(peer);
      await _database.logActivity(
        NetworkActivity(
          peerId: peer.peerId,
          event: 'discovered',
          details: 'Auto-discovered ${peer.name}',
          timestamp: DateTime.now(),
        ),
      );
    }
    await refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _peerSubscription?.cancel();
    _p2pService.dispose();
    _database.close();
    super.dispose();
  }
}
