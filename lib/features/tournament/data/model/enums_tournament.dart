enum TournamentSport {
  football('Futbol'),
  basketball('Baloncesto'),
  volleyball('Voleibol'),
  tennis('Tenis'),
  padel('Padel'),
  karate('Karate'),
  brazilianJiuJitsu('Brazilian Jiu-Jitsu');

  const TournamentSport(this.label);

  final String label;

  static TournamentSport fromValue(String value) {
    return TournamentSport.values.firstWhere(
      (sport) => sport.name == value,
      orElse: () => TournamentSport.football,
    );
  }

  /// Deportes que en este formulario imponen torneo por equipos (switch fijo).
  bool get isTeamOnlyDiscipline {
    return switch (this) {
      TournamentSport.football ||
      TournamentSport.basketball ||
      TournamentSport.volleyball => true,
      _ => false,
    };
  }
}

enum TournamentAccessType {
  publicOpen(
    label: 'Publico abierto',
    description: 'Cualquier usuario puede unirse libremente.',
  ),
  publicClosed(
    label: 'Publico cerrado',
    description:
        'Cualquier usuario puede solicitar acceso y requiere aprobacion.',
  ),
  privateInviteOnly(
    label: 'Privado',
    description: 'Solo se puede acceder mediante invitacion.',
  );

  const TournamentAccessType({required this.label, required this.description});

  final String label;
  final String description;

  static TournamentAccessType fromValue(String value) {
    return TournamentAccessType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => TournamentAccessType.publicOpen,
    );
  }
}

enum TournamentStatus {
  /// Fase 1 — Inscripciones abiertas. Los participantes pueden registrarse.
  registration('Inscripciones abiertas'),

  /// Fase 2 — Brackets publicados. El torneo está en marcha.
  /// Las inscripciones, ediciones y cancelaciones están bloqueadas.
  in_progress('En curso'),

  /// Fase 3 — Todos los resultados subidos. Torneo finalizado.
  /// No aparece en el feed principal; sí en el historial de los participantes.
  completed('Finalizado'),

  /// Estado auxiliar — Borrador local antes de publicar.
  draft('Borrador'),

  /// Estado auxiliar — Torneo cancelado por el organizador.
  cancelled('Cancelado');

  const TournamentStatus(this.label);

  final String label;

  /// Convierte un valor de Firestore al enum correspondiente.
  ///
  /// Compatibilidad hacia atrás:
  ///   - 'published'  → [registration]  (torneos legacy que aceptan inscripciones)
  ///   - 'closed'     → [in_progress]
  ///   - 'finished'   → [completed]
  static TournamentStatus fromValue(String value) {
    final val = value.toLowerCase().trim();
    if (val == 'registration') return TournamentStatus.registration;
    if (val == 'in_progress' || val == 'closed') return TournamentStatus.in_progress;
    if (val == 'completed' || val == 'finished') return TournamentStatus.completed;
    if (val == 'draft') return TournamentStatus.draft;
    if (val == 'cancelled') return TournamentStatus.cancelled;
    // 'published' y cualquier valor desconocido → registration (legacy)
    return TournamentStatus.registration;
  }

  /// Solo [registration] acepta nuevas inscripciones.
  bool get acceptsRegistrations => this == TournamentStatus.registration;

  /// Un torneo bloqueado tiene brackets generados y NO permite modificar
  /// inscripciones, editar datos ni ser eliminado.
  bool get isLocked =>
      this == TournamentStatus.in_progress ||
      this == TournamentStatus.completed;

  /// Solo se puede eliminar un torneo que aún no ha generado brackets.
  bool get canBeDeleted =>
      this == TournamentStatus.registration ||
      this == TournamentStatus.draft;

  /// Aparece en el feed principal de Home (excluye [completed]).
  bool get isActiveInFeed =>
      this == TournamentStatus.registration ||
      this == TournamentStatus.in_progress;

  /// Visible públicamente (excluye borradores y cancelados).
  bool get isPubliclyVisible =>
      this != TournamentStatus.draft &&
      this != TournamentStatus.cancelled;

  /// Torneos que solo deben mostrarse en historial, no en inscripciones activas.
  ///
  /// Incluye estados finalizados (`completed`, legacy `finished`) y
  /// [cancelled].
  bool get isExcludedFromActiveEnrollments =>
      this == TournamentStatus.completed ||
      this == TournamentStatus.cancelled;
}
