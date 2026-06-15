import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Background message handler must be top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM-BG] message received: ${message.messageId}');
  debugPrint('[FCM-BG] data: ${message.data}');
  debugPrint('[FCM-BG] notification: ${message.notification?.title}');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'sams_default',
    'SAMS Notifications',
    description: 'Payment alerts, fee updates, and reminders',
    importance: Importance.high,
  );

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('[FCM] Firebase init error: $e');
      return;
    }

    // Request notification permission (Android 13+ and iOS)
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] permission status: ${settings.authorizationStatus}');

    // Setup local notifications for foreground display
    await _setupLocalNotifications();

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Tapped notification while app was background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] notification tapped: ${message.data}');
    });

    // Get initial message if app was opened from terminated state
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] initial message: ${initialMessage.data}');
    }

    // Token refresh listener
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      debugPrint('[FCM] token refreshed: ${token.substring(0, 20)}...');
      _saveTokenToBackend(token);
    });
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotif.initialize(initSettings);

    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM-FG] received: ${message.notification?.title}');
    final notif = message.notification;
    if (notif == null) return;

    _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('[FCM] getToken error: $e');
      return null;
    }
  }

  /// Call this after user logs in successfully.
  /// Registers FCM token with backend so server can send targeted pushes.
  Future<void> registerTokenAfterLogin() async {
    final token = await getToken();
    if (token == null) {
      debugPrint('[FCM] no token to register');
      return;
    }
    debugPrint('[FCM] token: ${token.substring(0, 20)}...');
    await _saveTokenToBackend(token);
  }

  Future<void> _saveTokenToBackend(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');
      if (authToken == null) {
        debugPrint('[FCM] no auth token, skipping registration');
        return;
      }

      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );
      debugPrint('[FCM] register response: ${resp.statusCode}');
    } catch (e) {
      debugPrint('[FCM] register error: $e');
    }
  }

  Future<void> unregisterToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      debugPrint('[FCM] token deleted');
    } catch (e) {
      debugPrint('[FCM] unregister error: $e');
    }
  }
}
