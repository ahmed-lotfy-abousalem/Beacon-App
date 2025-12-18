import 'package:flutter/material.dart';
import '../services/messaging_service.dart';
import 'base_viewmodel.dart';

/// ViewModel for the Resource Page
/// Manages resource sharing and requesting
class ResourceViewModel extends BaseViewModel {
  final MessagingService _messagingService = MessagingService();

  final List<ResourceItem> _availableResources = [
    ResourceItem(
      name: 'Medical Supplies',
      description: 'First aid kits, bandages, medications',
      availableCount: 15,
      requestedCount: 8,
      icon: Icons.medical_services,
      color: Colors.red,
    ),
    ResourceItem(
      name: 'Shelter',
      description: 'Temporary housing, tents, blankets',
      availableCount: 12,
      requestedCount: 20,
      icon: Icons.home,
      color: Colors.blue,
    ),
    ResourceItem(
      name: 'Food',
      description: 'Emergency rations, water, canned goods',
      availableCount: 25,
      requestedCount: 15,
      icon: Icons.restaurant,
      color: Colors.green,
    ),
    ResourceItem(
      name: 'Transportation',
      description: 'Vehicles, fuel, evacuation assistance',
      availableCount: 8,
      requestedCount: 12,
      icon: Icons.directions_car,
      color: Colors.orange,
    ),
    ResourceItem(
      name: 'Communication',
      description: 'Radios, batteries, charging stations',
      availableCount: 6,
      requestedCount: 10,
      icon: Icons.radio,
      color: Colors.purple,
    ),
    ResourceItem(
      name: 'Tools & Equipment',
      description: 'Generators, flashlights, rescue tools',
      availableCount: 10,
      requestedCount: 7,
      icon: Icons.build,
      color: Colors.brown,
    ),
  ];

  List<ResourceItem> get availableResources => List.unmodifiable(_availableResources);

  /// Initialize messaging service
  Future<void> initialize() async {
    await _messagingService.initialize();
  }

  /// Share a resource
  Future<bool> shareResource({
    required ResourceItem resource,
    required String quantity,
    String? location,
  }) async {
    if (quantity.trim().isEmpty) {
      setError('Please enter quantity');
      return false;
    }

    setLoading(true);
    try {
      final locationText = location?.isNotEmpty == true ? ' at $location' : '';
      final message = '📦 RESOURCE SHARE: ${resource.name} - Quantity: $quantity$locationText';

      final success = await _messagingService.sendMessage(message);

      if (!success) {
        setError('Failed to send. Check WiFi Direct connection.');
      } else {
        clearError();
      }

      return success;
    } catch (e) {
      setError('Error sharing resource: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Request a resource
  Future<bool> requestResource({
    required ResourceItem resource,
    required String quantity,
    required String location,
    String? urgency,
  }) async {
    if (quantity.trim().isEmpty || location.trim().isEmpty) {
      setError('Please fill quantity and location');
      return false;
    }

    setLoading(true);
    try {
      final urgencyText = urgency?.isNotEmpty == true ? ' - URGENCY: $urgency' : '';
      final message = '🆘 RESOURCE REQUEST: ${resource.name} - Qty: $quantity - Location: $location$urgencyText';

      final success = await _messagingService.sendMessage(message);

      if (!success) {
        setError('Failed to send. Check WiFi Direct connection.');
      } else {
        clearError();
      }

      return success;
    } catch (e) {
      setError('Error requesting resource: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }
}

/// Data model for resource items
class ResourceItem {
  final String name;
  final String description;
  final int availableCount;
  final int requestedCount;
  final IconData icon;
  final Color color;

  ResourceItem({
    required this.name,
    required this.description,
    required this.availableCount,
    required this.requestedCount,
    required this.icon,
    required this.color,
  });
}

