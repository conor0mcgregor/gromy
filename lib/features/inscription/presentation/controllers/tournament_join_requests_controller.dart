import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../database/participant/models/app_participant.dart';
import '../../../../database/team/services/firestore_team_service.dart';
import '../../../tournament/data/model/app_tournament.dart';
import '../../../user/data/services/firestore_user_service.dart';
import '../../data/models/join_request.dart';
import '../../data/repositories/join_request_repository.dart';
import '../../data/services/firestore_join_request_service.dart';
import '../../domain/use_cases/approve_join_request_use_case.dart';
import '../../domain/use_cases/reject_join_request_use_case.dart';
import '../models/join_request_display.dart';

enum JoinRequestsLoadState { loading, loaded, empty, error }

class TournamentJoinRequestsController extends ChangeNotifier {
  TournamentJoinRequestsController({
    required this.tournament,
    JoinRequestRepository? repository,
    FirestoreUserService? userService,
    FirestoreTeamService? teamService,
    ApproveJoinRequestUseCase? approveUseCase,
    RejectJoinRequestUseCase? rejectUseCase,
  }) : _repository = repository ?? FirestoreJoinRequestService(),
       _userService = userService ?? FirestoreUserService(),
       _teamService = teamService ?? FirestoreTeamService(),
       _approveUseCase = approveUseCase ?? ApproveJoinRequestUseCase(),
       _rejectUseCase = rejectUseCase ?? RejectJoinRequestUseCase();

  final AppTournament tournament;
  final JoinRequestRepository _repository;
  final FirestoreUserService _userService;
  final FirestoreTeamService _teamService;
  final ApproveJoinRequestUseCase _approveUseCase;
  final RejectJoinRequestUseCase _rejectUseCase;

  StreamSubscription<List<JoinRequest>>? _subscription;
  JoinRequestsLoadState state = JoinRequestsLoadState.loading;
  List<JoinRequestDisplay> requests = [];
  String? errorMessage;
  JoinRequestStatus? statusFilter = JoinRequestStatus.pending;
  final Set<String> processingIds = {};

  bool isProcessing(String requestId) => processingIds.contains(requestId);

  void init() {
    watch(statusFilter);
  }

  void watch(JoinRequestStatus? status) {
    statusFilter = status;
    state = JoinRequestsLoadState.loading;
    errorMessage = null;
    notifyListeners();
    _subscription?.cancel();
    _subscription = _repository
        .watchRequests(tournamentId: tournament.id, status: status)
        .listen(
          (items) async {
            requests = await Future.wait(items.map(_resolve));
            state = requests.isEmpty
                ? JoinRequestsLoadState.empty
                : JoinRequestsLoadState.loaded;
            notifyListeners();
          },
          onError: (Object error) {
            errorMessage = error.toString().replaceFirst('Exception: ', '');
            state = JoinRequestsLoadState.error;
            notifyListeners();
          },
        );
  }

  Future<bool> approve(String requestId) async {
    return _runAction(requestId, () {
      return _approveUseCase.execute(
        tournament: tournament,
        requestId: requestId,
      );
    });
  }

  Future<bool> reject(String requestId, {String? reason}) async {
    return _runAction(requestId, () {
      return _rejectUseCase.execute(
        tournament: tournament,
        requestId: requestId,
        reason: reason,
      );
    });
  }

  Future<bool> _runAction(
    String requestId,
    Future<JoinRequest> Function() action,
  ) async {
    processingIds.add(requestId);
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      processingIds.remove(requestId);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      processingIds.remove(requestId);
      notifyListeners();
      return false;
    }
  }

  Future<JoinRequestDisplay> _resolve(JoinRequest request) async {
    if (request.entityType == ParticipantEntityType.team) {
      final team = await _teamService.getTeam(request.entityId);
      return JoinRequestDisplay(
        request: request,
        title: team?.name ?? 'Equipo no encontrado',
        subtitle: team == null ? null : '${team.members.length} miembros',
        avatarUrl: team?.photoUrl,
        team: team,
      );
    }

    final user = await _userService.getUser(request.entityId);
    final title = user == null
        ? 'Usuario no encontrado'
        : '${user.name} ${user.lastName}'.trim();
    return JoinRequestDisplay(
      request: request,
      title: title.isEmpty ? user?.nickname ?? 'Usuario' : title,
      subtitle: user?.email,
      avatarUrl: user?.photoUrl,
      user: user,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
