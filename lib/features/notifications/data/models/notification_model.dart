import '../../domain/entities/app_notification.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationModel  ·  Capa de datos
//
//  Extiende la entidad de dominio con métodos de serialización específicos
//  de Firestore. Actúa como DTO entre Firestore y la capa de dominio.
// ─────────────────────────────────────────────────────────────────────────────

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.body,
    required super.createdAt,
    super.read,
    super.clicked,
    super.readAt,
    super.expiresAt,
    super.actionRoute,
    super.data,
  });

  /// Crea un [NotificationModel] a partir de un mapa de Firestore.
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    final base = AppNotification.fromMap(map);
    return NotificationModel(
      id: base.id,
      userId: base.userId,
      type: base.type,
      title: base.title,
      body: base.body,
      createdAt: base.createdAt,
      read: base.read,
      clicked: base.clicked,
      readAt: base.readAt,
      expiresAt: base.expiresAt,
      actionRoute: base.actionRoute,
      data: base.data,
    );
  }

  /// Convierte una entidad de dominio a modelo de datos.
  factory NotificationModel.fromEntity(AppNotification entity) {
    return NotificationModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type,
      title: entity.title,
      body: entity.body,
      createdAt: entity.createdAt,
      read: entity.read,
      clicked: entity.clicked,
      readAt: entity.readAt,
      expiresAt: entity.expiresAt,
      actionRoute: entity.actionRoute,
      data: entity.data,
    );
  }
}
