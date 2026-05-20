import 'package:flutter/material.dart';

class DeleteAccountWarningCard extends StatelessWidget {
  const DeleteAccountWarningCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D6A).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF4D6A).withValues(alpha: 0.35),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFF8A8A)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Esta accion eliminara tu acceso a la plataforma. Algunos datos minimos podran conservarse de forma anonimizada por motivos legales, soporte o trazabilidad.',
              style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
