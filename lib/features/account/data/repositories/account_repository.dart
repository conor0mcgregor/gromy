import '../models/account_deletion_state.dart';

abstract interface class AccountRepository {
  Future<AccountDeletionState> getDeletionState(String userId);

  Future<void> deleteAccountPermanently(String userId);

  Future<void> revokeAuthAccess();
}
