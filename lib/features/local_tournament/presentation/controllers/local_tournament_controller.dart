import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../brackets/data/models/app_match.dart';
import '../../../brackets/presentation/controllers/bracket_admin_controller.dart' show DragSlotData;
import '../../data/models/local_athlete.dart';
import '../../data/models/local_match.dart';
import '../../data/models/local_tournament.dart';
import '../../data/repositories/local_tournament_repository.dart';
import '../../data/services/local_tournament_image_service.dart';
import '../../data/services/shared_preferences_local_tournament_repository.dart';
import '../../domain/local_bracket_generator.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LocalTournamentController  ·  Presentation
//
//  Gestiona el estado y las operaciones de un único torneo local.
//  Patrón: ChangeNotifier.
//  SRP: cada operación es atómica y persiste el estado inmediatamente.
// ─────────────────────────────────────────────────────────────────────────────

enum LocalTournamentControllerState {
  loading,
  ready,
  saving,
  error,
}

class LocalTournamentController extends ChangeNotifier {
  LocalTournamentController({
    required this.tournament,
    LocalTournamentRepository? repository,
    LocalTournamentImageService? imageService,
  })  : _repository = repository ?? SharedPreferencesLocalTournamentRepository(),
        _imageService = imageService ?? LocalTournamentImageService() {
    _current = tournament;
  }

  final LocalTournamentRepository _repository;
  final LocalTournamentImageService _imageService;
  static const _uuid = Uuid();

  LocalTournament tournament;
  late LocalTournament _current;

  LocalTournamentControllerState _state = LocalTournamentControllerState.ready;
  LocalTournamentControllerState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  LocalTournament get current => _current;

  List<LocalAthlete> get athletes => _current.athletes;
  List<LocalMatch> get matches => _current.matches;
  int get totalRounds => _current.totalRounds;
  Map<int, List<LocalMatch>> get matchesByRound => _current.matchesByRound;
  bool get hasBracket => _current.hasBracket;

  /// Matches adaptados al formato AppMatch para reutilizar BracketBoard y widgets existentes.
  Map<int, List<AppMatch>> get appMatchesByRound {
    final map = <int, List<AppMatch>>{};
    for (final match in _current.matches) {
      map.putIfAbsent(match.round, () => []).add(match.toAppMatch());
    }
    for (final list in map.values) {
      list.sort((a, b) => a.matchOrder.compareTo(b.matchOrder));
    }
    return map;
  }

  // ── Estado Intercambio Manual & Drag / Drop ──────────────────────────────

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

  String? validateSwapPreview({
    required AppMatch sourceMatch,
    required int sourceSlot,
    required AppMatch targetMatch,
    required int targetSlot,
  }) {
    if (sourceMatch.id == targetMatch.id && sourceSlot == targetSlot) {
      return 'No puedes intercambiar un participante consigo mismo.';
    }
    if (sourceMatch.round != 0 || targetMatch.round != 0) {
      return 'Solo se pueden intercambiar participantes de la primera ronda.';
    }
    if (sourceMatch.isCompleted || targetMatch.isCompleted) {
      return 'No se puede intercambiar en un enfrentamiento ya completado.';
    }
    final sourceId =
        sourceSlot == 1 ? sourceMatch.participant1Id : sourceMatch.participant2Id;
    final targetId =
        targetSlot == 1 ? targetMatch.participant1Id : targetMatch.participant2Id;
    if ((sourceId == null || sourceId.isEmpty) &&
        (targetId == null || targetId.isEmpty)) {
      return 'Ambos slots están vacíos.';
    }
    return null;
  }

  Future<String?> swapParticipantsDragDrop({
    required AppMatch sourceMatch,
    required int sourceSlot,
    required AppMatch targetMatch,
    required int targetSlot,
  }) async {
    return swapAthletes(
      matchId1: sourceMatch.id,
      slot1: sourceSlot,
      matchId2: targetMatch.id,
      slot2: targetSlot,
    );
  }

  Future<String?> executeManualSwap(AppMatch targetMatch, int targetSlot) async {
    if (_pendingSwapSource == null) return 'No hay un participante seleccionado para intercambiar.';
    final source = _pendingSwapSource!;
    _pendingSwapSource = null;
    notifyListeners();

    return swapAthletes(
      matchId1: source.match.id,
      slot1: source.slot,
      matchId2: targetMatch.id,
      slot2: targetSlot,
    );
  }

