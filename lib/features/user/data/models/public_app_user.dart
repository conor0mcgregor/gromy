/// Modelo inmutable que representa la información pública de un usuario.
///
/// Utilizado para mostrar el perfil de otros usuarios sin exponer
/// información sensible como el correo electrónico o la fecha de registro.
class PublicAppUser {
  const PublicAppUser({
    required this.uid,
    required this.nickname,
    required this.name,
    required this.lastName,
    this.photoUrl,
    this.biography,
  });

  final String uid;
  final String nickname;
  final String name;
  final String lastName;
  final String? photoUrl;
  final String? biography;

  // ── Serialización ───────────────────────────────────────────────────────────

  factory PublicAppUser.fromMap(Map<String, dynamic> map) => PublicAppUser(
    uid: map['uid'] as String,
    nickname: map['nickname'] as String,
    name: map['name'] as String,
    lastName: map['lastName'] as String,
    photoUrl: map['photoUrl'] as String?,
    biography: map['biography'] as String?,
  );
}
