import 'package:cloud_firestore/cloud_firestore.dart';

import 'bracket_enums.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AppBracket  ·  Dominio
//
//  Representa el bracket principal de un torneo (o de una categoría).
//  Se persiste en:  brackets/{bracketId}
//
//  Un torneo puede tener múltiples brackets si tiene categorías.
//  Los matches se almacenan como subcolección independiente:
//    brackets/{bracketId}/matches/{matchId}
// ─────────────────────────────────────────────────────────────────────────────

class AppBracket {
  const AppBracket({
    required this.id,
    required this.tournamentId,
    required this.status,
    required this.format,
    required this.totalRounds,
    required this.totalMatches,
    required this.participantCount,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.categoryName,
    this.publishedAt,
    this.completedAt,
    this.tournamentName,
  });

  /// ID del documento Firestore.
  final String id;

  /// ID del torneo padre.
  final String tournamentId;

  /// Estado actual del bracket.
  final BracketStatus status;

  /// Formato del bracket (single elimination, etc.).
  final BracketFormat format;

  /// Número total de rounds calculados.
  final int totalRounds;

  /// Número total de matches generados.
  final int totalMatches;

  /// Número de participantes incluidos en este bracket.
  final int participantCount;

  /// Categoría del torneo (null si el torneo no tiene categorías).
  final String? categoryId;

  /// Nombre legible de la categoría.
  final String? categoryName;

  /// Nombre del torneo (para notificaciones y visualización).
  final String? tournamentName;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Fecha de publicación (null si aún no se ha publicado).
  final DateTime? publishedAt;

  /// Fecha de completado (null si aún no se ha completado).
  final DateTime? completedAt;

  // ── Serialización ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'id': id,
    'tournamentId': tournamentId,
    'status': status.name,
    'format': format.name,
    'totalRounds': totalRounds,
    'totalMatches': totalMatches,
    'participantCount': participantCount,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'tournamentName': tournamentName,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'publishedAt': publishedAt != null
        ? Timestamp.fromDate(publishedAt!)
        : null,
    'completedAt': completedAt != null
        ? Timestamp.fromDate(completedAt!)
        : null,
  };

  factory AppBracket.fromMap(Map<String, dynamic> map) {
    return AppBracket(
      id: map['id'] as String? ?? '',
      tournamentId: map['tournamentId'] as String? ?? '',
      status: BracketStatus.fromValue(map['status'] as String? ?? ''),
      format: BracketFormat.fromValue(map['format'] as String? ?? ''),
      totalRounds: (map['totalRounds'] as num?)?.toInt() ?? 0,
      totalMatches: (map['totalMatches'] as num?)?.toInt() ?? 0,
      participantCount: (map['participantCount'] as num?)?.toInt() ?? 0,
      categoryId: map['categoryId'] as String?,
      categoryName: map['categoryName'] as String?,
      tournamentName: map['tournamentName'] as String?,
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
      publishedAt: _nullableDateFromValue(map['publishedAt']),
      completedAt: _nullableDateFromValue(map['completedAt']),
    );
  }

  // ── Copia con modificaciones ───────────────────────────────────────────────

  AppBracket copyWith({
    String? id,
    String? tournamentId,
    BracketStatus? status,
    BracketFormat? format,
    int? totalRounds,
    int? totalMatches,
    int? participantCount,
    String? categoryId,
    String? categoryName,
    String? tournamentName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    DateTime? completedAt,
  }) {
    return AppBracket(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      status: status ?? this.status,
      format: format ?? this.format,
      totalRounds: totalRounds ?? this.totalRounds,
      totalMatches: totalMatches ?? this.totalMatches,
      participantCount: participantCount ?? this.participantCount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      tournamentName: tournamentName ?? this.tournamentName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _nullableDateFromValue(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
