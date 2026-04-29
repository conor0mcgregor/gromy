// ─────────────────────────────────────────────────────────────────────────────
//  ParticipantDisplayService  ·  Implementación del repositorio
//
//  Orquesta las llamadas a FirestoreParticipantService, FirestoreUserService
//  y FirestoreTeamService para construir la lista de ParticipantDisplay.
//
//  Principios:
//  - No duplica datos: solo lee los IDs de la subcolección y resuelve las
//    entidades de dominio desde sus colecciones canónicas.
//  - Carga concurrente: usa Future.wait para paralelizar la resolución de
//    usuarios/equipos y reducir la latencia.
//  - Tolerante a errores: si un usuario/equipo no se puede resolver, se omite
//    ese participante (log de error, no crash).
// ─────────────────────────────────────────────────────────────────────────────

import '../../../../database/participant/models/app_participant.dart';
import '../../../../database/participant/services/firestore_participant_service.dart';
import '../../../../database/team/services/firestore_team_service.dart';
import '../../../user/data/services/firestore_user_service.dart';
import '../models/participant_display.dart';
import '../repositories/participant_display_repository.dart';

class ParticipantDisplayService implements ParticipantDisplayRepository {
  ParticipantDisplayService({
    FirestoreParticipantService? participantService,
    FirestoreUserService? userService,
    FirestoreTeamService? teamService,
  }) : _participantService =
           participantService ?? FirestoreParticipantService(),
       _userService = userService ?? FirestoreUserService(),
       _teamService = teamService ?? FirestoreTeamService();

  final FirestoreParticipantService _participantService;
  final FirestoreUserService _userService;
  final FirestoreTeamService _teamService;

  // ── ParticipantDisplayRepository impl ─────────────────────────────────────

  @override
  Future<List<ParticipantDisplay>> getParticipants(String tournamentId) async {
    final participants = await _participantService.getParticipants(
      tournamentId,
    );
    return _resolveAll(participants);
  }

  @override
  Future<List<ParticipantDisplay>> getParticipantsPreview(
    String tournamentId, {
    int limit = 7,
  }) async {
    final all = await _participantService.getParticipants(tournamentId);
    final capped = all.length > limit ? all.sublist(0, limit) : all;
    return _resolveAll(capped);
  }

  // ── Resolución concurrente ──────────────────────────────────────────────────

  Future<List<ParticipantDisplay>> _resolveAll(
    List<AppParticipant> participants,
  ) async {
    final futures = participants.map(_resolveOne);
    final results = await Future.wait(futures, eagerError: false);

    // Filtrar nulos (entidades que no se pudieron resolver).
    return results.whereType<ParticipantDisplay>().toList();
  }

  Future<ParticipantDisplay?> _resolveOne(AppParticipant participant) async {
    try {
      switch (participant.entityType) {
        case ParticipantEntityType.user:
          final user = await _userService.getUser(participant.entityId);
          if (user == null) return null;
          return UserParticipantDisplay(
            participantId: participant.id,
            entityId: participant.entityId,
            entityType: participant.entityType,
            categoryId: participant.categoryId,
            user: user,
          );

        case ParticipantEntityType.team:
          final team = await _teamService.getTeam(participant.entityId);
          if (team == null) return null;
          return TeamParticipantDisplay(
            participantId: participant.id,
            entityId: participant.entityId,
            entityType: participant.entityType,
            categoryId: participant.categoryId,
            team: team,
          );
      }
    } catch (e) {
      // ignore: avoid_print
      print(
        '[ParticipantDisplayService] Error resolviendo ${participant.entityId}: $e',
      );
      return null;
    }
  }
}
