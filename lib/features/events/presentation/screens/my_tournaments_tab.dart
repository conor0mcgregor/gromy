import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/tournament_card.dart';
import '../../../tournament/data/model/app_tournament.dart';
import '../controllers/events_controller.dart';
import 'events_screen.dart';

class MyTournamentsTab extends StatelessWidget {
  const MyTournamentsTab({super.key, required this.controller});

  final EventsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.currentUid == null) {
      return const EventsEmptyState(
        title: 'Inicia sesión',
        message: 'Necesitas iniciar sesión para ver tus torneos.',
        icon: Icons.lock_outline_rounded,
      );
    }

    return StreamBuilder<List<AppTournament>>(
      stream: controller.watchMyTournaments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const EventsLoadingState();
        }

        if (snapshot.hasError) {
          return EventsErrorState(message: '${snapshot.error}');
        }

        final myTournaments = snapshot.data ?? [];

        if (myTournaments.isEmpty) {
          return const EventsEmptyState(
            title: 'Aún no tienes torneos',
            message: 'Anímate a crear tu primer torneo.',
            icon: Icons.emoji_events_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          itemCount: myTournaments.length,
          itemBuilder: (context, index) {
            return TournamentCard(
              tournament: myTournaments[index],
              isMyTournament: true,
              animationDelay: Duration(milliseconds: 70 * index),
            );
          },
        );
      },
    );
  }
}
