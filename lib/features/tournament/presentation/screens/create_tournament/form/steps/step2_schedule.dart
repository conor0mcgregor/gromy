import 'package:flutter/material.dart';
import '../widgets/step_card.dart';
import '../widgets/form_fields.dart';
import '../widgets/form_helpers.dart';

/// Paso 2 — Cronograma: Fecha del evento, límite de inscripción y publicación
/// de los cuadros / enfrentamientos.
class Step2Schedule extends StatelessWidget {
  const Step2Schedule({
    super.key,
    required this.eventDate,
    required this.eventDateError,
    required this.onPickEventDate,
    required this.registrationDeadline,
    required this.registrationDeadlineError,
    required this.onPickRegistrationDeadline,
    required this.bracketPublishDate,
    required this.bracketPublishDateError,
    required this.onPickBracketPublishDate,
    required this.formatDate,
  });

  final DateTime? eventDate;
  final String? eventDateError;
  final VoidCallback onPickEventDate;

  final DateTime? registrationDeadline;
  final String? registrationDeadlineError;
  final VoidCallback onPickRegistrationDeadline;

  final DateTime? bracketPublishDate;
  final String? bracketPublishDateError;
  final VoidCallback onPickBracketPublishDate;

  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    return StepCard(
      icon: Icons.calendar_month_rounded,
      title: 'Cronograma',
      subtitle:
          'Define las fechas clave: el día del evento, el cierre de inscripciones y cuándo se publican los cuadros.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fecha del evento (obligatoria) ──
          const FieldLabel(label: 'Fecha del evento *'),
          const SizedBox(height: 8),
          PickerTile(
            icon: Icons.event_rounded,
            value: eventDate == null
                ? 'Elige la fecha del evento'
                : formatDate(eventDate!),
            isEmpty: eventDate == null,
            errorText: eventDateError,
            onTap: onPickEventDate,
          ),
          const SizedBox(height: 20),

          // ── Límite de inscripción (opcional) ──
          const FieldLabel(label: 'Límite de inscripción (opcional)'),
          const SizedBox(height: 4),
          Text(
            'Fecha máxima para que los participantes se apunten.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          PickerTile(
            icon: Icons.timer_outlined,
            value: registrationDeadline == null
                ? 'Sin fecha límite'
                : formatDate(registrationDeadline!),
            isEmpty: registrationDeadline == null,
            errorText: registrationDeadlineError,
            onTap: onPickRegistrationDeadline,
          ),
          const SizedBox(height: 20),

          // ── Publicación de cuadros (opcional) ──
          const FieldLabel(label: 'Publicación de cuadros (opcional)'),
          const SizedBox(height: 4),
          Text(
            'Cuándo se revelarán los enfrentamientos.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          PickerTile(
            icon: Icons.account_tree_rounded,
            value: bracketPublishDate == null
                ? 'Sin fecha definida'
                : formatDate(bracketPublishDate!),
            isEmpty: bracketPublishDate == null,
            errorText: bracketPublishDateError,
            onTap: onPickBracketPublishDate,
          ),
        ],
      ),
    );
  }
}
