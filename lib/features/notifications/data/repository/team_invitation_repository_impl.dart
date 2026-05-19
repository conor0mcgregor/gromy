import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../user/data/models/app_user.dart';
import '../../domain/entities/admin_invitation.dart';
import '../../domain/entities/pending_team_invitation.dart';
import '../../domain/repositories/team_invitation_repository.dart';

class CloudFunctionTeamInvitationRepository
    implements TeamInvitationRepository {
  static const String _createCallable = 'createTeamInvitation';
  static const String _acceptCallable = 'acceptTeamInvitation';
  static const String _rejectCallable = 'rejectTeamInvitation';
  static const String _cancelCallable = 'cancelTeamInvitation';

  CloudFunctionTeamInvitationRepository({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
  }) : _functions = functions ?? FirebaseFunctions.instance,
       _firestore =
           firestore ??
           FirebaseFirestore.instanceFor(
             app: Firebase.app(),
             databaseId: 'gromy-db',
           );

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<String> sendInvitation({
    required String teamId,
    required String invitedUserId,
  }) async {
    try {
      debugPrint(
        '[TeamInvitationRepository] Calling $_createCallable '
        'with teamId=$teamId invitedUserId=$invitedUserId',
      );
      final result = await _functions.httpsCallable(_createCallable).call({
        'teamId': teamId,
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
        '[TeamInvitationRepository] $_createCallable failed '
        'code=${e.code} message=${e.message}',
      );
      throw _mapFunctionsException(e, operation: _createCallable);
    }
  }

  @override
  Stream<List<PendingTeamInvitation>> watchPendingInvitations({
    required String teamId,
  }) {
    return _notifications
        .where('data.teamId', isEqualTo: teamId)
        .snapshots()
        .asyncMap((snapshot) async {
          final pendingDocs = snapshot.docs
              .where((doc) {
                final data = doc.data();
                final invitationData = Map<String, dynamic>.from(
                  data['data'] as Map? ?? const {},
                );
                return data['type'] == 'team_invitation' &&
                    InvitationStatus.fromString(
                          invitationData['status']?.toString(),
                        ) ==
                        InvitationStatus.pending;
              })
              .toList(growable: false);

          final invitations = await Future.wait(
            pendingDocs.map((doc) async {
              final data = doc.data();
              final invitationData = Map<String, dynamic>.from(
                data['data'] as Map? ?? const {},
              );
              final userId = data['userId']?.toString() ?? '';
              final user = await _loadUser(userId);
              final fullName = user == null
                  ? ''
                  : '${user.name} ${user.lastName}'.trim();
              final displayName = fullName.isNotEmpty
                  ? fullName
                  : user?.nickname ?? userId;

              return PendingTeamInvitation(
                notificationId: doc.id,
                teamId: invitationData['teamId']?.toString() ?? teamId,
                userId: userId,
                nickname: user?.nickname ?? userId,
                displayName: displayName,
                photoUrl: user?.photoUrl,
                status: InvitationStatus.fromString(
                  invitationData['status']?.toString(),
                ),
                invitedAt: _parseMillis(invitationData['invitedAt']),
              );
            }),
          );

          final sorted = invitations.toList(growable: false)
            ..sort((a, b) {
              final aMillis = a.invitedAt?.millisecondsSinceEpoch ?? 0;
              final bMillis = b.invitedAt?.millisecondsSinceEpoch ?? 0;
              return bMillis.compareTo(aMillis);
            });
          return sorted;
        });
  }

  @override
  Future<void> acceptInvitation({required String notificationId}) async {
    try {
      debugPrint(
        '[TeamInvitationRepository] Calling $_acceptCallable '
        'with notificationId=$notificationId',
      );
      await _functions.httpsCallable(_acceptCallable).call({
        'notificationId': notificationId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw _mapFunctionsException(e, operation: _acceptCallable);
    }
  }

  @override
  Future<void> rejectInvitation({required String notificationId}) async {
    try {
      debugPrint(
        '[TeamInvitationRepository] Calling $_rejectCallable '
        'with notificationId=$notificationId',
      );
      await _functions.httpsCallable(_rejectCallable).call({
        'notificationId': notificationId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw _mapFunctionsException(e, operation: _rejectCallable);
    }
  }

  @override
  Future<void> cancelInvitation({required String notificationId}) async {
    try {
      debugPrint(
        '[TeamInvitationRepository] Calling $_cancelCallable '
        'with notificationId=$notificationId',
      );
      await _functions.httpsCallable(_cancelCallable).call({
        'notificationId': notificationId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw _mapFunctionsException(e, operation: _cancelCallable);
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
      'already-exists' =>
        rawMessage.isNotEmpty
            ? rawMessage
            : 'La invitacion ya existe o el usuario ya es miembro.',
      'failed-precondition' =>
        rawMessage.isNotEmpty ? rawMessage : 'La invitacion ya fue respondida.',
      'deadline-exceeded' => 'La invitacion ha expirado.',
      'invalid-argument' =>
        rawMessage.isNotEmpty ? rawMessage : 'Parametros incorrectos.',
      _ =>
        rawMessage.isNotEmpty
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

  Future<AppUser?> _loadUser(String userId) async {
    if (userId.isEmpty) return null;
    final doc = await _users.doc(userId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return AppUser.fromMap(data);
  }

  DateTime? _parseMillis(dynamic value) {
    final millis = int.tryParse(value?.toString() ?? '');
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
}
