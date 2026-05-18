import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/app_bracket.dart';
import '../../data/models/app_match.dart';
import '../../data/repositories/bracket_repository.dart';
import '../../data/services/firestore_bracket_service.dart';
import '../../domain/use_cases/generate_bracket_use_case.dart';
import '../../domain/use_cases/publish_bracket_use_case.dart';
import '../../domain/use_cases/record_match_result_use_case.dart';
import '../../domain/use_cases/swap_participants_use_case.dart';
import '../../domain/use_cases/watch_bracket_use_case.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  BracketAdminController  ·  Presentation
//
//  Controller para la gestión administrativa de brackets.
//  Incluye operaciones de generación, edición, publicación y
//  registro de resultados.
//
//  SRP: gestiona estado y operaciones admin del bracket.
//  Patrón: ChangeNotifier.
// ─────────────────────────────────────────────────────────────────────────────

enum BracketAdminState { idle, loading, generating, publishing, saving, error }

/// Datos del slot que se está arrastrando actualmente.
class DragSlotData {
  const DragSlotData({
    required this.match,
    required this.slot,
  });

  final AppMatch match;

  /// 1 = participante superior, 2 = participante inferior.
  final int slot;

  String? get participantId =>
      slot == 1 ? match.participant1Id : match.participant2Id;

  String? get participantName =>
      slot == 1 ? match.participant1Name : match.participant2Name;

  String? get participantPhotoUrl =>
      slot == 1 ? match.participant1PhotoUrl : match.participant2PhotoUrl;
}

class BracketAdminController extends ChangeNotifier {
  BracketAdminController({
    required this.tournamentId,
    BracketRepository? repository,
  }) : _repository = repository ?? FirestoreBracketService() {
    _generateUseCase = GenerateBracketUseCase(_repository);
    _publishUseCase = PublishBracketUseCase(_repository);
    _recordResultUseCase = RecordMatchResultUseCase(_repository);
    _watchUseCase = WatchBracketUseCase(_repository);
    _swapUseCase = SwapParticipantsUseCase(_repository);
    _initBracketsStream();
  }

  final String tournamentId;
  final BracketRepository _repository;
  late final GenerateBracketUseCase _generateUseCase;
  late final PublishBracketUseCase _publishUseCase;
  late final RecordMatchResultUseCase _recordResultUseCase;
  late final WatchBracketUseCase _watchUseCase;
  late final SwapParticipantsUseCase _swapUseCase;

  // ── Estado ──────────────────────────────────────────────────────────────

  BracketAdminState _state = BracketAdminState.idle;
  BracketAdminState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  /// Todos los brackets del torneo (incluidos drafts para admin).
  List<AppBracket> _brackets = [];
  List<AppBracket> get brackets => _brackets;

  /// Bracket actualmente en edición.
  AppBracket? _activeBracket;
  AppBracket? get activeBracket => _activeBracket;

  /// Matches del bracket activo.
  List<AppMatch> _matches = [];
  List<AppMatch> get matches => _matches;

  // ── Estado drag & drop ─────────────────────────────────────────────────

  /// Slot que se está arrastrando actualmente (null = sin drag activo).
  DragSlotData? _activeDrag;
  DragSlotData? get activeDrag => _activeDrag;

  bool get isDragging => _activeDrag != null;

  void onDragStarted(AppMatch match, int slot) {
    _activeDrag = DragSlotData(match: match, slot: slot);
    notifyListeners();
  }

  void onDragEnded() {
    if (_activeDrag != null) {
      _activeDrag = null;
      notifyListeners();
    }
  }

  // ── Estado Intercambio Manual ──────────────────────────────────────────

  DragSlotData? _pendingSwapSource;
  DragSlotData? get pendingSwapSource => _pendingSwapSource;

  void startManualSwap(AppMatch match, int slot) {
    _pendingSwapSource = DragSlotData(match: match, slot: slot);
    notifyListeners();
  }

  void cancelManualSwap() {
    if (_pendingSwapSource != null) {
      _pendingSwapSource = null;
      notifyListeners();
    }
  }

  Future<String?> executeManualSwap(AppMatch targetMatch, int targetSlot) async {
    if (_pendingSwapSource == null) return 'No hay un origen seleccionado.';
    
    final source = _pendingSwapSource!;
    _pendingSwapSource = null; // Exit mode
    notifyListeners();

    return swapParticipantsDragDrop(
      sourceMatch: source.match,
      sourceSlot: source.slot,
      targetMatch: targetMatch,
      targetSlot: targetSlot,
    );
  }

