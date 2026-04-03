import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../model/app_tournament.dart';
import '../repositories/tournament_repository.dart';

class FirestoreTournamentService implements TournamentRepository {
  FirestoreTournamentService({FirebaseFirestore? firestore})
    : _db =
          firestore ??
          FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'gromy-db',
          );

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _tournaments =>
      _db.collection('tournaments');

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
}
