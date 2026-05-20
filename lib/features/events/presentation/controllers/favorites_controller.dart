import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../../tournament/data/model/app_tournament.dart';
import '../../data/repositories/favorite_repository.dart';
import '../../data/services/firestore_favorite_service.dart';

class FavoritesController {
  FavoritesController({
    FavoriteRepository? favoriteRepository,
    FirebaseAuth? auth,
  }) : _favoriteRepository = favoriteRepository,
       _authOverride = auth;

  final FavoriteRepository? _favoriteRepository;
  final FirebaseAuth? _authOverride;

  FavoriteRepository get _repository =>
      _favoriteRepository ?? FirestoreFavoriteService();

  FirebaseAuth? get _authSafe {
    if (_authOverride != null) return _authOverride;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  String? get currentUid {
    try {
      return _authSafe?.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Future<void> toggleFavorite(String tournamentId) async {
    final uid = currentUid;
    if (uid == null) {
      throw Exception('Usuario no autenticado');
    }
    await _repository.toggleFavorite(uid: uid, tournamentId: tournamentId);
  }

  Stream<bool> isFavorite(String tournamentId) {
    final uid = currentUid;
    if (uid == null) return Stream.value(false);
    try {
      return _repository.isFavorite(uid, tournamentId);
    } catch (e) {
      return Stream<bool>.error(e);
    }
  }

  Stream<List<AppTournament>> watchFavoriteTournaments() {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();
    try {
      return _repository.watchFavoriteTournaments(uid);
    } catch (e) {
      return Stream<List<AppTournament>>.error(e);
    }
  }
}
