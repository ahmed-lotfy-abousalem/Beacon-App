import 'dart:async';

import '../../data/models.dart';
import '../../services/notification_service.dart';
import '../../services/p2p_service.dart';
import '../base_view_model.dart';

/// PeerNotificationViewModel - Manages peer join/leave notifications
/// 
/// This ViewModel:
/// - Listens to peer events from P2PService
/// - Triggers notifications via NotificationService
/// - Maintains list of active peers
/// - Handles notification interactions
class PeerNotificationViewModel extends BaseViewModel {
  final P2PService _p2pService = P2PService();
  final NotificationService _notificationService = NotificationService();

  StreamSubscription<PeerEvent>? _peerEventSubscription;
  final List<ConnectedDevice> _activePeers = [];

  // Callbacks for UI
  Function(ConnectedDevice)? onPeerJoined;
  Function(ConnectedDevice)? onPeerLeft;

  /// Get current active peers
  List<ConnectedDevice> get activePeers => List.unmodifiable(_activePeers);

  /// Get peer count
  int get peerCount => _activePeers.length;

  /// Initialize the ViewModel
  Future<void> initialize() async {
    try {
      print('🚀 PeerNotificationViewModel.initialize() called');
      setLoading(true);

      // Initialize notification service
      print('⏳ Initializing NotificationService...');
      await _notificationService.initialize();
      print('✅ NotificationService initialized');

      // Initialize P2P service
      print('⏳ Initializing P2PService...');
      await _p2pService.initialize();
      print('✅ P2PService initialized');

      // Load initial peers
      print('⏳ Starting P2P discovery...');
      await _p2pService.startDiscovery();
      print('✅ P2P discovery started');

      // Listen to peer streams
      print('📡 Setting up peer event listener');
      _peerEventSubscription =
          _p2pService.peerEventStream.listen(
            _handlePeerEvent,
            onError: (error) {
              print('❌ Error in peer event stream: $error');
            },
          );

      // Also listen to peers list for initial population
      _p2pService.peersStream.listen((peers) {
        _activePeers.clear();
        _activePeers.addAll(peers);
        notifyListeners();
      });

      setLoading(false);
      print('✅ PeerNotificationViewModel initialization complete');
    } catch (e) {
      print('❌ PeerNotificationViewModel initialization error: $e');
      setError('Failed to initialize peer notifications: $e');
      setLoading(false);
    }
  }

  /// Handle peer events
  void _handlePeerEvent(PeerEvent event) {
    print('🎯 PeerNotificationViewModel received event: ${event.type} - ${event.device.name}');
    if (event.type == 'joined') {
      _handlePeerJoined(event.device);
    } else if (event.type == 'left') {
      _handlePeerLeft(event.device);
    }
  }

  /// Handle peer joined event
  void _handlePeerJoined(ConnectedDevice device) {
    print('🔔 PeerNotificationViewModel: Handling peer joined - ${device.name}');
    
    // Add to active peers if not already present
    if (!_activePeers.any((p) => p.peerId == device.peerId)) {
      _activePeers.add(device);
      print('✅ Added ${device.name} to active peers. Total: ${_activePeers.length}');
    }

    // Show notification
    print('📢 Showing peer joined notification for ${device.name}');
    _notificationService.showPeerJoinedNotification(
      peerName: device.name,
      peerId: device.peerId,
    );

    // Call callback
    print('📞 Calling onPeerJoined callback');
    onPeerJoined?.call(device);

    notifyListeners();
  }

  /// Handle peer left event
  void _handlePeerLeft(ConnectedDevice device) {
    // Remove from active peers
    _activePeers.removeWhere((p) => p.peerId == device.peerId);

    // Show notification
    _notificationService.showPeerLeftNotification(
      peerName: device.name,
      peerId: device.peerId,
    );

    // Call callback
    onPeerLeft?.call(device);

    notifyListeners();
  }

  /// Get formatted peer list for display
  String get peersDisplayText {
    if (_activePeers.isEmpty) {
      return 'No peers connected';
    }
    if (_activePeers.length == 1) {
      return '1 peer: ${_activePeers[0].name}';
    }
    final names = _activePeers.map((p) => p.name).join(', ');
    return '${_activePeers.length} peers: $names';
  }

  /// Stop discovery and cleanup
  Future<void> stopDiscovery() async {
    await _p2pService.stopDiscovery();
  }

  /// Dispose
  @override
  void dispose() {
    _peerEventSubscription?.cancel();
    _notificationService.dispose();
    super.dispose();
  }
}
