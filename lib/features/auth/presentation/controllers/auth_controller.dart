import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/auth_result.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../../user/data/models/app_user.dart';
import '../../../user/data/repositories/user_repository.dart';
import '../../../user/data/services/firestore_user_service.dart';

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
  })  : _authRepo = authRepository ?? FirebaseAuthService(),
        _userRepo = userRepository ?? FirestoreUserService();

  final AuthRepository _authRepo;
  final UserRepository _userRepo;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    return _runBool(() => _authRepo.signInWithEmail(email, password));
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
    User? createdUser;
    bool nicknameCheckedBeforeAuth = false;

    try {
      final normalizedNickname = _normalizeNickname(nickname);
      try {
        final available = await _userRepo.isNicknameAvailable(normalizedNickname);
        nicknameCheckedBeforeAuth = true;
        if (!available) {
          _errorMessage = 'Ese nickname ya esta en uso. Elige otro.';
          return false;
        }
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') {
          rethrow;
        }
      }

      final result = await _authRepo.registerWithEmail(email, password);
      if (result is AuthFailure) {
        _errorMessage = result.message;
        return false;
      }

      createdUser = FirebaseAuth.instance.currentUser;
      final uid = createdUser?.uid;
      if (uid == null) {
        _errorMessage = 'Error al obtener el usuario creado.';
        return false;
      }

      if (!nicknameCheckedBeforeAuth) {
        try {
          final available = await _userRepo.isNicknameAvailable(normalizedNickname);
          if (!available) {
            _errorMessage = 'Ese nickname ya esta en uso. Elige otro.';
            await _deleteFreshAuthUser(createdUser!);
            return false;
          }
        } on FirebaseException catch (e) {
          if (e.code == 'permission-denied') {
            // Ignorar y dejar que Firestore valide (por si las reglas de seguridad no permiten WHERE nickname)
            debugPrint('No se pudo validar nickname por reglas (ignorando para continuar)');
          } else {
            rethrow;
          }
        }
      }

      await _userRepo.createUser(
        AppUser(
          uid: uid,
          email: email.trim(),
          nickname: normalizedNickname,
          name: name.trim(),
          lastName: lastName.trim(),
          provider: 'email',
          createdAt: DateTime.now(),
        ),
      );

      return true;
    } on NicknameAlreadyInUseException {
      _errorMessage = 'Ese nickname ya esta en uso. Elige otro.';
      if (createdUser != null) {
        await _deleteFreshAuthUser(createdUser);
      }
      return false;
    } on FirebaseException catch (e) {
      _errorMessage = _firestoreErrorMessage(e.code);
      if (createdUser != null) {
        await _deleteFreshAuthUser(createdUser);
      }
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo completar el registro. Intentalo de nuevo.';
      if (createdUser != null) {
        await _deleteFreshAuthUser(createdUser);
      }
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
        final available = await _userRepo.isNicknameAvailable(normalizedNickname);
        if (!available) {
          _errorMessage = 'Ese nickname ya esta en uso. Elige otro.';
          return false;
        }
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          debugPrint('No se pudo validar nickname en completeSocialProfile por reglas (ignorando)');
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

  Future<void> _deleteFreshAuthUser(User user) async {
    try {
      await user.delete();
    } catch (_) {}
  }

  Future<bool> _safeUserExists(String uid) async {
    try {
      return await _userRepo.userExists(uid);
    } catch (_) {
      // Si el usuario ya se autenticó pero falla la lectura del perfil,
      // (por ejemplo por permission-denied), asumimos que no existe
      // para forzar al usuario a que complete su información.
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
