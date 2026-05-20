import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/getColors/getter_colors.dart';
import '../../../core/widgets/bar_small_botton.dart';
import '../../../core/widgets/expandable_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/static_location_map.dart';
import '../../brackets/presentation/widgets/brankets_section.dart';
import '../../participants/presentation/widgets/participants_section.dart';
import '../../tournament/data/model/app_tournament.dart';
import '../../../../database/participant/models/app_participant.dart';
import '../../../../database/team/models/app_team.dart';
import '../domain/models/enrollment_status.dart';
import '../presentation/controllers/preinscription_controller.dart';
import '../../events/presentation/controllers/favorites_controller.dart';
import '../../profile/presentation/screens/other_user_profile_screen.dart';
import 'inscription_screen.dart';

// ════════════════════════════════════════════════════════════════
//  PREINSCRIPTION SCREEN
//
//  Vista completa que muestra toda la información relevante del
//  torneo antes de que el usuario se inscriba.
//
//  Orden de secciones:
//    1. Portada hero (imagen + overlay)
//    2. Información básica (nombre, organizador, descripción)
//    3. Participantes (barra visual)
//    4. Fechas (ExpandableCard)
//    5. Descripción completa (ExpandableCard)
//    6. Contactos (ExpandableCard)
//    7. Ubicación (StaticLocationMap)
//    8. Botón de inscripción (sticky / fixed)
// ════════════════════════════════════════════════════════════════

class PreinscriptionScreen extends StatefulWidget {
  final AppTournament tournament;

  // Estos campos se mantienen para compatibilidad con navegación directa (ej. desde mis inscripciones)
  final bool? initialIsEnrolled;
  final AppParticipant? initialParticipant;
  final AppTeam? initialEnrolledTeam;
  final bool? initialCanCancelTeam;

  const PreinscriptionScreen({
    super.key,
    required this.tournament,
    this.initialIsEnrolled,
    this.initialParticipant,
    this.initialEnrolledTeam,
    this.initialCanCancelTeam,
  });

  @override
  State<PreinscriptionScreen> createState() => _PreinscriptionScreenState();
}

class _PreinscriptionScreenState extends State<PreinscriptionScreen> {
  late final PreinscriptionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PreinscriptionController(tournamentId: widget.tournament.id);

    // Si ya tenemos los datos (navegación desde "Mis torneos"), los usamos
    if (widget.initialIsEnrolled != null) {
      _controller.state = PreinscriptionState.loaded;
      _controller.enrollmentStatus = EnrollmentStatus(
        isEnrolled: widget.initialIsEnrolled!,
        participant: widget.initialParticipant,
        enrolledTeam: widget.initialEnrolledTeam,
        canCancel: widget.initialCanCancelTeam ?? true,
      );
    } else {
      // Si no, los buscamos (navegación desde Home)
      _controller.checkEnrollment();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final status = _controller.enrollmentStatus;
        final uid = FirebaseAuth.instance.currentUser?.uid;
        final isTournamentAdmin =
            uid != null &&
                (widget.tournament.organizerUid == uid ||
                    widget.tournament.adminIds.contains(uid));

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          extendBodyBehindAppBar: true,

          // ── AppBar transparente con botón back ──
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: _BackButton(),
            actions: [
              _FavoriteButton(tournament: widget.tournament),
              const SizedBox(width: 8),
              _ShareButton(),
              const SizedBox(width: 8),
            ],
          ),

          // ── Botón de inscripción fijo ──
          bottomNavigationBar: _controller.state == PreinscriptionState.loading
              ? const _LoadingBottomBar()
              : _StickyEnrollBar(
            tournament: widget.tournament,
            isEnrolled: status.isEnrolled,
            onCancelInscription: status.isEnrolled
                ? _controller.cancelInscription
                : null,
            enrolledTeam: status.enrolledTeam,
            canCancelTeam: status.canCancel,
          ),

          // ── Contenido scrollable ──
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Portada hero
                _CoverHero(tournament: widget.tournament),

                // Contenido con padding
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // 2. Información básica
                      _TournamentHeader(tournament: widget.tournament),
                      const SizedBox(height: 28),

                      // 3. Participantes
                      ParticipantsSection(tournament: widget.tournament),
                      const SizedBox(height: 20),

