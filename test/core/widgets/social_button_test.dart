import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gromy/core/widgets/social_button.dart';

void main() {
  testWidgets('invokes the callback when tapped', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialButton(
            label: 'Google',
            icon: Icons.g_mobiledata_rounded,
            onTap: () {
              taps++;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(SocialButton));
    await tester.pump();

    expect(taps, 1);
  });
}
