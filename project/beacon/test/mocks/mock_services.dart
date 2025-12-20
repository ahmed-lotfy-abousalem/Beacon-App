import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:beacon/services/p2p_service.dart';
import 'package:beacon/services/messaging_service.dart';
import 'package:beacon/services/notification_service.dart';
import 'package:beacon/services/speech_to_text_service.dart';
import 'package:beacon/services/text_to_speech_service.dart';
import 'package:beacon/services/wifi_direct_service.dart';
import 'package:beacon/data/models.dart';

/// Mock implementation of P2PService for testing
class MockP2PService extends Mock implements P2PService {
  final List<ConnectedDevice> _peers = [];

  List<ConnectedDevice> get peers => List.from(_peers);

  void addPeer(ConnectedDevice peer) {
    _peers.add(peer);
  }

  void removePeer(String peerId) {
    _peers.removeWhere((p) => p.peerId == peerId);
  }

  void updatePeer(String peerId, ConnectedDevice device) {
    final index = _peers.indexWhere((p) => p.peerId == peerId);
    if (index >= 0) {
      _peers[index] = device;
    }
  }

  void clear() {
    _peers.clear();
  }
}

/// Mock implementation of MessagingService for testing
class MockMessagingService extends Mock implements MessagingService {
  // Mock implementation for messaging
}

/// Mock implementation of NotificationService for testing
class MockNotificationService extends Mock implements NotificationService {
  final List<String> _displayedNotifications = [];

  List<String> get displayedNotifications => List.from(_displayedNotifications);

  void recordNotification(String notification) {
    _displayedNotifications.add(notification);
  }

  void clear() {
    _displayedNotifications.clear();
  }
}

/// Mock implementation of SpeechToTextService for testing
class MockSpeechToTextService extends Mock implements SpeechToTextService {
  String? _lastRecognizedText;
  bool _isListening = false;

  String? get lastRecognizedText => _lastRecognizedText;
  @override
  bool get isListening => _isListening;

  Future<void> simulateSpeechResult(String text) async {
    _lastRecognizedText = text;
  }

  void simulateListeningState(bool listening) {
    _isListening = listening;
  }

  void clear() {
    _lastRecognizedText = null;
    _isListening = false;
  }
}

/// Mock implementation of TextToSpeechService for testing
class MockTextToSpeechService extends Mock implements TextToSpeechService {
  final List<String> _spokenTexts = [];
  bool _isSpeaking = false;

  List<String> get spokenTexts => List.from(_spokenTexts);
  @override
  bool get isSpeaking => _isSpeaking;

  void recordSpokenText(String text) {
    _spokenTexts.add(text);
  }

  void setSpeakingState(bool speaking) {
    _isSpeaking = speaking;
  }

  void clear() {
    _spokenTexts.clear();
    _isSpeaking = false;
  }
}

/// Mock implementation of WiFiDirectService for testing
class MockWiFiDirectService extends Mock implements WiFiDirectService {
  bool _isConnected = false;
  final List<String> _discoveredDevices = [];

  bool get isConnected => _isConnected;
  List<String> get discoveredDevices => List.from(_discoveredDevices);

  void setConnected(bool connected) {
    _isConnected = connected;
  }

  void addDiscoveredDevice(String deviceId) {
    if (!_discoveredDevices.contains(deviceId)) {
      _discoveredDevices.add(deviceId);
    }
  }

  void removeDiscoveredDevice(String deviceId) {
    _discoveredDevices.remove(deviceId);
  }

  void clear() {
    _isConnected = false;
    _discoveredDevices.clear();
  }
}
