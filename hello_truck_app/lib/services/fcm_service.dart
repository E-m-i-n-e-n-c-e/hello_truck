// lib/services/ fcm_service.dart
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hello_truck_app/auth/api.dart';
import 'package:hello_truck_app/models/enums/fcm_enums.dart';

import '../utils/logger.dart';

class FCMService {
  final API _api;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  StreamSubscription? _tokenRefreshSubscription;
  StreamSubscription? _foregroundMessageSubscription;
  final StreamController<FcmEventType> _eventController = StreamController<FcmEventType>.broadcast();

  // Stream to listen to FCM events
  Stream<FcmEventType> get eventStream => _eventController.stream;

  FCMService(this._api);


  Future<void> initialize() async {
    if (_isInitialized || _api.accessToken == null) return;

    // Initialize local notifications first
    await _initializeNotifications(_localNotifications);

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

    AppLogger.log('FCM permission status: ${settings.authorizationStatus}');

    final token = await _messaging.getToken();
    AppLogger.log('FCM token: $token');

    if (token != null) {
      await _upsertToken(token);
    }

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
      _upsertToken(newToken);
    });

    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.log('FCM event received: ${message.data['event']}');
      AppLogger.log('FCM foreground messagessssss: ${message.notification?.title} - ${message.notification?.body}');
      if(message.data['event'] != null) {
        _eventController.add(FcmEventType.fromString(message.data['event']!));
      }
      else {
        // Show local notification for foreground messages
        _showNotification(message, _localNotifications);
      }
    });

    _isInitialized = true;
    AppLogger.log('FCM initialized');
  }

  Future<void> stop() async {
    if (!_isInitialized) return;

    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _foregroundMessageSubscription = null;
    _isInitialized = false;

    AppLogger.log('FCM stopped');
  }

  bool get isInitialized => _isInitialized;

  Future<void> _upsertToken(String fcmToken) async {
    try {
      if (_api.accessToken == null) {
        AppLogger.log('FCM upsert skipped: API not ready');
        return;
      }
      await _api.put('/customer/profile/fcm-token', data: { 'fcmToken': fcmToken });
      AppLogger.log('FCM token upserted successfully');
    } catch (e) {
      AppLogger.log('Failed to upsert FCM token: $e');
    }
  }

  // Static method to initialize notifications
  static Future<void> _initializeNotifications(FlutterLocalNotificationsPlugin localNotifications) async {
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

    await localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        AppLogger.log('Local notification tapped: ${response.payload}');
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

    await localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Static method to show notification
  static Future<void> _showNotification(RemoteMessage message, FlutterLocalNotificationsPlugin localNotifications) async {
    if (message.notification?.title != null && message.notification?.body != null) {
      await localNotifications.show(
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

  /// Static background handler to be registered in main()
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

    await _initializeNotifications(localNotifications);

    await _showNotification(message, localNotifications);
  }
}