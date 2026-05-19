import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../core/getColors/getter_colors.dart';
import '../../../core/widgets/bar_small_botton.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../database/team/models/app_team.dart';
import '../../../features/tournament/data/model/app_tournament.dart';
import '../../../features/tournament/data/model/enums_tournament.dart';
import '../../../features/profile/presentation/screens/profile_teams_tab.dart';
import '../presentation/controllers/inscription_controller.dart';
import '../presentation/widgets/dynamic_registration_field.dart';

// ════════════════════════════════════════════════════════════════
//  INSCRIPTION SCREEN
//  Formulario de inscripción a torneo (individual o por equipos).
// ════════════════════════════════════════════════════════════════

class InscriptionScreen extends StatefulWidget {
  final AppTournament tournament;
  const InscriptionScreen({super.key, required this.tournament});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  late final InscriptionController _ctrl;

  static const Color _bg = Color(0xFF0F172A);
  static const Color _accent = Color(0xFF6C63FF);
  static const Color _error = Color(0xFFFF4D6A);

  @override
  void initState() {
    super.initState();
    _ctrl = InscriptionController(tournament: widget.tournament);
    _ctrl.addListener(_onControllerChange);
    _ctrl.initialize();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerChange);
    _ctrl.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (!mounted) return;
    setState(() {});
    if (_ctrl.submitState == InscriptionSubmitState.success) {
      _showSuccessAndPop();
    } else if (_ctrl.submitState == InscriptionSubmitState.error &&
        _ctrl.submitError != null) {
      _showErrorSnackbar(_ctrl.submitError!);
      _ctrl.resetSubmitState();
    }
  }

  void _showSuccessAndPop() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(
        isJoinRequest: _ctrl.submittedJoinRequest,
        onClose: () {
          Navigator.of(context).pop(); // cerrar dialog
          Navigator.of(context).pop(); // volver a preinscription
          Navigator.of(context).pop(); // volver al listado
        },
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BarSmallBotton(
          icon: Icons.arrow_back_ios_new,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          BarSmallBotton(
            icon: Icons.close_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
        ],
        title: const Text(
          'Inscripción',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_ctrl.loadState) {
      case InscriptionLoadState.loading:
      case InscriptionLoadState.idle:
        return const Center(
          child: CircularProgressIndicator(strokeWidth: 2.5, color: _accent),
        );
      case InscriptionLoadState.error:
        return _ErrorState(message: _ctrl.loadError ?? 'Error desconocido');
      case InscriptionLoadState.loaded:
        return _buildForm();
    }
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 0. Portada hero
          _CoverHero(tournament: widget.tournament),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // 1. Torneo info chip
                _TournamentChip(tournament: widget.tournament),
                const SizedBox(height: 24),

                // 2. Información del usuario
                _SectionTitle(label: 'Tus datos', icon: Icons.person_rounded),
                const SizedBox(height: 12),
                _UserInfoCard(user: _ctrl.currentUser!),
                const SizedBox(height: 28),

                // 3. Tipo de inscripción (equipo si aplica)
                if (_ctrl.isTeamTournament) ...[
                  _SectionTitle(
                    label: 'Seleccionar equipo',
                    icon: Icons.groups_rounded,
                  ),
                  const SizedBox(height: 4),
                  _TeamRequirementHint(tournament: widget.tournament),
                  const SizedBox(height: 12),
                  _TeamSelector(ctrl: _ctrl),
                  const SizedBox(height: 28),
                ],

                // 4. Categorías
                if (_ctrl.hasCategories) ...[
                  _SectionTitle(
                    label: 'Categoría',
                    icon: Icons.category_rounded,
                  ),
                  const SizedBox(height: 12),
                  _CategorySelector(ctrl: _ctrl),
                  const SizedBox(height: 28),
                ],

                if (_ctrl.hasAdditionalFields) ...[
                  _SectionTitle(
                    label: 'Datos adicionales',
                    icon: Icons.dynamic_form_rounded,
                  ),
                  const SizedBox(height: 12),
                  _AdditionalFieldsSection(ctrl: _ctrl),
                  const SizedBox(height: 28),
                ],

                const SizedBox(height: 20),

                // 5. Botón de confirmación (dentro del flujo)
                _SubmitButton(ctrl: _ctrl),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sección: torneo chip ───────────────────────────────────────────────────

class _TournamentChip extends StatelessWidget {
  const _TournamentChip({required this.tournament});
  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFF6C63FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tournament.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tournament.sport.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section title ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6C63FF)),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

// ── User info card ─────────────────────────────────────────────────────────

class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({required this.user});
  final dynamic user; // AppUser

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              _InfoRow(
                label: 'Nickname',
                value: '@${user.nickname}',
                icon: Icons.alternate_email_rounded,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Nombre',
                value: '${user.name} ${user.lastName}',
                icon: Icons.badge_rounded,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Email',
                value: user.email,
                icon: Icons.email_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white.withValues(alpha: 0.06),
          ),
          child: Icon(
            icon,
            size: 15,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.lock_outline_rounded,
          size: 13,
          color: Color(0xFF6C63FF),
        ),
      ],
    );
  }
}

