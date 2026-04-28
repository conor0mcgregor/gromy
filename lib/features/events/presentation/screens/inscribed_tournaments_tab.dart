import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/tournament_card.dart';
import '../../../inscription/screen/preinscription_screen.dart';
import '../../../tournament/data/model/app_tournament.dart';
import '../../../../database/participant/models/app_participant.dart';
import '../../../../database/participant/services/firestore_participant_service.dart';
import '../controllers/events_controller.dart';
import 'events_screen.dart';

// ════════════════════════════════════════════════════════════════
//  INSCRIBED TOURNAMENTS TAB
//
//  Muestra todos los torneos en los que el usuario está inscrito,
//  permite navegar al detalle de cada uno y cancelar la inscripción.
// ════════════════════════════════════════════════════════════════

class InscribedTournamentsTab extends StatefulWidget {
  const InscribedTournamentsTab({super.key, required this.controller});

  final EventsController controller;

  @override
  State<InscribedTournamentsTab> createState() => _InscribedTournamentsTabState();
}

class _InscribedTournamentsTabState extends State<InscribedTournamentsTab> {
  // Servicio de participantes para buscar el AppParticipant de cada torneo.
  final _participantService = FirestoreParticipantService();

  @override
  Widget build(BuildContext context) {
    final uid = widget.controller.currentUid;

    if (uid == null) {
      return const EventsEmptyState(
        title: 'Inicia sesión',
        message: 'Necesitas iniciar sesión para ver tus inscripciones.',
        icon: Icons.lock_outline_rounded,
      );
    }

    return StreamBuilder<List<AppTournament>>(
      stream: widget.controller.watchEnrolledTournaments(),
      builder: (context, snapshot) {
        // ── Cargando ──
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const EventsLoadingState();
        }

        // ── Error ──
        if (snapshot.hasError) {
          return EventsErrorState(message: '${snapshot.error}');
        }

        final tournaments = snapshot.data ?? [];

        // ── Vacío ──
        if (tournaments.isEmpty) {
          return const EventsEmptyState(
            title: 'Sin inscripciones',
            message:
                'Aún no te has inscrito a ningún torneo.\nExplora la pantalla de inicio para encontrar eventos.',
            icon: Icons.how_to_reg_outlined,
          );
        }

        // ── Lista ──
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          itemCount: tournaments.length,
          itemBuilder: (context, index) {
            final tournament = tournaments[index];
            return TournamentCard(
              tournament: tournament,
              animationDelay: Duration(milliseconds: 70 * index),
              onTap: () => _navigateToDetail(context, tournament, uid),
            );
          },
        );
      },
    );
  }

  /// Navega al detalle del torneo en modo "inscrito".
  ///
  /// Carga primero el [AppParticipant] del usuario para poder pasar su ID
  /// al callback de cancelación.
  Future<void> _navigateToDetail(
    BuildContext context,
    AppTournament tournament,
    String uid,
  ) async {
    // Obtenemos el participante (lectura puntual, no hace falta stream aquí).
    AppParticipant? participant;
    try {
      final participants =
          await _participantService.getParticipants(tournament.id);
      participant = participants.where((p) => p.entityId == uid).firstOrNull;
    } catch (_) {
      // Si falla la carga del participante, navegamos igual pero sin
      // poder cancelar (el botón quedará deshabilitado).
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DemoEnrollScreen(
          tournament: tournament,
          isEnrolled: true,
          participant: participant,
          onCancelInscription: participant == null
              ? null
              : () => widget.controller.cancelInscription(
                    tournamentId: tournament.id,
                    participantId: participant!.id,
                  ),
        ),
      ),
    );
  }
}
