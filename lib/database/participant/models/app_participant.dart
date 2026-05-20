import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/models/registration_form.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AppParticipant  ·  Dominio
//
//  Representa la inscripción de un usuario o equipo a un torneo.
//  Se persiste como subcolección:
//    tournaments/{tournamentId}/participants/{participantId}
//
//  No contiene datos duplicados del usuario/equipo: sólo referencias por ID.
//  El tipo polimórfico (user|team) se codifica con [ParticipantEntityType].
// ─────────────────────────────────────────────────────────────────────────────

enum ParticipantEntityType {
  user,
  team;

  static ParticipantEntityType fromValue(String value) {
    return ParticipantEntityType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ParticipantEntityType.user,
    );
  }
}

enum ParticipantStatus {
  active,
  pending,
  approved,
  pendingReview,
  cancelled,
  rejected;

  String get firestoreValue {
    return switch (this) {
      ParticipantStatus.pendingReview => 'pending_review',
      _ => name,
    };
  }

  static ParticipantStatus fromValue(String value) {
    if (value == 'pending_review') return ParticipantStatus.pendingReview;
    return ParticipantStatus.values.firstWhere(
      (e) => e.name == value || e.firestoreValue == value,
      orElse: () => ParticipantStatus.pending,
    );
  }
}

class AppParticipant {
  const AppParticipant({
    required this.id,
    required this.tournamentId,
    required this.entityId,
    required this.entityType,
    required this.enrolledAt,
    required this.status,
    this.categoryId,
    this.registrationFormVersion = 1,
    this.registrationResponses = const [],
    this.notes,
    this.complementaryInfo,
    this.updatedAt,
    this.approvedBy,
    this.requiresReview = false,
    this.reviewStatus,
    this.reviewReason,
    this.lastEditedAt,
    this.updatedBy,
  });

  /// ID del documento Firestore (= `participantId`).
  final String id;

  /// ID del torneo padre (útil para consultas cruzadas).
  final String tournamentId;

  /// ID del usuario (`AppUser.uid`) o del equipo (`AppTeam.id`).
  final String entityId;

  /// Tipo de entidad inscrita.
  final ParticipantEntityType entityType;

  /// Timestamp de inscripción.
  final DateTime enrolledAt;

  /// Estado de la inscripción.
  final ParticipantStatus status;

  /// Categoría opcional del torneo a la que se inscribe.
  final String? categoryId;
  final int registrationFormVersion;
  final List<RegistrationResponse> registrationResponses;
  final String? notes;
  final String? complementaryInfo;
  final DateTime? updatedAt;
  final String? approvedBy;
  final bool requiresReview;
  final String? reviewStatus;
  final String? reviewReason;
  final DateTime? lastEditedAt;
  final String? updatedBy;

  // ── Serialización ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'id': id,
    'tournamentId': tournamentId,
    'entityId': entityId,
    'entityType': entityType.name,
    'enrolledAt': Timestamp.fromDate(enrolledAt),
    'status': status.firestoreValue,
    'categoryId': categoryId,
    'registrationFormVersion': registrationFormVersion,
    'responses': registrationResponses
        .map((response) => response.toMap())
        .toList(),
    'notes': notes,
    'complementaryInfo': complementaryInfo,
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'approvedBy': approvedBy,
    'requiresReview': requiresReview,
    'reviewStatus': reviewStatus,
    'reviewReason': reviewReason,
    'lastEditedAt': lastEditedAt != null
        ? Timestamp.fromDate(lastEditedAt!)
        : null,
    'updatedBy': updatedBy,
  };

  factory AppParticipant.fromMap(Map<String, dynamic> map) {
    return AppParticipant(
      id: map['id'] as String? ?? '',
      tournamentId: map['tournamentId'] as String? ?? '',
      entityId: map['entityId'] as String? ?? '',
      entityType: ParticipantEntityType.fromValue(
        map['entityType'] as String? ?? '',
      ),
      enrolledAt: _dateFromValue(map['enrolledAt']),
      status: ParticipantStatus.fromValue(map['status'] as String? ?? ''),
      categoryId: map['categoryId'] as String?,
      registrationFormVersion:
          (map['registrationFormVersion'] as num?)?.toInt() ?? 1,
      registrationResponses:
          (map['responses'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map(RegistrationResponse.fromMap)
              .toList(),
      notes: map['notes'] as String?,
      complementaryInfo: map['complementaryInfo'] as String?,
      updatedAt: _nullableDateFromValue(map['updatedAt']),
      approvedBy: map['approvedBy'] as String?,
      requiresReview: map['requiresReview'] as bool? ?? false,
      reviewStatus: map['reviewStatus'] as String?,
      reviewReason: map['reviewReason'] as String?,
      lastEditedAt: _nullableDateFromValue(map['lastEditedAt']),
      updatedBy: map['updatedBy'] as String?,
    );
  }

  // ── Copia con modificaciones ───────────────────────────────────────────────

  AppParticipant copyWith({
    String? id,
    String? tournamentId,
    String? entityId,
    ParticipantEntityType? entityType,
    DateTime? enrolledAt,
    ParticipantStatus? status,
    String? categoryId,
    int? registrationFormVersion,
    List<RegistrationResponse>? registrationResponses,
    String? notes,
    String? complementaryInfo,
    DateTime? updatedAt,
    String? approvedBy,
    bool? requiresReview,
    String? reviewStatus,
    String? reviewReason,
    DateTime? lastEditedAt,
    String? updatedBy,
  }) {
    return AppParticipant(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      registrationFormVersion:
          registrationFormVersion ?? this.registrationFormVersion,
      registrationResponses:
          registrationResponses ?? this.registrationResponses,
      notes: notes ?? this.notes,
      complementaryInfo: complementaryInfo ?? this.complementaryInfo,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      requiresReview: requiresReview ?? this.requiresReview,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      reviewReason: reviewReason ?? this.reviewReason,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static DateTime? _nullableDateFromValue(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
