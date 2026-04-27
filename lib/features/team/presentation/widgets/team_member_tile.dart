import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TeamMemberTile  ·  Widget reutilizable para listar miembros
//
//  Muestra: avatar circular + nombre/nickname + badge admin (opcional)
//  Opcionalmente incluye un trailing widget (toggle switch, botón eliminar…)
// ─────────────────────────────────────────────────────────────────────────────

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
  });

  final String displayName;
  final String nickname;
  final String? photoUrl;
  final bool isAdmin;
  final bool showAdminBadge;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            // ── Avatar ──
            _buildAvatar(),
            const SizedBox(width: 14),

            // ── Info ──
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
                      if (isAdmin && showAdminBadge) ...[
                        const SizedBox(width: 8),
                        _buildAdminBadge(),
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

            // ── Trailing ──
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
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
            : const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
              ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
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

  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.admin_panel_settings_rounded,
            size: 12,
            color: Color(0xFFB0A8FF),
          ),
          SizedBox(width: 4),
          Text(
            'Admin',
            style: TextStyle(
              color: Color(0xFFB0A8FF),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
