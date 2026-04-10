import 'package:image_picker/image_picker.dart';

import '../model/app_tournament.dart';

/// Contrato de acceso a datos para torneos.
///
/// OCP: se extiende con nuevos métodos sin modificar los existentes ni romper
/// implementaciones anteriores.
abstract interface class TournamentRepository {
  /// Crea un torneo sin imagen de portada.
  Future<AppTournament> createTournament(AppTournament tournament);

  /// Crea un torneo subiendo primero [coverImage] a Storage y obteniendo su
  /// URL para asignarla al campo `portadaUrl` antes de persistir en Firestore.
  ///
  /// El [tournament] debe tener `id` vacío; el repositorio generará el ID.
  Future<AppTournament> createTournamentWithCover({
    required AppTournament tournament,
    required XFile coverImage,
  });

  /// Devuelve un stream en tiempo real con todos los torneos.
  Stream<List<AppTournament>> watchTournaments();

  /// Devuelve un stream con los torneos en los que [uid] es creador.
  Stream<List<AppTournament>> watchMyTournaments(String uid);

  /// Devuelve un stream con los torneos en los que [uid] es administrador.
  Stream<List<AppTournament>> watchTournamentsAdmin(String uid);
}
