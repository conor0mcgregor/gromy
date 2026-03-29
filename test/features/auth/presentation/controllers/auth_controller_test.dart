import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gromy/database/registration/models/registration_action_result.dart';
import 'package:gromy/features/auth/data/models/auth_result.dart';
import 'package:gromy/features/auth/presentation/controllers/auth_controller.dart';
import 'package:gromy/features/user/data/repositories/user_repository.dart';

import '../../../../support/test_doubles.dart';

void main() {
  AuthController buildController({
    FakeAuthRepository? authRepository,
    FakeUserRepository? userRepository,
    FakeEmailRegistrationRepository? emailRegistrationRepository,
    FakeAppAccessResolver? appAccessResolver,
  }) {
    return AuthController(
      authRepository: authRepository ?? FakeAuthRepository(),
      userRepository: userRepository ?? FakeUserRepository(),
      emailRegistrationRepository:
          emailRegistrationRepository ?? FakeEmailRegistrationRepository(),
      appAccessResolver: appAccessResolver ?? FakeAppAccessResolver(),
    );
  }

  group('AuthController', () {
    test(
      'login returns true when the repository authenticates successfully',
      () async {
        final authRepo = FakeAuthRepository(
          onSignInWithEmail: (email, password) async => AuthSuccess(),
        );
        final controller = buildController(authRepository: authRepo);
        addTearDown(controller.dispose);

        var notifications = 0;
        controller.addListener(() {
          notifications++;
        });

        final result = await controller.login('ana@example.com', 'secret123');

        expect(result, isTrue);
        expect(controller.errorMessage, isNull);
        expect(controller.isLoading, isFalse);
        expect(authRepo.signInWithEmailCalls, 1);
        expect(authRepo.lastEmail, 'ana@example.com');
        expect(authRepo.lastPassword, 'secret123');
        expect(notifications, 2);
      },
    );

    test('login exposes the repository failure message', () async {
      final controller = buildController(
        authRepository: FakeAuthRepository(
          onSignInWithEmail: (email, password) async =>
              AuthFailure('Credenciales invalidas'),
        ),
      );
      addTearDown(controller.dispose);

      final result = await controller.login('ana@example.com', 'bad-pass');

      expect(result, isFalse);
      expect(controller.errorMessage, 'Credenciales invalidas');
      expect(controller.isLoading, isFalse);
    });

    test(
      'login returns a generic message when the repository throws',
      () async {
        final controller = buildController(
          authRepository: FakeAuthRepository(
            onSignInWithEmail: (email, password) {
              throw StateError('unexpected failure');
            },
          ),
        );
        addTearDown(controller.dispose);

        final result = await controller.login('ana@example.com', 'secret123');

        expect(result, isFalse);
        expect(
          controller.errorMessage,
          'No se pudo iniciar sesion. Intentalo de nuevo.',
        );
      },
    );

    test(
      'register stops before auth when the nickname is already taken',
      () async {
        final authRepo = FakeAuthRepository();
        final userRepo = FakeUserRepository(
          onIsNicknameAvailable: (nickname) async => false,
        );
        final emailRepo = FakeEmailRegistrationRepository();
        final controller = buildController(
          authRepository: authRepo,
          userRepository: userRepo,
          emailRegistrationRepository: emailRepo,
        );
        addTearDown(controller.dispose);

        final result = await controller.register(
          email: 'ana@example.com',
          password: 'secret123',
          nickname: 'Anita',
          name: 'Ana',
          lastName: 'Lopez',
        );

        expect(result, isFalse);
        expect(
          controller.errorMessage,
          'Ese nickname ya esta en uso. Elige otro.',
        );
        expect(userRepo.lastNicknameChecked, 'anita');
        expect(authRepo.registerWithEmailCalls, 0);
        expect(emailRepo.startRegistrationCalls, 0);
        expect(userRepo.createUserCalls, 0);
      },
    );

    test(
      'register stores the pending email flow and skips Firestore user creation',
      () async {
        final userRepo = FakeUserRepository(
          onIsNicknameAvailable: (nickname) async => true,
        );
        final emailRepo = FakeEmailRegistrationRepository();
        final controller = buildController(
          userRepository: userRepo,
          emailRegistrationRepository: emailRepo,
        );
        addTearDown(controller.dispose);

        final result = await controller.register(
          email: '  ana@example.com  ',
          password: 'secret123',
          nickname: '  AnaPro  ',
          name: '  Ana  ',
          lastName: '  Lopez  ',
        );

        expect(result, isTrue);
        expect(controller.errorMessage, isNull);
        expect(emailRepo.startRegistrationCalls, 1);
        expect(emailRepo.lastRegistrationEmail, '  ana@example.com  ');
        expect(emailRepo.lastRegistrationNickname, 'anapro');
        expect(emailRepo.lastRegistrationName, '  Ana  ');
        expect(emailRepo.lastRegistrationLastName, '  Lopez  ');
        expect(userRepo.createUserCalls, 0);
      },
    );

    test(
      'completePendingEmailRegistration exposes repository failures',
      () async {
        final controller = buildController(
          emailRegistrationRepository: FakeEmailRegistrationRepository(
            onCompleteRegistration: () async =>
                const RegistrationActionFailure('Correo no verificado'),
          ),
        );
        addTearDown(controller.dispose);

        final result = await controller.completePendingEmailRegistration();

        expect(result, isFalse);
        expect(controller.errorMessage, 'Correo no verificado');
      },
    );

    test('resendVerificationEmail reports repository failures', () async {
      final controller = buildController(
        emailRegistrationRepository: FakeEmailRegistrationRepository(
          onResendVerificationEmail: () async =>
              const RegistrationActionFailure('No se pudo reenviar'),
        ),
      );
      addTearDown(controller.dispose);

      final result = await controller.resendVerificationEmail();

      expect(result, isFalse);
      expect(controller.errorMessage, 'No se pudo reenviar');
    });

    test(
      'completeSocialProfile normalizes nickname and trims user data',
      () async {
        final userRepo = FakeUserRepository(
          onIsNicknameAvailable: (nickname) async => true,
        );
        final controller = buildController(userRepository: userRepo);
        addTearDown(controller.dispose);

        final result = await controller.completeSocialProfile(
          uid: 'uid-123',
          email: '  ana@example.com  ',
          nickname: '  AnaPRO  ',
          name: '  Ana  ',
          lastName: '  Lopez  ',
          provider: 'google',
          photoUrl: 'https://example.com/photo.png',
        );

        expect(result, isTrue);
        expect(controller.errorMessage, isNull);
        expect(userRepo.lastNicknameChecked, 'anapro');
        expect(userRepo.createUserCalls, 1);
        expect(userRepo.lastCreatedUser?.uid, 'uid-123');
        expect(userRepo.lastCreatedUser?.email, 'ana@example.com');
        expect(userRepo.lastCreatedUser?.nickname, 'anapro');
        expect(userRepo.lastCreatedUser?.name, 'Ana');
        expect(userRepo.lastCreatedUser?.lastName, 'Lopez');
        expect(userRepo.lastCreatedUser?.provider, 'google');
        expect(
          userRepo.lastCreatedUser?.photoUrl,
          'https://example.com/photo.png',
        );
      },
    );

    test('completeSocialProfile reports nickname conflicts', () async {
      final controller = buildController(
        userRepository: FakeUserRepository(
          onIsNicknameAvailable: (nickname) async => false,
        ),
      );
      addTearDown(controller.dispose);

      final result = await controller.completeSocialProfile(
        uid: 'uid-123',
        email: 'ana@example.com',
        nickname: 'AnaPro',
        name: 'Ana',
        lastName: 'Lopez',
        provider: 'google',
      );

      expect(result, isFalse);
      expect(
        controller.errorMessage,
        'Ese nickname ya esta en uso. Elige otro.',
      );
    });

    test('completeSocialProfile maps Firestore permission errors', () async {
      final controller = buildController(
        userRepository: FakeUserRepository(
          onIsNicknameAvailable: (nickname) async => true,
          onCreateUser: (user) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
            );
          },
        ),
      );
      addTearDown(controller.dispose);

      final result = await controller.completeSocialProfile(
        uid: 'uid-123',
        email: 'ana@example.com',
        nickname: 'AnaPro',
        name: 'Ana',
        lastName: 'Lopez',
        provider: 'google',
      );

      expect(result, isFalse);
      expect(
        controller.errorMessage,
        'Firestore rechazo la operacion. Revisa las reglas de seguridad.',
      );
    });

    test(
      'completeSocialProfile handles repository uniqueness exceptions',
      () async {
        final controller = buildController(
          userRepository: FakeUserRepository(
            onIsNicknameAvailable: (nickname) async => true,
            onCreateUser: (user) {
              throw const NicknameAlreadyInUseException();
            },
          ),
        );
        addTearDown(controller.dispose);

        final result = await controller.completeSocialProfile(
          uid: 'uid-123',
          email: 'ana@example.com',
          nickname: 'AnaPro',
          name: 'Ana',
          lastName: 'Lopez',
          provider: 'google',
        );

        expect(result, isFalse);
        expect(
          controller.errorMessage,
          'Ese nickname ya esta en uso. Elige otro.',
        );
      },
    );

    test(
      'loginWithGoogle returns a social failure when the repository fails',
      () async {
        final controller = buildController(
          authRepository: FakeAuthRepository(
            onSignInWithGoogle: () async => AuthFailure('Google cancelado'),
          ),
        );
        addTearDown(controller.dispose);

        final result = await controller.loginWithGoogle();

        expect(result, isA<SocialAuthFailure>());
        expect(controller.errorMessage, 'Google cancelado');
        expect((result as SocialAuthFailure).message, 'Google cancelado');
      },
    );

    test(
      'loginWithApple returns a generic social error when the repository throws',
      () async {
        final controller = buildController(
          authRepository: FakeAuthRepository(
            onSignInWithApple: () {
              throw StateError('unexpected');
            },
          ),
        );
        addTearDown(controller.dispose);

        final result = await controller.loginWithApple();

        expect(result, isA<SocialAuthFailure>());
        expect(
          controller.errorMessage,
          'No se pudo completar el inicio de sesion social.',
        );
        expect(
          (result as SocialAuthFailure).message,
          'No se pudo completar el inicio de sesion social.',
        );
      },
    );
  });
}
