import 'package:cloud_functions/cloud_functions.dart';

import '../models/app_bracket.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CloudFunctionBracketService  ·  Capa de datos
//
//  Encapsula las llamadas a Cloud Functions para operaciones críticas
//  de brackets que requieren validación server-side:
//    - Generación automática del bracket
//    - Publicación
//    - Regeneración
//
//  SRP: solo se encarga de la comunicación con Cloud Functions.
// ─────────────────────────────────────────────────────────────────────────────

class CloudFunctionBracketService {
  CloudFunctionBracketService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Genera un bracket completo para el torneo (o categoría).
  ///
  /// La Cloud Function:
  ///   1. Lee participantes del torneo
  ///   2. Calcula rounds y BYEs
  ///   3. Crea el documento bracket y todos los matches
  ///   4. Devuelve el bracket generado
  Future<AppBracket> generateBracket({
    required String tournamentId,
    String? categoryId,
  }) async {
    final callable = _functions.httpsCallable('generateBracket');
    final payload = <String, dynamic>{
      'tournamentId': tournamentId,
    };
    if (categoryId != null) {
      payload['categoryId'] = categoryId;
    }

    final result = await callable.call<Map<String, dynamic>>(payload);

    return AppBracket.fromMap(Map<String, dynamic>.from(result.data));
  }

  /// Publica un bracket (cambia status de draft → published).
  ///
  /// La Cloud Function:
  ///   1. Valida integridad del árbol
  ///   2. Cambia status a published
  ///   3. Envía notificaciones a participantes
  Future<void> publishBracket({required String bracketId}) async {
    final callable = _functions.httpsCallable('publishBracket');
    await callable.call<Map<String, dynamic>>({'bracketId': bracketId});
  }

  /// Regenera un bracket existente en estado draft.
  ///
  /// La Cloud Function:
  ///   1. Verifica que el bracket esté en draft
  ///   2. Elimina todos los matches existentes
  ///   3. Regenera el bracket completo
  ///   4. Devuelve el nuevo bracket
  Future<AppBracket> regenerateBracket({required String bracketId}) async {
    final callable = _functions.httpsCallable('regenerateBracket');
    final result = await callable.call<Map<String, dynamic>>({
      'bracketId': bracketId,
    });

    return AppBracket.fromMap(Map<String, dynamic>.from(result.data));
  }

  /// Registra un resultado desde backend. La Function valida permisos,
  /// participantes y estado antes de escribir el match.
  Future<void> recordMatchResult({
    required String bracketId,
    required String matchId,
    required String winnerId,
    required String loserId,
    required int scoreParticipant1,
    required int scoreParticipant2,
  }) async {
    final callable = _functions.httpsCallable('recordMatchResult');
    await callable.call<Map<String, dynamic>>({
      'bracketId': bracketId,
      'matchId': matchId,
      'winnerId': winnerId,
      'loserId': loserId,
      'scoreParticipant1': scoreParticipant1,
      'scoreParticipant2': scoreParticipant2,
    });
  }

  /// Actualiza el horario de un match mediante Cloud Function.
  Future<void> updateMatchSchedule({
    required String bracketId,
    required String matchId,
    required DateTime scheduledAt,
  }) async {
    final callable = _functions.httpsCallable('updateMatchSchedule');
    await callable.call<Map<String, dynamic>>({
      'bracketId': bracketId,
      'matchId': matchId,
      'scheduledAtMillis': scheduledAt.millisecondsSinceEpoch,
    });
  }

  /// Intercambia participantes entre dos slots en modo draft.
  Future<void> swapMatchParticipants({
    required String bracketId,
    required String matchId1,
    required int slotInMatch1,
    required String matchId2,
    required int slotInMatch2,
  }) async {
    final callable = _functions.httpsCallable('swapMatchParticipants');
    await callable.call<Map<String, dynamic>>({
      'bracketId': bracketId,
      'matchId1': matchId1,
      'slotInMatch1': slotInMatch1,
      'matchId2': matchId2,
      'slotInMatch2': slotInMatch2,
    });
  }
}
