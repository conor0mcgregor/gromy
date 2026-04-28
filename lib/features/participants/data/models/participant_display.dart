// ─────────────────────────────────────────────────────────────────────────────
//  ParticipantDisplay  ·  Modelos de vista (capa de presentación)
//
//  Une AppParticipant con los datos resueltos del usuario/equipo.
//  Usa sealed class para garantizar exhaustividad en los switch.
//
//  No duplica datos: los modelos de dominio (AppUser, AppTeam) se mantienen
//  intactos y solo se añade la referencia al categoryId del participante.
// ─────────────────────────────────────────────────────────────────────────────

import '../../../../database/team/models/app_team.dart';
import '../../../../features/user/data/models/app_user.dart';

sealed class ParticipantDisplay {
  const ParticipantDisplay({required this.participantId, this.categoryId});

  /// ID del documento AppParticipant en Firestore.
  final String participantId;

  /// Categoría opcional del torneo a la que está inscrito.
  final String? categoryId;
}

/// Participante individual: usuario inscrito directamente.
final class UserParticipantDisplay extends ParticipantDisplay {
  const UserParticipantDisplay({
    required super.participantId,
    super.categoryId,
    required this.user,
  });

  final AppUser user;
}

/// Participante por equipos: un equipo inscrito.
final class TeamParticipantDisplay extends ParticipantDisplay {
  const TeamParticipantDisplay({
    required super.participantId,
    super.categoryId,
    required this.team,
  });

  final AppTeam team;
}
