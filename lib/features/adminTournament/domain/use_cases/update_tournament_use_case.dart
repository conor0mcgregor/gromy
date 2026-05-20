import '../../../../core/models/registration_form.dart';
import '../../../tournament/data/model/app_tournament.dart';
import '../../data/repositories/admin_tournament_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  UpdateTournamentUseCase  ·  Dominio
//
//  SRP: única responsabilidad → actualizar los datos del torneo.
//  Validaciones previas antes de persistir.
// ─────────────────────────────────────────────────────────────────────────────

class UpdateTournamentUseCase {
  const UpdateTournamentUseCase(this._repository);

  final AdminTournamentRepository _repository;

  /// Ejecuta la actualización del torneo.
  ///
  /// [updated] debe tener un ID válido. Si cambian los administradores,
  /// solo el creador puede guardar esa modificación.
  Future<void> execute({
    required AppTournament original,
    required AppTournament updated,
    required String callerUid,
  }) async {
    if (updated.id.isEmpty) {
      throw ArgumentError('El torneo debe tener un ID válido.');
    }
    if (updated.name.trim().isEmpty) {
      throw ArgumentError('El nombre del torneo no puede estar vacío.');
    }

    final registrationFormErrors = RegistrationFormValidator.validateSchema(
      updated.registrationForm,
    );
    if (registrationFormErrors.isNotEmpty) {
      throw ArgumentError(registrationFormErrors.first);
    }

    if (_listChanged(original.adminIds, updated.adminIds) &&
        callerUid != original.organizerUid) {
      throw Exception(
        'Solo el creador del torneo puede gestionar administradores.',
      );
    }

    final withTimestamp = updated.copyWith(updatedAt: DateTime.now());
    await _repository.updateTournament(
      original: original,
      updated: withTimestamp,
    );
  }

  bool _listChanged(List<String> a, List<String> b) {
    if (a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }
}
