import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/app_match.dart';
import '../../data/models/bracket_enums.dart';
import '../../../../features/profile/presentation/widgets/user_profile_navigation_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MatchDetailPanel  ·  Widget
//
//  Modal bottom sheet de detalles de un enfrentamiento.
//  Diseño limpio, jerarquía visual clara, chips de estado,
//  avatares con fotos de perfil y toda la información relevante.
//
//  Información mostrada:
//   - Número de enfrentamiento y ronda
//   - Categoría y estado (chip de color)
//   - Horario (fecha + hora o "Pendiente de definir")
//   - Participantes con avatar/foto, nombre, tipo
//   - Ganador (trophy + highlight)
//   - Resultado/scores
//   - Timestamps (creación y última actualización)
// ─────────────────────────────────────────────────────────────────────────────

const _kAccent = Color(0xFF6C63FF);
const _kGreen = Color(0xFF22C55E);
const _kOrange = Color(0xFFFFB347);
const _kRed = Color(0xFFEF4444);
const _kCyan = Color(0xFF00D4FF);
const _kBg = Color(0xFF0F172A);
const _kCard = Color(0xFF1E293B);

class MatchDetailPanel extends StatelessWidget {
  const MatchDetailPanel({
    super.key,
    required this.match,
    this.matchNumber,
    this.roundName,
    this.categoryName,
  });

  final AppMatch match;

  /// Número correlativo del match (ej. 3).
  final int? matchNumber;

  /// Nombre legible del round (ej. "Cuartos de final").
  final String? roundName;

  /// Nombre de la categoría (puede ser null si el torneo no tiene categorías).
  final String? categoryName;

