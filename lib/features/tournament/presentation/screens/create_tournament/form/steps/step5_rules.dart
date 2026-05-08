import 'package:flutter/material.dart';

import '../widgets/form_fields.dart';
import '../widgets/step_card.dart';

/// Paso 5 - Reglamento: Editor de texto enriquecido para reglas, datos
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
    return Column(
        children: [
          StepCard(
            icon: Icons.gavel_rounded,
            title: 'Reglamento',
            subtitle:
            'Especifica las reglas del torneo, formato de competición, criterios de desempate y toda información técnica relevante.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const _FormatHint(
                        icon: Icons.format_bold_rounded,
                        label: 'Títulos',
                      ),
                      const _FormatHint(
                        icon: Icons.format_list_bulleted_rounded,
                        label: 'Guiones',
                      ),
                      Text(
                        'Usa la tecla Intro para separar párrafos',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
          const SizedBox(height: 18),

          // Área de redacción profesional (Sin icono)
          GlassField(
            controller: rulesController,
            label: 'Reglas y detalles técnicos',
            // Hint más limpio y directo para no saturar la vista
            hint: 'Redacta aquí el reglamento...\n\n'
                'Te sugerimos incluir:\n'
                '- Formato (Eliminatoria, liguilla...)\n'
                '- Duración de los encuentros\n'
                '- Criterios de desempate\n'
                '- Normas de conducta',
            errorText: rulesError,
            // Ya no pasamos el parámetro 'icon'

            // Mejoras de UX para redacción larga:
            minLines: 12, // Más altura inicial para que parezca un folio
            maxLines: 30, // Permitimos que el área crezca bastante
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline, // Obliga al teclado a mostrar la tecla "Enter/Intro"
            capitalization: TextCapitalization.sentences,
            onChanged: onRulesChanged,
          ),
        ]
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