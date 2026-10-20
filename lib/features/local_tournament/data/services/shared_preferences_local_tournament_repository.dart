import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_tournament.dart';
import '../repositories/local_tournament_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SharedPreferencesLocalTournamentRepository
//
//  Implementación de LocalTournamentRepository usando SharedPreferences.
//  Los torneos se serializan como JSON y se almacenan bajo una clave única.
//
//  Estrategia de almacenamiento:
//    - Clave de índice: 'local_tournaments_index' → List<String> de IDs
//    - Clave por torneo: 'local_tournament_{id}' → JSON del torneo
//
//  Esto permite operaciones eficientes de lectura individual y listado
//  sin cargar todos los datos en memoria a la vez.
// ─────────────────────────────────────────────────────────────────────────────

class SharedPreferencesLocalTournamentRepository
    implements LocalTournamentRepository {
  static const _indexKey = 'local_tournaments_index';
  static const _prefix = 'local_tournament_';

  @override
  Future<List<LocalTournament>> getAllTournaments() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_indexKey) ?? [];
    final tournaments = <LocalTournament>[];
    for (final id in ids) {
      final json = prefs.getString('$_prefix$id');
      if (json != null) {
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          tournaments.add(LocalTournament.fromMap(map));
        } catch (_) {
          // Registro corrupto: se ignora
        }
      }
    }
    // Ordenar por fecha de actualización descendente
    tournaments.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return tournaments;
  }

  @override
  Future<LocalTournament?> getTournamentById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_prefix$id');
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return LocalTournament.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveTournament(LocalTournament tournament) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_indexKey) ?? [];
    if (!ids.contains(tournament.id)) {
      ids.add(tournament.id);
      await prefs.setStringList(_indexKey, ids);
    }
    final json = jsonEncode(tournament.toMap());
    await prefs.setString('$_prefix${tournament.id}', json);
  }

  @override
  Future<void> deleteTournament(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_indexKey) ?? [];
    ids.remove(id);
    await prefs.setStringList(_indexKey, ids);
    await prefs.remove('$_prefix$id');
  }
}
