import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/account_deletion_result.dart';
import '../models/account_deletion_state.dart';
import '../repositories/account_repository.dart';
import 'account_reauth_service.dart';
import 'cloud_function_account_service.dart';
import 'firebase_account_service.dart';

class AccountService {
  AccountService({
    AccountRepository? repository,
    CloudFunctionAccountService? cloudFunctions,
    AccountReauthService? reauthService,
    FirebaseAuth? auth,
  }) : _repository = repository ?? FirebaseAccountService(),
       _cloudFunctions = cloudFunctions ?? CloudFunctionAccountService(),
       _reauthService = reauthService ?? AccountReauthService(),
       _auth = auth ?? FirebaseAuth.instance;

  final AccountRepository _repository;
  final CloudFunctionAccountService _cloudFunctions;
  final AccountReauthService _reauthService;
  final FirebaseAuth _auth;

  Future<AccountDeletionState> getDeletionState(String userId) {
    return _repository.getDeletionState(userId);
  }

  Future<AccountDeletionResult> deleteAccount({
    required String userId,
    String? password,
  }) async {
    try {
      final state = await _repository.getDeletionState(userId);
      if (!state.canDelete) {
        return const AccountDeletionBlocked(
          'No puedes eliminar la cuenta todavia. Revisa los motivos indicados.',
        );
      }

      final reauthError = await _reauthenticate(password: password);
      if (reauthError != null) {
        return AccountDeletionFailure(reauthError);
      }

      await _cloudFunctions.deleteUserAccount();
      await _repository.revokeAuthAccess();
      return const AccountDeletionSuccess();
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') {
        return AccountDeletionBlocked(
          e.message ?? 'No puedes eliminar la cuenta en este momento.',
        );
      }
      return AccountDeletionFailure(_functionsMessage(e));
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

  Future<String?> _reauthenticate({String? password}) async {
    final provider = _reauthService.primaryProviderId();
    return switch (provider) {
      'google.com' => _reauthService.reauthenticateWithGoogle(),
      'apple.com' => _reauthService.reauthenticateWithApple(),
      _ => () async {
        if (password == null || password.isEmpty) {
          return 'Debes confirmar tu contrasena para eliminar la cuenta.';
        }
        return _reauthService.reauthenticateWithPassword(password);
      }(),
    };
  }

  bool requiresPasswordConfirmation() {
    return _reauthService.primaryProviderId() == 'password';
  }

  String? get currentUserEmail => _auth.currentUser?.email;

  String _authMessage(String code) {
    return switch (code) {
      'requires-recent-login' =>
        'Por seguridad, vuelve a confirmar tu identidad e intentalo de nuevo.',
      'network-request-failed' => 'Sin conexion a internet.',
      _ => 'No se pudo verificar tu identidad.',
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

  String _functionsMessage(FirebaseFunctionsException e) {
    return switch (e.code) {
      'unauthenticated' => 'Debes iniciar sesion para eliminar tu cuenta.',
      'permission-denied' => 'No tienes permisos para eliminar la cuenta.',
      'unavailable' => 'El servicio no esta disponible. Intentalo mas tarde.',
      'deadline-exceeded' => 'La operacion tardo demasiado. Intentalo de nuevo.',
      _ => e.message ?? 'No se pudo eliminar la cuenta.',
    };
  }
}
