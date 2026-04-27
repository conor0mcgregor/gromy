import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../controllers/team_form_controller.dart';
import '../../../widgets/team_member_tile.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Step2 · Resumen / Review del equipo
//
//  Muestra todos los datos introducidos antes de confirmar la creación:
//  - Foto y nombre
//  - Lista de miembros con roles
// ─────────────────────────────────────────────────────────────────────────────

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // ── Título ──
        _buildStepTitle(),
        const SizedBox(height: 28),

        // ── Card resumen ──
        _buildSummaryCard(),
        const SizedBox(height: 20),

        // ── Miembros ──
        if (members.isNotEmpty) ...[
          _buildSectionLabel('Miembros (${members.length})'),
          const SizedBox(height: 12),
          ...members.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TeamMemberTile(
                  displayName: m.displayName,
                  nickname: m.nickname,
                  photoUrl: m.photoUrl,
                  isAdmin: m.isAdmin,
                  showAdminBadge: true,
                ),
              )),
        ] else ...[
          _buildInfoCard(
            icon: Icons.info_outline_rounded,
            text: 'No has añadido miembros. Podrás añadirlos después desde la gestión del equipo.',
          ),
        ],

        const SizedBox(height: 20),

        // ── Aviso ──
        _buildInfoCard(
          icon: Icons.check_circle_outline_rounded,
          text: 'Tú serás añadido automáticamente como miembro y administrador del equipo.',
          color: const Color(0xFF22C55E),
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
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
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
                      'Revisa los datos antes de crear el equipo',
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

  Widget _buildSummaryCard() {
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
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              // ── Foto ──
              _buildTeamPhoto(),
              const SizedBox(width: 18),

              // ── Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamName.isEmpty ? '—' : teamName,
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
                      '${members.length + 1} miembro${members.isNotEmpty ? 's' : ''}',
                    ),
                    const SizedBox(height: 4),
                    _buildInfoChip(
                      Icons.admin_panel_settings_rounded,
                      '${members.where((m) => m.isAdmin).length + 1} admin${members.where((m) => m.isAdmin).isNotEmpty ? 's' : ''}',
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
            ? Image.memory(coverBytes!, fit: BoxFit.cover, width: 72, height: 72)
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
