import 'package:flutter/foundation.dart';

import '../../data/repository/admin_invitation_repository_impl.dart';
import '../../domain/entities/admin_invitation.dart';
import '../../domain/repositories/admin_invitation_repository.dart';
import '../../domain/use_cases/admin_invitation_use_cases.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AdminInvitationController  ·  Estado y lógica de presentación
//
//  Orquesta el ciclo de vida de una invitación de administrador.
//  Expone estado reactivo para la UI mediante ChangeNotifier.
//
//  SRP: solo gestiona la lógica de UI para invitaciones de admin.
//  DIP: depende de abstracciones de dominio.
// ─────────────────────────────────────────────────────────────────────────────

enum InvitationAction { accepting, rejecting, idle }

class AdminInvitationController extends ChangeNotifier {
  AdminInvitationController({AdminInvitationRepository? repository})
    : _repository = repository;

  AdminInvitationRepository? _repository;
  bool _useCasesReady = false;

  late final AcceptAdminInvitationUseCase _accept;
  late final RejectAdminInvitationUseCase _reject;
  late final CancelAdminInvitationUseCase _cancel;
  late final SendAdminInvitationUseCase _send;

  void _ensureUseCases() {
    if (_useCasesReady) return;
    final repo = _repository ??= CloudFunctionAdminInvitationRepository();
    _accept = AcceptAdminInvitationUseCase(repo);
    _reject = RejectAdminInvitationUseCase(repo);
    _cancel = CancelAdminInvitationUseCase(repo);
    _send = SendAdminInvitationUseCase(repo);
    _useCasesReady = true;
  }

  // ── Estado reactivo ────────────────────────────────────────────────────────

  InvitationAction _action = InvitationAction.idle;
  InvitationAction get action => _action;

  bool get isBusy => _action != InvitationAction.idle;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  // ── Acciones ───────────────────────────────────────────────────────────────

  /// Acepta la invitación con el [notificationId] dado.
  ///
  /// Retorna `true` si tuvo éxito.
  Future<bool> acceptInvitation(String notificationId) async {
    return _executeAction(
      action: InvitationAction.accepting,
      operation: () => _accept(notificationId: notificationId),
      successMessage: '¡Ahora eres administrador del torneo!',
    );
  }

  /// Rechaza la invitación con el [notificationId] dado.
  ///
  /// Retorna `true` si tuvo éxito.
  Future<bool> rejectInvitation(String notificationId) async {
    return _executeAction(
      action: InvitationAction.rejecting,
      operation: () => _reject(notificationId: notificationId),
      successMessage: 'Invitación rechazada.',
    );
  }

  /// Cancela una invitación pendiente (solo el creador del torneo).
  ///
  /// Retorna `true` si tuvo éxito.
  Future<bool> cancelInvitation(String notificationId) async {
    return _executeAction(
      action: InvitationAction.idle,
      operation: () => _cancel(notificationId: notificationId),
      successMessage: 'Invitación cancelada.',
    );
  }

  /// Envía una invitación a un usuario para administrar un torneo.
  ///
  /// [tournamentId] ID del torneo.
  /// [invitedUserId] UID del usuario invitado.
  ///
  /// Retorna `true` si tuvo éxito.
  Future<bool> sendInvitation({
    required String tournamentId,
    required String invitedUserId,
  }) async {
    return _executeAction(
      action: InvitationAction.idle,
      operation: () =>
          _send(tournamentId: tournamentId, invitedUserId: invitedUserId),
      successMessage: 'Invitación enviada correctamente.',
    );
  }

  // ── Helper privado ─────────────────────────────────────────────────────────

  Future<bool> _executeAction({
    required InvitationAction action,
    required Future<void> Function() operation,
    required String successMessage,
  }) async {
    _ensureUseCases();
    _action = action;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await operation();
      _successMessage = successMessage;
      _action = InvitationAction.idle;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _action = InvitationAction.idle;
      notifyListeners();
      debugPrint('AdminInvitationController error: $e');
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}

/// Extensión utilitaria para obtener la invitación de admin desde una notificación.
extension AdminInvitationFromNotificationData on Map<String, dynamic> {
  AdminInvitation toAdminInvitation(String notificationId) {
    return AdminInvitation.fromNotificationData(
      notificationId: notificationId,
      data: this,
    );
  }
}
