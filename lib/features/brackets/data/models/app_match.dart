import 'package:cloud_firestore/cloud_firestore.dart';

import 'bracket_enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AppMatch  ·  Dominio
//
//  Representa un enfrentamiento individual dentro de un bracket.
//  Se persiste como subcolección:
//    brackets/{bracketId}/matches/{matchId}
//
//  Cada match conoce sus padres (parentMatch1Id, parentMatch2Id) y su hijo
//  (childMatchId), formando un árbol binario navegable en ambas direcciones.
//
//  El campo `positionInChild` indica en qué slot (1 o 2) del match hijo
//  se inserta el ganador de este match.
// ─────────────────────────────────────────────────────────────────────────────

class AppMatch {
  const AppMatch({
    required this.id,
    required this.bracketId,
    required this.round,
    required this.matchOrder,
    required this.status,
    this.participant1Id,
    this.participant2Id,
    this.participant1Type,
    this.participant2Type,
    this.participant1Name,
    this.participant2Name,
    this.participant1PhotoUrl,
    this.participant2PhotoUrl,
    this.participant1MemberIds = const [],
    this.participant2MemberIds = const [],
    this.participant1MemberNames = const [],
    this.participant2MemberNames = const [],
    this.winnerId,
    this.loserId,
    this.parentMatch1Id,
    this.parentMatch2Id,
    this.childMatchId,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.scoreParticipant1,
    this.scoreParticipant2,
    this.positionInChild,
    this.categoryId,
  });

  /// ID del documento Firestore.
  final String id;

  /// ID del bracket padre.
  final String bracketId;

  /// Número de round (0 = primera ronda, 1 = segunda, etc.).
  final int round;

  /// Orden del match dentro del round (0-indexed).
  final int matchOrder;

  /// Estado del match.
  final MatchStatus status;

  /// IDs de los participantes (user o team).
  final String? participant1Id;
  final String? participant2Id;

  /// Tipos de los participantes.
  final MatchParticipantType? participant1Type;
  final MatchParticipantType? participant2Type;

  /// Nombres cacheados para visualización rápida sin consultas extra.
  final String? participant1Name;
  final String? participant2Name;

  /// URLs de fotos cacheadas.
  final String? participant1PhotoUrl;
  final String? participant2PhotoUrl;

  /// Miembros cacheados cuando el participante es un equipo.
  final List<String> participant1MemberIds;
  final List<String> participant2MemberIds;
  final List<String> participant1MemberNames;
  final List<String> participant2MemberNames;

  /// ID del ganador y perdedor.
  final String? winnerId;
  final String? loserId;

  /// IDs de los matches padre cuyos ganadores alimentan este match.
  final String? parentMatch1Id;
  final String? parentMatch2Id;

  /// ID del match hijo al que avanza el ganador.
  final String? childMatchId;

  /// Timestamps del match.
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  /// Puntuaciones.
  final int? scoreParticipant1;
  final int? scoreParticipant2;

  /// Posición (1 o 2) que ocupa el ganador en el match hijo.
  final int? positionInChild;

  /// Categoría del torneo (redundante para consultas rápidas).
  final String? categoryId;

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// `true` si el match tiene ambos participantes asignados.
  bool get isReady =>
      participant1Id != null &&
      participant1Id!.isNotEmpty &&
      participant2Id != null &&
      participant2Id!.isNotEmpty;

  /// `true` si es un BYE (solo un participante).
  bool get isBye => status == MatchStatus.bye;

  /// `true` si el match está completado.
  bool get isCompleted => status == MatchStatus.completed;

  /// `true` si es la final (no tiene match hijo).
  bool get isFinal => childMatchId == null || childMatchId!.isEmpty;

