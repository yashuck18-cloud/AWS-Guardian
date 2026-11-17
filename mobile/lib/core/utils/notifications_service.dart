import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../firebase_options.dart';
import '../router/app_router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  debugPrint('Handling a background/cold message: ${message.messageId}');
}

class NotificationsService {
  static final NotificationsService _instance = NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Holds pending route when app is opened via notification from cold/terminated state
  String? pendingRoute;

  String? consumePendingRoute() {
    final route = pendingRoute;
    pendingRoute = null;
    return route;
  }

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'aws_guardian_alerts_channel',
    'AWS Guardian Alerts',
    description: 'Real-time security and cost alerts from AWS Guardian',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Local Notification clicked: ${details.payload}');
          _handlePayloadNavigation(details.payload);
        },
      );

      // Request FCM permission (iOS and Android 13+)
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        await androidPlugin.requestNotificationsPermission();
      }

      // Configure foreground notification presentation options
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Mark initialized BEFORE registering listeners to prevent recursive initialization
      _isInitialized = true;

      // Listen to foreground FCM messages and display notification banner
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message received: ${message.messageId}');
        final notification = message.notification;
        if (notification != null) {
          showLocalNotification(
            id: notification.hashCode,
            title: notification.title ?? 'AWS Guardian Alert',
            body: notification.body ?? '',
            payload: jsonEncode(message.data),
          );
        }
      });

      // Handle when user taps on notification and app opens from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification opened from background: ${message.messageId}');
        _handleDataNavigation(message.data);
      });

      // Handle when app is launched directly from terminated state via notification click
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FCM App opened from terminated initialMessage: ${initialMessage.messageId}');
        _handleDataNavigation(initialMessage.data);
      }
    } catch (e) {
      debugPrint('NotificationsService initialization error: $e');
    }
  }

  void _handlePayloadNavigation(String? payloadStr) {
    if (payloadStr == null || payloadStr.isEmpty) return;
    try {
      final data = jsonDecode(payloadStr) as Map<String, dynamic>;
      _handleDataNavigation(data);
    } catch (_) {
      if (payloadStr.startsWith('/')) {
        pendingRoute = payloadStr;
        navigateToPath(payloadStr);
      }
    }
  }

  void _handleDataNavigation(Map<String, dynamic> data) {
    if (data.isEmpty) return;

    final route = data['route']?.toString();
    final alertId = data['alert_id']?.toString();
    final resourceId = data['resource_id']?.toString();

    String targetRoute = '/alerts';
    if (route != null && route.isNotEmpty) {
      targetRoute = route;
    } else if (alertId != null && alertId.isNotEmpty) {
      targetRoute = '/alerts/$alertId';
    } else if (resourceId != null && resourceId.isNotEmpty) {
      targetRoute = '/resources/$resourceId';
    } else {
      targetRoute = '/notifications';
    }

    debugPrint('FCM Notification tapped! Resolved targetRoute: $targetRoute');
    pendingRoute = targetRoute;
    navigateToPath(targetRoute);
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _notificationsPlugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('Error displaying notification: $e');
    }
  }
}
