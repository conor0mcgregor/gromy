import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../database/participant/models/app_participant.dart';
import '../../../../database/participant/repositories/participant_repository.dart';
import '../../../../database/participant/services/firestore_participant_service.dart';
import '../model/app_tournament.dart';
import '../model/enums_tournament.dart';
import '../repositories/tournament_repository.dart';
import 'firebase_tournament_storage_service.dart';
import 'tournament_storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FirestoreTournamentService  ·  Capa de datos
//
//  Implementa [TournamentRepository] usando Firestore como backend.
//
//  SRP: delega la gestión de Storage en [TournamentStorageService] y la de
//       participantes en [ParticipantRepository].
//  DIP: depende de abstracciones, no de implementaciones concretas.
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreTournamentService implements TournamentRepository {
  FirestoreTournamentService({
    FirebaseFirestore? firestore,
    TournamentStorageService? storageService,
    ParticipantRepository? participantRepository,
  }) : _db =
      firestore ??
          FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'gromy-db',
          ),
        _storageService = storageService ?? FirebaseTournamentStorageService(),
        _participantRepo =
            participantRepository ?? FirestoreParticipantService();

  final FirebaseFirestore _db;
  final TournamentStorageService _storageService;
  final ParticipantRepository _participantRepo;

  CollectionReference<Map<String, dynamic>> get _tournaments =>
      _db.collection('tournaments');

  CollectionReference<Map<String, dynamic>> get _privateTournaments =>
      _db.collection('private_tournaments');

  Future<DocumentReference<Map<String, dynamic>>> _getTournamentDoc(
      String id,
      ) async {
    final doc = await _tournaments.doc(id).get();
    if (doc.exists) {
      return _tournaments.doc(id);
    }
    return _privateTournaments.doc(id);
  }

  // ── Creación ───────────────────────────────────────────────────────────────

  @override
  Future<AppTournament> createTournament(AppTournament tournament) async {
    final collection =
        tournament.accessType == TournamentAccessType.privateInviteOnly
        ? _privateTournaments
        : _tournaments;
    final docRef = tournament.id.isEmpty
        ? collection.doc()
        : collection.doc(tournament.id);
    final tournamentToSave = tournament.copyWith(
      id: docRef.id,
      status: TournamentStatus.published,
    );

    await docRef
        .set(tournamentToSave.toMap())
        .timeout(const Duration(seconds: 10));

    return tournamentToSave;
  }

  @override
  Future<AppTournament> createTournamentWithCover({
    required AppTournament tournament,
    required XFile coverImage,
  }) async {
    // 1. Reservar un ID en Firestore para usarlo en la ruta de Storage.
    final collection =
    tournament.accessType == TournamentAccessType.privateInviteOnly
        ? _privateTournaments
        : _tournaments;
    final docRef = tournament.id.isEmpty
        ? collection.doc()
        : collection.doc(tournament.id);

    // 2. Subir imagen y obtener URL de descarga.
    final downloadUrl = await _storageService.uploadCoverImage(
      tournamentId: docRef.id,
      ownerUid: tournament.organizerUid,
      image: coverImage,
    );

    // 3. Asignar la URL al torneo y persistir.
    final tournamentToSave = tournament.copyWith(
      id: docRef.id,
      portadaUrl: downloadUrl,
      status: TournamentStatus.published,
    );

    await docRef
        .set(tournamentToSave.toMap())
        .timeout(const Duration(seconds: 10));

    return tournamentToSave;
  }

  // ── Lectura ────────────────────────────────────────────────────────────────

  Stream<List<AppTournament>> _watchAllPublicTournaments() {
    return _tournaments.snapshots().map((snapshot) {
      final list = <AppTournament>[];
      for (final doc in snapshot.docs) {
        try {
          final tournament = AppTournament.fromMap(doc.data());
          if (tournament.isPubliclyVisible) {
            list.add(tournament);
          }
        } catch (e) {
          // ignore: avoid_print
          print('Error mapeando torneo: $e');
        }
      }
      return list;
    });
  }

  @override
  Stream<List<AppTournament>> watchTournaments() {
    return _watchAllPublicTournaments().map((all) {
      final pastThreshold = DateTime.now().subtract(const Duration(days: 1));
      final active = all.where((t) => !t.scheduledAt.isBefore(pastThreshold)).toList();
      active.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      return active;
    });
  }

  Stream<List<AppTournament>> _watchPrivateTournaments() {
    return _privateTournaments.snapshots().map((snapshot) {
      final list = <AppTournament>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(AppTournament.fromMap(doc.data()));
        } catch (e) {
          // ignore: avoid_print
          print('Error mapeando torneo privado: $e');
        }
      }
      return list;
    });
  }

  @override
  Stream<List<AppTournament>> watchMyTournaments(String uid) {
    return Rx.combineLatest2(_watchAllPublicTournaments(), _watchPrivateTournaments(), (
          List<AppTournament> public,
      List<AppTournament> private,
    ) {
      final all = [...public, ...private];
      return all.where((t) => t.organizerUid == uid).toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    });
  }

  @override
  Stream<List<AppTournament>> watchTournamentsAdmin(String uid) {
    return Rx.combineLatest2(_watchAllPublicTournaments(), _watchPrivateTournaments(), (
          List<AppTournament> public,
      List<AppTournament> private,
    ) {
      final all = [...public, ...private];
      return all.where((t) => t.adminIds.contains(uid)).toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    });
  }

  // ── Participantes (delegación en ParticipantRepository) ───────────────────

  @override
  Future<AppParticipant> joinTournament({
    required String tournamentId,
    required String entityId,
    required ParticipantEntityType entityType,
    ParticipantStatus status = ParticipantStatus.pending,
    String? categoryId,
  }) async {
    final docRef = await _getTournamentDoc(tournamentId);
    final doc = await docRef.get();
    if (doc.exists && doc.data() != null) {
      final t = AppTournament.fromMap(doc.data()!);
      final pastThreshold = DateTime.now().subtract(const Duration(days: 1));
      if (t.scheduledAt.isBefore(pastThreshold)) {
        throw Exception('El torneo ha finalizado, ya no se admiten inscripciones.');
      }
    } else {
      throw Exception('El torneo no existe.');
    }

    return _participantRepo.joinTournament(
      tournamentId: tournamentId,
      entityId: entityId,
      entityType: entityType,
      status: status,
      categoryId: categoryId,
    );
  }

  @override
  Future<List<AppParticipant>> getParticipants(String tournamentId) {
    return _participantRepo.getParticipants(tournamentId);
  }

  @override
  Stream<List<AppParticipant>> watchParticipants(String tournamentId) {
    return _participantRepo.watchParticipants(tournamentId);
  }

  @override
  Stream<List<AppTournament>> watchEnrolledTournaments(String uid) {
    return _participantRepo.watchEnrolledParticipants(uid).asyncMap((
        participants,
        ) async {
      final tournaments = <AppTournament>[];
      for (final p in participants) {
        try {
          var doc = await _tournaments.doc(p.tournamentId).get();
          if (!doc.exists) {
            doc = await _privateTournaments.doc(p.tournamentId).get();
          }
          if (doc.exists && doc.data() != null) {
            final tournament = AppTournament.fromMap(doc.data()!);
            if (tournament.isPubliclyVisible) {
              tournaments.add(tournament);
            }
          }
        } catch (e) {
          // ignore: avoid_print
          print('Error fetching tournament for participant: $e');
        }
      }
      return tournaments;
    });
  }

  @override
  Stream<List<AppTournament>> watchHistoricalTournaments(String uid) {
    return _participantRepo.watchEnrolledParticipants(uid).asyncMap((
        participants,
        ) async {
      final tournaments = <AppTournament>[];
      final validParticipants = participants.where((p) => p.status != ParticipantStatus.rejected).toList();
      final now = DateTime.now();
      final pastThreshold = now.subtract(const Duration(days: 1));

      for (final p in validParticipants) {
        try {
          var doc = await _tournaments.doc(p.tournamentId).get();
          if (!doc.exists) {
            doc = await _privateTournaments.doc(p.tournamentId).get();
          }
          if (doc.exists && doc.data() != null) {
            final t = AppTournament.fromMap(doc.data()!);
            if (t.scheduledAt.isBefore(pastThreshold)) {
              tournaments.add(t);
            }
          }
        } catch (e) {
          // ignore: avoid_print
          print('Error fetching historical tournament: $e');
        }
      }
      tournaments.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      return tournaments;
    });
  }

  @override
  Future<void> cancelInscription({
    required String tournamentId,
    required String participantId,
  }) async {
    await _db.runTransaction((transaction) async {
      DocumentReference<Map<String, dynamic>> tournamentRef = _tournaments.doc(
        tournamentId,
      );
      DocumentSnapshot<Map<String, dynamic>> tournamentDoc = await transaction
          .get(tournamentRef);
      if (!tournamentDoc.exists) {
        tournamentRef = _privateTournaments.doc(tournamentId);
        tournamentDoc = await transaction.get(tournamentRef);
        if (!tournamentDoc.exists) {
          throw Exception('El torneo no existe.');
        }
      }

      final participantRef = tournamentRef
          .collection('participants')
          .doc(participantId);
      final participantDoc = await transaction.get(participantRef);
      if (!participantDoc.exists) {
        throw Exception(
          'El participante ya no está inscrito o la inscripción ya fue cancelada.',
        );
      }

      final data = tournamentDoc.data();
      final currentCount = data?['participantCount'] as int? ?? 0;

      transaction.delete(participantRef);

      if (currentCount > 0) {
        transaction.update(tournamentRef, {
          'participantCount': currentCount - 1,
        });
      }
    });
  }

  @override
  Future<void> incrementParticipantCount(String tournamentId) async {
    final ref = await _getTournamentDoc(tournamentId);
    await ref.update({'participantCount': FieldValue.increment(1)});
  }

  @override
  Future<void> decrementParticipantCount(String tournamentId) async {
    final ref = await _getTournamentDoc(tournamentId);
    await ref.update({'participantCount': FieldValue.increment(-1)});
  }

  // ── Validación de duplicados ───────────────────────────────────────────────

  @override
  Future<AppTournament?> findDuplicateTournament({
    required DateTime scheduledAt,
    required String location,
  }) async {
    // Rango del día natural seleccionado para acotar la consulta; el filtrado
    // final exige el mismo instante y la misma ubicación normalizada.
    final dayStart = DateTime(
      scheduledAt.year,
      scheduledAt.month,
      scheduledAt.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));

    final snapshot = await _tournaments
        .where(
      'scheduledAt',
      isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart),
    )
        .where('scheduledAt', isLessThan: Timestamp.fromDate(dayEnd))
        .get()
        .timeout(const Duration(seconds: 10));

    final normalizedLocation = location.trim().toLowerCase();

    for (final doc in snapshot.docs) {
      try {
        final t = AppTournament.fromMap(doc.data());
        if (!t.isPubliclyVisible) continue;
        final sameScheduledAt =
            t.scheduledAt.millisecondsSinceEpoch ==
                scheduledAt.millisecondsSinceEpoch;
        final sameLocation =
            t.location.trim().toLowerCase() == normalizedLocation;
        if (sameScheduledAt && sameLocation) return t;
      } catch (_) {
        // Ignorar documentos con formato incorrecto.
      }
    }
    return null;
  }
}
