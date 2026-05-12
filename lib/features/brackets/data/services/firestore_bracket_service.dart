import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_bracket.dart';
import '../models/app_match.dart';
import '../repositories/bracket_repository.dart';
import 'cloud_function_bracket_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FirestoreBracketService  ·  Capa de datos
//
//  Implementa [BracketRepository] usando Firestore como backend.
//
//  SRP: delega las operaciones de Cloud Functions en
//       [CloudFunctionBracketService].
//  DIP: depende de abstracciones cuando es viable.
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreBracketService implements BracketRepository {
  FirestoreBracketService({
    FirebaseFirestore? firestore,
    CloudFunctionBracketService? cloudFunctionService,
  }) : _db =
           firestore ??
           FirebaseFirestore.instanceFor(
             app: Firebase.app(),
             databaseId: 'gromy-db',
           ),
       _cfService = cloudFunctionService ?? CloudFunctionBracketService();

  final FirebaseFirestore _db;
  final CloudFunctionBracketService _cfService;

  CollectionReference<Map<String, dynamic>> get _brackets =>
      _db.collection('brackets');

  CollectionReference<Map<String, dynamic>> _matches(String bracketId) =>
      _brackets.doc(bracketId).collection('matches');

  // ── Brackets ──────────────────────────────────────────────────────────────

  @override
  Stream<List<AppBracket>> watchBrackets(String tournamentId) {
    return _brackets
        .where('tournamentId', isEqualTo: tournamentId)
        .snapshots()
        .map((snapshot) {
          final list = <AppBracket>[];
          for (final doc in snapshot.docs) {
            try {
              list.add(AppBracket.fromMap(doc.data()));
            } catch (e) {
              // ignore: avoid_print
              print('Error mapeando bracket: $e');
            }
          }
          return list;
        });
  }

  @override
  Future<AppBracket?> getBracket(String bracketId) async {
    final doc = await _brackets.doc(bracketId).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppBracket.fromMap(doc.data()!);
  }

  @override
  Stream<AppBracket?> watchBracket(String bracketId) {
    return _brackets.doc(bracketId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppBracket.fromMap(doc.data()!);
    });
  }

  // ── Matches ───────────────────────────────────────────────────────────────

  @override
  Stream<List<AppMatch>> watchMatches(String bracketId) {
    return _matches(
      bracketId,
    ).orderBy('round').orderBy('matchOrder').snapshots().map((snapshot) {
      final list = <AppMatch>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(AppMatch.fromMap(doc.data()));
        } catch (e) {
          // ignore: avoid_print
          print('Error mapeando match: $e');
        }
      }
      return list;
    });
  }

  @override
  Future<List<AppMatch>> getMatches(String bracketId) async {
    final snapshot = await _matches(
      bracketId,
    ).orderBy('round').orderBy('matchOrder').get();
    final list = <AppMatch>[];
    for (final doc in snapshot.docs) {
      try {
        list.add(AppMatch.fromMap(doc.data()));
      } catch (e) {
        // ignore: avoid_print
        print('Error mapeando match: $e');
      }
    }
    return list;
  }

  @override
  Future<void> updateMatchResult({
    required String bracketId,
    required String matchId,
    required String winnerId,
    required String loserId,
    required int scoreParticipant1,
    required int scoreParticipant2,
  }) async {
    await _cfService.recordMatchResult(
      bracketId: bracketId,
      matchId: matchId,
      winnerId: winnerId,
      loserId: loserId,
      scoreParticipant1: scoreParticipant1,
      scoreParticipant2: scoreParticipant2,
    );
  }

  @override
  Future<void> updateMatchSchedule({
    required String bracketId,
    required String matchId,
    required DateTime scheduledAt,
  }) async {
    await _cfService.updateMatchSchedule(
      bracketId: bracketId,
      matchId: matchId,
      scheduledAt: scheduledAt,
    );
  }

  @override
  Future<void> swapParticipants({
    required String bracketId,
    required String matchId1,
    required int slotInMatch1,
    required String matchId2,
    required int slotInMatch2,
  }) async {
    await _cfService.swapMatchParticipants(
      bracketId: bracketId,
      matchId1: matchId1,
      slotInMatch1: slotInMatch1,
      matchId2: matchId2,
      slotInMatch2: slotInMatch2,
    );
  }

  // ── Cloud Functions (delegadas) ───────────────────────────────────────────

  @override
  Future<AppBracket> generateBracket({
    required String tournamentId,
    String? categoryId,
  }) {
    return _cfService.generateBracket(
      tournamentId: tournamentId,
      categoryId: categoryId,
    );
  }

  @override
  Future<void> publishBracket({required String bracketId}) {
    return _cfService.publishBracket(bracketId: bracketId);
  }

  @override
  Future<AppBracket> regenerateBracket({required String bracketId}) {
    return _cfService.regenerateBracket(bracketId: bracketId);
  }
}
