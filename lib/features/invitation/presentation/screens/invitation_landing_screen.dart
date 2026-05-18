import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/getColors/getter_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/glow_orb.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../inscription/screen/preinscription_screen.dart';
import '../../../tournament/data/model/app_tournament.dart';
import '../../domain/models/invitation_validation_result.dart';
import '../controllers/invitation_controller.dart';

// ════════════════════════════════════════════════════════════════════════════
//  INVITATION LANDING SCREEN
//
//  Pantalla de aterrizaje para un enlace de invitación a torneo privado.
//
//  Flujo:
//    1. Spinner mientras se valida el token
//    2. Error específico si el token es inválido / expirado / revocado / etc.
//    3. Información del torneo + CTA hacia PreinscriptionScreen si es válido
//
//  NUNCA registra al usuario automáticamente.
//  NUNCA expone errores crudos de Firestore.
// ════════════════════════════════════════════════════════════════════════════

class InvitationLandingScreen extends StatefulWidget {
  const InvitationLandingScreen({super.key, required this.token});

  /// Token de invitación (= ID del documento en `tournamentInvitations`).
  final String token;

  @override
  State<InvitationLandingScreen> createState() =>
      _InvitationLandingScreenState();
}

class _InvitationLandingScreenState extends State<InvitationLandingScreen>
    with SingleTickerProviderStateMixin {
  late final InvitationController _ctrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = InvitationController(token: widget.token)..addListener(_rebuild);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _ctrl.validate().then((_) {
      if (mounted) _fadeCtrl.forward();
    });
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_rebuild)
      ..dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fondo ───────────────────────────────────────────────────
          const _Background(),

          // ── Orbs de ambiente ────────────────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: GlowOrb(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
              size: 260,
            ),
          ),
          Positioned(
            bottom: 100,
            left: -70,
            child: GlowOrb(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.18),
              size: 220,
            ),
          ),

          // ── Contenido ───────────────────────────────────────────────
          SafeArea(
            child: _ctrl.state == InvitationLoadState.loading &&
                    _ctrl.result == null
                ? const _LoadingView()
                : FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildBody(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final result = _ctrl.result;

    return switch (result) {
      null => const _LoadingView(),
      InvitationValid(:final tournament) => _ValidView(
        tournament: tournament,
        onGoToTournament: () => _navigateToTournament(tournament),
      ),
      InvitationNotFound() => const _ErrorView(
        icon: Icons.link_off_rounded,
        title: 'Enlace no válido',
        message:
            'Este enlace de invitación no existe o no es válido. Pide al organizador un nuevo enlace.',
      ),
      InvitationRevoked() => const _ErrorView(
        icon: Icons.block_rounded,
        title: 'Invitación revocada',
        message:
            'El organizador ha cancelado este enlace de invitación. Contacta con él para obtener uno nuevo.',
      ),
      InvitationExpired() => const _ErrorView(
        icon: Icons.timer_off_rounded,
        title: 'Enlace expirado',
        message:
            'Este enlace de invitación ha caducado (validez de 30 días). Pide al organizador que genere uno nuevo.',
      ),
      InvitationTournamentNotFound() => const _ErrorView(
        icon: Icons.search_off_rounded,
        title: 'Torneo no encontrado',
        message:
            'El torneo asociado a este enlace ya no está disponible.',
      ),
      InvitationTournamentFull(:final tournament) => _FullView(
        tournament: tournament,
      ),
    };
  }

  void _navigateToTournament(AppTournament tournament) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Usuario no autenticado → login y luego volver aquí
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => LoginScreen(
            // AuthController por defecto; al autenticarse AuthGate
            // devolverá AppShell. Volvemos manualmente.
          ),
        ),
      ).then((_) {
        // Después del login (si tuvo éxito), reintentamos la navegación
        if (!mounted) return;
        final newUser = FirebaseAuth.instance.currentUser;
        if (newUser != null) _navigateToTournament(tournament);
      });
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PreinscriptionScreen(tournament: tournament),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  VISTAS INTERNAS
// ════════════════════════════════════════════════════════════════════════════

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.8,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Verificando invitación…',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vista de error genérico ───────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFFF4D6A), Color(0xFFFF6B9D)],
            ).createShader(b),
            child: Icon(icon, size: 72, color: Colors.white),
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
            ).createShader(b),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: Colors.white.withValues(alpha: 0.55),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 36),
          GradientButton(
            label: 'Volver',
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.maybePop(context),
            variant: GradientButtonVariant.ocean,
            size: GradientButtonSize.medium,
          ),
        ],
      ),
    );
  }
}

