import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Use Cases  ·  Capa de dominio
//
//  Cada use case encapsula una única operación de negocio (SRP).
//  Dependen de la abstracción [NotificationRepository] (DIP).
// ─────────────────────────────────────────────────────────────────────────────

/// Observa las notificaciones del usuario en tiempo real.
class WatchNotificationsUseCase {
  const WatchNotificationsUseCase(this._repository);
  final NotificationRepository _repository;

  Stream<List<AppNotification>> call({
    required String userId,
    int? limit,
  }) {
    return _repository.watchNotifications(userId: userId, limit: limit);
  }
}

/// Observa el conteo de notificaciones no leídas.
class WatchUnreadCountUseCase {
  const WatchUnreadCountUseCase(this._repository);
  final NotificationRepository _repository;

  Stream<int> call({required String userId}) {
    return _repository.watchUnreadCount(userId: userId);
  }
}

/// Marca una notificación como leída.
class MarkAsReadUseCase {
  const MarkAsReadUseCase(this._repository);
  final NotificationRepository _repository;

  Future<void> call({required String notificationId}) {
    return _repository.markAsRead(notificationId: notificationId);
  }
}

/// Marca todas las notificaciones del usuario como leídas.
class MarkAllAsReadUseCase {
  const MarkAllAsReadUseCase(this._repository);
  final NotificationRepository _repository;

  Future<void> call({required String userId}) {
    return _repository.markAllAsRead(userId: userId);
  }
}

/// Marca una notificación como clickeada/interactuada.
class MarkAsClickedUseCase {
  const MarkAsClickedUseCase(this._repository);
  final NotificationRepository _repository;

  Future<void> call({required String notificationId}) {
    return _repository.markAsClicked(notificationId: notificationId);
  }
}

/// Elimina una notificación específica.
class DeleteNotificationUseCase {
  const DeleteNotificationUseCase(this._repository);
  final NotificationRepository _repository;

  Future<void> call({required String notificationId}) {
    return _repository.deleteNotification(notificationId: notificationId);
  }
}

/// Elimina todas las notificaciones del usuario.
class DeleteAllNotificationsUseCase {
  const DeleteAllNotificationsUseCase(this._repository);
  final NotificationRepository _repository;

  Future<void> call({required String userId}) {
    return _repository.deleteAllNotifications(userId: userId);
  }
}

/// Guarda un token FCM del dispositivo actual.
class SaveFcmTokenUseCase {
  const SaveFcmTokenUseCase(this._repository);
  final NotificationRepository _repository;

  Future<void> call({
    required String userId,
    required String token,
    required String platform,
  }) {
    return _repository.saveToken(
      userId: userId,
      token: token,
      platform: platform,
    );
  }
}

/// Elimina un token FCM (al cerrar sesión).
class RemoveFcmTokenUseCase {
  const RemoveFcmTokenUseCase(this._repository);
  final NotificationRepository _repository;

  Future<void> call({
    required String userId,
    required String token,
  }) {
    return _repository.removeToken(userId: userId, token: token);
  }
}
