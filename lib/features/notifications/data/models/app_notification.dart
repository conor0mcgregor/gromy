import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AppNotification  ·  Dominio
//
//  Notificación in-app almacenada en:
//    users/{userId}/notifications/{notificationId}
// ─────────────────────────────────────────────────────────────────────────────

enum NotificationType {
  joinRequestReceived,
  joinRequestApproved,
  joinRequestRejected,
  inscriptionEdited,
  general;

  static NotificationType fromValue(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.general,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.data = const {},
    this.read = false,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'title': title,
        'body': body,
        'data': data,
        'read': read,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      type: NotificationType.fromValue(map['type'] as String? ?? ''),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      data: (map['data'] as Map<String, dynamic>?) ?? const {},
      read: map['read'] as bool? ?? false,
      createdAt: _dateFromValue(map['createdAt']),
    );
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
