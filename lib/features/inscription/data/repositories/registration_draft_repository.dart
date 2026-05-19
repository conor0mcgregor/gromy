import '../../domain/models/registration_draft.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RegistrationDraftRepository  ·  Abstracción de la capa de datos
//
//  Define el contrato para persistir borradores de inscripción.
//  Cumple DIP: la capa de dominio depende de esta abstracción, no de
//  implementaciones concretas (Firestore, local, etc.).
// ─────────────────────────────────────────────────────────────────────────────

abstract interface class RegistrationDraftRepository {
  /// Guarda o reemplaza el borrador en la store de persistencia.
  Future<void> saveRegistrationDraft(RegistrationDraft draft);

  /// Devuelve el borrador para [userId] y [tournamentId], o null si no existe.
  Future<RegistrationDraft?> getRegistrationDraft(
    String userId,
    String tournamentId,
  );

  /// Elimina el borrador para [userId] y [tournamentId].
  /// No lanza excepción si el documento no existe.
  Future<void> deleteRegistrationDraft(String userId, String tournamentId);
}
