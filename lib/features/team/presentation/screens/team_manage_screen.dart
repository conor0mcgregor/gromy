import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/getColors/getter_colors.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/glow_orb.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/toggle_switch.dart';
import '../../../../database/team/models/app_team.dart';
import '../../../../database/team/services/firestore_team_service.dart';
import '../../data/services/team_storage_service.dart';
import '../../../notifications/data/repository/team_invitation_repository_impl.dart';
import '../../../notifications/domain/entities/pending_team_invitation.dart';
import '../../../notifications/domain/use_cases/team_invitation_use_cases.dart';
import '../../../user/data/models/app_user.dart';
import '../../../user/data/services/firestore_user_service.dart';
import '../../../profile/presentation/screens/other_user_profile_screen.dart';
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
  final _storageService = TeamStorageService();
  final _teamInvitationRepository = CloudFunctionTeamInvitationRepository();
  final _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _memberController = TextEditingController();

  String? _memberError;
  bool _isSearching = false;
  bool _isSavingName = false;
  bool _isUploadingPhoto = false;
  bool _isDeleting = false;

  final Map<String, AppUser?> _userCache = {};
  bool _isLoadingUsers = true;
  bool _isLoadingPendingInvitations = true;
  List<PendingTeamInvitation> _pendingInvitations = [];
  StreamSubscription<List<PendingTeamInvitation>>? _pendingInvitationsSub;

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
    _watchPendingInvitations();
  }

  @override
  void dispose() {
    _pendingInvitationsSub?.cancel();
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

  void _watchPendingInvitations() {
    _pendingInvitationsSub?.cancel();
    final watchUseCase = WatchPendingTeamInvitationsUseCase(
      _teamInvitationRepository,
    );
    _pendingInvitationsSub = watchUseCase(teamId: _team.id).listen(
      (invitations) {
        if (!mounted) return;
        setState(() {
          _pendingInvitations = invitations;
          _isLoadingPendingInvitations = false;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _isLoadingPendingInvitations = false);
      },
    );
  }

  // ── Acciones ───────────────────────────────────────────────────────────────

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName.length < 3) {
      _showSnackBar(
        'El nombre debe tener al menos 3 caracteres.',
        isError: true,
      );
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

  Future<void> _changePhoto() async {
    FocusScope.of(context).unfocus();
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      final photoUrl = await _storageService.uploadTeamPhoto(
        teamId: _team.id,
        imageFile: picked,
      );

      final updated = _team.copyWith(photoUrl: photoUrl);
      await _teamService.updateTeam(updated);
      setState(() => _team = updated);
      _showSnackBar('Foto actualizada.', isError: false);
    } on TeamStorageException catch (e) {
      _showSnackBar('Error al subir la foto: ${e.message}', isError: true);
    } catch (_) {
      _showSnackBar('No se pudo cambiar la foto.', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _addMember() async {
    final raw = _memberController.text.trim();
    if (raw.isEmpty) {
      setState(() => _memberError = 'Escribe un nickname, email o UID.');
      return;
    }

    setState(() {
      _isSearching = true;
      _memberError = null;
    });

    try {
      // Buscar usuario por nickname, email o UID
      AppUser? user;
      final cleanRaw = raw.startsWith('@') ? raw.substring(1) : raw;
      if (cleanRaw.contains('@')) {
        user = await _userService.getUserByEmail(cleanRaw);
      } else {
        user = await _userService.getUserByNickname(cleanRaw);
        user ??= await _userService.getUser(cleanRaw);
      }

      if (user == null) {
        setState(() => _memberError = 'No existe un usuario con esos datos.');
        return;
      }
      final invitedUser = user;

      if (_team.members.contains(invitedUser.uid)) {
        setState(() => _memberError = 'Este usuario ya es miembro del equipo.');
        return;
      }

      // Enviar invitación en lugar de añadir directamente
      if (_pendingInvitations.any((inv) => inv.userId == invitedUser.uid)) {
        setState(
          () =>
              _memberError = 'Este usuario ya tiene una invitacion pendiente.',
        );
        return;
      }

      final sendUseCase = SendTeamInvitationUseCase(_teamInvitationRepository);
      await sendUseCase(teamId: _team.id, invitedUserId: invitedUser.uid);

      _memberController.clear();
      _showSnackBar(
        'Invitación enviada a @${invitedUser.nickname}. Será miembro cuando la acepte.',
        isError: false,
      );
    } on Exception catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _memberError = msg);
    } catch (_) {
      setState(() => _memberError = 'Error al enviar la invitación.');
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

  Future<void> _cancelPendingInvitation(
    PendingTeamInvitation invitation,
  ) async {
    final confirm = await _showConfirmDialog(
      '¿Cancelar invitación?',
      'Este usuario dejará de tener una invitación pendiente para entrar en el equipo.',
    );
    if (!confirm) return;

    try {
      final cancelUseCase = CancelTeamInvitationUseCase(
        _teamInvitationRepository,
      );
      await cancelUseCase(notificationId: invitation.notificationId);
      _showSnackBar('Invitación cancelada.', isError: false);
    } on Exception catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _showSnackBar(msg, isError: true);
    } catch (_) {
      _showSnackBar('No se pudo cancelar la invitación.', isError: true);
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
              color: isDangerous
                  ? const Color(0xFFFF4D6A)
                  : const Color(0xFF00D4FF),
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
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
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
        backgroundColor: isError
            ? const Color(0xFFFF4D6A)
            : const Color(0xFF22C55E),
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
                              _buildPhotoSection(),
                              const SizedBox(height: 28),
                              _buildNameSection(),
                              const SizedBox(height: 28),
                              _buildAddMemberSection(),
                              const SizedBox(height: 28),
                              _buildPendingInvitationsSection(),
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

  // ── Sección: foto del equipo ──

  Widget _buildPhotoSection() {
    final hasPhoto = _team.photoUrl != null && _team.photoUrl!.isNotEmpty;
    final initial = _team.name.isNotEmpty ? _team.name[0].toUpperCase() : '?';

    return _buildSectionCard(
      icon: Icons.camera_alt_rounded,
      title: 'Foto del equipo',
      child: Column(
        children: [
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _isUploadingPhoto ? null : _changePhoto,
              child: Stack(
                children: [
                  Container(
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
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
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
                  ),
                  // Overlay de cámara
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                        ),
                        border: Border.all(
                          color: const Color(0xFF0A0A1A),
                          width: 2.5,
                        ),
                      ),
                      child: _isUploadingPhoto
                          ? const Padding(
                        padding: EdgeInsets.all(6),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _isUploadingPhoto
                  ? 'Subiendo foto...'
                  : 'Toca la imagen para cambiarla',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
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
                    : ElevatedButton(
                        onPressed: _addMember,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(
                            12,
                          ), // Ajusta el tamaño del botón
                          shadowColor: const Color(0xFF0DFF00),
                          elevation: 2,
                          backgroundColor: Colors.white,
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: Colors.black,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
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
                    'Las invitaciones pendientes se muestran aparte y no cuentan como miembros reales hasta que se aceptan.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.58),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_memberError != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFFF4D6A),
                  size: 14,
                ),
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

  Widget _buildPendingInvitationsSection() {
    if (_isLoadingPendingInvitations) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invitaciones pendientes',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      );
    }

    if (_pendingInvitations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 36,
              color: Colors.white.withValues(alpha: 0.18),
            ),
            const SizedBox(height: 10),
            Text(
              'No hay invitaciones pendientes',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cuando invites a alguien aparecerá aquí hasta que acepte.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.26),
                fontSize: 12.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Invitaciones pendientes',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            Text(
              '${_pendingInvitations.length}',
              style: TextStyle(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Estas personas todavía no pertenecen al equipo. La invitación debe aceptarse antes de contar como miembro real.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 14),
        ..._pendingInvitations.map(
          (invitation) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TeamMemberTile(
              displayName: invitation.displayName,
              nickname: invitation.nickname,
              photoUrl: invitation.photoUrl,
              muted: true,
              statusLabel: 'Pendiente',
              statusColor: const Color(0xFFF59E0B),
              trailing: GestureDetector(
                onTap: () => _cancelPendingInvitation(invitation),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFFF59E0B),
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

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
          'Solo aquí aparecen los miembros reales que ya forman parte del equipo.',
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OtherUserProfileScreen(targetUid: uid),
                    ),
                  );
                },
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
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFF4D6A),
                    size: 20,
                  ),
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
                variant: GradientButtonVariant.danger,
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
