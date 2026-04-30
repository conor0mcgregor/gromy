import '../../data/repositories/admin_tournament_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ManageAdminsUseCase  ·  Dominio
//
//  SRP: gestionar la lista de administradores de un torneo.
//  Restricciones:
//    - Solo el creador puede añadir/eliminar admins.
//    - No se permite eliminar al creador de adminIds.
// ─────────────────────────────────────────────────────────────────────────────

class ManageAdminsUseCase {
  const ManageAdminsUseCase(this._repository);

  final AdminTournamentRepository _repository;

  /// Añade un administrador al torneo.
  ///
  /// [callerUid] — UID del usuario que ejecuta la acción.
  /// [creatorUid] — UID del creador del torneo.
  /// Lanza [Exception] si el llamante no es el creador.
  Future<void> addAdmin({
    required String tournamentId,
    required String adminUid,
    required String callerUid,
    required String creatorUid,
  }) async {
    _assertIsCreator(callerUid, creatorUid);

    if (adminUid.isEmpty) {
      throw ArgumentError('El UID del administrador no puede estar vacío.');
    }

    await _repository.addAdmin(
      tournamentId: tournamentId,
      adminUid: adminUid,
    );
  }

  /// Elimina un administrador del torneo.
  ///
  /// No permite eliminar al creador de la lista.
  Future<void> removeAdmin({
    required String tournamentId,
    required String adminUid,
    required String callerUid,
    required String creatorUid,
  }) async {
    _assertIsCreator(callerUid, creatorUid);

    if (adminUid == creatorUid) {
      throw Exception('No se puede eliminar al creador de la lista de administradores.');
    }

    await _repository.removeAdmin(
      tournamentId: tournamentId,
      adminUid: adminUid,
    );
  }

  void _assertIsCreator(String callerUid, String creatorUid) {
    if (callerUid != creatorUid) {
      throw Exception('Solo el creador del torneo puede gestionar administradores.');
    }
  }
}
