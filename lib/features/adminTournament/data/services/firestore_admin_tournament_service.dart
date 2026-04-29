import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../tournament/data/model/app_tournament.dart';
import '../repositories/admin_tournament_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FirestoreAdminTournamentService  ·  Capa de datos
//
//  Implementa [AdminTournamentRepository] usando Firestore como backend.
//
//  SRP: solo gestiona operaciones de administración de torneos.
//  DIP: los consumidores dependen de la abstracción, no de esta clase.
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreAdminTournamentService implements AdminTournamentRepository {
  FirestoreAdminTournamentService({FirebaseFirestore? firestore})
    : _db =
          firestore ??
          FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'gromy-db',
          );

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _tournaments =>
      _db.collection('tournaments');

  // ── Actualización ─────────────────────────────────────────────────────────

  @override
  Future<void> updateTournament({
    required AppTournament original,
    required AppTournament updated,
  }) async {
    final data = _changedFields(original, updated);
    if (data.isEmpty) return;

    data['updatedAt'] = Timestamp.fromDate(updated.updatedAt);
    await _tournaments
        .doc(updated.id)
        .update(data)
        .timeout(const Duration(seconds: 10));
  }

  Map<String, dynamic> _changedFields(
    AppTournament original,
    AppTournament updated,
  ) {
    final data = <String, dynamic>{};

    _putIfChanged(data, 'name', original.name, updated.name);
    _putIfChanged(
      data,
      'description',
      original.description,
      updated.description,
    );
    _putIfChanged(
      data,
      'allInformation',
      original.allInformation,
      updated.allInformation,
    );
    _putIfChanged(
      data,
      'scheduledAt',
      original.scheduledAt,
      updated.scheduledAt,
      mapper: (value) => Timestamp.fromDate(value as DateTime),
    );
    _putIfChanged(
      data,
      'maxParticipants',
      original.maxParticipants,
      updated.maxParticipants,
    );
    _putIfChanged(
      data,
      'membersPerTeam',
      original.membersPerTeam,
      updated.membersPerTeam,
    );
    _putIfChanged(data, 'location', original.location, updated.location);
    _putIfChanged(data, 'latitude', original.latitude, updated.latitude);
    _putIfChanged(data, 'longitude', original.longitude, updated.longitude);
    _putIfChanged(data, 'portadaUrl', original.portadaUrl, updated.portadaUrl);
    _putIfChanged(
      data,
      'registrationDeadline',
      original.registrationDeadline,
      updated.registrationDeadline,
      mapper: _nullableTimestamp,
    );
    _putIfChanged(
      data,
      'bracketPublishDate',
      original.bracketPublishDate,
      updated.bracketPublishDate,
      mapper: _nullableTimestamp,
    );
    _putIfChanged(
      data,
      'contactEmail',
      original.contactEmail,
      updated.contactEmail,
    );
    _putIfChanged(
      data,
      'contactPhone',
      original.contactPhone,
      updated.contactPhone,
    );
    if (!_stringListEquals(original.contactLinks, updated.contactLinks)) {
      data['contactLinks'] = updated.contactLinks;
    }
    if (!_stringListEquals(original.categories, updated.categories)) {
      data['categories'] = updated.categories;
    }
    if (!_stringListEquals(original.adminIds, updated.adminIds)) {
      data['adminIds'] = updated.adminIds;
    }

    return data;
  }

  void _putIfChanged(
    Map<String, dynamic> data,
    String field,
    Object? original,
    Object? updated, {
    Object? Function(Object? value)? mapper,
  }) {
    if (original == updated) return;
    data[field] = mapper == null ? updated : mapper(updated);
  }

  Object? _nullableTimestamp(Object? value) {
    if (value == null) return null;
    return Timestamp.fromDate(value as DateTime);
  }

  bool _stringListEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ── Participantes ─────────────────────────────────────────────────────────

  @override
  Future<void> removeParticipant({
    required String tournamentId,
    required String participantId,
  }) async {
    final tournamentRef = _tournaments.doc(tournamentId);
    final participantRef = tournamentRef
        .collection('participants')
        .doc(participantId);

    await _db.runTransaction((transaction) async {
      // 1. Verificar existencia del participante
      final participantDoc = await transaction.get(participantRef);
      if (!participantDoc.exists) {
        throw Exception('El participante ya no está inscrito.');
      }

      // 2. Obtener torneo para actualizar contador
      final tournamentDoc = await transaction.get(tournamentRef);
      if (!tournamentDoc.exists) {
        throw Exception('El torneo no existe.');
      }

      final currentCount =
          tournamentDoc.data()?['participantCount'] as int? ?? 0;

      // 3. Eliminar participante
      transaction.delete(participantRef);

      // 4. Decrementar contador
      if (currentCount > 0) {
        transaction.update(tournamentRef, {
          'participantCount': currentCount - 1,
        });
      }
    });
  }

  @override
  Future<void> updateParticipantCategory({
    required String tournamentId,
    required String participantId,
    required String categoryId,
  }) async {
    final participantRef = _tournaments
        .doc(tournamentId)
        .collection('participants')
        .doc(participantId);

    await _db
        .runTransaction((transaction) async {
          final participantDoc = await transaction.get(participantRef);
          if (!participantDoc.exists) {
            throw Exception('El participante ya no está inscrito.');
          }

          transaction.update(participantRef, {'categoryId': categoryId});
        })
        .timeout(const Duration(seconds: 10));
  }

  // ── Administradores ───────────────────────────────────────────────────────

  @override
  Future<void> addAdmin({
    required String tournamentId,
    required String adminUid,
  }) async {
    await _tournaments
        .doc(tournamentId)
        .update({
          'adminIds': FieldValue.arrayUnion([adminUid]),
        })
        .timeout(const Duration(seconds: 10));
  }

  @override
  Future<void> removeAdmin({
    required String tournamentId,
    required String adminUid,
  }) async {
    await _tournaments
        .doc(tournamentId)
        .update({
          'adminIds': FieldValue.arrayRemove([adminUid]),
        })
        .timeout(const Duration(seconds: 10));
  }

  // ── Eliminación ───────────────────────────────────────────────────────────

  @override
  Future<void> deleteTournament(String tournamentId) async {
    final tournamentRef = _tournaments.doc(tournamentId);

    // 1. Eliminar todos los participantes de la subcolección
    final participantsSnap = await tournamentRef
        .collection('participants')
        .get();
    final batch = _db.batch();
    for (final doc in participantsSnap.docs) {
      batch.delete(doc.reference);
    }

    // 2. Eliminar bracket si existe
    final bracketSnap = await tournamentRef.collection('bracket').get();
    for (final doc in bracketSnap.docs) {
      batch.delete(doc.reference);
    }

    // 3. Eliminar el documento del torneo
    batch.delete(tournamentRef);

    await batch.commit().timeout(const Duration(seconds: 15));
  }

  // ── Lectura auxiliar ──────────────────────────────────────────────────────

  @override
  Future<AppTournament?> getTournament(String tournamentId) async {
    final doc = await _tournaments
        .doc(tournamentId)
        .get()
        .timeout(const Duration(seconds: 10));
    if (!doc.exists || doc.data() == null) return null;
    return AppTournament.fromMap(doc.data()!);
  }
}
