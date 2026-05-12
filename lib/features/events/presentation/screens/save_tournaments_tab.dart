import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/tournament_card.dart';
import '../../../inscription/screen/preinscription_screen.dart';
import '../../../tournament/data/model/app_tournament.dart';
import '../controllers/events_controller.dart';
import '../controllers/favorites_controller.dart';
import 'events_screen.dart';

class SaveTournamentsTab extends StatefulWidget {
  const SaveTournamentsTab({super.key, required this.controller});

  final EventsController controller;

  @override
  State<SaveTournamentsTab> createState() => _SaveTournamentsTabState();
}

class _SaveTournamentsTabState extends State<SaveTournamentsTab> {
  late final FavoritesController _favoritesController;

  @override
  void initState() {
    super.initState();
    _favoritesController = FavoritesController();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.currentUid == null) {
      return const EventsEmptyState(
        title: 'Inicia sesión',
        message: 'Necesitas iniciar sesión para ver tus eventos guardados.',
        icon: Icons.lock_outline_rounded,
      );
    }

    return StreamBuilder<List<AppTournament>>(
      stream: _favoritesController.watchFavoriteTournaments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const EventsLoadingState();
        }

        if (snapshot.hasError) {
          return EventsErrorState(message: '${snapshot.error}');
        }

        final tournaments = snapshot.data ?? [];

        if (tournaments.isEmpty) {
          return const EventsEmptyState(
            title: 'Aún no tienes favoritos',
            message: 'Explora torneos y marca el icono del corazón para guardarlos aquí.',
            icon: Icons.favorite_border_rounded,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          itemCount: tournaments.length,
          itemBuilder: (context, index) {
            final tournament = tournaments[index];
            return TournamentCard(
              tournament: tournament,
              animationDelay: Duration(milliseconds: 70 * index),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PreinscriptionScreen(tournament: tournament),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
