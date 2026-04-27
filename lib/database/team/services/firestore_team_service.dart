import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_team.dart';
import '../repositories/team_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FirestoreTeamService  ·  Capa de datos
//
//  Implementa [TeamRepository] usando la colección raíz `teams`.
//
//  Decisión de diseño:
//  - Colección raíz (no subcolección de torneo) → un equipo es una entidad
//    independiente que puede participar en varios torneos. Evita duplicar el
//    estado del equipo por cada torneo.
//  - Las consultas por miembro usan `array-contains` para eficiencia.
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreTeamService implements TeamRepository {
  FirestoreTeamService({FirebaseFirestore? firestore})
      : _db = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'gromy-db',
            );

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _teams =>
      _db.collection('teams');

  // ── TeamRepository impl ────────────────────────────────────────────────────

  @override
  Future<AppTeam> createTeam(AppTeam team) async {
    final docRef = team.id.isEmpty ? _teams.doc() : _teams.doc(team.id);
    final teamToSave = team.copyWith(id: docRef.id);

    await docRef
        .set(teamToSave.toMap())
        .timeout(const Duration(seconds: 10));

    return teamToSave;
  }

  @override
  Future<void> updateTeam(AppTeam team) async {
    await _teams
        .doc(team.id)
        .set(team.toMap())
        .timeout(const Duration(seconds: 10));
  }

  @override
  Future<AppTeam?> getTeam(String teamId) async {
    final doc = await _teams
        .doc(teamId)
        .get()
        .timeout(const Duration(seconds: 10));

    if (!doc.exists) return null;
    return AppTeam.fromMap(doc.data()!);
  }

  @override
  Stream<List<AppTeam>> watchTeamsByCreator(String creatorId) {
    return _teams
        .where('creatorId', isEqualTo: creatorId)
        .snapshots()
        .map(_mapSnapshotToTeams);
  }

  @override
  Stream<List<AppTeam>> watchTeamsByMember(String userId) {
    return _teams
        .where('members', arrayContains: userId)
        .snapshots()
        .map(_mapSnapshotToTeams);
  }

  @override
  Future<void> addMember({
    required String teamId,
    required String userId,
  }) async {
    await _teams.doc(teamId).update({
      'members': FieldValue.arrayUnion([userId]),
    }).timeout(const Duration(seconds: 10));
  }

  @override
  Future<void> removeMember({
    required String teamId,
    required String userId,
  }) async {
    await _teams.doc(teamId).update({
      'members': FieldValue.arrayRemove([userId]),
    }).timeout(const Duration(seconds: 10));
  }

  @override
  Future<void> addAdmin({
    required String teamId,
    required String userId,
  }) async {
    await _teams.doc(teamId).update({
      'adminIds': FieldValue.arrayUnion([userId]),
    }).timeout(const Duration(seconds: 10));
  }

  @override
  Future<void> removeAdmin({
    required String teamId,
    required String userId,
  }) async {
    await _teams.doc(teamId).update({
      'adminIds': FieldValue.arrayRemove([userId]),
    }).timeout(const Duration(seconds: 10));
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    await _teams
        .doc(teamId)
        .delete()
        .timeout(const Duration(seconds: 10));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<AppTeam> _mapSnapshotToTeams(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final list = <AppTeam>[];
    for (final doc in snapshot.docs) {
      try {
        list.add(AppTeam.fromMap(doc.data()));
      } catch (e) {
        // ignore: avoid_print
        print('Error mapeando equipo: $e');
      }
    }
    return list;
  }
}
