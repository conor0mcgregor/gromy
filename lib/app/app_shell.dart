import 'package:flutter/material.dart';

import '../core/icons/my_icons.dart';
import '../core/widgets/glow_orb.dart';
import '../core/widgets/tourney_nav_bar.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/events/presentation/screens/events_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/notidications/presentation/screens/notifications_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/tournament/presentation/screens/create_tournament_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.authController});

  final AuthController? authController;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  late final AuthController _authController;
  late final bool _ownsAuthController;

  @override
  void initState() {
    super.initState();
    _ownsAuthController = widget.authController == null;
    _authController = widget.authController ?? AuthController();
  }

  @override
  void dispose() {
    if (_ownsAuthController) {
      _authController.dispose();
    }
    super.dispose();
  }

  List<Widget> _buildTabs() {
    return [
      const HomeScreen(),
      const EventsScreen(),
      const CreateTournamentScreen(),
      const NotificationsScreen(),
      ProfileScreen(authController: _authController),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _buildTabs();

    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
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
          IndexedStack(
            index: _currentIndex,
            children: tabs,
          ),
        ],
      ),
      bottomNavigationBar: TourneyNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          NavItem(
            icon: MyFlutterApp.logo_gromy,
            activeIcon: MyFlutterApp.logo_gromy,
            iconSize: 24,
            scale: 2.5,
            label: 'Inicio',
          ),
          NavItem(
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_month_rounded,
            label: 'Eventos',
          ),
          NavItem(
            icon: Icons.add,
            activeIcon: Icons.add,
            label: '',
            isCentral: true,
          ),
          NavItem(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications_rounded,
            label: 'Alertas',
            badgeCount: 3,
          ),
          NavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
