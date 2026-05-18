import 'package:flutter/foundation.dart';

import '../../data/services/firestore_invitation_service.dart';
import '../../domain/models/invitation_validation_result.dart';
import '../../domain/use_cases/validate_invitation_use_case.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  InvitationController
//
//  ChangeNotifier para la pantalla de aterrizaje de invitación.
//  Valida el token y expone el resultado sellado para que la UI lo refleje.
// ─────────────────────────────────────────────────────────────────────────────

enum InvitationLoadState { loading, success, error }

class InvitationController extends ChangeNotifier {
  InvitationController({
    required this.token,
    ValidateInvitationUseCase? validateUseCase,
  }) : _validateUseCase =
           validateUseCase ??
           ValidateInvitationUseCase(FirestoreInvitationService());

  final String token;
  final ValidateInvitationUseCase _validateUseCase;

  InvitationLoadState _state = InvitationLoadState.loading;
  InvitationValidationResult? _result;

  InvitationLoadState get state => _state;
  InvitationValidationResult? get result => _result;

  /// Valida el token al iniciar la pantalla.
  Future<void> validate() async {
    _state = InvitationLoadState.loading;
    _result = null;
    notifyListeners();

    try {
      _result = await _validateUseCase.execute(token);
      _state = InvitationLoadState.success;
    } catch (e) {
      debugPrint('[InvitationController] validate error: $e');
      _result = const InvitationNotFound();
      _state = InvitationLoadState.error;
    }
    notifyListeners();
  }
}
