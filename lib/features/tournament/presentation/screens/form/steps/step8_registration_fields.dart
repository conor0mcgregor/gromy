import 'package:flutter/material.dart';

import '../../../../../../features/inscription/domain/models/registration_field.dart';
import '../widgets/form_helpers.dart';
import '../widgets/step_card.dart';

/// Paso 8 — Campos adicionales: permite al organizador definir campos
/// personalizados que los participantes deberán rellenar al inscribirse.
///
/// SRP: puramente presentacional. El estado vive en [TournamentFormController].
class Step8RegistrationFields extends StatelessWidget {
  const Step8RegistrationFields({
    super.key,
    required this.fields,
    required this.onAddField,
    required this.onRemoveField,
    required this.onUpdateField,
  });

  final List<RegistrationFieldDraft> fields;
  final VoidCallback onAddField;
  final ValueChanged<int> onRemoveField;
  final void Function(int index, RegistrationFieldDraft updated) onUpdateField;

  @override
  Widget build(BuildContext context) {
    return StepCard(
      icon: Icons.dynamic_form_rounded,
      title: 'Campos adicionales',
      subtitle:
          'Añade campos personalizados que los participantes deberán rellenar al inscribirse (opcional).',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info badge ──
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    'Este paso es opcional. Crea campos como "Talla de camiseta", "Teléfono de emergencia", etc.',
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

          // ── Lista de campos definidos ──
          if (fields.isNotEmpty) ...[
            ...List.generate(fields.length, (i) {
              final field = fields[i];
              return _FieldEditor(
                index: i,
                draft: field,
                onUpdate: (updated) => onUpdateField(i, updated),
                onRemove: () => onRemoveField(i),
              );
            }),
            const SizedBox(height: 12),
            const GlassDivider(),
            const SizedBox(height: 12),
          ],

          // ── Estado vacío ──
          if (fields.isEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.dynamic_form_outlined,
                    color: Colors.white.withValues(alpha: 0.18),
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sin campos adicionales',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const GlassDivider(),
            const SizedBox(height: 12),
          ],

          // ── Botón añadir ──
          SizedBox(
            height: 48,
            child: OutlineButton(
              label: 'Añadir campo',
              icon: Icons.add_rounded,
              onPressed: onAddField,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Modelo draft para el formulario de creación (no Firestore).
// ─────────────────────────────────────────────────────────────────────────────

class RegistrationFieldDraft {
  String label;
  RegistrationFieldType type;
  bool required;
  List<String> options; // Para select / multiSelect

  RegistrationFieldDraft({
    this.label = '',
    this.type = RegistrationFieldType.text,
    this.required = false,
    this.options = const [],
  });

  RegistrationFieldDraft copyWith({
    String? label,
    RegistrationFieldType? type,
    bool? required,
    List<String>? options,
  }) {
    return RegistrationFieldDraft(
      label: label ?? this.label,
      type: type ?? this.type,
      required: required ?? this.required,
      options: options ?? this.options,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Editor de un campo individual
// ─────────────────────────────────────────────────────────────────────────────

class _FieldEditor extends StatefulWidget {
  const _FieldEditor({
    required this.index,
    required this.draft,
    required this.onUpdate,
    required this.onRemove,
  });

  final int index;
  final RegistrationFieldDraft draft;
  final ValueChanged<RegistrationFieldDraft> onUpdate;
  final VoidCallback onRemove;

  @override
  State<_FieldEditor> createState() => _FieldEditorState();
}

class _FieldEditorState extends State<_FieldEditor> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _optionsCtrl;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.draft.label);
    _optionsCtrl = TextEditingController(text: widget.draft.options.join(', '));
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _optionsCtrl.dispose();
    super.dispose();
  }

  static const _fieldTypes = RegistrationFieldType.values;

  String _typeLabel(RegistrationFieldType t) => switch (t) {
        RegistrationFieldType.text => 'Texto',
        RegistrationFieldType.textarea => 'Texto largo',
        RegistrationFieldType.number => 'Número',
        RegistrationFieldType.date => 'Fecha',
        RegistrationFieldType.checkbox => 'Casilla',
        RegistrationFieldType.select => 'Selección',
        RegistrationFieldType.multiSelect => 'Multi-selección',
      };

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final needsOptions = draft.type.requiresOptions;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header with remove button ──
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                      color: Color(0xFF6C63FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  draft.label.isEmpty ? 'Nuevo campo' : draft.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: widget.onRemove,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFFFF4D6A).withValues(alpha: 0.1),
                  ),
                  child: const Icon(Icons.close_rounded, color: Color(0xFFFF4D6A), size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Label field ──
          _buildFieldLabel('Nombre del campo'),
          const SizedBox(height: 8),
          _buildGlassInput(
            controller: _labelCtrl,
            hint: 'Ej. Talla de camiseta',
            icon: Icons.text_fields_rounded,
            onChanged: (v) => widget.onUpdate(draft.copyWith(label: v)),
          ),
          const SizedBox(height: 12),

          // ── Type selector ──
          _buildFieldLabel('Tipo de campo'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _fieldTypes.map((t) {
              final isSelected = draft.type == t;
              return GestureDetector(
                onTap: () => widget.onUpdate(draft.copyWith(type: t)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isSelected
                        ? const Color(0xFF6C63FF).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF6C63FF).withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    _typeLabel(t),
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF6C63FF) : Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // ── Options for select/multiSelect ──
          if (needsOptions) ...[
            _buildFieldLabel('Opciones (separadas por coma)'),
            const SizedBox(height: 8),
            _buildGlassInput(
              controller: _optionsCtrl,
              hint: 'Ej. S, M, L, XL',
              icon: Icons.list_rounded,
              onChanged: (v) {
                final opts = v
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                widget.onUpdate(draft.copyWith(options: opts));
              },
            ),
            const SizedBox(height: 12),
          ],

          // ── Required toggle ──
          GestureDetector(
            onTap: () => widget.onUpdate(draft.copyWith(required: !draft.required)),
            child: Row(
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: draft.required
                          ? const Color(0xFF6C63FF)
                          : Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    color: draft.required
                        ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                        : Colors.transparent,
                  ),
                  child: draft.required
                      ? const Icon(Icons.check_rounded, color: Color(0xFF6C63FF), size: 14)
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  'Campo obligatorio',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──

  Widget _buildFieldLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(icon, color: Colors.white38, size: 18),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
