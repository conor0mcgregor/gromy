import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../repository/notification_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/use_cases/notification_use_cases.dart';

class FcmTokenService {
  static final FcmTokenService _instance = FcmTokenService._internal();
  factory FcmTokenService() => _instance;

  FcmTokenService._internal({
    NotificationRepository? repository,
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
  }) : _saveToken = SaveFcmTokenUseCase(
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

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<User?>? _authStateSub;
  bool _initialized = false;
  String? _lastKnownToken;
  String? _lastSyncedUserId;

  Future<void> initializeToken() async {
    if (_initialized) return;
    _initialized = true;

    _tokenRefreshSub = _messaging.onTokenRefresh.listen(_handleTokenRefresh);
    _authStateSub = _auth.authStateChanges().listen(_handleAuthStateChanged);

    await _syncCurrentSession();
  }

  Future<void> removeCurrentToken() async {
    final userId = _lastSyncedUserId ?? _auth.currentUser?.uid;
    final token = _lastKnownToken ?? await _messaging.getToken();
    if (userId == null || token == null) return;

    try {
      await _removeToken(userId: userId, token: token);
      debugPrint('[FcmTokenService] Token removed for userId=$userId');
    } catch (e) {
      debugPrint('[FcmTokenService] Error removing token: $e');
    }
  }

  Future<void> _syncCurrentSession() async {
    final token = await _messaging.getToken();
    if (token == null) {
      debugPrint('[FcmTokenService] No FCM token available on startup.');
      return;
    }

    _lastKnownToken = token;
    debugPrint('[FcmTokenService] Current token: $token');

    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[FcmTokenService] No authenticated user yet. Token will sync after login.');
      return;
    }

    await _persistToken(user.uid, token);
  }

  Future<void> _handleAuthStateChanged(User? user) async {
    final token = _lastKnownToken ?? await _messaging.getToken();
    if (token == null) return;

    if (_lastSyncedUserId != null && _lastSyncedUserId != user?.uid) {
      try {
        await _removeToken(userId: _lastSyncedUserId!, token: token);
        debugPrint(
          '[FcmTokenService] Removed token from previous userId=$_lastSyncedUserId',
        );
      } catch (e) {
        debugPrint('[FcmTokenService] Error removing previous user token: $e');
      }
    }

    if (user == null) {
      _lastSyncedUserId = null;
      return;
    }

    await _persistToken(user.uid, token);
  }

  Future<void> _handleTokenRefresh(String newToken) async {
    final previousToken = _lastKnownToken;
    _lastKnownToken = newToken;
    debugPrint('[FcmTokenService] Token refreshed: $newToken');

    final user = _auth.currentUser;
    if (user == null) return;

    if (previousToken != null && previousToken != newToken) {
      try {
        await _removeToken(userId: user.uid, token: previousToken);
      } catch (e) {
        debugPrint('[FcmTokenService] Error removing previous token: $e');
      }
    }

    await _persistToken(user.uid, newToken);
  }

  Future<void> _persistToken(String userId, String token) async {
    try {
      await _saveToken(
        userId: userId,
        token: token,
        platform: _currentPlatform,
      );
      _lastSyncedUserId = userId;
      debugPrint('[FcmTokenService] Token persisted for userId=$userId');
    } catch (e) {
      debugPrint('[FcmTokenService] Error persisting token: $e');
    }
  }

  String get _currentPlatform {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
    } catch (_) {}
    return 'unknown';
  }
}
