import 'package:flutter/foundation.dart';

import '../../data/repository/team_invitation_repository_impl.dart';
import '../../domain/entities/team_invitation.dart';
import '../../domain/repositories/team_invitation_repository.dart';
import '../../domain/use_cases/team_invitation_use_cases.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TeamInvitationController  ·  Estado y lógica de presentación
//
//  Orquesta el ciclo de vida de una invitación de equipo.
//  Espeja el patrón de AdminInvitationController.
//
//  SRP: solo gestiona la lógica de UI para invitaciones de equipo.
//  DIP: depende de abstracciones de dominio.
// ─────────────────────────────────────────────────────────────────────────────

enum TeamInvitationAction { accepting, rejecting, idle }

class TeamInvitationController extends ChangeNotifier {
  TeamInvitationController({
    TeamInvitationRepository? repository,
  }) {
    final repo = repository ?? CloudFunctionTeamInvitationRepository();
    _accept = AcceptTeamInvitationUseCase(repo);
    _reject = RejectTeamInvitationUseCase(repo);
    _cancel = CancelTeamInvitationUseCase(repo);
    _send = SendTeamInvitationUseCase(repo);
  }

  late final AcceptTeamInvitationUseCase _accept;
  late final RejectTeamInvitationUseCase _reject;
  late final CancelTeamInvitationUseCase _cancel;
  late final SendTeamInvitationUseCase _send;

  // ── Estado reactivo ────────────────────────────────────────────────────────

  TeamInvitationAction _action = TeamInvitationAction.idle;
  TeamInvitationAction get action => _action;

  bool get isBusy => _action != TeamInvitationAction.idle;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  // ── Acciones ───────────────────────────────────────────────────────────────

  /// Acepta la invitación con el [notificationId] dado.
  Future<bool> acceptInvitation(String notificationId) async {
    return _executeAction(
      action: TeamInvitationAction.accepting,
      operation: () => _accept(notificationId: notificationId),
      successMessage: '¡Ahora eres miembro del equipo!',
    );
  }

  /// Rechaza la invitación con el [notificationId] dado.
  Future<bool> rejectInvitation(String notificationId) async {
    return _executeAction(
      action: TeamInvitationAction.rejecting,
      operation: () => _reject(notificationId: notificationId),
      successMessage: 'Invitación rechazada.',
    );
  }

  /// Cancela una invitación pendiente (solo admins del equipo).
  Future<bool> cancelInvitation(String notificationId) async {
    return _executeAction(
      action: TeamInvitationAction.idle,
      operation: () => _cancel(notificationId: notificationId),
      successMessage: 'Invitación cancelada.',
    );
  }

  /// Envía una invitación a un usuario para unirse a un equipo.
  ///
  /// Devuelve el [notificationId] creado, o null si falla.
  Future<String?> sendInvitation({
    required String teamId,
    required String invitedUserId,
  }) async {
    _action = TeamInvitationAction.idle;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final notificationId = await _send(
        teamId: teamId,
        invitedUserId: invitedUserId,
      );
      _successMessage = 'Invitación enviada correctamente.';
      notifyListeners();
      return notificationId;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      debugPrint('TeamInvitationController.sendInvitation error: $e');
      return null;
    }
  }

  // ── Helper privado ─────────────────────────────────────────────────────────

  Future<bool> _executeAction({
    required TeamInvitationAction action,
    required Future<void> Function() operation,
    required String successMessage,
  }) async {
    _action = action;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await operation();
      _successMessage = successMessage;
      _action = TeamInvitationAction.idle;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _action = TeamInvitationAction.idle;
      notifyListeners();
      debugPrint('TeamInvitationController error: $e');
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}

/// Extensión utilitaria para construir TeamInvitation desde los datos.
extension TeamInvitationFromNotificationData on Map<String, dynamic> {
  TeamInvitation toTeamInvitation(String notificationId) {
    return TeamInvitation.fromNotificationData(
      notificationId: notificationId,
      data: this,
    );
  }
}
