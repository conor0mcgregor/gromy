import 'package:flutter/material.dart';
import 'package:gromy/core/widgets/glass_tab_bar.dart';

import '../controllers/events_controller.dart';
import 'save_tournaments_tab.dart';
import '../../../tournament/presentation/screens/inscribed_tournaments/inscribed_tournaments_tab.dart';

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
                    GlassTabBar(
                      tabs: const [
                        GlassTab(label: 'Guardados', icon: Icons.bookmark),
                        GlassTab(label: 'Inscripciones',    icon: Icons.person_rounded),
                      ],
                    )
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    SaveTournamentsTab(controller: _controller),
                    InscribedTournamentsTab(controller: _controller),
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
    print(message);
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
