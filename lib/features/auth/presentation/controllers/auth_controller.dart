import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../database/registration/models/registration_action_result.dart';
import '../../../../database/registration/repositories/email_registration_repository.dart';
import '../../../../database/registration/services/firebase_email_registration_service.dart';
import '../../../../database/session/models/app_access_state.dart';
import '../../../../database/session/repositories/app_access_resolver.dart';
import '../../../../database/session/services/firebase_app_access_resolver.dart';
import '../../../user/data/models/app_user.dart';
import '../../../user/data/repositories/user_repository.dart';
import '../../../user/data/services/firestore_user_service.dart';
import '../../data/models/auth_result.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/firebase_auth_service.dart';

sealed class SocialAuthResult {}

final class SocialAuthExisting extends SocialAuthResult {}

final class SocialAuthNewUser extends SocialAuthResult {
  SocialAuthNewUser({
    required this.uid,
    required this.email,
    required this.photoUrl,
    required this.provider,
  });

  final String uid;
  final String email;
  final String? photoUrl;
  final String provider;
}

final class SocialAuthFailure extends SocialAuthResult {
  SocialAuthFailure(this.message);

  final String message;
}

class AuthController extends ChangeNotifier {
  AuthController({
    AuthRepository? authRepository,
    UserRepository? userRepository,
    EmailRegistrationRepository? emailRegistrationRepository,
    AppAccessResolver? appAccessResolver,
  }) : this._(
          authRepository: authRepository ?? FirebaseAuthService(),
          userRepository: userRepository ?? FirestoreUserService(),
          emailRegistrationRepository: emailRegistrationRepository,
          appAccessResolver: appAccessResolver,
        );

  AuthController._({
    required AuthRepository authRepository,
    required UserRepository userRepository,
    EmailRegistrationRepository? emailRegistrationRepository,
    AppAccessResolver? appAccessResolver,
  })  : _authRepo = authRepository,
        _userRepo = userRepository,
        _emailRegistrationRepo = emailRegistrationRepository ??
            FirebaseEmailRegistrationService(userRepository: userRepository),
        _appAccessResolver = appAccessResolver ??
            FirebaseAppAccessResolver(userRepository: userRepository);

  final AuthRepository _authRepo;
  final UserRepository _userRepo;
  final EmailRegistrationRepository _emailRegistrationRepo;
  final AppAccessResolver _appAccessResolver;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<AppAccessState> resolveCurrentAccessState() {
    return _appAccessResolver.resolve();
  }

  Future<bool> login(String email, String password) async {
    return _runBool(() => _authRepo.signInWithEmail(email, password));
  }

  Future<bool> isValidNickName(String nickname) async {
    if (nickname.isEmpty) return false;
    return _userRepo.isNicknameAvailable(nickname);
  }

  Future<bool> register({
    required String email,
    required String password,
    required String nickname,
    required String name,
    required String lastName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final normalizedNickname = _normalizeNickname(nickname);
      try {
        final available = await isValidNickName(normalizedNickname);
        if (!available) {
          _errorMessage = 'Ese nickname ya esta en uso. Elige otro.';
          return false;
        }
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') {
          rethrow;
        }
      }

      final result = await _emailRegistrationRepo.startRegistration(
        email: email,
        password: password,
        nickname: normalizedNickname,
        name: name,
        lastName: lastName,
      );

      switch (result) {
        case RegistrationActionSuccess():
          return true;
        case RegistrationActionFailure(:final message):
          _errorMessage = message;
          return false;
      }
    } on FirebaseException catch (e) {
      _errorMessage = _firestoreErrorMessage(e.code);
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo completar el registro. Intentalo de nuevo.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> completePendingEmailRegistration() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _emailRegistrationRepo.completeRegistration();
      switch (result) {
        case RegistrationActionSuccess():
          return true;
        case RegistrationActionFailure(:final message):
          _errorMessage = message;
          return false;
      }
    } on FirebaseException catch (e) {
      _errorMessage = _firestoreErrorMessage(e.code);
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo completar el registro. Intentalo de nuevo.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resendVerificationEmail() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _emailRegistrationRepo.resendVerificationEmail();
      switch (result) {
        case RegistrationActionSuccess():
          return true;
        case RegistrationActionFailure(:final message):
          _errorMessage = message;
          return false;
      }
    } catch (_) {
      _errorMessage = 'No se pudo reenviar el correo de verificacion.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<SocialAuthResult> loginWithGoogle() async {
    return _runSocial(
      () => _authRepo.signInWithGoogle(),
      provider: 'google',
    );
  }

