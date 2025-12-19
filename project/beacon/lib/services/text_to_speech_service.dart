import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-Speech Service
/// Handles text-to-speech conversion for chat messages.
/// Uses the flutter_tts plugin for native platform speech synthesis.
class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  late FlutterTts _flutterTts;
  
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String _currentSpeakingText = '';
  
  // Callbacks
  Function(bool)? _onSpeakingStatusChanged;
  Function(String)? _onError;

  factory TextToSpeechService() {
    return _instance;
  }

  TextToSpeechService._internal() {
    _flutterTts = FlutterTts();
  }

  /// Get initialization status
  bool get isInitialized => _isInitialized;
  
  /// Get current speaking status
  bool get isSpeaking => _isSpeaking;
  
  /// Get current text being spoken
  String get currentSpeakingText => _currentSpeakingText;

  /// Initialize the text-to-speech service
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Set up callbacks
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _onSpeakingStatusChanged?.call(true);
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _currentSpeakingText = '';
        _onSpeakingStatusChanged?.call(false);
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        _currentSpeakingText = '';
        _onSpeakingStatusChanged?.call(false);
      });

      _flutterTts.setErrorHandler((message) {
        _isSpeaking = false;
        _currentSpeakingText = '';
        _onSpeakingStatusChanged?.call(false);
        _onError?.call('Text-to-speech error: $message');
      });

      // Set language to English (default)
      await _flutterTts.setLanguage('en-US');

      // Set speech rate (0.5 = slower, 1.0 = normal, 2.0 = faster)
      await _flutterTts.setSpeechRate(1.0);

      // Set pitch (1.0 = normal pitch)
      await _flutterTts.setPitch(1.0);

      // Set volume (0.0 to 1.0)
      await _flutterTts.setVolume(1.0);

      _isInitialized = true;
      return true;
    } catch (e) {
      _onError?.call('Failed to initialize text-to-speech: $e');
      return false;
    }
  }

  /// Speak the given text
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        _onError?.call('Text-to-speech service not initialized');
        return;
      }
    }

    try {
      // Stop any currently speaking text
      if (_isSpeaking) {
        await stop();
      }

      _currentSpeakingText = text;
      await _flutterTts.speak(text);
    } catch (e) {
      _onError?.call('Error speaking text: $e');
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _currentSpeakingText = '';
      _onSpeakingStatusChanged?.call(false);
    } catch (e) {
      _onError?.call('Error stopping speech: $e');
    }
  }

  /// Pause speaking
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      _onError?.call('Error pausing speech: $e');
    }
  }

  /// Get available languages
  Future<List<dynamic>> getLanguages() async {
    try {
      return await _flutterTts.getLanguages ?? [];
    } catch (e) {
      _onError?.call('Error getting languages: $e');
      return [];
    }
  }

  /// Set language for speech
  Future<void> setLanguage(String languageCode) async {
    try {
      await _flutterTts.setLanguage(languageCode);
    } catch (e) {
      _onError?.call('Error setting language: $e');
    }
  }

  /// Set speech rate (0.5 = slower, 1.0 = normal, 2.0 = faster)
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      _onError?.call('Error setting speech rate: $e');
    }
  }

  /// Set pitch (1.0 = normal pitch)
  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
    } catch (e) {
      _onError?.call('Error setting pitch: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume);
    } catch (e) {
      _onError?.call('Error setting volume: $e');
    }
  }

  /// Set callback for speaking status changes
  void setOnSpeakingStatusChanged(Function(bool) callback) {
    _onSpeakingStatusChanged = callback;
  }

  /// Set callback for errors
  void setOnError(Function(String) callback) {
    _onError = callback;
  }

  /// Dispose the service
  void dispose() {
    try {
      _flutterTts.stop();
    } catch (e) {
      // Ignore errors during disposal
    }
  }
}
