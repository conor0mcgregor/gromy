import 'package:flutter_test/flutter_test.dart';
import 'package:gromy/features/auth/data/models/auth_result.dart';
import 'package:gromy/features/auth/presentation/controllers/auth_controller.dart';

import '../../../../support/test_doubles.dart';

void main() {
  AuthController buildController({
    FakeAuthRepository? authRepository,
  }) {
    return AuthController(
      authRepository: authRepository ?? FakeAuthRepository(),
      userRepository: FakeUserRepository(),
      emailRegistrationRepository: FakeEmailRegistrationRepository(),
      appAccessResolver: FakeAppAccessResolver(),
    );
  }

  group('AuthController.sendPasswordResetEmail', () {
    test(
      'returns true and calls the repository once with the trimmed email',
      () async {
        final authRepo = FakeAuthRepository();
        final controller = buildController(authRepository: authRepo);
        addTearDown(controller.dispose);

        final result =
            await controller.sendPasswordResetEmail('  ana@example.com  ');

        expect(result, isTrue);
        expect(authRepo.sendPasswordResetEmailCalls, 1);
        expect(authRepo.lastPasswordResetEmail, 'ana@example.com');
      },
    );

    test(
      'always returns true even when the repository would expose a failure',
      () async {
        // Simula un repositorio que lanza internamente (e.g. error de red).
        // El controlador debe absorber el error y devolver true igualmente.
        final authRepo = FakeAuthRepository(
          onSendPasswordResetEmail: (email) async {
            throw StateError('network failure');
          },
        );
        final controller = buildController(authRepository: authRepo);
        addTearDown(controller.dispose);

        final result = await controller.sendPasswordResetEmail('x@example.com');

        expect(result, isTrue);
        expect(controller.errorMessage, isNull);
      },
    );

    test('isLoading transitions from true to false around the call', () async {
      final loadingStates = <bool>[];

      final controller = buildController();
      addTearDown(controller.dispose);

      controller.addListener(() {
        loadingStates.add(controller.isLoading);
      });

      await controller.sendPasswordResetEmail('ana@example.com');

      // First notification: isLoading = true (set before call)
      // Second notification: isLoading = false (set in finally)
      expect(loadingStates, [true, false]);
    });

    test('notifyListeners fires exactly twice', () async {
      final controller = buildController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.sendPasswordResetEmail('ana@example.com');

      expect(notifications, 2);
    });

    test('does not set errorMessage after a successful call', () async {
      final controller = buildController();
      addTearDown(controller.dispose);

      await controller.sendPasswordResetEmail('ana@example.com');

      expect(controller.errorMessage, isNull);
    });

    test('returns true for an empty string (validation is the screen concern)',
        () async {
      // La validación del formato es responsabilidad de la pantalla.
      // El controlador delega al repositorio sin validar.
      final authRepo = FakeAuthRepository();
      final controller = buildController(authRepository: authRepo);
      addTearDown(controller.dispose);

      final result = await controller.sendPasswordResetEmail('');

      expect(result, isTrue);
      expect(authRepo.sendPasswordResetEmailCalls, 1);
    });

    test(
      'returns true for a non-existing email '
      '(security: no account enumeration)',
      () async {
        // El servicio real de Firebase lanzaría user-not-found, pero el
        // FirebaseAuthService lo silencia. Aquí verificamos que si el fake
        // devuelve AuthSuccess, el controlador también devuelve true.
        final authRepo = FakeAuthRepository(
          onSendPasswordResetEmail: (_) async => AuthSuccess(),
        );
        final controller = buildController(authRepository: authRepo);
        addTearDown(controller.dispose);

        final result =
            await controller.sendPasswordResetEmail('noexiste@example.com');

        expect(result, isTrue);
      },
    );
  });
}
