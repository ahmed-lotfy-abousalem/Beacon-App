import 'package:flutter/foundation.dart';

/// Tables used by the encrypted SQLite database.
class BeaconTables {
  static const userProfile = 'user_profile';
  static const connectedDevices = 'connected_devices';
  static const networkActivity = 'network_activity';
}

/// Represents the single user profile stored on the device.
@immutable
class UserProfile {
  final int id;
  final String name;
  final String role;
  final String phone;
  final String location;
  final DateTime updatedAt;

  const UserProfile({
    this.id = 1,
    required this.name,
    required this.role,
    required this.phone,
    required this.location,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? name,
    String? role,
    String? phone,
    String? location,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'phone': phone,
      'location': location,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int,
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      location: map['location'] as String? ?? '',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updated_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

/// Represents a peer discovered over the ad-hoc network.
@immutable
class ConnectedDevice {
  final String peerId;
  final String name;
  final String status;
  final DateTime lastSeen;
  final int signalStrength;
  final bool isEmergency;

  const ConnectedDevice({
    required this.peerId,
    required this.name,
    required this.status,
    required this.lastSeen,
    required this.signalStrength,
    required this.isEmergency,
  });

  ConnectedDevice copyWith({
    String? name,
    String? status,
    DateTime? lastSeen,
    int? signalStrength,
    bool? isEmergency,
  }) {
    return ConnectedDevice(
      peerId: peerId,
      name: name ?? this.name,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      signalStrength: signalStrength ?? this.signalStrength,
      isEmergency: isEmergency ?? this.isEmergency,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'peer_id': peerId,
      'name': name,
      'status': status,
      'last_seen': lastSeen.millisecondsSinceEpoch,
      'signal_strength': signalStrength,
      'is_emergency': isEmergency ? 1 : 0,
    };
  }

  factory ConnectedDevice.fromMap(Map<String, dynamic> map) {
    return ConnectedDevice(
      peerId: map['peer_id'] as String,
      name: map['name'] as String? ?? 'Unknown',
      status: map['status'] as String? ?? 'Unknown',
      lastSeen: DateTime.fromMillisecondsSinceEpoch(
        (map['last_seen'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      signalStrength: map['signal_strength'] as int? ?? 1,
      isEmergency: (map['is_emergency'] as int? ?? 0) == 1,
    );
  }
}

/// Represents a communication or network level event.
@immutable
class NetworkActivity {
  final int? id;
  final String peerId;
  final String event;
  final String details;
  final DateTime timestamp;

  const NetworkActivity({
    this.id,
    required this.peerId,
    required this.event,
    required this.details,
    required this.timestamp,
  });

  // Compatibility getters for test code
  String get type => event;
  String get description => details;
  String get activityType => event;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'peer_id': peerId,
      'event': event,
      'details': details,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory NetworkActivity.fromMap(Map<String, dynamic> map) {
    return NetworkActivity(
      id: map['id'] as int?,
      peerId: map['peer_id'] as String? ?? 'unknown',
      event: map['event'] as String? ?? 'log',
      details: map['details'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
