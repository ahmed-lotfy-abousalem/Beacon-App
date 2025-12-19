import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Notification event emitted by NotificationService
class NotificationEvent {
  final String type; // 'peer_joined', 'peer_left', 'message', etc.
  final String title;
  final String body;
  final Map<String, dynamic>? data;

  NotificationEvent({
    required this.type,
    required this.title,
    required this.body,
    this.data,
  });
}

/// Service to manage local and system notifications
/// 
/// This service provides:
/// - Local notifications for peer join/leave events
/// - Message notifications
/// - Sound and vibration support
/// - Notification event streaming for UI updates
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final _notificationEventController =
      StreamController<NotificationEvent>.broadcast();

  bool _isInitialized = false;

  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  /// Get stream of notification events
  Stream<NotificationEvent> get notificationEventStream =>
      _notificationEventController.stream;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Linux initialization settings
    const LinuxInitializationSettings linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    // Initialize with all platform settings
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );

    // Request Android notification permission (Android 13+)
    print('🔔 Requesting Android notification permission');
    final androidPermission = await Permission.notification.request();
    print('🔔 Android notification permission: $androidPermission');

    // Request iOS permissions
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    _isInitialized = true;
    print('✅ Notification service initialized');
  }

  /// Show a simple notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    bool withSound = true,
    bool withVibration = true,
  }) async {
    print('📢 NotificationService.showNotification: $title - $body');
    if (!_isInitialized) {
      print('⚠️ NotificationService not initialized, initializing now...');
      await initialize();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'peer_notifications',
      'Peer Notifications',
      channelDescription: 'Notifications for peer join/leave events',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    print('🔔 Calling _notificationsPlugin.show()');
    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
      payload: payload,
    );
    print('✅ Notification shown successfully');
  }

  /// Show a peer joined notification
  Future<void> showPeerJoinedNotification({
    required String peerName,
    String? peerId,
  }) async {
    print('🔔 NotificationService: Showing peer joined notification for $peerName');
    final title = 'Peer Joined';
    final body = '$peerName has joined the network';

    await showNotification(
      title: title,
      body: body,
      payload: 'peer_joined:$peerId',
    );

    // Emit event for UI updates
    print('📡 Emitting peer joined event');
    _notificationEventController.add(
      NotificationEvent(
        type: 'peer_joined',
        title: title,
        body: body,
        data: {'peerId': peerId, 'peerName': peerName},
      ),
    );
  }

  /// Show a peer left notification
  Future<void> showPeerLeftNotification({
    required String peerName,
    String? peerId,
  }) async {
    final title = 'Peer Left';
    final body = '$peerName has left the network';

    await showNotification(
      title: title,
      body: body,
      payload: 'peer_left:$peerId',
    );

    // Emit event for UI updates
    _notificationEventController.add(
      NotificationEvent(
        type: 'peer_left',
        title: title,
        body: body,
        data: {'peerId': peerId, 'peerName': peerName},
      ),
    );
  }

  /// Show a new message notification
  Future<void> showMessageNotification({
    required String senderName,
    required String messagePreview,
    String? senderId,
  }) async {
    final title = 'New message from $senderName';
    final body = messagePreview.length > 100
        ? '${messagePreview.substring(0, 100)}...'
        : messagePreview;

    await showNotification(
      title: title,
      body: body,
      payload: 'message:$senderId',
    );

    // Emit event for UI updates
    _notificationEventController.add(
      NotificationEvent(
        type: 'message',
        title: title,
        body: body,
        data: {'senderId': senderId, 'senderName': senderName},
      ),
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      print('Notification tapped with payload: $payload');
      // Emit tap event for navigation logic
      _notificationEventController.add(
        NotificationEvent(
          type: 'tap',
          title: 'Notification Tap',
          body: 'Payload: $payload',
          data: {'payload': payload},
        ),
      );
    }
  }

  /// Static method for background notification handling
  static void _notificationTapBackground(
      NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    _instance._handleNotificationTap(payload);
  }

  /// Cancel a notification by id
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Dispose the service
  void dispose() {
    _notificationEventController.close();
  }
}
