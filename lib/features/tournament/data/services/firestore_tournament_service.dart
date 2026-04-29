import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../database/participant/models/app_participant.dart';
import '../../../../database/participant/repositories/participant_repository.dart';
import '../../../../database/participant/services/firestore_participant_service.dart';
import '../model/app_tournament.dart';
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
  })  : _db = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'gromy-db',
            ),
        _storageService =
            storageService ?? FirebaseTournamentStorageService(),
        _participantRepo =
            participantRepository ?? FirestoreParticipantService();

  final FirebaseFirestore _db;
  final TournamentStorageService _storageService;
  final ParticipantRepository _participantRepo;

  CollectionReference<Map<String, dynamic>> get _tournaments =>
      _db.collection('tournaments');

  // ── Creación ───────────────────────────────────────────────────────────────

  @override
  Future<AppTournament> createTournament(AppTournament tournament) async {
    final docRef = tournament.id.isEmpty
        ? _tournaments.doc()
        : _tournaments.doc(tournament.id);
    final tournamentToSave = tournament.copyWith(id: docRef.id);

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
    final docRef = tournament.id.isEmpty
        ? _tournaments.doc()
        : _tournaments.doc(tournament.id);

    // 2. Subir imagen y obtener URL de descarga.
    final downloadUrl = await _storageService.uploadCoverImage(
      tournamentId: docRef.id,
      image: coverImage,
    );

    // 3. Asignar la URL al torneo y persistir.
    final tournamentToSave = tournament.copyWith(
      id: docRef.id,
      portadaUrl: downloadUrl,
    );

    await docRef
        .set(tournamentToSave.toMap())
        .timeout(const Duration(seconds: 10));

    return tournamentToSave;
  }

  // ── Lectura ────────────────────────────────────────────────────────────────

  @override
  Stream<List<AppTournament>> watchTournaments() {
    return _tournaments.snapshots().map((snapshot) {
      final list = <AppTournament>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(AppTournament.fromMap(doc.data()));
        } catch (e) {
          // ignore: avoid_print
          print('Error mapeando torneo: $e');
        }
      }
      list.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      return list;
    });
  }

  @override
  Stream<List<AppTournament>> watchMyTournaments(String uid) {
    return watchTournaments().map(
      (tournaments) =>
          tournaments.where((t) => t.organizerUid == uid).toList(),
    );
  }

  @override
  Stream<List<AppTournament>> watchTournamentsAdmin(String uid) {
    return watchTournaments().map(
      (tournaments) =>
          tournaments.where((t) => t.adminIds.contains(uid)).toList(),
    );
  }

  // ── Participantes (delegación en ParticipantRepository) ───────────────────

  @override
  Future<AppParticipant> joinTournament({
    required String tournamentId,
    required String entityId,
    required ParticipantEntityType entityType,
    ParticipantStatus status = ParticipantStatus.pending,
    String? categoryId,
  }) {
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
    return _participantRepo.watchEnrolledParticipants(uid).asyncMap((participants) async {
      final tournaments = <AppTournament>[];
      for (final p in participants) {
        try {
          final doc = await _tournaments.doc(p.tournamentId).get();
          if (doc.exists && doc.data() != null) {
            tournaments.add(AppTournament.fromMap(doc.data()!));
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
  Future<void> cancelInscription({
    required String tournamentId,
    required String participantId,
  }) async {
    final tournamentRef = _tournaments.doc(tournamentId);
    final participantRef = tournamentRef.collection('participants').doc(participantId);

    await _db.runTransaction((transaction) async {
      // 1. Verificar si el participante existe
      final participantDoc = await transaction.get(participantRef);
      if (!participantDoc.exists) {
        throw Exception('El participante ya no está inscrito o la inscripción ya fue cancelada.');
      }

      // 2. Obtener el documento del torneo para modificar el contador
      final tournamentDoc = await transaction.get(tournamentRef);
      if (!tournamentDoc.exists) {
        throw Exception('El torneo no existe.');
      }

      final data = tournamentDoc.data();
      final currentCount = data?['participantCount'] as int? ?? 0;

      // 3. Eliminar el participante
      transaction.delete(participantRef);

      // 4. Decrementar el contador asegurando que no sea negativo
      if (currentCount > 0) {
        transaction.update(tournamentRef, {'participantCount': currentCount - 1});
      }
    });
  }

  @override
  Future<void> incrementParticipantCount(String tournamentId) async {
    await _tournaments.doc(tournamentId).update({
      'participantCount': FieldValue.increment(1),
    });
  }

  @override
  Future<void> decrementParticipantCount(String tournamentId) async {
    await _tournaments.doc(tournamentId).update({
      'participantCount': FieldValue.increment(-1),
    });
  }

  // ── Validación de duplicados ───────────────────────────────────────────────

  @override
  Future<AppTournament?> findDuplicateTournament({
    required DateTime scheduledAt,
    required String location,
  }) async {
    // Rango del día natural seleccionado (00:00:00 → 23:59:59).
    final dayStart = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    final dayEnd   = dayStart.add(const Duration(days: 1));

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
        if (t.location.trim().toLowerCase() == normalizedLocation) return t;
      } catch (_) {
        // Ignorar documentos con formato incorrecto.
      }
    }
    return null;
  }
}
