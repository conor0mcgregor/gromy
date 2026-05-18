import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/model/app_tournament.dart';
import '../../data/model/enums_tournament.dart';
import '../../../../core/getColors/getter_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../database/participant/services/firestore_participant_service.dart';
import '../../../../features/inscription/presentation/screens/join_requests_screen.dart';
import '../../../../features/inscription/presentation/screens/edit_inscription_screen.dart';
import '../../../../features/inscription/data/services/firestore_join_request_service.dart';

// Reutilizamos InfoSection e InfoField de step7_review
import '../../presentation/screens/form/steps/step7_review.dart';

// Mapa (se mantiene intacto)
import 'widgets/tournament_map_section.dart';

// ════════════════════════════════════════════════════════════════
//  TOURNAMENT DETAILS
//  Estética idéntica a Step7Review: InfoSection + InfoField,
//  glassmorphism, layout mobile-first.
// ════════════════════════════════════════════════════════════════

class TournamentDetails extends StatefulWidget {
  final AppTournament tournament;
  final VoidCallback? onMoreInfoPressed;
  final VoidCallback? onRegisterPressed;

  const TournamentDetails({
    super.key,
    required this.tournament,
    this.onMoreInfoPressed,
    this.onRegisterPressed,
  });

  @override
  State<TournamentDetails> createState() => _TournamentDetailsState();
}

class _TournamentDetailsState extends State<TournamentDetails>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final primaryColor = sportColor(t.sport);
    final isPublic = t.accessType == TournamentAccessType.publicOpen;
    final occupancy = t.participantCount / t.maxParticipants;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Hero portada ─────────────────────────────────────
              _CoverHero(
                portadaUrl: t.portadaUrl,
                sport: t.sport,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 20),

              // ── Todo el contenido de secciones con padding ─────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 2. Identidad ──────────────────────────────────
                    InfoSection(
                      icon: Icons.badge_rounded,
                      title: 'Identidad',
                      accentColor: const Color(0xFF6C63FF),
                      children: [
                        InfoField(
                          label: 'Nombre del torneo',
                          value: t.name,
                        ),
                        InfoField(
                          label: 'Descripción',
                          value: t.description.isEmpty ? '—' : t.description,
                          multiline: true,
                        ),
                      ],
                    ),

                    // ── 3. Disciplina ─────────────────────────────────
                    InfoSection(
                      icon: Icons.sports_rounded,
                      title: 'Disciplina',
                      accentColor: primaryColor,
                      children: [
                        InfoField(label: 'Deporte', value: t.sport.label),
                        if (t.membersPerTeam != null && t.membersPerTeam! > 1)
                          InfoField(
                            label: 'Modalidad',
                            value: 'Por equipos (${t.membersPerTeam} jugadores)',
                          )
                        else
                          const InfoField(
                            label: 'Modalidad',
                            value: 'Individual',
                          ),
                      ],
                    ),

                    // ── 4. Cronograma ─────────────────────────────────
                    InfoSection(
                      icon: Icons.calendar_month_rounded,
                      title: 'Cronograma',
                      accentColor: const Color(0xFFA855F7),
                      children: [
                        InfoField(
                          label: 'Fecha del evento',
                          value: _formatDate(t.scheduledAt),
                        ),
                        if (t.registrationDeadline != null)
                          InfoField(
                            label: 'Límite de inscripción',
                            value: _formatDate(t.registrationDeadline!),
                          ),
                        if (t.bracketPublishDate != null)
                          InfoField(
                            label: 'Publicación de cuadros',
                            value: _formatDate(t.bracketPublishDate!),
                          ),
                      ],
                    ),

                    // ── 5. Logística ──────────────────────────────────
                    InfoSection(
                      icon: Icons.tune_rounded,
                      title: 'Logística',
                      accentColor: const Color(0xFFFFB347),
                      children: [
                        InfoField(
                          label: 'Participantes',
                          value: '${t.participantCount} / ${t.maxParticipants}',
                          valueColor: occupancyColor(occupancy),
                        ),
                        InfoField(
                          label: 'Acceso',
                          value: t.accessType.label,
                          leadingIcon: isPublic
                              ? Icons.public_rounded
                              : Icons.lock_rounded,
                          leadingIconColor: isPublic
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFFFB347),
                        ),
                      ],
                    ),

                    // ── 6. Ubicación (texto) ──────────────────────────
                    InfoSection(
                      icon: Icons.location_on_rounded,
                      title: 'Ubicación',
                      accentColor: const Color(0xFF22C55E),
                      children: [
                        InfoField(label: 'Lugar', value: t.location),
                        InfoField(
                          label: 'Coordenadas en el mapa',
                          value: t.latitude != null && t.longitude != null
                              ? 'Marcadas correctamente'
                              : 'Sin coordenadas',
                          valueColor: t.latitude != null && t.longitude != null
                              ? const Color(0xFF22C55E)
                              : Colors.white.withValues(alpha: 0.45),
                          leadingIcon: t.latitude != null && t.longitude != null
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          leadingIconColor:
                              t.latitude != null && t.longitude != null
                                  ? const Color(0xFF22C55E)
                                  : Colors.white.withValues(alpha: 0.3),
                        ),
                      ],
                    ),

                    // ── 7. Reglamento ─────────────────────────────────
                    if (t.allInformation.isNotEmpty)
                      InfoSection(
                        icon: Icons.gavel_rounded,
                        title: 'Reglamento',
                        accentColor: const Color(0xFFFF6B9D),
                        children: [
                          InfoField(
                            label: 'Reglas del torneo',
                            value: t.allInformation,
                            multiline: true,
                          ),
                        ],
                      ),

                    // ── 8. Staff y Soporte ─────────────────────────────
                    InfoSection(
                      icon: Icons.support_agent_rounded,
                      title: 'Staff y Soporte',
                      accentColor: const Color(0xFF00D4FF),
                      children: [
                        if (t.organizerDisplayName != null)
                          InfoField(
                            label: 'Organizador',
                            value: t.organizerDisplayName!,
                          ),
                        if (t.contactEmail != null &&
                            t.contactEmail!.isNotEmpty)
                          InfoField(
                            label: 'Email de contacto',
                            value: t.contactEmail!,
                          ),
                        if (t.contactPhone != null &&
                            t.contactPhone!.isNotEmpty)
                          InfoField(
                            label: 'Teléfono',
                            value: t.contactPhone!,
                          ),
                        if (t.contactLinks.isNotEmpty)
                          InfoField(
                            label: 'Enlaces',
                            value: t.contactLinks.join('\n'),
                            multiline: true,
                          ),
                        InfoField(
                          label: 'Administradores',
                          value: t.adminIds.isEmpty
                              ? 'Solo el organizador'
                              : '${t.adminIds.length} asignados',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── 9. Mapa (se mantiene intacto) ──────────────────────
              TournamentMapSection(
                latitude: t.latitude,
                longitude: t.longitude,
                location: t.location,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 16),

              // ── 10. Acciones del organizador / participante ───────
              _TournamentActions(tournament: t),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
  String _formatDate(DateTime date) {
    return DateFormat("dd 'de' MMMM, yyyy  ·  HH:mm", 'es').format(date);
  }
}

// ════════════════════════════════════════════════════════════════
//  WIDGET: Hero portada + nombre + badge de deporte
// ════════════════════════════════════════════════════════════════

class _CoverHero extends StatelessWidget {
  const _CoverHero({
    required this.sport,
    required this.primaryColor,
    this.portadaUrl,
  });

  final String? portadaUrl;
  final TournamentSport sport;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final uri = portadaUrl?.trim();
    final hasUrl = uri != null && uri.isNotEmpty;

    return Stack(
      children: [
        // Portada
        SizedBox(
          height: 260,
          width: double.infinity,
          child: hasUrl
              ? Image.network(
                  uri,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : _placeholder(),
                  errorBuilder: (_, e, s) => _placeholder(),
                )
              : _placeholder(),
        ),

        // Gradiente inferior
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 140,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  const Color(0xFF0A0A1A),
                ],
              ),
            ),
          ),
        ),

        // Badge de deporte + Nombre
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        sport.label.toUpperCase(),
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
}

