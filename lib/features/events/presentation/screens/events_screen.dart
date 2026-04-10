import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gromy/core/widgets/glass_tab_bar.dart';

import '../controllers/events_controller.dart';
import 'admin_tournaments_tab.dart';
import 'inscribed_tournaments_tab.dart';
import 'my_tournaments_tab.dart';

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
      length: 3,
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
                      'Gestiona tus torneos y tus inscripciones',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassTabBar(
                      tabs: const [
                        GlassTab(label: 'Mis torneos',   icon: Icons.emoji_events_rounded),
                        GlassTab(label: 'Admin', icon: Icons.admin_panel_settings_outlined),
                        GlassTab(label: 'Inscripciones',    icon: Icons.person_rounded),
                      ],
                    )
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    MyTournamentsTab(controller: _controller),
                    AdminTournamentsTab(controller: _controller),
                    const InscribedTournamentsTab(),
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


class EventsLoadingState extends StatelessWidget {
  const EventsLoadingState({super.key});

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

class EventsErrorState extends StatelessWidget {
  const EventsErrorState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return EventsEmptyState(
      title: 'Ups…',
      message: message,
      icon: Icons.error_outline_rounded,
    );
  }
}

class EventsEmptyState extends StatelessWidget {
  const EventsEmptyState({
    super.key,
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
