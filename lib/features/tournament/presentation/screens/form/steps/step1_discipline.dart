import 'package:flutter/material.dart';
import '../../../../data/model/enums_tournament.dart';
import '../widgets/step_card.dart';
import '../widgets/tournament_selectors.dart';
import '../widgets/form_helpers.dart';

/// Paso 1 — Disciplina: Selección de deporte / categoría.
class Step1Discipline extends StatelessWidget {
  const Step1Discipline({
    super.key,
    required this.selectedSport,
    required this.sportError,
    required this.onSportChanged,
  });

  final TournamentSport? selectedSport;
  final String? sportError;
  final ValueChanged<TournamentSport> onSportChanged;

  IconData _sportIcon(TournamentSport sport) => switch (sport) {
        TournamentSport.football => Icons.sports_soccer_rounded,
        TournamentSport.basketball => Icons.sports_basketball_rounded,
        TournamentSport.volleyball => Icons.sports_volleyball_rounded,
        TournamentSport.tennis => Icons.sports_tennis_rounded,
        TournamentSport.padel => Icons.sports_tennis_rounded,
        TournamentSport.karate => Icons.sports_martial_arts_rounded,
        TournamentSport.brazilianJiuJitsu => Icons.sports_kabaddi_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return StepCard(
      icon: Icons.sports_rounded,
      title: 'Disciplina',
      subtitle: 'Selecciona la modalidad deportiva del torneo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth >= 400 ? 2 : 1;
            const spacing = 10.0;
            final w = (c.maxWidth - spacing * (cols - 1)) / cols;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: TournamentSport.values.map((sport) {
                final selected = selectedSport == sport;
                return SizedBox(
                  width: w,
                  child: SportChip(
                    title: sport.label,
                    icon: _sportIcon(sport),
                    selected: selected,
                    onTap: () => onSportChanged(sport),
                  ),
                );
              }).toList(),
            );
          }),
          if (sportError != null) ...[
            const SizedBox(height: 10),
            ErrorText(message: sportError!),
          ],
        ],
      ),
    );
  }
}
