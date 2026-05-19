import 'enums_tournament.dart';

class TournamentDraft {
  const TournamentDraft({
    required this.id,
    required this.ownerUid,
    required this.updatedAt,
    this.name,
    this.description,
    this.coverImagePath,
    this.sport,
    this.isTeamSport = false,
    this.eventDate,
    this.registrationDeadline,
    this.bracketPublishDate,
    this.location,
    this.latitude,
    this.longitude,
    this.maxParticipants,
    this.membersPerTeam,
    this.accessType,
    this.rules,
    this.categories = const [],
    this.contactEmail,
    this.contactPhone,
    this.contactLinks = const [],
    this.extraAdminUids = const [],
    this.extraAdminLabels = const [],
  });

  final String id;
  final String ownerUid;
  final DateTime updatedAt;
  final String? name;
  final String? description;
  final String? coverImagePath;
  final TournamentSport? sport;
  final bool isTeamSport;
  final DateTime? eventDate;
  final DateTime? registrationDeadline;
  final DateTime? bracketPublishDate;
  final String? location;
  final double? latitude;
  final double? longitude;
  final int? maxParticipants;
  final int? membersPerTeam;
  final TournamentAccessType? accessType;
  final String? rules;
  final List<String> categories;
  final String? contactEmail;
  final String? contactPhone;
  final List<String> contactLinks;
  final List<String> extraAdminUids;
  final List<String> extraAdminLabels;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerUid': ownerUid,
      'status': 'draft',
      'updatedAt': updatedAt.toIso8601String(),
      'name': name,
      'description': description,
      'coverImagePath': coverImagePath,
      'sport': sport?.name,
      'isTeamSport': isTeamSport,
      'eventDate': eventDate?.toIso8601String(),
      'registrationDeadline': registrationDeadline?.toIso8601String(),
      'bracketPublishDate': bracketPublishDate?.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'maxParticipants': maxParticipants,
      'membersPerTeam': membersPerTeam,
      'accessType': accessType?.name,
      'rules': rules,
      'categories': categories,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'contactLinks': contactLinks,
      'extraAdminUids': extraAdminUids,
      'extraAdminLabels': extraAdminLabels,
    };
  }

  factory TournamentDraft.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final ownerUid = json['ownerUid'] as String? ?? '';
    if (id.isEmpty || ownerUid.isEmpty) {
      throw const FormatException('Borrador sin propietario válido.');
    }

    return TournamentDraft(
      id: id,
      ownerUid: ownerUid,
      updatedAt: _dateFromValue(json['updatedAt']) ?? DateTime.now(),
      name: _stringOrNull(json['name']),
      description: _stringOrNull(json['description']),
      coverImagePath: _stringOrNull(json['coverImagePath']),
      sport: _enumOrNull<TournamentSport>(
        json['sport'],
        TournamentSport.values,
      ),
      isTeamSport: json['isTeamSport'] as bool? ?? false,
      eventDate: _dateFromValue(json['eventDate']),
      registrationDeadline: _dateFromValue(json['registrationDeadline']),
      bracketPublishDate: _dateFromValue(json['bracketPublishDate']),
      location: _stringOrNull(json['location']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      maxParticipants: (json['maxParticipants'] as num?)?.toInt(),
      membersPerTeam: (json['membersPerTeam'] as num?)?.toInt(),
      accessType: _enumOrNull<TournamentAccessType>(
        json['accessType'],
        TournamentAccessType.values,
      ),
      rules: _stringOrNull(json['rules']),
      categories: _stringList(json['categories']),
      contactEmail: _stringOrNull(json['contactEmail']),
      contactPhone: _stringOrNull(json['contactPhone']),
      contactLinks: _stringList(json['contactLinks']),
      extraAdminUids: _stringList(json['extraAdminUids']),
      extraAdminLabels: _stringList(json['extraAdminLabels']),
    );
  }

  TournamentDraft copyWith({
    String? id,
    String? ownerUid,
    DateTime? updatedAt,
    String? name,
    String? description,
    String? coverImagePath,
    TournamentSport? sport,
    bool? isTeamSport,
    DateTime? eventDate,
    DateTime? registrationDeadline,
    DateTime? bracketPublishDate,
    String? location,
    double? latitude,
    double? longitude,
    int? maxParticipants,
    int? membersPerTeam,
    TournamentAccessType? accessType,
    String? rules,
    List<String>? categories,
    String? contactEmail,
    String? contactPhone,
    List<String>? contactLinks,
    List<String>? extraAdminUids,
    List<String>? extraAdminLabels,
  }) {
    return TournamentDraft(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      sport: sport ?? this.sport,
      isTeamSport: isTeamSport ?? this.isTeamSport,
      eventDate: eventDate ?? this.eventDate,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      bracketPublishDate: bracketPublishDate ?? this.bracketPublishDate,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      membersPerTeam: membersPerTeam ?? this.membersPerTeam,
      accessType: accessType ?? this.accessType,
      rules: rules ?? this.rules,
      categories: categories ?? this.categories,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      contactLinks: contactLinks ?? this.contactLinks,
      extraAdminUids: extraAdminUids ?? this.extraAdminUids,
      extraAdminLabels: extraAdminLabels ?? this.extraAdminLabels,
    );
  }

  static String? _stringOrNull(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<String> _stringList(dynamic value) {
    return (value as List<dynamic>? ?? const <dynamic>[])
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static T? _enumOrNull<T extends Enum>(dynamic value, List<T> values) {
    if (value is! String || value.isEmpty) return null;
    for (final option in values) {
      if (option.name == value) return option;
    }
    return null;
  }
}
