import 'package:flutter/material.dart';
import 'package:gromy/features/team/presentation/widgets/admin_chip.dart';

class TeamMemberTile extends StatelessWidget {
  const TeamMemberTile({
    super.key,
    required this.displayName,
    required this.nickname,
    this.photoUrl,
    this.isAdmin = false,
    this.showAdminBadge = true,
    this.trailing,
    this.onTap,
    this.statusLabel,
    this.statusColor,
    this.muted = false,
  });

  final String displayName;
  final String nickname;
  final String? photoUrl;
  final bool isAdmin;
  final bool showAdminBadge;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? statusLabel;
  final Color? statusColor;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final accent = statusColor ?? const Color(0xFFF59E0B);

    return Opacity(
      opacity: muted ? 0.78 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: muted
                ? accent.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: muted
                  ? accent.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              _buildAvatar(accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 8),
                          AdminChip(small: !showAdminBadge),
                        ],
                        if (statusLabel != null) ...[
                          const SizedBox(width: 8),
                          _StatusChip(label: statusLabel!, color: accent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@$nickname',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Color accent) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final initials = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : nickname.isNotEmpty
        ? nickname[0].toUpperCase()
        : '?';

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasPhoto
            ? null
            : LinearGradient(
                colors: muted
                    ? [accent.withValues(alpha: 0.95), const Color(0xFFFDE68A)]
                    : const [Color(0xFF6C63FF), Color(0xFF00D4FF)],
              ),
        border: Border.all(
          color: muted
              ? accent.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