  Future<SocialAuthResult> loginWithApple() async {
    return _runSocial(
      () => _authRepo.signInWithApple(),
      provider: 'apple',
    );
  }

  Future<bool> completeSocialProfile({
    required String uid,
    required String email,
    required String nickname,
    required String name,
    required String lastName,
    required String provider,
    String? photoUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final normalizedNickname = _normalizeNickname(nickname);
      try {
        final available = await isValidNickName(normalizedNickname);
        if (!available) {
          _errorMessage = 'Ese nickname ya esta en uso. Elige otro.';
          return false;
        }
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          debugPrint(
            'No se pudo validar nickname en completeSocialProfile por reglas (ignorando)',
          );
        } else {
          rethrow;
        }
      }

      await _userRepo.createUser(
        AppUser(
          uid: uid,
          email: email.trim(),
          nickname: normalizedNickname,
          name: name.trim(),
          lastName: lastName.trim(),
          provider: provider,
          createdAt: DateTime.now(),
          photoUrl: photoUrl,
        ),
      );

      return true;
    } on NicknameAlreadyInUseException {
      _errorMessage = 'Ese nickname ya esta en uso. Elige otro.';
      return false;
    } on FirebaseException catch (e) {
      _errorMessage = _firestoreErrorMessage(e.code);
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo guardar el perfil. Intentalo de nuevo.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() => _authRepo.signOut();

  Future<bool> _runBool(Future<AuthResult> Function() op) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await op();
      switch (result) {
        case AuthSuccess():
          return true;
        case AuthFailure(:final message):
          _errorMessage = message;
          return false;
      }
    } catch (_) {
      _errorMessage = 'No se pudo iniciar sesion. Intentalo de nuevo.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<SocialAuthResult> _runSocial(
    Future<AuthResult> Function() op, {
    required String provider,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await op();
      switch (result) {
        case AuthFailure(:final message):
          _errorMessage = message;
          return SocialAuthFailure(message);
        case AuthSuccess(:final isNewUser):
          final firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser == null) {
            return SocialAuthFailure('Error al obtener el usuario.');
          }

          if (isNewUser) {
            return SocialAuthNewUser(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              photoUrl: firebaseUser.photoURL,
              provider: provider,
            );
          }

          final existsInFirestore = await _safeUserExists(firebaseUser.uid);
          if (existsInFirestore) {
            return SocialAuthExisting();
          }

          return SocialAuthNewUser(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            photoUrl: firebaseUser.photoURL,
            provider: provider,
          );
      }
    } catch (_) {
      const message = 'No se pudo completar el inicio de sesion social.';
      _errorMessage = message;
      return SocialAuthFailure(message);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _safeUserExists(String uid) async {
    try {
      return await _userRepo.userExists(uid);
    } catch (_) {
      return false;
    }
  }

  String _normalizeNickname(String nickname) => nickname.trim().toLowerCase();

  String _firestoreErrorMessage(String code) {
    return switch (code) {
      'permission-denied' =>
        'Firestore rechazo la operacion. Revisa las reglas de seguridad.',
      'unavailable' =>
        'Firestore no esta disponible ahora mismo. Intentalo de nuevo.',
      'failed-precondition' =>
        'Firestore no esta listo todavia para esta operacion.',
      _ => 'No se pudo guardar el perfil del usuario.',
    };
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
