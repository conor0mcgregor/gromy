sealed class AccountDeletionResult {
  const AccountDeletionResult();
}

final class AccountDeletionSuccess extends AccountDeletionResult {
  const AccountDeletionSuccess();
}

final class AccountDeletionBlocked extends AccountDeletionResult {
  const AccountDeletionBlocked(this.message);

  final String message;
}

final class AccountDeletionFailure extends AccountDeletionResult {
  const AccountDeletionFailure(this.message);

  final String message;
}
