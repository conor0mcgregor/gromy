import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../database/participant/models/app_participant.dart';
import 'registration_response.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  JoinRequest  ·  Dominio
//
//  Solicitud de inscripción a un torneo cerrado.
//  Se persiste como subcolección:
//    tournaments/{tournamentId}/joinRequests/{requestId}
// ─────────────────────────────────────────────────────────────────────────────

enum JoinRequestStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static JoinRequestStatus fromValue(String value) {
    return JoinRequestStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => JoinRequestStatus.pending,
    );
  }
}

class JoinRequest {
  const JoinRequest({
    required this.id,
    required this.tournamentId,
    required this.entityId,
    required this.entityType,
    required this.requestedBy,
    required this.status,
    required this.createdAt,
    this.responses = const [],
    this.updatedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
  });

  final String id;
  final String tournamentId;

  /// ID del usuario o equipo que solicita inscripción.
  final String entityId;

  /// Tipo de entidad (user | team).
  final ParticipantEntityType entityType;

  /// UID del usuario que envió la solicitud.
  final String requestedBy;

  final JoinRequestStatus status;

  /// Respuestas a los campos adicionales del formulario (si los hay).
  final List<RegistrationResponse> responses;

  final DateTime createdAt;
  final DateTime? updatedAt;

  /// UID del organizador que revisó la solicitud.
  final String? reviewedBy;
  final DateTime? reviewedAt;

  /// Motivo de rechazo (trazabilidad mínima).
  final String? rejectionReason;

  bool get isPending => status == JoinRequestStatus.pending;

  // ── Serialización ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'tournamentId': tournamentId,
        'entityId': entityId,
        'entityType': entityType.name,
        'requestedBy': requestedBy,
        'status': status.name,
        'responses': responses.map((r) => r.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt':
            updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'reviewedBy': reviewedBy,
        'reviewedAt':
            reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
        'rejectionReason': rejectionReason,
      };

  factory JoinRequest.fromMap(Map<String, dynamic> map) {
    return JoinRequest(
      id: map['id'] as String? ?? '',
      tournamentId: map['tournamentId'] as String? ?? '',
      entityId: map['entityId'] as String? ?? '',
      entityType: ParticipantEntityType.fromValue(
        map['entityType'] as String? ?? '',
      ),
      requestedBy: map['requestedBy'] as String? ?? '',
      status: JoinRequestStatus.fromValue(map['status'] as String? ?? ''),
      responses:
          (map['responses'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) =>
                  RegistrationResponse.fromMap(e as Map<String, dynamic>))
              .toList(),
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _nullableDate(map['updatedAt']),
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: _nullableDate(map['reviewedAt']),
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  JoinRequest copyWith({
    String? id,
    String? tournamentId,
    String? entityId,
    ParticipantEntityType? entityType,
    String? requestedBy,
    JoinRequestStatus? status,
    List<RegistrationResponse>? responses,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
  }) {
    return JoinRequest(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      requestedBy: requestedBy ?? this.requestedBy,
      status: status ?? this.status,
      responses: responses ?? this.responses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
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
