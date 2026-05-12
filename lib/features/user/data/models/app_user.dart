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
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    uid: map['uid'] as String,
    email: map['email'] as String,
    nickname: map['nickname'] as String,
    name: map['name'] as String,
    lastName: map['lastName'] as String,
    provider: map['provider'] as String,
    photoUrl: map['photoUrl'] as String?,
    biography: map['biography'] as String?,
    createdAt: (map['createdAt'] as Timestamp).toDate(),
  );

  // ── Copia con modificaciones ────────────────────────────────────────────────

  AppUser copyWith({
    String? nickname,
    String? name,
    String? lastName,
    String? photoUrl,
    String? biography,
  }) =>
      AppUser(
        uid: uid,
        email: email,
        nickname: nickname ?? this.nickname,
        name: name ?? this.name,
        lastName: lastName ?? this.lastName,
        provider: provider,
        createdAt: createdAt,
        photoUrl: photoUrl ?? this.photoUrl,
        biography: biography ?? this.biography,
      );
}
