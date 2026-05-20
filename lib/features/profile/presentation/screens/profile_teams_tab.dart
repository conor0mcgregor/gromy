import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/getColors/getter_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../database/team/services/firestore_team_service.dart';
import '../../../../database/team/models/app_team.dart';
import '../../../team/presentation/screens/create_team_screen.dart';
import '../../../team/presentation/screens/team_detail_screen.dart';
import '../../../team/presentation/widgets/team_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ProfileTeamsTab  ·  Pestaña de equipos del perfil
//
//  - Botón "Crear equipo" en la parte superior
//  - Lista en tiempo real de los equipos del usuario
// ─────────────────────────────────────────────────────────────────────────────

class ProfileTeamsTab extends StatelessWidget {
  const ProfileTeamsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = _currentUser();
    if (currentUser == null) {
      return _buildErrorState('No se pudo obtener el usuario actual.');
    }

    final teamService = FirestoreTeamService();

    return StreamBuilder<List<AppTeam>>(
      stream: teamService.watchTeamsByMember(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState('Error al cargar los equipos.');
        }

        final teams = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ── Botón crear equipo ──
              GradientButton(
                label: 'Crear equipo',
                icon: Icons.group_add_rounded,
                variant: GradientButtonVariant.violet,
                size: GradientButtonSize.large,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateTeamScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // ── Lista de equipos ──
              if (teams.isEmpty)
                Expanded(child: _buildEmptyState())
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: teams.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      return TeamCard(
                        team: team,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TeamDetailScreen(team: team),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  User? _currentUser() {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
            ).createShader(bounds),
            child: const Icon(Icons.groups_rounded, size: 64),
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
            ).createShader(bounds),
            child: const Text(
              'Sin equipos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primer equipo y empieza a competir',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.35),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Color(0xFFFF4D6A),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
