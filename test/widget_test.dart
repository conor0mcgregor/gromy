import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gromy/app/app_shell.dart';
import 'package:gromy/features/events/presentation/screens/events_screen.dart';
import 'package:gromy/features/home/presentation/screens/home_screen.dart';
import 'package:gromy/features/notidications/presentation/screens/notifications_screen.dart';
import 'package:gromy/features/profile/presentation/screens/profile_screen.dart';
import 'package:gromy/features/tournament/presentation/screens/create_tournament_screen.dart';

void main() {
  testWidgets('AppShell changes page when the navigation bar is used', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(EventsScreen), findsNothing);

    await tester.tap(find.text('Eventos'));
    await tester.pumpAndSettle();
    expect(find.byType(EventsScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byType(CreateTournamentScreen), findsOneWidget);

    await tester.tap(find.text('Alertas'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });
}
