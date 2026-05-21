import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/models/registration_form.dart';
import '../../../brackets/data/services/cloud_function_bracket_service.dart';
import '../../../tournament/data/helpers/tournament_collection_resolver.dart';
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
  FirestoreAdminTournamentService({
    FirebaseFirestore? firestore,
    CloudFunctionBracketService? bracketCloudService,
    TournamentCollectionResolver? tournamentResolver,
  }) : _db =
           firestore ??
           FirebaseFirestore.instanceFor(
             app: Firebase.app(),
             databaseId: 'gromy-db',
           ),
       _bracketCloudService =
           bracketCloudService ?? CloudFunctionBracketService(),
       _tournamentResolver =
           tournamentResolver ??
           TournamentCollectionResolver(firestore: firestore);

  final FirebaseFirestore _db;
  final CloudFunctionBracketService _bracketCloudService;
  final TournamentCollectionResolver _tournamentResolver;

  CollectionReference<Map<String, dynamic>> get _tournaments =>
      _db.collection('tournaments');

  Future<DocumentReference<Map<String, dynamic>>> _tournamentRefFor(
    String tournamentId,
  ) => _tournamentResolver.referenceFor(tournamentId);

  // ── Actualización ─────────────────────────────────────────────────────────

  @override
  Future<void> updateTournament({
    required AppTournament original,
    required AppTournament updated,
  }) async {
    final data = _changedFields(original, updated);
    if (data.isEmpty) return;

    data['updatedAt'] = Timestamp.fromDate(updated.updatedAt);
    final tournamentRef = await _tournamentRefFor(updated.id);
    await tournamentRef.update(data).timeout(const Duration(seconds: 10));
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
    _putIfChanged(
      data,
      'organizerDisplayName',
      original.organizerDisplayName,
      updated.organizerDisplayName,
    );
    _putIfChanged(
      data,
      'organizerEmail',
      original.organizerEmail,
      updated.organizerEmail,
    );
    _putIfChanged(data, 'status', original.status.name, updated.status.name);
    if (!_stringListEquals(original.contactLinks, updated.contactLinks)) {
      data['contactLinks'] = updated.contactLinks;
    }
    if (!_stringListEquals(original.categories, updated.categories)) {
      data['categories'] = updated.categories;
    }
    if (!_registrationFormsEqual(
      original.registrationForm,
      updated.registrationForm,
    )) {
      data['registrationForm'] = updated.registrationForm.toMap();
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

  bool _registrationFormsEqual(
    RegistrationFormSchema a,
    RegistrationFormSchema b,
  ) {
    if (a.version != b.version || a.fields.length != b.fields.length) {
      return false;
    }
    for (var i = 0; i < a.fields.length; i++) {
      final left = a.fields[i];
      final right = b.fields[i];
      if (left.id != right.id ||
          left.label != right.label ||
          left.description != right.description ||
          left.type != right.type ||
          left.required != right.required ||
          left.order != right.order ||
          left.enabled != right.enabled ||
          left.createdAt != right.createdAt ||
          left.updatedAt != right.updatedAt ||
          !_stringListEquals(left.options, right.options)) {
        return false;
      }
    }
    return true;
  }

  // ── Participantes ─────────────────────────────────────────────────────────

  @override
  Future<void> removeParticipant({
    required String tournamentId,
    required String participantId,
  }) async {
    final tournamentRef = await _tournamentRefFor(tournamentId);
    String? entityId;

    await _db.runTransaction((transaction) async {
      // 1. Verificar existencia del participante
      final participantRef = tournamentRef
          .collection('participants')
          .doc(participantId);
      var writableParticipantRef = participantRef;
      var participantDoc = await transaction.get(participantRef);
      if (!participantDoc.exists &&
          tournamentRef.parent.id == 'private_tournaments') {
        final legacyParticipantRef = _tournaments
            .doc(tournamentId)
            .collection('participants')
            .doc(participantId);
        final legacyParticipantDoc = await transaction.get(
          legacyParticipantRef,
        );
        if (legacyParticipantDoc.exists) {
          writableParticipantRef = legacyParticipantRef;
          participantDoc = legacyParticipantDoc;
        }
      }
      if (!participantDoc.exists) {
        throw Exception('El participante ya no está inscrito.');
      }

      entityId = participantDoc.data()?['entityId'] as String?;
      if (entityId == null || entityId!.isEmpty) {
        throw Exception('El participante no tiene entityId válido.');
      }

      // 2. Obtener torneo para actualizar contador
      final tournamentDoc = await transaction.get(tournamentRef);
      if (!tournamentDoc.exists) {
        throw Exception('El torneo no existe.');
      }

      final currentCount =
          tournamentDoc.data()?['participantCount'] as int? ?? 0;

      // 3. Eliminar participante
      transaction.delete(writableParticipantRef);

      // 4. Decrementar contador
      if (currentCount > 0) {
        transaction.update(tournamentRef, {
          'participantCount': currentCount - 1,
        });
      }
    });

    await _bracketCloudService.purgeParticipantFromBrackets(
      tournamentId: tournamentId,
      entityId: entityId!,
    );
  }

  @override
  Future<int> migrateCategoryParticipants({
    required String tournamentId,
    required String sourceCategory,
    required String targetCategory,
  }) async {
    if (sourceCategory.trim().isEmpty || targetCategory.trim().isEmpty) {
      throw ArgumentError('Las categorías no pueden estar vacías.');
    }
    if (sourceCategory == targetCategory) {
      throw ArgumentError(
        'La categoría destino debe ser distinta a la que se elimina.',
      );
    }

    final tournamentRef = await _tournamentRefFor(tournamentId);
    final refs = await _participantRefsFor(tournamentRef, tournamentId);
    final entityIds = <String>{};
    final docRefs = <DocumentReference<Map<String, dynamic>>>[];

    for (final ref in refs) {
      final snap = await ref
          .collection('participants')
          .where('categoryId', isEqualTo: sourceCategory)
          .get();
      for (final doc in snap.docs) {
        final entityId = doc.data()['entityId'] as String?;
        if (entityId == null || entityId.isEmpty) continue;
        entityIds.add(entityId);
        docRefs.add(doc.reference);
      }
    }

    if (docRefs.isEmpty) return 0;

    for (final entityId in entityIds) {
      await _bracketCloudService.purgeParticipantFromBrackets(
        tournamentId: tournamentId,
        entityId: entityId,
        categoryId: sourceCategory,
      );
    }

    const batchLimit = 400;
    var batch = _db.batch();
    var ops = 0;

    for (final docRef in docRefs) {
      batch.update(docRef, {
        'categoryId': targetCategory,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ops++;
      if (ops >= batchLimit) {
        await batch.commit();
        batch = _db.batch();
        ops = 0;
      }
    }

    if (ops > 0) {
      await batch.commit();
    }

    return docRefs.length;
  }

  Future<List<DocumentReference<Map<String, dynamic>>>> _participantRefsFor(
    DocumentReference<Map<String, dynamic>> tournamentRef,
    String tournamentId,
  ) async {
    if (tournamentRef.parent.id == 'private_tournaments') {
      return [
        tournamentRef,
        _tournaments.doc(tournamentId),
      ];
    }
    return [tournamentRef];
  }

  @override
  Future<void> updateParticipantCategory({
    required String tournamentId,
    required String participantId,
    required String categoryId,
  }) async {
    final tournamentRef = await _tournamentRefFor(tournamentId);

    await _db
        .runTransaction((transaction) async {
          final participantRef = tournamentRef
              .collection('participants')
              .doc(participantId);
          var writableParticipantRef = participantRef;
          var participantDoc = await transaction.get(participantRef);
          if (!participantDoc.exists &&
              tournamentRef.parent.id == 'private_tournaments') {
            final legacyParticipantRef = _tournaments
                .doc(tournamentId)
                .collection('participants')
                .doc(participantId);
            final legacyParticipantDoc = await transaction.get(
              legacyParticipantRef,
            );
            if (legacyParticipantDoc.exists) {
              writableParticipantRef = legacyParticipantRef;
              participantDoc = legacyParticipantDoc;
            }
          }
          if (!participantDoc.exists) {
            throw Exception('El participante ya no está inscrito.');
          }

          transaction.update(writableParticipantRef, {
            'categoryId': categoryId,
          });
        })
        .timeout(const Duration(seconds: 10));
  }

  // ── Administradores ───────────────────────────────────────────────────────

  @override
  Future<void> addAdmin({
    required String tournamentId,
    required String adminUid,
  }) async {
    final tournamentRef = await _tournamentRefFor(tournamentId);
    await tournamentRef
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
    final tournamentRef = await _tournamentRefFor(tournamentId);
    await tournamentRef
        .update({
          'adminIds': FieldValue.arrayRemove([adminUid]),
        })
        .timeout(const Duration(seconds: 10));
  }

  // ── Eliminación ───────────────────────────────────────────────────────────

  @override
  Future<void> deleteTournament(String tournamentId) async {
    final tournamentRef = await _tournamentRefFor(tournamentId);

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

    if (tournamentRef.parent.id == 'private_tournaments') {
      final legacyParticipantsSnap = await _tournaments
          .doc(tournamentId)
          .collection('participants')
          .get();
      for (final doc in legacyParticipantsSnap.docs) {
        batch.delete(doc.reference);
      }
    }

    // 3. Eliminar el documento del torneo
    batch.delete(tournamentRef);

    await batch.commit().timeout(const Duration(seconds: 15));
  }

  // ── Lectura auxiliar ──────────────────────────────────────────────────────

  @override
  Future<AppTournament?> getTournament(String tournamentId) async {
    final lookup = await _tournamentResolver.lookup(tournamentId);
    final data = lookup?.data;
    if (lookup == null || data == null) return null;
    return AppTournament.fromMap(data);
  }
}
