import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../controllers/team_form_controller.dart';
import '../../../widgets/team_member_tile.dart';

class Step2TeamReview extends StatelessWidget {
  const Step2TeamReview({
    super.key,
    required this.teamName,
    required this.coverBytes,
    required this.members,
  });

  final String teamName;
  final Uint8List? coverBytes;
  final List<TeamMemberEntry> members;

  @override
  Widget build(BuildContext context) {
    final pendingAdmins = members.where((m) => m.isAdmin).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildStepTitle(),
        const SizedBox(height: 28),
        _buildSummaryCard(pendingAdmins),
        const SizedBox(height: 20),
        if (members.isNotEmpty) ...[
          _buildSectionLabel('Invitaciones pendientes (${members.length})'),
          const SizedBox(height: 6),
          Text(
            'Estas personas recibiran una invitacion al crear el equipo. Aun no contaran como miembros reales.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          ...members.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TeamMemberTile(
                displayName: m.displayName,
                nickname: m.nickname,
                photoUrl: m.photoUrl,
                isAdmin: m.isAdmin,
                showAdminBadge: true,
                muted: true,
                statusLabel: 'Pendiente',
                statusColor: const Color(0xFFF59E0B),
              ),
            ),
          ),
        ] else ...[
          _buildInfoCard(
            icon: Icons.info_outline_rounded,
            text:
                'No has preparado invitaciones. Podras invitar usuarios despues desde la gestion del equipo.',
          ),
        ],
        const SizedBox(height: 20),
        _buildInfoCard(
          icon: Icons.check_circle_outline_rounded,
          text:
              'Tu seras el unico miembro real al crearse el equipo y tambien su administrador inicial.',
          color: const Color(0xFF22C55E),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          icon: Icons.pending_actions_rounded,
          text: members.isEmpty
              ? 'No hay invitaciones pendientes por enviar en esta creacion.'
              : 'Las ${members.length} invitaciones se enviaran al crear el equipo y quedaran claramente marcadas como pendientes.',
          color: const Color(0xFFF59E0B),
        ),
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
                const Color(0xFF10B981).withValues(alpha: 0.12),
                const Color(0xFF22C55E).withValues(alpha: 0.06),
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
                    colors: [Color(0xFF10B981), Color(0xFF22C55E)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fact_check_rounded,
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
                      'Resumen del equipo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Revisa miembros reales e invitaciones antes de crear el equipo',
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

  Widget _buildSummaryCard(int pendingAdmins) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              _buildTeamPhoto(),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamName.isEmpty ? '-' : teamName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoChip(
                      Icons.people_rounded,
                      '1 miembro real al crear',
                    ),
                    const SizedBox(height: 4),
                    _buildInfoChip(
                      Icons.schedule_send_rounded,
                      '${members.length} invitacion${members.length == 1 ? '' : 'es'} pendiente${members.length == 1 ? '' : 's'}',
                    ),
                    const SizedBox(height: 4),
                    _buildInfoChip(
                      Icons.admin_panel_settings_rounded,
                      '1 admin real + $pendingAdmins admin pendiente${pendingAdmins == 1 ? '' : 's'}',
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

  Widget _buildTeamPhoto() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: coverBytes == null
            ? const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
              )
            : null,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: coverBytes != null
            ? Image.memory(
                coverBytes!,
                fit: BoxFit.cover,
                width: 72,
                height: 72,
              )
            : Center(
                child: Text(
                  teamName.isNotEmpty ? teamName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF00D4FF)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String text,
    Color color = const Color(0xFF00D4FF),
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
