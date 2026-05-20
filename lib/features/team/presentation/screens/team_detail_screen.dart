import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/getColors/getter_colors.dart';
import '../../../../core/widgets/glow_orb.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../database/team/models/app_team.dart';
import '../../../../database/team/services/firestore_team_service.dart';
import '../../../user/data/services/firestore_user_service.dart';
import '../../../user/data/models/app_user.dart';
import '../../../profile/presentation/screens/other_user_profile_screen.dart';
import '../../../../app/app_shell.dart';
import '../widgets/team_member_tile.dart';
import 'team_manage_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TeamDetailScreen  ·  Pantalla de detalle del equipo
//
//  Muestra: foto, nombre, lista de miembros y admins.
//  Si el usuario es admin, muestra un botón "Gestionar".
// ─────────────────────────────────────────────────────────────────────────────

class TeamDetailScreen extends StatefulWidget {
  const TeamDetailScreen({super.key, required this.team});

  final AppTeam team;

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen>
    with SingleTickerProviderStateMixin {
  late AppTeam _team;
  final _userService = FirestoreUserService();
  final _teamService = FirestoreTeamService();

  final Map<String, AppUser?> _userCache = {};
  bool _isLoadingUsers = true;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isAdmin => _team.isAdmin(_currentUid);

  @override
  void initState() {
    super.initState();
    _team = widget.team;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    _loadUsers();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    for (final uid in _team.members) {
      if (!_userCache.containsKey(uid)) {
        try {
          final user = await _userService.getUser(uid);
          _userCache[uid] = user;
        } catch (_) {
          _userCache[uid] = null;
        }
      }
    }
    if (mounted) setState(() => _isLoadingUsers = false);
  }

  Future<void> _refreshTeam() async {
    final updated = await _teamService.getTeam(_team.id);
    if (updated != null && mounted) {
      setState(() => _team = updated);
      _isLoadingUsers = true;
      await _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fondo ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0A1A),
                  Color(0xFF0D0D2B),
                  Color(0xFF12122E),
                ],
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: GlowOrb(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
              size: 260,
            ),
          ),
          Positioned(
            bottom: 80,
            left: -70,
            child: GlowOrb(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.2),
              size: 220,
            ),
          ),

          // ── Contenido ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // ── App bar ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white70,
                          ),
                        ),
                        const Spacer(),
                        if (_isAdmin)
                          _buildAdminBadge(),
                      ],
                    ),
                  ),

                  // ── Scrollable content ──
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: Column(
                            children: [
                              _buildTeamHeader(),
                              const SizedBox(height: 28),
                              _buildMembersSection(),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Botón gestionar (solo admins) ──
          if (_isAdmin)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0A0A1A).withValues(alpha: 0),
                      const Color(0xFF0A0A1A),
                    ],
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: GradientButton(
                      label: 'Gestionar equipo',
                      icon: Icons.settings_rounded,
                      variant: GradientButtonVariant.violet,
                      size: GradientButtonSize.large,
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeamManageScreen(team: _team),
                          ),
                        );
                        _refreshTeam();
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTeamHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6C63FF).withValues(alpha: 0.14),
                const Color(0xFF00D4FF).withValues(alpha: 0.07),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Column(
            children: [
              // ── Avatar ──
              _buildLargeAvatar(),
              const SizedBox(height: 18),

              // ── Nombre ──
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
                ).createShader(bounds),
                child: Text(
                  _team.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),

              // ── Stats ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatChip(
                    Icons.people_rounded,
                    '${_team.members.length} miembros',
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    Icons.admin_panel_settings_rounded,
                    '${_team.adminIds.length} admins',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeAvatar() {
    final hasPhoto = _team.photoUrl != null && _team.photoUrl!.isNotEmpty;
    final initial = _team.name.isNotEmpty ? _team.name[0].toUpperCase() : '?';

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasPhoto
            ? null
            : const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
          _team.photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        )
            : Center(
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF00D4FF)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.admin_panel_settings_rounded,
              size: 14, color: Color(0xFFB0A8FF)),
          SizedBox(width: 4),
          Text(
            'Administrador',
            style: TextStyle(
              color: Color(0xFFB0A8FF),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Sección título ──
        Row(
          children: [
            Text(
              'Miembros',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            Text(
              '${_team.members.length}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_isLoadingUsers)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          )
        else
          ..._team.members.map((uid) {
            final user = _userCache[uid];
            final isAdmin = _team.isAdmin(uid);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TeamMemberTile(
                displayName: user != null
                    ? '${user.name} ${user.lastName}'.trim()
                    : 'Usuario desconocido',
                nickname: user?.nickname ?? uid,
                photoUrl: user?.photoUrl,
                isAdmin: isAdmin,
                showAdminBadge: true,
                onTap: () {
                  if (FirebaseAuth.instance.currentUser?.uid == uid) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppShell(initialIndex: 4),
                      ),
                          (route) => false,
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OtherUserProfileScreen(targetUid: uid),
                    ),
                  );
                },
              ),
            );
          }),
      ],
    );
  }
}
