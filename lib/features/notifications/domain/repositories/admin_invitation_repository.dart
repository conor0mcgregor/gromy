// ─────────────────────────────────────────────────────────────────────────────
//  AdminInvitationRepository  ·  Contrato de dominio
//
//  Define las operaciones de invitación de administrador.
//  Implementado mediante Cloud Functions para garantizar seguridad.
// ─────────────────────────────────────────────────────────────────────────────

abstract interface class AdminInvitationRepository {
  /// Envía una invitación de administrador a un usuario.
  ///
  /// [tournamentId] ID del torneo.
  /// [invitedUserId] UID del usuario invitado.
  ///
  /// Lanza [FirebaseFunctionsException] si falla la Cloud Function.
  Future<void> sendInvitation({
    required String tournamentId,
    required String invitedUserId,
  });

  /// Acepta una invitación de administrador.
  ///
  /// [notificationId] ID de la notificación de invitación.
  Future<void> acceptInvitation({required String notificationId});

  /// Rechaza una invitación de administrador.
  ///
  /// [notificationId] ID de la notificación de invitación.
  Future<void> rejectInvitation({required String notificationId});

  /// Cancela una invitación pendiente (solo creador del torneo).
  ///
  /// [notificationId] ID de la notificación de invitación.
  Future<void> cancelInvitation({required String notificationId});
}
