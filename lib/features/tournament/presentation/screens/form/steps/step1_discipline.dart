import 'package:flutter/material.dart';
import '../../../../../../core/widgets/toggle_switch.dart';
import '../../../../data/model/enums_tournament.dart';
import '../widgets/step_card.dart';
import '../widgets/tournament_selectors.dart';
import '../widgets/form_helpers.dart';

/// Textos y flags de la fila “tipo de torneo” (sin [BuildContext]).
abstract final class Step1DisciplineCopy {
  static String teamSwitchLabel(bool isTeamSport) => isTeamSport
      ? 'Torneo por equipos'
      : 'Torneo individual';

  static String teamSwitchDescription({
    required TournamentSport? selectedSport,
    required bool isTeamSport,
  }) {
    if (selectedSport == null) {
      return 'Elige una disciplina para configurar la modalidad.';
    }
    if (selectedSport.isTeamOnlyDiscipline) {
      return 'Este deporte solo se juega por equipos.';
    }
    return isTeamSport
        ? 'Los participantes compiten agrupados en equipos.'
        : 'Los participantes compiten de forma individual.';
  }

  /// El switch solo es interactivo con disciplina elegida y sin bloqueo por deporte.
  static bool isTeamSwitchInteractive({
    required TournamentSport? selectedSport,
    required bool teamModeLockedByDiscipline,
  }) {
    return selectedSport != null && !teamModeLockedByDiscipline;
  }
}

/// Paso 1 — Disciplina: deporte y modalidad (equipos / individual).
class Step1Discipline extends StatelessWidget {
  const Step1Discipline({
    super.key,
    required this.selectedSport,
    required this.sportError,
    required this.onSportChanged,
    required this.isTeamSport,
    required this.teamModeLockedByDiscipline,
    required this.onTeamTournamentChanged,
  });

  final TournamentSport? selectedSport;
  final String? sportError;
  final ValueChanged<TournamentSport> onSportChanged;
  final bool isTeamSport;
  final bool teamModeLockedByDiscipline;
  final ValueChanged<bool> onTeamTournamentChanged;

  IconData _sportIcon(TournamentSport sport) => switch (sport) {
        TournamentSport.football => Icons.sports_soccer_rounded,
        TournamentSport.basketball => Icons.sports_basketball_rounded,
        TournamentSport.volleyball => Icons.sports_volleyball_rounded,
        TournamentSport.tennis => Icons.sports_tennis_rounded,
        TournamentSport.padel => Icons.sports_tennis_rounded,
        TournamentSport.karate => Icons.sports_martial_arts_rounded,
        TournamentSport.brazilianJiuJitsu => Icons.sports_kabaddi_rounded,
      };

  Widget _buildSportGrid() {
    return LayoutBuilder(
      builder: (context, c) {
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
      },
    );
  }

  Widget _buildTeamModeSection() {
    final interactive = Step1DisciplineCopy.isTeamSwitchInteractive(
      selectedSport: selectedSport,
      teamModeLockedByDiscipline: teamModeLockedByDiscipline,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(
          'Modalidad',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ToggleSwitch(
          value: isTeamSport,
          onChanged: onTeamTournamentChanged,
          label: Step1DisciplineCopy.teamSwitchLabel(isTeamSport),
          description: Step1DisciplineCopy.teamSwitchDescription(
            selectedSport: selectedSport,
            isTeamSport: isTeamSport,
          ),
          color: ToggleSwitchColor.violet,
          enabled: interactive,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StepCard(
      icon: Icons.sports_rounded,
      title: 'Disciplina',
      subtitle: 'Selecciona la modalidad deportiva del torneo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTeamModeSection(),
          const SizedBox(height: 18),
          _buildSportGrid(),
          if (sportError != null) ...[
            const SizedBox(height: 10),
            ErrorText(message: sportError!),
          ],
        ],
      ),
    );
  }
}
