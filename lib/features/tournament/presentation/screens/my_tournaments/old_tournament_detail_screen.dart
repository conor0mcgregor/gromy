import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/widgets/expandable_card.dart';
import '../../../../../core/widgets/static_location_map.dart';
import '../../../../brackets/presentation/widgets/brankets_section.dart';
import '../../../../participants/presentation/widgets/participants_section.dart';
import '../../../../profile/presentation/widgets/user_profile_navigation_helper.dart';
import '../../../data/model/app_tournament.dart';
import '../../../data/model/enums_tournament.dart';
import '../../../domain/helpers/tournament_champion_resolver.dart';

// ════════════════════════════════════════════════════════════════
//  OLD TOURNAMENT DETAIL — Vista histórica de solo lectura
// ════════════════════════════════════════════════════════════════

class OldTournamentDetailScreen extends StatefulWidget {
  const OldTournamentDetailScreen({super.key, required this.tournament});

  final AppTournament tournament;

  @override
  State<OldTournamentDetailScreen> createState() =>
      _OldTournamentDetailScreenState();
}

class _OldTournamentDetailScreenState extends State<OldTournamentDetailScreen> {
  late final Future<OldTournamentSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = TournamentChampionResolver().resolve(widget.tournament.id);
  }

  @override
  Widget build(BuildContext context) {
    final tournament = widget.tournament;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const _BackButton(),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CoverHero(tournament: tournament),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _TournamentHeader(tournament: tournament),
                  const SizedBox(height: 12),
                  _FinalStatusBanner(tournament: tournament),
                  const SizedBox(height: 16),
                  FutureBuilder<OldTournamentSummary>(
                    future: _summaryFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const _SummaryLoadingCard();
                      }
                      final summary = snapshot.data;
                      if (summary == null ||
                          (summary.championName == null &&
                              summary.formatLabel == null)) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          _ResultsSection(
                            tournament: tournament,
                            summary: summary,
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                  _GeneralInfoSection(tournament: tournament),
                  const SizedBox(height: 16),
                  ParticipantsSection(tournament: tournament),
                  const SizedBox(height: 20),
                  BracketsSection(
                    tournamentId: tournament.id,
                    isAdmin: false,
                  ),
                  const SizedBox(height: 16),
                  _DatesSection(tournament: tournament),
                  const SizedBox(height: 16),
                  _DescriptionSection(tournament: tournament),
                  const SizedBox(height: 16),
                  _ConfigSection(tournament: tournament),
                  const SizedBox(height: 16),
                  _ContactsSection(tournament: tournament),
                  const SizedBox(height: 24),
                  _LocationSection(tournament: tournament),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────────────────

class _CoverHero extends StatelessWidget {
  const _CoverHero({required this.tournament});
  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    final uri = tournament.portadaUrl?.trim();
    final hasUrl = uri != null && uri.isNotEmpty;

    return SizedBox(
      height: 280,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasUrl)
            Image.network(
              uri,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            )
          else
            _placeholder(),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.45, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    const Color(0xFF0F172A),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 20,
            child: _SportBadge(sport: tournament.sport.label),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C63FF).withValues(alpha: 0.22),
            const Color(0xFF0F172A),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.emoji_events_rounded,
          size: 64,
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

class _SportBadge extends StatelessWidget {
  const _SportBadge({required this.sport});
  final String sport;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00D4A8);
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
          child: Text(
            sport.toUpperCase(),
            style: const TextStyle(
              color: accent,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _TournamentHeader extends StatelessWidget {
  const _TournamentHeader({required this.tournament});
  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    final isCancelled = tournament.status == TournamentStatus.cancelled;
    final badgeColor =
        isCancelled ? const Color(0xFFFF6B6B) : const Color(0xFF00D4A8);
    final badgeLabel =
        isCancelled ? 'CANCELADO' : 'COMPLETADO';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: badgeColor.withValues(alpha: 0.12),
            border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
          ),
          child: Text(
            badgeLabel,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 12),
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
        if (tournament.organizerDisplayName != null &&
            tournament.organizerDisplayName!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _OrganizerChip(
            name: tournament.organizerDisplayName!,
            organizerUid: tournament.organizerUid,
          ),
        ],
        if (tournament.description.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            tournament.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14.5,
              height: 1.55,
            ),
          ),
        ],
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
    return UserProfileClickable(
      userId: organizerUid,
      borderRadius: 999,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Banners y secciones ──────────────────────────────────────────────────────

class _FinalStatusBanner extends StatelessWidget {
  const _FinalStatusBanner({required this.tournament});
  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    final isCancelled = tournament.status == TournamentStatus.cancelled;
    final color =
        isCancelled ? const Color(0xFFFF6B6B) : const Color(0xFFB0A8FF);
    final title = isCancelled ? 'Torneo cancelado' : 'Torneo finalizado';
    final subtitle = isCancelled
        ? 'Este torneo fue cancelado. La información se muestra solo para consulta.'
        : 'Vista histórica de solo lectura. No es posible modificar datos ni gestionar inscripciones.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(
              isCancelled ? Icons.cancel_outlined : Icons.history_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.75),
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
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

class _SummaryLoadingCard extends StatelessWidget {
  const _SummaryLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF00D4A8),
        ),
      ),
    );
  }
}

