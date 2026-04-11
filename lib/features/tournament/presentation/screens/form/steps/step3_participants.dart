import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/model/enums_tournament.dart';
import '../widgets/step_card.dart';
import '../widgets/form_fields.dart';
import '../widgets/form_helpers.dart';
import '../widgets/tournament_selectors.dart';

class Step3Participants extends StatelessWidget {
  const Step3Participants({
    super.key,
    required this.selectedSport,
    required this.maxParticipantsController,
    required this.maxParticipantsError,
    required this.onMaxParticipantsChanged,
    required this.membersPerTeamController,
    required this.membersPerTeamError,
    required this.onMembersPerTeamChanged,
    required this.selectedAccessType,
    required this.accessTypeError,
    required this.onAccessTypeChanged,
  });

  final TournamentSport? selectedSport;

  final TextEditingController maxParticipantsController;
  final String? maxParticipantsError;
  final ValueChanged<String>? onMaxParticipantsChanged;

  final TextEditingController membersPerTeamController;
  final String? membersPerTeamError;
  final ValueChanged<String>? onMembersPerTeamChanged;

  final TournamentAccessType? selectedAccessType;
  final String? accessTypeError;
  final ValueChanged<TournamentAccessType> onAccessTypeChanged;

  bool _isTeamSport(TournamentSport sport) {
    return sport == TournamentSport.football ||
        sport == TournamentSport.basketball ||
        sport == TournamentSport.volleyball;
  }

  IconData _getAccessTypeIcon(TournamentAccessType type) => switch (type) {
        TournamentAccessType.publicOpen => Icons.public_rounded,
        TournamentAccessType.publicClosed => Icons.lock_open_rounded,
        TournamentAccessType.privateInviteOnly => Icons.mail_lock_rounded,
      };

  @override
  Widget build(BuildContext context) {
    if (selectedSport == null) return const SizedBox.shrink();

    final isTeamSport = _isTeamSport(selectedSport!);

    return StepCard(
      icon: Icons.groups_2_rounded,
      title: 'Participantes',
      subtitle: 'Define cuántos pueden apuntarse y quién tiene acceso al torneo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassField(
            controller: maxParticipantsController,
            hint: 'Ej. 16',
            icon: Icons.groups_2_rounded,
            label: isTeamSport
                ? 'Número máximo de equipos'
                : 'Número máximo de participantes',
            errorText: maxParticipantsError,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: onMaxParticipantsChanged,
          ),
          const SizedBox(height: 16),
          if (isTeamSport) ...[
            GlassField(
              controller: membersPerTeamController,
              hint: 'Ej. 5',
              icon: Icons.group,
              label: 'Miembros por equipo',
              errorText: membersPerTeamError,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: onMembersPerTeamChanged,
            ),
          ],
          const SizedBox(height: 20),
          const FieldLabel(label: '¿Quién puede apuntarse?'),
          const SizedBox(height: 10),
          ...TournamentAccessType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AccessCard(
                title: type.label,
                subtitle: type.description,
                icon: _getAccessTypeIcon(type),
                selected: selectedAccessType == type,
                onTap: () => onAccessTypeChanged(type),
              ),
            ),
          ),
          if (accessTypeError != null) ErrorText(message: accessTypeError!),
        ],
      ),
    );
  }
}
