import 'package:firebase_auth/firebase_auth.dart';

import '../models/account_deletion_result.dart';
import '../models/account_deletion_state.dart';
import '../repositories/account_repository.dart';
import 'firebase_account_service.dart';

class AccountService {
  AccountService({AccountRepository? repository})
    : _repository = repository ?? FirebaseAccountService();

  final AccountRepository _repository;

  Future<AccountDeletionState> getDeletionState(String userId) {
    return _repository.getDeletionState(userId);
  }

  Future<AccountDeletionResult> deleteAccount(String userId) async {
    try {
      final state = await _repository.getDeletionState(userId);
      if (!state.canDelete) {
        return const AccountDeletionBlocked(
          'No puedes eliminar la cuenta todavia. Revisa los motivos indicados.',
        );
      }

      await _repository.removePersonalStorage(userId);
      await _repository.anonymizeUserAccount(userId);
      await _repository.revokeAuthAccess();
      return const AccountDeletionSuccess();
    } on FirebaseAuthException catch (e) {
      return AccountDeletionFailure(_authMessage(e.code));
    } on FirebaseException catch (e) {
      return AccountDeletionFailure(_firebaseMessage(e.code));
    } catch (_) {
      return const AccountDeletionFailure(
        'No se pudo eliminar la cuenta. Intentalo de nuevo.',
      );
    }
  }

  String _authMessage(String code) {
    return switch (code) {
      'requires-recent-login' =>
        'Firebase requiere una reautenticacion reciente para continuar.',
      'network-request-failed' => 'Sin conexion a internet.',
      _ => 'No se pudo revocar el acceso de la cuenta.',
    };
  }

  String _firebaseMessage(String code) {
    return switch (code) {
      'permission-denied' =>
        'No tienes permisos para completar la eliminacion de la cuenta.',
      'unavailable' =>
        'Firebase no esta disponible ahora mismo. Intentalo de nuevo.',
      _ => 'No se pudo completar la baja de la cuenta.',
    };
  }
}
