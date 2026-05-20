import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_participant.dart';
import '../repositories/participant_repository.dart';
import '../../../core/models/registration_form.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FirestoreParticipantService  ·  Capa de datos
//
//  Implementa [ParticipantRepository] usando la subcolección:
//    tournaments/{tournamentId}/participants/{participantId}
//
//  Decisión de diseño:
//  - Subcolección de tournament → los participantes sólo existen en el
//    contexto de su torneo, lo que facilita consultas, reglas de seguridad
//    y borrado en cascada.
//  - No se duplica info del usuario/equipo: sólo se almacena entityId.
//  - entityType permite soporte polimórfico (user|team) sin herencia.
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreParticipantService implements ParticipantRepository {
  FirestoreParticipantService({FirebaseFirestore? firestore})
    : _db =
          firestore ??
          FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'gromy-db',
          );

  final FirebaseFirestore _db;

  /// Referencia a la subcolección de participantes del torneo.
  CollectionReference<Map<String, dynamic>> _participantsRef(
    String tournamentId,
  ) => _db
      .collection('tournaments')
      .doc(tournamentId)
      .collection('participants');

  CollectionReference<Map<String, dynamic>> _privateParticipantsRef(
    String tournamentId,
  ) => _db
      .collection('private_tournaments')
      .doc(tournamentId)
      .collection('participants');

  Future<CollectionReference<Map<String, dynamic>>> _participantsRefFor(
    String tournamentId,
  ) async {
    final privateDoc = await _db
        .collection('private_tournaments')
        .doc(tournamentId)
        .get()
        .timeout(const Duration(seconds: 10));
    if (privateDoc.exists) return _privateParticipantsRef(tournamentId);
    return _participantsRef(tournamentId);
  }

  Future<List<CollectionReference<Map<String, dynamic>>>> _readRefsFor(
    String tournamentId,
  ) async {
    final privateDoc = await _db
        .collection('private_tournaments')
        .doc(tournamentId)
        .get()
        .timeout(const Duration(seconds: 10));
    if (privateDoc.exists) {
      return [
        _privateParticipantsRef(tournamentId),
        _participantsRef(tournamentId),
      ];
    }
    return [_participantsRef(tournamentId)];
  }

  // ── ParticipantRepository impl ─────────────────────────────────────────────

  @override
  Future<AppParticipant> joinTournament({
    required String tournamentId,
    required String entityId,
    required ParticipantEntityType entityType,
    ParticipantStatus status = ParticipantStatus.pending,
    String? categoryId,
    int registrationFormVersion = 1,
    List<RegistrationResponse> registrationResponses = const [],
  }) async {
    // Impide inscripciones duplicadas.
    final alreadyEnrolled = await isEnrolled(
      tournamentId: tournamentId,
      entityId: entityId,
    );
    if (alreadyEnrolled) {
      throw Exception(
        'La entidad $entityId ya está inscrita en el torneo $tournamentId.',
      );
    }

    final colRef = await _participantsRefFor(tournamentId);
    final docRef = colRef.doc(); // Firestore genera el ID

    final participant = AppParticipant(
      id: docRef.id,
      tournamentId: tournamentId,
      entityId: entityId,
      entityType: entityType,
      enrolledAt: DateTime.now(),
      status: status,
      categoryId: categoryId,
      registrationFormVersion: registrationFormVersion,
      registrationResponses: registrationResponses,
    );

    await docRef.set(participant.toMap()).timeout(const Duration(seconds: 10));

    return participant;
  }

  @override
  Stream<List<AppParticipant>> watchParticipants(String tournamentId) {
    return Stream.fromFuture(_readRefsFor(tournamentId)).switchMap((refs) {
      final streams = refs.map((ref) {
        return ref.orderBy('enrolledAt', descending: false).snapshots().map((
          snapshot,
        ) {
          final list = <AppParticipant>[];
          for (final doc in snapshot.docs) {
            try {
              list.add(AppParticipant.fromMap(doc.data()));
            } catch (e) {
              // ignore: avoid_print
              print('Error mapeando participante: $e');
            }
          }
          return list;
        });
      });
      return Rx.combineLatestList(streams).map(
        (lists) => _dedupeParticipants(lists.expand((list) => list).toList()),
      );
    });
  }

  @override
  Future<List<AppParticipant>> getParticipants(String tournamentId) async {
    final refs = await _readRefsFor(tournamentId);
    final snapshots = await Future.wait(
      refs.map(
        (ref) => ref
            .orderBy('enrolledAt', descending: false)
            .get()
            .timeout(const Duration(seconds: 10)),
      ),
    );

    return _dedupeParticipants(
      snapshots
          .expand((snapshot) => snapshot.docs)
          .map((doc) => AppParticipant.fromMap(doc.data()))
          .toList(),
    );
  }

  @override
  Future<AppParticipant?> getParticipant({
    required String tournamentId,
    required String participantId,
  }) async {
    final refs = await _readRefsFor(tournamentId);
    for (final ref in refs) {
      final doc = await ref
          .doc(participantId)
          .get()
          .timeout(const Duration(seconds: 10));
      final data = doc.data();
      if (doc.exists && data != null) return AppParticipant.fromMap(data);
    }
    return null;
  }

  @override
  Future<void> updateStatus({
    required String tournamentId,
    required String participantId,
    required ParticipantStatus status,
  }) async {
    final ref = await _writableParticipantRef(
      tournamentId: tournamentId,
      participantId: participantId,
    );
    await ref
        .doc(participantId)
        .update({'status': status.firestoreValue})
        .timeout(const Duration(seconds: 10));
  }

  @override
  Future<void> updateParticipant({
    required String tournamentId,
    required String participantId,
    required Map<String, dynamic> data,
  }) async {
    final ref = await _writableParticipantRef(
      tournamentId: tournamentId,
      participantId: participantId,
    );
    await ref
        .doc(participantId)
        .update(data)
        .timeout(const Duration(seconds: 10));
  }

  @override
  Future<void> leaveTournament({
    required String tournamentId,
    required String participantId,
  }) async {
    final ref = await _writableParticipantRef(
      tournamentId: tournamentId,
      participantId: participantId,
    );
    await ref.doc(participantId).delete().timeout(const Duration(seconds: 10));
  }

  @override
  Future<bool> isEnrolled({
    required String tournamentId,
    required String entityId,
  }) async {
    final refs = await _readRefsFor(tournamentId);
    for (final ref in refs) {
      final snapshot = await ref
          .where('entityId', isEqualTo: entityId)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      if (snapshot.docs.isNotEmpty) return true;
    }
    return false;
  }

  Future<CollectionReference<Map<String, dynamic>>> _writableParticipantRef({
    required String tournamentId,
    required String participantId,
  }) async {
    final refs = await _readRefsFor(tournamentId);
    for (final ref in refs) {
      final doc = await ref
          .doc(participantId)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) return ref;
    }
    return refs.first;
  }

  List<AppParticipant> _dedupeParticipants(List<AppParticipant> participants) {
    final byId = <String, AppParticipant>{};
    for (final participant in participants) {
      byId[participant.id] = participant;
    }
    final list = byId.values.toList(growable: false);
    list.sort((a, b) => a.enrolledAt.compareTo(b.enrolledAt));
    return list;
  }

  @override
  Stream<List<AppParticipant>> watchEnrolledParticipants(String entityId) {
    // 1. Obtener los equipos donde el usuario es miembro
    final teamsStream = _db
        .collection('teams')
        .where('members', arrayContains: entityId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());

    // 2. Por cada actualización de equipos, generar los streams de participantes
    return teamsStream.switchMap((teamIds) {
      final idsToQuery = [entityId, ...teamIds];

      // Creamos un stream por cada ID (usuario + equipos) para evadir el límite de 10 de whereIn
      final streams = idsToQuery.map(
        (id) => _db
            .collectionGroup('participants')
            .where('entityId', isEqualTo: id)
            .snapshots()
            .map((snapshot) {
              final list = <AppParticipant>[];
              for (final doc in snapshot.docs) {
                try {
                  list.add(AppParticipant.fromMap(doc.data()));
                } catch (e) {
                  // ignore: avoid_print
                  print('Error mapeando participante inscrito: $e');
                }
              }
              return list;
            }),
      );

      // Combinamos todos los streams y aplanamos la lista
      return Rx.combineLatestList(streams).map((lists) {
        final combined = lists.expand((l) => l).toList();
        combined.sort((a, b) => b.enrolledAt.compareTo(a.enrolledAt));
        return combined;
      });
    });
  }
}
