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
    required this.createdAt,
  });

  /// ID del documento Firestore.
  final String id;

  final String name;

  /// UID del usuario que creó el equipo.
  final String creatorId;

  /// Lista de UIDs de usuarios miembros del equipo.
  final List<String> members;

  final DateTime createdAt;

  // ── Serialización ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'creatorId': creatorId,
        'members': members,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory AppTeam.fromMap(Map<String, dynamic> map) {
    return AppTeam(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      creatorId: map['creatorId'] as String? ?? '',
      members: (map['members'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      createdAt: _dateFromValue(map['createdAt']),
    );
  }

  // ── Copia con modificaciones ───────────────────────────────────────────────

  AppTeam copyWith({
    String? id,
    String? name,
    String? creatorId,
    List<String>? members,
    DateTime? createdAt,
  }) {
    return AppTeam(
      id: id ?? this.id,
      name: name ?? this.name,
      creatorId: creatorId ?? this.creatorId,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}