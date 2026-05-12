import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rxdart/rxdart.dart';

import '../../../tournament/data/model/app_tournament.dart';
import '../repositories/favorite_repository.dart';

class FirestoreFavoriteService implements FavoriteRepository {
  FirestoreFavoriteService({FirebaseFirestore? firestore})
      : _db = firestore ??
      FirebaseFirestore.instanceFor(
          app: Firebase.app(), databaseId: 'gromy-db');

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _userFavorites(String uid) =>
      _db.collection('users').doc(uid).collection('favorites');

  CollectionReference<Map<String, dynamic>> get _tournaments =>
      _db.collection('tournaments');

  @override
  Future<void> toggleFavorite({
    required String uid,
    required String tournamentId,
  }) async {
    final docRef = _userFavorites(uid).doc(tournamentId);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'tournamentId': tournamentId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Stream<bool> isFavorite(String uid, String tournamentId) {
    return _userFavorites(uid)
        .doc(tournamentId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  @override
  Stream<List<AppTournament>> watchFavoriteTournaments(String uid) {
    return _userFavorites(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .switchMap((snapshot) {
      if (snapshot.docs.isEmpty) {
        return Stream.value(<AppTournament>[]);
      }

      final tournamentIds =
      snapshot.docs.map((doc) => doc.id).toList();

      // Firestore 'whereIn' limits to 30 items
      // If we have more than 30, we should chunk them, but for simplicity, 
      // let's fetch in chunks of 30 and combine the streams.
      final chunks = <List<String>>[];
      for (var i = 0; i < tournamentIds.length; i += 30) {
        chunks.add(tournamentIds.sublist(
            i,
            i + 30 > tournamentIds.length
                ? tournamentIds.length
                : i + 30));
      }

      final streams = chunks.map((chunk) {
        return _tournaments
            .where(FieldPath.documentId, whereIn: chunk)
            .snapshots()
            .map((snap) => snap.docs
            .map((doc) => AppTournament.fromMap(doc.data()))
            .toList());
      });

      return Rx.combineLatestList(streams).map((lists) {
        final allTournaments = lists.expand((element) => element).toList();

        // Mantener el orden de createdAt original (que viene en snapshot.docs)
        final orderedTournaments = <AppTournament>[];
        for (final id in tournamentIds) {
          final t = allTournaments.where((element) => element.id == id).firstOrNull;
          if (t != null) {
            orderedTournaments.add(t);
          }
        }

        return orderedTournaments;
      });
    });
  }
}
