import 'package:flutter/material.dart';
import 'package:gromy/features/tournament/data/services/firestore_tournament_service.dart';

import '../../../home/presentation/widgets/tournament_card.dart';
import '../../../inscription/screen/preinscription_screen.dart';
import '../../../tournament/data/model/app_tournament.dart';

class HistoricalTournamentsScreen extends StatefulWidget {
  const HistoricalTournamentsScreen({super.key, required this.uid});

  final String uid;

  @override
  State<HistoricalTournamentsScreen> createState() =>
      _HistoricalTournamentsScreenState();
}

class _HistoricalTournamentsScreenState
    extends State<HistoricalTournamentsScreen> {
  late final FirestoreTournamentService _tournamentService;

  @override
  void initState() {
    super.initState();
    _tournamentService = FirestoreTournamentService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Historial de Torneos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<AppTournament>>(
        stream: _tournamentService.watchHistoricalTournaments(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error al cargar el historial',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final tournaments = snapshot.data ?? [];

          if (tournaments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aún no tienes historial',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aquí aparecerán los torneos en los\nque hayas participado y finalizado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              final tournament = tournaments[index];
              return TournamentCard(
                tournament: tournament,
                animationDelay: Duration(milliseconds: 80 * index),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PreinscriptionScreen(
                        tournament: tournament,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
