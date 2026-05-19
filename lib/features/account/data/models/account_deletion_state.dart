enum AccountDeletionBlockingCode {
  soleTournamentOrganizer,
  soleTeamOwner,
  activePayments,
  criticalProcesses,
  unauthenticated,
}

class AccountDeletionBlockingReason {
  const AccountDeletionBlockingReason({
    required this.code,
    required this.message,
    required this.action,
  });

  final AccountDeletionBlockingCode code;
  final String message;
  final String action;
}

class AccountDeletionState {
  const AccountDeletionState({
    required this.userId,
    required this.canDelete,
    required this.blockingReasons,
    required this.hasActiveTournaments,
    required this.hasActivePayments,
    required this.isSoleOrganizer,
    required this.isTeamOwner,
    required this.checkedAt,
  });

  final String userId;
  final bool canDelete;
  final List<AccountDeletionBlockingReason> blockingReasons;
  final bool hasActiveTournaments;
  final bool hasActivePayments;
  final bool isSoleOrganizer;
  final bool isTeamOwner;
  final DateTime checkedAt;

  factory AccountDeletionState.allowed(String userId) {
    return AccountDeletionState(
      userId: userId,
      canDelete: true,
      blockingReasons: const [],
      hasActiveTournaments: false,
      hasActivePayments: false,
      isSoleOrganizer: false,
      isTeamOwner: false,
      checkedAt: DateTime.now(),
    );
  }
}
