import 'package:flutter/material.dart';

/// Base ViewModel class for all ViewModels
/// Provides common functionality like error handling, loading states, and disposal
/// All ViewModels should extend this class
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  
  /// Whether the ViewModel is currently loading data
  bool get isLoading => _isLoading;
  
  /// Error message if any error occurred
  String? get errorMessage => _errorMessage;
  
  /// Whether an error exists
  bool get hasError => _errorMessage != null;
  
  /// Set loading state
  @protected
  void setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }
  
  /// Set error message
  @protected
  void setError(String? message) {
    if (_errorMessage != message) {
      _errorMessage = message;
      notifyListeners();
    }
  }
  
  /// Clear error message
  @protected
  void clearError() {
    setError(null);
  }
  
  /// Execute an async operation with automatic loading and error handling
  /// 
  /// Example:
  /// ```dart
  /// await executeAsync(() async {
  ///   await someLongOperation();
  /// });
  /// ```
  @protected
  Future<T> executeAsync<T>(Future<T> Function() operation) async {
    try {
      setLoading(true);
      clearError();
      final result = await operation();
      setLoading(false);
      return result;
    } catch (e) {
      final errorMsg = e.toString();
      setError(errorMsg);
      setLoading(false);
      rethrow;
    }
  }
  
  /// Dispose method - override in subclasses if needed
  @override
  void dispose() {
    super.dispose();
  }
}