class _ResultsSection extends StatelessWidget {
  const _ResultsSection({
    required this.tournament,
    required this.summary,
  });

  final AppTournament tournament;
  final OldTournamentSummary summary;

  @override
  Widget build(BuildContext context) {
    final finishedAt = summary.completedAt ?? tournament.updatedAt;

    return ExpandableCard(
      title: 'Resultados',
      icon: Icons.emoji_events_rounded,
      accentColor: const Color(0xFF00D4A8),
      initiallyExpanded: true,
      children: [
        if (summary.championName != null)
          ExpandableInfoRow(
            label: 'Ganador',
            value: summary.championName!,
            valueColor: const Color(0xFF00D4A8),
          ),
        if (summary.formatLabel != null)
          ExpandableInfoRow(
            label: 'Formato de competición',
            value: summary.formatLabel!,
          ),
        ExpandableInfoRow(
          label: 'Estado final',
          value: tournament.status.label,
        ),
        ExpandableInfoRow(
          label: 'Fecha de finalización',
          value: _formatDate(finishedAt),
          showDivider: false,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat("dd/MM/yyyy  ·  HH:mm", 'es').format(date);
  }
}

class _GeneralInfoSection extends StatelessWidget {
  const _GeneralInfoSection({required this.tournament});
  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    final isTeam =
        tournament.membersPerTeam != null && tournament.membersPerTeam! > 1;

    return ExpandableCard(
      title: 'Información general',
      icon: Icons.info_outline_rounded,
      accentColor: const Color(0xFF6C63FF),
      initiallyExpanded: true,
      children: [
        ExpandableInfoRow(label: 'Deporte', value: tournament.sport.label),
        ExpandableInfoRow(
          label: 'Modalidad',
          value: isTeam
              ? 'Por equipos (${tournament.membersPerTeam} jugadores)'
              : 'Individual',
        ),
        ExpandableInfoRow(
          label: 'Acceso',
          value: tournament.accessType.label,
        ),
        ExpandableInfoRow(
          label: 'Participantes',
          value:
              '${tournament.participantCount} / ${tournament.maxParticipants}',
        ),
        ExpandableInfoRow(
          label: 'Ubicación',
          value: tournament.location.isEmpty ? '—' : tournament.location,
          showDivider: false,
        ),
      ],
    );
  }
}

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
          ),
        if (tournament.bracketPublishDate != null)
          ExpandableInfoRow(
            label: 'Publicación de cuadros',
            value: _formatDate(tournament.bracketPublishDate!),
          ),
        ExpandableInfoRow(
          label: 'Última actualización',
          value: _formatDate(tournament.updatedAt),
          showDivider: false,
        ),
      ],
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.tournament});
  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    final hasRules = tournament.allInformation.isNotEmpty;
    final hasAdditional =
        tournament.additionalInfo != null &&
        tournament.additionalInfo!.isNotEmpty;

    if (!hasRules && !hasAdditional) return const SizedBox.shrink();

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

class _ConfigSection extends StatelessWidget {
  const _ConfigSection({required this.tournament});
  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    final categories = tournament.categories;
    final hasCategories = categories.isNotEmpty;

    return ExpandableCard(
      title: 'Configuración del torneo',
      icon: Icons.tune_rounded,
      accentColor: const Color(0xFFF59E0B),
      children: [
        ExpandableInfoRow(
          label: 'Duración máxima de enfrentamiento',
          value: '${tournament.maxMatchDurationMinutes} minutos',
        ),
        ExpandableInfoRow(
          label: 'Máximo de participantes',
          value: '${tournament.maxParticipants}',
        ),
        if (hasCategories)
          ExpandableInfoRow(
            label: 'Categorías',
            value: categories.join(', '),
          ),
        ExpandableInfoRow(
          label: 'Formulario de inscripción',
          value: tournament.registrationForm.fields.isEmpty
              ? 'Sin campos personalizados'
              : '${tournament.registrationForm.fields.length} campo(s)',
          showDivider: false,
        ),
      ],
    );
  }
}

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

    if (!hasEmail && !hasPhone && !hasLinks) {
      return const SizedBox.shrink();
    }

    return ExpandableCard(
      title: 'Contacto',
      icon: Icons.support_agent_rounded,
      accentColor: const Color(0xFF22C55E),
      children: [
        if (hasEmail)
          ExpandableInfoRow(label: 'Email', value: tournament.contactEmail!),
        if (hasPhone)
          ExpandableInfoRow(label: 'Teléfono', value: tournament.contactPhone!),
        if (hasLinks) ...[
          const SizedBox(height: 4),
          ...tournament.contactLinks.map(
            (link) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () async {
                  final uri = Uri.parse(link);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text(
                  link,
                  style: const TextStyle(
                    color: Color(0xFF00D4FF),
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({required this.tournament});
  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    final hasCoords =
        tournament.latitude != null && tournament.longitude != null;
    if (!hasCoords && tournament.location.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        if (hasCoords)
          StaticLocationMap(
            latitude: tournament.latitude!,
            longitude: tournament.longitude!,
            locationLabel: tournament.location,
          )
        else
          Text(
            tournament.location,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.35),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}
