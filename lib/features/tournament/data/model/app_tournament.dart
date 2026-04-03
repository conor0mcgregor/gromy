import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums_tournament.dart';

class AppTournament {
  const AppTournament({
    required this.id,
    required this.name,
    required this.description,
    required this.scheduledAt,
    required this.maxParticipants,
    required this.location,
    required this.sport,
    required this.accessType,
    required this.organizerUid,
    required this.adminIds,
    required this.createdAt,
    required this.updatedAt,
    this.additionalInfo,
    this.organizerEmail,
    this.organizerDisplayName,
    this.participantCount = 0,
  });

  final String id;
  final String name;
  final String description;
  final DateTime scheduledAt;
  final int maxParticipants;
  final String location;
  final TournamentSport sport;
  final TournamentAccessType accessType;
  final String organizerUid;
  final List<String> adminIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? additionalInfo;
  final String? organizerEmail;
  final String? organizerDisplayName;
  final int participantCount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'maxParticipants': maxParticipants,
      'location': location,
      'sport': sport.name,
      'accessType': accessType.name,
      'organizerUid': organizerUid,
      'organizerEmail': organizerEmail,
      'organizerDisplayName': organizerDisplayName,
      'adminIds': adminIds,
      'participantCount': participantCount,
      'additionalInfo': additionalInfo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AppTournament.fromMap(Map<String, dynamic> map) {
    return AppTournament(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      scheduledAt: _dateFromValue(map['scheduledAt']),
      maxParticipants: (map['maxParticipants'] as num?)?.toInt() ?? 0,
      location: map['location'] as String? ?? '',
      sport: TournamentSport.fromValue(map['sport'] as String? ?? ''),
      accessType: TournamentAccessType.fromValue(
        map['accessType'] as String? ?? '',
      ),
      organizerUid: map['organizerUid'] as String? ?? '',
      organizerEmail: map['organizerEmail'] as String?,
      organizerDisplayName: map['organizerDisplayName'] as String?,
      adminIds: (map['adminIds'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(),
      participantCount: (map['participantCount'] as num?)?.toInt() ?? 0,
      additionalInfo: map['additionalInfo'] as String?,
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
    );
  }

  AppTournament copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? scheduledAt,
    int? maxParticipants,
    String? location,
    TournamentSport? sport,
    TournamentAccessType? accessType,
    String? organizerUid,
    List<String>? adminIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? additionalInfo,
    String? organizerEmail,
    String? organizerDisplayName,
    int? participantCount,
  }) {
    return AppTournament(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      location: location ?? this.location,
      sport: sport ?? this.sport,
      accessType: accessType ?? this.accessType,
      organizerUid: organizerUid ?? this.organizerUid,
      adminIds: adminIds ?? this.adminIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      organizerEmail: organizerEmail ?? this.organizerEmail,
      organizerDisplayName: organizerDisplayName ?? this.organizerDisplayName,
      participantCount: participantCount ?? this.participantCount,
    );
  }

  static DateTime _dateFromValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
