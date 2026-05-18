import 'package:flutter/material.dart';

import '../../data/models/app_match.dart';
import '../../data/models/bracket_enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DraggableMatchCard  ·  Widget
//
//  Versión drag & drop del MatchCard para modo admin con bracket en draft.
//  Cada slot (participante 1 y 2) es simultáneamente:
//    - Draggable: se puede arrastrar el participante hacia otro slot
//    - DragTarget: puede recibir un participante de otro slot
//
//  Comportamiento visual:
//    - Elevación + escala al arrastrar
//    - Highlight de color al ser target válido
//    - Animaciones suaves con AnimatedContainer
//    - Sin menús intermedios: el intercambio es inmediato al soltar
// ─────────────────────────────────────────────────────────────────────────────

/// Datos que se transportan durante el drag.
class ParticipantDragData {
  const ParticipantDragData({
    required this.match,
    required this.slot,
    required this.participantId,
    required this.participantName,
    required this.participantPhotoUrl,
    required this.participantType,
  });

  final AppMatch match;

  /// 1 = superior, 2 = inferior.
  final int slot;
  final String? participantId;
  final String? participantName;
  final String? participantPhotoUrl;
  final MatchParticipantType? participantType;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Colores de la paleta compartida
// ─────────────────────────────────────────────────────────────────────────────

const _kAccent = Color(0xFF6C63FF);
const _kGreen = Color(0xFF22C55E);
const _kOrange = Color(0xFFFFB347);

class DraggableMatchCard extends StatefulWidget {
  const DraggableMatchCard({
    super.key,
    required this.match,
    required this.onDropped,
    required this.onTap,
    required this.isDraftMode,
    this.width = 220,
    this.isDraggingAny = false,
    this.pendingSwapSourceSlot,
    this.onParticipantDoubleTap,
  });

  final AppMatch match;

  /// Callback cuando un participante es soltado encima de un slot.
  /// [source] es el participante arrastrado, [targetSlot] es 1 o 2.
  final void Function(ParticipantDragData source, int targetSlot) onDropped;

  /// Callback al tocar la card.
  final VoidCallback onTap;

  /// Habilita drag solo en modo draft.
  final bool isDraftMode;

  final double width;

  /// True cuando hay un drag activo en el bracket (para atenuar otros matches).
  final bool isDraggingAny;

  /// Si este match tiene un slot seleccionado como origen para intercambio, se indica aquí (1 o 2).
  final int? pendingSwapSourceSlot;

  /// Callback para el doble toque en un slot
  final void Function(int slot)? onParticipantDoubleTap;

  @override
  State<DraggableMatchCard> createState() => _DraggableMatchCardState();
}

class _DraggableMatchCardState extends State<DraggableMatchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swapController;
  late final Animation<double> _swapScale;

  @override
  void initState() {
    super.initState();
    _swapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _swapScale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _swapController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _swapController.dispose();
    super.dispose();
  }

