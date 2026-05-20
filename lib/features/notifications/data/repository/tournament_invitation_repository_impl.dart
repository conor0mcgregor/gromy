import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

class CloudFunctionTournamentInvitationRepository {
  CloudFunctionTournamentInvitationRepository({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(
            app: Firebase.app(),
            region: 'us-central1',
          );

  final FirebaseFunctions _functions;

  Future<String> sendInvitation({
    required String tournamentId,
    required String invitedUserId,
  }) async {
    final result = await _functions
        .httpsCallable('createTournamentInvitation')
        .call({'tournamentId': tournamentId, 'invitedUserId': invitedUserId});
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['notificationId']?.toString() ?? '';
  }

  Future<void> acceptInvitation({required String notificationId}) async {
    await _functions.httpsCallable('acceptTournamentInvitation').call({
      'notificationId': notificationId,
    });
  }

  Future<void> rejectInvitation({required String notificationId}) async {
    await _functions.httpsCallable('rejectTournamentInvitation').call({
      'notificationId': notificationId,
    });
  }
}