  // ── Atletas ────────────────────────────────────────────────────────────────

  /// Añade un atleta con el nombre dado.
  /// Genera un ID único internamente. Permite nombres duplicados.
  Future<void> addAthlete(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final athlete = LocalAthlete(
      id: _uuid.v4(),
      name: trimmed,
      createdAt: DateTime.now(),
    );

    _current = _current.copyWith(
      athletes: [..._current.athletes, athlete],
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
  }

  /// Añade múltiples atletas a la vez (para flujos rápidos de registro).
  Future<void> addAthletes(List<String> names) async {
    final now = DateTime.now();
    final newAthletes = names
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .map((n) => LocalAthlete(id: _uuid.v4(), name: n, createdAt: now))
        .toList();

    if (newAthletes.isEmpty) return;

    _current = _current.copyWith(
      athletes: [..._current.athletes, ...newAthletes],
      updatedAt: now,
    );
    notifyListeners();
    await _persist();
  }

  /// Edita el nombre de un atleta existente.
  Future<void> editAthlete(String athleteId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final updated = _current.athletes.map((a) {
      return a.id == athleteId ? a.copyWith(name: trimmed) : a;
    }).toList();

    _current = _current.copyWith(
      athletes: updated,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
  }

  /// Elimina un atleta. Si hay bracket activo, limpia su slot.
  Future<void> removeAthlete(String athleteId) async {
    final updatedAthletes = _current.athletes
        .where((a) => a.id != athleteId)
        .toList();

    // Si hay bracket, limpiar el atleta de sus matches
    List<LocalMatch> updatedMatches = _current.matches;
    if (_current.hasBracket) {
      updatedMatches = _current.matches.map((m) {
        LocalMatch updated = m;
        if (m.athlete1?.id == athleteId) {
          updated = updated.copyWith(clearAthlete1: true);
        }
        if (m.athlete2?.id == athleteId) {
          updated = updated.copyWith(clearAthlete2: true);
        }
        if (m.winnerId == athleteId) {
          updated = updated.copyWith(
            clearWinner: true,
            status: LocalMatchStatus.pending,
          );
        }
        return updated;
      }).toList();
    }

    _current = _current.copyWith(
      athletes: updatedAthletes,
      matches: updatedMatches,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
  }

  /// Reordena los atletas (para drag & drop en la lista).
  Future<void> reorderAthletes(int oldIndex, int newIndex) async {
    final list = List<LocalAthlete>.from(_current.athletes);
    if (newIndex > oldIndex) newIndex--;
    final athlete = list.removeAt(oldIndex);
    list.insert(newIndex, athlete);

    _current = _current.copyWith(
      athletes: list,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
  }

  // ── Bracket ────────────────────────────────────────────────────────────────

  /// Genera el bracket de eliminación directa.
  /// Si ya existe uno, lo reemplaza.
  Future<void> generateBracket() async {
    if (_current.athletes.isEmpty) {
      _setError('Añade al menos un atleta para generar el bracket.');
      return;
    }

    _setState(LocalTournamentControllerState.saving);

    final result = LocalBracketGenerator.generate(
      bracketId: _current.id,
      athletes: _current.athletes,
      shuffle: true,
    );

    _current = _current.copyWith(
      matches: result.matches,
      totalRounds: result.totalRounds,
      status: LocalTournamentStatus.inProgress,
      updatedAt: DateTime.now(),
    );

    _successMessage = 'Bracket generado correctamente.';
    _setState(LocalTournamentControllerState.ready);
    await _persist();
  }

  /// Intercambia dos atletas en los slots de la primera ronda.
  Future<String?> swapAthletes({
    required String matchId1,
    required int slot1,
    required String matchId2,
    required int slot2,
  }) async {
    if (matchId1 == matchId2 && slot1 == slot2) {
      return 'No puedes intercambiar un participante consigo mismo.';
    }

    final match1 = _matchById(matchId1);
    final match2 = _matchById(matchId2);

    if (match1 == null || match2 == null) return 'Enfrentamiento no encontrado.';
    if (match1.round != 0 || match2.round != 0) {
      return 'Solo se pueden intercambiar participantes de la primera ronda.';
    }
    if (match1.isCompleted || match2.isCompleted) {
      return 'No se puede intercambiar en un enfrentamiento completado.';
    }

    final a1 = slot1 == 1 ? match1.athlete1 : match1.athlete2;
    final a2 = slot2 == 1 ? match2.athlete1 : match2.athlete2;

    if (a1 == null && a2 == null) {
      return 'Ambos slots están vacíos.';
    }

    final updatedMatches = _current.matches.map((m) {
      if (m.id == matchId1) {
        return slot1 == 1
            ? m.copyWith(athlete1: a2)
            : m.copyWith(athlete2: a2);
      }
      if (m.id == matchId2) {
        return slot2 == 1
            ? m.copyWith(athlete1: a1)
            : m.copyWith(athlete2: a1);
      }
      return m;
    }).toList();

    _current = _current.copyWith(
      matches: updatedMatches,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
    return null; // éxito
  }

  /// Registra el resultado de un match y hace avanzar al ganador.
  /// Si se modifica un resultado previo, limpia en cascada las rondas posteriores
  /// para evitar inconsistencias en el bracket.
  Future<String?> recordMatchResult({
    required String matchId,
    required String winnerId,
    required String loserId,
    int scoreAthlete1 = 0,
    int scoreAthlete2 = 0,
  }) async {
    final match = _matchById(matchId);
    if (match == null) return 'Enfrentamiento no encontrado.';
    if (!match.isReady) return 'El enfrentamiento aún no tiene ambos participantes.';
    if (match.isBye) return 'No se puede registrar resultado en un BYE.';

    final winner = match.athlete1?.id == winnerId
        ? match.athlete1!
        : match.athlete2!;

    final oldWinnerId = match.winnerId;

    List<LocalMatch> updatedMatches = List<LocalMatch>.from(_current.matches);

    // Si se está cambiando un ganador previo, limpiar en cascada su rastro
    if (oldWinnerId != null && oldWinnerId != winnerId) {
      _clearDescendantWinner(
        updatedMatches,
        match.childMatchId,
        match.positionInChild,
        oldWinnerId,
      );
    }

    // Actualizar el match actual
    final matchIdx = updatedMatches.indexWhere((m) => m.id == matchId);
    if (matchIdx != -1) {
      updatedMatches[matchIdx] = updatedMatches[matchIdx].copyWith(
        status: LocalMatchStatus.completed,
        winnerId: winnerId,
        loserId: loserId,
        scoreAthlete1: scoreAthlete1,
        scoreAthlete2: scoreAthlete2,
      );
    }

    // Hacer avanzar al ganador al match hijo
    if (match.childMatchId != null && match.childMatchId!.isNotEmpty) {
      final childIdx = updatedMatches.indexWhere((m) => m.id == match.childMatchId);
      if (childIdx != -1) {
        if (match.positionInChild == 1) {
          updatedMatches[childIdx] = updatedMatches[childIdx].copyWith(athlete1: winner);
        } else {
          updatedMatches[childIdx] = updatedMatches[childIdx].copyWith(athlete2: winner);
        }
      }
    }

    // Actualizar estado del torneo si el final está completado
    LocalTournamentStatus newStatus = _current.status;
    final finalMatch = updatedMatches.firstWhere(
      (m) => m.isFinal,
      orElse: () => updatedMatches.first,
    );
    if (finalMatch.isCompleted || (finalMatch.childMatchId == null && matchId == finalMatch.id)) {
      final updated = updatedMatches.firstWhere((m) => m.id == matchId);
      if (updated.isCompleted && updated.isFinal) {
        newStatus = LocalTournamentStatus.finished;
      }
    }

    _current = _current.copyWith(
      matches: updatedMatches,
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    _successMessage = 'Resultado registrado. ${winner.name} avanza.';
    notifyListeners();
    await _persist();
    return null;
  }

  /// Deshace el resultado de un match (permite corregir errores).
  /// Limpia recursivamente al ganador de todas las rondas posteriores.
  Future<String?> undoMatchResult(String matchId) async {
    final match = _matchById(matchId);
    if (match == null) return 'Enfrentamiento no encontrado.';
    if (!match.isCompleted) return 'El enfrentamiento no tiene resultado.';

    final previousWinnerId = match.winnerId;

    List<LocalMatch> updatedMatches = List<LocalMatch>.from(_current.matches);

    // Restablecer el match actual
    final matchIdx = updatedMatches.indexWhere((m) => m.id == matchId);
    if (matchIdx != -1) {
      updatedMatches[matchIdx] = LocalMatch(
        id: match.id,
        bracketId: match.bracketId,
        round: match.round,
        matchOrder: match.matchOrder,
        status: LocalMatchStatus.pending,
        athlete1: match.athlete1,
        athlete2: match.athlete2,
        parentMatch1Id: match.parentMatch1Id,
        parentMatch2Id: match.parentMatch2Id,
        childMatchId: match.childMatchId,
        positionInChild: match.positionInChild,
      );
    }

    // Limpiar en cascada al ganador de todos los matches hijos
    if (previousWinnerId != null) {
      _clearDescendantWinner(
        updatedMatches,
        match.childMatchId,
        match.positionInChild,
        previousWinnerId,
      );
    }

    _current = _current.copyWith(
      matches: updatedMatches,
      status: LocalTournamentStatus.inProgress,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
    return null;
  }

  void _clearDescendantWinner(
    List<LocalMatch> matchesList,
    String? childMatchId,
    int? positionInChild,
    String? oldWinnerId,
  ) {
    if (childMatchId == null || childMatchId.isEmpty || oldWinnerId == null) return;
    final idx = matchesList.indexWhere((m) => m.id == childMatchId);
    if (idx == -1) return;
    final child = matchesList[idx];

    LocalMatch updated = child;
    bool changed = false;

    if (positionInChild == 1 && child.athlete1?.id == oldWinnerId) {
      updated = updated.copyWith(clearAthlete1: true);
      changed = true;
    } else if (positionInChild == 2 && child.athlete2?.id == oldWinnerId) {
      updated = updated.copyWith(clearAthlete2: true);
      changed = true;
    }

    if (child.winnerId == oldWinnerId) {
      updated = updated.copyWith(clearWinner: true, status: LocalMatchStatus.pending);
      changed = true;
      _clearDescendantWinner(
        matchesList,
        child.childMatchId,
        child.positionInChild,
        oldWinnerId,
      );
    }

    if (changed) {
      matchesList[idx] = updated;
    }
  }

  // ── Torneo ─────────────────────────────────────────────────────────────────

  /// Actualiza el nombre del torneo.
  Future<void> updateName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _current = _current.copyWith(name: trimmed, updatedAt: DateTime.now());
    notifyListeners();
    await _persist();
  }

  /// Actualiza el deporte/disciplina.
  Future<void> updateSport(String? sport) async {
    _current = _current.copyWith(sport: sport, updatedAt: DateTime.now());
    notifyListeners();
    await _persist();
  }

  // ── Portada ────────────────────────────────────────────────────────────────

  /// Selecciona una imagen de la galería para vista previa.
  Future<XFile?> pickImageForPreview() async {
    return _imageService.pickImageFile();
  }

  /// Confirma y guarda una imagen seleccionada tras la vista previa.
  Future<bool> setCoverImage(XFile file) async {
    final path = await _imageService.savePickedImage(file, _current.id);
    if (path == null) return false;

    // Eliminar imagen anterior si existe
    if (_current.coverImagePath != null) {
      await _imageService.deleteCoverImage(_current.coverImagePath);
    }

    _current = _current.copyWith(
      coverImagePath: path,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
    return true;
  }

  /// Abre el selector de galería y guarda la imagen de portada directamente.
  Future<bool> pickCoverImage() async {
    final path = await _imageService.pickAndSaveCoverImage(
      tournamentId: _current.id,
    );
    if (path == null) return false;

    // Eliminar imagen anterior si existe
    if (_current.coverImagePath != null) {
      await _imageService.deleteCoverImage(_current.coverImagePath);
    }

    _current = _current.copyWith(
      coverImagePath: path,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
    return true;
  }

  /// Elimina la imagen de portada actual.
  Future<void> removeCoverImage() async {
    await _imageService.deleteCoverImage(_current.coverImagePath);
    _current = _current.copyWith(
      clearCoverImage: true,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
  }

  // ── Nombre del round ──────────────────────────────────────────────────────

  String roundName(int roundIndex) {
    final total = _current.totalRounds;
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

  // ── Mensajes ──────────────────────────────────────────────────────────────

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // ── Interno ────────────────────────────────────────────────────────────────

  LocalMatch? _matchById(String id) {
    try {
      return _current.matches.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist() async {
    try {
      await _repository.saveTournament(_current);
    } catch (e) {
      debugPrint('LocalTournamentController: error persisting: $e');
    }
  }

  void _setState(LocalTournamentControllerState state) {
    _state = state;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _state = LocalTournamentControllerState.error;
    notifyListeners();
  }
}
