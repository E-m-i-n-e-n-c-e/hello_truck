// lib/services/ fcm_service.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hello_truck_app/auth/api.dart';
import 'package:hello_truck_app/models/enums/fcm_enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

// Background FCM handler must be a top-level function and annotated for AOT
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  await FCMService._initializeNotifications(localNotifications);

  // Show notification only if the default notification payload is null
  // and data contains title & body
  final hasNotification = message.notification != null;
  final hasDataTitle = message.data['title'] != null;
  final hasDataBody = message.data['body'] != null;

  if (!hasNotification && hasDataTitle && hasDataBody) {
    await FCMService._showNotification(
      RemoteMessage(
        data: message.data,
        notification: RemoteNotification(
          title: message.data['title'],
          body: message.data['body'],
        ),
      ),
      localNotifications,
    );
  }

  developer.log('🔥 Background FCM received: ${message.data}');
  final event = message.data['event'];
  if (event != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Ensure latest values from disk
    final pendingEvents = prefs.getStringList('pending_events') ?? [];
    await prefs.setStringList('pending_events', [...pendingEvents, event]);
    developer.log('FCM background message pending events: $pendingEvents');
  }
}

class FCMService {
  late API _api;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  StreamSubscription? _tokenRefreshSubscription;
  StreamSubscription? _foregroundMessageSubscription;
  final StreamController<FcmEventType> _eventController = StreamController<FcmEventType>.broadcast();

  // Stream to listen to FCM events
  Stream<FcmEventType> get eventStream => _eventController.stream;

  // Function to allow others to add events to the controller
  void addEvent(FcmEventType event) {
    _eventController.add(event);
  }

  FCMService();

  Future<void> initialize(API api) async {
    if (_isInitialized) return;
    _api = api;

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
}