// ── Team requirement hint ──────────────────────────────────────────────────

class _TeamRequirementHint extends StatelessWidget {
  const _TeamRequirementHint({required this.tournament});
  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    final required = tournament.membersPerTeam;
    if (required == null || required <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 13,
            color: Color(0xFFFFB347),
          ),
          const SizedBox(width: 6),
          Text(
            'Este torneo requiere equipos de $required miembros.',
            style: const TextStyle(color: Color(0xFFFFB347), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Team selector ──────────────────────────────────────────────────────────

class _TeamSelector extends StatelessWidget {
  const _TeamSelector({required this.ctrl});
  final InscriptionController ctrl;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppTeam>>(
      stream: ctrl.watchUserTeams(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF6C63FF),
            ),
          );
        }

        final teams = snapshot.data ?? [];

        if (teams.isEmpty) {
          return _NoTeamsState(ctrl: ctrl);
        }

        return Column(
          children: [
            // Selector de equipo
            ...teams.map(
              (team) => _TeamTile(
                team: team,
                isSelected: ctrl.selectedTeam?.id == team.id,
                tournament: ctrl.tournament,
                onTap: () => ctrl.selectTeam(team),
              ),
            ),

            const SizedBox(height: 12),

            // Botón crear equipo
            _CreateTeamButton(),
          ],
        );
      },
    );
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({
    required this.team,
    required this.isSelected,
    required this.tournament,
    required this.onTap,
  });
  final AppTeam team;
  final bool isSelected;
  final AppTournament tournament;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final required = tournament.membersPerTeam ?? 0;
    final hasEnough = required <= 0 || team.members.length >= required;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? const Color(0xFF6C63FF).withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6C63FF).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.07),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar equipo
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              ),
              child: team.photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        team.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) => const Icon(
                          Icons.groups_rounded,
                          color: Color(0xFF6C63FF),
                          size: 22,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.groups_rounded,
                      color: Color(0xFF6C63FF),
                      size: 22,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.people_alt_rounded,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${team.members.length} miembro${team.members.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12,
                        ),
                      ),
                      if (!hasEnough && required > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                          color: Color(0xFFFF4D6A),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Necesita $required',
                          style: const TextStyle(
                            color: Color(0xFFFF4D6A),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF6C63FF),
                size: 22,
              )
            else
              Icon(
                Icons.radio_button_unchecked_rounded,
                color: Colors.white.withValues(alpha: 0.2),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _NoTeamsState extends StatelessWidget {
  const _NoTeamsState({required this.ctrl});
  final InscriptionController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 48,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'No tienes equipos',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Crea un equipo para poder inscribirte en este torneo.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _CreateTeamButton(),
        ],
      ),
    );
  }
}

class _CreateTeamButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _TeamCreationPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
          ),
          color: const Color(0xFF6C63FF).withValues(alpha: 0.07),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_add_rounded, color: Color(0xFF6C63FF), size: 18),
            SizedBox(width: 8),
            Text(
              'Crear equipo',
              style: TextStyle(
                color: Color(0xFF6C63FF),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Página auxiliar que muestra el tab de equipos del perfil para crear uno.
class _TeamCreationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: BarSmallBotton(
          icon: Icons.arrow_back_ios_new,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Mis equipos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      body: const ProfileTeamsTab(),
    );
  }
}