// ════════════════════════════════════════════════════════════════
//  WIDGET: Tournament Actions (organizer + participant)
// ════════════════════════════════════════════════════════════════

class _TournamentActions extends StatelessWidget {
  const _TournamentActions({required this.tournament});
  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    final isOrganizer = tournament.organizerUid == uid ||
        tournament.adminIds.contains(uid);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Organizer: view join requests ──
          if (isOrganizer && tournament.requiresApproval) ...[
            _ActionTile(
              icon: Icons.how_to_reg_rounded,
              label: 'Solicitudes de inscripción',
              subtitle: 'Revisar y aprobar solicitudes pendientes',
              accentColor: const Color(0xFFFFB347),
              showBadge: true,
              tournamentId: tournament.id,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => JoinRequestsScreen(
                    tournament: tournament,
                    currentUserId: uid,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Participant: edit inscription ──
          if (!isOrganizer) ...[
            FutureBuilder(
              future: FirestoreParticipantService().getParticipantByEntity(
                tournamentId: tournament.id,
                entityId: uid,
              ),
              builder: (context, snapshot) {
                final participant = snapshot.data;
                if (participant == null) return const SizedBox.shrink();

                return _ActionTile(
                  icon: Icons.edit_note_rounded,
                  label: 'Editar mi inscripción',
                  subtitle: 'Modificar datos o categoría',
                  accentColor: const Color(0xFF6C63FF),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditInscriptionScreen(
                        tournament: tournament,
                        participant: participant,
                        currentUserId: uid,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
    this.showBadge = false,
    this.tournamentId,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;
  final bool showBadge;
  final String? tournamentId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: accentColor.withValues(alpha: 0.06),
          border: Border.all(color: accentColor.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: accentColor.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
              ],
            )),
            // Badge for pending count
            if (showBadge && tournamentId != null)
              FutureBuilder<int>(
                future: FirestoreJoinRequestService().getPendingCount(tournamentId!),
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: accentColor.withValues(alpha: 0.2),
                    ),
                    child: Text('$count', style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w800)),
                  );
                },
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
    );
  }
}