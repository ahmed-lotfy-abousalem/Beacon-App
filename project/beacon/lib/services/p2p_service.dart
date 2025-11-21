import 'dart:async';
import 'dart:math';

import 'package:uuid/uuid.dart';

import '../data/models.dart';

/// Simulates a peer-to-peer layer that would normally delegate discovery
/// to Wi-Fi Direct or Nearby Connections.
///
/// In production the `startDiscovery` method would call into Wi-Fi Direct
/// (Android) or Nearby APIs. Here we keep it simple: a timer emits fake peers
/// so the UI, database, and state management pieces can all be demonstrated.
class P2PService {
  final _uuid = const Uuid();
  final _peersController = StreamController<List<ConnectedDevice>>.broadcast();
  final _random = Random();

  Timer? _discoveryTimer;
  List<ConnectedDevice> _currentPeers = [];

  Stream<List<ConnectedDevice>> get peersStream => _peersController.stream;

  bool get isDiscovering => _discoveryTimer != null;

  /// Starts fake discovery by emitting a new peer list every few seconds.
  void startDiscovery() {
    if (_discoveryTimer != null) return;

    _discoveryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final now = DateTime.now();
      final newPeer = ConnectedDevice(
        peerId: _uuid.v4(),
        name: _randomName(),
        status: 'Active',
        lastSeen: now,
        signalStrength: _randomSignal(),
        isEmergency: _random.nextBool(),
      );

      _currentPeers = [
        newPeer,
        ..._currentPeers.where(
          (peer) => now.difference(peer.lastSeen).inMinutes < 10,
        ),
      ];
      _peersController.add(_currentPeers);
    });
  }

  /// Stops fake discovery and clears cached peers.
  void stopDiscovery() {
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    _currentPeers = [];
    _peersController.add(_currentPeers);
  }

  Future<void> dispose() async {
    stopDiscovery();
    await _peersController.close();
  }

  String _randomName() {
    const teams = [
      'Emergency Team',
      'Rescue Unit',
      'Medical Team',
      'Volunteer Crew',
      'Civilian Group',
    ];
    final suffix = _random.nextInt(900) + 100;
    return '${teams[_random.nextInt(teams.length)]} $suffix';
  }

  int _randomSignal() => _random.nextInt(5).clamp(1, 5);
}