// ── Category selector ──────────────────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.ctrl});
  final InscriptionController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: ctrl.tournament.categories.map((cat) {
        final isSelected = ctrl.selectedCategoryId == cat;
        return GestureDetector(
          onTap: () => ctrl.selectCategory(isSelected ? null : cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: isSelected
                  ? const Color(0xFFA855F7).withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFA855F7).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.07),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isSelected
                      ? const Color(0xFFA855F7)
                      : Colors.white.withValues(alpha: 0.25),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  cat,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AdditionalFieldsSection extends StatelessWidget {
  const _AdditionalFieldsSection({required this.ctrl});

  final InscriptionController ctrl;

  @override
  Widget build(BuildContext context) {
    final fields = ctrl.registrationForm.activeFields;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            DynamicRegistrationField(
              field: fields[i],
              value: ctrl.registrationValues[fields[i].id],
              errorText: ctrl.registrationErrors[fields[i].id],
              onChanged: (value) =>
                  ctrl.updateRegistrationValue(fields[i].id, value),
            ),
            if (i < fields.length - 1) ...[
              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              const SizedBox(height: 16),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Sección: Cover Hero ───────────────────────────────────────────────────

class _CoverHero extends StatelessWidget {
  const _CoverHero({required this.tournament});
  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    final uri = tournament.portadaUrl?.trim();
    final hasUrl = uri != null && uri.isNotEmpty;

    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasUrl)
            Image.network(
              uri,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(),
            )
          else
            _buildPlaceholder(),

          // Overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.6, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                    const Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1E293B),
      child: Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          size: 48,
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}

// ── Submit Button ──────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.ctrl});
  final InscriptionController ctrl;

  @override
  Widget build(BuildContext context) {
    final isLoading = ctrl.submitState == InscriptionSubmitState.submitting;
    final requiresApproval =
        ctrl.tournament.accessType != TournamentAccessType.publicOpen;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Validation hints
        if (ctrl.loadState == InscriptionLoadState.loaded) ...[
          if (ctrl.isTeamTournament && ctrl.selectedTeam == null)
            _HintRow(
              text: 'Selecciona un equipo para continuar',
              color: const Color(0xFFFFB347),
            ),
          if (ctrl.isTeamTournament && ctrl.teamValidationError != null)
            _HintRow(
              text: ctrl.teamValidationError!,
              color: const Color(0xFFFF4D6A),
            ),
          if (ctrl.hasCategories && ctrl.selectedCategoryId == null)
            _HintRow(
              text: 'Selecciona una categoría para continuar',
              color: const Color(0xFFFFB347),
            ),
          if (ctrl.registrationErrors.isNotEmpty)
            _HintRow(
              text: 'Completa los campos adicionales obligatorios.',
              color: const Color(0xFFFF4D6A),
            ),
          const SizedBox(height: 12),
        ],

        GradientButton(
          label: isLoading
              ? (requiresApproval ? 'Enviando...' : 'Inscribiendo...')
              : (requiresApproval
                    ? 'Solicitar inscripcion'
                    : 'Confirmar inscripción'),
          icon: isLoading
              ? null
              : (requiresApproval
                    ? Icons.pending_actions_rounded
                    : Icons.how_to_reg_rounded),
          isLoading: isLoading,
          variant: GradientButtonVariant.forest,
          size: GradientButtonSize.large,
          onPressed: ctrl.canSubmit ? () => ctrl.confirmEnrollment() : null,
        ),
      ],
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Color(0xFFFF4D6A),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Success dialog ─────────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({required this.onClose, required this.isJoinRequest});
  final VoidCallback onClose;
  final bool isJoinRequest;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                border: Border.all(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF22C55E),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Inscripción enviada!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Tu solicitud ha sido registrada correctamente. Recibirás confirmación próximamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: 'Aceptar',
              onPressed: onClose,
              variant: GradientButtonVariant.forest,
              size: GradientButtonSize.medium,
            ),
          ],
        ),
      ),
    );
  }
}
