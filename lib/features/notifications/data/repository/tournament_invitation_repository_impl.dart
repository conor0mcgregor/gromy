import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class CloudFunctionTournamentInvitationRepository {
  CloudFunctionTournamentInvitationRepository({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(
            app: Firebase.app(),
            region: 'us-central1',
          );

  final FirebaseFunctions _functions;
  static const _createCallable = 'createTournamentInvitation';

  Future<String> sendInvitation({
    required String tournamentId,
    required String invitedUserId,
  }) async {
    try {
      final result = await _functions.httpsCallable(_createCallable).call({
        'tournamentId': tournamentId,
        'invitedUserId': invitedUserId,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return data['notificationId']?.toString() ?? '';
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        '[TournamentInvitationRepository] $_createCallable failed '
        'code=${e.code} message=${e.message}',
      );
      throw _mapFunctionsException(e);
    }
  }

  Future<void> acceptInvitation({required String notificationId}) async {
    try {
      await _functions.httpsCallable('acceptTournamentInvitation').call({
        'notificationId': notificationId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw _mapFunctionsException(e);
    }
  }

  Future<void> rejectInvitation({required String notificationId}) async {
    try {
      await _functions.httpsCallable('rejectTournamentInvitation').call({
        'notificationId': notificationId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw _mapFunctionsException(e);
    }
  }

  Exception _mapFunctionsException(FirebaseFunctionsException e) {
    final rawMessage = (e.message ?? '').trim();
    final message = switch (e.code) {
      'unauthenticated' => 'Debes iniciar sesión para invitar jugadores.',
      'permission-denied' =>
        'No tienes permiso para invitar jugadores a este torneo.',
      'not-found' => _mapNotFoundMessage(rawMessage),
      'already-exists' => _mapAlreadyExistsMessage(rawMessage),
      'failed-precondition' =>
        rawMessage.isNotEmpty
            ? rawMessage
            : 'No se puede enviar la invitación en este momento.',
      'invalid-argument' =>
        rawMessage.isNotEmpty ? rawMessage : 'Datos de invitación no válidos.',
      _ =>
        rawMessage.isNotEmpty
            ? rawMessage
            : 'No se pudo enviar la invitación. Inténtalo de nuevo.',
    };
    return Exception(message);
  }

  String _mapAlreadyExistsMessage(String rawMessage) {
    final lower = rawMessage.toLowerCase();
    if (lower.contains('inscrito')) {
      return 'Este jugador ya está inscrito en el torneo.';
    }
    if (lower.contains('invitacion pendiente') ||
        lower.contains('invitación pendiente')) {
      return 'Ya has invitado a este jugador.';
    }
    if (lower.contains('solicitud pendiente')) {
      return 'Este jugador ya tiene una solicitud de inscripción pendiente.';
    }
    return rawMessage.isNotEmpty
        ? rawMessage
        : 'No se puede invitar a este jugador.';
  }

  String _mapNotFoundMessage(String rawMessage) {
    final normalized = rawMessage.toLowerCase();
    if (normalized.contains('torneo')) {
      return 'No se encontró el torneo.';
    }
    if (normalized.contains('usuario')) {
      return 'No se encontró el jugador.';
    }
    return rawMessage.isNotEmpty
        ? rawMessage
        : 'No se encontró el recurso solicitado.';
  }
}
