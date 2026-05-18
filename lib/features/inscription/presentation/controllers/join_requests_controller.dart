import 'package:flutter/foundation.dart';

import '../../../../database/participant/models/app_participant.dart';
import '../../../../features/inscription/domain/models/join_request.dart';
import '../../../../features/notifications/data/models/app_notification.dart';
import '../../../../features/notifications/data/services/firestore_notification_service.dart';
import '../../../../features/user/data/services/firestore_user_service.dart';
import '../../../../features/tournament/data/model/app_tournament.dart';
import '../../data/repositories/join_request_repository.dart';
import '../../data/services/firestore_join_request_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  JoinRequestsController  ·  Presentación
//
//  Gestiona la cola de solicitudes de inscripción para organizadores.
// ─────────────────────────────────────────────────────────────────────────────

class JoinRequestsController extends ChangeNotifier {
  JoinRequestsController({
    required this.tournament,
    required this.currentUserId,
    JoinRequestRepository? requestRepo,
  }) : _requestRepo = requestRepo ?? FirestoreJoinRequestService();

  final AppTournament tournament;
  final String currentUserId;
  final JoinRequestRepository _requestRepo;

  final _notificationService = FirestoreNotificationService();
  final _userService = FirestoreUserService();

  bool isLoading = false;
  String? error;

  /// IDs de solicitudes que están siendo procesadas.
  final Set<String> processingIds = {};

  /// Stream de solicitudes pendientes.
  Stream<List<JoinRequest>> watchPendingRequests() {
    return _requestRepo.watchPendingRequests(tournament.id);
  }

  /// Stream de todas las solicitudes.
  Stream<List<JoinRequest>> watchAllRequests() {
    return _requestRepo.watchAllRequests(tournament.id);
  }

  /// Aprueba una solicitud.
  Future<bool> approveRequest(JoinRequest request) async {
    if (processingIds.contains(request.id)) return false;

    processingIds.add(request.id);
    error = null;
    notifyListeners();

    try {
      await _requestRepo.approveRequest(
        tournamentId: tournament.id,
        requestId: request.id,
        reviewedBy: currentUserId,
      );

      // Notificar al usuario solicitante.
      await _notificationService.createNotification(
        AppNotification(
          id: '',
          userId: request.requestedBy,
          type: NotificationType.joinRequestApproved,
          title: '¡Solicitud aprobada!',
          body:
              'Tu solicitud para el torneo "${tournament.name}" ha sido aprobada.',
          data: {
            'tournamentId': tournament.id,
            'requestId': request.id,
          },
          createdAt: DateTime.now(),
        ),
      );

      processingIds.remove(request.id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      processingIds.remove(request.id);
      notifyListeners();
      return false;
    }
  }

  /// Rechaza una solicitud.
  Future<bool> rejectRequest(
    JoinRequest request, {
    String? reason,
  }) async {
    if (processingIds.contains(request.id)) return false;

    processingIds.add(request.id);
    error = null;
    notifyListeners();

    try {
      await _requestRepo.rejectRequest(
        tournamentId: tournament.id,
        requestId: request.id,
        reviewedBy: currentUserId,
        rejectionReason: reason,
      );

      // Notificar al usuario solicitante.
      await _notificationService.createNotification(
        AppNotification(
          id: '',
          userId: request.requestedBy,
          type: NotificationType.joinRequestRejected,
          title: 'Solicitud rechazada',
          body:
              'Tu solicitud para el torneo "${tournament.name}" ha sido rechazada.',
          data: {
            'tournamentId': tournament.id,
            'requestId': request.id,
            if (reason != null) 'reason': reason,
          },
          createdAt: DateTime.now(),
        ),
      );

      processingIds.remove(request.id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      processingIds.remove(request.id);
      notifyListeners();
      return false;
    }
  }

  /// Obtiene el nombre de la entidad solicitante.
  Future<String> getEntityName(JoinRequest request) async {
    if (request.entityType == ParticipantEntityType.user) {
      final user = await _userService.getUser(request.entityId);
      return user != null
          ? '${user.name} ${user.lastName}'.trim()
          : 'Usuario desconocido';
    }
    return 'Equipo';
  }
}
