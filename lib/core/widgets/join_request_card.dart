import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/inscription/domain/models/join_request.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  JoinRequestCard  ·  Widget reutilizable
//
//  Muestra una solicitud de inscripción con acciones de aprobar/rechazar.
// ─────────────────────────────────────────────────────────────────────────────

class JoinRequestCard extends StatelessWidget {
  const JoinRequestCard({
    super.key,
    required this.request,
    this.entityName,
    this.entityAvatarUrl,
    this.onApprove,
    this.onReject,
    this.onTap,
    this.isLoading = false,
  });

  final JoinRequest request;
  final String? entityName;
  final String? entityAvatarUrl;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTap;
  final bool isLoading;

  Color get _statusColor => switch (request.status) {
        JoinRequestStatus.pending => const Color(0xFFFFB347),
        JoinRequestStatus.approved => const Color(0xFF22C55E),
        JoinRequestStatus.rejected => const Color(0xFFFF4D6A),
        JoinRequestStatus.cancelled => Colors.white38,
      };

  String get _statusLabel => switch (request.status) {
        JoinRequestStatus.pending => 'Pendiente',
        JoinRequestStatus.approved => 'Aprobada',
        JoinRequestStatus.rejected => 'Rechazada',
        JoinRequestStatus.cancelled => 'Cancelada',
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: avatar + name + status badge
                Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          const Color(0xFF6C63FF).withValues(alpha: 0.2),
                      backgroundImage: entityAvatarUrl != null
                          ? NetworkImage(entityAvatarUrl!)
                          : null,
                      child: entityAvatarUrl == null
                          ? Icon(
                              request.entityType.name == 'team'
                                  ? Icons.groups_rounded
                                  : Icons.person_rounded,
                              color: const Color(0xFF6C63FF),
                              size: 20,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Name + date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entityName ?? 'Sin nombre',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm', 'es')
                                .format(request.createdAt),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: _statusColor.withValues(alpha: 0.15),
                        border: Border.all(
                          color: _statusColor.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        _statusLabel,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                // Action buttons (only for pending)
                if (request.isPending && !isLoading) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Reject
                      Expanded(
                        child: _ActionButton(
                          label: 'Rechazar',
                          icon: Icons.close_rounded,
                          color: const Color(0xFFFF4D6A),
                          onTap: onReject,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Approve
                      Expanded(
                        child: _ActionButton(
                          label: 'Aprobar',
                          icon: Icons.check_rounded,
                          color: const Color(0xFF22C55E),
                          onTap: onApprove,
                        ),
                      ),
                    ],
                  ),
                ],

                if (isLoading) ...[
                  const SizedBox(height: 14),
                  const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  ),
                ],

                // Rejection reason
                if (request.status == JoinRequestStatus.rejected &&
                    request.rejectionReason != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFFF4D6A).withValues(alpha: 0.08),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color:
                              const Color(0xFFFF4D6A).withValues(alpha: 0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            request.rejectionReason!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
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
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withValues(alpha: 0.12),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
