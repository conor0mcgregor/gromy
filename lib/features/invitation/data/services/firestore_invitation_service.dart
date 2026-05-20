import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../tournament/data/model/app_tournament.dart';
import '../../../tournament/data/model/enums_tournament.dart';
import '../../domain/models/invitation_validation_result.dart';
import '../models/app_invitation.dart';
import '../repositories/invitation_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FirestoreInvitationService  ·  Implementación de [InvitationRepository]
//
//  Colección Firestore: `tournamentInvitations`
//  El ID del documento (UUID automático de Firestore) actúa como token seguro.
//
//  Usa la instancia `gromy-db`, igual que [FirestoreTournamentService].
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreInvitationService implements InvitationRepository {
  FirestoreInvitationService({FirebaseFirestore? firestore})
      : _db = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'gromy-db',
            );

  final FirebaseFirestore _db;

  static const _kDefaultExpirationDays = 30;

  CollectionReference<Map<String, dynamic>> get _invitations =>
      _db.collection('tournamentInvitations');

  CollectionReference<Map<String, dynamic>> get _privateTournaments =>
      _db.collection('private_tournaments');

  // ── Creación ───────────────────────────────────────────────────────────────

  @override
  Future<AppInvitation> createInvitation({
    required String tournamentId,
    required String createdByUid,
  }) async {
    final docRef = _invitations.doc(); // UUID auto-generated = token seguro
    final now = DateTime.now();
    final invitation = AppInvitation(
      id: docRef.id,
      tournamentId: tournamentId,
      createdByUid: createdByUid,
      createdAt: now,
      expiresAt: now.add(const Duration(days: _kDefaultExpirationDays)),
    );

    await docRef
        .set(invitation.toMap())
        .timeout(const Duration(seconds: 10));

    return invitation;
  }

  // ── Lectura ────────────────────────────────────────────────────────────────

  @override
  Future<AppInvitation?> getInvitationByToken(String token) async {
    try {
      final doc = await _invitations
          .doc(token)
          .get()
          .timeout(const Duration(seconds: 10));
      if (!doc.exists || doc.data() == null) return null;
      return AppInvitation.fromMap(doc.data()!);
    } catch (e) {
      developer.log(
        '[FirestoreInvitationService] getInvitationByToken error: $e',
      );
      return null;
    }
  }

  // ── Validación ─────────────────────────────────────────────────────────────

  @override
  Future<InvitationValidationResult> validateInvitation(String token) async {
    try {
      // 1. Existe la invitación?
      final invitation = await getInvitationByToken(token);
      if (invitation == null) return const InvitationNotFound();

      // 2. Está revocada?
      if (invitation.revoked) return const InvitationRevoked();

      // 3. Ha expirado?
      if (invitation.isExpired) return const InvitationExpired();

      // 4. Existe el torneo privado?
      final tournamentDoc = await _privateTournaments
          .doc(invitation.tournamentId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!tournamentDoc.exists || tournamentDoc.data() == null) {
        return const InvitationTournamentNotFound();
      }

      AppTournament tournament;
      try {
        tournament = AppTournament.fromMap(tournamentDoc.data()!);
      } catch (e) {
        return const InvitationTournamentNotFound();
      }

      // 5. Confirmar que es realmente un torneo privado
      if (tournament.accessType != TournamentAccessType.privateInviteOnly) {
        return const InvitationTournamentNotFound();
      }

      // 6. Está lleno el torneo?
      if (tournament.participantCount >= tournament.maxParticipants) {
        return InvitationTournamentFull(tournament: tournament);
      }

      return InvitationValid(invitation: invitation, tournament: tournament);
    } catch (e) {
      // Cualquier error inesperado se trata como token inválido/no encontrado
      developer.log('[FirestoreInvitationService] validateInvitation error: $e');
      return const InvitationNotFound();
    }
  }

  // ── Revocación ────────────────────────────────────────────────────────────

  @override
  Future<void> revokeInvitation(String invitationId) async {
    await _invitations
        .doc(invitationId)
        .update({'revoked': true})
        .timeout(const Duration(seconds: 10));
  }
}
