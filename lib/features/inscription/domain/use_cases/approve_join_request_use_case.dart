import 'package:firebase_auth/firebase_auth.dart';

import '../../../../features/notifications/data/repository/notification_repository_impl.dart';
import '../../../../features/tournament/data/model/app_tournament.dart';
import '../../data/models/join_request.dart';
import '../../data/repositories/join_request_repository.dart';
import '../../data/services/firestore_join_request_service.dart';
import '../../data/services/join_request_notification_service.dart';

class ApproveJoinRequestUseCase {
  ApproveJoinRequestUseCase({
    JoinRequestRepository? repository,
    JoinRequestNotificationService? notificationService,
    FirebaseAuth? auth,
  }) : _repository = repository ?? FirestoreJoinRequestService(),
       _notificationService =
           notificationService ??
           JoinRequestNotificationService(NotificationRepositoryImpl()),
       _auth = auth ?? FirebaseAuth.instance;

  final JoinRequestRepository _repository;
  final JoinRequestNotificationService _notificationService;
  final FirebaseAuth _auth;

  Future<JoinRequest> execute({
    required AppTournament tournament,
    required String requestId,
  }) async {
    final reviewerUid = _auth.currentUser?.uid;
    if (reviewerUid == null) throw Exception('No hay sesion activa.');

    final request = await _repository.approveRequest(
      tournamentId: tournament.id,
      requestId: requestId,
      reviewerUid: reviewerUid,
    );

    try {
      await _notificationService.notifyApproved(
        userId: request.requestedBy,
        tournamentId: tournament.id,
        tournamentName: tournament.name,
      );
    } catch (_) {}

    return request;
  }
}
