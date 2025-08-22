// lib/services/ fcm_service.dart
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hello_truck_app/auth/api.dart';

class FCMService {
  final API _api;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  StreamSubscription? _tokenRefreshSubscription;
  StreamSubscription? _foregroundMessageSubscription;

  FCMService(this._api);

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) debugPrint('Local notification tapped: ${response.payload}');
        // Handle notification tap here
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'fcm_default_channel',
      'FCM Notifications',
      description: 'Your notifications from the app',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> initialize() async {
    if (_isInitialized || _api.accessToken == null) return;

    // Initialize local notifications first
    await _initializeLocalNotifications();

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false, // Prevent duplicate notifications on iOS
      sound: false,
      badge: false,
    );

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) debugPrint('FCM permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await _messaging.getToken();
      if (kDebugMode) debugPrint('FCM token: $token');

      if (token != null) {
        await _upsertToken(token);
      }

      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
        _upsertToken(newToken);
      });

      _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) debugPrint('FCM foreground message: ${message.notification?.title} - ${message.notification?.body}');

        // Show local notification for foreground messages
        _showLocalNotification(message);
      });

      _isInitialized = true;
      if (kDebugMode) debugPrint('FCM initialized');
    } else {
      if (kDebugMode) debugPrint('FCM permission denied');
    }
  }

  Future<void> stop() async {
    if (!_isInitialized) return;

    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _foregroundMessageSubscription = null;
    _isInitialized = false;

    if (kDebugMode) debugPrint('FCM stopped');
  }

  bool get isInitialized => _isInitialized;

  Future<void> _upsertToken(String fcmToken) async {
    try {
      if (_api.accessToken == null) {
        if (kDebugMode) debugPrint('FCM upsert skipped: API not ready');
        return;
      }
      await _api.put('/customer/profile/fcm-token', data: { 'fcmToken': fcmToken });
      if (kDebugMode) debugPrint('FCM token upserted successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to upsert FCM token: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (message.notification != null) {
      await _localNotifications.show(
        message.notification!.hashCode,
        message.notification!.title,
        message.notification!.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'fcm_default_channel',
            'FCM Notifications',
            channelDescription: 'Your notifications from the app',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }
}