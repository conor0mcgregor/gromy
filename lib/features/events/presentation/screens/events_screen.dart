import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../home/presentation/widgets/tournament_card.dart';
import '../../../tournament/data/model/app_tournament.dart';
import '../controllers/events_controller.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late final EventsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EventsController();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
                      ).createShader(b),
                      child: const Text(
                        'Eventos',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gestiona tus torneos y futuras inscripciones',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _GlassTabBar(
                      tabs: [
                        Tab(text: 'Mis Torneos'),
                        Tab(text: 'Inscrito'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _MyTournamentsTab(controller: _controller),
                    const _InscritoEmptyTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassTabBar extends StatelessWidget {
  const _GlassTabBar({required this.tabs});

  final List<Widget> tabs;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.07),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: TabBar(
            tabs: tabs,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.55),
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyTournamentsTab extends StatelessWidget {
  const _MyTournamentsTab({required this.controller});

  final EventsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.currentUid == null) {
      return const _EmptyState(
        title: 'Inicia sesión',
        message: 'Necesitas iniciar sesión para ver tus torneos.',
        icon: Icons.lock_outline_rounded,
      );
    }

    // 1. Primer StreamBuilder: Escucha los torneos que tú administras
    return StreamBuilder<List<AppTournament>>(
      stream: controller.watchMyTournaments(),
      builder: (context, mySnapshot) {

        // 2. Segundo StreamBuilder (Anidado): Escucha a los que estás inscrito
        return StreamBuilder<List<AppTournament>>(
          stream: controller.watchTournamentsAdmin(),
          builder: (context, inscribedSnapshot) {

            // Si ambos están cargando, mostramos la pantalla de carga
            if (mySnapshot.connectionState == ConnectionState.waiting &&
                inscribedSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingState();
            }

            // Manejo de errores de cualquiera de los dos
            if (mySnapshot.hasError) return _ErrorState(message: '${mySnapshot.error}');
            if (inscribedSnapshot.hasError) return _ErrorState(message: '${inscribedSnapshot.error}');

            // Obtenemos los datos de ambas listas
            final myTournaments = mySnapshot.data ?? <AppTournament>[];
            final inscribedTournaments = inscribedSnapshot.data ?? <AppTournament>[];

            // 3. ¡FUSIÓN! Unimos ambas listas en una sola
            // Usamos el operador "spread" (...) para meter todos los elementos juntos
            final allTournaments = [...myTournaments, ...inscribedTournaments];

            if (allTournaments.isEmpty) {
              return const _EmptyState(
                title: 'Aún no tienes torneos',
                message: 'Crea un torneo, pide que te añadan como admin o inscríbete a uno.',
                icon: Icons.emoji_events_outlined,
              );
            }

            // 4. Mostramos la lista única con todos los torneos mezclados
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              itemCount: allTournaments.length,
              itemBuilder: (context, index) {
                final tournament = allTournaments[index];

                // Comprobamos si el torneo actual pertenece a la lista de "Mis Torneos"
                // para decirle a la tarjeta si le pones el diseño de Administrador o no
                final bool isMine = myTournaments.contains(tournament);

                return TournamentCard(
                  tournament: tournament,
                  isMyTournament: isMine,
                  animationDelay: Duration(milliseconds: 70 * index),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _InscritoEmptyTab extends StatelessWidget {
  const _InscritoEmptyTab();

  @override
  Widget build(BuildContext context) {
    return const _EmptyState(
      title: 'Inscripciones',
      message: 'Aún no te has inscrito a ningún torneo.',
      icon: Icons.how_to_reg_outlined,
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

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
            'Cargando...',
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      title: 'Ups…',
      message: message,
      icon: Icons.error_outline_rounded,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
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

