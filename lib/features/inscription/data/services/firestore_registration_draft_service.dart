import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../domain/models/registration_draft.dart';
import '../repositories/registration_draft_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FirestoreRegistrationDraftService  ·  Capa de datos
//
//  Implementa [RegistrationDraftRepository] usando Firestore.
//
//  Colección: `registrationDrafts` en la instancia `gromy-db`.
//  ID del documento: "{userId}_{tournamentId}"
//
//  Decisión de diseño:
//  - Colección raíz (no subcolección) para permitir lecturas rápidas por userId
//    sin conocer el tournamentId de antemano.
//  - El ID compuesto garantiza unicidad y hace innecesario un índice adicional.
//  - Un borrador por usuario por torneo (upsert con set()).
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreRegistrationDraftService
    implements RegistrationDraftRepository {
  FirestoreRegistrationDraftService({FirebaseFirestore? firestore})
      : _db = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'gromy-db',
            );

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _drafts =>
      _db.collection('registrationDrafts');

  // ── Escritura ──────────────────────────────────────────────────────────────

  @override
  Future<void> saveRegistrationDraft(RegistrationDraft draft) async {
    await _drafts
        .doc(draft.id)
        .set(draft.toMap())
        .timeout(const Duration(seconds: 10));
  }

  // ── Lectura ────────────────────────────────────────────────────────────────

  @override
  Future<RegistrationDraft?> getRegistrationDraft(
    String userId,
    String tournamentId,
  ) async {
    try {
      final docId = RegistrationDraft.buildId(userId, tournamentId);
      final doc = await _drafts
          .doc(docId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!doc.exists || doc.data() == null) return null;

      return RegistrationDraft.fromMap(doc.data()!);
    } catch (_) {
      // Trata cualquier error de lectura como "sin borrador"
      return null;
    }
  }

  // ── Eliminación ───────────────────────────────────────────────────────────

  @override
  Future<void> deleteRegistrationDraft(
    String userId,
    String tournamentId,
  ) async {
    try {
      final docId = RegistrationDraft.buildId(userId, tournamentId);
      await _drafts
          .doc(docId)
          .delete()
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Ignorar errores de borrado (documento ya no existía, etc.)
    }
  }
}
