import '../../../notifications/domain/entities/app_notification.dart';
import '../../../notifications/domain/entities/notification_type.dart';
import '../../../notifications/domain/repositories/notification_repository.dart';

class JoinRequestNotificationService {
  const JoinRequestNotificationService(this._repository);

  final NotificationRepository _repository;

  Future<void> notifyOrganizer({
    required String organizerUid,
    required String tournamentId,
    required String tournamentName,
    required String requestId,
    required String requesterName,
    String? tournamentPortadaUrl,
    String? tournamentSport,
    String? tournamentLocation,
    int? tournamentParticipantCount,
    int? tournamentMaxParticipants,
    String? requesterNickname,
    String? requesterAvatarUrl,
    String? entityType,
  }) {
    final requesterLabel = requesterNickname?.trim().isNotEmpty == true
        ? '@${requesterNickname!.trim()}'
        : requesterName;

    return _repository.createNotification(
      AppNotification(
        id: '',
        userId: organizerUid,
        type: NotificationType.joinRequestPending,
        title: 'Nueva solicitud de inscripcion',
        body: '$requesterLabel ha solicitado unirse a tu torneo.',
        createdAt: DateTime.now(),
        actionRoute: '/tournament/join-requests',
        data: {
          'tournamentId': tournamentId,
          'requestId': requestId,
          'tournamentName': tournamentName,
          'requesterName': requesterName,
          'requesterNickname': requesterNickname,
          'requesterAvatarUrl': requesterAvatarUrl,
          'tournamentPortadaUrl': tournamentPortadaUrl,
          'tournamentSport': tournamentSport,
          'tournamentLocation': tournamentLocation,
          'tournamentParticipantCount': tournamentParticipantCount,
          'tournamentMaxParticipants': tournamentMaxParticipants,
          'entityType': entityType,
          'status': 'pending',
        },
      ),
    );
  }

  Future<void> notifyApproved({
    required String userId,
    required String tournamentId,
    required String tournamentName,
  }) {
    return _repository.createNotification(
      AppNotification(
        id: '',
        userId: userId,
        type: NotificationType.joinRequestApproved,
        title: 'Solicitud aprobada',
        body: 'Tu solicitud para $tournamentName fue aprobada.',
        createdAt: DateTime.now(),
        actionRoute: '/tournament/detail',
        data: {'tournamentId': tournamentId, 'tournamentName': tournamentName},
      ),
    );
  }

  Future<void> notifyRejected({
    required String userId,
    required String tournamentId,
    required String tournamentName,
  }) {
    return _repository.createNotification(
      AppNotification(
        id: '',
        userId: userId,
        type: NotificationType.joinRequestRejected,
        title: 'Solicitud rechazada',
        body: 'Tu solicitud para $tournamentName ha sido rechazada.',
        createdAt: DateTime.now(),
        actionRoute: '/tournament/detail',
        data: {'tournamentId': tournamentId, 'tournamentName': tournamentName},
      ),
    );
  }
}
