import '../../../../database/participant/models/app_participant.dart';
import '../models/join_request.dart';

abstract interface class JoinRequestRepository {
  Future<JoinRequest> createRequest({
    required String tournamentId,
    required String entityId,
    required ParticipantEntityType entityType,
    required String requestedBy,
    String? categoryId,
    Map<String, dynamic> registrationValues,
  });

  Stream<List<JoinRequest>> watchRequests({
    required String tournamentId,
    JoinRequestStatus? status,
  });

  Future<List<JoinRequest>> getRequests({
    required String tournamentId,
    JoinRequestStatus? status,
  });

  Future<bool> hasPendingRequest({
    required String tournamentId,
    required String entityId,
  });

  Future<JoinRequest> approveRequest({
    required String tournamentId,
    required String requestId,
    required String reviewerUid,
  });

  Future<JoinRequest> rejectRequest({
    required String tournamentId,
    required String requestId,
    required String reviewerUid,
    String? reason,
  });
}
