import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../data/models/app_invitation.dart';
import '../../data/services/firestore_invitation_service.dart';
import '../../domain/use_cases/create_invitation_use_case.dart';
import '../../domain/use_cases/revoke_invitation_use_case.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  GenerateInvitationController
//
//  ChangeNotifier que gestiona la generación y revocación de un enlace de
//  invitación dentro de la pantalla de gestión del torneo.
//
//  No expone errores internos de Firestore: los mapea a mensajes de usuario.
// ─────────────────────────────────────────────────────────────────────────────

/// Esquema de invitación con custom scheme mobile.
///
/// Formato: https://gromy-ps.firebaseapp.com/invite/{token}
///
/// Para probar: adb shell am start -a android.intent.action.VIEW -d "https://gromy-ps.firebaseapp.com/invite/{token}"
const String kInvitationBaseUrl = 'https://gromy-ps.firebaseapp.com/invite';

class GenerateInvitationController extends ChangeNotifier {
  GenerateInvitationController({
    required this.tournamentId,
    required this.organizerUid,
    CreateInvitationUseCase? createUseCase,
    RevokeInvitationUseCase? revokeUseCase,
  })  : _createUseCase =
            createUseCase ??
            CreateInvitationUseCase(FirestoreInvitationService()),
        _revokeUseCase =
            revokeUseCase ??
            RevokeInvitationUseCase(FirestoreInvitationService());

  final String tournamentId;
  final String organizerUid;

  final CreateInvitationUseCase _createUseCase;
  final RevokeInvitationUseCase _revokeUseCase;

  bool _isGenerating = false;
  bool _isRevoking = false;
  AppInvitation? _currentInvitation;
  String? _errorMessage;
  bool _copiedToClipboard = false;

  bool get isGenerating => _isGenerating;
  bool get isRevoking => _isRevoking;
  bool get isBusy => _isGenerating || _isRevoking;
  AppInvitation? get currentInvitation => _currentInvitation;
  String? get errorMessage => _errorMessage;
  bool get copiedToClipboard => _copiedToClipboard;

  bool get hasLink => _currentInvitation != null;

  String get invitationLink =>
      _currentInvitation != null
          ? '$kInvitationBaseUrl/${_currentInvitation!.id}'
          : '';

  // ── Generar enlace ─────────────────────────────────────────────────────────

  Future<void> generateLink() async {
    _isGenerating = true;
    _errorMessage = null;
    _copiedToClipboard = false;
    notifyListeners();

    try {
      _currentInvitation = await _createUseCase.execute(
        tournamentId: tournamentId,
        requestingUid: organizerUid,
      );
    } catch (e) {
      debugPrint('[GenerateInvitationController] generateLink error: $e');
      _errorMessage = 'No se pudo generar el enlace. Inténtalo de nuevo.';
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // ── Copiar al portapapeles ─────────────────────────────────────────────────

  Future<void> copyLinkToClipboard() async {
    if (!hasLink) return;

    await Clipboard.setData(ClipboardData(text: invitationLink));
    _copiedToClipboard = true;
    notifyListeners();

    // Restablecer el indicador de "copiado" tras 2 segundos
    await Future<void>.delayed(const Duration(seconds: 2));
    if (_copiedToClipboard) {
      _copiedToClipboard = false;
      notifyListeners();
    }
  }

  // ── Revocar enlace ─────────────────────────────────────────────────────────

  Future<bool> revokeLink() async {
    if (_currentInvitation == null) return false;

    _isRevoking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _revokeUseCase.execute(_currentInvitation!.id);
      _currentInvitation = null;
      return true;
    } catch (e) {
      debugPrint('[GenerateInvitationController] revokeLink error: $e');
      _errorMessage = 'No se pudo revocar el enlace. Inténtalo de nuevo.';
      return false;
    } finally {
      _isRevoking = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
