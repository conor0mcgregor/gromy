import '../entities/pending_team_invitation.dart';
import '../repositories/team_invitation_repository.dart';

class SendTeamInvitationUseCase {
  const SendTeamInvitationUseCase(this._repository);
  final TeamInvitationRepository _repository;

  Future<String> call({required String teamId, required String invitedUserId}) {
    return _repository.sendInvitation(
      teamId: teamId,
      invitedUserId: invitedUserId,
    );
  }
}

class WatchPendingTeamInvitationsUseCase {
  const WatchPendingTeamInvitationsUseCase(this._repository);
  final TeamInvitationRepository _repository;

  Stream<List<PendingTeamInvitation>> call({required String teamId}) {
    return _repository.watchPendingInvitations(teamId: teamId);
  }
}

class AcceptTeamInvitationUseCase {
  const AcceptTeamInvitationUseCase(this._repository);
  final TeamInvitationRepository _repository;

  Future<void> call({required String notificationId}) {
    return _repository.acceptInvitation(notificationId: notificationId);
  }
}

class RejectTeamInvitationUseCase {
  const RejectTeamInvitationUseCase(this._repository);
  final TeamInvitationRepository _repository;

  Future<void> call({required String notificationId}) {
    return _repository.rejectInvitation(notificationId: notificationId);
  }
}

class CancelTeamInvitationUseCase {
  const CancelTeamInvitationUseCase(this._repository);
  final TeamInvitationRepository _repository;

  Future<void> call({required String notificationId}) {
    return _repository.cancelInvitation(notificationId: notificationId);
  }
}
