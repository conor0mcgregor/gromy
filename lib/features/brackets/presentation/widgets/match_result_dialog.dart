import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../features/user/data/models/app_user.dart';
import '../../data/models/app_match.dart';
import '../../data/models/bracket_enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MatchResultDialog  ·  Widget
// ─────────────────────────────────────────────────────────────────────────────

class MatchResultDialog extends StatefulWidget {
  const MatchResultDialog({super.key, required this.match});

  final AppMatch match;

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

  AppUser? _user1;
  AppUser? _user2;
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    if (widget.match.scoreParticipant1 != null) {
      _score1Controller.text = '${widget.match.scoreParticipant1}';
    }
    if (widget.match.scoreParticipant2 != null) {
      _score2Controller.text = '${widget.match.scoreParticipant2}';
    }
    _selectedWinnerId = widget.match.winnerId;

    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      if (widget.match.participant1Type == MatchParticipantType.user && widget.match.participant1Id != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(widget.match.participant1Id!).get();
        if (doc.exists) _user1 = AppUser.fromMap(doc.data()!);
      }
      if (widget.match.participant2Type == MatchParticipantType.user && widget.match.participant2Id != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(widget.match.participant2Id!).get();
        if (doc.exists) _user2 = AppUser.fromMap(doc.data()!);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingUsers = false);
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
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: const Color(0xFF0F172A).withValues(alpha: 0.90),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 20)),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF6C63FF), size: 22),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Registrar resultado', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          SizedBox(height: 2),
                          Text('Selecciona al ganador y anota el score', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                if (_isLoadingUsers)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  )
                else ...[
                  // Participant 1
                  _buildModernParticipantCard(
                    fallbackName: widget.match.participant1Name ?? 'Participante 1',
                    participantId: widget.match.participant1Id!,
                    photoUrl: widget.match.participant1PhotoUrl,
                    memberNames: widget.match.participant1MemberNames,
                    user: _user1,
                    scoreController: _score1Controller,
                    isSelected: _selectedWinnerId == widget.match.participant1Id,
                    onSelect: () => setState(() => _selectedWinnerId = widget.match.participant1Id),
                  ),

                  // VS Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.05))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                          child: Text('VS', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2)),
                        ),
                        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.05))),
                      ],
                    ),
                  ),

                  // Participant 2
                  _buildModernParticipantCard(
                    fallbackName: widget.match.participant2Name ?? 'Participante 2',
                    participantId: widget.match.participant2Id!,
                    photoUrl: widget.match.participant2PhotoUrl,
                    memberNames: widget.match.participant2MemberNames,
                    user: _user2,
                    scoreController: _score2Controller,
                    isSelected: _selectedWinnerId == widget.match.participant2Id,
                    onSelect: () => setState(() => _selectedWinnerId = widget.match.participant2Id),
                  ),
                ],

                const SizedBox(height: 32),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Cancelar', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedWinnerId != null ? _submitResult : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          disabledBackgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Confirmar', style: TextStyle(color: _selectedWinnerId != null ? Colors.white : Colors.white54, fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ));
  }

  Widget _buildModernParticipantCard({
    required String fallbackName,
    required String participantId,
    required String? photoUrl,
    required List<String> memberNames,
    required AppUser? user,
    required TextEditingController scoreController,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    final accent = const Color(0xFF22C55E);
    
    String displayName = user?.nickname ?? fallbackName;
    String? subName;
    if (user != null) {
      subName = '${user.name} ${user.lastName}'.trim();
    } else if (memberNames.isNotEmpty) {
      subName = memberNames.join(', ');
    }

    final avatarUrl = user?.photoUrl ?? photoUrl;

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? accent.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: isSelected ? accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: accent.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: -5)]
              : null,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl.trim(),
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: accent.withValues(alpha: 0.5))));
                        },
                        errorBuilder: (ctx, err, stack) => Icon(Icons.person_rounded, size: 24, color: Colors.white.withValues(alpha: 0.2)),
                      )
                    : Icon(Icons.person_rounded, size: 24, color: Colors.white.withValues(alpha: 0.2)),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9), fontSize: 17, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, letterSpacing: -0.3),
                  ),
                  if (subName != null && subName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subName,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w500, height: 1.2),
                    ),
                  ],
                ],
              ),
            ),

            // Score Input
            const SizedBox(width: 12),
            Container(
              width: 64,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isSelected ? accent.withValues(alpha: 0.15) : const Color(0xFF1E293B),
                border: Border.all(color: isSelected ? accent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
              ),
              child: Center(
                child: TextField(
                  controller: scoreController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                  style: TextStyle(color: isSelected ? accent : Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
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
    final loserId = _selectedWinnerId == widget.match.participant1Id ? widget.match.participant2Id! : widget.match.participant1Id!;
    Navigator.pop(context, MatchResultData(winnerId: _selectedWinnerId!, loserId: loserId, scoreParticipant1: score1, scoreParticipant2: score2));
  }
}

class MatchResultData {
  const MatchResultData({required this.winnerId, required this.loserId, required this.scoreParticipant1, required this.scoreParticipant2});
  final String winnerId;
  final String loserId;
  final int scoreParticipant1;
  final int scoreParticipant2;
}
