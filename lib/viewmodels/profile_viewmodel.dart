import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../providers/beacon_provider.dart';
import 'base_viewmodel.dart';

/// ViewModel for the Profile Page
/// Manages user profile, emergency contacts, and settings
class ProfileViewModel extends BaseViewModel {
  final List<EmergencyContact> _emergencyContacts = [
    EmergencyContact(
      name: 'Jane Doe',
      relationship: 'Spouse',
      phone: '+1 (555) 987-6543',
      isPrimary: true,
    ),
    EmergencyContact(
      name: 'Dr. Smith',
      relationship: 'Family Doctor',
      phone: '+1 (555) 456-7890',
      isPrimary: false,
    ),
    EmergencyContact(
      name: 'Emergency Services',
      relationship: 'Emergency Contact',
      phone: '911',
      isPrimary: false,
    ),
  ];

  List<EmergencyContact> get emergencyContacts => List.unmodifiable(_emergencyContacts);

  /// Get user profile from provider
  UserProfile? getUserProfile(BuildContext context) {
    return context.read<BeaconProvider>().userProfile;
  }

  /// Save user profile
  Future<void> saveProfile(BuildContext context, UserProfile profile) async {
    setLoading(true);
    try {
      await context.read<BeaconProvider>().saveProfile(profile);
      clearError();
    } catch (e) {
      setError('Failed to save profile: $e');
    } finally {
      setLoading(false);
    }
  }

  /// Add emergency contact
  void addEmergencyContact(EmergencyContact contact) {
    _emergencyContacts.add(contact);
    notifyListeners();
  }

  /// Update emergency contact
  void updateEmergencyContact(int index, EmergencyContact contact) {
    if (index >= 0 && index < _emergencyContacts.length) {
      _emergencyContacts[index] = contact;
      notifyListeners();
    }
  }

  /// Remove emergency contact
  void removeEmergencyContact(int index) {
    if (index >= 0 && index < _emergencyContacts.length) {
      _emergencyContacts.removeAt(index);
      notifyListeners();
    }
  }
}

/// Data model for emergency contacts
class EmergencyContact {
  final String name;
  final String relationship;
  final String phone;
  final bool isPrimary;

  EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
    required this.isPrimary,
  });
}

