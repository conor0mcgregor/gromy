import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

import '../../presentation/navigation/notification_navigation_handler.dart';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Manejo de notificaciones en background. No requiere inicializar UI.
  debugPrint('[PushNotificationService] Mensaje en background: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'gromy_high_importance_channel', // id
    'Notificaciones Importantes', // title
    description: 'Este canal se usa para notificaciones importantes.', // description
    importance: Importance.max,
  );

  /// Global navigator key para poder navegar cuando se toca la notificación.
  /// Debes configurarla en MaterialApp(navigatorKey: PushNotificationService.navigatorKey)
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _setupLocalNotifications();

    // Foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background (App en segundo plano pero no terminada)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Terminated (App cerrada completamente, se abre al tocar la notificación)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            _navigateFromPayload(data);
          } catch (e) {
            debugPrint('[PushNotificationService] Error parsing payload: $e');
          }
        }
      },
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[PushNotificationService] Mensaje en foreground: ${message.messageId}');
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/launcher_icon',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[PushNotificationService] Notificación tocada (opened app).');
    _navigateFromPayload(message.data);
  }

  void _navigateFromPayload(Map<String, dynamic> data) {
    final route = data['actionRoute']?.toString();
    final context = navigatorKey.currentContext;

    if (context != null && route != null && route.isNotEmpty) {
      debugPrint('[PushNotificationService] Navegando a: $route');
      
      Map<String, dynamic> parsedData = data;
      if (data.containsKey('data') && data['data'] is String) {
        try {
          parsedData = jsonDecode(data['data'] as String) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('[PushNotificationService] Error decodificando data: $e');
        }
      }

      final handled = NotificationNavigationHandler.instance.navigateFromRouteAndData(context, route, parsedData);
      if (!handled) {
        debugPrint('[PushNotificationService] Ningún handler registrado para la ruta: $route');
      }
    } else {
      debugPrint('[PushNotificationService] No se puede navegar: Contexto o ruta nula. Ruta: $route');
    }
  }
}
