import '../../../../database/participant/models/app_participant.dart';
import '../../../../database/team/repositories/team_repository.dart';
import '../../data/repositories/join_request_repository.dart';
import '../../data/services/firestore_join_request_service.dart';
import '../../../tournament/data/repositories/tournament_repository.dart';
import '../models/enrollment_status.dart';

class CheckEnrollmentUseCase {
  final TournamentRepository _tournamentRepository;
  final TeamRepository _teamRepository;
  final JoinRequestRepository _joinRequestRepository;

  CheckEnrollmentUseCase(
    this._tournamentRepository,
    this._teamRepository, {
    JoinRequestRepository? joinRequestRepository,
  }) : _joinRequestRepository =
           joinRequestRepository ?? FirestoreJoinRequestService();

  Future<EnrollmentStatus> execute({
    required String tournamentId,
    required String? userId,
  }) async {
    if (userId == null) return EnrollmentStatus.notEnrolled();

    try {
      final participants = await _tournamentRepository.getParticipants(
        tournamentId,
      );

      // 1. Verificar inscripción individual
      final individualParticipant = participants
          .where(
            (p) =>
                p.entityId == userId &&
                p.entityType == ParticipantEntityType.user,
          )
          .firstOrNull;

      if (individualParticipant != null) {
        return EnrollmentStatus(
          isEnrolled: true,
          participant: individualParticipant,
          canCancel: true,
        );
      }

      // 2. Verificar inscripción por equipo
      // Obtenemos los equipos del usuario
      final myTeams = await _teamRepository.watchTeamsByMember(userId).first;
      final myTeamIds = myTeams.map((t) => t.id).toSet();

      final teamParticipant = participants
          .where(
            (p) =>
                p.entityType == ParticipantEntityType.team &&
                myTeamIds.contains(p.entityId),
          )
          .firstOrNull;

      if (teamParticipant != null) {
        final enrolledTeam = myTeams.firstWhere(
          (t) => t.id == teamParticipant.entityId,
        );
        return EnrollmentStatus(
          isEnrolled: true,
          participant: teamParticipant,
          enrolledTeam: enrolledTeam,
          canCancel: enrolledTeam.isAdmin(userId),
        );
      }

      final entityIds = <String>{userId, ...myTeamIds};
      for (final entityId in entityIds) {
        final hasPending = await _joinRequestRepository.hasPendingRequest(
          tournamentId: tournamentId,
          entityId: entityId,
        );
        if (hasPending) {
          return EnrollmentStatus(
            isEnrolled: false,
            hasPendingJoinRequest: true,
          );
        }
      }

      return EnrollmentStatus.notEnrolled();
    } catch (e) {
      // En caso de error, asumimos no inscrito para no bloquear la UI
      return EnrollmentStatus.notEnrolled();
    }
  }
}
