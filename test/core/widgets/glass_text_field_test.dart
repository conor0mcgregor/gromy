import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gromy/core/widgets/glass_text_field.dart';

void main() {
  testWidgets('renders error text and updates the bound controller', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassTextField(
            controller: controller,
            hint: 'tu@correo.com',
            icon: Icons.email_outlined,
            errorText: 'Campo obligatorio',
          ),
        ),
      ),
    );

    expect(find.text('tu@correo.com'), findsOneWidget);
    expect(find.text('Campo obligatorio'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ana@example.com');

    expect(controller.text, 'ana@example.com');
  });

  testWidgets('passes obscureText to the inner TextField', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassTextField(
            controller: controller,
            hint: 'password',
            icon: Icons.lock_outline,
            obscureText: true,
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.obscureText, isTrue);
  });
}
