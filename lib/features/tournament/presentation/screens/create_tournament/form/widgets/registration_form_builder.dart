import 'package:flutter/material.dart';

import '../../../../../../../core/models/registration_form.dart';
import 'form_helpers.dart';
import 'step_card.dart';

class RegistrationFormBuilder extends StatelessWidget {
  const RegistrationFormBuilder({
    super.key,
    required this.schema,
    required this.onUpsertField,
    required this.onRemoveField,
    required this.onToggleField,
    required this.onMoveField,
    this.errorText,
  });

  final RegistrationFormSchema schema;
  final ValueChanged<RegistrationField> onUpsertField;
  final ValueChanged<String> onRemoveField;
  final void Function(String id, bool enabled) onToggleField;
  final void Function(String id, int delta) onMoveField;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final fields = [...schema.fields]
      ..sort((a, b) => a.order.compareTo(b.order));
    return StepCard(
      icon: Icons.dynamic_form_rounded,
      title: 'Campos adicionales de inscripcion',
      subtitle:
          'Configura datos extra que los participantes rellenaran al apuntarse.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (errorText != null) ...[
            _ErrorBanner(message: errorText!),
            const SizedBox(height: 14),
          ],
          SizedBox(
            height: 48,
            child: OutlineButton(
              label: 'Anadir campo',
              icon: Icons.add_rounded,
              onPressed: () => _openFieldEditor(context),
            ),
          ),
          const SizedBox(height: 18),
          const GlassDivider(),
          const SizedBox(height: 18),
          if (fields.isEmpty)
            const _EmptyState()
          else
            Column(
              children: [
                for (var i = 0; i < fields.length; i++) ...[
                  _FieldCard(
                    field: fields[i],
                    isFirst: i == 0,
                    isLast: i == fields.length - 1,
                    onEdit: () => _openFieldEditor(context, fields[i]),
                    onRemove: () => onRemoveField(fields[i].id),
                    onToggle: (enabled) => onToggleField(fields[i].id, enabled),
                    onMoveUp: () => onMoveField(fields[i].id, -1),
                    onMoveDown: () => onMoveField(fields[i].id, 1),
                  ),
                  if (i < fields.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _openFieldEditor(
    BuildContext context, [
    RegistrationField? field,
  ]) async {
    final result = await showModalBottomSheet<RegistrationField>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RegistrationFieldEditor(field: field),
    );
    if (result != null) onUpsertField(result);
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.field,
    required this.isFirst,
    required this.isLast,
    required this.onEdit,
    required this.onRemove,
    required this.onToggle,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final RegistrationField field;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final ValueChanged<bool> onToggle;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: field.enabled ? 0.05 : 0.025),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.14),
                ),
                child: const Icon(
                  Icons.short_text_rounded,
                  color: Color(0xFFB0A8FF),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.label,
                      style: TextStyle(
                        color: field.enabled
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${field.type.label}${field.required ? ' - Obligatorio' : ' - Opcional'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: field.enabled,
                activeThumbColor: const Color(0xFF6C63FF),
                onChanged: onToggle,
              ),
            ],
          ),
          if (field.description?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              field.description!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12.5,
              ),
            ),
          ],
          if (field.options.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: field.options
                  .map(
                    (option) => Chip(
                      label: Text(option),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(
                        0xFF00D4FF,
                      ).withValues(alpha: 0.1),
                      labelStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                      ),
                      side: BorderSide(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.25),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                tooltip: 'Subir',
                onPressed: isFirst ? null : onMoveUp,
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
                color: Colors.white70,
              ),
              IconButton(
                tooltip: 'Bajar',
                onPressed: isLast ? null : onMoveDown,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                color: Colors.white70,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Editar'),
              ),
              IconButton(
                tooltip: 'Eliminar',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                color: const Color(0xFFFF4D6A),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegistrationFieldEditor extends StatefulWidget {
  const _RegistrationFieldEditor({this.field});

  final RegistrationField? field;

  @override
  State<_RegistrationFieldEditor> createState() =>
      _RegistrationFieldEditorState();
}

class _RegistrationFieldEditorState extends State<_RegistrationFieldEditor> {
  late final TextEditingController _labelController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _optionsController;
  late RegistrationFieldType _type;
  late bool _required;
  String? _error;

  @override
  void initState() {
    super.initState();
    final field = widget.field;
    _labelController = TextEditingController(text: field?.label ?? '');
    _descriptionController = TextEditingController(
      text: field?.description ?? '',
    );
    _optionsController = TextEditingController(
      text: field?.options.join('\n') ?? '',
    );
    _type = field?.type ?? RegistrationFieldType.text;
    _required = field?.required ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _descriptionController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.viewInsetsOf(context),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  widget.field == null ? 'Nuevo campo' : 'Editar campo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _SheetTextField(
                  controller: _labelController,
                  label: 'Titulo',
                  hint: 'Ej. Talla de camiseta',
                ),
                const SizedBox(height: 12),
                _SheetTextField(
                  controller: _descriptionController,
                  label: 'Descripcion opcional',
                  hint: 'Ayuda breve para el participante',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                _TypeSelector(
                  value: _type,
                  onChanged: (type) => setState(() => _type = type),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Campo obligatorio',
                    style: TextStyle(color: Colors.white),
                  ),
                  activeThumbColor: const Color(0xFF6C63FF),
                  value: _required,
                  onChanged: (value) => setState(() => _required = value),
                ),
                if (_type.usesOptions) ...[
                  const SizedBox(height: 8),
                  _SheetTextField(
                    controller: _optionsController,
                    label: 'Opciones',
                    hint: 'Una opcion por linea',
                    maxLines: 5,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  _ErrorBanner(message: _error!),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Guardar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    final now = DateTime.now();
    final field = RegistrationField(
      id:
          widget.field?.id ??
          'field_${now.microsecondsSinceEpoch.toRadixString(36)}',
      label: _labelController.text,
      description: _descriptionController.text,
      type: _type,
      required: _required,
      options: _type.usesOptions
          ? _optionsController.text
                .split('\n')
                .map((option) => option.trim())
                .where((option) => option.isNotEmpty)
                .toList()
          : const [],
      order: widget.field?.order ?? 0,
      enabled: widget.field?.enabled ?? true,
      createdAt: widget.field?.createdAt ?? now,
      updatedAt: now,
    );

    final errors = RegistrationFormValidator.validateSchema(
      RegistrationFormSchema(fields: [field]),
    );
    if (errors.isNotEmpty) {
      setState(() => _error = errors.first);
      return;
    }

    Navigator.pop(context, field);
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.value, required this.onChanged});

  final RegistrationFieldType value;
  final ValueChanged<RegistrationFieldType> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<RegistrationFieldType>(
      initialValue: value,
      dropdownColor: const Color(0xFF1E293B),
      decoration: _sheetDecoration('Tipo de campo'),
      style: const TextStyle(color: Colors.white),
      items: RegistrationFieldType.values
          .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
          .toList(),
      onChanged: (type) {
        if (type != null) onChanged(type);
      },
    );
  }
}

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: _sheetDecoration(label).copyWith(hintText: hint),
    );
  }
}

InputDecoration _sheetDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.32)),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.4),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.playlist_add_rounded,
            color: Colors.white.withValues(alpha: 0.18),
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(
            'No hay campos adicionales configurados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFFF4D6A).withValues(alpha: 0.08),
        border: Border.all(
          color: const Color(0xFFFF4D6A).withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFFF8AA0),
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
