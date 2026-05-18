import '../models/app_notification.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationRepository  ·  Contrato de dominio
// ─────────────────────────────────────────────────────────────────────────────

abstract interface class NotificationRepository {
  /// Crea una notificación para el usuario [userId].
  Future<void> createNotification(AppNotification notification);

  /// Stream en tiempo real de notificaciones del usuario.
  Stream<List<AppNotification>> watchUserNotifications(String userId);

  /// Marca una notificación como leída.
  Future<void> markAsRead(String userId, String notificationId);

  /// Marca todas las notificaciones del usuario como leídas.
  Future<void> markAllAsRead(String userId);

  /// Cuenta notificaciones no leídas del usuario.
  Stream<int> watchUnreadCount(String userId);
}
