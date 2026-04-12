import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../widgets/step_card.dart';

/// Paso 7 — Review: Resumen de solo lectura de todos los datos para
/// confirmación final antes de crear el torneo.
class Step7Review extends StatelessWidget {
  const Step7Review({
    super.key,
    required this.coverBytes,
    required this.name,
    required this.description,
    required this.sport,
    required this.eventDate,
    required this.registrationDeadline,
    required this.bracketPublishDate,
    required this.location,
    required this.hasCoordinates,
    required this.maxParticipants,
    required this.membersPerTeam,
    required this.accessType,
    required this.rulesPreview,
    required this.contactEmail,
    required this.contactPhone,
    required this.contactLinks,
    required this.admins,
  });

  final Uint8List? coverBytes;
  final String name;
  final String description;
  final String sport;
  final String eventDate;
  final String? registrationDeadline;
  final String? bracketPublishDate;
  final String location;
  final bool hasCoordinates;
  final String maxParticipants;
  final String? membersPerTeam;
  final String accessType;
  final String rulesPreview;
  final String contactEmail;
  final String? contactPhone;
  final List<String> contactLinks;
  final List<String> admins;

  @override
  Widget build(BuildContext context) {
    return StepCard(
      icon: Icons.checklist_rounded,
      title: '¡Casi listo! 🎉',
      subtitle:
          'Revisa toda la información antes de crear el torneo. Pulsa «Crear torneo» para confirmar.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Portada ──
          if (coverBytes != null && coverBytes!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                coverBytes!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Identidad ──
          _ReviewSection(
            icon: Icons.badge_rounded,
            title: 'Identidad',
            children: [
              _ReviewRow(label: 'Nombre', value: name),
              _ReviewRow(label: 'Descripción', value: description),
            ],
          ),

          // ── Disciplina ──
          _ReviewSection(
            icon: Icons.sports_rounded,
            title: 'Disciplina',
            children: [_ReviewRow(label: 'Deporte', value: sport)],
          ),

          // ── Cronograma ──
          _ReviewSection(
            icon: Icons.calendar_month_rounded,
            title: 'Cronograma',
            children: [
              _ReviewRow(label: 'Fecha del evento', value: eventDate),
              if (registrationDeadline != null)
                _ReviewRow(
                  label: 'Límite inscripción',
                  value: registrationDeadline!,
                ),
              if (bracketPublishDate != null)
                _ReviewRow(
                  label: 'Publicación cuadros',
                  value: bracketPublishDate!,
                ),
            ],
          ),

          // ── Ubicación ──
          _ReviewSection(
            icon: Icons.location_on_rounded,
            title: 'Ubicación',
            children: [
              _ReviewRow(label: 'Lugar', value: location),
              _ReviewRow(
                label: 'Coordenadas',
                value: hasCoordinates ? '✅ Marcadas en el mapa' : '—',
              ),
            ],
          ),

          // ── Logística ──
          _ReviewSection(
            icon: Icons.tune_rounded,
            title: 'Logística',
            children: [
              _ReviewRow(label: 'Participantes', value: maxParticipants),
              if (membersPerTeam != null)
                _ReviewRow(label: 'Miembros/equipo', value: membersPerTeam!),
              _ReviewRow(label: 'Acceso', value: accessType),
            ],
          ),

          // ── Reglamento ──
          _ReviewSection(
            icon: Icons.gavel_rounded,
            title: 'Reglamento',
            children: [
              _ReviewRow(
                label: 'Reglas',
                value: rulesPreview.length > 120
                    ? '${rulesPreview.substring(0, 120)}...'
                    : rulesPreview,
              ),
            ],
          ),

          // ── Staff y Soporte ──
          _ReviewSection(
            icon: Icons.support_agent_rounded,
            title: 'Staff y Soporte',
            children: [
              _ReviewRow(label: 'Email', value: contactEmail),
              if (contactPhone != null && contactPhone!.isNotEmpty)
                _ReviewRow(label: 'Teléfono', value: contactPhone!),
              if (contactLinks.isNotEmpty)
                _ReviewRow(label: 'Enlaces', value: contactLinks.join('\n')),
              _ReviewRow(
                label: 'Admins',
                value: admins.isEmpty ? 'Solo tú' : admins.join(', '),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sección del review ─────────────────────────────────────────────

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: const Color(0xFF6C63FF), size: 15),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
