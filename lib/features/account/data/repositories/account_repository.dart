import '../../domain/models/account_deletion_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AccountRepository  ·  Contrato de dominio
// ─────────────────────────────────────────────────────────────────────────────

abstract interface class AccountRepository {
  /// Verifica si la cuenta puede eliminarse y devuelve los motivos de bloqueo.
  Future<AccountDeletionState> checkDeletionEligibility(String userId);

  /// Ejecuta la eliminación/desactivación de la cuenta.
  /// Coordina Auth, Firestore y Storage.
  Future<void> executeAccountDeletion(String userId);
}
