import 'package:cloud_firestore/cloud_firestore.dart';

import 'notification_type.dart';

/// Entidad de dominio que representa una notificación persistente.
///
/// Cada instancia corresponde a un documento en `notifications/{id}`.
/// Diseñada para ser inmutable y extensible a nuevos tipos sin romper
/// implementaciones existentes (OCP).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.clicked = false,
    this.readAt,
    this.expiresAt,
    this.actionRoute,
    this.data = const {},
  });

  /// Identificador único del documento en Firestore.
  final String id;

  /// UID del usuario destinatario.
  final String userId;

  /// Tipo de notificación (extensible mediante [NotificationType]).
  final String type;

  /// Título corto que se muestra en la tarjeta y en la push notification.
  final String title;

  /// Cuerpo descriptivo de la notificación.
  final String body;

  /// Indica si el usuario ya leyó esta notificación.
  final bool read;

  /// Indica si el usuario hizo tap / interactuó con la notificación.
  final bool clicked;

  /// Fecha de creación del documento.
  final DateTime createdAt;

  /// Fecha en la que se marcó como leída (null si aún no leída).
  final DateTime? readAt;

  /// Fecha de expiración opcional (para limpieza futura).
  final DateTime? expiresAt;

  /// Ruta de navegación contextual (ej: `/tournament/abc123`).
  final String? actionRoute;

  /// Datos adicionales para la navegación o visualización contextual.
  final Map<String, dynamic> data;

  // ── Serialización ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'read': read,
      'clicked': clicked,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'actionRoute': actionRoute,
      'data': data,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? NotificationType.general,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      read: map['read'] as bool? ?? false,
      clicked: map['clicked'] as bool? ?? false,
      createdAt: _dateFromValue(map['createdAt']),
      readAt: _nullableDateFromValue(map['readAt']),
      expiresAt: _nullableDateFromValue(map['expiresAt']),
      actionRoute: map['actionRoute'] as String?,
      data: (map['data'] as Map<String, dynamic>?) ?? const {},
    );
  }

  // ── copyWith ───────────────────────────────────────────────────────────────

  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    bool? read,
    bool? clicked,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? expiresAt,
    String? actionRoute,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      read: read ?? this.read,
      clicked: clicked ?? this.clicked,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      expiresAt: expiresAt ?? this.expiresAt,
      actionRoute: actionRoute ?? this.actionRoute,
      data: data ?? this.data,
    );
  }

  // ── Helpers de fecha ───────────────────────────────────────────────────────

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _nullableDateFromValue(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  /// Helper para obtener el [NotificationType] resuelto.
  /// Devuelve el String directamente para mantener extensibilidad.
  bool get isUnread => !read;

  @override
  String toString() => 'AppNotification(id: $id, type: $type, title: $title)';
}
