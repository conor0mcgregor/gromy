import 'package:flutter/material.dart';

import '../../../adminTournament/presentation/screens/tournament_management_screen.dart';
import '../../../home/presentation/widgets/tournament_card.dart';
import '../../data/model/app_tournament.dart';
import '../controllers/my_tournaments_list_controller.dart';
import 'create_tournament/create_tournament_screen.dart';

class MyTournamentScreen extends StatefulWidget {
  const MyTournamentScreen({super.key});

  @override
  State<MyTournamentScreen> createState() => _MyTournamentScreenState();
}

class _MyTournamentScreenState extends State<MyTournamentScreen> {
  late final MyTournamentsListController _controller;
  bool _isCreatingTournament = false;

  @override
  void initState() {
    super.initState();
    _controller = MyTournamentsListController();
  }

  void _toggleCreateMode() {
    setState(() {
      _isCreatingTournament = !_isCreatingTournament;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
                        ).createShader(b),
                        child: Text(
                          _isCreatingTournament ? 'Crear Torneo' : 'Mis Torneos',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isCreatingTournament 
                            ? 'Configura tu nuevo evento'
                            : 'Torneos que administras o creaste',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: Container(
                      key: ValueKey(_isCreatingTournament),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isCreatingTournament 
                              ? [const Color(0xFF4A4480), const Color(0xFF008FA8)]
                              : [const Color(0xFF6C63FF), const Color(0xFF00D4FF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isCreatingTournament ? Icons.close_rounded : Icons.add_rounded, 
                          color: Colors.white
                        ),
                        onPressed: _toggleCreateMode,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _isCreatingTournament
                    ? const CreateTournamentScreen(key: ValueKey('create_screen'))
                    : KeyedSubtree(
                        key: const ValueKey('list_screen'),
                        child: _buildTournamentList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentList() {
    if (_controller.currentUid == null) {
      return const _TournamentEmptyState(
        title: 'Inicia sesión',
        message: 'Necesitas iniciar sesión para ver tus torneos.',
        icon: Icons.lock_outline_rounded,
      );
    }

    return StreamBuilder<List<AppTournament>>(
      stream: _controller.watchAdministeredTournaments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _TournamentLoadingState();
        }

        if (snapshot.hasError) {
          return _TournamentErrorState(message: '${snapshot.error}');
        }

        final managedTournaments = snapshot.data ?? [];

        if (managedTournaments.isEmpty) {
          return const _TournamentEmptyState(
            title: 'Sin torneos',
            message: 'Aún no has creado ni administras ningún torneo.',
            icon: Icons.admin_panel_settings_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          itemCount: managedTournaments.length,
          itemBuilder: (context, index) {
            final tournament = managedTournaments[index];
            final isCreator = tournament.organizerUid == _controller.currentUid;
            
            return TournamentCard(
              tournament: tournament,
              isMyTournament: isCreator,
              animationDelay: Duration(milliseconds: 70 * index),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TournamentManagementScreen(
                    tournament: tournament,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TournamentLoadingState extends StatelessWidget {
  const _TournamentLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              valueColor: AlwaysStoppedAnimation(Color(0xFF00D4FF)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Cargando torneos...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentErrorState extends StatelessWidget {
  const _TournamentErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    debugPrint(message);
    return _TournamentEmptyState(
      title: 'Ups…',
      message: message,
      icon: Icons.error_outline_rounded,
    );
  }
}

class _TournamentEmptyState extends StatelessWidget {
  const _TournamentEmptyState({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
              ).createShader(b),
              child: Icon(icon, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
              ).createShader(b),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.4),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
