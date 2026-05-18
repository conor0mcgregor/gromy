import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../database/participant/models/app_participant.dart';
import '../../domain/models/join_request.dart';
import '../repositories/join_request_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FirestoreJoinRequestService  ·  Capa de datos
//
//  Implementa [JoinRequestRepository] usando la subcolección:
//    tournaments/{tournamentId}/joinRequests/{requestId}
//
//  La aprobación se realiza con una transacción Firestore para garantizar
//  atomicidad: leer torneo → verificar aforo → crear participante →
//  incrementar contador → marcar solicitud como approved.
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreJoinRequestService implements JoinRequestRepository {
  FirestoreJoinRequestService({FirebaseFirestore? firestore})
      : _db = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'gromy-db',
            );

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _requestsRef(String tournamentId) =>
      _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('joinRequests');

  CollectionReference<Map<String, dynamic>> _participantsRef(
    String tournamentId,
  ) =>
      _db
          .collection('tournaments')
          .doc(tournamentId)
          .collection('participants');

  DocumentReference<Map<String, dynamic>> _tournamentDoc(String id) =>
      _db.collection('tournaments').doc(id);

  @override
  Future<JoinRequest> createRequest(JoinRequest request) async {
    // Verificar duplicados.
    final exists = await hasExistingRequest(
      tournamentId: request.tournamentId,
      entityId: request.entityId,
    );
    if (exists) {
      throw Exception('Ya existe una solicitud pendiente para esta entidad.');
    }

    final docRef = _requestsRef(request.tournamentId).doc();
    final toSave = request.copyWith(id: docRef.id);

    await docRef.set(toSave.toMap()).timeout(const Duration(seconds: 10));
    return toSave;
  }

  @override
  Future<List<JoinRequest>> getRequests(String tournamentId) async {
    final snapshot = await _requestsRef(tournamentId)
        .orderBy('createdAt', descending: true)
        .get()
        .timeout(const Duration(seconds: 10));

    return snapshot.docs
        .map((doc) => JoinRequest.fromMap(doc.data()))
        .toList();
  }

  @override
  Stream<List<JoinRequest>> watchPendingRequests(String tournamentId) {
    return _requestsRef(tournamentId)
        .where('status', isEqualTo: JoinRequestStatus.pending.name)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JoinRequest.fromMap(doc.data()))
            .toList());
  }

  @override
  Stream<List<JoinRequest>> watchAllRequests(String tournamentId) {
    return _requestsRef(tournamentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => JoinRequest.fromMap(doc.data()))
            .toList());
  }

  @override
  Future<void> approveRequest({
    required String tournamentId,
    required String requestId,
    required String reviewedBy,
  }) async {
    await _db.runTransaction((transaction) async {
      // 1. Leer torneo.
      final tournamentSnap =
          await transaction.get(_tournamentDoc(tournamentId));
      if (!tournamentSnap.exists) {
        throw Exception('El torneo no existe.');
      }
      final tournamentData = tournamentSnap.data()!;
      final maxParticipants =
          (tournamentData['maxParticipants'] as num?)?.toInt() ?? 0;
      final currentCount =
          (tournamentData['participantCount'] as num?)?.toInt() ?? 0;

      // 2. Leer solicitud.
      final requestDoc = _requestsRef(tournamentId).doc(requestId);
      final requestSnap = await transaction.get(requestDoc);
      if (!requestSnap.exists) {
        throw Exception('La solicitud no existe.');
      }
      final request = JoinRequest.fromMap(requestSnap.data()!);

      // 3. Verificar que la solicitud sigue pendiente.
      if (!request.isPending) {
        throw Exception('La solicitud ya ha sido revisada.');
      }

      // 4. Verificar aforo.
      if (currentCount >= maxParticipants) {
        throw Exception('El torneo está lleno. No se puede aprobar.');
      }

      // 5. Crear participante.
      final participantDoc = _participantsRef(tournamentId).doc();
      final participant = AppParticipant(
        id: participantDoc.id,
        tournamentId: tournamentId,
        entityId: request.entityId,
        entityType: request.entityType,
        enrolledAt: DateTime.now(),
        status: ParticipantStatus.approved,
        approvedBy: reviewedBy,
        source: 'manual_approval',
        responses: request.responses,
      );
      transaction.set(participantDoc, participant.toMap());

      // 6. Incrementar contador de participantes.
      transaction.update(
        _tournamentDoc(tournamentId),
        {'participantCount': FieldValue.increment(1)},
      );

      // 7. Marcar solicitud como approved.
      transaction.update(requestDoc, {
        'status': JoinRequestStatus.approved.name,
        'reviewedBy': reviewedBy,
        'reviewedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }).timeout(const Duration(seconds: 15));
  }

  @override
  Future<void> rejectRequest({
    required String tournamentId,
    required String requestId,
    required String reviewedBy,
    String? rejectionReason,
  }) async {
    await _requestsRef(tournamentId).doc(requestId).update({
      'status': JoinRequestStatus.rejected.name,
      'reviewedBy': reviewedBy,
      'reviewedAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'rejectionReason': rejectionReason ?? 'Sin motivo especificado.',
    }).timeout(const Duration(seconds: 10));
  }

  @override
  Future<bool> hasExistingRequest({
    required String tournamentId,
    required String entityId,
  }) async {
    final snapshot = await _requestsRef(tournamentId)
        .where('entityId', isEqualTo: entityId)
        .where('status', isEqualTo: JoinRequestStatus.pending.name)
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 10));
    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<int> getPendingCount(String tournamentId) async {
    final snapshot = await _requestsRef(tournamentId)
        .where('status', isEqualTo: JoinRequestStatus.pending.name)
        .count()
        .get()
        .timeout(const Duration(seconds: 10));
    return snapshot.count ?? 0;
  }
}
