import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../profile/presentation/screens/historical_tournaments_screen.dart'
    as profile;

/// Historial de torneos finalizados del usuario actual.
class HistoricalTournamentsScreen extends StatelessWidget {
  const HistoricalTournamentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A1A),
        body: Center(
          child: Text(
            'Inicia sesión para ver tu historial de inscripciones.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return profile.HistoricalTournamentsScreen(uid: uid);
  }
}
