enum TournamentResultStatus { won, participated, eliminated, pending }

class UserTournamentHistoryEntry {
  const UserTournamentHistoryEntry({
    required this.tournamentId,
    required this.tournamentName,
    this.scheduledAt,
    required this.tournamentType,
    required this.tournamentStatus,
    required this.participantStatus,
    required this.resultStatus,
    required this.placementLabel,
    this.sport,
    this.coverImageUrl,
  });

  final String tournamentId;
  final String tournamentName;
  final DateTime? scheduledAt;
  final String tournamentType;
  final String tournamentStatus;
  final String participantStatus;
  final TournamentResultStatus resultStatus;
  final String placementLabel;
  final String? sport;
  final String? coverImageUrl;

  factory UserTournamentHistoryEntry.fromMap(Map<String, dynamic> map) {
    return UserTournamentHistoryEntry(
      tournamentId: map['tournamentId'] as String? ?? '',
      tournamentName: map['tournamentName'] as String? ?? 'Torneo',
      scheduledAt: map['scheduledAt'] != null
          ? DateTime.tryParse(map['scheduledAt'] as String)
          : null,
      tournamentType: map['tournamentType'] as String? ?? 'tournament',
      tournamentStatus: map['tournamentStatus'] as String? ?? '',
      participantStatus: map['participantStatus'] as String? ?? '',
      resultStatus: _parseResultStatus(map['resultStatus'] as String?),
      placementLabel: map['placementLabel'] as String? ?? 'Participo',
      sport: map['sport'] as String?,
      coverImageUrl: map['coverImageUrl'] as String?,
    );
  }

  static TournamentResultStatus _parseResultStatus(String? value) {
    return switch (value) {
      'won' => TournamentResultStatus.won,
      'eliminated' => TournamentResultStatus.eliminated,
      'pending' => TournamentResultStatus.pending,
      _ => TournamentResultStatus.participated,
    };
  }
}
