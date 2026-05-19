import '../entities/pending_team_invitation.dart';

abstract interface class TeamInvitationRepository {
  Future<String> sendInvitation({
    required String teamId,
    required String invitedUserId,
  });

  Stream<List<PendingTeamInvitation>> watchPendingInvitations({
    required String teamId,
  });

  Future<void> acceptInvitation({required String notificationId});

  Future<void> rejectInvitation({required String notificationId});

  Future<void> cancelInvitation({required String notificationId});
}
