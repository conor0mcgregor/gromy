import 'package:flutter/material.dart';

import '../../domain/entities/app_notification.dart';

class TournamentInvitationCard extends StatefulWidget {
  const TournamentInvitationCard({
    super.key,
    required this.notification,
    required this.onDismiss,
    required this.onTap,
    required this.onAccept,
    required this.onReject,
  });

  final AppNotification notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;
  final Future<bool> Function() onAccept;
  final Future<bool> Function() onReject;

  @override
  State<TournamentInvitationCard> createState() =>
      _TournamentInvitationCardState();
}

enum _CardAction { idle, accepting, rejecting }

class _TournamentInvitationCardState extends State<TournamentInvitationCard> {
  _CardAction _action = _CardAction.idle;

  bool get _isBusy => _action != _CardAction.idle;

  Future<void> _handleAccept() async {
    if (_isBusy) return;
    setState(() => _action = _CardAction.accepting);
    await widget.onAccept();
    if (mounted) setState(() => _action = _CardAction.idle);
  }

  Future<void> _handleReject() async {
    if (_isBusy) return;
    setState(() => _action = _CardAction.rejecting);
    await widget.onReject();
    if (mounted) setState(() => _action = _CardAction.idle);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.notification.data;
    final isUnread = widget.notification.isUnread;
    final status = data['status']?.toString() ?? 'pending';
    final isPending = status == 'pending';
    final name = _read(
      data,
      'tournamentName',
      fallback: widget.notification.title,
    );
    final description = _read(data, 'tournamentDescription');
    final location = _read(data, 'tournamentLocation');
    final sport = _read(data, 'tournamentSport');
    final inviter = _read(data, 'inviterName', fallback: 'Organizador');
    final cover = _read(data, 'tournamentPortadaUrl');
    final count = (data['tournamentParticipantCount'] as num?)?.toInt() ?? 0;
    final max = (data['tournamentMaxParticipants'] as num?)?.toInt() ?? 0;

    return Dismissible(
      key: ValueKey(widget.notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDismiss(),
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
                    const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                    const Color(0xFF06B6D4).withValues(alpha: 0.10),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.02),
                  ],
          ),
          border: Border.all(
            color: isUnread
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.30)
                : Colors.white.withValues(alpha: 0.07),
          ),
          boxShadow: isUnread
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.13),
                    blurRadius: 20,
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
              onTap: widget.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Cover(cover: cover),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _TypeLabel(status: status),
                                  const Spacer(),
                                  Text(
                                    _formatTime(widget.notification.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                  ),
                                  if (isUnread) const SizedBox(width: 6),
                                  if (isUnread) const _UnreadDot(),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Te invito $inviter',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF67E8F9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.56),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  _Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (sport.isNotEmpty)
                          _InfoChip(icon: Icons.sports_rounded, label: sport),
                        if (location.isNotEmpty)
                          _InfoChip(icon: Icons.place_rounded, label: location),
                        if (max > 0)
                          _InfoChip(
                            icon: Icons.people_alt_rounded,
                            label: '$count / $max',
                          ),
                      ],
                    ),
                  ),
                  if (isPending) ...[
                    _Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Rechazar',
                              icon: Icons.close_rounded,
                              color: const Color(0xFFEF4444),
                              isLoading: _action == _CardAction.rejecting,
                              isDisabled: _isBusy,
                              onTap: _handleReject,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: _ActionButton(
                              label: 'Aceptar e inscribirme',
                              icon: Icons.check_rounded,
                              color: const Color(0xFF22C55E),
                              filled: true,
                              isLoading: _action == _CardAction.accepting,
                              isDisabled: _isBusy,
                              onTap: _handleAccept,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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

class _Cover extends StatelessWidget {
  const _Cover({required this.cover});

  final String cover;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
        ),
      ),
      child: cover.isEmpty
          ? const Icon(Icons.lock_rounded, color: Colors.white, size: 30)
          : ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                cover,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.lock_rounded, color: Colors.white),
              ),
            ),
    );
  }
}

class _TypeLabel extends StatelessWidget {
  const _TypeLabel({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'accepted' => 'ACEPTADA',
      'rejected' => 'RECHAZADA',
      _ => 'INVITACION PRIVADA',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
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
        maxWidth: MediaQuery.of(context).size.width * 0.6,
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
                color: Colors.white.withValues(alpha: 0.58),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final bool isDisabled;
  final bool filled;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isDisabled ? null : onTap,
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: filled
                  ? color.withValues(alpha: 0.82)
                  : Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          filled ? Colors.white : color,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: filled ? Colors.white : color,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: filled ? Colors.white : color,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
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
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF8B5CF6),
      ),
    );
  }
}
