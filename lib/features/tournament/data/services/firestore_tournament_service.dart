import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';

import '../model/app_tournament.dart';
import '../repositories/tournament_repository.dart';
import 'firebase_tournament_storage_service.dart';
import 'tournament_storage_service.dart';

/// Implementación de [TournamentRepository] usando Firestore como backend.
///
/// SRP: delega la gestión de Storage en [TournamentStorageService] y se
///       centra exclusivamente en las operaciones de Firestore.
/// DIP: depende de la abstracción [TournamentStorageService], no de la
///       implementación concreta.
class FirestoreTournamentService implements TournamentRepository {
  FirestoreTournamentService({
    FirebaseFirestore? firestore,
    TournamentStorageService? storageService,
  })  : _db = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'gromy-db',
            ),
        _storageService =
            storageService ?? FirebaseTournamentStorageService();

  final FirebaseFirestore _db;
  final TournamentStorageService _storageService;

  CollectionReference<Map<String, dynamic>> get _tournaments =>
      _db.collection('tournaments');

  // ──────────────────────────────────────────────────────────────
  //  TournamentRepository impl
  // ──────────────────────────────────────────────────────────────

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
    // Filtramos del lado del cliente para evitar índices compuestos en
    // Firestore. En un proyecto de mayor escala se usaría una query de
    // tipo array-contains con un índice.
    return watchTournaments().map(
      (tournaments) => tournaments
          .where(
            (t) =>
                t.organizerUid == uid,
          )
          .toList(),
    );
  }
  @override
  Stream<List<AppTournament>> watchTournamentsAdmin(String uid) {
    // Filtramos del lado del cliente para evitar índices compuestos en
    // Firestore. En un proyecto de mayor escala se usaría una query de
    // tipo array-contains con un índice.
    return watchTournaments().map(
      (tournaments) => tournaments
          .where(
            (t) =>
                t.adminIds.contains(uid),
          )
          .toList(),
    );
  }


}
