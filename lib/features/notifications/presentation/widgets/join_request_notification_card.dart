import 'package:flutter/material.dart';

import '../../domain/entities/app_notification.dart';

class JoinRequestNotificationCard extends StatelessWidget {
  const JoinRequestNotificationCard({
    super.key,
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  static const _accent = Color(0xFFF59E0B);
  static const _reviewColor = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    final data = notification.data;
    final isUnread = notification.isUnread;
    final tournamentName = _read(
      data,
      'tournamentName',
      fallback: 'Torneo privado',
    );
    final requesterName = _read(data, 'requesterName', fallback: 'Un usuario');
    final requesterNickname = _read(data, 'requesterNickname');
    final requesterLabel = requesterNickname.isEmpty
        ? requesterName
        : '@$requesterNickname';
    final tournamentCover = _read(data, 'tournamentPortadaUrl');
    final requesterAvatar = _read(data, 'requesterAvatarUrl');
    final sport = _read(data, 'tournamentSport');
    final location = _read(data, 'tournamentLocation');
    final participantCount = (data['tournamentParticipantCount'] as num?)
        ?.toInt();
    final maxParticipants = (data['tournamentMaxParticipants'] as num?)
        ?.toInt();
    final status = _read(data, 'status', fallback: 'pending');

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: _buildDismissBackground(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isUnread
                ? [
                    _accent.withValues(alpha: 0.18),
                    const Color(0xFF22C55E).withValues(alpha: 0.09),
                    const Color(0xFF06B6D4).withValues(alpha: 0.05),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.02),
                  ],
          ),
          border: Border.all(
            color: isUnread
                ? _accent.withValues(alpha: 0.30)
                : Colors.white.withValues(alpha: 0.07),
          ),
          boxShadow: isUnread
              ? [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.14),
                    blurRadius: 22,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              splashColor: _accent.withValues(alpha: 0.10),
              highlightColor: _accent.withValues(alpha: 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 112,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _TournamentCover(url: tournamentCover),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.05),
                                Colors.black.withValues(alpha: 0.78),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          top: 12,
                          child: Row(
                            children: [
                              _StatusLabel(status: status),
                              const Spacer(),
                              Text(
                                _formatTime(notification.createdAt),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isUnread) ...[
                                const SizedBox(width: 7),
                                const _UnreadDot(),
                              ],
                            ],
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 12,
                          child: Text(
                            tournamentName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RequesterAvatar(url: requesterAvatar),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$requesterLabel ha solicitado unirse a tu torneo',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(
                                    alpha: isUnread ? 0.94 : 0.70,
                                  ),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  height: 1.24,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Nueva solicitud de inscripcion para $tournamentName',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.52),
                                  fontSize: 12.5,
                                  height: 1.30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (sport.isNotEmpty)
                          _InfoChip(icon: Icons.sports_rounded, label: sport),
                        if (location.isNotEmpty)
                          _InfoChip(icon: Icons.place_rounded, label: location),
                        if (participantCount != null &&
                            maxParticipants != null &&
                            maxParticipants > 0)
                          _InfoChip(
                            icon: Icons.people_alt_rounded,
                            label: '$participantCount / $maxParticipants',
                          ),
                      ],
                    ),
                  ),
                  _Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Requiere revision administrativa',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _accent.withValues(alpha: 0.92),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _ReviewButton(onTap: onTap),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _read(Map<String, dynamic> data, String key, {String fallback = ''}) {
    final value = data[key]?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0x00EF4444), Color(0x33EF4444)],
        ),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return 'Hace ${(diff.inDays / 7).floor()} sem';
  }
}

class _TournamentCover extends StatelessWidget {
  const _TournamentCover({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF3F2E12), Color(0xFF064E3B)],
        ),
      ),
      child: const Align(
        alignment: Alignment.center,
        child: Icon(
          Icons.emoji_events_rounded,
          color: Color(0xFFFFD166),
          size: 42,
        ),
      ),
    );
  }
}

class _RequesterAvatar extends StatelessWidget {
  const _RequesterAvatar({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url.isNotEmpty;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: JoinRequestNotificationCard._accent.withValues(alpha: 0.14),
        border: Border.all(
          color: JoinRequestNotificationCard._accent.withValues(alpha: 0.32),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasUrl
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    return const Icon(
      Icons.person_add_alt_1_rounded,
      color: JoinRequestNotificationCard._accent,
      size: 23,
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      'approved' => (
        'APROBADA',
        JoinRequestNotificationCard._reviewColor,
        Icons.check_circle_rounded,
      ),
      'rejected' => ('RECHAZADA', Color(0xFFEF4444), Icons.cancel_rounded),
      'cancelled' => ('CANCELADA', Color(0xFF94A3B8), Icons.block_rounded),
      _ => (
        'NUEVA SOLICITUD',
        JoinRequestNotificationCard._accent,
        Icons.pending_actions_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        color: Colors.black.withValues(alpha: 0.44),
        border: Border.all(color: color.withValues(alpha: 0.58)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.62,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.52)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewButton extends StatelessWidget {
  const _ReviewButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
            ),
            border: Border.all(color: Color(0x5522C55E)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.rate_review_rounded, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                'Revisar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: JoinRequestNotificationCard._accent,
        boxShadow: [
          BoxShadow(
            color: JoinRequestNotificationCard._accent.withValues(alpha: 0.65),
            blurRadius: 7,
          ),
        ],
      ),
    );
  }
}
