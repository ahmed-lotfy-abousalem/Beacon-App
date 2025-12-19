import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/messaging_service.dart';
import '../../services/wifi_direct_service.dart';
import '../../services/speech_to_text_service.dart';
import '../../services/text_to_speech_service.dart';
import '../base_view_model.dart';

/// ChatViewModel - Manages all logic for the Chat Page
/// 
/// Responsibilities:
/// - Initialize and manage services (messaging, WiFi Direct, speech-to-text, TTS)
/// - Handle message sending and receiving
/// - Manage speech-to-text state and operations
/// - Manage text-to-speech state and operations
/// - Expose only necessary state to the UI
/// 
/// This ViewModel separates business logic from the UI layer (ChatPage),
/// making the code more testable and maintainable.
class ChatViewModel extends BaseViewModel {
  // Services
  final MessagingService _messagingService = MessagingService();
  final WiFiDirectService _wifiDirectService = WiFiDirectService();
  final SpeechToTextService _speechToTextService = SpeechToTextService();
  final TextToSpeechService _textToSpeechService = TextToSpeechService();
  
  // Stream subscriptions
  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<WiFiDirectEvent>? _socketEventSubscription;
  
  // State properties
  bool _isSocketConnected = false;
  bool _isSpeechListening = false;
  bool _isTTSSpeaking = false;
  String _currentSpeakingMessageId = '';
  final TextEditingController messageController = TextEditingController();
  
  // Getters - expose state to UI
  bool get isSocketConnected => _isSocketConnected;
  bool get isSpeechListening => _isSpeechListening;
  bool get isTTSSpeaking => _isTTSSpeaking;
  String get currentSpeakingMessageId => _currentSpeakingMessageId;
  List<ChatMessage> get messages => _messagingService.messages;
  WiFiDirectService get wifiDirectService => _wifiDirectService;
  
  // Callbacks for UI errors
  Function(String)? onError;
  
  /// Initialize the ViewModel
  /// Call this in initState of the page
  Future<void> initialize() async {
    try {
      setLoading(true);
      
      // Initialize all services
      await _initializeMessaging();
      await _initializeSpeechToText();
      await _initializeTextToSpeech();
      
      setLoading(false);
    } catch (e) {
      setError('Failed to initialize chat: $e');
      setLoading(false);
    }
  }
  
  /// Initialize messaging service
  Future<void> _initializeMessaging() async {
    try {
      await _messagingService.initialize();
      
      // Listen for incoming messages
      _messageSubscription = _messagingService.messageStream.listen((message) {
        notifyListeners(); // Notify UI of new message
      });
      
      // Listen for socket connection events
      _socketEventSubscription = _wifiDirectService.eventStream.listen((event) {
        if (event.type == 'socketConnected') {
          _setSocketConnected(true);
        } else if (event.type == 'socketDisconnected') {
          _setSocketConnected(false);
        }
      });
      
      // Check initial socket state
      _isSocketConnected = _wifiDirectService.isSocketConnected;
      notifyListeners();
    } catch (e) {
      setError('Failed to initialize messaging: $e');
    }
  }
  
  /// Initialize speech-to-text service
  Future<void> _initializeSpeechToText() async {
    try {
      await _speechToTextService.initialize();
      
      // Set up callbacks
      _speechToTextService.setOnTextRecognized((text) {
        messageController.text = text;
        notifyListeners();
      });
      
      _speechToTextService.setOnListeningStatusChanged((isListening) {
        _isSpeechListening = isListening;
        notifyListeners();
      });
      
      _speechToTextService.setOnError((error) {
        onError?.call('Speech recognition error: $error');
      });
    } catch (e) {
      setError('Failed to initialize speech-to-text: $e');
    }
  }
  
  /// Initialize text-to-speech service
  Future<void> _initializeTextToSpeech() async {
    try {
      await _textToSpeechService.initialize();
      
      // Set up callbacks
      _textToSpeechService.setOnSpeakingStatusChanged((isSpeaking) {
        _isTTSSpeaking = isSpeaking;
        notifyListeners();
      });
      
      _textToSpeechService.setOnError((error) {
        onError?.call('Text-to-speech error: $error');
      });
    } catch (e) {
      setError('Failed to initialize text-to-speech: $e');
    }
  }
  
  /// Send a message
  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || !_isSocketConnected) {
      if (text.isEmpty) {
        onError?.call('Message cannot be empty');
      } else {
        onError?.call('Not connected to WiFi Direct. Please wait for connection.');
      }
      return;
    }
    
    try {
      setLoading(true);
      messageController.clear();
      
      final success = await _messagingService.sendMessage(text);
      
      if (!success) {
        onError?.call(
          'Failed to send message. WiFi Direct is connected but socket communication is not ready. Please wait a few seconds and try again.',
        );
      }
      
      setLoading(false);
    } catch (e) {
      onError?.call('Error sending message: $e');
      setLoading(false);
    }
  }
  
  /// Start speech-to-text listening
  Future<void> startSpeechListening() async {
    try {
      if (!_speechToTextService.isInitialized) {
        final initialized = await _speechToTextService.initialize();
        if (!initialized) {
          onError?.call('Speech recognition is not available on this device');
          return;
        }
      }
      
      await _speechToTextService.startListening();
    } catch (e) {
      onError?.call('Error starting speech recognition: $e');
    }
  }
  
  /// Stop speech-to-text listening
  Future<void> stopSpeechListening() async {
    try {
      await _speechToTextService.stopListening();
      
      // Auto-send if message was recognized
      if (messageController.text.trim().isNotEmpty && _isSocketConnected) {
        await Future.delayed(const Duration(milliseconds: 500));
        await sendMessage();
      }
    } catch (e) {
      onError?.call('Error stopping speech recognition: $e');
    }
  }
  
  /// Speak a message using text-to-speech
  Future<void> speakMessage(ChatMessage message) async {
    try {
      if (_isTTSSpeaking && _currentSpeakingMessageId == message.text) {
        // Stop if already speaking this message
        await _textToSpeechService.stop();
      } else {
        // Speak the message
        _currentSpeakingMessageId = message.text;
        await _textToSpeechService.speak(message.text);
      }
    } catch (e) {
      onError?.call('Error speaking message: $e');
    }
  }
  
  /// Stop text-to-speech
  Future<void> stopSpeaking() async {
    try {
      await _textToSpeechService.stop();
      _currentSpeakingMessageId = '';
      notifyListeners();
    } catch (e) {
      onError?.call('Error stopping speech: $e');
    }
  }
  
  /// Helper method to update socket connection state
  void _setSocketConnected(bool value) {
    if (_isSocketConnected != value) {
      _isSocketConnected = value;
      notifyListeners();
    }
  }
  
  /// Dispose all resources
  @override
  void dispose() {
    messageController.dispose();
    _messageSubscription?.cancel();
    _socketEventSubscription?.cancel();
    _speechToTextService.dispose();
    _textToSpeechService.dispose();
    super.dispose();
  }
}
