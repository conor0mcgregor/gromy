import 'package:flutter/material.dart';

import '../controllers/events_controller.dart';
import 'events_screen.dart';

class SaveTournamentsTab extends StatelessWidget {
  const SaveTournamentsTab({super.key, required this.controller});

  final EventsController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.currentUid == null) {
      return const EventsEmptyState(
        title: 'Inicia sesión',
        message: 'Necesitas iniciar sesión para ver tus eventos guardados.',
        icon: Icons.lock_outline_rounded,
      );
    }

    return const EventsEmptyState(
      title: 'Próximamente',
      message: 'La funcionalidad de eventos guardados y favoritos se encuentra en construcción.',
      icon: Icons.construction_rounded,
    );
  }
}