                      BracketsSection(
                        tournamentId: widget.tournament.id,
                        isAdmin: isTournamentAdmin,
                      ),
                      const SizedBox(height: 16),

                      // 4. Fechas
                      _DatesSection(tournament: widget.tournament),
                      const SizedBox(height: 16),

                      // 5. Descripción completa
                      _DescriptionSection(tournament: widget.tournament),
                      const SizedBox(height: 16),

                      // 6. Contactos
                      _ContactsSection(tournament: widget.tournament),
                      const SizedBox(height: 24),

                      // 7. Ubicación
                      _LocationSection(tournament: widget.tournament),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoadingBottomBar extends StatelessWidget {
  const _LoadingBottomBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(color: Color(0xFF0F172A)),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  1. COVER HERO
// ════════════════════════════════════════════════════════════════

class _CoverHero extends StatelessWidget {
  const _CoverHero({required this.tournament});
  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    final uri = tournament.portadaUrl?.trim();
    final hasUrl = uri != null && uri.isNotEmpty;

    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de fondo
          if (hasUrl)
            Image.network(
              uri,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              loadingBuilder: (_, child, progress) =>
              progress == null ? child : _buildPlaceholder(),
              errorBuilder: (_, e, s) => _buildPlaceholder(),
            )
          else
            _buildPlaceholder(),

          // Overlay degradado inferior
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.4, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    const Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
          ),

          // Badge deporte (esquina inferior izquierda)
          Positioned(
            bottom: 16,
            left: 20,
            child: _SportBadge(sport: tournament.sport.label),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C63FF).withValues(alpha: 0.25),
            const Color(0xFF0F172A),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.emoji_events_rounded,
          size: 72,
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  SPORT BADGE
// ════════════════════════════════════════════════════════════════

class _SportBadge extends StatelessWidget {
  const _SportBadge({required this.sport});
  final String sport;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF6C63FF);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sport.toUpperCase(),
                style: const TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  2. TOURNAMENT HEADER — nombre, organizador, descripción corta
// ════════════════════════════════════════════════════════════════

class _TournamentHeader extends StatelessWidget {
  const _TournamentHeader({required this.tournament});
  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre
        Text(
          tournament.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),

        // Chip organizador
        if (tournament.organizerDisplayName != null &&
            tournament.organizerDisplayName!.isNotEmpty)
          _OrganizerChip(
            name: tournament.organizerDisplayName!,
            organizerUid: tournament.organizerUid,
          ),

        if (tournament.organizerDisplayName != null &&
            tournament.organizerDisplayName!.isNotEmpty)
          const SizedBox(height: 14),

        // Descripción breve
        if (tournament.description.isNotEmpty)
          Text(
            tournament.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14.5,
              height: 1.55,
            ),
          ),
      ],
    );
  }
}