  /// Anima brevemente la card tras un intercambio exitoso.
  void triggerSwapAnimation() {
    _swapController.forward().then((_) => _swapController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final canDrag = widget.isDraftMode && widget.match.round == 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: widget.isDraggingAny ? 0.85 : 1.0,
        child: ScaleTransition(
          scale: _swapScale,
          child: _buildCard(canDrag),
        ),
      ),
    );
  }

  Widget _buildCard(bool canDrag) {
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: _borderColor, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(canDrag),
          _buildSlot(
            slot: 1,
            name: widget.match.participant1Name,
            photoUrl: widget.match.participant1PhotoUrl,
            participantId: widget.match.participant1Id,
            participantType: widget.match.participant1Type,
            score: widget.match.scoreParticipant1,
            isWinner: widget.match.winnerId != null &&
                widget.match.winnerId == widget.match.participant1Id,
            canDrag: canDrag,
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: Colors.white.withValues(alpha: 0.08),
          ),
          _buildSlot(
            slot: 2,
            name: widget.match.participant2Name,
            photoUrl: widget.match.participant2PhotoUrl,
            participantId: widget.match.participant2Id,
            participantType: widget.match.participant2Type,
            score: widget.match.scoreParticipant2,
            isWinner: widget.match.winnerId != null &&
                widget.match.winnerId == widget.match.participant2Id,
            canDrag: canDrag,
          ),
          if (widget.match.scheduledAt != null) _buildFooter(),
        ],
      ),
    );
  }

  // ── Slot con Draggable + DragTarget ────────────────────────────────────────

  Widget _buildSlot({
    required int slot,
    required String? name,
    required String? photoUrl,
    required String? participantId,
    required MatchParticipantType? participantType,
    required int? score,
    required bool isWinner,
    required bool canDrag,
  }) {
    final dragData = ParticipantDragData(
      match: widget.match,
      slot: slot,
      participantId: participantId,
      participantName: name,
      participantPhotoUrl: photoUrl,
      participantType: participantType,
    );

    final isEmpty = participantId == null || participantId.isEmpty;
    final displayName =
        isEmpty ? (widget.match.isBye ? 'BYE' : 'Por definir') : (name ?? 'Participante');

    // Contenido del slot
    Widget slotContent = GestureDetector(
      onDoubleTap: widget.onParticipantDoubleTap != null ? () => widget.onParticipantDoubleTap!(slot) : null,
      child: _ParticipantSlotContent(
        displayName: displayName,
        photoUrl: photoUrl,
        isEmpty: isEmpty,
        isWinner: isWinner,
        participantType: participantType,
        score: score,
        isPendingSwapSource: widget.pendingSwapSourceSlot == slot,
      ),
    );

    // Solo primera ronda en draft tiene drag
    if (!canDrag) {
      return DragTarget<ParticipantDragData>(
        onWillAcceptWithDetails: (_) => false,
        builder: (context, candidateItems, rejectedItems) => slotContent,
      );
    }

    return DragTarget<ParticipantDragData>(
      onWillAcceptWithDetails: (details) {
        final source = details.data;
        // Rechazar si es el mismo slot exacto
        return !(source.match.id == widget.match.id && source.slot == slot);
      },
      onAcceptWithDetails: (details) {
        widget.onDropped(details.data, slot);
        triggerSwapAnimation();
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        final isRejected = rejectedData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isHovered
                ? _kAccent.withValues(alpha: 0.12)
                : isRejected
                    ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                    : Colors.transparent,
            borderRadius: slot == 1
                ? const BorderRadius.vertical(top: Radius.zero)
                : const BorderRadius.vertical(bottom: Radius.circular(13)),
          ),
          child: Stack(
            children: [
              // Highlight ring cuando es target válido
              if (isHovered)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: slot == 1
                          ? const BorderRadius.vertical(top: Radius.zero)
                          : const BorderRadius.vertical(
                              bottom: Radius.circular(13)),
                      border: Border.all(
                        color: _kAccent.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

              // Draggable wrapper
              Draggable<ParticipantDragData>(
                data: dragData,
                feedback: _DragFeedbackWidget(
                  name: displayName,
                  photoUrl: photoUrl,
                  isEmpty: isEmpty,
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: slotContent,
                ),
                onDragStarted: () {},
                onDragEnd: (_) {},
                child: slotContent,
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool canDrag) {
    final Color statusColor;
    final String statusText;

    switch (widget.match.status) {
      case MatchStatus.completed:
        statusColor = _kGreen;
        statusText = 'Completado';
      case MatchStatus.inProgress:
        statusColor = _kAccent;
        statusText = 'En curso';
      case MatchStatus.scheduled:
        statusColor = const Color(0xFF00D4FF);
        statusText = 'Programado';
      case MatchStatus.bye:
        statusColor = _kOrange;
        statusText = 'BYE';
      case MatchStatus.cancelled:
        statusColor = const Color(0xFFEF4444);
        statusText = 'Cancelado';
      default:
        statusColor = Colors.white.withValues(alpha: 0.3);
        statusText = 'Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (canDrag)
            Icon(
              Icons.drag_indicator_rounded,
              size: 14,
              color: _kAccent.withValues(alpha: 0.45),
            )
          else if (widget.isDraftMode == false && !widget.match.isCompleted)
            Icon(
              Icons.edit_rounded,
              size: 12,
              color: Colors.white.withValues(alpha: 0.3),
            ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    final dt = widget.match.scheduledAt!;
    final formatted =
        '${dt.day.toString().padLeft(2, '0')} / ${dt.month.toString().padLeft(2, '0')} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 11,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 4),
          Text(
            formatted,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color get _borderColor {
    if (widget.match.isCompleted) return _kGreen.withValues(alpha: 0.3);
    if (widget.match.isBye) return _kOrange.withValues(alpha: 0.3);
    if (widget.match.status == MatchStatus.inProgress) {
      return _kAccent.withValues(alpha: 0.5);
    }
    return Colors.white.withValues(alpha: 0.1);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _ParticipantSlotContent  ·  Widget puro (sin drag lógica)
//
//  Renderiza el contenido de un slot: avatar + nombre + score + trophy.
// ─────────────────────────────────────────────────────────────────────────────

class _ParticipantSlotContent extends StatelessWidget {
  const _ParticipantSlotContent({
    required this.displayName,
    required this.photoUrl,
    required this.isEmpty,
    required this.isWinner,
    required this.participantType,
    required this.score,
    this.isPendingSwapSource = false,
  });

  final String displayName;
  final String? photoUrl;
  final bool isEmpty;
  final bool isWinner;
  final MatchParticipantType? participantType;
  final int? score;
  final bool isPendingSwapSource;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isPendingSwapSource
            ? const Color(0xFF22C55E).withValues(alpha: 0.15)
            : isWinner
                ? _kGreen.withValues(alpha: 0.06)
                : Colors.transparent,
        border: Border.all(
          color: isPendingSwapSource ? const Color(0xFF22C55E).withValues(alpha: 0.6) : Colors.transparent,
          width: isPendingSwapSource ? 1.5 : 0,
        ),
        boxShadow: isPendingSwapSource
            ? [BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2)]
            : null,
      ),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isEmpty
                    ? Colors.white.withValues(alpha: 0.25)
                    : isWinner
                        ? _kGreen
                        : Colors.white.withValues(alpha: 0.85),
                fontSize: 12.5,
                fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (participantType == MatchParticipantType.team) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.groups_rounded,
              size: 13,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ],
          if (score != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: isWinner
                    ? _kGreen.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.06),
              ),
              child: Text(
                '$score',
                style: TextStyle(
                  color: isWinner ? _kGreen : Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          if (isWinner) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.emoji_events_rounded,
              size: 13,
              color: _kGreen.withValues(alpha: 0.8),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isEmpty
            ? Colors.white.withValues(alpha: 0.05)
            : isWinner
                ? _kGreen.withValues(alpha: 0.15)
                : _kAccent.withValues(alpha: 0.12),
        border: Border.all(
          color: isEmpty
              ? Colors.white.withValues(alpha: 0.08)
              : isWinner
                  ? _kGreen.withValues(alpha: 0.4)
                  : _kAccent.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => _placeholderIcon(),
              ),
            )
          : _placeholderIcon(),
    );
  }

  Widget _placeholderIcon() {
    return Icon(
      isEmpty ? Icons.help_outline_rounded : Icons.person_rounded,
      size: 13,
      color: Colors.white.withValues(alpha: isEmpty ? 0.15 : 0.4),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _DragFeedbackWidget  ·  Widget
//
//  Pill flotante que aparece bajo el dedo mientras se arrastra un participante.
//  Diseñado para ser compacto, legible y no obstruir la vista del bracket.
// ─────────────────────────────────────────────────────────────────────────────

class _DragFeedbackWidget extends StatelessWidget {
  const _DragFeedbackWidget({
    required this.name,
    required this.photoUrl,
    required this.isEmpty,
  });

  final String name;
  final String? photoUrl;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: 1.05,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: const Color(0xFF1E293B),
            border: Border.all(color: _kAccent.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _kAccent.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kAccent.withValues(alpha: 0.2),
                  border: Border.all(color: _kAccent.withValues(alpha: 0.5)),
                ),
                child: photoUrl != null && photoUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) =>
                              const Icon(Icons.person_rounded, size: 13, color: _kAccent),
                        ),
                      )
                    : const Icon(Icons.person_rounded, size: 13, color: _kAccent),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.open_with_rounded, size: 14, color: _kAccent),
            ],
          ),
        ),
      ),
    );
  }
}
