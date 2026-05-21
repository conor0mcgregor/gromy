import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Resultado de búsqueda de un torneo en colección pública o privada.
class TournamentDocumentLookup {
  const TournamentDocumentLookup({
    required this.reference,
    required this.snapshot,
  });

  final DocumentReference<Map<String, dynamic>> reference;
  final DocumentSnapshot<Map<String, dynamic>> snapshot;

  bool get isPrivate => reference.parent.id == 'private_tournaments';

  Map<String, dynamic>? get data => snapshot.data();
}

/// Resuelve referencias de torneo en `tournaments` o `private_tournaments`.
class TournamentCollectionResolver {
  TournamentCollectionResolver({FirebaseFirestore? firestore})
    : _db =
          firestore ??
          FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'gromy-db',
          );

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _publicTournaments =>
      _db.collection('tournaments');

  CollectionReference<Map<String, dynamic>> get _privateTournaments =>
      _db.collection('private_tournaments');

  /// Busca el documento en ambas colecciones. Devuelve `null` si no existe.
  Future<TournamentDocumentLookup?> lookup(String tournamentId) async {
    final publicSnap = await _publicTournaments
        .doc(tournamentId)
        .get()
        .timeout(const Duration(seconds: 10));
    if (publicSnap.exists) {
      return TournamentDocumentLookup(
        reference: publicSnap.reference,
        snapshot: publicSnap,
      );
    }

    final privateSnap = await _privateTournaments
        .doc(tournamentId)
        .get()
        .timeout(const Duration(seconds: 10));
    if (privateSnap.exists) {
      return TournamentDocumentLookup(
        reference: privateSnap.reference,
        snapshot: privateSnap,
      );
    }

    return null;
  }

  /// Devuelve la referencia del torneo en la colección donde existe.
  Future<DocumentReference<Map<String, dynamic>>> referenceFor(
    String tournamentId,
  ) async {
    final found = await lookup(tournamentId);
    if (found == null) {
      throw Exception('El torneo no existe.');
    }
    return found.reference;
  }
}
