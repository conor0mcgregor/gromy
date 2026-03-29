import 'package:firebase_auth/firebase_auth.dart';

import '../../../features/user/data/models/app_user.dart';
import '../../../features/user/data/repositories/user_repository.dart';
import '../../../features/user/data/services/firestore_user_service.dart';
import '../models/pending_email_registration.dart';
import '../models/registration_action_result.dart';
import '../repositories/email_registration_repository.dart';
import '../repositories/pending_email_registration_store.dart';
import 'shared_preferences_pending_email_registration_store.dart';

class FirebaseEmailRegistrationService implements EmailRegistrationRepository {
  FirebaseEmailRegistrationService({
    FirebaseAuth? auth,
    UserRepository? userRepository,
    PendingEmailRegistrationStore? pendingRegistrationStore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _userRepository = userRepository ?? FirestoreUserService(),
        _pendingRegistrationStore = pendingRegistrationStore ??
            SharedPreferencesPendingEmailRegistrationStore();

  final FirebaseAuth _auth;
  final UserRepository _userRepository;
  final PendingEmailRegistrationStore _pendingRegistrationStore;

  @override
  Future<RegistrationActionResult> startRegistration({
    required String email,
    required String password,
    required String nickname,
    required String name,
    required String lastName,
  }) async {
    User? createdUser;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      createdUser = credential.user;
      if (createdUser == null) {
        return const RegistrationActionFailure(
          'No se pudo crear la cuenta. Intentalo de nuevo.',
        );
      }

      await createdUser.sendEmailVerification();
      await _pendingRegistrationStore.save(
        PendingEmailRegistration(
          uid: createdUser.uid,
          email: email.trim(),
          nickname: nickname.trim().toLowerCase(),
          name: name.trim(),
          lastName: lastName.trim(),
          createdAt: DateTime.now(),
        ),
      );

      return const RegistrationActionSuccess();
    } on FirebaseAuthException catch (e) {
      if (createdUser != null) {
        await _deleteFreshUser(createdUser);
      }
      return RegistrationActionFailure(_authErrorMessage(e.code));
    } catch (_) {
      if (createdUser != null) {
        await _deleteFreshUser(createdUser);
      }
      return const RegistrationActionFailure(
        'No se pudo preparar la verificacion del correo. Intentalo de nuevo.',
      );
    }
  }

  @override
  Future<RegistrationActionResult> completeRegistration() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const RegistrationActionFailure(
        'Tu sesion ha caducado. Inicia sesion de nuevo.',
      );
    }

    try {
      await currentUser.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null) {
        return const RegistrationActionFailure(
          'No se pudo actualizar el estado del usuario.',
        );
      }

      if (!refreshedUser.emailVerified) {
        return const RegistrationActionFailure(
          'Tu correo aun no esta verificado. Revisa tu bandeja de entrada.',
        );
      }

      final pendingRegistration = await _pendingRegistrationStore.getByUid(
        refreshedUser.uid,
      );
      if (pendingRegistration == null) {
        return const RegistrationActionFailure(
          'No encontramos tus datos pendientes en este dispositivo.',
        );
      }

      final isNicknameAvailable = await _userRepository.isNicknameAvailable(
        pendingRegistration.nickname,
      );
      if (!isNicknameAvailable) {
        return const RegistrationActionFailure(
          'Ese nickname ya esta en uso. Elige otro.',
        );
      }

      await _userRepository.createUser(
        AppUser(
          uid: refreshedUser.uid,
          email: pendingRegistration.email,
          nickname: pendingRegistration.nickname,
          name: pendingRegistration.name,
          lastName: pendingRegistration.lastName,
          provider: 'email',
          createdAt: DateTime.now(),
        ),
      );

      try {
        await _pendingRegistrationStore.deleteByUid(refreshedUser.uid);
      } catch (_) {}

      return const RegistrationActionSuccess();
    } on FirebaseAuthException catch (e) {
      return RegistrationActionFailure(_authErrorMessage(e.code));
    } on NicknameAlreadyInUseException {
      return const RegistrationActionFailure(
        'Ese nickname ya esta en uso. Elige otro.',
      );
    } catch (_) {
      return const RegistrationActionFailure(
        'No se pudo completar el registro. Intentalo de nuevo.',
      );
    }
  }

  @override
  Future<RegistrationActionResult> resendVerificationEmail() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const RegistrationActionFailure(
        'No hay ninguna cuenta pendiente de verificacion.',
      );
    }

    try {
      await currentUser.sendEmailVerification();
      return const RegistrationActionSuccess();
    } on FirebaseAuthException catch (e) {
      return RegistrationActionFailure(_authErrorMessage(e.code));
    } catch (_) {
      return const RegistrationActionFailure(
        'No se pudo reenviar el correo de verificacion.',
      );
    }
  }

  @override
  Future<PendingEmailRegistration?> getPendingRegistrationForCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    return _pendingRegistrationStore.getByUid(currentUser.uid);
  }

  @override
  Future<void> clearPendingRegistration() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }

    await _pendingRegistrationStore.deleteByUid(currentUser.uid);
  }

  Future<void> _deleteFreshUser(User user) async {
    try {
      await user.delete();
    } catch (_) {}
  }

  String _authErrorMessage(String code) {
    return switch (code) {
      'email-already-in-use' => 'Ese correo ya esta registrado.',
      'invalid-email' => 'El correo electronico no es valido.',
      'weak-password' => 'La contrasena es demasiado debil (minimo 6 caracteres).',
      'too-many-requests' => 'Demasiados intentos. Espera un momento.',
      'network-request-failed' => 'Sin conexion a internet.',
      _ => 'Error de autenticacion ($code).',
    };
  }
}
