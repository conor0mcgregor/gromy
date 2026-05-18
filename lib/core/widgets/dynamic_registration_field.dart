import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/inscription/domain/models/registration_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DynamicRegistrationField  ·  Widget reutilizable
//
//  Renderiza un campo dinámico según su [RegistrationFieldType].
//  No contiene lógica de negocio — solo presentación.
// ─────────────────────────────────────────────────────────────────────────────

class DynamicRegistrationField extends StatelessWidget {
  const DynamicRegistrationField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  final RegistrationField field;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              Flexible(
                child: Text(
                  field.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (field.required)
                Text(
                  ' *',
                  style: TextStyle(
                    color: const Color(0xFFFF4D6A).withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          // Description
          if (field.description != null && field.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              field.description!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Field widget
          _buildFieldWidget(context),
          // Error
          if (errorText != null) ...[
            const SizedBox(height: 4),
            Text(
              errorText!,
              style: const TextStyle(
                color: Color(0xFFFF4D6A),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldWidget(BuildContext context) {
    return switch (field.type) {
      RegistrationFieldType.text => _buildTextField(),
      RegistrationFieldType.textarea => _buildTextField(maxLines: 4),
      RegistrationFieldType.number => _buildTextField(
          keyboardType: TextInputType.number,
        ),
      RegistrationFieldType.date => _buildDateField(context),
      RegistrationFieldType.checkbox => _buildCheckbox(),
      RegistrationFieldType.select => _buildSelect(),
      RegistrationFieldType.multiSelect => _buildMultiSelect(),
    };
  }

  Widget _buildTextField({
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: TextFormField(
          initialValue: value as String? ?? '',
          maxLines: maxLines,
          keyboardType: keyboardType,
          enabled: enabled,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          onChanged: (v) => onChanged(v),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF6C63FF),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    final dateStr = value as String? ?? '';
    final displayText =
        dateStr.isNotEmpty ? dateStr : 'Seleccionar fecha';

    return GestureDetector(
      onTap: enabled
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFF6C63FF),
                        surface: Color(0xFF1A1A2E),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                onChanged(DateFormat('dd/MM/yyyy').format(picked));
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: Colors.white.withValues(alpha: 0.4),
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              displayText,
              style: TextStyle(
                color: dateStr.isEmpty
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    final isChecked = value as bool? ?? false;
    return GestureDetector(
      onTap: enabled ? () => onChanged(!isChecked) : null,
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isChecked
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              color: isChecked
                  ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                  : Colors.transparent,
            ),
            child: isChecked
                ? const Icon(Icons.check_rounded,
                    color: Color(0xFF6C63FF), size: 16)
                : null,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              field.label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelect() {
    final selectedValue = value as String?;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: field.options.contains(selectedValue) ? selectedValue : null,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1A2E),
          hint: Text(
            'Seleccionar...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
          items: field.options
              .map((opt) => DropdownMenuItem(
                    value: opt,
                    child: Text(
                      opt,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: enabled ? (v) => onChanged(v) : null,
        ),
      ),
    );
  }

  Widget _buildMultiSelect() {
    final selected = (value is List)
        ? (value as List).map((e) => e.toString()).toList()
        : <String>[];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: field.options.map((opt) {
        final isSelected = selected.contains(opt);
        return GestureDetector(
          onTap: enabled
              ? () {
                  final updated = List<String>.from(selected);
                  isSelected ? updated.remove(opt) : updated.add(opt);
                  onChanged(updated);
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isSelected
                  ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              opt,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
