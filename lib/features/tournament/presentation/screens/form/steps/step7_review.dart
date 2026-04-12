import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════
//  STEP 7 — REVIEW SCREEN
//  Layout mobile-first: label arriba, valor abajo, ancho completo.
//  Sin StepCard. Secciones independientes con glassmorphism propio.
// ════════════════════════════════════════════════════════════════

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero de confirmación ──────────────────────────────────
        const _ReviewHero(),
        const SizedBox(height: 20),

        // ── Portada ──────────────────────────────────────────────
        if (coverBytes != null && coverBytes!.isNotEmpty) ...[
          _CoverImage(bytes: coverBytes!),
          const SizedBox(height: 20),
        ],

        // ── Identidad ─────────────────────────────────────────────
        InfoSection(
          icon: Icons.badge_rounded,
          title: 'Identidad',
          accentColor: const Color(0xFF6C63FF),
          children: [
            InfoField(label: 'Nombre del torneo', value: name),
            InfoField(label: 'Descripción', value: description, multiline: true),
          ],
        ),

        // ── Disciplina ────────────────────────────────────────────
        InfoSection(
          icon: Icons.sports_rounded,
          title: 'Disciplina',
          accentColor: const Color(0xFF00D4FF),
          children: [
            InfoField(label: 'Deporte', value: sport),
          ],
        ),

        // ── Cronograma ────────────────────────────────────────────
        InfoSection(
          icon: Icons.calendar_month_rounded,
          title: 'Cronograma',
          accentColor: const Color(0xFFA855F7),
          children: [
            InfoField(label: 'Fecha del evento', value: eventDate),
            if (registrationDeadline != null)
              InfoField(
                label: 'Límite de inscripción',
                value: registrationDeadline!,
              ),
            if (bracketPublishDate != null)
              InfoField(
                label: 'Publicación de cuadros',
                value: bracketPublishDate!,
              ),
          ],
        ),

        // ── Ubicación ─────────────────────────────────────────────
        InfoSection(
          icon: Icons.location_on_rounded,
          title: 'Ubicación',
          accentColor: const Color(0xFF22C55E),
          children: [
            InfoField(label: 'Lugar', value: location),
            InfoField(
              label: 'Coordenadas en el mapa',
              value: hasCoordinates ? 'Marcadas correctamente' : 'Sin coordenadas',
              valueColor: hasCoordinates
                  ? const Color(0xFF22C55E)
                  : Colors.white.withValues(alpha: 0.45),
              leadingIcon: hasCoordinates
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              leadingIconColor: hasCoordinates
                  ? const Color(0xFF22C55E)
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),

        // ── Logística ─────────────────────────────────────────────
        InfoSection(
          icon: Icons.tune_rounded,
          title: 'Logística',
          accentColor: const Color(0xFFFFB347),
          children: [
            // Participantes + acceso en fila de dos en pantallas anchas
            _ResponsivePair(
              first: InfoField(
                label: 'Participantes máx.',
                value: maxParticipants,
              ),
              second: InfoField(
                label: 'Acceso',
                value: accessType,
              ),
            ),
            if (membersPerTeam != null)
              InfoField(label: 'Miembros por equipo', value: membersPerTeam!),
          ],
        ),

        // ── Reglamento ────────────────────────────────────────────
        InfoSection(
          icon: Icons.gavel_rounded,
          title: 'Reglamento',
          accentColor: const Color(0xFFFF6B9D),
          children: [
            InfoField(
              label: 'Reglas del torneo',
              value: rulesPreview.length > 200
                  ? '${rulesPreview.substring(0, 200)}…'
                  : rulesPreview.isEmpty
                  ? '—'
                  : rulesPreview,
              multiline: true,
            ),
          ],
        ),

        // ── Staff y Soporte ───────────────────────────────────────
        InfoSection(
          icon: Icons.support_agent_rounded,
          title: 'Staff y Soporte',
          accentColor: const Color(0xFF00D4FF),
          children: [
            InfoField(label: 'Email de contacto', value: contactEmail),
            if (contactPhone != null && contactPhone!.isNotEmpty)
              InfoField(label: 'Teléfono', value: contactPhone!),
            if (contactLinks.isNotEmpty)
              InfoField(
                label: 'Enlaces',
                value: contactLinks.join('\n'),
                multiline: true,
              ),
            InfoField(
              label: 'Administradores',
              value: admins.isEmpty ? 'Solo tú' : admins.join(', '),
            ),
          ],
        ),

        // ── Aviso final ───────────────────────────────────────────
        const _ConfirmNote(),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  WIDGET: Hero de confirmación
// ════════════════════════════════════════════════════════════════

class _ReviewHero extends StatelessWidget {
  const _ReviewHero();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6C63FF).withValues(alpha: 0.18),
                const Color(0xFF00D4FF).withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              // Icono trofeo con glow
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
                      ).createShader(b),
                      child: const Text(
                        '¡Casi listo! 🎉',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Revisa que todo esté correcto antes de crear el torneo.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
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

// ════════════════════════════════════════════════════════════════
//  WIDGET: Portada
// ════════════════════════════════════════════════════════════════

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Image.memory(
            bytes,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          // Gradiente inferior para legibilidad
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14, bottom: 12,
            child: Row(
              children: [
                Icon(Icons.image_rounded,
                    color: Colors.white.withValues(alpha: 0.8), size: 14),
                const SizedBox(width: 6),
                Text(
                  'Portada del torneo',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  WIDGET REUTILIZABLE: InfoSection
//  Cada bloque temático: cabecera con icono + color + campos.
// ════════════════════════════════════════════════════════════════

class InfoSection extends StatelessWidget {
  const InfoSection({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.accentColor = const Color(0xFF6C63FF),
  });

  final IconData icon;
  final String title;
  final Color accentColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cabecera de sección ──
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    color: accentColor.withValues(alpha: 0.08),
                    border: Border(
                      bottom: BorderSide(
                        color: accentColor.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          color: accentColor.withValues(alpha: 0.15),
                        ),
                        child: Icon(icon, color: accentColor, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Campos ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _intersperse(children),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Inserta divisores entre los hijos (evita divisor al final).
  List<Widget> _intersperse(List<Widget> items) {
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(
          Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        );
      }
    }
    return result;
  }
}

// ════════════════════════════════════════════════════════════════
//  WIDGET REUTILIZABLE: InfoField
//  Label arriba · Valor abajo · Ancho completo
// ════════════════════════════════════════════════════════════════

class InfoField extends StatelessWidget {
  const InfoField({
    super.key,
    required this.label,
    required this.value,
    this.multiline = false,
    this.valueColor,
    this.leadingIcon,
    this.leadingIconColor,
  });

  final String label;
  final String value;

  /// Si true, el valor no se trunca en una línea.
  final bool multiline;

  /// Color del texto del valor (por defecto blanco).
  final Color? valueColor;

  /// Icono opcional a la izquierda del valor.
  final IconData? leadingIcon;
  final Color? leadingIconColor;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.isEmpty ? '—' : value;
    final effectiveValueColor = valueColor ?? Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),

          // Valor
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (leadingIcon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 1, right: 6),
                  child: Icon(
                    leadingIcon,
                    size: 16,
                    color: leadingIconColor ??
                        Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
              Expanded(
                child: Text(
                  displayValue,
                  maxLines: multiline ? null : 3,
                  overflow:
                  multiline ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: TextStyle(
                    color: effectiveValueColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  WIDGET: Par responsive (dos campos en fila si hay espacio)
// ════════════════════════════════════════════════════════════════

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // En pantallas >= 420px los dos campos van en fila
        if (constraints.maxWidth >= 420) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              const SizedBox(width: 8),
              Expanded(child: second),
            ],
          );
        }
        // En móvil pequeño van apilados con divisor
        return Column(
          children: [
            first,
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            second,
          ],
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  WIDGET: Nota de confirmación al pie
// ════════════════════════════════════════════════════════════════

class _ConfirmNote extends StatelessWidget {
  const _ConfirmNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF6C63FF).withValues(alpha: 0.06),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFB0A8FF),
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Una vez creado el torneo podrás editar algunos datos desde el panel de administración.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}