import '../../../brackets/data/models/app_match.dart';
import '../../../brackets/data/models/bracket_enums.dart';
import 'local_athlete.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LocalMatch  ·  Data Model
//
//  Representa un enfrentamiento en un torneo local.
//  Almacenado completamente en local (shared_preferences / JSON).
//  Refleja la misma estructura que AppMatch pero sin dependencias de Firestore.
// ─────────────────────────────────────────────────────────────────────────────

enum LocalMatchStatus {
  pending,
  completed,
  bye;

  static LocalMatchStatus fromValue(String value) =>
      LocalMatchStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => LocalMatchStatus.pending,
      );

  String get label => switch (this) {
    LocalMatchStatus.pending => 'Pendiente',
    LocalMatchStatus.completed => 'Completado',
    LocalMatchStatus.bye => 'BYE',
  };
}

class LocalMatch {
  const LocalMatch({
    required this.id,
    required this.bracketId,
    required this.round,
    required this.matchOrder,
    required this.status,
    this.athlete1,
    this.athlete2,
    this.winnerId,
    this.loserId,
    this.scoreAthlete1,
    this.scoreAthlete2,
    this.parentMatch1Id,
    this.parentMatch2Id,
    this.childMatchId,
    this.positionInChild,
  });

  final String id;
  final String bracketId;
  final int round;
  final int matchOrder;
  final LocalMatchStatus status;

  final LocalAthlete? athlete1;
  final LocalAthlete? athlete2;

  final String? winnerId;
  final String? loserId;
  final int? scoreAthlete1;
  final int? scoreAthlete2;

  final String? parentMatch1Id;
  final String? parentMatch2Id;
  final String? childMatchId;

  /// Posición (1 o 2) que ocupa el ganador en el match hijo.
  final int? positionInChild;

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool get isReady => athlete1 != null && athlete2 != null;

  bool get isBye => status == LocalMatchStatus.bye;

  bool get isCompleted => status == LocalMatchStatus.completed;

  bool get isFinal => childMatchId == null || childMatchId!.isEmpty;

  LocalAthlete? get winner {
    if (winnerId == null) return null;
    if (athlete1?.id == winnerId) return athlete1;
    if (athlete2?.id == winnerId) return athlete2;
    return null;
  }

  // ── Serialización ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'id': id,
    'bracketId': bracketId,
    'round': round,
    'matchOrder': matchOrder,
    'status': status.name,
    'athlete1': athlete1?.toMap(),
    'athlete2': athlete2?.toMap(),
    'winnerId': winnerId,
    'loserId': loserId,
    'scoreAthlete1': scoreAthlete1,
    'scoreAthlete2': scoreAthlete2,
    'parentMatch1Id': parentMatch1Id,
    'parentMatch2Id': parentMatch2Id,
    'childMatchId': childMatchId,
    'positionInChild': positionInChild,
  };

  factory LocalMatch.fromMap(Map<String, dynamic> map) {
    return LocalMatch(
      id: map['id'] as String? ?? '',
      bracketId: map['bracketId'] as String? ?? '',
      round: (map['round'] as num?)?.toInt() ?? 0,
      matchOrder: (map['matchOrder'] as num?)?.toInt() ?? 0,
      status: LocalMatchStatus.fromValue(map['status'] as String? ?? ''),
      athlete1: map['athlete1'] != null
          ? LocalAthlete.fromMap(
              Map<String, dynamic>.from(map['athlete1'] as Map),
            )
          : null,
      athlete2: map['athlete2'] != null
          ? LocalAthlete.fromMap(
              Map<String, dynamic>.from(map['athlete2'] as Map),
            )
          : null,
      winnerId: map['winnerId'] as String?,
      loserId: map['loserId'] as String?,
      scoreAthlete1: (map['scoreAthlete1'] as num?)?.toInt(),
      scoreAthlete2: (map['scoreAthlete2'] as num?)?.toInt(),
      parentMatch1Id: map['parentMatch1Id'] as String?,
      parentMatch2Id: map['parentMatch2Id'] as String?,
      childMatchId: map['childMatchId'] as String?,
      positionInChild: (map['positionInChild'] as num?)?.toInt(),
    );
  }

  LocalMatch copyWith({
    String? id,
    String? bracketId,
    int? round,
    int? matchOrder,
    LocalMatchStatus? status,
    LocalAthlete? athlete1,
    LocalAthlete? athlete2,
    String? winnerId,
    String? loserId,
    int? scoreAthlete1,
    int? scoreAthlete2,
    String? parentMatch1Id,
    String? parentMatch2Id,
    String? childMatchId,
    int? positionInChild,
    bool clearAthlete1 = false,
    bool clearAthlete2 = false,
    bool clearWinner = false,
    bool clearResult = false,
  }) {
    return LocalMatch(
      id: id ?? this.id,
      bracketId: bracketId ?? this.bracketId,
      round: round ?? this.round,
      matchOrder: matchOrder ?? this.matchOrder,
      status: status ?? this.status,
      athlete1: clearAthlete1 ? null : (athlete1 ?? this.athlete1),
      athlete2: clearAthlete2 ? null : (athlete2 ?? this.athlete2),
      winnerId: (clearWinner || clearResult)
          ? null
          : (winnerId ?? this.winnerId),
      loserId: (clearWinner || clearResult) ? null : (loserId ?? this.loserId),
      scoreAthlete1: clearResult ? null : (scoreAthlete1 ?? this.scoreAthlete1),
      scoreAthlete2: clearResult ? null : (scoreAthlete2 ?? this.scoreAthlete2),
      parentMatch1Id: parentMatch1Id ?? this.parentMatch1Id,
      parentMatch2Id: parentMatch2Id ?? this.parentMatch2Id,
      childMatchId: childMatchId ?? this.childMatchId,
      positionInChild: positionInChild ?? this.positionInChild,
    );
  }

  /// Convierte este [LocalMatch] a [AppMatch] para reutilizar los componentes
  /// visuales existentes del bracket online (BracketBoard, MatchCard, DraggableMatchCard).
  AppMatch toAppMatch() {
    return AppMatch(
      id: id,
      bracketId: bracketId,
      round: round,
      matchOrder: matchOrder,
      status: switch (status) {
        LocalMatchStatus.pending => MatchStatus.pending,
        LocalMatchStatus.completed => MatchStatus.completed,
        LocalMatchStatus.bye => MatchStatus.bye,
      },
      participant1Id: athlete1?.id,
      participant2Id: athlete2?.id,
      participant1Name: athlete1?.name,
      participant2Name: athlete2?.name,
      winnerId: winnerId,
      loserId: loserId,
      scoreParticipant1: scoreAthlete1,
      scoreParticipant2: scoreAthlete2,
      parentMatch1Id: parentMatch1Id,
      parentMatch2Id: parentMatch2Id,
      childMatchId: childMatchId,
      positionInChild: positionInChild,
    );
  }
}
