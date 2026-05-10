import '../entities/app_notification.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationRepository  ·  Contrato de dominio
//
//  Define las operaciones que el sistema de notificaciones necesita.
//  Cumple ISP: solo métodos relevantes para notificaciones.
//  Cumple DIP: el dominio no conoce la implementación concreta.
// ─────────────────────────────────────────────────────────────────────────────

abstract interface class NotificationRepository {
  // ── Lectura en tiempo real ─────────────────────────────────────────────────

  /// Stream de notificaciones del usuario, ordenadas por fecha (más recientes primero).
  ///
  /// Opcionalmente se puede limitar con [limit] para paginación futura.
  Stream<List<AppNotification>> watchNotifications({
    required String userId,
    int? limit,
  });

  /// Stream del conteo de notificaciones no leídas para el usuario.
  Stream<int> watchUnreadCount({required String userId});

  // ── Escritura ──────────────────────────────────────────────────────────────

  /// Marca una notificación como leída.
  Future<void> markAsRead({required String notificationId});

  /// Marca todas las notificaciones del usuario como leídas.
  Future<void> markAllAsRead({required String userId});

  /// Marca una notificación como clickeada/interactuada.
  Future<void> markAsClicked({required String notificationId});

  /// Elimina una notificación específica.
  Future<void> deleteNotification({required String notificationId});

  /// Elimina todas las notificaciones del usuario.
  Future<void> deleteAllNotifications({required String userId});

  // ── FCM Tokens ─────────────────────────────────────────────────────────────

  /// Registra un token FCM para el dispositivo actual del usuario.
  Future<void> saveToken({
    required String userId,
    required String token,
    required String platform,
  });

  /// Elimina un token FCM específico (al cerrar sesión o desinstalar).
  Future<void> removeToken({
    required String userId,
    required String token,
  });
}