// ── Vista: torneo lleno ───────────────────────────────────────────────────

class _FullView extends StatelessWidget {
  const _FullView({required this.tournament});

  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFFFB347), Color(0xFFFF6B00)],
            ).createShader(b),
            child: const Icon(
              Icons.groups_rounded,
              size: 72,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
            ).createShader(b),
            child: const Text(
              'Torneo completo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tournament.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFFFB347),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Este torneo ha alcanzado su capacidad máxima '
            '(${tournament.maxParticipants} participantes). '
            'No es posible inscribirse en este momento.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: Colors.white.withValues(alpha: 0.55),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 36),
          GradientButton(
            label: 'Volver',
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.maybePop(context),
            variant: GradientButtonVariant.ocean,
            size: GradientButtonSize.medium,
          ),
        ],
      ),
    );
  }
}

// ── Vista válida ──────────────────────────────────────────────────────────

class _ValidView extends StatelessWidget {
  const _ValidView({
    required this.tournament,
    required this.onGoToTournament,
  });

  final AppTournament tournament;
  final VoidCallback onGoToTournament;

  String _formatDate(DateTime date) =>
      DateFormat("dd 'de' MMMM, yyyy", 'es').format(date);

  @override
  Widget build(BuildContext context) {
    final primaryColor = sportColor(tournament.sport);
    final occupancy = tournament.participantCount / tournament.maxParticipants;
    final occupColor = occupancyColor(occupancy);
    final isFull = tournament.participantCount >= tournament.maxParticipants;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── AppBar manual ──────────────────────────────────────────
          Row(
            children: [
              _GlassBack(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Invitación privada',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Portada / badge deporte ────────────────────────────────
          _CoverCard(tournament: tournament, primaryColor: primaryColor),
          const SizedBox(height: 24),

          // ── Nombre + organizador ───────────────────────────────────
          Text(
            tournament.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          if (tournament.organizerDisplayName != null &&
              tournament.organizerDisplayName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 6),
                Text(
                  'Organizado por ${tournament.organizerDisplayName}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // ── Info chips ────────────────────────────────────────────
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.sports_rounded,
                label: tournament.sport.label,
                color: primaryColor,
              ),
              _InfoChip(
                icon: Icons.calendar_month_rounded,
                label: _formatDate(tournament.scheduledAt),
                color: const Color(0xFFA855F7),
              ),
              _InfoChip(
                icon: Icons.location_on_rounded,
                label: tournament.location.length > 28
                    ? '${tournament.location.substring(0, 28)}…'
                    : tournament.location,
                color: const Color(0xFF22C55E),
              ),
              _InfoChip(
                icon: Icons.people_alt_rounded,
                label:
                    '${tournament.participantCount} / ${tournament.maxParticipants}',
                color: occupColor,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Descripción ───────────────────────────────────────────
          if (tournament.description.isNotEmpty) ...[
            Text(
              tournament.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 14.5,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Aviso: no se registra automáticamente ─────────────────
          _DisclaimerBanner(),
          const SizedBox(height: 28),

          // ── CTA principal ─────────────────────────────────────────
          GradientButton(
            label: isFull
                ? 'Torneo completo'
                : 'Ver torneo e inscribirme',
            icon: isFull
                ? Icons.block_rounded
                : Icons.emoji_events_rounded,
            onPressed: isFull ? null : onGoToTournament,
            variant: isFull
                ? GradientButtonVariant.danger
                : GradientButtonVariant.violet,
            size: GradientButtonSize.large,
          ),
          const SizedBox(height: 12),
          GradientButton(
            label: 'Volver',
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.maybePop(context),
            variant: GradientButtonVariant.ocean,
            size: GradientButtonSize.medium,
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────

class _GlassBack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({required this.tournament, required this.primaryColor});

  final AppTournament tournament;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final uri = tournament.portadaUrl?.trim();
    final hasUrl = uri != null && uri.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: hasUrl
                ? Image.network(
                    uri,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => _placeholder(),
                  )
                : _placeholder(),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          // Candado de "privado"
          Positioned(
            top: 14,
            right: 14,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB347).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFB347).withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        color: Color(0xFFFFB347),
                        size: 12,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'PRIVADO',
                        style: TextStyle(
                          color: Color(0xFFFFB347),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withValues(alpha: 0.25),
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.emoji_events_rounded,
            size: 64,
            color: primaryColor.withValues(alpha: 0.5),
          ),
        ),
      );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Color(0xFF6C63FF),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aún no estás inscrito. Confirma tu inscripción en el siguiente paso. '
                  'Abrir este enlace no te registra automáticamente.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
