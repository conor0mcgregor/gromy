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
