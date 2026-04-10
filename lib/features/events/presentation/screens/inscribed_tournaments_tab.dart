import 'package:flutter/material.dart';

import 'events_screen.dart';

class InscribedTournamentsTab extends StatelessWidget {
  const InscribedTournamentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const EventsEmptyState(
      title: 'Inscripciones',
      message: 'Aún no te has inscrito a ningún torneo.',
      icon: Icons.how_to_reg_outlined,
    );
  }
}
