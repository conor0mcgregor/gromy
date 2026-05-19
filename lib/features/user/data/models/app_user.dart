import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo inmutable que representa un usuario de la aplicación.
///
/// Almacenado en Firestore como: /users/{uid}
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.nickname,
    required this.name,
    required this.lastName,
    required this.provider,
    required this.createdAt,
    this.photoUrl,
    this.biography,
    this.isDeleted = false,
    this.deletedAt,
    this.personalDataRemoved = false,
  });

  final String uid;
  final String email;
  final String nickname;
  final String name;
  final String lastName;
  final String provider; // 'email' | 'google' | 'apple'
  final DateTime createdAt;
  final String? photoUrl;
  final String? biography;
  final bool isDeleted;
  final DateTime? deletedAt;
  final bool personalDataRemoved;

  // ── Serialización ───────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'nickname': nickname,
    'name': name,
    'lastName': lastName,
    'provider': provider,
    'photoUrl': photoUrl,
    'biography': biography,
    'createdAt': Timestamp.fromDate(createdAt),
    'isDeleted': isDeleted,
    'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    'personalDataRemoved': personalDataRemoved,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    uid: map['uid'] as String,
    email: map['email'] as String? ?? '',
    nickname: map['nickname'] as String? ?? 'usuario_eliminado',
    name: map['name'] as String? ?? 'Usuario',
    lastName: map['lastName'] as String? ?? 'eliminado',
    provider: map['provider'] as String? ?? 'unknown',
    photoUrl: map['photoUrl'] as String?,
    biography: map['biography'] as String?,
    createdAt: _dateFromValue(map['createdAt']),
    isDeleted: map['isDeleted'] as bool? ?? false,
    deletedAt: _nullableDateFromValue(map['deletedAt']),
    personalDataRemoved: map['personalDataRemoved'] as bool? ?? false,
  );

  // ── Copia con modificaciones ────────────────────────────────────────────────

  AppUser copyWith({
    String? nickname,
    String? name,
    String? lastName,
    String? photoUrl,
    String? biography,
    bool? isDeleted,
    DateTime? deletedAt,
    bool? personalDataRemoved,
  }) => AppUser(
    uid: uid,
    email: email,
    nickname: nickname ?? this.nickname,
    name: name ?? this.name,
    lastName: lastName ?? this.lastName,
    provider: provider,
    createdAt: createdAt,
    photoUrl: photoUrl ?? this.photoUrl,
    biography: biography ?? this.biography,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt ?? this.deletedAt,
    personalDataRemoved: personalDataRemoved ?? this.personalDataRemoved,
  );

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static DateTime? _nullableDateFromValue(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
