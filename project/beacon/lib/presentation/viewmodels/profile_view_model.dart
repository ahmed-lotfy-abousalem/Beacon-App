import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../services/p2p_service.dart';
import '../base_view_model.dart';

/// ProfileViewModel - Manages user profile state and operations
/// 
/// This ViewModel demonstrates:
/// - Loading user profile data
/// - Saving profile changes
/// - Managing validation
/// - Handling async operations with error handling
class ProfileViewModel extends BaseViewModel {
  final P2PService _p2pService = P2PService();
  
  // State properties
  UserProfile? _userProfile;
  bool _isEditing = false;
  String? _validationError;
  
  // Form controllers
  final nameController = TextEditingController();
  final roleController = TextEditingController();
  
  // Getters
  UserProfile? get userProfile => _userProfile;
  bool get isEditing => _isEditing;
  String? get validationError => _validationError;
  
  // Callbacks
  Function()? onProfileSaved;
  Function(String)? onError;
  
  /// Initialize the ViewModel
  Future<void> initialize() async {
    try {
      setLoading(true);
      await loadProfile();
      setLoading(false);
    } catch (e) {
      setError('Failed to initialize profile: $e');
      setLoading(false);
    }
  }
  
  /// Load user profile
  Future<void> loadProfile() async {
    try {
      // In a real app, you would fetch from repository
      // For now, simulate loading
      await Future.delayed(const Duration(milliseconds: 500));
      
      _userProfile = UserProfile(
        id: 1,
        name: 'Your Name',
        role: 'User',
        phone: '',
        location: '',
        updatedAt: DateTime.now(),
      );
      
      // Populate form fields
      nameController.text = _userProfile?.name ?? '';
      roleController.text = _userProfile?.role ?? '';
      
      notifyListeners();
    } catch (e) {
      setError('Failed to load profile: $e');
    }
  }
  
  /// Toggle editing mode
  void toggleEditing() {
    _isEditing = !_isEditing;
    if (!_isEditing) {
      // Reset form if cancelled
      nameController.text = _userProfile?.name ?? '';
      roleController.text = _userProfile?.role ?? '';
      _validationError = null;
    }
    notifyListeners();
  }
  
  /// Validate profile data
  bool _validateProfile() {
    final name = nameController.text.trim();
    
    if (name.isEmpty) {
      _validationError = 'Name cannot be empty';
      notifyListeners();
      return false;
    }
    
    if (name.length < 2) {
      _validationError = 'Name must be at least 2 characters';
      notifyListeners();
      return false;
    }
    
    _validationError = null;
    return true;
  }
  
  /// Save profile changes
  Future<void> saveProfile() async {
    if (!_validateProfile()) {
      return;
    }
    
    try {
      setLoading(true);
      
      // Create updated profile
      final updatedProfile = UserProfile(
        id: _userProfile?.id ?? 1,
        name: nameController.text.trim(),
        role: roleController.text.trim(),
        phone: _userProfile?.phone ?? '',
        location: _userProfile?.location ?? '',
        updatedAt: DateTime.now(),
      );
      
      // Save to database (in a real app, use repository)
      // await _repository.saveProfile(updatedProfile);
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      _userProfile = updatedProfile;
      _isEditing = false;
      setLoading(false);
      
      // Notify UI
      onProfileSaved?.call();
      notifyListeners();
    } catch (e) {
      setError('Failed to save profile: $e');
      onError?.call('Error saving profile: $e');
      setLoading(false);
    }
  }
  
  /// Update a specific profile field
  void updateName(String name) {
    nameController.text = name;
    _validationError = null; // Clear validation on change
    notifyListeners();
  }
  
  void updateRole(String role) {
    roleController.text = role;
    notifyListeners();
  }
  
  /// Get list of connected devices
  Stream<List<ConnectedDevice>> get peersStream => _p2pService.peersStream;
  
  /// Dispose
  @override
  void dispose() {
    nameController.dispose();
    roleController.dispose();
    super.dispose();
  }
}