  // ── Serialización ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'id': id,
    'bracketId': bracketId,
    'round': round,
    'matchOrder': matchOrder,
    'status': status.name,
    'participant1Id': participant1Id,
    'participant2Id': participant2Id,
    'participant1Type': participant1Type?.name,
    'participant2Type': participant2Type?.name,
    'participant1Name': participant1Name,
    'participant2Name': participant2Name,
    'participant1PhotoUrl': participant1PhotoUrl,
    'participant2PhotoUrl': participant2PhotoUrl,
    'participant1MemberIds': participant1MemberIds,
    'participant2MemberIds': participant2MemberIds,
    'participant1MemberNames': participant1MemberNames,
    'participant2MemberNames': participant2MemberNames,
    'winnerId': winnerId,
    'loserId': loserId,
    'parentMatch1Id': parentMatch1Id,
    'parentMatch2Id': parentMatch2Id,
    'childMatchId': childMatchId,
    'scheduledAt': scheduledAt != null
        ? Timestamp.fromDate(scheduledAt!)
        : null,
    'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
    'completedAt': completedAt != null
        ? Timestamp.fromDate(completedAt!)
        : null,
    'scoreParticipant1': scoreParticipant1,
    'scoreParticipant2': scoreParticipant2,
    'positionInChild': positionInChild,
    'categoryId': categoryId,
  };

  factory AppMatch.fromMap(Map<String, dynamic> map) {
    return AppMatch(
      id: map['id'] as String? ?? '',
      bracketId: map['bracketId'] as String? ?? '',
      round: (map['round'] as num?)?.toInt() ?? 0,
      matchOrder: (map['matchOrder'] as num?)?.toInt() ?? 0,
      status: MatchStatus.fromValue(map['status'] as String? ?? ''),
      participant1Id: map['participant1Id'] as String?,
      participant2Id: map['participant2Id'] as String?,
      participant1Type: map['participant1Type'] != null
          ? MatchParticipantType.fromValue(map['participant1Type'] as String)
          : null,
      participant2Type: map['participant2Type'] != null
          ? MatchParticipantType.fromValue(map['participant2Type'] as String)
          : null,
      participant1Name: map['participant1Name'] as String?,
      participant2Name: map['participant2Name'] as String?,
      participant1PhotoUrl: map['participant1PhotoUrl'] as String?,
      participant2PhotoUrl: map['participant2PhotoUrl'] as String?,
      participant1MemberIds: _stringListFromValue(map['participant1MemberIds']),
      participant2MemberIds: _stringListFromValue(map['participant2MemberIds']),
      participant1MemberNames: _stringListFromValue(
        map['participant1MemberNames'],
      ),
      participant2MemberNames: _stringListFromValue(
        map['participant2MemberNames'],
      ),
      winnerId: map['winnerId'] as String?,
      loserId: map['loserId'] as String?,
      parentMatch1Id: map['parentMatch1Id'] as String?,
      parentMatch2Id: map['parentMatch2Id'] as String?,
      childMatchId: map['childMatchId'] as String?,
      scheduledAt: _nullableDateFromValue(map['scheduledAt']),
      startedAt: _nullableDateFromValue(map['startedAt']),
      completedAt: _nullableDateFromValue(map['completedAt']),
      scoreParticipant1: (map['scoreParticipant1'] as num?)?.toInt(),
      scoreParticipant2: (map['scoreParticipant2'] as num?)?.toInt(),
      positionInChild: (map['positionInChild'] as num?)?.toInt(),
      categoryId: map['categoryId'] as String?,
    );
  }

  // ── Copia con modificaciones ───────────────────────────────────────────────

  AppMatch copyWith({
    String? id,
    String? bracketId,
    int? round,
    int? matchOrder,
    MatchStatus? status,
    String? participant1Id,
    String? participant2Id,
    MatchParticipantType? participant1Type,
    MatchParticipantType? participant2Type,
    String? participant1Name,
    String? participant2Name,
    String? participant1PhotoUrl,
    String? participant2PhotoUrl,
    List<String>? participant1MemberIds,
    List<String>? participant2MemberIds,
    List<String>? participant1MemberNames,
    List<String>? participant2MemberNames,
    String? winnerId,
    String? loserId,
    String? parentMatch1Id,
    String? parentMatch2Id,
    String? childMatchId,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? scoreParticipant1,
    int? scoreParticipant2,
    int? positionInChild,
    String? categoryId,
  }) {
    return AppMatch(
      id: id ?? this.id,
      bracketId: bracketId ?? this.bracketId,
      round: round ?? this.round,
      matchOrder: matchOrder ?? this.matchOrder,
      status: status ?? this.status,
      participant1Id: participant1Id ?? this.participant1Id,
      participant2Id: participant2Id ?? this.participant2Id,
      participant1Type: participant1Type ?? this.participant1Type,
      participant2Type: participant2Type ?? this.participant2Type,
      participant1Name: participant1Name ?? this.participant1Name,
      participant2Name: participant2Name ?? this.participant2Name,
      participant1PhotoUrl: participant1PhotoUrl ?? this.participant1PhotoUrl,
      participant2PhotoUrl: participant2PhotoUrl ?? this.participant2PhotoUrl,
      participant1MemberIds:
          participant1MemberIds ?? this.participant1MemberIds,
      participant2MemberIds:
          participant2MemberIds ?? this.participant2MemberIds,
      participant1MemberNames:
          participant1MemberNames ?? this.participant1MemberNames,
      participant2MemberNames:
          participant2MemberNames ?? this.participant2MemberNames,
      winnerId: winnerId ?? this.winnerId,
      loserId: loserId ?? this.loserId,
      parentMatch1Id: parentMatch1Id ?? this.parentMatch1Id,
      parentMatch2Id: parentMatch2Id ?? this.parentMatch2Id,
      childMatchId: childMatchId ?? this.childMatchId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      scoreParticipant1: scoreParticipant1 ?? this.scoreParticipant1,
      scoreParticipant2: scoreParticipant2 ?? this.scoreParticipant2,
      positionInChild: positionInChild ?? this.positionInChild,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  static DateTime? _nullableDateFromValue(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static List<String> _stringListFromValue(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }
}
