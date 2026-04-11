import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'form_helpers.dart';

class GlassField extends StatelessWidget {
  const GlassField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.label,
    this.errorText,
    this.maxLines = 1,
    this.minLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.capitalization = TextCapitalization.none,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String label;
  final String? errorText;
  final int maxLines;
  final int minLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: errorText != null
                ? const Color(0xFFFF4D6A).withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: errorText != null
                  ? const Color(0xFFFF4D6A).withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.1),
              width: errorText != null ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            minLines: minLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: capitalization,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.32),
                fontSize: 14,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(icon, color: Colors.white38, size: 20),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 44, minHeight: 44),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          ErrorText(message: errorText!),
        ],
      ],
    );
  }
}

class PickerTile extends StatelessWidget {
  const PickerTile({
    super.key,
    required this.icon,
    required this.value,
    required this.isEmpty,
    required this.onTap,
    this.errorText,
  });

  final IconData icon;
  final String value;
  final bool isEmpty;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: errorText != null
                  ? const Color(0xFFFF4D6A).withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.07),
              border: Border.all(
                color: errorText != null
                    ? const Color(0xFFFF4D6A).withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.1),
                width: errorText != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white38, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: isEmpty
                          ? Colors.white.withValues(alpha: 0.32)
                          : Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white38),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          ErrorText(message: errorText!),
        ],
      ],
    );
  }
}
