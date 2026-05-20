import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/account_deletion_result.dart';
import '../../data/models/account_deletion_state.dart';
import '../../domain/use_cases/delete_account_use_case.dart';

class DeleteAccountController extends ChangeNotifier {
  DeleteAccountController({DeleteAccountUseCase? useCase, FirebaseAuth? auth})
    : _useCase = useCase ?? DeleteAccountUseCase(),
      _auth = auth ?? FirebaseAuth.instance;

  final DeleteAccountUseCase _useCase;
  final FirebaseAuth _auth;

  AccountDeletionState? state;
  String? errorMessage;
  bool isLoading = false;
  bool isDeleting = false;

  Future<void> load() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      errorMessage = 'No hay una sesion activa.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      state = await _useCase.check(uid);
    } catch (_) {
      errorMessage = 'No se pudieron comprobar las restricciones.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool get requiresPassword => _useCase.requiresPasswordConfirmation();

  String? get userEmail => _useCase.currentUserEmail;

  Future<AccountDeletionResult> deleteAccount({String? password}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const AccountDeletionFailure('No hay una sesion activa.');
    }

    isDeleting = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _useCase.execute(uid, password: password);
      if (result case AccountDeletionBlocked(:final message)) {
        errorMessage = message;
        await load();
      }
      if (result case AccountDeletionFailure(:final message)) {
        errorMessage = message;
      }
      return result;
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }
}
