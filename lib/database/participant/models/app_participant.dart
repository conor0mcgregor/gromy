import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../features/inscription/domain/models/registration_response.dart';

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
  pending,
  approved,
  rejected,
  pendingReview;

  static ParticipantStatus fromValue(String value) {
    return ParticipantStatus.values.firstWhere(
      (e) => e.name == value,
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
    this.registrationFormVersion,
    this.responses = const [],
    this.updatedAt,
    this.updatedBy,
    this.lastEditedAt,
    this.requiresReview = false,
    this.reviewReason,
    this.approvedBy,
    this.source,
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

  /// Versión del formulario de inscripción usado al registrarse.
  final int? registrationFormVersion;

  /// Respuestas a los campos adicionales del formulario.
  final List<RegistrationResponse> responses;

  /// Última fecha de actualización.
  final DateTime? updatedAt;

  /// UID del usuario que realizó la última actualización.
  final String? updatedBy;

  /// Última fecha de edición por el propio inscrito.
  final DateTime? lastEditedAt;

  /// Indica si la inscripción requiere revisión tras una edición.
  final bool requiresReview;

  /// Motivo por el que requiere revisión.
  final String? reviewReason;

  /// UID del organizador que aprobó la inscripción.
  final String? approvedBy;

  /// Origen de la inscripción (ej. 'direct', 'manual_approval').
  final String? source;

  // ── Serialización ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'tournamentId': tournamentId,
        'entityId': entityId,
        'entityType': entityType.name,
        'enrolledAt': Timestamp.fromDate(enrolledAt),
        'status': status.name,
        'categoryId': categoryId,
        'registrationFormVersion': registrationFormVersion,
        'responses': responses.map((r) => r.toMap()).toList(),
        'updatedAt':
            updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'updatedBy': updatedBy,
        'lastEditedAt':
            lastEditedAt != null ? Timestamp.fromDate(lastEditedAt!) : null,
        'requiresReview': requiresReview,
        'reviewReason': reviewReason,
        'approvedBy': approvedBy,
        'source': source,
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
          (map['registrationFormVersion'] as num?)?.toInt(),
      responses:
          (map['responses'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) =>
                  RegistrationResponse.fromMap(e as Map<String, dynamic>))
              .toList(),
      updatedAt: _nullableDate(map['updatedAt']),
      updatedBy: map['updatedBy'] as String?,
      lastEditedAt: _nullableDate(map['lastEditedAt']),
      requiresReview: map['requiresReview'] as bool? ?? false,
      reviewReason: map['reviewReason'] as String?,
      approvedBy: map['approvedBy'] as String?,
      source: map['source'] as String?,
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
    List<RegistrationResponse>? responses,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? lastEditedAt,
    bool? requiresReview,
    String? reviewReason,
    String? approvedBy,
    String? source,
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
      responses: responses ?? this.responses,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      requiresReview: requiresReview ?? this.requiresReview,
      reviewReason: reviewReason ?? this.reviewReason,
      approvedBy: approvedBy ?? this.approvedBy,
      source: source ?? this.source,
    );
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static DateTime? _nullableDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}