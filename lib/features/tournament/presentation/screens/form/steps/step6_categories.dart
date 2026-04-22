import 'package:flutter/material.dart';

import '../widgets/form_fields.dart';
import '../widgets/form_helpers.dart';
import '../widgets/step_card.dart';
import '../widgets/tournament_selectors.dart';

/// Paso 6 — Categorías: permite al usuario añadir etiquetas/categorías
/// opcionales al torneo (ej. 'Sub-18', 'Femenino', 'Amateur').
///
/// SRP: este widget es puramente presentacional. La lógica de negocio
/// (validación de duplicados, lista de estado) vive en [TournamentFormController].
class Step6Categories extends StatelessWidget {
  const Step6Categories({
    super.key,
    required this.categoryController,
    required this.categories,
    required this.onAddCategory,
    required this.onRemoveCategory,
  });

  final TextEditingController categoryController;
  final List<String> categories;
  final VoidCallback onAddCategory;
  final ValueChanged<String> onRemoveCategory;

  @override
  Widget build(BuildContext context) {
    return StepCard(
      icon: Icons.label_rounded,
      title: 'Categorías',
      subtitle:
          'Añade etiquetas opcionales para organizar el torneo (ej. Sub-18, Femenino, Amateur).',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info badge (opcional) ─────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF6C63FF).withValues(alpha: 0.06),
              border: Border.all(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFB0A8FF),
                  size: 15,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Este campo es opcional. Puedes crear el torneo sin añadir categorías.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Input + Botón Añadir ───────────────────────────────
          GlassField(
            controller: categoryController,
            hint: 'Ej. Sub-18, Femenino, Amateur...',
            icon: Icons.label_outline_rounded,
            label: 'Nombre de la categoría',
            capitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onChanged: (_) {},
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlineButton(
              label: 'Añadir',
              icon: Icons.add_rounded,
              onPressed: onAddCategory,
            ),
          ),

          // ── Lista de categorías ───────────────────────────────
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 20),
            const GlassDivider(),
            const SizedBox(height: 16),
            const FieldLabel(label: 'Categorías añadidas'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories
                  .map(
                    (cat) => CategoryChip(
                      label: cat,
                      onRemove: () => onRemoveCategory(cat),
                    ),
                  )
                  .toList(),
            ),
          ],

          // ── Estado vacío amigable ─────────────────────────────
          if (categories.isEmpty) ...[
            const SizedBox(height: 20),
            const GlassDivider(),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.label_off_outlined,
                    color: Colors.white.withValues(alpha: 0.18),
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sin categorías todavía',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
