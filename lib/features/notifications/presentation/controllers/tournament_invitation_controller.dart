import 'package:flutter/foundation.dart';

import '../../data/repository/tournament_invitation_repository_impl.dart';

enum TournamentInvitationAction { idle, accepting, rejecting }

class TournamentInvitationController extends ChangeNotifier {
  TournamentInvitationController({
    CloudFunctionTournamentInvitationRepository? repository,
  }) : _repository = repository;

  CloudFunctionTournamentInvitationRepository? _repository;

  TournamentInvitationAction action = TournamentInvitationAction.idle;
  String? errorMessage;

  Future<bool> acceptInvitation(String notificationId) async {
    return _run(
      TournamentInvitationAction.accepting,
      () => _invitationRepository.acceptInvitation(
        notificationId: notificationId,
      ),
    );
  }

  Future<bool> rejectInvitation(String notificationId) async {
    return _run(
      TournamentInvitationAction.rejecting,
      () => _invitationRepository.rejectInvitation(
        notificationId: notificationId,
      ),
    );
  }

  CloudFunctionTournamentInvitationRepository get _invitationRepository =>
      _repository ??= CloudFunctionTournamentInvitationRepository();

  Future<bool> _run(
    TournamentInvitationAction nextAction,
    Future<void> Function() task,
  ) async {
    if (action != TournamentInvitationAction.idle) return false;
    action = nextAction;
    errorMessage = null;
    notifyListeners();

    try {
      await task();
      action = TournamentInvitationAction.idle;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      action = TournamentInvitationAction.idle;
      notifyListeners();
      return false;
    }
  }
}
