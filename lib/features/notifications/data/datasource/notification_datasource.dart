import '../../domain/entities/app_notification.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationDatasource  ·  Contrato de acceso a datos
//
//  Abstracción sobre la fuente de datos concreta (Firestore).
//  Permite sustituir la implementación sin tocar la lógica de negocio.
// ─────────────────────────────────────────────────────────────────────────────

abstract interface class NotificationDatasource {
  /// Stream de notificaciones para un usuario, ordenadas descendentemente.
  Stream<List<AppNotification>> watchNotifications({
    required String userId,
    int? limit,
  });

  /// Stream del conteo de notificaciones no leídas.
  Stream<int> watchUnreadCount({required String userId});

  /// Marca una notificación como leída.
  Future<void> markAsRead({required String notificationId});

  /// Marca todas las notificaciones de un usuario como leídas.
  Future<void> markAllAsRead({required String userId});

  /// Marca una notificación como clickeada.
  Future<void> markAsClicked({required String notificationId});

  /// Elimina una notificación.
  Future<void> deleteNotification({required String notificationId});

  /// Elimina todas las notificaciones de un usuario.
  Future<void> deleteAllNotifications({required String userId});

  /// Guarda un token FCM.
  Future<void> saveToken({
    required String userId,
    required String token,
    required String platform,
  });

  /// Elimina un token FCM.
  Future<void> removeToken({
    required String userId,
    required String token,
  });
}
