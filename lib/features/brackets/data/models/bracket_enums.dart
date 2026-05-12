// ─────────────────────────────────────────────────────────────────────────────
//  Bracket Enums  ·  Dominio
//
//  Enumeraciones para el sistema de brackets.
//  Cada enum incluye un factory `fromValue` para deserialización segura.
// ─────────────────────────────────────────────────────────────────────────────

/// Estado del bracket completo.
enum BracketStatus {
  draft,
  published,
  active,
  completed,
  cancelled;

  static BracketStatus fromValue(String value) {
    return BracketStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BracketStatus.draft,
    );
  }

  String get label => switch (this) {
    BracketStatus.draft => 'Borrador',
    BracketStatus.published => 'Publicado',
    BracketStatus.active => 'En curso',
    BracketStatus.completed => 'Completado',
    BracketStatus.cancelled => 'Cancelado',
  };

  bool get isDraft => this == BracketStatus.draft;
  bool get isPublished => this == BracketStatus.published;
  bool get isActive => this == BracketStatus.active;
  bool get isCompleted => this == BracketStatus.completed;
  bool get isCancelled => this == BracketStatus.cancelled;

  /// Indica si el bracket es visible para usuarios no-admin.
  bool get isPubliclyVisible =>
      this == BracketStatus.published ||
      this == BracketStatus.active ||
      this == BracketStatus.completed;
}

/// Estado de un match individual.
enum MatchStatus {
  pending,
  scheduled,
  inProgress,
  completed,
  cancelled,
  bye;

  static MatchStatus fromValue(String value) {
    return MatchStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MatchStatus.pending,
    );
  }

  String get label => switch (this) {
    MatchStatus.pending => 'Pendiente',
    MatchStatus.scheduled => 'Programado',
    MatchStatus.inProgress => 'En curso',
    MatchStatus.completed => 'Completado',
    MatchStatus.cancelled => 'Cancelado',
    MatchStatus.bye => 'BYE',
  };
}

/// Tipo de participante en un match (usuario individual o equipo).
enum MatchParticipantType {
  user,
  team;

  static MatchParticipantType fromValue(String value) {
    return MatchParticipantType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MatchParticipantType.user,
    );
  }
}

/// Formato del torneo/bracket.
/// Extensible para futuras modalidades.
enum BracketFormat {
  singleElimination,
  doubleElimination,
  roundRobin,
  swiss;

  static BracketFormat fromValue(String value) {
    return BracketFormat.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BracketFormat.singleElimination,
    );
  }

  String get label => switch (this) {
    BracketFormat.singleElimination => 'Eliminación directa',
    BracketFormat.doubleElimination => 'Doble eliminación',
    BracketFormat.roundRobin => 'Todos contra todos',
    BracketFormat.swiss => 'Sistema suizo',
  };
}
