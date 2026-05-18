import '../../domain/models/join_request.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  JoinRequestRepository  ·  Contrato de dominio
//
//  Gestiona las solicitudes de inscripción a torneos cerrados.
//  La aprobación usa transacciones Firestore para garantizar
//  que nunca se supere el aforo.
// ─────────────────────────────────────────────────────────────────────────────

abstract interface class JoinRequestRepository {
  /// Crea una nueva solicitud de inscripción.
  Future<JoinRequest> createRequest(JoinRequest request);

  /// Obtiene todas las solicitudes de un torneo.
  Future<List<JoinRequest>> getRequests(String tournamentId);

  /// Stream en tiempo real de solicitudes pendientes de un torneo.
  Stream<List<JoinRequest>> watchPendingRequests(String tournamentId);

  /// Stream en tiempo real de todas las solicitudes de un torneo.
  Stream<List<JoinRequest>> watchAllRequests(String tournamentId);

  /// Aprueba una solicitud usando transacción Firestore.
  /// Crea la inscripción y verifica el aforo atómicamente.
  Future<void> approveRequest({
    required String tournamentId,
    required String requestId,
    required String reviewedBy,
  });

  /// Rechaza una solicitud con motivo opcional.
  Future<void> rejectRequest({
    required String tournamentId,
    required String requestId,
    required String reviewedBy,
    String? rejectionReason,
  });

  /// Comprueba si ya existe una solicitud pendiente para la entidad.
  Future<bool> hasExistingRequest({
    required String tournamentId,
    required String entityId,
  });

  /// Obtiene el conteo de solicitudes pendientes de un torneo.
  Future<int> getPendingCount(String tournamentId);
}
