import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/models/registration_form.dart';
import 'enums_tournament.dart';

class AppTournament {
  const AppTournament({
    required this.id,
    required this.name,
    required this.description,
    required this.allInformation,
    required this.scheduledAt,
    required this.maxParticipants,
    required this.location,
    required this.sport,
    required this.accessType,
    this.status = TournamentStatus.published,
    required this.organizerUid,
    required this.adminIds,
    required this.maxMatchDurationMinutes,
    required this.createdAt,
    required this.updatedAt,
    this.portadaUrl,
    this.additionalInfo,
    this.organizerEmail,
    this.organizerDisplayName,
    this.participantCount = 0,
    this.membersPerTeam,
    this.latitude,
    this.longitude,
    this.registrationDeadline,
    this.bracketPublishDate,
    this.contactEmail,
    this.contactPhone,
    this.contactLinks = const [],
    this.categories = const [],
    this.registrationForm = const RegistrationFormSchema(),
  });

  final String id;
  final String name;
  final String description;
  final String allInformation;
  final DateTime scheduledAt;
  final int maxParticipants;
  final String location;
  final TournamentSport sport;
  final TournamentAccessType accessType;
  final TournamentStatus status;
  final String organizerUid;
  final List<String> adminIds;
  final int maxMatchDurationMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// URL de la imagen de portada almacenada en Firebase Storage. Puede ser null
  /// si el torneo no tiene portada asignada.
  final String? portadaUrl;

  final String? additionalInfo;
  final String? organizerEmail;
  final String? organizerDisplayName;
  final int participantCount;
  final int? membersPerTeam;

  /// Coordenadas geográficas del lugar del torneo.
  final double? latitude;
  final double? longitude;

  /// Fecha límite de inscripción.
  final DateTime? registrationDeadline;

  /// Fecha de publicación de cuadros/enfrentamientos.
  final DateTime? bracketPublishDate;

  /// Datos de contacto del organizador.
  final String? contactEmail;
  final String? contactPhone;
  final List<String> contactLinks;

  /// Categorías opcionales del torneo (ej. 'Sub-18', 'Femenino', 'Amateur').
  final List<String> categories;

  final RegistrationFormSchema registrationForm;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'allInformation': allInformation,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'maxParticipants': maxParticipants,
      'membersPerTeam': membersPerTeam,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'sport': sport.name,
      'accessType': accessType.name,
      'status': status.name,
      'organizerUid': organizerUid,
      'organizerEmail': organizerEmail,
      'organizerDisplayName': organizerDisplayName,
      'adminIds': adminIds,
      'maxMatchDurationMinutes': maxMatchDurationMinutes,
      'participantCount': participantCount,
      'portadaUrl': portadaUrl,
      'additionalInfo': additionalInfo,
      'registrationDeadline': registrationDeadline != null
          ? Timestamp.fromDate(registrationDeadline!)
          : null,
      'bracketPublishDate': bracketPublishDate != null
          ? Timestamp.fromDate(bracketPublishDate!)
          : null,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'contactLinks': contactLinks,
      'categories': categories,
      'registrationForm': registrationForm.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AppTournament.fromMap(Map<String, dynamic> map) {
    return AppTournament(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      allInformation: map['allInformation'] as String? ?? '',
      scheduledAt: _dateFromValue(map['scheduledAt']),
      maxParticipants: (map['maxParticipants'] as num?)?.toInt() ?? 0,
      membersPerTeam: (map['membersPerTeam'] as num?)?.toInt() ?? 0,
      location: map['location'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      sport: TournamentSport.fromValue(map['sport'] as String? ?? ''),
      accessType: TournamentAccessType.fromValue(
        map['accessType'] as String? ?? '',
      ),
      status: TournamentStatus.fromValue(map['status'] as String? ?? ''),
      organizerUid: map['organizerUid'] as String? ?? '',
      organizerEmail: map['organizerEmail'] as String?,
      organizerDisplayName: map['organizerDisplayName'] as String?,
      adminIds: (map['adminIds'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(),
      maxMatchDurationMinutes: (map['maxMatchDurationMinutes'] as num?)?.toInt() ?? 60,
      participantCount: (map['participantCount'] as num?)?.toInt() ?? 0,
      portadaUrl: map['portadaUrl'] as String?,
      additionalInfo: map['additionalInfo'] as String?,
      registrationDeadline: _nullableDateFromValue(map['registrationDeadline']),
      bracketPublishDate: _nullableDateFromValue(map['bracketPublishDate']),
      contactEmail: map['contactEmail'] as String?,
      contactPhone: map['contactPhone'] as String?,
      contactLinks: (map['contactLinks'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(),
      categories: (map['categories'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(),
      registrationForm: RegistrationFormSchema.fromMap(
        map['registrationForm'] as Map<String, dynamic>?,
      ),
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
    );
  }

  AppTournament copyWith({
    String? id,
    String? name,
    String? description,
    String? allInformation,
    DateTime? scheduledAt,
    int? maxParticipants,
    String? location,
    TournamentSport? sport,
    TournamentAccessType? accessType,
    TournamentStatus? status,
    String? organizerUid,
    List<String>? adminIds,
    int? maxMatchDurationMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? portadaUrl,
    String? additionalInfo,
    String? organizerEmail,
    String? organizerDisplayName,
    int? participantCount,
    int? membersPerTeam,
    double? latitude,
    double? longitude,
    DateTime? registrationDeadline,
    DateTime? bracketPublishDate,
    String? contactEmail,
    String? contactPhone,
    List<String>? contactLinks,
    List<String>? categories,
    RegistrationFormSchema? registrationForm,
  }) {
    return AppTournament(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      allInformation: allInformation ?? this.allInformation,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      location: location ?? this.location,
      sport: sport ?? this.sport,
      accessType: accessType ?? this.accessType,
      status: status ?? this.status,
      organizerUid: organizerUid ?? this.organizerUid,
      adminIds: adminIds ?? this.adminIds,
      maxMatchDurationMinutes: maxMatchDurationMinutes ?? this.maxMatchDurationMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      portadaUrl: portadaUrl ?? this.portadaUrl,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      organizerEmail: organizerEmail ?? this.organizerEmail,
      organizerDisplayName: organizerDisplayName ?? this.organizerDisplayName,
      participantCount: participantCount ?? this.participantCount,
      membersPerTeam: membersPerTeam ?? this.membersPerTeam,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      bracketPublishDate: bracketPublishDate ?? this.bracketPublishDate,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      contactLinks: contactLinks ?? this.contactLinks,
      categories: categories ?? this.categories,
      registrationForm: registrationForm ?? this.registrationForm,
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

  static DateTime? _nullableDateFromValue(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  bool get acceptsRegistrations {
    if (!status.acceptsRegistrations) return false;
    if (registrationDeadline != null &&
        DateTime.now().isAfter(registrationDeadline!)) {
      return false;
    }
    return true;
  }

  bool get isPubliclyVisible => status.isPubliclyVisible;
}
