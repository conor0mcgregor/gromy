// ─────────────────────────────────────────────────────────────────────────────
//  AccountDeletionState  ·  Dominio
//
//  Resultado de la verificación de elegibilidad para eliminar cuenta.
// ─────────────────────────────────────────────────────────────────────────────

class AccountDeletionState {
  const AccountDeletionState({
    required this.userId,
    required this.canDelete,
    this.blockingReasons = const [],
    this.hasActiveTournaments = false,
    this.isSoleOrganizer = false,
    this.isTeamOwner = false,
    this.checkedAt,
  });

  final String userId;
  final bool canDelete;
  final List<String> blockingReasons;
  final bool hasActiveTournaments;
  final bool isSoleOrganizer;
  final bool isTeamOwner;
  final DateTime? checkedAt;

  bool get hasBlockingReasons => blockingReasons.isNotEmpty;
}
