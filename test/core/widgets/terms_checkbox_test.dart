import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gromy/core/widgets/terms_checkbox.dart';

void main() {
  testWidgets('toggles the value through onChanged when tapped', (
    tester,
  ) async {
    bool? receivedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TermsCheckbox(
            value: false,
            onChanged: (value) {
              receivedValue = value;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TermsCheckbox));
    await tester.pump();

    expect(receivedValue, isTrue);
  });

  testWidgets('shows the check icon when selected', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TermsCheckbox(value: true, onChanged: _noop)),
      ),
    );

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}

void _noop(bool? _) {}
