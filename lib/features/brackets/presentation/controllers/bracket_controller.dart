import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/app_bracket.dart';
import '../../data/models/app_match.dart';
import '../../data/repositories/bracket_repository.dart';
import '../../data/services/firestore_bracket_service.dart';
import '../../domain/use_cases/watch_bracket_use_case.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  BracketController  ·  Presentation
//
//  Controller reactivo para la visualización pública de brackets.
//  Gestiona el estado de carga, selección de categoría y los streams
//  de bracket/matches en tiempo real.
//
//  SRP: solo se encarga del estado de presentación del bracket.
//  Patrón: ChangeNotifier (consistente con el resto de la app).
// ─────────────────────────────────────────────────────────────────────────────

enum BracketViewState { loading, loaded, empty, error }

class BracketController extends ChangeNotifier {
  BracketController({required this.tournamentId, BracketRepository? repository})
    : _repository = repository ?? FirestoreBracketService() {
    _watchUseCase = WatchBracketUseCase(_repository);
    _initBracketsStream();
  }

  final String tournamentId;
  final BracketRepository _repository;
  late final WatchBracketUseCase _watchUseCase;

  // ── Estado ──────────────────────────────────────────────────────────────

  BracketViewState _state = BracketViewState.loading;
  BracketViewState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Lista de todos los brackets del torneo (uno por categoría).
  List<AppBracket> _brackets = [];
  List<AppBracket> get brackets => _brackets;

  /// Bracket actualmente seleccionado.
  AppBracket? _selectedBracket;
  AppBracket? get selectedBracket => _selectedBracket;

  /// Matches del bracket seleccionado.
  List<AppMatch> _matches = [];
  List<AppMatch> get matches => _matches;

  /// Matches organizados por round para el renderizado.
  Map<int, List<AppMatch>> get matchesByRound {
    final map = <int, List<AppMatch>>{};
    for (final match in _matches) {
      map.putIfAbsent(match.round, () => []).add(match);
    }
    // Ordenar matches dentro de cada round
    for (final list in map.values) {
      list.sort((a, b) => a.matchOrder.compareTo(b.matchOrder));
    }
    return map;
  }

  /// Indica si hay un bracket publicado visible.
  bool get hasPublishedBracket =>
      _brackets.any((b) => b.status.isPubliclyVisible);

  /// Categorías disponibles (extraídas de los brackets).
  List<String> get availableCategories => _brackets
      .where((b) => b.categoryName != null && b.categoryName!.isNotEmpty)
      .map((b) => b.categoryName!)
      .toSet()
      .toList();

  // ── Streams ─────────────────────────────────────────────────────────────

  StreamSubscription<List<AppBracket>>? _bracketsSub;
  StreamSubscription<List<AppMatch>>? _matchesSub;

  void _initBracketsStream() {
    _bracketsSub = _watchUseCase
        .watchBrackets(tournamentId)
        .listen(
          (brackets) {
            // Solo mostrar brackets publicados/activos/completados para usuarios
            _brackets = brackets
                .where((b) => b.status.isPubliclyVisible)
                .toList();

            if (_brackets.isEmpty) {
              _state = BracketViewState.empty;
              _selectedBracket = null;
              _matches = [];
              notifyListeners();
              return;
            }

            // Auto-seleccionar el primer bracket si no hay uno seleccionado
            if (_selectedBracket == null ||
                !_brackets.any((b) => b.id == _selectedBracket!.id)) {
              selectBracket(_brackets.first);
            } else {
              // Actualizar el bracket seleccionado con datos nuevos
              final updated = _brackets.firstWhere(
                (b) => b.id == _selectedBracket!.id,
                orElse: () => _brackets.first,
              );
              _selectedBracket = updated;
              _state = BracketViewState.loaded;
              notifyListeners();
            }
          },
          onError: (error) {
            _state = BracketViewState.error;
            _errorMessage = 'Error al cargar brackets: $error';
            notifyListeners();
          },
        );
  }

  /// Cambia el bracket seleccionado (ej. al cambiar de categoría).
  void selectBracket(AppBracket bracket) {
    _selectedBracket = bracket;
    _state = BracketViewState.loading;
    notifyListeners();

    // Cancelar stream anterior de matches
    _matchesSub?.cancel();

    // Iniciar nuevo stream de matches
    _matchesSub = _watchUseCase
        .watchMatches(bracket.id)
        .listen(
          (matches) {
            _matches = matches;
            _state = BracketViewState.loaded;
            notifyListeners();
          },
          onError: (error) {
            _state = BracketViewState.error;
            _errorMessage = 'Error al cargar matches: $error';
            notifyListeners();
          },
        );
  }

  /// Selecciona un bracket por nombre de categoría.
  void selectCategory(String categoryName) {
    final bracket = _brackets.firstWhere(
      (b) => b.categoryName == categoryName,
      orElse: () => _brackets.first,
    );
    selectBracket(bracket);
  }

  /// Nombre del round según su índice y el total de rounds.
  String roundName(int roundIndex, int totalRounds) {
    final roundsFromEnd = totalRounds - roundIndex;
    return switch (roundsFromEnd) {
      1 => 'Final',
      2 => 'Semifinales',
      3 => 'Cuartos de final',
      4 => 'Octavos de final',
      5 => 'Dieciseisavos',
      _ => 'Ronda ${roundIndex + 1}',
    };
  }

  @override
  void dispose() {
    _bracketsSub?.cancel();
    _matchesSub?.cancel();
    super.dispose();
  }
}
