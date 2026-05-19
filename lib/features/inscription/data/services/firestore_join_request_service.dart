import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/models/registration_form.dart';
import '../../../../database/participant/models/app_participant.dart';
import '../../../tournament/data/model/app_tournament.dart';
import '../../../tournament/data/model/enums_tournament.dart';
import '../models/join_request.dart';
import '../repositories/join_request_repository.dart';

class FirestoreJoinRequestService implements JoinRequestRepository {
  FirestoreJoinRequestService({FirebaseFirestore? firestore})
    : _db =
          firestore ??
          FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'gromy-db',
          );

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _tournaments =>
      _db.collection('tournaments');

  CollectionReference<Map<String, dynamic>> get _privateTournaments =>
      _db.collection('private_tournaments');

  Future<DocumentReference<Map<String, dynamic>>> _findTournamentRef(
    String tournamentId,
  ) async {
    final publicDoc = await _tournaments.doc(tournamentId).get();
    if (publicDoc.exists) return _tournaments.doc(tournamentId);

    final privateDoc = await _privateTournaments.doc(tournamentId).get();
    if (privateDoc.exists) return _privateTournaments.doc(tournamentId);

    throw Exception('El torneo no existe.');
  }

  CollectionReference<Map<String, dynamic>> _requestsRef(
    DocumentReference<Map<String, dynamic>> tournamentRef,
  ) {
    return tournamentRef.collection('joinRequests');
  }

  @override
  Future<JoinRequest> createRequest({
    required String tournamentId,
    required String entityId,
    required ParticipantEntityType entityType,
    required String requestedBy,
    String? categoryId,
    Map<String, dynamic> registrationValues = const {},
  }) async {
    final tournamentRef = await _findTournamentRef(tournamentId);
    final requestsRef = _requestsRef(tournamentRef);
    final requestRef = requestsRef.doc();

    return _db.runTransaction((transaction) async {
      final tournamentDoc = await transaction.get(tournamentRef);
      final tournamentData = tournamentDoc.data();
      if (!tournamentDoc.exists || tournamentData == null) {
        throw Exception('El torneo no existe.');
      }

      final tournament = AppTournament.fromMap(tournamentData);
      if (tournament.accessType == TournamentAccessType.publicOpen) {
        throw Exception('Este torneo permite inscripcion directa.');
      }
      if (!tournament.scheduledAt.isAfter(DateTime.now())) {
        throw Exception('El torneo ya ha comenzado.');
      }
      if (tournament.maxParticipants > 0 &&
          tournament.participantCount >= tournament.maxParticipants) {
        throw Exception('El aforo del torneo esta agotado.');
      }

      final formErrors = RegistrationFormValidator.validateResponses(
        schema: tournament.registrationForm,
        values: registrationValues,
      );
      if (formErrors.isNotEmpty) {
        throw Exception(formErrors.values.first);
      }

      final participantQuery = await tournamentRef
          .collection('participants')
          .where('entityId', isEqualTo: entityId)
          .limit(1)
          .get();
      if (participantQuery.docs.isNotEmpty) {
        throw Exception('Ya existe una inscripcion para este torneo.');
      }

      final duplicateQuery = await requestsRef
          .where('entityId', isEqualTo: entityId)
          .where('status', isEqualTo: JoinRequestStatus.pending.name)
          .limit(1)
          .get();
      if (duplicateQuery.docs.isNotEmpty) {
        throw Exception('Ya tienes una solicitud pendiente para este torneo.');
      }

      final now = DateTime.now();
      final request = JoinRequest(
        id: requestRef.id,
        tournamentId: tournamentId,
        entityId: entityId,
        entityType: entityType,
        requestedBy: requestedBy,
        status: JoinRequestStatus.pending,
        createdAt: now,
        updatedAt: now,
        categoryId: categoryId,
        registrationFormVersion: tournament.registrationForm.version,
        responses: RegistrationFormValidator.buildResponses(
          schema: tournament.registrationForm,
          values: registrationValues,
        ),
      );

      transaction.set(requestRef, request.toMap());
      return request;
    });
  }

  @override
  Stream<List<JoinRequest>> watchRequests({
    required String tournamentId,
    JoinRequestStatus? status,
  }) async* {
    final tournamentRef = await _findTournamentRef(tournamentId);
    Query<Map<String, dynamic>> query = _requestsRef(
      tournamentRef,
    ).orderBy('createdAt', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    yield* query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['requestId'] = data['requestId'] ?? doc.id;
        return JoinRequest.fromMap(data);
      }).toList();
    });
  }

  @override
  Future<List<JoinRequest>> getRequests({
    required String tournamentId,
    JoinRequestStatus? status,
  }) async {
    final tournamentRef = await _findTournamentRef(tournamentId);
    Query<Map<String, dynamic>> query = _requestsRef(
      tournamentRef,
    ).orderBy('createdAt', descending: true);
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    final snapshot = await query.get().timeout(const Duration(seconds: 10));
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['requestId'] = data['requestId'] ?? doc.id;
      return JoinRequest.fromMap(data);
    }).toList();
  }

  @override
  Future<bool> hasPendingRequest({
    required String tournamentId,
    required String entityId,
  }) async {
    final tournamentRef = await _findTournamentRef(tournamentId);
    final snapshot = await _requestsRef(tournamentRef)
        .where('entityId', isEqualTo: entityId)
        .where('status', isEqualTo: JoinRequestStatus.pending.name)
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 10));
    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<JoinRequest> approveRequest({
    required String tournamentId,
    required String requestId,
    required String reviewerUid,
  }) async {
    final tournamentRef = await _findTournamentRef(tournamentId);
    final requestRef = _requestsRef(tournamentRef).doc(requestId);

    return _db.runTransaction((transaction) async {
      final tournamentDoc = await transaction.get(tournamentRef);
      final requestDoc = await transaction.get(requestRef);
      final tournamentData = tournamentDoc.data();
      final requestData = requestDoc.data();

      if (!tournamentDoc.exists || tournamentData == null) {
        throw Exception('El torneo no existe.');
      }
      if (!requestDoc.exists || requestData == null) {
        throw Exception('La solicitud ya no existe.');
      }

      final tournament = AppTournament.fromMap(tournamentData);
      final request = JoinRequest.fromMap({
        ...requestData,
        'requestId': requestDoc.id,
      });

      _assertReviewerCanManage(tournament, reviewerUid);
      if (request.status != JoinRequestStatus.pending) {
        throw Exception('La solicitud ya fue revisada.');
      }
      if (!tournament.scheduledAt.isAfter(DateTime.now())) {
        throw Exception('El torneo ya ha comenzado.');
      }
      if (tournament.maxParticipants > 0 &&
          tournament.participantCount >= tournament.maxParticipants) {
        throw Exception('El aforo del torneo esta agotado.');
      }

      final participantQuery = await tournamentRef
          .collection('participants')
          .where('entityId', isEqualTo: request.entityId)
          .limit(1)
          .get();
      if (participantQuery.docs.isNotEmpty) {
        throw Exception('La entidad ya esta inscrita.');
      }

      final participantRef = tournamentRef.collection('participants').doc();
      final now = DateTime.now();
      transaction.set(participantRef, {
        'id': participantRef.id,
        'tournamentId': tournamentId,
        'entityId': request.entityId,
        'entityType': request.entityType.name,
        'status': ParticipantStatus.active.firestoreValue,
        'enrolledAt': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'approvedBy': reviewerUid,
        'source': 'manual_approval',
        'categoryId': request.categoryId,
        'registrationFormVersion': request.registrationFormVersion,
        'responses': request.responses.map((r) => r.toMap()).toList(),
      });
      transaction.update(tournamentRef, {
        'participantCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(now),
      });
      transaction.update(requestRef, {
        'status': JoinRequestStatus.approved.name,
        'reviewedBy': reviewerUid,
        'reviewedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      return JoinRequest.fromMap({
        ...request.toMap(),
        'status': JoinRequestStatus.approved.name,
        'reviewedBy': reviewerUid,
        'reviewedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
    });
  }

  @override
  Future<JoinRequest> rejectRequest({
    required String tournamentId,
    required String requestId,
    required String reviewerUid,
    String? reason,
  }) async {
    final tournamentRef = await _findTournamentRef(tournamentId);
    final requestRef = _requestsRef(tournamentRef).doc(requestId);

    return _db.runTransaction((transaction) async {
      final tournamentDoc = await transaction.get(tournamentRef);
      final requestDoc = await transaction.get(requestRef);
      final tournamentData = tournamentDoc.data();
      final requestData = requestDoc.data();

      if (!tournamentDoc.exists || tournamentData == null) {
        throw Exception('El torneo no existe.');
      }
      if (!requestDoc.exists || requestData == null) {
        throw Exception('La solicitud ya no existe.');
      }

      final tournament = AppTournament.fromMap(tournamentData);
      final request = JoinRequest.fromMap({
        ...requestData,
        'requestId': requestDoc.id,
      });

      _assertReviewerCanManage(tournament, reviewerUid);
      if (request.status != JoinRequestStatus.pending) {
        throw Exception('La solicitud ya fue revisada.');
      }

      final now = DateTime.now();
      final cleanReason = reason?.trim();
      final rejectionReason = cleanReason == null || cleanReason.isEmpty
          ? 'Sin motivo indicado'
          : cleanReason;
      transaction.update(requestRef, {
        'status': JoinRequestStatus.rejected.name,
        'reviewedBy': reviewerUid,
        'reviewedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'rejectionReason': rejectionReason,
      });

      return JoinRequest.fromMap({
        ...request.toMap(),
        'status': JoinRequestStatus.rejected.name,
        'reviewedBy': reviewerUid,
        'reviewedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'rejectionReason': rejectionReason,
      });
    });
  }

  void _assertReviewerCanManage(AppTournament tournament, String reviewerUid) {
    if (tournament.organizerUid != reviewerUid &&
        !tournament.adminIds.contains(reviewerUid)) {
      throw Exception('No tienes permisos para revisar solicitudes.');
    }
  }
}
