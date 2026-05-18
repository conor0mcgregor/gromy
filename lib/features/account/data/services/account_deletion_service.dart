import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/models/account_deletion_state.dart';
import '../repositories/account_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AccountDeletionService  ·  Capa de datos
//
//  Estrategia: Desactivación lógica + anonimización de datos personales.
//  - No elimina documentos necesarios para trazabilidad.
//  - Anonimiza datos personales (nombre, email, foto).
//  - Elimina foto de perfil en Storage.
//  - Deshabilita acceso Auth.
// ─────────────────────────────────────────────────────────────────────────────

class AccountDeletionService implements AccountRepository {
  AccountDeletionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _db = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'gromy-db',
            ),
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  @override
  Future<AccountDeletionState> checkDeletionEligibility(String userId) async {
    final reasons = <String>[];
    bool isSoleOrganizer = false;
    bool isTeamOwner = false;
    bool hasActiveTournaments = false;

    // 1. Verificar si es organizador único de torneo activo.
    final tournamentsSnapshot = await _db
        .collection('tournaments')
        .where('organizerUid', isEqualTo: userId)
        .get()
        .timeout(const Duration(seconds: 10));

    for (final doc in tournamentsSnapshot.docs) {
      final data = doc.data();
      final scheduledAt = data['scheduledAt'];
      DateTime? date;
      if (scheduledAt is Timestamp) date = scheduledAt.toDate();

      // Torneo aún no realizado.
      if (date != null && date.isAfter(DateTime.now())) {
        hasActiveTournaments = true;
        final adminIds = (data['adminIds'] as List<dynamic>?) ?? [];
        if (adminIds.length <= 1) {
          isSoleOrganizer = true;
          reasons.add(
            'Eres el único organizador del torneo "${data['name']}". '
            'Transfiere la organización antes de continuar.',
          );
        }
      }
    }

    // 2. Verificar si es el único admin de un equipo activo.
    final teamsSnapshot = await _db
        .collection('teams')
        .where('adminIds', arrayContains: userId)
        .get()
        .timeout(const Duration(seconds: 10));

    for (final doc in teamsSnapshot.docs) {
      final data = doc.data();
      final adminIds = (data['adminIds'] as List<dynamic>?) ?? [];
      if (adminIds.length <= 1) {
        isTeamOwner = true;
        reasons.add(
          'Eres el único administrador del equipo "${data['name']}". '
          'Transfiere la administración antes de continuar.',
        );
      }
    }

    return AccountDeletionState(
      userId: userId,
      canDelete: reasons.isEmpty,
      blockingReasons: reasons,
      hasActiveTournaments: hasActiveTournaments,
      isSoleOrganizer: isSoleOrganizer,
      isTeamOwner: isTeamOwner,
      checkedAt: DateTime.now(),
    );
  }

  @override
  Future<void> executeAccountDeletion(String userId) async {
    // 1. Verificar elegibilidad una vez más.
    final state = await checkDeletionEligibility(userId);
    if (!state.canDelete) {
      throw Exception(
        'No se puede eliminar la cuenta: ${state.blockingReasons.join('; ')}',
      );
    }

    // 2. Obtener datos del usuario para saber si tiene foto.
    final userDoc = await _db
        .collection('users')
        .doc(userId)
        .get()
        .timeout(const Duration(seconds: 10));

    if (userDoc.exists) {
      final photoUrl = userDoc.data()?['photoUrl'] as String?;

      // 3. Eliminar foto de perfil en Storage si existe.
      if (photoUrl != null && photoUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(photoUrl).delete();
        } catch (_) {
          // Si falla la eliminación de la foto, continuar igualmente.
        }
      }

      // 4. Anonimizar datos del usuario en Firestore.
      await _db.collection('users').doc(userId).update({
        'isDeleted': true,
        'deletedAt': Timestamp.fromDate(DateTime.now()),
        'name': 'Usuario eliminado',
        'lastName': '',
        'nickname': 'usuario_eliminado_${userId.substring(0, 8)}',
        'email': FieldValue.delete(),
        'photoUrl': FieldValue.delete(),
        'personalDataRemoved': true,
      }).timeout(const Duration(seconds: 10));
    }

    // 5. Cancelar inscripciones individuales activas en torneos futuros.
    // (Las participaciones pasadas se mantienen anonimizadas)
    final tournamentsSnapshot = await _db
        .collection('tournaments')
        .where('scheduledAt', isGreaterThan: Timestamp.now())
        .get()
        .timeout(const Duration(seconds: 10));

    for (final tournamentDoc in tournamentsSnapshot.docs) {
      final participants = await _db
          .collection('tournaments')
          .doc(tournamentDoc.id)
          .collection('participants')
          .where('entityId', isEqualTo: userId)
          .where('entityType', isEqualTo: 'user')
          .get()
          .timeout(const Duration(seconds: 10));

      for (final participant in participants.docs) {
        await participant.reference.delete();
        // Decrementar contador.
        await _db.collection('tournaments').doc(tournamentDoc.id).update({
          'participantCount': FieldValue.increment(-1),
        });
      }
    }

    // 6. Eliminar notificaciones del usuario.
    final notifications = await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .get()
        .timeout(const Duration(seconds: 10));

    final batch = _db.batch();
    for (final doc in notifications.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // 7. Eliminar cuenta de Firebase Auth.
    try {
      final user = _auth.currentUser;
      if (user != null && user.uid == userId) {
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Es necesario reautenticarse antes de eliminar la cuenta.',
        );
      }
      rethrow;
    }
  }
}
