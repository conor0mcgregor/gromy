// ════════════════════════════════════════════════════════════════
//  3. PARTICIPANTES — barra de progreso visual
// ════════════════════════════════════════════════════════════════

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/widgets/participant_card.dart';
import '../../../tournament/data/model/app_tournament.dart';
import '../../data/models/participant_display.dart';
import '../../data/repositories/participant_display_repository.dart';
import '../../data/services/participant_display_service.dart';
import '../screens/participants_screen.dart';

class ParticipantsSection extends StatefulWidget {
  const ParticipantsSection({
    super.key,
    required this.tournament,
    this.enableManagementNavigation = false,
    this.managementScreenBuilder,
  });

  final AppTournament tournament;
  final bool enableManagementNavigation;
  final WidgetBuilder? managementScreenBuilder;

  @override
  State<ParticipantsSection> createState() => ParticipantsSectionState();
}

class ParticipantsSectionState extends State<ParticipantsSection> {
  final ParticipantDisplayRepository _repository = ParticipantDisplayService();
  List<ParticipantDisplay> _preview = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final data = await _repository.getParticipantsPreview(
        widget.tournament.id,
        limit: 5,
      );
      if (mounted) {
        setState(() {
          _preview = data;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loaded = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.tournament.participantCount;
    final max = widget.tournament.maxParticipants;
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final percentage = (ratio * 100).round();

    // Color según ocupación
    final barColor = ratio >= 0.8
        ? const Color(0xFFFF4D6A)
        : ratio >= 0.5
        ? const Color(0xFFFFB347)
        : const Color(0xFF22C55E);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openParticipants,
        borderRadius: BorderRadius.circular(20),
        splashColor: barColor.withValues(alpha: 0.1),
        highlightColor: barColor.withValues(alpha: 0.05),
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
                  // Header
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

                  // Barra de progreso
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

                  // Texto complementario
                  Text(
                    percentage < 100
                        ? 'Quedan ${max - current} plazas disponibles'
                        : 'Torneo completo',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),

                  // Vista previa de avatares
                  if (_loaded && _preview.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _AvatarPreviewRow(
                      participants: _preview,
                      totalCount: current,
                      accentColor: barColor,
                    ),
                  ],
                  if (widget.enableManagementNavigation) ...[
                    const SizedBox(height: 14),
                    _ManagementAccessHint(accentColor: barColor),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openParticipants() {
    final isTeamTournament = (widget.tournament.membersPerTeam ?? 1) > 1;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => widget.enableManagementNavigation
            ? widget.managementScreenBuilder?.call(context) ??
                  ParticipantsScreen(
                    tournamentId: widget.tournament.id,
                    tournamentName: widget.tournament.name,
                    isTeamTournament: isTeamTournament,
                    categories: widget.tournament.categories,
                  )
            : ParticipantsScreen(
                tournamentId: widget.tournament.id,
                tournamentName: widget.tournament.name,
                isTeamTournament: isTeamTournament,
                categories: widget.tournament.categories,
              ),
      ),
    );
  }
}

class _ManagementAccessHint extends StatelessWidget {
  const _ManagementAccessHint({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: accentColor.withValues(alpha: 0.1),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.manage_accounts_rounded, color: accentColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Gestionar participantes',
              style: TextStyle(
                color: accentColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: accentColor, size: 16),
        ],
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
    final totalWidth =
        participants.length * (_avatarSize - _overlap) +
        _overlap +
        (showOverflow ? _avatarSize + 4 : 0);

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
