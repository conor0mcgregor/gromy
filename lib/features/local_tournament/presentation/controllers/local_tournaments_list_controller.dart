import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/local_tournament.dart';
import '../../data/repositories/local_tournament_repository.dart';
import '../../data/services/shared_preferences_local_tournament_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LocalTournamentsListController  ·  Presentation
//
//  Gestiona la lista de torneos locales (creación, eliminación, listado).
//  Patrón: ChangeNotifier.
// ─────────────────────────────────────────────────────────────────────────────

class LocalTournamentsListController extends ChangeNotifier {
  LocalTournamentsListController({LocalTournamentRepository? repository})
      : _repository = repository ?? SharedPreferencesLocalTournamentRepository();

  final LocalTournamentRepository _repository;
  static const _uuid = Uuid();

  List<LocalTournament> _tournaments = [];
  List<LocalTournament> get tournaments => _tournaments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Carga todos los torneos locales.
  Future<void> loadTournaments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tournaments = await _repository.getAllTournaments();
    } catch (e) {
      _error = 'Error al cargar torneos: $e';
      debugPrint('LocalTournamentsListController: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crea un nuevo torneo local con el nombre dado.
  Future<LocalTournament?> createTournament({
    required String name,
    String? sport,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final now = DateTime.now();
    final tournament = LocalTournament(
      id: _uuid.v4(),
      name: trimmed,
      sport: sport?.trim().isEmpty == true ? null : sport?.trim(),
      createdAt: now,
      updatedAt: now,
      status: LocalTournamentStatus.setup,
      athletes: const [],
      matches: const [],
    );

    try {
      await _repository.saveTournament(tournament);
      _tournaments = [tournament, ..._tournaments];
      notifyListeners();
      return tournament;
    } catch (e) {
      debugPrint('LocalTournamentsListController: create error: $e');
      return null;
    }
  }

  /// Elimina un torneo local.
  Future<void> deleteTournament(String id) async {
    try {
      await _repository.deleteTournament(id);
      _tournaments = _tournaments.where((t) => t.id != id).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('LocalTournamentsListController: delete error: $e');
    }
  }

  /// Recarga un torneo específico desde el repositorio (tras volver de detalle).
  Future<void> refreshTournament(String id) async {
    try {
      final updated = await _repository.getTournamentById(id);
      if (updated != null) {
        _tournaments = _tournaments.map((t) => t.id == id ? updated : t).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('LocalTournamentsListController: refresh error: $e');
    }
  }
}
