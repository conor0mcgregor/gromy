import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gromy/features/auth/presentation/controllers/auth_controller.dart';
import 'package:gromy/features/auth/presentation/screens/register_dates_screen.dart';
import 'package:gromy/features/home/presentation/screens/home_screen.dart';
import 'package:gromy/features/user/data/repositories/user_repository.dart';

import '../../../../support/test_doubles.dart';

void main() {
  Widget buildTestApp(AuthController controller) {
    return MaterialApp(
      home: RegisterDatesScreen(
        uid: 'uid-123',
        email: 'ana@example.com',
        provider: 'google',
        authController: controller,
        successBuilder: (_) => const HomeScreen(),
      ),
    );
  }

  group('RegisterDatesScreen', () {
    testWidgets('validates empty required fields locally', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final userRepo = FakeUserRepository();
      final controller = AuthController(
        authRepository: FakeAuthRepository(),
        userRepository: userRepo,
        emailRegistrationRepository: FakeEmailRegistrationRepository(),
        appAccessResolver: FakeAppAccessResolver(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(buildTestApp(controller));
      await tester.ensureVisible(find.text('Guardar y continuar'));
      await tester.tap(find.text('Guardar y continuar'));
      await tester.pump();

      expect(
        find.textContaining('Introduce un nombre de usuario'),
        findsOneWidget,
      );
      expect(find.textContaining('Introduce tu nombre'), findsOneWidget);
      expect(find.textContaining('Introduce tu apellido'), findsOneWidget);
      expect(userRepo.createUserCalls, 0);
    });

    testWidgets('navigates to the app shell after saving a valid profile', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = AuthController(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(
          onIsNicknameAvailable: (nickname) async => true,
        ),
        emailRegistrationRepository: FakeEmailRegistrationRepository(),
        appAccessResolver: FakeAppAccessResolver(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(buildTestApp(controller));

      await tester.enterText(find.byType(TextField).at(0), 'PlayerOne');
      await tester.enterText(find.byType(TextField).at(1), 'Ana');
      await tester.enterText(find.byType(TextField).at(2), 'Lopez');
      await tester.ensureVisible(find.text('Guardar y continuar'));
      await tester.tap(find.text('Guardar y continuar'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('shows the nickname error returned by the controller', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = AuthController(
        authRepository: FakeAuthRepository(),
        userRepository: FakeUserRepository(
          onIsNicknameAvailable: (nickname) async => true,
          onCreateUser: (user) {
            throw const NicknameAlreadyInUseException();
          },
        ),
        emailRegistrationRepository: FakeEmailRegistrationRepository(),
        appAccessResolver: FakeAppAccessResolver(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(buildTestApp(controller));

      await tester.enterText(find.byType(TextField).at(0), 'PlayerOne');
      await tester.enterText(find.byType(TextField).at(1), 'Ana');
      await tester.enterText(find.byType(TextField).at(2), 'Lopez');
      await tester.ensureVisible(find.text('Guardar y continuar'));
      await tester.tap(find.text('Guardar y continuar'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Ese nickname ya esta en uso'),
        findsOneWidget,
      );
    });
  });
}