  static Future<void> show(
    BuildContext context,
    AppMatch match, {
    int? matchNumber,
    String? roundName,
    String? categoryName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MatchDetailPanel(
        match: match,
        matchNumber: matchNumber,
        roundName: roundName,
        categoryName: categoryName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: mq.size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(child: _buildHandle()),
                  const SizedBox(height: 18),

                  // Encabezado: número + ronda + categoría
                  _buildHeader(),
                  const SizedBox(height: 18),

                  // Chips de estado y horario
                  _buildStatusRow(),
                  const SizedBox(height: 20),

                  // Participantes
                  _buildSectionLabel('Enfrentamiento'),
                  const SizedBox(height: 10),
                  _buildParticipantCard(
                    participantId: match.participant1Id,
                    name: match.participant1Name,
                    photoUrl: match.participant1PhotoUrl,
                    type: match.participant1Type,
                    memberNames: match.participant1MemberNames,
                    score: match.scoreParticipant1,
                    isWinner: match.winnerId != null &&
                        match.winnerId == match.participant1Id,
                    label: 'Participante 1',
                  ),
                  const SizedBox(height: 8),

                  // VS divider
                  _buildVsDivider(),
                  const SizedBox(height: 8),

                  _buildParticipantCard(
                    participantId: match.participant2Id,
                    name: match.participant2Name,
                    photoUrl: match.participant2PhotoUrl,
                    type: match.participant2Type,
                    memberNames: match.participant2MemberNames,
                    score: match.scoreParticipant2,
                    isWinner: match.winnerId != null &&
                        match.winnerId == match.participant2Id,
                    label: 'Participante 2',
                  ),

                  // Resultado / scores
                  if (match.isCompleted) ...[
                    const SizedBox(height: 20),
                    _buildSectionLabel('Resultado'),
                    const SizedBox(height: 10),
                    _buildScoreCard(),
                  ],

                  // Timestamps
                  const SizedBox(height: 20),
                  _buildSectionLabel('Información'),
                  const SizedBox(height: 10),
                  _buildInfoCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Handle ─────────────────────────────────────────────────────────────────

  Widget _buildHandle() {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.16),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Número del match
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [_kAccent, Color(0xFF9B5DE5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              matchNumber != null ? '#${matchNumber! + 1}' : '—',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                roundName ?? 'Enfrentamiento',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              if (categoryName != null && categoryName!.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.category_rounded,
                      size: 13,
                      color: _kAccent.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      categoryName!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              Row(
                children: [
                  Icon(
                    Icons.route_rounded,
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Ronda ${match.round + 1}  ·  Posición ${match.matchOrder + 1}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Chips de estado ─────────────────────────────────────────────────────────

  Widget _buildStatusRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildStatusChip(),
        _buildScheduleChip(),
      ],
    );
  }

  Widget _buildStatusChip() {
    final (color, label, icon) = _statusMeta();
    return _Chip(
      label: label,
      icon: icon,
      color: color,
    );
  }

  Widget _buildScheduleChip() {
    if (match.scheduledAt == null) {
      return _Chip(
        label: 'Horario: Pendiente de definir',
        icon: Icons.schedule_rounded,
        color: Colors.white.withValues(alpha: 0.3),
        dimmed: true,
      );
    }
    final formatted = DateFormat(
      "d 'de' MMMM, HH:mm",
      'es',
    ).format(match.scheduledAt!);
    return _Chip(
      label: formatted,
      icon: Icons.event_rounded,
      color: _kCyan,
    );
  }

  (Color, String, IconData) _statusMeta() {
    return switch (match.status) {
      MatchStatus.completed => (_kGreen, 'Completado', Icons.check_circle_rounded),
      MatchStatus.inProgress => (_kAccent, 'En curso', Icons.sports_rounded),
      MatchStatus.scheduled => (_kCyan, 'Programado', Icons.event_rounded),
      MatchStatus.bye => (_kOrange, 'BYE (pase directo)', Icons.fast_forward_rounded),
      MatchStatus.cancelled => (_kRed, 'Cancelado', Icons.cancel_rounded),
      _ => (Colors.white.withValues(alpha: 0.4), 'Pendiente', Icons.hourglass_empty_rounded),
    };
  }

  // ── Participante card ───────────────────────────────────────────────────────

  Widget _buildParticipantCard({
    required String? participantId,
    required String? name,
    required String? photoUrl,
    required MatchParticipantType? type,
    required List<String> memberNames,
    required int? score,
    required bool isWinner,
    required String label,
  }) {
    final isEmpty = participantId == null || participantId.isEmpty;
    final displayName = isEmpty
        ? (match.isBye ? 'BYE' : 'Por definir')
        : (name ?? 'Participante');
    final isTeam = type == MatchParticipantType.team;

    Widget cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isWinner
            ? _kGreen.withValues(alpha: 0.07)
            : _kCard.withValues(alpha: 0.8),
        border: Border.all(
          color: isWinner
              ? _kGreen.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.07),
          width: isWinner ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar grande
              _buildAvatar(
                photoUrl: photoUrl,
                isEmpty: isEmpty,
                isWinner: isWinner,
                isTeam: isTeam,
                size: 48,
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label (Participante 1 / 2)
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Nombre
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isEmpty
                            ? Colors.white.withValues(alpha: 0.3)
                            : isWinner
                                ? _kGreen
                                : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Tipo (equipo / individual)
                    if (!isEmpty)
                      Row(
                        children: [
                          Icon(
                            isTeam
                                ? Icons.groups_rounded
                                : Icons.person_rounded,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isTeam ? 'Equipo' : 'Individual',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Score grande + trophy
              if (!isEmpty) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (score != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isWinner
                              ? _kGreen.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                        child: Text(
                          '$score',
                          style: TextStyle(
                            color: isWinner ? _kGreen : Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    if (isWinner) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            size: 14,
                            color: _kGreen,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Ganador',
                            style: TextStyle(
                              color: _kGreen.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),

          // Miembros del equipo
          if (isTeam && memberNames.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.white.withValues(alpha: 0.06),
            ),
            const SizedBox(height: 10),
            Text(
              'Integrantes',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: memberNames
                  .map(
                    (memberName) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: _kAccent.withValues(alpha: 0.1),
                        border: Border.all(
                          color: _kAccent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 11,
                            color: _kAccent.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            memberName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );

    if (!isEmpty && !isTeam && participantId != null) {
      return UserProfileClickable(
        userId: participantId,
        borderRadius: 16,
        child: cardContent,
      );
    }
    
    return cardContent;
  }

  Widget _buildAvatar({
    required String? photoUrl,
    required bool isEmpty,
    required bool isWinner,
    required bool isTeam,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isEmpty
            ? Colors.white.withValues(alpha: 0.04)
            : isWinner
                ? _kGreen.withValues(alpha: 0.15)
                : _kAccent.withValues(alpha: 0.1),
        border: Border.all(
          color: isEmpty
              ? Colors.white.withValues(alpha: 0.07)
              : isWinner
                  ? _kGreen.withValues(alpha: 0.5)
                  : _kAccent.withValues(alpha: 0.35),
          width: isWinner ? 2 : 1.5,
        ),
      ),
      child: photoUrl != null && photoUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _avatarFallback(isEmpty, isTeam),
              ),
            )
          : _avatarFallback(isEmpty, isTeam),
    );
  }

  Widget _avatarFallback(bool isEmpty, bool isTeam) {
    return Icon(
      isEmpty
          ? Icons.help_outline_rounded
          : isTeam
              ? Icons.groups_rounded
              : Icons.person_rounded,
      size: 22,
      color: Colors.white.withValues(alpha: isEmpty ? 0.15 : 0.4),
    );
  }

  // ── VS divider ──────────────────────────────────────────────────────────────

  Widget _buildVsDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Text(
              'VS',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }

  // ── Score card ──────────────────────────────────────────────────────────────

  Widget _buildScoreCard() {
    final s1 = match.scoreParticipant1 ?? 0;
    final s2 = match.scoreParticipant2 ?? 0;
    final n1 = match.participant1Name ?? 'P1';
    final n2 = match.participant2Name ?? 'P2';
    final winner1 = match.winnerId == match.participant1Id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _kCard.withValues(alpha: 0.8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  n1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: winner1 ? _kGreen : Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$s1',
                  style: TextStyle(
                    color: winner1 ? _kGreen : Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '–',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 28,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  n2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !winner1 ? _kGreen : Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$s2',
                  style: TextStyle(
                    color: !winner1 ? _kGreen : Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info card (timestamps) ──────────────────────────────────────────────────

  Widget _buildInfoCard() {
    final dateFormat = DateFormat("d MMM yyyy, HH:mm", 'es');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _kCard.withValues(alpha: 0.8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.fingerprint_rounded,
            label: 'Match ID',
            value: match.id.length > 12
                ? '...${match.id.substring(match.id.length - 12)}'
                : match.id,
          ),
          _buildInfoDivider(),
          _buildInfoRow(
            icon: Icons.leaderboard_rounded,
            label: 'Bracket ID',
            value: match.bracketId.length > 12
                ? '...${match.bracketId.substring(match.bracketId.length - 12)}'
                : match.bracketId,
          ),
          if (match.startedAt != null) ...[
            _buildInfoDivider(),
            _buildInfoRow(
              icon: Icons.play_arrow_rounded,
              label: 'Iniciado',
              value: dateFormat.format(match.startedAt!),
            ),
          ],
          if (match.completedAt != null) ...[
            _buildInfoDivider(),
            _buildInfoRow(
              icon: Icons.flag_rounded,
              label: 'Completado',
              value: dateFormat.format(match.completedAt!),
              valueColor: _kGreen,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _kAccent.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white.withValues(alpha: 0.8),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDivider() {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.05),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _Chip  ·  Widget auxiliar
// ─────────────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    this.dimmed = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: dimmed ? 0.04 : 0.1),
        border: Border.all(
          color: color.withValues(alpha: dimmed ? 0.12 : 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color.withValues(alpha: dimmed ? 0.5 : 1)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: dimmed ? 0.5 : 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
