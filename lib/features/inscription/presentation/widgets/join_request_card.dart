import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/join_request.dart';
import '../models/join_request_display.dart';

class JoinRequestCard extends StatelessWidget {
  const JoinRequestCard({
    super.key,
    required this.display,
    required this.isProcessing,
    this.onApprove,
    this.onReject,
    this.onTap,
  });

  final JoinRequestDisplay display;
  final bool isProcessing;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  static const _accent = Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    final request = display.request;
    final canReview = request.status == JoinRequestStatus.pending;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(
                  url: display.avatarUrl,
                  isTeam: request.entityType.name == 'team',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        display.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        display.subtitle ??
                            DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(request.createdAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.48),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(status: request.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Solicitado el ${DateFormat('dd/MM/yyyy HH:mm').format(request.createdAt)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.52),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (request.responses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: request.responses.take(3).map((response) {
                  return _ResponseChip(label: response.fieldLabelSnapshot);
                }).toList(),
              ),
            ],
            if (canReview) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing ? null : onReject,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF4D6A),
                        side: const BorderSide(color: Color(0x66FF4D6A)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isProcessing ? null : onApprove,
                      icon: isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Aprobar'),
                      style: FilledButton.styleFrom(backgroundColor: _accent),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.isTeam});

  final String? url;
  final bool isTeam;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.trim().isNotEmpty;
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.18),
      backgroundImage: hasUrl ? NetworkImage(url!) : null,
      child: hasUrl
          ? null
          : Icon(
              isTeam ? Icons.groups_rounded : Icons.person_rounded,
              color: const Color(0xFF6C63FF),
            ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final JoinRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      JoinRequestStatus.pending => ('Pendiente', const Color(0xFFF59E0B)),
      JoinRequestStatus.approved => ('Aprobada', const Color(0xFF22C55E)),
      JoinRequestStatus.rejected => ('Rechazada', const Color(0xFFFF4D6A)),
      JoinRequestStatus.cancelled => ('Cancelada', const Color(0xFF94A3B8)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ResponseChip extends StatelessWidget {
  const _ResponseChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.06),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.62),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
