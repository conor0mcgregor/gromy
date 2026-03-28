import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gromy/core/widgets/password_strength_bar.dart';

void main() {
  testWidgets('shows the provided label and progress value', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PasswordStrengthBar(
            strength: 0.75,
            color: Colors.green,
            label: 'Fuerte',
          ),
        ),
      ),
    );

    expect(find.textContaining('Seguridad'), findsOneWidget);
    expect(find.text('Fuerte'), findsOneWidget);

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    final valueColor = indicator.valueColor! as AlwaysStoppedAnimation<Color?>;

    expect(indicator.value, 0.75);
    expect(valueColor.value, Colors.green);
  });
}
