import 'package:flutter/material.dart';

import '../../../adminTournament/presentation/screens/tournament_management_screen.dart';
import '../../../home/presentation/widgets/tournament_card.dart';
import '../../../tournament/data/model/app_tournament.dart';
import '../controllers/events_controller.dart';
import 'events_screen.dart';

class AdminTournamentsTab extends StatelessWidget {
  const AdminTournamentsTab({super.key, required this.controller});

  final EventsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.currentUid == null) {
      return const EventsEmptyState(
        title: 'Inicia sesión',
        message: 'Necesitas iniciar sesión para ver los torneos.',
        icon: Icons.lock_outline_rounded,
      );
    }

    
    return StreamBuilder<List<AppTournament>>(
      stream: controller.watchAllAdministeredTournaments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const EventsLoadingState();
        }

        if (snapshot.hasError) {
          return EventsErrorState(message: '${snapshot.error}');
        }

        final managedTournaments = snapshot.data ?? [];

        if (managedTournaments.isEmpty) {
          return const EventsEmptyState(
            title: 'Sin torneos para gestionar',
            message: 'Aquí aparecerán los torneos que has creado o en los que eres administrador.',
            icon: Icons.admin_panel_settings_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          itemCount: managedTournaments.length,
          itemBuilder: (context, index) {
            final tournament = managedTournaments[index];
            final isCreator = tournament.organizerUid == controller.currentUid;
            
            return TournamentCard(
              tournament: tournament,
              isMyTournament: isCreator,
              animationDelay: Duration(milliseconds: 70 * index),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TournamentManagementScreen(
                    tournament: tournament,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
