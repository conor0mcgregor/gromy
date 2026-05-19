import '../../../../database/participant/models/app_participant.dart';
import '../../../../database/team/models/app_team.dart';
import '../../../../database/team/repositories/team_repository.dart';
import '../../../../database/team/services/firestore_team_service.dart';
import '../../../../features/notifications/data/repository/notification_repository_impl.dart';
import '../../../../features/tournament/data/model/app_tournament.dart';
import '../../../../features/user/data/models/app_user.dart';
import '../../../../features/user/data/repositories/user_repository.dart';
import '../../../../features/user/data/services/firestore_user_service.dart';
import '../../data/models/join_request.dart';
import '../../data/repositories/join_request_repository.dart';
import '../../data/services/firestore_join_request_service.dart';
import '../../data/services/join_request_notification_service.dart';

class CreateJoinRequestUseCase {
  CreateJoinRequestUseCase({
    JoinRequestRepository? repository,
    TeamRepository? teamRepository,
    UserRepository? userRepository,
    JoinRequestNotificationService? notificationService,
  }) : _repository = repository ?? FirestoreJoinRequestService(),
       _teamRepository = teamRepository ?? FirestoreTeamService(),
       _userRepository = userRepository ?? FirestoreUserService(),
       _notificationService =
           notificationService ??
           JoinRequestNotificationService(NotificationRepositoryImpl());

  final JoinRequestRepository _repository;
  final TeamRepository _teamRepository;
  final UserRepository _userRepository;
  final JoinRequestNotificationService _notificationService;

  Future<JoinRequest> execute({
    required AppTournament tournament,
    required String entityId,
    required ParticipantEntityType entityType,
    required AppUser requestedBy,
    String? categoryId,
    Map<String, dynamic> registrationValues = const {},
  }) async {
    final request = await _repository.createRequest(
      tournamentId: tournament.id,
      entityId: entityId,
      entityType: entityType,
      requestedBy: requestedBy.uid,
      categoryId: categoryId,
      registrationValues: registrationValues,
    );

    try {
      await _notificationService.notifyOrganizer(
        organizerUid: tournament.organizerUid,
        tournamentId: tournament.id,
        tournamentName: tournament.name,
        requestId: request.id,
        requesterName: await _resolveEntityName(
          entityId: entityId,
          entityType: entityType,
          fallbackUser: requestedBy,
        ),
      );
    } catch (_) {
      // La solicitud no debe fallar si la notificacion no se puede crear.
    }

    return request;
  }

  Future<String> _resolveEntityName({
    required String entityId,
    required ParticipantEntityType entityType,
    required AppUser fallbackUser,
  }) async {
    if (entityType == ParticipantEntityType.team) {
      final AppTeam? team = await _teamRepository.getTeam(entityId);
      return team?.name ?? 'Un equipo';
    }
    final user = await _userRepository.getUser(entityId);
    final resolved = user ?? fallbackUser;
    final fullName = '${resolved.name} ${resolved.lastName}'.trim();
    return fullName.isNotEmpty ? fullName : resolved.nickname;
  }
}
