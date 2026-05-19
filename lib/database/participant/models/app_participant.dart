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
  pending,
  approved,
  rejected;

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
    this.registrationFormVersion = 1,
    this.registrationResponses = const [],
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
    'responses': registrationResponses
        .map((response) => response.toMap())
        .toList(),
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
    );
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
