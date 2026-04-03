import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gromy/app/app_shell.dart';
import 'package:gromy/features/auth/presentation/controllers/auth_controller.dart';
import 'package:gromy/features/events/presentation/screens/events_screen.dart';
import 'package:gromy/features/home/presentation/screens/home_screen.dart';
import 'package:gromy/features/notidications/presentation/screens/notifications_screen.dart';
import 'package:gromy/features/profile/presentation/screens/profile_screen.dart';
import 'package:gromy/features/tournament/presentation/screens/create_tournament_screen.dart';

import 'support/test_doubles.dart';

void main() {
  testWidgets('AppShell changes page when the navigation bar is used', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          authController: AuthController(
            authRepository: FakeAuthRepository(),
            userRepository: FakeUserRepository(),
            emailRegistrationRepository: FakeEmailRegistrationRepository(),
            appAccessResolver: FakeAppAccessResolver(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(EventsScreen), findsNothing);

    await tester.tap(find.text('Eventos'));
    await tester.pump();
    expect(find.byType(EventsScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.byType(CreateTournamentScreen), findsOneWidget);

    await tester.tap(find.text('Alertas'));
    await tester.pump();
    expect(find.byType(NotificationsScreen), findsOneWidget);

    await tester.tap(find.text('Perfil'));
    await tester.pump();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });
}
