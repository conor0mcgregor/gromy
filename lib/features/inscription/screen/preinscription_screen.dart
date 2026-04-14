import 'package:flutter/material.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../tournament/data/model/app_tournament.dart';
import '../../tournament/presentation/details/tournament_details.dart';
import '../../../core/getColors/getter_colors.dart';

class DemoEnrollScreen extends StatelessWidget {
  final AppTournament tournament;

  const DemoEnrollScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    // 👇 Añadimos el Scaffold aquí 👇
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Ajusta el color de fondo si lo necesitas
      body: TournamentDetails(
        tournament: tournament,
        onRegisterPressed: () {
          // Lógica para inscribirse al torneo
        },
      ),
    );
  }
}