class _OrganizerChip extends StatelessWidget {
  const _OrganizerChip({required this.name, required this.organizerUid});
  final String name;
  final String organizerUid;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtherUserProfileScreen(targetUid: organizerUid),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_rounded,
              size: 14,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            Text(
              'Organizado por ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  3. PARTICIPANTES — barra de progreso visual
// ════════════════════════════════════════════════════════════════

// ════════════════════════════════════════════════════════════════
//  4. FECHAS — ExpandableCard
// ════════════════════════════════════════════════════════════════

class _DatesSection extends StatelessWidget {
  const _DatesSection({required this.tournament});
  final AppTournament tournament;

  String _formatDate(DateTime date) {
    return DateFormat("dd 'de' MMMM, yyyy  ·  HH:mm", 'es').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return ExpandableCard(
      title: 'Fechas del torneo',
      icon: Icons.calendar_month_rounded,
      accentColor: const Color(0xFFA855F7),
      children: [
        ExpandableInfoRow(
          label: 'Fecha del evento',
          value: _formatDate(tournament.scheduledAt),
        ),
        if (tournament.registrationDeadline != null)
          ExpandableInfoRow(
            label: 'Límite de inscripción',
            value: _formatDate(tournament.registrationDeadline!),
            valueColor: _isDeadlineClose(tournament.registrationDeadline!)
                ? const Color(0xFFFFB347)
                : null,
          ),
        if (tournament.bracketPublishDate != null)
          ExpandableInfoRow(
            label: 'Publicación de cuadros',
            value: _formatDate(tournament.bracketPublishDate!),
            showDivider: false,
          ),
        if (tournament.bracketPublishDate == null &&
            tournament.registrationDeadline == null)
          const ExpandableInfoRow(
            label: 'Más fechas',
            value: 'Pendiente de confirmar',
            showDivider: false,
          ),
      ],
    );
  }

  bool _isDeadlineClose(DateTime deadline) {
    return deadline.difference(DateTime.now()).inDays <= 3;
  }
}

// ════════════════════════════════════════════════════════════════
//  5. DESCRIPCIÓN COMPLETA — ExpandableCard
// ════════════════════════════════════════════════════════════════

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.tournament});
  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    final hasRules = tournament.allInformation.isNotEmpty;
    final hasAdditional =
        tournament.additionalInfo != null &&
            tournament.additionalInfo!.isNotEmpty;

    if (!hasRules && !hasAdditional) {
      return const SizedBox.shrink();
    }

    return ExpandableCard(
      title: 'Información completa',
      icon: Icons.article_rounded,
      accentColor: const Color(0xFF00D4FF),
      children: [
        if (hasRules) ...[
          Text(
            'Reglamento',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tournament.allInformation,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
        ],
        if (hasRules && hasAdditional) ...[
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 14),
        ],
        if (hasAdditional) ...[
          Text(
            'Información adicional',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tournament.additionalInfo!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  6. CONTACTOS — ExpandableCard
// ════════════════════════════════════════════════════════════════

class _ContactsSection extends StatelessWidget {
  const _ContactsSection({required this.tournament});
  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    final hasEmail =
        tournament.contactEmail != null && tournament.contactEmail!.isNotEmpty;
    final hasPhone =
        tournament.contactPhone != null && tournament.contactPhone!.isNotEmpty;
    final hasLinks = tournament.contactLinks.isNotEmpty;
    final hasOrganizer =
        tournament.organizerDisplayName != null &&
            tournament.organizerDisplayName!.isNotEmpty;

    // Si no hay ningún dato de contacto, no mostramos la sección
    if (!hasEmail && !hasPhone && !hasLinks && !hasOrganizer) {
      return const SizedBox.shrink();
    }

    return ExpandableCard(
      title: 'Contacto',
      icon: Icons.support_agent_rounded,
      accentColor: const Color(0xFF22C55E),
      children: [
        if (hasOrganizer)
          _ContactRow(
            icon: Icons.person_rounded,
            label: 'Organizador',
            value: tournament.organizerDisplayName!,
          ),
        if (hasEmail)
          _ContactRow(
            icon: Icons.email_rounded,
            label: 'Email',
            value: tournament.contactEmail!,
          ),
        if (hasPhone)
          _ContactRow(
            icon: Icons.phone_rounded,
            label: 'Teléfono',
            value: tournament.contactPhone!,
          ),
        if (hasLinks) ...[
          const SizedBox(height: 4),
          Text(
            'ENLACES',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          ...tournament.contactLinks.map(
                (link) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.link_rounded,
                    size: 14,
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final uri = Uri.parse(link);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      child: Text(
                        link,
                        style: const TextStyle(
                          color: Color(0xFF00D4FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF00D4FF),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: Colors.white.withValues(alpha: 0.06),
            ),
            child: Icon(
              icon,
              size: 15,
              color: Colors.white.withValues(alpha: 0.5),
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
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
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

// ════════════════════════════════════════════════════════════════
//  7. UBICACIÓN — StaticLocationMap
// ════════════════════════════════════════════════════════════════

class _LocationSection extends StatelessWidget {
  const _LocationSection({required this.tournament});
  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    final hasCoords =
        tournament.latitude != null && tournament.longitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 18,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ubicación',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),

        // Mapa
        if (hasCoords)
          StaticLocationMap(
            latitude: tournament.latitude!,
            longitude: tournament.longitude!,
            height: 360,
            zoom: 15.0,
            locationLabel: tournament.location,
          ),

        if (hasCoords) const SizedBox(height: 12),

        // Dirección en glass card
        _AddressCard(location: tournament.location),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.place_rounded,
                  color: Color(0xFF22C55E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dirección',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
}

// ════════════════════════════════════════════════════════════════
//  8. STICKY ENROLL BAR — botón fijo inferior
// ════════════════════════════════════════════════════════════════

class _StickyEnrollBar extends StatefulWidget {
  const _StickyEnrollBar({
    required this.tournament,
    this.isEnrolled = false,
    this.onCancelInscription,
    this.enrolledTeam,
    this.canCancelTeam = true,
  });
  final AppTournament tournament;
  final bool isEnrolled;
  final Future<void> Function()? onCancelInscription;
  final AppTeam? enrolledTeam;
  final bool canCancelTeam;

  @override
  State<_StickyEnrollBar> createState() => _StickyEnrollBarState();
}

class _StickyEnrollBarState extends State<_StickyEnrollBar> {
  bool _isCancelling = false;

  Future<void> _handleCancel() async {
    if (_isCancelling || widget.onCancelInscription == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          '¿Cancelar inscripción?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Seguro que quieres cancelar la inscripción? Perderás tu plaza en el torneo.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Atrás', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Confirmar',
              style: TextStyle(
                color: Color(0xFFFF4D6A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);

    try {
      await widget.onCancelInscription!();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscripción cancelada correctamente'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
        // Quitamos el Navigator.pop(context) para que la pantalla se actualice dinámicamente
        // y el usuario pueda ver el botón de "Inscribirse" de nuevo si lo desea.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar: $e'),
            backgroundColor: const Color(0xFFFF4D6A),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFull =
        widget.tournament.participantCount >= widget.tournament.maxParticipants;
    final acceptsRegistrations = widget.tournament.acceptsRegistrations;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: widget.isEnrolled
            ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.enrolledTeam != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Inscrito como: ${widget.enrolledTeam!.name}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Ya estás inscrito en este torneo',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            GradientButton(
              label: widget.canCancelTeam
                  ? (_isCancelling
                  ? 'Cancelando...'
                  : 'Cancelar inscripción')
                  : 'Solo administradores pueden cancelar',
              icon: widget.canCancelTeam
                  ? (_isCancelling
                  ? Icons.hourglass_top_rounded
                  : Icons.cancel_rounded)
                  : Icons.lock_outline_rounded,
              onPressed: (widget.canCancelTeam && !_isCancelling)
                  ? _handleCancel
                  : null,
              variant: GradientButtonVariant.danger,
              size: GradientButtonSize.large,
            ),
          ],
        )
            : GradientButton(
                label: !acceptsRegistrations
                    ? 'Inscripción no disponible'
                    : isFull
                    ? 'Torneo completo'
                    : 'Inscribirse al torneo',
                icon: !acceptsRegistrations || isFull
                    ? Icons.block_rounded
                    : Icons.how_to_reg_rounded,
                onPressed: !acceptsRegistrations || isFull
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              InscriptionScreen(tournament: widget.tournament),
                        ),
                      ),
                variant: isFull
                    ? GradientButtonVariant.sunset
                    : GradientButtonVariant.select,
                size: GradientButtonSize.large,
              ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  APPBAR WIDGETS
// ════════════════════════════════════════════════════════════════

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BarSmallBotton(
      icon: Icons.arrow_back_ios_new,
      onTap: () => Navigator.of(context).maybePop(),
    );
  }
}

class _ShareButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BarSmallBotton(
      icon: Icons.share,
      onTap: () {
        //logica compartir
      },
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  final AppTournament tournament;
  const _FavoriteButton({required this.tournament});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  late final FavoritesController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = FavoritesController();
  }

  Future<void> _toggle() async {
    setState(() => _isLoading = true);
    try {
      await _controller.toggleFavorite(widget.tournament.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar en favoritos: $e'),
            backgroundColor: const Color(0xFFFF4D6A),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _controller.isFavorite(widget.tournament.id),
      initialData: false,
      builder: (context, snapshot) {
        final isFav = snapshot.data ?? false;
        return BarSmallBotton(
          icon: isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          iconColor: isFav ? const Color(0xFFFF4D6A) : Colors.white,
          onTap: _isLoading ? () {} : _toggle,
        );
      },
    );
  }
}
