import 'package:flutter/material.dart';
import '../main.dart';
import 'base_viewmodel.dart';

/// ViewModel for the Landing Page
/// Handles navigation logic from landing page to main app
class LandingViewModel extends BaseViewModel {
  /// Navigate to the main dashboard
  void navigateToDashboard(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationPage()),
    );
  }
}

