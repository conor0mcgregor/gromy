import 'package:flutter/material.dart';

class AdminChip extends StatelessWidget{
  const AdminChip({super.key, required this.small});
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.admin_panel_settings_rounded,
            size: 12,
            color: Color(0xFFB0A8FF),
          ),
          if (!small) ...[
            const SizedBox(width: 4),
            const Text(
              'Admin',
              style: TextStyle(
                color: Color(0xFFB0A8FF),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ]
        ],
      ),
    );
  }

}