import 'package:flutter/material.dart';

import '../../../../app/app_shell.dart';
import '../../../../database/session/models/app_access_state.dart';
import '../../../../database/session/repositories/app_access_resolver.dart';
import '../../../../database/session/services/firebase_app_access_resolver.dart';
import 'email_verification_pending_screen.dart';
import 'login_screen.dart';
import 'register_dates_screen.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key, this.appAccessResolver});

  final AppAccessResolver? appAccessResolver;

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  late final AppAccessResolver _appAccessResolver;

  @override
  void initState() {
    super.initState();
    _appAccessResolver = widget.appAccessResolver ?? FirebaseAppAccessResolver();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppAccessState>(
      stream: _appAccessResolver.watch(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final accessState = snapshot.data!;
        return switch (accessState) {
          AppAccessUnauthenticated() => const LoginScreen(),
          AppAccessAuthenticated() => const AppShell(),
          AppAccessPendingEmailRegistration() => EmailVerificationPendingScreen(
              accessState: accessState,
            ),
          AppAccessProfileCompletionRequired(
            :final uid,
            :final email,
            :final provider,
            :final photoUrl,
          ) =>
            RegisterDatesScreen(
              uid: uid,
              email: email,
              provider: provider,
              photoUrl: photoUrl,
            ),
        };
      },
    );
  }
}
