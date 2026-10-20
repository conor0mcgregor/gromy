// ─────────────────────────────────────────────────────────────────────────────
//  LocalAthlete  ·  Data Model
//
//  Representa un atleta en un torneo local.
//  Solo requiere un nombre; el identificador único se genera internamente.
//  Sin dependencia de Firebase Auth ni de usuarios registrados.
// ─────────────────────────────────────────────────────────────────────────────

class LocalAthlete {
  const LocalAthlete({
    required this.id,
    required this.name,
    this.createdAt,
  });

  /// Identificador único generado localmente (UUID v4-like).
  final String id;

  /// Nombre visible del atleta.
  final String name;

  /// Fecha de creación (para ordenar).
  final DateTime? createdAt;

  // ── Serialización ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory LocalAthlete.fromMap(Map<String, dynamic> map) {
    return LocalAthlete(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }

  LocalAthlete copyWith({String? id, String? name, DateTime? createdAt}) {
    return LocalAthlete(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LocalAthlete && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
