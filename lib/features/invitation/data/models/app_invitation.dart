import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AppInvitation  ·  Modelo de enlace de invitación para torneos privados
//
//  El documento ID de Firestore actúa como token seguro (UUID generado por
//  Firestore, no predecible). No se expone ningún campo interno sensible en la
//  UI.
// ─────────────────────────────────────────────────────────────────────────────

class AppInvitation {
  const AppInvitation({
    required this.id,
    required this.tournamentId,
    required this.createdByUid,
    required this.createdAt,
    required this.expiresAt,
    this.revoked = false,
    this.maxUses,
    this.usedCount = 0,
  });

  /// Token de invitación (= document ID en Firestore, UUID seguro).
  final String id;

  /// ID del torneo privado asociado.
  final String tournamentId;

  /// UID del organizador que generó el enlace.
  final String createdByUid;

  /// Fecha de creación.
  final DateTime createdAt;

  /// Fecha de expiración (30 días desde creación por defecto).
  final DateTime expiresAt;

  /// Si el organizador ha revocado manualmente esta invitación.
  final bool revoked;

  /// Límite de usos. Si es null, el enlace es de uso ilimitado.
  final int? maxUses;

  /// Número de veces que se ha usado el enlace para acceder al torneo.
  final int usedCount;

  // ── Computed helpers ──────────────────────────────────────────────────────

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isActive => !revoked && !isExpired;

  bool get hasReachedMaxUses =>
      maxUses != null && usedCount >= maxUses!;

  // ── Serialización ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'createdByUid': createdByUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'revoked': revoked,
      'maxUses': maxUses,
      'usedCount': usedCount,
    };
  }

  factory AppInvitation.fromMap(Map<String, dynamic> map) {
    return AppInvitation(
      id: map['id'] as String? ?? '',
      tournamentId: map['tournamentId'] as String? ?? '',
      createdByUid: map['createdByUid'] as String? ?? '',
      createdAt: _dateFromValue(map['createdAt']),
      expiresAt: _dateFromValue(map['expiresAt']),
      revoked: map['revoked'] as bool? ?? false,
      maxUses: (map['maxUses'] as num?)?.toInt(),
      usedCount: (map['usedCount'] as num?)?.toInt() ?? 0,
    );
  }

  AppInvitation copyWith({
    String? id,
    String? tournamentId,
    String? createdByUid,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? revoked,
    int? maxUses,
    int? usedCount,
  }) {
    return AppInvitation(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      createdByUid: createdByUid ?? this.createdByUid,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      revoked: revoked ?? this.revoked,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
    );
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
