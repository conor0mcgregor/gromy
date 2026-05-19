import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../../core/getColors/getter_colors.dart';
import '../../../../../../core/widgets/field_label.dart';
import '../../../../../../core/widgets/glass_text_field.dart';
import '../../../../../../core/widgets/gradient_button.dart';
import '../../../../../../core/widgets/toggle_switch.dart';
import '../../../controllers/team_form_controller.dart';
import '../../../widgets/team_member_tile.dart';

class Step1TeamMembers extends StatelessWidget {
  const Step1TeamMembers({
    super.key,
    required this.memberController,
    required this.memberError,
    required this.isSearching,
    required this.members,
    required this.onMemberChanged,
    required this.onAddMember,
    required this.onRemoveMember,
    required this.onToggleAdmin,
  });

  final TextEditingController memberController;
  final String? memberError;
  final bool isSearching;
  final List<TeamMemberEntry> members;
  final ValueChanged<String> onMemberChanged;
  final VoidCallback onAddMember;
  final ValueChanged<String> onRemoveMember;
  final ValueChanged<String> onToggleAdmin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildStepTitle(),
        const SizedBox(height: 24),
        const FieldLabel(label: 'Invitar usuario por nickname'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GlassTextField(
                controller: memberController,
                hint: '@nickname',
                icon: Icons.person_search_rounded,
                onChanged: onMemberChanged,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              height: 52,
              child: isSearching
                  ? Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : GradientButton(
                      label: '',
                      icon: Icons.person_add_rounded,
                      variant: GradientButtonVariant.ocean,
                      size: GradientButtonSize.medium,
                      onPressed: onAddMember,
                    ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildHintCard(),
        if (memberError != null) ...[
          const SizedBox(height: 8),
          _buildErrorText(memberError!),
        ],
        const SizedBox(height: 24),
        if (members.isNotEmpty) ...[
          Row(
            children: [
              const FieldLabel(label: 'Invitaciones pendientes de enviar'),
              const Spacer(),
              Text(
                '${members.length}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Se enviarán al crear el equipo y no contarán como miembros hasta aceptar.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          ...members.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TeamMemberTile(
                displayName: member.displayName,
                nickname: member.nickname,
                photoUrl: member.photoUrl,
                isAdmin: member.isAdmin,
                muted: true,
                statusLabel: 'Pendiente',
                statusColor: const Color(0xFFF59E0B),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ToggleSwitch(
                      value: member.isAdmin,
                      onChanged: (_) => onToggleAdmin(member.uid),
                      color: ToggleSwitchColor.violet,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => onRemoveMember(member.uid),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFFFF4D6A,
                          ).withValues(alpha: 0.12),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFFFF4D6A),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else ...[
          _buildEmptyState(),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStepTitle() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6C63FF).withValues(alpha: 0.12),
                const Color(0xFF00D4FF).withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.group_add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invitaciones del equipo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Añade personas para invitarlas. Serán miembros solo cuando acepten.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHintCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.pending_outlined,
            size: 16,
            color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Los usuarios añadidos aquí quedarán como pendientes hasta que acepten la invitación.',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.58),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.schedule_send_rounded,
            size: 40,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'Aun no has preparado invitaciones',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Puedes invitar ahora o dejar el equipo creado y hacerlo mas tarde desde gestion.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 12.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorText(String text) {
    return Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Color(0xFFFF4D6A),
          size: 14,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFFF4D6A),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
