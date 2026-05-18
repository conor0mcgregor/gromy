import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../domain/models/registration_form_schema.dart';
import '../repositories/registration_form_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FirestoreRegistrationFormService  ·  Capa de datos
//
//  Implementa [RegistrationFormRepository] usando Firestore.
//  El esquema se almacena como campo embebido del documento del torneo:
//    tournaments/{tournamentId}.registrationForm
//
//  Decisión: campo embebido en lugar de subcolección porque el esquema
//  siempre se lee junto con el torneo y su tamaño es moderado.
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreRegistrationFormService implements RegistrationFormRepository {
  FirestoreRegistrationFormService({FirebaseFirestore? firestore})
      : _db = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'gromy-db',
            );

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _tournamentDoc(String id) =>
      _db.collection('tournaments').doc(id);

  @override
  Future<RegistrationFormSchema?> getFormSchema(String tournamentId) async {
    final doc = await _tournamentDoc(tournamentId)
        .get()
        .timeout(const Duration(seconds: 10));

    if (!doc.exists || doc.data() == null) return null;

    final formData = doc.data()!['registrationForm'];
    if (formData == null) return null;

    return RegistrationFormSchema.fromMap(
      formData as Map<String, dynamic>,
    );
  }

  @override
  Future<void> saveFormSchema(
    String tournamentId,
    RegistrationFormSchema schema,
  ) async {
    // Leer versión actual para auto-incrementar.
    final current = await getFormSchema(tournamentId);
    final nextVersion = (current?.version ?? 0) + 1;

    final updatedSchema = schema.copyWith(
      version: nextVersion,
      updatedAt: DateTime.now(),
      createdAt: current?.createdAt ?? DateTime.now(),
    );

    await _tournamentDoc(tournamentId).update({
      'registrationForm': updatedSchema.toMap(),
    }).timeout(const Duration(seconds: 10));
  }

  @override
  Future<void> deleteFormSchema(String tournamentId) async {
    await _tournamentDoc(tournamentId).update({
      'registrationForm': FieldValue.delete(),
    }).timeout(const Duration(seconds: 10));
  }
}
