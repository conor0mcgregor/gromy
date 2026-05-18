import '../../data/models/app_bracket.dart';
import '../../data/models/app_match.dart';
import '../../data/repositories/bracket_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SwapParticipantsUseCase  ·  Domain
//
//  Encapsula la lógica de validación y ejecución del intercambio de
//  participantes entre dos slots del bracket.
//
//  Validaciones:
//   - Bracket debe estar en modo draft
//   - Ambos matches deben pertenecer al mismo bracket
//   - Ambos matches deben ser de primera ronda (round 0)
//   - No se puede intercambiar un slot consigo mismo
//   - No se puede intercambiar slots vacíos entre sí (ambos nulos)
//   - El bracket no puede estar publicado/bloqueado
// ─────────────────────────────────────────────────────────────────────────────

/// Resultado de una validación de intercambio.
sealed class SwapValidationResult {
  const SwapValidationResult();
}

/// El intercambio es válido.
class SwapValid extends SwapValidationResult {
  const SwapValid();
}

/// El intercambio no es válido, con motivo descriptivo.
class SwapInvalid extends SwapValidationResult {
  const SwapInvalid(this.reason);
  final String reason;
}

class SwapParticipantsUseCase {
  const SwapParticipantsUseCase(this._repository);

  final BracketRepository _repository;

  // ── Validación en cliente (pre-check antes de llamar al backend) ──────────

  SwapValidationResult validate({
    required AppBracket bracket,
    required AppMatch sourceMatch,
    required int sourceSlot,
    required AppMatch targetMatch,
    required int targetSlot,
  }) {
    // 1. El bracket debe estar en draft
    if (!bracket.status.isDraft) {
      return const SwapInvalid(
        'El bracket ya está publicado. No se pueden intercambiar participantes.',
      );
    }

    // 2. Ambos matches deben ser de primera ronda
    if (sourceMatch.round != 0) {
      return const SwapInvalid(
        'Solo se pueden intercambiar participantes de la primera ronda.',
      );
    }
    if (targetMatch.round != 0) {
      return const SwapInvalid(
        'El destino debe ser un match de la primera ronda.',
      );
    }

    // 3. No intercambiar consigo mismo
    if (sourceMatch.id == targetMatch.id && sourceSlot == targetSlot) {
      return const SwapInvalid(
        'No puedes intercambiar un participante consigo mismo.',
      );
    }

    // 4. No intercambiar matches completados/BYE
    if (sourceMatch.isCompleted) {
      return const SwapInvalid(
        'El enfrentamiento de origen ya está completado.',
      );
    }
    if (targetMatch.isCompleted) {
      return const SwapInvalid(
        'El enfrentamiento de destino ya está completado.',
      );
    }

    // 5. El slot origen no puede ser completamente vacío si el destino también es vacío
    final sourceId = sourceSlot == 1
        ? sourceMatch.participant1Id
        : sourceMatch.participant2Id;
    final targetId = targetSlot == 1
        ? targetMatch.participant1Id
        : targetMatch.participant2Id;

    if ((sourceId == null || sourceId.isEmpty) &&
        (targetId == null || targetId.isEmpty)) {
      return const SwapInvalid(
        'Ambos slots están vacíos. No hay nada que intercambiar.',
      );
    }

    // 6. Evitar dejar un enfrentamiento completamente vacío
    final newSource1 = sourceSlot == 1 ? targetId : sourceMatch.participant1Id;
    final newSource2 = sourceSlot == 2 ? targetId : sourceMatch.participant2Id;

    final newTarget1 = targetSlot == 1 ? sourceId : targetMatch.participant1Id;
    final newTarget2 = targetSlot == 2 ? sourceId : targetMatch.participant2Id;

    bool isSourceEmpty = (newSource1 == null || newSource1.isEmpty) && (newSource2 == null || newSource2.isEmpty);
    bool isTargetEmpty = (newTarget1 == null || newTarget1.isEmpty) && (newTarget2 == null || newTarget2.isEmpty);

    if (isSourceEmpty || isTargetEmpty) {
      return const SwapInvalid('No se permite dejar un enfrentamiento completamente vacío (BYE vs BYE).');
    }

    return const SwapValid();
  }

  // ── Ejecución vía Cloud Function ─────────────────────────────────────────

  Future<void> call({
    required String bracketId,
    required String matchId1,
    required int slotInMatch1,
    required String matchId2,
    required int slotInMatch2,
  }) async {
    await _repository.swapParticipants(
      bracketId: bracketId,
      matchId1: matchId1,
      slotInMatch1: slotInMatch1,
      matchId2: matchId2,
      slotInMatch2: slotInMatch2,
    );
  }
}
