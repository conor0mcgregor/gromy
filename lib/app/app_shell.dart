import 'package:flutter/material.dart';

import '../features/events/presentation/screens/events_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/notidications/presentation/screens/notifications_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/tournament/presentation/screens/create_tournament_screen.dart';
import '../core/icons/my_icons.dart';
import '../core/widgets/glow_orb.dart';
import '../core/widgets/tourney_nav_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppShell – demo que muestra cómo usar el widget TourneyNavBar
// ─────────────────────────────────────────────────────────────────────────────

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    EventsScreen(),
    CreateTournamentScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // el body se extiende bajo la nav bar
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo degradado compartido con login/register
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0A1A),
                  Color(0xFF0D0D2B),
                  Color(0xFF12122E),
                ],
              ),
            ),
          ),
          // Esferas ambient (reutilizando GlowOrb de lib/widgets)
          Positioned(
            top: -80,
            right: -60,
            child: GlowOrb(
              color: const Color(0xFF6C63FF).withOpacity(0.28),
              size: 260,
            ),
          ),
          Positioned(
            bottom: 100,
            left: -70,
            child: GlowOrb(
              color: const Color(0xFF00D4FF).withOpacity(0.18),
              size: 220,
            ),
          ),
          // Página activa
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: child,
            ),
            child: KeyedSubtree(
              key: ValueKey(_currentIndex),
              child: _pages[_currentIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: TourneyNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          NavItem(
              icon: MyFlutterApp.logo_gromy,
              activeIcon: MyFlutterApp.logo_gromy,
              iconSize: 24, // Tamaño físico real de la "caja"
              scale: 2.5,   // Tamaño visual pintado
              label: 'Inicio'),
          NavItem(
              icon: Icons.calendar_today_outlined,
              activeIcon: Icons.calendar_month_rounded,
              label: 'Eventos'),
          NavItem(
              icon: Icons.add,
              activeIcon: Icons.add,
              label: '',
              isCentral: true),
          NavItem(
              icon: Icons.notifications_outlined,
              activeIcon: Icons.notifications_rounded,
              label: 'Alertas',
              badgeCount: 3), // badge de demo
          NavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Perfil'),
        ],
      ),
    );
  }
}


