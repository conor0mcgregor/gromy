import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gromy/core/widgets/tourney_nav_bar.dart';

void main() {
  testWidgets('renders labels, caps the badge and reports taps', (
    tester,
  ) async {
    var tappedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: TourneyNavBar(
            currentIndex: 0,
            onTap: (index) {
              tappedIndex = index;
            },
            items: const [
              NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Inicio',
              ),
              NavItem(
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications_rounded,
                label: 'Alertas',
                badgeCount: 12,
              ),
              NavItem(icon: Icons.add, activeIcon: Icons.add, isCentral: true),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Alertas'), findsOneWidget);
    expect(find.text('9+'), findsOneWidget);

    await tester.tap(find.text('Alertas'));
    await tester.pump();
    expect(tappedIndex, 1);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(tappedIndex, 2);
  });
}
