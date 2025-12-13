import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Speech-to-Text Service
/// Handles speech recognition and conversion to text for the chat application.
/// Uses the speech_to_text plugin for native Android speech recognition.
class SpeechToTextService {
  static final SpeechToTextService _instance = SpeechToTextService._internal();
  late stt.SpeechToText _speechToText;
  
  bool _isListening = false;
  String _recognizedText = '';
  bool _isInitialized = false;
  
  // Callbacks
  Function(String)? _onTextRecognized;
  Function(bool)? _onListeningStatusChanged;
  Function(String)? _onError;

  factory SpeechToTextService() {
    return _instance;
  }

  SpeechToTextService._internal() {
    _speechToText = stt.SpeechToText();
  }

  /// Check if speech recognition is available on the device
  Future<bool> get isAvailable async {
    return await _speechToText.initialize(
      onError: _handleError,
      onStatus: _handleStatus,
    );
  }

  /// Initialize the speech-to-text service
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Check and request microphone permission
      final microphoneStatus = await Permission.microphone.request();
      
      if (microphoneStatus.isDenied) {
        _onError?.call('Microphone permission denied');
        return false;
      }

      if (microphoneStatus.isPermanentlyDenied) {
        _onError?.call('Microphone permission permanently denied. Please enable in settings.');
        return false;
      }

      // Initialize speech to text
      final initialized = await _speechToText.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
      );

      if (initialized) {
        _isInitialized = true;
        return true;
      } else {
        _onError?.call('Speech recognition not available');
        return false;
      }
    } catch (e) {
      _onError?.call('Failed to initialize speech recognition: $e');
      return false;
    }
  }

  /// Start listening for speech input
  Future<void> startListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        _onError?.call('Speech recognition not available');
        return;
      }
    }

    if (_isListening) {
      return; // Already listening
    }

    try {
      _recognizedText = '';
      _isListening = true;
      _onListeningStatusChanged?.call(true);

      // Start listening - using Google's speech recognition
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30), // Listen for up to 30 seconds
        pauseFor: const Duration(seconds: 5), // Stop if silence for 5 seconds
        partialResults: true, // Show partial results while speaking
        localeId: 'en_US', // Default to US English
      );
    } catch (e) {
      _isListening = false;
      _onListeningStatusChanged?.call(false);
      _onError?.call('Error starting speech recognition: $e');
    }
  }

  /// Stop listening for speech input
  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
      _isListening = false;
      _onListeningStatusChanged?.call(false);
    } catch (e) {
      _onError?.call('Error stopping speech recognition: $e');
    }
  }

  /// Cancel speech recognition without returning result
  Future<void> cancel() async {
    try {
      await _speechToText.cancel();
      _isListening = false;
      _recognizedText = '';
      _onListeningStatusChanged?.call(false);
    } catch (e) {
      _onError?.call('Error canceling speech recognition: $e');
    }
  }

  /// Get the recognized text
  String get recognizedText => _recognizedText;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Check if speech-to-text service is initialized
  bool get isInitialized => _isInitialized;

  /// Set callback for recognized text
  void setOnTextRecognized(Function(String) callback) {
    _onTextRecognized = callback;
  }

  /// Set callback for listening status changes
  void setOnListeningStatusChanged(Function(bool) callback) {
    _onListeningStatusChanged = callback;
  }

  /// Set callback for errors
  void setOnError(Function(String) callback) {
    _onError = callback;
  }

  /// Handle speech recognition result
  void _onSpeechResult(final result) {
    if (result.finalResult) {
      _recognizedText = result.recognizedWords;
      _onTextRecognized?.call(_recognizedText);
    } else {
      // Update with partial result
      _recognizedText = result.recognizedWords;
      _onTextRecognized?.call(_recognizedText);
    }
  }

  /// Handle error from speech recognition
  void _handleError(error) {
    print('Speech recognition error: $error');
    _onError?.call('Error: $error');
    _isListening = false;
    _onListeningStatusChanged?.call(false);
  }

  /// Handle status changes from speech recognition
  void _handleStatus(status) {
    print('Speech recognition status: $status');
  }

  /// Cleanup resources
  void dispose() {
    _speechToText.cancel();
    _isListening = false;
    _recognizedText = '';
  }
}
