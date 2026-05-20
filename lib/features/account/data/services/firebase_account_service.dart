import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/account_deletion_state.dart';
import '../repositories/account_repository.dart';

class FirebaseAccountService implements AccountRepository {
  FirebaseAccountService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db =
           firestore ??
           FirebaseFirestore.instanceFor(
             app: Firebase.app(),
             databaseId: 'gromy-db',
           ),
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  static const _deletedDisplayName = 'Usuario eliminado';
  static const _deletedNickname = 'usuario_eliminado';

  @override
  Future<AccountDeletionState> getDeletionState(String userId) async {
    if (_auth.currentUser?.uid != userId) {
      return AccountDeletionState(
        userId: userId,
        canDelete: false,
        blockingReasons: const [
          AccountDeletionBlockingReason(
            code: AccountDeletionBlockingCode.unauthenticated,
            message: 'No hay una sesion activa para eliminar esta cuenta.',
            action: 'Vuelve a iniciar sesion antes de continuar.',
          ),
        ],
        hasActiveTournaments: false,
        hasActivePayments: false,
        isSoleOrganizer: false,
        isTeamOwner: false,
        checkedAt: DateTime.now(),
      );
    }

    final reasons = <AccountDeletionBlockingReason>[];
    final now = DateTime.now();
    final tournamentChecks = await Future.wait([
      _soleOrganizerReasons('tournaments', userId, now),
      _soleOrganizerReasons('private_tournaments', userId, now),
    ]);
    for (final list in tournamentChecks) {
      reasons.addAll(list);
    }

    final teamReasons = await _soleTeamOwnerReasons(userId);
    reasons.addAll(teamReasons);

    final hasActivePayments = await _hasActivePayments(userId);
    if (hasActivePayments) {
      reasons.add(
        const AccountDeletionBlockingReason(
          code: AccountDeletionBlockingCode.activePayments,
          message: 'No puedes eliminar tu cuenta porque hay pagos en curso.',
          action: 'Espera a que los pagos finalicen o contacta con soporte.',
        ),
      );
    }

    final hasCriticalProcesses = await _hasCriticalProcesses(userId);
    if (hasCriticalProcesses) {
      reasons.add(
        const AccountDeletionBlockingReason(
          code: AccountDeletionBlockingCode.criticalProcesses,
          message:
              'No puedes eliminar tu cuenta porque hay procesos criticos pendientes.',
          action: 'Completa o cancela esos procesos antes de continuar.',
        ),
      );
    }

    return AccountDeletionState(
      userId: userId,
      canDelete: reasons.isEmpty,
      blockingReasons: reasons,
      hasActiveTournaments: tournamentChecks.any((list) => list.isNotEmpty),
      hasActivePayments: hasActivePayments,
      isSoleOrganizer: tournamentChecks.any((list) => list.isNotEmpty),
      isTeamOwner: teamReasons.isNotEmpty,
      checkedAt: DateTime.now(),
    );
  }

