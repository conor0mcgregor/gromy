import '../../data/models/account_deletion_result.dart';
import '../../data/models/account_deletion_state.dart';
import '../../data/services/account_service.dart';

class DeleteAccountUseCase {
  DeleteAccountUseCase({AccountService? service})
    : _service = service ?? AccountService();

  final AccountService _service;

  Future<AccountDeletionState> check(String userId) {
    return _service.getDeletionState(userId);
  }

  Future<AccountDeletionResult> execute(
    String userId, {
    String? password,
  }) {
    return _service.deleteAccount(userId: userId, password: password);
  }

  bool requiresPasswordConfirmation() {
    return _service.requiresPasswordConfirmation();
  }

  String? get currentUserEmail => _service.currentUserEmail;
}
