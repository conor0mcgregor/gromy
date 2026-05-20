import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repository/notification_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/use_cases/notification_use_cases.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationsController  ·  Estado y lógica de presentación
//
//  Orquesta los use cases y expone el estado reactivo a la UI.
//  Usa ChangeNotifier para compatibilidad con el patrón existente del proyecto.
// ─────────────────────────────────────────────────────────────────────────────

/// Estados posibles de la pantalla de notificaciones.
enum NotificationsState { loading, loaded, empty, error }

class NotificationsController extends ChangeNotifier {
  NotificationsController({NotificationRepository? repository})
    : _repository = repository;

  NotificationRepository? _repository;
  bool _useCasesReady = false;

  // Use cases
  late final WatchNotificationsUseCase _watchNotifications;
  late final WatchUnreadCountUseCase _watchUnreadCount;
  late final MarkAsReadUseCase _markAsRead;
  late final MarkAllAsReadUseCase _markAllAsRead;
  late final MarkAsClickedUseCase _markAsClicked;
  late final UpdateNotificationDataUseCase _updateNotificationData;
  late final DeleteNotificationUseCase _deleteNotification;
  late final DeleteAllNotificationsUseCase _deleteAllNotifications;

  // ── Estado reactivo ────────────────────────────────────────────────────────

  NotificationsState _state = NotificationsState.loading;
  NotificationsState get state => _state;

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription<List<AppNotification>>? _notificationsSub;
  StreamSubscription<int>? _unreadCountSub;
  String? _activeUserId;

  void _ensureUseCases() {
    if (_useCasesReady) return;
    final repository = _repository ??= NotificationRepositoryImpl();
    _watchNotifications = WatchNotificationsUseCase(repository);
    _watchUnreadCount = WatchUnreadCountUseCase(repository);
    _markAsRead = MarkAsReadUseCase(repository);
    _markAllAsRead = MarkAllAsReadUseCase(repository);
    _markAsClicked = MarkAsClickedUseCase(repository);
    _updateNotificationData = UpdateNotificationDataUseCase(repository);
    _deleteNotification = DeleteNotificationUseCase(repository);
    _deleteAllNotifications = DeleteAllNotificationsUseCase(repository);
    _useCasesReady = true;
  }

  // ── Inicialización ─────────────────────────────────────────────────────────

  /// Inicia la escucha en tiempo real de las notificaciones del usuario.
  void init(String userId) {
    if (_activeUserId == userId && _notificationsSub != null) {
      // La pantalla puede montarse después de que el stream ya emitió datos.
      notifyListeners();
      return;
    }
    _ensureUseCases();

    _activeUserId = userId;
    _state = NotificationsState.loading;
    _errorMessage = null;
    // No notifyListeners aquí: puede llamarse durante el build (p. ej. IndexedStack).

    _notificationsSub?.cancel();
    _unreadCountSub?.cancel();

    _notificationsSub = _watchNotifications(userId: userId).listen(
      (data) {
        _notifications = data;
        _state = data.isEmpty
            ? NotificationsState.empty
            : NotificationsState.loaded;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _state = NotificationsState.error;
        _errorMessage = 'Error al cargar notificaciones: $error';
        notifyListeners();
      },
    );

    _unreadCountSub = _watchUnreadCount(userId: userId).listen(
      (count) {
        _unreadCount = count;
        notifyListeners();
      },
      onError: (_) {
        // Silenciar errores del conteo; el stream principal ya gestiona el error.
      },
    );
  }

  // ── Acciones ───────────────────────────────────────────────────────────────

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      _ensureUseCases();
      await _markAsRead(notificationId: notificationId);
    } catch (e) {
      debugPrint('Error marcando como leída: $e');
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      _ensureUseCases();
      await _markAllAsRead(userId: userId);
    } catch (e) {
      debugPrint('Error marcando todas como leídas: $e');
    }
  }

  Future<void> markNotificationAsClicked(String notificationId) async {
    try {
      _ensureUseCases();
      await _markAsClicked(notificationId: notificationId);
    } catch (e) {
      debugPrint('Error marcando como clickeada: $e');
    }
  }

  Future<void> updateNotificationData(
    String notificationId,
    Map<String, dynamic> data,
  ) async {
    try {
      _ensureUseCases();
      await _updateNotificationData(notificationId: notificationId, data: data);
    } catch (e) {
      debugPrint('Error actualizando datos de notificacion: $e');
    }
  }

  Future<void> removeNotification(String notificationId) async {
    try {
      _ensureUseCases();
      await _deleteNotification(notificationId: notificationId);
    } catch (e) {
      debugPrint('Error eliminando notificación: $e');
    }
  }

  Future<void> removeAllNotifications(String userId) async {
    try {
      _ensureUseCases();
      await _deleteAllNotifications(userId: userId);
    } catch (e) {
      debugPrint('Error eliminando todas las notificaciones: $e');
    }
  }

  // ── Limpieza ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _notificationsSub?.cancel();
    _unreadCountSub?.cancel();
    super.dispose();
  }
}
