import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/getColors/getter_colors.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/glow_orb.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/toggle_switch.dart';
import '../../../../database/team/models/app_team.dart';
import '../../../../database/team/services/firestore_team_service.dart';
import '../../../user/data/models/app_user.dart';
import '../../../user/data/services/firestore_user_service.dart';
import '../widgets/team_member_tile.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TeamManageScreen  ·  Pantalla de gestión del equipo (solo admins)
//
//  Permite:
//  - Cambiar nombre del equipo
//  - Añadir/eliminar miembros
//  - Cambiar roles (admin / no admin)
//  - Eliminar el equipo
// ─────────────────────────────────────────────────────────────────────────────

class TeamManageScreen extends StatefulWidget {
  const TeamManageScreen({super.key, required this.team});

  final AppTeam team;

  @override
  State<TeamManageScreen> createState() => _TeamManageScreenState();
}

class _TeamManageScreenState extends State<TeamManageScreen>
    with SingleTickerProviderStateMixin {
  late AppTeam _team;
  final _teamService = FirestoreTeamService();
  final _userService = FirestoreUserService();

  final _nameController = TextEditingController();
  final _memberController = TextEditingController();

  String? _memberError;
  bool _isSearching = false;
  bool _isSavingName = false;
  bool _isDeleting = false;

  final Map<String, AppUser?> _userCache = {};
  bool _isLoadingUsers = true;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;


  @override
  void initState() {
    super.initState();
    _team = widget.team;
    _nameController.text = _team.name;

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
    _nameController.dispose();
    _memberController.dispose();
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
      setState(() {
        _team = updated;
        _isLoadingUsers = true;
      });
      await _loadUsers();
    }
  }

  // ── Acciones ───────────────────────────────────────────────────────────────

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName.length < 3) {
      _showSnackBar('El nombre debe tener al menos 3 caracteres.', isError: true);
      return;
    }
    if (newName == _team.name) return;

    setState(() => _isSavingName = true);
    try {
      final updated = _team.copyWith(name: newName);
      await _teamService.updateTeam(updated);
      setState(() => _team = updated);
      _showSnackBar('Nombre actualizado.', isError: false);
    } catch (_) {
      _showSnackBar('Error al actualizar el nombre.', isError: true);
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  Future<void> _addMember() async {
    final raw = _memberController.text.trim();
    if (raw.isEmpty) {
      setState(() => _memberError = 'Escribe un nickname.');
      return;
    }

    setState(() {
      _isSearching = true;
      _memberError = null;
    });

    try {
      final cleanRaw = raw.startsWith('@') ? raw.substring(1) : raw;
      final user = await _userService.getUserByNickname(cleanRaw);

      if (user == null) {
        setState(() => _memberError = 'No existe un usuario con ese nickname.');
        return;
      }

      if (_team.members.contains(user.uid)) {
        setState(() => _memberError = 'Este usuario ya es miembro del equipo.');
        return;
      }

      await _teamService.addMember(teamId: _team.id, userId: user.uid);
      _memberController.clear();
      _userCache[user.uid] = user;
      await _refreshTeam();
      _showSnackBar('Miembro añadido.', isError: false);
    } catch (_) {
      setState(() => _memberError = 'Error al añadir el miembro.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _removeMember(String uid) async {
    if (uid == _team.creatorId) {
      _showSnackBar('No puedes eliminar al creador del equipo.', isError: true);
      return;
    }

    final confirm = await _showConfirmDialog(
      '¿Eliminar miembro?',
      'Este usuario dejará de formar parte del equipo.',
    );
    if (!confirm) return;

    try {
      await _teamService.removeMember(teamId: _team.id, userId: uid);
      // Si era admin, también quitarlo de admins
      if (_team.isAdmin(uid)) {
        await _teamService.removeAdmin(teamId: _team.id, userId: uid);
      }
      await _refreshTeam();
      _showSnackBar('Miembro eliminado.', isError: false);
    } catch (_) {
      _showSnackBar('Error al eliminar el miembro.', isError: true);
    }
  }

  Future<void> _toggleAdmin(String uid) async {
    if (uid == _team.creatorId) {
      _showSnackBar('El creador siempre es administrador.', isError: true);
      return;
    }

    try {
      if (_team.isAdmin(uid)) {
        await _teamService.removeAdmin(teamId: _team.id, userId: uid);
      } else {
        await _teamService.addAdmin(teamId: _team.id, userId: uid);
      }
      await _refreshTeam();
    } catch (_) {
      _showSnackBar('Error al cambiar el rol.', isError: true);
    }
  }

  Future<void> _deleteTeam() async {
    final confirm = await _showConfirmDialog(
      '¿Eliminar equipo?',
      'Se eliminará el equipo "${_team.name}" y todos sus datos. Esta acción no se puede deshacer.',
      isDangerous: true,
    );
    if (!confirm) return;

    setState(() => _isDeleting = true);
    try {
      await _teamService.deleteTeam(_team.id);
      if (mounted) {
        _showSnackBar('Equipo eliminado.', isError: false);
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (_) {
      _showSnackBar('Error al eliminar el equipo.', isError: true);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  Future<bool> _showConfirmDialog(
    String title,
    String content, {
    bool isDangerous = false,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101127),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isDangerous
                  ? Icons.warning_amber_rounded
                  : Icons.info_outline_rounded,
              color:
                  isDangerous ? const Color(0xFFFF4D6A) : const Color(0xFF00D4FF),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: isDangerous
                  ? const Color(0xFFFF4D6A)
                  : const Color(0xFF6C63FF),
            ),
            child: Text(
              isDangerous ? 'Eliminar' : 'Confirmar',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return confirm == true;
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.info_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFFF4D6A) : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
                          ).createShader(bounds),
                          child: const Text(
                            'Gestionar equipo',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48), // balance
                      ],
                    ),
                  ),

                  // ── Scrollable content ──
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildNameSection(),
                              const SizedBox(height: 28),
                              _buildAddMemberSection(),
                              const SizedBox(height: 28),
                              _buildMembersSection(),
                              const SizedBox(height: 40),
                              _buildDangerZone(),
                              const SizedBox(height: 40),
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
        ],
      ),
    );
  }

  // ── Sección: nombre del equipo ──

  Widget _buildNameSection() {
    return _buildSectionCard(
      icon: Icons.edit_rounded,
      title: 'Nombre del equipo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          GlassTextField(
            controller: _nameController,
            hint: 'Nombre del equipo',
            icon: Icons.groups_rounded,
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: _isSavingName ? 'Guardando...' : 'Guardar nombre',
            icon: Icons.save_rounded,
            isLoading: _isSavingName,
            variant: GradientButtonVariant.ocean,
            size: GradientButtonSize.small,
            onPressed: _saveName,
          ),
        ],
      ),
    );
  }

  // ── Sección: añadir miembros ──

  Widget _buildAddMemberSection() {
    return _buildSectionCard(
      icon: Icons.person_add_rounded,
      title: 'Añadir miembros',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GlassTextField(
                  controller: _memberController,
                  hint: '@nickname',
                  icon: Icons.person_search_rounded,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 52,
                height: 52,
                child: _isSearching
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
                        onPressed: _addMember,
                      ),
              ),
            ],
          ),
          if (_memberError != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFFF4D6A), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _memberError!,
                    style: const TextStyle(
                      color: Color(0xFFFF4D6A),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Sección: lista de miembros ──

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Miembros del equipo',
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
        const SizedBox(height: 4),
        Text(
          'Usa el toggle para cambiar el rol de administrador',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 14),

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
            final isCreator = uid == _team.creatorId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TeamMemberTile(
                displayName: user != null
                    ? '${user.name} ${user.lastName}'.trim()
                    : 'Usuario desconocido',
                nickname: user?.nickname ?? uid,
                photoUrl: user?.photoUrl,
                isAdmin: isAdmin,
                showAdminBadge: false,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toggle admin
                    ToggleSwitch(
                      value: isAdmin,
                      onChanged: (_) => _toggleAdmin(uid),
                      color: ToggleSwitchColor.violet,
                      enabled: !isCreator,
                    ),
                    const SizedBox(width: 8),
                    // Botón eliminar
                    if (!isCreator)
                      GestureDetector(
                        onTap: () => _removeMember(uid),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF4D6A).withValues(alpha: 0.12),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFFFF4D6A),
                            size: 16,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 32), // placeholder
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ── Zona de peligro ──

  Widget _buildDangerZone() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFFFF4D6A).withValues(alpha: 0.06),
            border: Border.all(
              color: const Color(0xFFFF4D6A).withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFFF4D6A), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Zona de peligro',
                    style: TextStyle(
                      color: Color(0xFFFF4D6A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Eliminar el equipo de forma permanente. Esta acción no se puede deshacer.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              GradientButton(
                label: _isDeleting ? 'Eliminando...' : 'Eliminar equipo',
                icon: Icons.delete_forever_rounded,
                isLoading: _isDeleting,
                variant: GradientButtonVariant.sunset,
                size: GradientButtonSize.medium,
                onPressed: _deleteTeam,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper: card de sección ──

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFF00D4FF), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
