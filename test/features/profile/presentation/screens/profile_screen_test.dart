import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gromy/features/auth/presentation/controllers/auth_controller.dart';
import 'package:gromy/features/profile/presentation/screens/profile_screen.dart';

import '../../../../support/test_doubles.dart';

void main() {
  Widget buildTestApp(AuthController controller) {
    return MaterialApp(
      home: Scaffold(
        body: ProfileScreen(authController: controller),
      ),
    );
  }

  testWidgets('logout delegates to the injected auth controller', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository();
    final controller = AuthController(
      authRepository: authRepository,
      userRepository: FakeUserRepository(),
      emailRegistrationRepository: FakeEmailRegistrationRepository(),
      appAccessResolver: FakeAppAccessResolver(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildTestApp(controller));
    await tester.tap(find.text('Cerrar sesion'));
    await tester.pumpAndSettle();

    expect(authRepository.signOutCalls, 1);
  });

  testWidgets('logout shows feedback when sign out fails', (tester) async {
    final controller = AuthController(
      authRepository: FakeAuthRepository(
        onSignOut: () {
          throw StateError('network');
        },
      ),
      userRepository: FakeUserRepository(),
      emailRegistrationRepository: FakeEmailRegistrationRepository(),
      appAccessResolver: FakeAppAccessResolver(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(buildTestApp(controller));
    await tester.tap(find.text('Cerrar sesion'));
    await tester.pumpAndSettle();

    expect(
      find.text('No se pudo cerrar sesion. Intentalo de nuevo.'),
      findsOneWidget,
    );
  });
}
