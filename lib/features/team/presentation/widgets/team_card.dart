import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../database/team/models/app_team.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TeamCard  ·  Tarjeta de equipo para la lista del perfil
//
//  Diseño glassmorphism coherente con el resto de la app:
//  foto circular del equipo a la izquierda + nombre a la derecha.
// ─────────────────────────────────────────────────────────────────────────────

class TeamCard extends StatelessWidget {
  const TeamCard({
    super.key,
    required this.team,
    required this.onTap,
  });

  final AppTeam team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // ── Foto del equipo ──
                _buildTeamAvatar(),
                const SizedBox(width: 16),

                // ── Nombre del equipo ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${team.members.length} miembro${team.members.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Flecha ──
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamAvatar() {
    final hasPhoto = team.photoUrl != null && team.photoUrl!.isNotEmpty;
    final initials = team.name.isNotEmpty ? team.name[0].toUpperCase() : '?';

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasPhoto
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
              ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                team.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
      ),
    );
  }
}
