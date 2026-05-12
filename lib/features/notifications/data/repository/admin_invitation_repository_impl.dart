import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../domain/repositories/admin_invitation_repository.dart';

// Implementacion de datos para invitaciones de administrador.
//
// La logica sensible vive en Cloud Functions. Este repositorio solo
// encapsula el acceso a los callables y traduce errores de infraestructura
// a mensajes legibles para la capa superior.
class CloudFunctionAdminInvitationRepository
    implements AdminInvitationRepository {
  static const String _createInvitationCallable = 'createAdminInvitation';
  static const String _acceptInvitationCallable = 'acceptAdminInvitation';
  static const String _rejectInvitationCallable = 'rejectAdminInvitation';
  static const String _cancelInvitationCallable = 'cancelAdminInvitation';

  CloudFunctionAdminInvitationRepository({
    FirebaseFunctions? functions,
  }) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  @override
  Future<String> sendInvitation({
    required String tournamentId,
    required String invitedUserId,
  }) async {
    try {
      debugPrint(
        '[AdminInvitationRepository] Calling $_createInvitationCallable '
        'with tournamentId=$tournamentId invitedUserId=$invitedUserId',
      );
      final result = await _functions.httpsCallable(_createInvitationCallable).call({
        'tournamentId': tournamentId,
        'invitedUserId': invitedUserId,
      });
      final data = Map<String, dynamic>.from(
        (result.data as Map?)?.cast<String, dynamic>() ?? const {},
      );
      final notificationId = data['notificationId']?.toString() ?? '';
      if (notificationId.isEmpty) {
        throw Exception(
          'La Cloud Function no devolvio un notificationId valido.',
        );
      }
      return notificationId;
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        '[AdminInvitationRepository] $_createInvitationCallable failed '
        'code=${e.code} message=${e.message} details=${e.details}',
      );
      throw _mapFunctionsException(e, operation: _createInvitationCallable);
    }
  }

  @override
  Future<void> acceptInvitation({required String notificationId}) async {
    try {
      debugPrint(
        '[AdminInvitationRepository] Calling $_acceptInvitationCallable '
        'with notificationId=$notificationId',
      );
      await _functions.httpsCallable(_acceptInvitationCallable).call({
        'notificationId': notificationId,
      });
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        '[AdminInvitationRepository] $_acceptInvitationCallable failed '
        'code=${e.code} message=${e.message} details=${e.details}',
      );
      throw _mapFunctionsException(e, operation: _acceptInvitationCallable);
    }
  }

  @override
  Future<void> rejectInvitation({required String notificationId}) async {
    try {
      debugPrint(
        '[AdminInvitationRepository] Calling $_rejectInvitationCallable '
        'with notificationId=$notificationId',
      );
      await _functions.httpsCallable(_rejectInvitationCallable).call({
        'notificationId': notificationId,
      });
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        '[AdminInvitationRepository] $_rejectInvitationCallable failed '
        'code=${e.code} message=${e.message} details=${e.details}',
      );
      throw _mapFunctionsException(e, operation: _rejectInvitationCallable);
    }
  }

  @override
  Future<void> cancelInvitation({required String notificationId}) async {
    try {
      debugPrint(
        '[AdminInvitationRepository] Calling $_cancelInvitationCallable '
        'with notificationId=$notificationId',
      );
      await _functions.httpsCallable(_cancelInvitationCallable).call({
        'notificationId': notificationId,
      });
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        '[AdminInvitationRepository] $_cancelInvitationCallable failed '
        'code=${e.code} message=${e.message} details=${e.details}',
      );
      throw _mapFunctionsException(e, operation: _cancelInvitationCallable);
    }
  }

  Exception _mapFunctionsException(
    FirebaseFunctionsException e, {
    required String operation,
  }) {
    final rawMessage = (e.message ?? '').trim();
    final message = switch (e.code) {
      'unauthenticated' => 'Debes iniciar sesion para realizar esta accion.',
      'permission-denied' => 'No tienes permiso para realizar esta accion.',
      'not-found' => _mapNotFoundMessage(
        rawMessage: rawMessage,
        operation: operation,
      ),
      'already-exists' => rawMessage.isNotEmpty
          ? rawMessage
          : 'La invitacion ya existe o el usuario ya es administrador.',
      'failed-precondition' => rawMessage.isNotEmpty
          ? rawMessage
          : 'La invitacion ya fue respondida.',
      'deadline-exceeded' => 'La invitacion ha expirado.',
      'invalid-argument' => rawMessage.isNotEmpty
          ? rawMessage
          : 'Parametros incorrectos.',
      _ => rawMessage.isNotEmpty
          ? rawMessage
          : 'Ha ocurrido un error. Intentalo de nuevo.',
    };
    return Exception(message);
  }

  String _mapNotFoundMessage({
    required String rawMessage,
    required String operation,
  }) {
    final normalized = rawMessage.toLowerCase();
    final backendUnavailable =
        rawMessage.isEmpty ||
        normalized == 'not found' ||
        normalized.contains('function was not found') ||
        normalized.contains('requested entity was not found');

    if (backendUnavailable) {
      return 'La operacion $operation no esta disponible en el backend. '
          'Compila y despliega las Cloud Functions antes de usar invitaciones.';
    }

    return rawMessage;
  }
}