  // ── Matches organizados por round ────────────────────────────────────────

  /// Matches organizados por round.
  Map<int, List<AppMatch>> get matchesByRound {
    final map = <int, List<AppMatch>>{};
    for (final match in _matches) {
      map.putIfAbsent(match.round, () => []).add(match);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.matchOrder.compareTo(b.matchOrder));
    }
    return map;
  }

  /// `true` si el bracket activo está en modo draft (editable).
  bool get isDraftMode => _activeBracket?.status.isDraft ?? false;

  /// `true` si hay un bracket generado (cualquier estado).
  bool get hasBracket => _brackets.isNotEmpty;

  // ── Streams ─────────────────────────────────────────────────────────────

  StreamSubscription<List<AppBracket>>? _bracketsSub;
  StreamSubscription<List<AppMatch>>? _matchesSub;

  void _initBracketsStream() {
    _bracketsSub = _watchUseCase
        .watchBrackets(tournamentId)
        .listen(
          (brackets) {
            _brackets = brackets;

            if (_brackets.isEmpty) {
              _activeBracket = null;
              _matches = [];
              _state = BracketAdminState.idle;
              notifyListeners();
              return;
            }

            // Auto-seleccionar bracket activo
            if (_activeBracket == null ||
                !_brackets.any((b) => b.id == _activeBracket!.id)) {
              selectBracket(_brackets.first);
            } else {
              _activeBracket = _brackets.firstWhere(
                (b) => b.id == _activeBracket!.id,
                orElse: () => _brackets.first,
              );
              if (_state == BracketAdminState.loading) {
                _state = BracketAdminState.idle;
              }
              notifyListeners();
            }
          },
          onError: (error) {
            _state = BracketAdminState.error;
            _errorMessage = 'Error al cargar brackets: $error';
            notifyListeners();
          },
        );
  }

  void selectBracket(AppBracket bracket) {
    _activeBracket = bracket;
    _state = BracketAdminState.loading;
    notifyListeners();

    _matchesSub?.cancel();
    _matchesSub = _watchUseCase
        .watchMatches(bracket.id)
        .listen(
          (matches) {
            _matches = matches;
            _state = BracketAdminState.idle;
            notifyListeners();
          },
          onError: (error) {
            _state = BracketAdminState.error;
            _errorMessage = 'Error al cargar matches: $error';
            notifyListeners();
          },
        );
  }

  // ── Operaciones Admin ─────────────────────────────────────────────────

  /// Genera un nuevo bracket para el torneo.
  Future<void> generateBracket({String? categoryId}) async {
    _state = BracketAdminState.generating;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final bracket = await _generateUseCase(
        tournamentId: tournamentId,
        categoryId: categoryId,
      );
      _activeBracket = bracket;
      _successMessage = 'Bracket generado correctamente.';
      _state = BracketAdminState.idle;
    } catch (e) {
      _state = BracketAdminState.error;
      _errorMessage = _extractErrorMessage(e);
    }
    notifyListeners();
  }

  /// Regenera el bracket actual (solo si está en draft).
  Future<void> regenerateBracket() async {
    if (_activeBracket == null) return;
    if (!isDraftMode) {
      _errorMessage = 'Solo se puede regenerar un bracket en borrador.';
      _state = BracketAdminState.error;
      notifyListeners();
      return;
    }

    _state = BracketAdminState.generating;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final bracket = await _repository.regenerateBracket(
        bracketId: _activeBracket!.id,
      );
      _activeBracket = bracket;
      _successMessage = 'Bracket regenerado correctamente.';
      _state = BracketAdminState.idle;
    } catch (e) {
      _state = BracketAdminState.error;
      _errorMessage = _extractErrorMessage(e);
    }
    notifyListeners();
  }

  /// Publica el bracket actual.
  Future<void> publishBracket() async {
    if (_activeBracket == null) return;

    _state = BracketAdminState.publishing;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _publishUseCase(bracketId: _activeBracket!.id);
      _successMessage = 'Bracket publicado correctamente.';
      _state = BracketAdminState.idle;
    } catch (e) {
      _state = BracketAdminState.error;
      _errorMessage = _extractErrorMessage(e);
    }
    notifyListeners();
  }

  /// Registra el resultado de un match.
  Future<void> recordMatchResult({
    required String matchId,
    required String winnerId,
    required String loserId,
    required int scoreParticipant1,
    required int scoreParticipant2,
  }) async {
    if (_activeBracket == null) return;

    _state = BracketAdminState.saving;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _recordResultUseCase(
        bracketId: _activeBracket!.id,
        matchId: matchId,
        winnerId: winnerId,
        loserId: loserId,
        scoreParticipant1: scoreParticipant1,
        scoreParticipant2: scoreParticipant2,
      );
      _successMessage = 'Resultado registrado. El ganador avanza.';
      _state = BracketAdminState.idle;
    } catch (e) {
      _state = BracketAdminState.error;
      _errorMessage = _extractErrorMessage(e);
    }
    notifyListeners();
  }

  /// Actualiza el horario de un match.
  Future<void> updateMatchSchedule({
    required String matchId,
    required DateTime scheduledAt,
  }) async {
    if (_activeBracket == null) return;

    _state = BracketAdminState.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateMatchSchedule(
        bracketId: _activeBracket!.id,
        matchId: matchId,
        scheduledAt: scheduledAt,
      );
      _successMessage = 'Horario actualizado.';
      _state = BracketAdminState.idle;
    } catch (e) {
      _state = BracketAdminState.error;
      _errorMessage = _extractErrorMessage(e);
    }
    notifyListeners();
  }

  /// Intercambia participantes via drag & drop (solo en draft).
  /// Valida localmente antes de llamar al backend.
  /// Devuelve [null] si el intercambio fue exitoso, o un mensaje de error.
  Future<String?> swapParticipantsDragDrop({
    required AppMatch sourceMatch,
    required int sourceSlot,
    required AppMatch targetMatch,
    required int targetSlot,
  }) async {
    if (_activeBracket == null) return 'Bracket no encontrado.';

    // Validación en cliente
    final validation = _swapUseCase.validate(
      bracket: _activeBracket!,
      sourceMatch: sourceMatch,
      sourceSlot: sourceSlot,
      targetMatch: targetMatch,
      targetSlot: targetSlot,
    );

    if (validation is SwapInvalid) {
      return validation.reason;
    }

    _state = BracketAdminState.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      await _swapUseCase(
        bracketId: _activeBracket!.id,
        matchId1: sourceMatch.id,
        slotInMatch1: sourceSlot,
        matchId2: targetMatch.id,
        slotInMatch2: targetSlot,
      );
      _successMessage = 'Participantes intercambiados.';
      _state = BracketAdminState.idle;
      notifyListeners();
      return null; // éxito
    } catch (e) {
      _state = BracketAdminState.error;
      _errorMessage = _extractErrorMessage(e);
      notifyListeners();
      return _errorMessage;
    }
  }

  /// Intercambia participantes entre dos slots (solo en draft).
  /// Mantiene compatibilidad con el sistema anterior.
  Future<void> swapParticipants({
    required String matchId1,
    required int slotInMatch1,
    required String matchId2,
    required int slotInMatch2,
  }) async {
    if (_activeBracket == null || !isDraftMode) return;

    _state = BracketAdminState.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.swapParticipants(
        bracketId: _activeBracket!.id,
        matchId1: matchId1,
        slotInMatch1: slotInMatch1,
        matchId2: matchId2,
        slotInMatch2: slotInMatch2,
      );
      _successMessage = 'Participantes intercambiados.';
      _state = BracketAdminState.idle;
    } catch (e) {
      _state = BracketAdminState.error;
      _errorMessage = _extractErrorMessage(e);
    }
    notifyListeners();
  }

  /// Nombre del round según su índice.
  String roundName(int roundIndex) {
    final total = _activeBracket?.totalRounds ?? 0;
    final roundsFromEnd = total - roundIndex;
    return switch (roundsFromEnd) {
      1 => 'Final',
      2 => 'Semifinales',
      3 => 'Cuartos de final',
      4 => 'Octavos de final',
      5 => 'Dieciseisavos',
      _ => 'Ronda ${roundIndex + 1}',
    };
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  String _extractErrorMessage(dynamic e) {
    String fullError = e.toString();

    String firstLine = fullError.split('\n').first;

    if (firstLine.contains(']')) {
      return firstLine.split(']').last.trim();
    }

    return firstLine.trim();
  }

  @override
  void dispose() {
    _bracketsSub?.cancel();
    _matchesSub?.cancel();
    super.dispose();
  }
}
