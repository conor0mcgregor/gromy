import 'local_athlete.dart';
import 'local_match.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LocalTournament  ·  Data Model
//
//  Representa un torneo local gestionado desde un único dispositivo.
//  Sin dependencias de Firebase. Persiste localmente en JSON.
// ─────────────────────────────────────────────────────────────────────────────

enum LocalTournamentStatus {
  setup,      // Configurando participantes
  inProgress, // Bracket en marcha
  finished;   // Torneo completado

  static LocalTournamentStatus fromValue(String value) =>
      LocalTournamentStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => LocalTournamentStatus.setup,
      );

  String get label => switch (this) {
    LocalTournamentStatus.setup => 'Configurando',
    LocalTournamentStatus.inProgress => 'En curso',
    LocalTournamentStatus.finished => 'Finalizado',
  };
}

class LocalTournament {
  const LocalTournament({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.athletes,
    required this.matches,
    this.coverImagePath,
    this.sport,
    this.totalRounds = 0,
  });

  /// ID único generado localmente.
  final String id;

  /// Nombre del torneo.
  final String name;

  /// Deporte o disciplina (opcional).
  final String? sport;

  /// Estado del torneo.
  final LocalTournamentStatus status;

  /// Lista de atletas inscritos.
  final List<LocalAthlete> athletes;

  /// Lista de matches del bracket.
  final List<LocalMatch> matches;

  /// Ruta de la imagen de portada en el dispositivo.
  final String? coverImagePath;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Número total de rondas del bracket.
  final int totalRounds;

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool get hasBracket => matches.isNotEmpty;

  Map<int, List<LocalMatch>> get matchesByRound {
    final map = <int, List<LocalMatch>>{};
    for (final match in matches) {
      map.putIfAbsent(match.round, () => []).add(match);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.matchOrder.compareTo(b.matchOrder));
    }
    return map;
  }

  LocalMatch? get champion {
    final finals = matches.where((m) => m.isFinal && m.isCompleted);
    if (finals.isEmpty) return null;
    return finals.first;
  }

  // ── Serialización ──────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'sport': sport,
    'status': status.name,
    'athletes': athletes.map((a) => a.toMap()).toList(),
    'matches': matches.map((m) => m.toMap()).toList(),
    'coverImagePath': coverImagePath,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'totalRounds': totalRounds,
  };

  factory LocalTournament.fromMap(Map<String, dynamic> map) {
    return LocalTournament(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      sport: map['sport'] as String?,
      status: LocalTournamentStatus.fromValue(map['status'] as String? ?? ''),
      athletes: (map['athletes'] as List<dynamic>? ?? [])
          .map((e) => LocalAthlete.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      matches: (map['matches'] as List<dynamic>? ?? [])
          .map((e) => LocalMatch.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      coverImagePath: map['coverImagePath'] as String?,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
      totalRounds: (map['totalRounds'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  LocalTournament copyWith({
    String? id,
    String? name,
    String? sport,
    LocalTournamentStatus? status,
    List<LocalAthlete>? athletes,
    List<LocalMatch>? matches,
    String? coverImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalRounds,
    bool clearCoverImage = false,
  }) {
    return LocalTournament(
      id: id ?? this.id,
      name: name ?? this.name,
      sport: sport ?? this.sport,
      status: status ?? this.status,
      athletes: athletes ?? this.athletes,
      matches: matches ?? this.matches,
      coverImagePath: clearCoverImage ? null : (coverImagePath ?? this.coverImagePath),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalRounds: totalRounds ?? this.totalRounds,
    );
  }
}
