import '../../data/repositories/invitation_repository.dart';
import '../models/invitation_validation_result.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ValidateInvitationUseCase
//
//  Devuelve un resultado sellado; nunca lanza al llamador.
// ─────────────────────────────────────────────────────────────────────────────

class ValidateInvitationUseCase {
  const ValidateInvitationUseCase(this._repository);

  final InvitationRepository _repository;

  Future<InvitationValidationResult> execute(String token) async {
    if (token.trim().isEmpty) return const InvitationNotFound();
    return _repository.validateInvitation(token.trim());
  }
}
