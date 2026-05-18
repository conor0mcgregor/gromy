import 'package:flutter/foundation.dart';

import '../../domain/models/account_deletion_state.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/services/account_deletion_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DeleteAccountController  ·  Presentación
// ─────────────────────────────────────────────────────────────────────────────

enum DeletionCheckState { idle, checking, checked, error }
enum DeletionExecuteState { idle, executing, success, error }

class DeleteAccountController extends ChangeNotifier {
  DeleteAccountController({
    required this.userId,
    AccountRepository? repository,
  }) : _repo = repository ?? AccountDeletionService();

  final String userId;
  final AccountRepository _repo;

  DeletionCheckState checkState = DeletionCheckState.idle;
  DeletionExecuteState executeState = DeletionExecuteState.idle;

  AccountDeletionState? eligibility;
  String? error;
  bool confirmationChecked = false;

  bool get canDelete =>
      eligibility != null &&
      eligibility!.canDelete &&
      confirmationChecked &&
      executeState != DeletionExecuteState.executing;

  /// Verifica si la cuenta puede eliminarse.
  Future<void> checkEligibility() async {
    checkState = DeletionCheckState.checking;
    error = null;
    notifyListeners();

    try {
      eligibility = await _repo.checkDeletionEligibility(userId);
      checkState = DeletionCheckState.checked;
    } catch (e) {
      checkState = DeletionCheckState.error;
      error = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  /// Toggle de confirmación.
  void toggleConfirmation(bool value) {
    confirmationChecked = value;
    notifyListeners();
  }

  /// Ejecuta la eliminación de cuenta.
  Future<bool> executeDelete() async {
    if (!canDelete) return false;

    executeState = DeletionExecuteState.executing;
    error = null;
    notifyListeners();

    try {
      await _repo.executeAccountDeletion(userId);
      executeState = DeletionExecuteState.success;
      notifyListeners();
      return true;
    } catch (e) {
      executeState = DeletionExecuteState.error;
      error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
