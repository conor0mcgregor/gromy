import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_shell.dart';
import '../../../../database/team/services/firestore_team_service.dart';
import '../../../profile/presentation/screens/other_user_profile_screen.dart';
import '../../../team/presentation/screens/team_detail_screen.dart';
import '../../data/models/app_match.dart';
import '../../data/models/bracket_enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MatchCard  ·  Widget
//
//  Card visual para un enfrentamiento individual.
//  Muestra participantes, fotos, scores, estado y horario.
//  Soporta modo admin (con botón de edición).
// ─────────────────────────────────────────────────────────────────────────────

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    this.isAdmin = false,
    this.onTap,
    this.width = 220,
  });

  final AppMatch match;
  final bool isAdmin;
  final VoidCallback? onTap;
  final double width;

  static const _accentColor = Color(0xFF6C63FF);
  static const _winnerColor = Color(0xFF22C55E);
  static const _byeColor = Color(0xFFFFB347);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: _borderColor, width: 1.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header con estado y round
                _buildHeader(),
                // Participante 1
                _buildParticipantRow(
                  context: context,
                  name: match.participant1Name,
                  photoUrl: match.participant1PhotoUrl,
                  participantId: match.participant1Id,
                  participantType: match.participant1Type,
                  score: match.scoreParticipant1,
                  isWinner:
                      match.winnerId != null &&
                      match.winnerId == match.participant1Id,
                  isTop: true,
                ),
                // Separador
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                // Participante 2
                _buildParticipantRow(
                  context: context,
                  name: match.participant2Name,
                  photoUrl: match.participant2PhotoUrl,
                  participantId: match.participant2Id,
                  participantType: match.participant2Type,
                  score: match.scoreParticipant2,
                  isWinner:
                      match.winnerId != null &&
                      match.winnerId == match.participant2Id,
                  isTop: false,
                ),
                // Footer con horario
                if (match.scheduledAt != null) _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color get _borderColor {
    if (match.isCompleted) return _winnerColor.withValues(alpha: 0.3);
    if (match.isBye) return _byeColor.withValues(alpha: 0.3);
    if (match.status == MatchStatus.inProgress) {
      return _accentColor.withValues(alpha: 0.5);
    }
    return Colors.white.withValues(alpha: 0.1);
  }

  Widget _buildHeader() {
    final Color statusColor;
    final String statusText;

    switch (match.status) {
      case MatchStatus.completed:
        statusColor = _winnerColor;
        statusText = 'Completado';
      case MatchStatus.inProgress:
        statusColor = _accentColor;
        statusText = 'En curso';
      case MatchStatus.scheduled:
        statusColor = const Color(0xFF00D4FF);
        statusText = 'Programado';
      case MatchStatus.bye:
        statusColor = _byeColor;
        statusText = 'BYE';
      case MatchStatus.cancelled:
        statusColor = const Color(0xFFEF4444);
        statusText = 'Cancelado';
      default:
        statusColor = Colors.white.withValues(alpha: 0.3);
        statusText = 'Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (isAdmin && !match.isCompleted)
            Icon(
              Icons.edit_rounded,
              size: 12,
              color: Colors.white.withValues(alpha: 0.3),
            ),
        ],
      ),
    );
  }

  Widget _buildParticipantRow({
    required BuildContext context,
    required String? name,
    required String? photoUrl,
    required String? participantId,
    required MatchParticipantType? participantType,
    required int? score,
    required bool isWinner,
    required bool isTop,
  }) {
    final isEmpty = participantId == null || participantId.isEmpty;
    final displayName = isEmpty
        ? (match.isBye ? 'BYE' : 'Por definir')
        : (name ?? 'Participante');

    return GestureDetector(
      onTap: isEmpty
          ? null
          : () => _handleParticipantTap(
                context,
                participantId,
                participantType ?? MatchParticipantType.user,
              ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isWinner
              ? _winnerColor.withValues(alpha: 0.06)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Foto / Avatar
            _buildAvatar(photoUrl, isEmpty, isWinner),
            const SizedBox(width: 8),
            // Nombre
            Expanded(
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isEmpty
                      ? Colors.white.withValues(alpha: 0.25)
                      : isWinner
                      ? _winnerColor
                      : Colors.white.withValues(alpha: 0.85),
                  fontSize: 12.5,
                  fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            // Score
            if (participantType == MatchParticipantType.team) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.groups_rounded,
                size: 13,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ],
            if (score != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: isWinner
                      ? _winnerColor.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.06),
                ),
                child: Text(
                  '$score',
                  style: TextStyle(
                    color: isWinner
                        ? _winnerColor
                        : Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            // Indicador de ganador
            if (isWinner) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.emoji_events_rounded,
                size: 13,
                color: _winnerColor.withValues(alpha: 0.8),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleParticipantTap(
    BuildContext context,
    String participantId,
    MatchParticipantType type,
  ) async {
    if (type == MatchParticipantType.user) {
      if (FirebaseAuth.instance.currentUser?.uid == participantId) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const AppShell(initialIndex: 4),
          ),
          (route) => false,
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtherUserProfileScreen(targetUid: participantId),
        ),
      );
    } else if (type == MatchParticipantType.team) {
      // Mostrar indicador de carga simple
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
      );
      try {
        final team = await FirestoreTeamService().getTeam(participantId);
        if (context.mounted) Navigator.pop(context); // Quitar indicador
        if (team != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamDetailScreen(team: team),
            ),
          );
        }
      } catch (_) {
        if (context.mounted) {
          Navigator.pop(context); // Quitar indicador
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo cargar el detalle del equipo.'),
              backgroundColor: Color(0xFFFF4D6A),
            ),
          );
        }
      }
    }
  }

  Widget _buildAvatar(String? photoUrl, bool isEmpty, bool isWinner) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isEmpty
            ? Colors.white.withValues(alpha: 0.05)
            : isWinner
            ? _winnerColor.withValues(alpha: 0.15)
            : _accentColor.withValues(alpha: 0.12),
        border: Border.all(
          color: isEmpty
              ? Colors.white.withValues(alpha: 0.08)
              : isWinner
              ? _winnerColor.withValues(alpha: 0.4)
              : _accentColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: photoUrl != null && photoUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildPlaceholderIcon(isEmpty),
              ),
            )
          : _buildPlaceholderIcon(isEmpty),
    );
  }

  Widget _buildPlaceholderIcon(bool isEmpty) {
    return Icon(
      isEmpty ? Icons.help_outline_rounded : Icons.person_rounded,
      size: 13,
      color: Colors.white.withValues(alpha: isEmpty ? 0.15 : 0.4),
    );
  }

  Widget _buildFooter() {
    final formatted = DateFormat(
      'dd MMM · HH:mm',
      'es',
    ).format(match.scheduledAt!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 11,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 4),
          Text(
            formatted,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
