import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../providers/beacon_provider.dart';
import '../services/messaging_service.dart';
import '../services/wifi_direct_service.dart';
import 'base_viewmodel.dart';

/// ViewModel for the Network Dashboard Page
/// Manages connected devices, network status, and predefined messages
class NetworkDashboardViewModel extends BaseViewModel {
  final MessagingService _messagingService = MessagingService();
  final WiFiDirectService _wifiDirectService = WiFiDirectService();

  StreamSubscription<WiFiDirectEvent>? _socketEventSubscription;
  bool _isSocketConnected = false;

  bool get isSocketConnected => _isSocketConnected;

  @override
  Future<void> dispose() async {
    await _socketEventSubscription?.cancel();
    super.dispose();
  }

  /// Initialize socket monitoring
  void initializeSocketMonitoring() {
    _isSocketConnected = _wifiDirectService.isSocketConnected;

    _socketEventSubscription = _wifiDirectService.eventStream.listen((event) {
      if (event.type == 'socketConnected') {
        _isSocketConnected = true;
        notifyListeners();
      } else if (event.type == 'socketDisconnected') {
        _isSocketConnected = false;
        notifyListeners();
      }
    });
  }

  /// Get connected devices from provider
  List<ConnectedDevice> getConnectedDevices(BuildContext context) {
    return context.watch<BeaconProvider>().connectedDevices;
  }

  /// Check if provider is loading
  bool isLoadingDevices(BuildContext context) {
    return context.watch<BeaconProvider>().isLoading;
  }

  /// Refresh devices
  Future<void> refreshDevices(BuildContext context) async {
    await context.read<BeaconProvider>().refresh();
  }

  /// Get predefined messages
  List<String> getPredefinedMessages() {
    return [
      'Need immediate medical assistance',
      'Evacuation required in my area',
      'Food and water supplies needed',
      'Shelter required for 5 people',
      'All safe, no assistance needed',
      'Emergency supplies available',
    ];
  }

  /// Send predefined message
  Future<bool> sendPredefinedMessage(String message) async {
    setLoading(true);
    try {
      final messageWithPrefix = '⚠️ $message';
      final success = await _messagingService.sendMessage(messageWithPrefix);
      
      if (!success) {
        setError('Failed to send. Check WiFi Direct connection.');
      } else {
        clearError();
      }
      
      return success;
    } catch (e) {
      setError('Error sending message: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Format last seen timestamp
  String formatLastSeen(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hrs ago';
    return '${difference.inDays} days ago';
  }
}

