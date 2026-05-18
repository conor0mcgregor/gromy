import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'features/auth/presentation/screens/auth_gate_screen.dart';
import 'features/invitation/data/services/deep_link_service.dart';
import 'features/notifications/data/services/fcm_token_service.dart';
import 'features/notifications/data/services/push_notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting();
  // Inicializar Google Sign-In (obligatorio en google_sign_in v7+)
  await GoogleSignIn.instance.initialize(
    clientId: kIsWeb
        ? '863422546089-pqpvbhcc7js8kan7b2j9t2rn73q3uagp.apps.googleusercontent.com'
        : null,
  );

  // ── Notificaciones FCM ──────────────────────────────────────────────────
  // 1. Solicitar permiso al sistema operativo
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // 2. Inicializar token FCM (persistencia en Firestore)
  final fcmTokenService = FcmTokenService();
  await fcmTokenService.initializeToken();

  // 3. Inicializar servicio de Push Notifications (foreground, background, local notifications)
  final pushService = PushNotificationService();
  await pushService.initialize();

  runApp(const MyApp());

  // 4. Inicializar DeepLinkService DESPUÉS de runApp para que el navigator
  //    esté montado cuando se procese el cold start link.
  //    Reutiliza el mismo navigatorKey que PushNotificationService.
  final deepLinkService = DeepLinkService(
    navigatorKey: PushNotificationService.navigatorKey,
  );
  await deepLinkService.initialize();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login',
      navigatorKey: PushNotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGateScreen(),
    );
  }
}

