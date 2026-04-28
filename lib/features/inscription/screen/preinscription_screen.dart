import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/getColors/getter_colors.dart';
import '../../../core/widgets/bar_small_botton.dart';
import '../../../core/widgets/expandable_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/participant_card.dart';
import '../../../core/widgets/static_location_map.dart';
import '../../participants/data/models/participant_display.dart';
import '../../participants/data/services/participant_display_service.dart';
import '../../participants/presentation/screens/participants_screen.dart';
import '../../tournament/data/model/app_tournament.dart';

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

class DemoEnrollScreen extends StatelessWidget {
  final AppTournament tournament;

  const DemoEnrollScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
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
          _ShareButton(),
          const SizedBox(width: 8),
        ],
      ),

      // ── Botón de inscripción fijo ──
      bottomNavigationBar: _StickyEnrollBar(tournament: tournament),

      // ── Contenido scrollable ──
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Portada hero
            _CoverHero(tournament: tournament),

            // Contenido con padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // 2. Información básica
                  _TournamentHeader(tournament: tournament),
                  const SizedBox(height: 28),

                  // 3. Participantes
                  _ParticipantsSection(tournament: tournament),
                  const SizedBox(height: 20),

                  // 4. Fechas
                  _DatesSection(tournament: tournament),
                  const SizedBox(height: 16),

                  // 5. Descripción completa
                  _DescriptionSection(tournament: tournament),
                  const SizedBox(height: 16),

                  // 6. Contactos
                  _ContactsSection(tournament: tournament),
                  const SizedBox(height: 24),

                  // 7. Ubicación
                  _LocationSection(tournament: tournament),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
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
          _OrganizerChip(name: tournament.organizerDisplayName!),

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
  const _OrganizerChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  3. PARTICIPANTES — barra de progreso + vista previa de avatares
// ════════════════════════════════════════════════════════════════

class _ParticipantsSection extends StatefulWidget {
  const _ParticipantsSection({required this.tournament});
  final AppTournament tournament;

  @override
  State<_ParticipantsSection> createState() => _ParticipantsSectionState();
}

class _ParticipantsSectionState extends State<_ParticipantsSection> {
  final _service = ParticipantDisplayService();
  List<ParticipantDisplay> _preview = [];
  bool _loaded = false;

  static const int _maxPreview = 7;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final result = await _service.getParticipantsPreview(
        widget.tournament.id,
        limit: _maxPreview,
      );
      if (mounted) setState(() { _preview = result; _loaded = true; });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  void _navigateToFull(BuildContext context) {
    final t = widget.tournament;
    final isTeam = t.membersPerTeam != null && t.membersPerTeam! > 1;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParticipantsScreen(
          tournamentId: t.id,
          tournamentName: t.name,
          isTeamTournament: isTeam,
          categories: t.categories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.tournament.participantCount;
    final max = widget.tournament.maxParticipants;
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final percentage = (ratio * 100).round();

    final barColor = ratio >= 0.8
        ? const Color(0xFFFF4D6A)
        : ratio >= 0.5
            ? const Color(0xFFFFB347)
            : const Color(0xFF22C55E);

    return GestureDetector(
      onTap: () => _navigateToFull(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        color: barColor.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        Icons.groups_2_rounded,
                        size: 18,
                        color: barColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Participantes',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    Text(
                      '$current / $max',
                      style: TextStyle(
                        color: barColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Barra de progreso ────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, child) => FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  barColor.withValues(alpha: 0.7),
                                  barColor,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Texto complementario ─────────────────────────
                Text(
                  percentage < 100
                      ? 'Quedan ${max - current} plazas disponibles'
                      : 'Torneo completo',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),

                // ── Vista previa de avatares ──────────────────────
                if (_loaded && _preview.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _AvatarPreviewRow(
                    participants: _preview,
                    totalCount: current,
                    accentColor: barColor,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  AVATAR PREVIEW ROW — fila de avatares superpuestos
// ════════════════════════════════════════════════════════════════

class _AvatarPreviewRow extends StatelessWidget {
  const _AvatarPreviewRow({
    required this.participants,
    required this.totalCount,
    required this.accentColor,
  });

  final List<ParticipantDisplay> participants;
  final int totalCount;
  final Color accentColor;

  static const double _avatarSize = 32;
  static const double _overlap = 10;

  String _photoUrl(ParticipantDisplay p) => switch (p) {
    UserParticipantDisplay(:final user) => user.photoUrl ?? '',
    TeamParticipantDisplay(:final team) => team.photoUrl ?? '',
  };

  String _nickname(ParticipantDisplay p) => switch (p) {
    UserParticipantDisplay(:final user) => user.nickname,
    TeamParticipantDisplay(:final team) => team.name,
  };

  @override
  Widget build(BuildContext context) {
    final overflow = totalCount - participants.length;
    final showOverflow = overflow > 0;
    final totalWidth = participants.length * (_avatarSize - _overlap)
        + _overlap
        + (showOverflow ? _avatarSize + 4 : 0);

    return Row(
      children: [
        SizedBox(
          height: _avatarSize,
          width: totalWidth,
          child: Stack(
            children: [
              // Avatares superpuestos (de derecha a izquierda para el z-order)
              ...List.generate(participants.length, (i) {
                final p = participants[i];
                return Positioned(
                  left: i * (_avatarSize - _overlap),
                  child: ParticipantAvatar(
                    photoUrl: _photoUrl(p),
                    nickname: _nickname(p),
                    size: _avatarSize,
                    borderColor: const Color(0xFF0F172A),
                  ),
                );
              }),

              // Indicador +X
              if (showOverflow)
                Positioned(
                  left: participants.length * (_avatarSize - _overlap),
                  child: Container(
                    width: _avatarSize,
                    height: _avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.2),
                      border: Border.all(
                        color: const Color(0xFF0F172A),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '+$overflow',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Ver todos',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

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
    final hasAdditional = tournament.additionalInfo != null &&
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
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
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
    final hasEmail = tournament.contactEmail != null &&
        tournament.contactEmail!.isNotEmpty;
    final hasPhone = tournament.contactPhone != null &&
        tournament.contactPhone!.isNotEmpty;
    final hasLinks = tournament.contactLinks.isNotEmpty;
    final hasOrganizer = tournament.organizerDisplayName != null &&
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
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
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

class _StickyEnrollBar extends StatelessWidget {
  const _StickyEnrollBar({required this.tournament});
  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    final isFull = tournament.participantCount >= tournament.maxParticipants;

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
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
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
        child: GradientButton(
          label: isFull ? 'Torneo completo' : 'Inscribirse al torneo',
          icon: isFull ? Icons.block_rounded : Icons.how_to_reg_rounded,
          onPressed: isFull ? null : () {/* TODO: lógica de inscripción */},
          variant: isFull
              ? GradientButtonVariant.sunset
              : GradientButtonVariant.violet,
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
        }
    );
  }
}
