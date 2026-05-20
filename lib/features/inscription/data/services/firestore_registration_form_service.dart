import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/models/registration_form.dart';
import '../repositories/registration_form_repository.dart';

class FirestoreRegistrationFormService implements RegistrationFormRepository {
  FirestoreRegistrationFormService({FirebaseFirestore? firestore})
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

  Future<DocumentReference<Map<String, dynamic>>> _getTournamentDoc(
    String tournamentId,
  ) async {
    final publicDoc = await _tournaments.doc(tournamentId).get();
    if (publicDoc.exists) return _tournaments.doc(tournamentId);
    return _privateTournaments.doc(tournamentId);
  }

  @override
  Future<RegistrationFormSchema> getActiveForm(String tournamentId) async {
    final ref = await _getTournamentDoc(tournamentId);
    final doc = await ref.get().timeout(const Duration(seconds: 10));
    return RegistrationFormSchema.fromMap(
      doc.data()?['registrationForm'] as Map<String, dynamic>?,
    );
  }

  @override
  Future<void> saveForm({
    required String tournamentId,
    required RegistrationFormSchema form,
    bool incrementVersion = true,
  }) async {
    final errors = RegistrationFormValidator.validateSchema(form);
    if (errors.isNotEmpty) {
      throw ArgumentError(errors.first);
    }

    final ref = await _getTournamentDoc(tournamentId);
    final doc = await ref.get().timeout(const Duration(seconds: 10));
    final current = RegistrationFormSchema.fromMap(
      doc.data()?['registrationForm'] as Map<String, dynamic>?,
    );
    final next = form.copyWith(
      version: incrementVersion ? current.version + 1 : current.version,
    );

    await ref
        .update({
          'registrationForm': next.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 10));
  }
}
