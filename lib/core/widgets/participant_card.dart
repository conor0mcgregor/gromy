import 'dart:ui';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ParticipantCard  ·  Widget reutilizable
//
//  Muestra los datos de un participante (usuario) de forma compacta:
//    - Izquierda: avatar circular con foto o inicial
//    - Derecha: nickname (negrita) + nombre completo (texto pequeño)
//
//  Reutilizable en ParticipantsScreen, TeamCard (miembros) y cualquier
//  otro lugar de la app que necesite mostrar usuarios.
//
//  Parámetros opcionales:
//    - [trailing]: widget personalizado a la derecha (botón, badge, etc.)
//    - [onTap]: callback al pulsar la card
//    - [showBorder]: muestra borde glassmorphism (true por defecto)
// ─────────────────────────────────────────────────────────────────────────────

class ParticipantCard extends StatelessWidget {
  const ParticipantCard({
    super.key,
    required this.nickname,
    required this.displayName,
    this.photoUrl,
    this.trailing,
    this.onTap,
    this.showBorder = true,
    this.avatarSize = 44,
  });

  /// Nickname del usuario (se muestra con @, en negrita).
  final String nickname;

  /// Nombre completo (nombre + apellido), se muestra debajo del nickname.
  final String displayName;

  /// URL de la foto de perfil. Si es null o vacío, se muestra la inicial.
  final String? photoUrl;

  /// Widget opcional a la derecha de la card.
  final Widget? trailing;

  /// Callback al pulsar la card.
  final VoidCallback? onTap;

  /// Muestra el borde glassmorphism alrededor de la card.
  final bool showBorder;

  /// Tamaño del avatar en píxeles.
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: const Color(0xFF6C63FF).withValues(alpha: 0.06),
        highlightColor: const Color(0xFF6C63FF).withValues(alpha: 0.03),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: showBorder
              ? BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                )
              : null,
          child: Row(
            children: [
              // ── Avatar ────────────────────────────────────────────
              _ParticipantAvatar(
                photoUrl: photoUrl,
                nickname: nickname,
                displayName: displayName,
                size: avatarSize,
              ),
              const SizedBox(width: 14),

              // ── Texto ─────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '@$nickname',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (displayName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        displayName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // ── Trailing ──────────────────────────────────────────
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Avatar circular reutilizable (extrae la lógica para usarlo también
//  en la fila de vista previa de avatares).
// ─────────────────────────────────────────────────────────────────────────────

class ParticipantAvatar extends StatelessWidget {
  const ParticipantAvatar({
    super.key,
    this.photoUrl,
    required this.nickname,
    this.displayName = '',
    this.size = 44,
    this.borderColor,
  });

  final String? photoUrl;
  final String nickname;
  final String displayName;
  final double size;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return _ParticipantAvatar(
      photoUrl: photoUrl,
      nickname: nickname,
      displayName: displayName,
      size: size,
      borderColor: borderColor,
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  const _ParticipantAvatar({
    required this.photoUrl,
    required this.nickname,
    required this.displayName,
    required this.size,
    this.borderColor,
  });

  final String? photoUrl;
  final String nickname;
  final String displayName;
  final double size;
  final Color? borderColor;

  String get _initial {
    if (displayName.isNotEmpty) return displayName[0].toUpperCase();
    if (nickname.isNotEmpty) return nickname[0].toUpperCase();
    return '?';
  }

  bool get _hasPhoto => photoUrl != null && photoUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _hasPhoto
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
              ),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: _hasPhoto
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitial(),
              )
            : _buildInitial(),
      ),
    );
  }

  Widget _buildInitial() {
    final fontSize = size * 0.38;
    return Center(
      child: Text(
        _initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
