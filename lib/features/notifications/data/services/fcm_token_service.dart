import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../repository/notification_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/use_cases/notification_use_cases.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FcmTokenService  ·  Gestión de tokens FCM
//
//  Responsabilidad: registrar/eliminar tokens del dispositivo actual.
//  Se puede llamar desde el inicio de la app y al cerrar sesión.
// ─────────────────────────────────────────────────────────────────────────────

class FcmTokenService {
  FcmTokenService({
    NotificationRepository? repository,
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
  })  : _saveToken = SaveFcmTokenUseCase(
          repository ?? NotificationRepositoryImpl(),
        ),
        _removeToken = RemoveFcmTokenUseCase(
          repository ?? NotificationRepositoryImpl(),
        ),
        _messaging = messaging ?? FirebaseMessaging.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final SaveFcmTokenUseCase _saveToken;
  final RemoveFcmTokenUseCase _removeToken;
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;

  /// Obtiene el token FCM actual y lo persiste en Firestore.
  ///
  /// Debe llamarse al iniciar la app y al detectar cambios de token.
  Future<void> initializeToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await _saveToken(
        userId: user.uid,
        token: token,
        platform: _currentPlatform,
      );

      // Escuchar renovaciones de token
      _messaging.onTokenRefresh.listen((newToken) async {
        final currentUser = _auth.currentUser;
        if (currentUser == null) return;

        await _saveToken(
          userId: currentUser.uid,
          token: newToken,
          platform: _currentPlatform,
        );
      });
    } catch (e) {
      debugPrint('Error inicializando token FCM: $e');
    }
  }

  /// Elimina el token FCM actual (llamar al cerrar sesión).
  Future<void> removeCurrentToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await _removeToken(userId: user.uid, token: token);
    } catch (e) {
      debugPrint('Error eliminando token FCM: $e');
    }
  }

  /// Detecta la plataforma actual.
  String get _currentPlatform {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
    } catch (_) {
      // Platform no disponible (ej: web)
    }
    return 'unknown';
  }
}
