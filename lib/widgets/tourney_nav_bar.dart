import 'dart:ui';
import 'package:flutter/material.dart';


/// Modelo de datos para cada elemento de la barra de navegación.
class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isCentral;
  final int badgeCount;
  final double? iconSize;
  final double scale;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    this.label = '',
    this.isCentral = false,
    this.badgeCount = 0,
    this.iconSize,
    this.scale = 1.0,
  });
}

/// Barra de navegación inferior reutilizable con glassmorphism.
///
/// Parámetros:
///   [items]        - Lista de objetos NavItem con la información de cada botón.
///   [currentIndex] - Índice de la pestaña actualmente activa.
///   [onTap]        - Callback que se llama al tocar un ítem (recibe el índice).
class TourneyNavBar extends StatelessWidget {
  const TourneyNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D2B).withOpacity(0.75),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final item = items[i];
                final isActive = currentIndex == i;

                if (item.isCentral) {
                  return Expanded(
                    child: _CentralButton(
                      isActive: isActive,
                      icon: item.icon,
                      onTap: () => onTap(i),
                    ),
                  );
                }

                return Expanded(
                  child: _NavBarItem(
                    item: item,
                    isActive: isActive,
                    onTap: () => onTap(i),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subwidgets internos de la barra de navegación
// ─────────────────────────────────────────────────────────────────────────────

/// Ítem normal (con animación de píldora activa y badge)
class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Píldora activa + ícono
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF6C63FF).withOpacity(0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Ícono con ShaderMask cuando activo
                  Transform.scale(
                    scale: item.scale,
                    child: isActive
                        ? ShaderMask(
                            shaderCallback: (b) => const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                            ).createShader(b),
                            child: Icon(item.activeIcon,
                                color: Colors.white, size: item.iconSize ?? 24),
                          )
                        : Icon(item.icon,
                            color: Colors.white.withOpacity(0.4), size: item.iconSize ?? 24),
                  ),

                  // Badge de notificaciones
                  if (item.badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4D6A),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0D0D2B),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            item.badgeCount > 9 ? '9+' : '${item.badgeCount}',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 3),

            // Texto del ítem (Label)
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withOpacity(0.35),
                letterSpacing: 0.2,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón central (ej. "Crear torneo") con gradiente elevado
class _CentralButton extends StatelessWidget {
  const _CentralButton({
    required this.isActive,
    required this.icon,
    required this.onTap,
  });

  final bool isActive;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 68,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            width: isActive ? 52 : 48,
            height: isActive ? 52 : 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
              ),
              borderRadius: BorderRadius.circular(isActive ? 18 : 16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF)
                      .withOpacity(isActive ? 0.6 : 0.35),
                  blurRadius: isActive ? 20 : 12,
                  spreadRadius: isActive ? 2 : 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isActive ? 28 : 26,
            ),
          ),
        ),
      ),
    );
  }
}