  @override
  Future<void> anonymizeUserAccount(String userId) async {
    final userRef = _db.collection('users').doc(userId);
    final userDoc = await userRef.get().timeout(const Duration(seconds: 10));
    if (!userDoc.exists) {
      throw StateError('No existe el documento de usuario.');
    }

    final queryResults = await Future.wait([
      _db
          .collection('users')
          .doc(userId)
          .collection('fcm_tokens')
          .get()
          .timeout(const Duration(seconds: 10)),
      _db
          .collection('tournaments')
          .where('organizerUid', isEqualTo: userId)
          .get()
          .timeout(const Duration(seconds: 10)),
      _db
          .collection('private_tournaments')
          .where('organizerUid', isEqualTo: userId)
          .get()
          .timeout(const Duration(seconds: 10)),
      _db
          .collection('teams')
          .where('members', arrayContains: userId)
          .get()
          .timeout(const Duration(seconds: 10)),
      _db
          .collection('teams')
          .where('adminIds', arrayContains: userId)
          .get()
          .timeout(const Duration(seconds: 10)),
    ]);

    final tokenDocs = queryResults[0].docs;
    final tournamentDocs = [...queryResults[1].docs, ...queryResults[2].docs];
    final teamDocs = {
      for (final doc in [...queryResults[3].docs, ...queryResults[4].docs])
        doc.id: doc,
    }.values;

    final batch = _db.batch();
    batch.set(userRef, {
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'displayName': _deletedDisplayName,
      'nickname': _deletedNickname,
      'name': 'Usuario',
      'lastName': 'eliminado',
      'email': null,
      'photoUrl': null,
      'biography': null,
      'phone': null,
      'phoneNumber': null,
      'fcmToken': FieldValue.delete(),
      'fcmTokens': FieldValue.delete(),
      'notificationTokens': FieldValue.delete(),
      'personalDataRemoved': true,
    }, SetOptions(merge: true));

    batch.set(_db.collection('account_deletions').doc(userId), {
      'userId': userId,
      'deletedAt': FieldValue.serverTimestamp(),
      'strategy': 'logical_deletion_anonymization',
      'personalDataRemoved': true,
    }, SetOptions(merge: true));

    for (final doc in tokenDocs) {
      batch.delete(doc.reference);
    }

    for (final doc in tournamentDocs) {
      batch.update(doc.reference, {
        'organizerDisplayName': _deletedDisplayName,
        'organizerEmail': null,
        'contactEmail': null,
        'contactPhone': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    for (final doc in teamDocs) {
      batch.update(doc.reference, {
        'members': FieldValue.arrayRemove([userId]),
        'adminIds': FieldValue.arrayRemove([userId]),
      });
    }

    await batch.commit().timeout(const Duration(seconds: 10));
  }

  @override
  Future<void> removePersonalStorage(String userId) async {
    final refs = [_storage.ref('profile_images/$userId.jpg')];

    for (final ref in refs) {
      try {
        await ref.delete();
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') rethrow;
      }
    }
  }

  @override
  Future<void> revokeAuthAccess() async {
    await _auth.signOut();
  }

  Future<List<AccountDeletionBlockingReason>> _soleOrganizerReasons(
    String collection,
    String userId,
    DateTime now,
  ) async {
    final snapshot = await _db
        .collection(collection)
        .where('organizerUid', isEqualTo: userId)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .get()
        .timeout(const Duration(seconds: 10));

    final reasons = <AccountDeletionBlockingReason>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final adminIds = (data['adminIds'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toSet();
      final hasOtherResponsible = adminIds.any((uid) => uid != userId);
      if (!hasOtherResponsible) {
        final name = data['name'] as String? ?? 'un torneo activo';
        reasons.add(
          AccountDeletionBlockingReason(
            code: AccountDeletionBlockingCode.soleTournamentOrganizer,
            message:
                'No puedes eliminar tu cuenta porque eres el unico organizador de "$name".',
            action: 'Transfiere la organizacion antes de continuar.',
          ),
        );
      }
    }

    return reasons;
  }

  Future<List<AccountDeletionBlockingReason>> _soleTeamOwnerReasons(
    String userId,
  ) async {
    final snapshots = await Future.wait([
      _db
          .collection('teams')
          .where('adminIds', arrayContains: userId)
          .get()
          .timeout(const Duration(seconds: 10)),
      _db
          .collection('teams')
          .where('creatorId', isEqualTo: userId)
          .get()
          .timeout(const Duration(seconds: 10)),
    ]);

    final reasons = <AccountDeletionBlockingReason>[];
    final docs = {
      for (final snapshot in snapshots)
        for (final doc in snapshot.docs) doc.id: doc,
    }.values;

    for (final doc in docs) {
      final data = doc.data();
      final adminIds = (data['adminIds'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toSet();
      final creatorId = data['creatorId'] as String? ?? '';
      if (adminIds.isEmpty && creatorId.isNotEmpty) {
        adminIds.add(creatorId);
      }

      final hasOtherResponsible = adminIds.any((uid) => uid != userId);
      if (!hasOtherResponsible) {
        final name = data['name'] as String? ?? 'un equipo activo';
        reasons.add(
          AccountDeletionBlockingReason(
            code: AccountDeletionBlockingCode.soleTeamOwner,
            message:
                'No puedes eliminar tu cuenta porque eres el unico responsable de "$name".',
            action: 'Asigna otro administrador del equipo antes de continuar.',
          ),
        );
      }
    }

    return reasons;
  }

  Future<bool> _hasActivePayments(String userId) async {
    return _hasPendingDocument(
      collection: 'payments',
      userId: userId,
      statuses: const ['pending', 'processing', 'in_progress'],
    );
  }

  Future<bool> _hasCriticalProcesses(String userId) async {
    return _hasPendingDocument(
      collection: 'critical_processes',
      userId: userId,
      statuses: const ['pending', 'processing', 'open'],
    );
  }

  Future<bool> _hasPendingDocument({
    required String collection,
    required String userId,
    required List<String> statuses,
  }) async {
    final snapshot = await _db
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: statuses)
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 10));
    return snapshot.docs.isNotEmpty;
  }
}
