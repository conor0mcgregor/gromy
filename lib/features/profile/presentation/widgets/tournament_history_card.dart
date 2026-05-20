import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../user/data/models/user_tournament_history_entry.dart';

class TournamentHistoryCard extends StatelessWidget {
  const TournamentHistoryCard({super.key, required this.entry});

  final UserTournamentHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final dateLabel = entry.scheduledAt != null
        ? DateFormat('d MMM yyyy', 'es').format(entry.scheduledAt!)
        : 'Fecha por confirmar';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResultBadge(status: entry.resultStatus),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.tournamentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dateLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                  ),
                ),
                if (entry.sport != null && entry.sport!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.sport!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Chip(label: entry.placementLabel),
                    _Chip(label: _resultLabel(entry.resultStatus)),
                    if (entry.tournamentType.contains('private'))
                      const _Chip(label: 'Privado'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _resultLabel(TournamentResultStatus status) {
    return switch (status) {
      TournamentResultStatus.won => 'Ganado',
      TournamentResultStatus.eliminated => 'Eliminado',
      TournamentResultStatus.pending => 'En curso',
      TournamentResultStatus.participated => 'Participado',
    };
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.status});

  final TournamentResultStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      TournamentResultStatus.won => (
        const Color(0xFFFFD166),
        Icons.emoji_events_rounded,
      ),
      TournamentResultStatus.eliminated => (
        const Color(0xFFFF4D6A),
        Icons.sports_martial_arts_rounded,
      ),
      TournamentResultStatus.pending => (
        const Color(0xFF00D4FF),
        Icons.hourglass_top_rounded,
      ),
      TournamentResultStatus.participated => (
        const Color(0xFF6C63FF),
        Icons.flag_rounded,
      ),
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
