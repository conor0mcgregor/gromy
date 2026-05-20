import 'package:flutter/material.dart';

import '../../../../core/models/registration_form.dart';

class DynamicRegistrationField extends StatefulWidget {
  const DynamicRegistrationField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.dark = true,
    this.enabled = true,
  });

  final RegistrationField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final String? errorText;
  final bool dark;
  final bool enabled;

  @override
  State<DynamicRegistrationField> createState() =>
      _DynamicRegistrationFieldState();
}

class _DynamicRegistrationFieldState extends State<DynamicRegistrationField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant DynamicRegistrationField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.value?.toString() ?? '';
    if (_controller.text != next &&
        widget.field.type != RegistrationFieldType.checkbox &&
        widget.field.type != RegistrationFieldType.select &&
        widget.field.type != RegistrationFieldType.multiSelect) {
      _controller.text = next;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                field.required ? '${field.label} *' : field.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (field.description?.isNotEmpty == true) ...[
          const SizedBox(height: 4),
          Text(
            field.description!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Opacity(
          opacity: widget.enabled ? 1 : 0.55,
          child: IgnorePointer(
            ignoring: !widget.enabled,
            child: _buildInput(context),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: const TextStyle(
              color: Color(0xFFFF4D6A),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInput(BuildContext context) {
    return switch (widget.field.type) {
      RegistrationFieldType.text => _TextInput(
        controller: _controller,
        hint: 'Escribe tu respuesta',
        error: widget.errorText != null,
        onChanged: widget.onChanged,
      ),
      RegistrationFieldType.textarea => _TextInput(
        controller: _controller,
        hint: 'Escribe los detalles',
        error: widget.errorText != null,
        maxLines: 4,
        textInputAction: TextInputAction.newline,
        onChanged: widget.onChanged,
      ),
      RegistrationFieldType.number => _TextInput(
        controller: _controller,
        hint: 'Introduce un numero',
        error: widget.errorText != null,
        keyboardType: TextInputType.number,
        onChanged: widget.onChanged,
      ),
      RegistrationFieldType.date => _DateInput(
        value: widget.value?.toString(),
        error: widget.errorText != null,
        onChanged: widget.onChanged,
      ),
      RegistrationFieldType.checkbox => _CheckboxInput(
        label: widget.field.label,
        value: widget.value == true,
        error: widget.errorText != null,
        onChanged: widget.onChanged,
      ),
      RegistrationFieldType.select => _SelectInput(
        options: widget.field.options,
        value: widget.value?.toString(),
        error: widget.errorText != null,
        onChanged: widget.onChanged,
      ),
      RegistrationFieldType.multiSelect => _MultiSelectInput(
        options: widget.field.options,
        values: widget.value is List
            ? (widget.value as List).map((item) => item.toString()).toList()
            : const [],
        error: widget.errorText != null,
        onChanged: widget.onChanged,
      ),
    };
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.hint,
    required this.error,
    required this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final String hint;
  final bool error;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      error: error,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.32),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
        ),
      ),
    );
  }
}

class _DateInput extends StatelessWidget {
  const _DateInput({
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final String? value;
  final bool error;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    final parsed = value == null ? null : DateTime.tryParse(value!);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: parsed ?? DateTime(now.year, now.month, now.day),
          firstDate: DateTime(now.year - 100),
          lastDate: DateTime(now.year + 10),
        );
        if (picked != null) {
          onChanged(picked.toIso8601String());
        }
      },
      child: _FieldShell(
        error: error,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: Colors.white.withValues(alpha: 0.45),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  parsed == null
                      ? 'Selecciona una fecha'
                      : '${parsed.day}/${parsed.month}/${parsed.year}',
                  style: TextStyle(
                    color: parsed == null
                        ? Colors.white.withValues(alpha: 0.32)
                        : Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckboxInput extends StatelessWidget {
  const _CheckboxInput({
    required this.label,
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool error;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      error: error,
      child: CheckboxListTile(
        value: value,
        onChanged: (checked) => onChanged(checked == true),
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color(0xFF6C63FF),
        contentPadding: const EdgeInsets.only(left: 4, right: 10),
        title: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}

class _SelectInput extends StatelessWidget {
  const _SelectInput({
    required this.options,
    required this.value,
    required this.error,
    required this.onChanged,
  });

  final List<String> options;
  final String? value;
  final bool error;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      error: error,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : null,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E293B),
          hint: Text(
            'Selecciona una opcion',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.32)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          iconEnabledColor: Colors.white54,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: options
              .map(
                (option) =>
                    DropdownMenuItem(value: option, child: Text(option)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _MultiSelectInput extends StatelessWidget {
  const _MultiSelectInput({
    required this.options,
    required this.values,
    required this.error,
    required this.onChanged,
  });

  final List<String> options;
  final List<String> values;
  final bool error;
  final ValueChanged<dynamic> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldShell(
      error: error,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final selected = values.contains(option);
            return FilterChip(
              label: Text(option),
              selected: selected,
              onSelected: (checked) {
                final next = [...values];
                checked ? next.add(option) : next.remove(option);
                onChanged(next);
              },
              selectedColor: const Color(0xFF6C63FF).withValues(alpha: 0.35),
              checkmarkColor: Colors.white,
              labelStyle: const TextStyle(color: Colors.white),
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.child, required this.error});

  final Widget child;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: error
            ? const Color(0xFFFF4D6A).withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: error
              ? const Color(0xFFFF4D6A).withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.1),
          width: error ? 1.4 : 1,
        ),
      ),
      child: child,
    );
  }
}
