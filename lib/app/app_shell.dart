import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/icons/my_icons.dart';
import '../core/widgets/glow_orb.dart';
import '../core/widgets/tourney_nav_bar.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/events/presentation/screens/events_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/notifications/presentation/controllers/notifications_controller.dart';
import '../features/notifications/presentation/navigation/notification_navigation_handler.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/inscription/data/models/join_request.dart';
import '../features/inscription/screen/preinscription_screen.dart';
import '../features/inscription/screen/tournament_join_requests_screen.dart';
import '../features/tournament/data/services/firestore_tournament_service.dart';
import '../features/tournament/presentation/screens/my_tournament_screen.dart';
import 'notification_routes.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.authController, this.initialIndex = 0});

  final AuthController? authController;
  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  late final AuthController _authController;
  late final bool _ownsAuthController;
  late final NotificationsController _controllerNotifications;
  late final List<Widget?> _tabs;

  String? _userId;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _ownsAuthController = widget.authController == null;
    _authController = widget.authController ?? AuthController();
    _controllerNotifications = NotificationsController();
    _tabs = List<Widget?>.filled(5, null);

    try {
      _userId = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      _userId = null;
    }
    if (_userId != null) {
      _controllerNotifications.init(_userId!);
    }
    _registerNotificationRoutes();
  }

  void _registerNotificationRoutes() {
    NotificationNavigationHandler.instance.registerRoutes({
      '/tournament/join-requests': (context, data) async {
        final tournamentId = data['tournamentId']?.toString();
        if (tournamentId == null || tournamentId.isEmpty) return;
        final tournament = await FirestoreTournamentService().getTournament(
          tournamentId,
        );
        if (!context.mounted) return;
        if (tournament == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El torneo ya no existe.')),
          );
          return;
        }
        final requestId = data['requestId']?.toString();
        final notificationId =
            data['notificationId']?.toString() ?? data['id']?.toString();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TournamentJoinRequestsScreen(
              tournament: tournament,
              initialRequestId: requestId,
              initialStatusFilter: JoinRequestStatus.pending,
              onRequestHandled: (request) {
                if (notificationId == null || notificationId.isEmpty) return;
                _controllerNotifications.markNotificationAsRead(notificationId);
                _controllerNotifications
                    .updateNotificationData(notificationId, {
                      'status': request.status.name,
                      'reviewedAt': DateTime.now().toIso8601String(),
                    });
              },
            ),
          ),
        );
      },
      '/tournament/detail': (context, data) async {
        final tournamentId = data['tournamentId'] as String?;
        if (tournamentId == null || tournamentId.isEmpty) return;
        final tournament = await FirestoreTournamentService().getTournament(
          tournamentId,
        );
        if (tournament == null || !context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PreinscriptionScreen(tournament: tournament),
          ),
        );
      },
    });

    // Registrar rutas de navegación para push notifications
    NotificationRoutes.register();
  }

  @override
  void dispose() {
    _controllerNotifications.dispose();
    if (_ownsAuthController) {
      _authController.dispose();
    }
    super.dispose();
  }

  Widget _buildTab(int index) {
    return _tabs[index] ??= switch (index) {
      0 => const HomeScreen(),
      1 => const EventsScreen(),
      2 => const MyTournamentScreen(),
      3 => NotificationsScreen(controller: _controllerNotifications),
      _ => ProfileScreen(authController: _authController),
    };
  }

  @override
  Widget build(BuildContext context) {
    _buildTab(_currentIndex);

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
              color: const Color(0xFF6C63FF).withValues(alpha: 0.28),
              size: 260,
            ),
          ),
          Positioned(
            bottom: 100,
            left: -70,
            child: GlowOrb(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.18),
              size: 220,
            ),
          ),
          Stack(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                if (_tabs[i] != null)
                  Offstage(
                    offstage: _currentIndex != i,
                    child: TickerMode(
                      enabled: _currentIndex == i,
                      child: _tabs[i]!,
                    ),
                  ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _controllerNotifications,
        builder: (context, _) {
          return TourneyNavBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: [
              const NavItem(
                icon: MyFlutterApp.logo_gromy,
                activeIcon: MyFlutterApp.logo_gromy,
                iconSize: 24,
                scale: 2.5,
                label: 'Inicio',
              ),
              const NavItem(
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_month_rounded,
                label: 'Eventos',
              ),
              const NavItem(
                icon: Icons.emoji_events_outlined,
                activeIcon: IconPack1.trophy_1,
                label: 'mis torneos',
                isCentral: false,
              ),
              NavItem(
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications_rounded,
                label: 'Alertas',
                badgeCount: _controllerNotifications.unreadCount,
              ),
              const NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Perfil',
              ),
            ],
          );
        },
      ),
    );
  }
}
