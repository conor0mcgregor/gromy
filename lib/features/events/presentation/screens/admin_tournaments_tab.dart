import 'package:flutter/material.dart';

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

    // Aprovechamos watchTournamentsAdmin, pero lo filtramos localmente 
    // para excluir los torneos donde el usuario es organizador absoluto.
    return StreamBuilder<List<AppTournament>>(
      stream: controller.watchTournamentsAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const EventsLoadingState();
        }

        if (snapshot.hasError) {
          return EventsErrorState(message: '${snapshot.error}');
        }

        final allAdminTournaments = snapshot.data ?? [];
        
        final onlyAdminTournaments = allAdminTournaments
            .where((t) => t.organizerUid != controller.currentUid)
            .toList();

        if (onlyAdminTournaments.isEmpty) {
          return const EventsEmptyState(
            title: 'No administras torneos',
            message: 'Aún no has sido invitado a administrar ningún torneo de terceros.',
            icon: Icons.admin_panel_settings_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          itemCount: onlyAdminTournaments.length,
          itemBuilder: (context, index) {
            return TournamentCard(
              tournament: onlyAdminTournaments[index],
              isMyTournament: false, // Puedes manejar el UI como consideres
              animationDelay: Duration(milliseconds: 70 * index),
            );
          },
        );
      },
    );
  }
}
