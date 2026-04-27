import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AppTeam  ·  Dominio
//
//  Representa un equipo registrado de forma independiente.
//  Se persiste en la colección raíz:  teams/{teamId}
//
//  Decisión de diseño: colección raíz en lugar de subcolección de torneo
//  para permitir que un equipo participe en múltiples torneos sin duplicar
//  su información. Los participantes sólo guardan una referencia (entityId).
// ─────────────────────────────────────────────────────────────────────────────

class AppTeam {
  const AppTeam({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.members,
    required this.adminIds,
    required this.createdAt,
    this.photoUrl,
  });

  /// ID del documento Firestore.
  final String id;

  final String name;

  /// UID del usuario que creó el equipo.
  final String creatorId;

  /// Lista de UIDs de usuarios miembros del equipo.
  final List<String> members;

  /// Lista de UIDs de administradores del equipo.
  /// El creador siempre es administrador.
  final List<String> adminIds;

  final DateTime createdAt;

  /// URL de la foto de perfil del equipo (puede ser null).
  final String? photoUrl;

  /// Devuelve true si [userId] es administrador del equipo.
  bool isAdmin(String userId) => adminIds.contains(userId);

  /// Devuelve true si [userId] es miembro del equipo.
  bool isMember(String userId) => members.contains(userId);

  // ── Serialización ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'creatorId': creatorId,
        'members': members,
        'adminIds': adminIds,
        'photoUrl': photoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory AppTeam.fromMap(Map<String, dynamic> map) {
    final creatorId = map['creatorId'] as String? ?? '';
    final adminIds = (map['adminIds'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => e.toString())
        .toList();

    // Retrocompatibilidad: si no hay adminIds, el creador es admin.
    if (adminIds.isEmpty && creatorId.isNotEmpty) {
      adminIds.add(creatorId);
    }

    return AppTeam(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      creatorId: creatorId,
      members: (map['members'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      adminIds: adminIds,
      photoUrl: map['photoUrl'] as String?,
      createdAt: _dateFromValue(map['createdAt']),
    );
  }

  // ── Copia con modificaciones ───────────────────────────────────────────────

  AppTeam copyWith({
    String? id,
    String? name,
    String? creatorId,
    List<String>? members,
    List<String>? adminIds,
    DateTime? createdAt,
    String? photoUrl,
  }) {
    return AppTeam(
      id: id ?? this.id,
      name: name ?? this.name,
      creatorId: creatorId ?? this.creatorId,
      members: members ?? this.members,
      adminIds: adminIds ?? this.adminIds,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}