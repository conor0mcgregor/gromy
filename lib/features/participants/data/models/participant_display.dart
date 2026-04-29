// ─────────────────────────────────────────────────────────────────────────────
//  ParticipantDisplay  ·  Modelos de vista (capa de presentación)
//
//  Une AppParticipant con los datos resueltos del usuario/equipo.
//  Usa sealed class para garantizar exhaustividad en los switch.
//
//  No duplica datos: los modelos de dominio (AppUser, AppTeam) se mantienen
//  intactos y solo se añade la referencia al categoryId del participante.
// ─────────────────────────────────────────────────────────────────────────────

import '../../../../database/participant/models/app_participant.dart';
import '../../../../database/team/models/app_team.dart';
import '../../../../features/user/data/models/app_user.dart';

sealed class ParticipantDisplay {
  const ParticipantDisplay({
    required this.participantId,
    required this.entityId,
    required this.entityType,
    this.categoryId,
  });

  /// ID del documento AppParticipant en Firestore.
  final String participantId;

  /// ID de la entidad inscrita (usuario o equipo).
  final String entityId;

  /// Tipo de entidad inscrita.
  final ParticipantEntityType entityType;

  /// Categoría opcional del torneo a la que está inscrito.
  final String? categoryId;
}

/// Participante individual: usuario inscrito directamente.
final class UserParticipantDisplay extends ParticipantDisplay {
  const UserParticipantDisplay({
    required super.participantId,
    required super.entityId,
    required super.entityType,
    super.categoryId,
    required this.user,
  });

  final AppUser user;
}

/// Participante por equipos: un equipo inscrito.
final class TeamParticipantDisplay extends ParticipantDisplay {
  const TeamParticipantDisplay({
    required super.participantId,
    required super.entityId,
    required super.entityType,
    super.categoryId,
    required this.team,
  });

  final AppTeam team;
}
