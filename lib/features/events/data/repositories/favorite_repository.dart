import '../../../tournament/data/model/app_tournament.dart';

/// Contrato para la gestión de torneos favoritos.
abstract interface class FavoriteRepository {
  /// Agrega o elimina un torneo de la lista de favoritos del usuario.
  Future<void> toggleFavorite({
    required String uid,
    required String tournamentId,
  });

  /// Devuelve un stream que emite true si el torneo es favorito.
  Stream<bool> isFavorite(String uid, String tournamentId);

  /// Devuelve un stream con los torneos favoritos del usuario.
  Stream<List<AppTournament>> watchFavoriteTournaments(String uid);
}
