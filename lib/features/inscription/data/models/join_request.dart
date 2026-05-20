import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/models/registration_form.dart';
import '../../../../database/participant/models/app_participant.dart';

enum JoinRequestStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static JoinRequestStatus fromValue(String value) {
    return JoinRequestStatus.values.firstWhere(
      (status) => status.name == value,
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
    required this.updatedAt,
    this.categoryId,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    this.registrationFormVersion = 1,
    this.responses = const [],
  });

  final String id;
  final String tournamentId;
  final String entityId;
  final ParticipantEntityType entityType;
  final String requestedBy;
  final JoinRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? categoryId;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final int registrationFormVersion;
  final List<RegistrationResponse> responses;

  Map<String, dynamic> toMap() {
    return {
      'requestId': id,
      'tournamentId': tournamentId,
      'entityId': entityId,
      'entityType': entityType.name,
      'requestedBy': requestedBy,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'categoryId': categoryId,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'rejectionReason': rejectionReason,
      'registrationFormVersion': registrationFormVersion,
      'responses': responses.map((response) => response.toMap()).toList(),
    };
  }

  factory JoinRequest.fromMap(Map<String, dynamic> map) {
    return JoinRequest(
      id: map['requestId'] as String? ?? map['id'] as String? ?? '',
      tournamentId: map['tournamentId'] as String? ?? '',
      entityId: map['entityId'] as String? ?? '',
      entityType: ParticipantEntityType.fromValue(
        map['entityType'] as String? ?? '',
      ),
      requestedBy: map['requestedBy'] as String? ?? '',
      status: JoinRequestStatus.fromValue(map['status'] as String? ?? ''),
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
      categoryId: map['categoryId'] as String?,
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: _nullableDateFromValue(map['reviewedAt']),
      rejectionReason: map['rejectionReason'] as String?,
      registrationFormVersion:
          (map['registrationFormVersion'] as num?)?.toInt() ?? 1,
      responses: (map['responses'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(RegistrationResponse.fromMap)
          .toList(),
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
