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
  registration('Inscripciones abiertas'),
  in_progress('En curso / Inscripciones cerradas'),
  completed('Finalizado'),
  draft('Borrador'),
  published('Publicado'),
  closed('Cerrado'),
  finished('Finalizado'),
  cancelled('Cancelado');

  const TournamentStatus(this.label);

  final String label;

  static TournamentStatus fromValue(String value) {
    final val = value.toLowerCase().trim();
    if (val == 'registration' || val == 'published' || val == 'draft') {
      return TournamentStatus.registration;
    }
    if (val == 'in_progress' || val == 'closed' || val == 'cancelled') {
      return TournamentStatus.in_progress;
    }
    if (val == 'completed' || val == 'finished') {
      return TournamentStatus.completed;
    }
    return TournamentStatus.registration;
  }

  bool get acceptsRegistrations => this == TournamentStatus.registration;
  bool get isPubliclyVisible =>
      this == TournamentStatus.registration ||
      this == TournamentStatus.in_progress ||
      this == TournamentStatus.completed;
}
