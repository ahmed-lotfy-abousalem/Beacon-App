# Peer Notification System Implementation Guide

## Overview

A complete notification system has been implemented for the Beacon app that automatically notifies users when peers join or leave the P2P network. This includes both system notifications and in-app visual feedback.

## Architecture

### Components

1. **NotificationService** (`lib/services/notification_service.dart`)
   - Manages local notifications using `flutter_local_notifications`
   - Provides peer-specific notification methods
   - Emits notification events for UI updates
   - Handles notification permissions (iOS)

2. **P2PService Enhanced** (`lib/services/p2p_service.dart`)
   - Now emits `PeerEvent` stream with peer join/leave events
   - Detects peer changes automatically
   - Maintains peer list synchronization

3. **PeerNotificationViewModel** (`lib/presentation/viewmodels/peer_notification_view_model.dart`)
   - Manages peer event listening
   - Integrates with NotificationService
   - Provides UI state and callbacks
   - Maintains active peer list

4. **ChatPageMVVM Enhanced** (`lib/presentation/pages/chat_page_mvvm.dart`)
   - Integrated PeerNotificationViewModel
   - Shows peer count in AppBar subtitle
   - Displays in-app notifications (snackbars)
   - Provides visual feedback for peer events

## Key Features

### 1. Automatic Peer Detection
- P2PService automatically detects when new peers appear in the network
- Compares peer lists to identify joins and leaves
- Emits typed `PeerEvent` objects with peer information

### 2. Multi-Layer Notifications
- **System Notifications**: Using flutter_local_notifications
- **In-App Notifications**: Styled snackbars with icons and colors
- **UI Updates**: Real-time peer list and count display

### 3. Event Streaming
```dart
// Listen to peer events
_p2pService.peerEventStream.listen((event) {
  if (event.type == 'joined') {
    // Handle peer join
  } else if (event.type == 'left') {
    // Handle peer leave
  }
});

// Get peer list updates
_p2pService.peersStream.listen((peers) {
  // Update UI with new peer list
});
```

### 4. Notification Types

#### Peer Joined
- Title: "Peer Joined"
- Body: "{Peer Name} has joined the network"
- Icon: login icon (green)
- System notification with sound

#### Peer Left
- Title: "Peer Left"
- Body: "{Peer Name} has left the network"
- Icon: logout icon (red)
- System notification with sound

### 5. Real-Time Peer Status
AppBar displays:
- "1 peer: {Name}" (single peer)
- "N peers: {Names}" (multiple peers)
- "No peers connected" (idle state)

## Usage

### Initialize Notifications in Any Screen
```dart
late PeerNotificationViewModel _peerNotificationViewModel;

@override
void initState() {
  super.initState();
  _peerNotificationViewModel = PeerNotificationViewModel();
  
  // Set callbacks
  _peerNotificationViewModel.onPeerJoined = (device) {
    // Handle peer joined
  };
  
  _peerNotificationViewModel.onPeerLeft = (device) {
    // Handle peer left
  };
  
  // Initialize
  _peerNotificationViewModel.initialize();
}

@override
void dispose() {
  _peerNotificationViewModel.dispose();
  super.dispose();
}
```

### Show Custom Notifications
```dart
final notificationService = NotificationService();
await notificationService.initialize();

// Show peer joined notification
await notificationService.showPeerJoinedNotification(
  peerName: 'Emergency Responder',
  peerId: 'device123',
);

// Show custom message notification
await notificationService.showMessageNotification(
  senderName: 'John Doe',
  messagePreview: 'Emergency detected',
  senderId: 'sender123',
);
```

## Data Flow

```
P2PService (WiFi Direct)
    ↓
[Detects peer changes]
    ↓
Emits PeerEvent('joined'/'left', device)
    ↓
PeerNotificationViewModel listens
    ↓
NotificationService.showPeerXxxNotification()
    ↓
System Notification + In-App Snackbar + UI Update
```

## Integration Points

### 1. ChatPageMVVM
Already integrated with:
- Peer status display in AppBar
- Peer join/leave snackbar notifications
- Real-time peer count updates

### 2. Other Pages
Can be integrated similarly by:
1. Creating PeerNotificationViewModel instance
2. Setting up callbacks
3. Calling `initialize()`
4. Handling notifications as needed

### 3. Custom Notifications
For other events (messages, emergencies):
```dart
await NotificationService().showMessageNotification(
  senderName: sender,
  messagePreview: preview,
);
```

## Platform Support

### Android
- ✅ Full support with channels
- ✅ Sound and vibration
- ✅ Icons and colors
- Requires: Android 5.0+

### iOS
- ✅ Full support with permissions
- ✅ Alert, badge, and sound
- Requests permissions on first initialization
- Requires: iOS 9.0+

### Linux
- ✅ Basic support
- Uses D-Bus notifications
- Requires: systemd user session

## Configuration

### Notification Channels (Android)
Channel: `peer_notifications`
- Name: "Peer Notifications"
- Description: "Notifications for peer join/leave events"
- Importance: Maximum
- Sound: Enabled
- Vibration: Enabled

### iOS Permissions
Requested on initialization:
- Alert permission
- Badge permission
- Sound permission

## Testing

### Test Peer Joins
1. Open the app on one device
2. Open the app on another device
3. Both devices should see peer notifications
4. AppBar subtitle should update with peer count

### Test Peer Leaves
1. Close or disable WiFi on one device
2. Other device should see "Peer Left" notification
3. AppBar should update peer count

### Test Notifications
1. Notifications appear as system notifications
2. In-app snackbars show with icons and colors
3. Multiple notifications queue properly

## Best Practices

1. **Initialize Early**: Call `PeerNotificationViewModel.initialize()` in initState
2. **Clean Up**: Always call `dispose()` to close streams
3. **Check Mounted**: Use `if (mounted)` before setState operations
4. **Handle Errors**: NotificationService initializes gracefully if not available
5. **Minimal Permissions**: Only requests necessary notification permissions

## Future Enhancements

1. **Notification History**: Store recent peer join/leave events
2. **Notification Preferences**: Allow users to customize notification behavior
3. **Custom Sounds**: Different sounds for different event types
4. **Notification Actions**: Quick actions from notification (e.g., "Call", "Message")
5. **Persistent Notification**: Option to show always-on peer list notification
6. **Notification Badges**: Badge count for unread notifications

## Dependencies Added

```yaml
flutter_local_notifications: ^18.0.0
```

This package handles:
- Local notifications on Android, iOS, and Linux
- Permission management
- Notification lifecycle
- User interaction handling

## Files Modified/Created

### Created:
- `lib/services/notification_service.dart` - Notification management
- `lib/presentation/viewmodels/peer_notification_view_model.dart` - Peer notification logic

### Modified:
- `lib/services/p2p_service.dart` - Added peer event streaming
- `lib/presentation/pages/chat_page_mvvm.dart` - Integrated notifications
- `pubspec.yaml` - Added flutter_local_notifications dependency

## Summary

The notification system is fully integrated and operational. Peers will now receive immediate notifications when other users join or leave the network, enhancing awareness and communication during emergency situations.
