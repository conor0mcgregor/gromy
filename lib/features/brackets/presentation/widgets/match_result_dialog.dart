import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/app_match.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MatchResultDialog  ·  Widget
//
//  Dialog glassmórfico para que un admin registre el resultado de un match.
//  Muestra los dos participantes, campos de score y selección de ganador.
// ─────────────────────────────────────────────────────────────────────────────

class MatchResultDialog extends StatefulWidget {
  const MatchResultDialog({super.key, required this.match});

  final AppMatch match;

  /// Muestra el dialog y devuelve el resultado, o null si se cancela.
  static Future<MatchResultData?> show(BuildContext context, AppMatch match) {
    return showDialog<MatchResultData>(
      context: context,
      barrierDismissible: true,
      builder: (_) => MatchResultDialog(match: match),
    );
  }

  @override
  State<MatchResultDialog> createState() => _MatchResultDialogState();
}

class _MatchResultDialogState extends State<MatchResultDialog> {
  final _score1Controller = TextEditingController(text: '0');
  final _score2Controller = TextEditingController(text: '0');
  String? _selectedWinnerId;

  @override
  void initState() {
    super.initState();
    // Pre-fill existing scores
    if (widget.match.scoreParticipant1 != null) {
      _score1Controller.text = '${widget.match.scoreParticipant1}';
    }
    if (widget.match.scoreParticipant2 != null) {
      _score2Controller.text = '${widget.match.scoreParticipant2}';
    }
    _selectedWinnerId = widget.match.winnerId;
  }

  @override
  void dispose() {
    _score1Controller.dispose();
    _score2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFF0F172A).withValues(alpha: 0.95),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                const Text(
                  'Registrar resultado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 24),

                // Participante 1
                _buildParticipantSection(
                  name: widget.match.participant1Name ?? 'Participante 1',
                  participantId: widget.match.participant1Id!,
                  memberNames: widget.match.participant1MemberNames,
                  scoreController: _score1Controller,
                  isSelected: _selectedWinnerId == widget.match.participant1Id,
                  onSelect: () => setState(
                    () => _selectedWinnerId = widget.match.participant1Id,
                  ),
                ),

                const SizedBox(height: 12),

                // VS
                Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 12),

                // Participante 2
                _buildParticipantSection(
                  name: widget.match.participant2Name ?? 'Participante 2',
                  participantId: widget.match.participant2Id!,
                  memberNames: widget.match.participant2MemberNames,
                  scoreController: _score2Controller,
                  isSelected: _selectedWinnerId == widget.match.participant2Id,
                  onSelect: () => setState(
                    () => _selectedWinnerId = widget.match.participant2Id,
                  ),
                ),

                const SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedWinnerId != null
                            ? _submitResult
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          disabledBackgroundColor: Colors.white.withValues(
                            alpha: 0.05,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Confirmar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
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

  Widget _buildParticipantSection({
    required String name,
    required String participantId,
    required List<String> memberNames,
    required TextEditingController scoreController,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    final accent = const Color(0xFF22C55E);

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? accent.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio selector
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? accent
                    : Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: isSelected
                      ? accent
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),

            // Nombre
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  if (memberNames.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      memberNames.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Score input
            SizedBox(
              width: 56,
              height: 38,
              child: TextField(
                controller: scoreController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: accent.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitResult() {
    if (_selectedWinnerId == null) return;

    final score1 = int.tryParse(_score1Controller.text) ?? 0;
    final score2 = int.tryParse(_score2Controller.text) ?? 0;

    final loserId = _selectedWinnerId == widget.match.participant1Id
        ? widget.match.participant2Id!
        : widget.match.participant1Id!;

    Navigator.pop(
      context,
      MatchResultData(
        winnerId: _selectedWinnerId!,
        loserId: loserId,
        scoreParticipant1: score1,
        scoreParticipant2: score2,
      ),
    );
  }
}

/// Datos del resultado de un match.
class MatchResultData {
  const MatchResultData({
    required this.winnerId,
    required this.loserId,
    required this.scoreParticipant1,
    required this.scoreParticipant2,
  });

  final String winnerId;
  final String loserId;
  final int scoreParticipant1;
  final int scoreParticipant2;
}
