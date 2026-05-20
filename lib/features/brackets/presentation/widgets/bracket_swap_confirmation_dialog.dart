import 'package:flutter/material.dart';

import '../../data/models/app_match.dart';

/// Muestra un diálogo de confirmación antes de intercambiar participantes.
/// Devuelve `true` si el usuario confirma, `false` si cancela.
Future<bool> showBracketSwapConfirmationDialog({
  required BuildContext context,
  required AppMatch sourceMatch,
  required int sourceSlot,
  required AppMatch targetMatch,
  required int targetSlot,
  required String Function(int roundIndex) roundNameBuilder,
}) {
  final sourceName = _participantLabel(sourceMatch, sourceSlot);
  final targetName = _participantLabel(targetMatch, targetSlot);
  final roundLabel = roundNameBuilder(sourceMatch.round);
  final sourcePos = _slotLabel(sourceMatch, sourceSlot);
  final targetPos = _slotLabel(targetMatch, targetSlot);
  final hasSchedule =
      sourceMatch.scheduledAt != null || targetMatch.scheduledAt != null;

  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      color: Color(0xFF6C63FF),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Confirmar intercambio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '¿Estás seguro de que deseas intercambiar a '
                '$sourceName por $targetName en este bracket?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              _InfoRow(
                icon: Icons.layers_rounded,
                label: 'Ronda',
                value: roundLabel,
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.grid_view_rounded,
                label: 'Posiciones',
                value: '$sourcePos ↔ $targetPos',
              ),
              if (hasSchedule) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Uno o ambos enfrentamientos tienen horario asignado. '
                          'Revisa que el cambio siga siendo correcto.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'Esta acción modificará el bracket actual y no se puede deshacer '
                'automáticamente.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.65),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF44C831),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirmar intercambio',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  ).then((value) => value ?? false);
}

String _participantLabel(AppMatch match, int slot) {
  final name = slot == 1 ? match.participant1Name : match.participant2Name;
  final id = slot == 1 ? match.participant1Id : match.participant2Id;
  if (id == null || id.isEmpty) return 'Por definir';
  if (name != null && name.trim().isNotEmpty) return name.trim();
  return 'Participante';
}

String _slotLabel(AppMatch match, int slot) {
  final pos = slot == 1 ? 'arriba' : 'abajo';
  return 'Partido ${match.matchOrder + 1} ($pos)';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.35)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 12.5,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
