import 'package:flutter/material.dart';
import '../widgets/step_card.dart';
import '../widgets/form_fields.dart';

/// Paso 5 — Reglamento: Editor de texto enriquecido para reglas, datos
/// adicionales y detalles técnicos del torneo.
class Step5Rules extends StatelessWidget {
  const Step5Rules({
    super.key,
    required this.rulesController,
    required this.rulesError,
    required this.onRulesChanged,
  });

  final TextEditingController rulesController;
  final String? rulesError;
  final ValueChanged<String>? onRulesChanged;

  @override
  Widget build(BuildContext context) {
    return StepCard(
      icon: Icons.gavel_rounded,
      title: 'Reglamento',
      subtitle:
          'Especifica las reglas del torneo, formato de competición, criterios de desempate y toda información técnica relevante.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de formato decorativa (hint visual)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                _FormatHint(icon: Icons.format_bold_rounded, label: 'Negrita'),
                const SizedBox(width: 12),
                _FormatHint(
                    icon: Icons.format_list_bulleted_rounded,
                    label: 'Listas'),
                const SizedBox(width: 12),
                _FormatHint(
                    icon: Icons.format_list_numbered_rounded,
                    label: 'Secciones'),
                const Spacer(),
                Text(
                  'Usa saltos de línea para organizar',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          GlassField(
            controller: rulesController,
            hint:
                '📋 Ejemplo de estructura:\n\n'
                '1. FORMATO\n'
                '   - Eliminación directa / Liguilla\n'
                '   - Partidos a X sets/puntos\n\n'
                '2. REGLAS GENERALES\n'
                '   - Tiempo de partido\n'
                '   - Faltas y sanciones\n\n'
                '3. DESEMPATE\n'
                '   - Criterio 1, Criterio 2...\n\n'
                '(Mínimo 100 caracteres)',
            icon: Icons.description_rounded,
            label: 'Reglas y detalles técnicos',
            errorText: rulesError,
            minLines: 10,
            maxLines: 25,
            capitalization: TextCapitalization.sentences,
            onChanged: onRulesChanged,
          ),
        ],
      ),
    );
  }
}

class _FormatHint extends StatelessWidget {
  const _FormatHint({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 15),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
