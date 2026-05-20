class UserSportStats {
  const UserSportStats({
    required this.totalPlayed,
    required this.tournamentsWon,
    required this.matchesPlayed,
    required this.matchesWon,
    required this.matchesLost,
    required this.matchesDraw,
    required this.winRate,
  });

  final int totalPlayed;
  final int tournamentsWon;
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final int matchesDraw;
  final int winRate;

  factory UserSportStats.fromMap(Map<String, dynamic> map) {
    return UserSportStats(
      totalPlayed: (map['totalPlayed'] as num?)?.toInt() ?? 0,
      tournamentsWon: (map['tournamentsWon'] as num?)?.toInt() ?? 0,
      matchesPlayed: (map['matchesPlayed'] as num?)?.toInt() ?? 0,
      matchesWon: (map['matchesWon'] as num?)?.toInt() ?? 0,
      matchesLost: (map['matchesLost'] as num?)?.toInt() ?? 0,
      matchesDraw: (map['matchesDraw'] as num?)?.toInt() ?? 0,
      winRate: (map['winRate'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalPlayed': totalPlayed,
      'tournamentsWon': tournamentsWon,
      'matchesPlayed': matchesPlayed,
      'matchesWon': matchesWon,
      'matchesLost': matchesLost,
      'matchesDraw': matchesDraw,
      'winRate': winRate,
    };
  }

  static const empty = UserSportStats(
    totalPlayed: 0,
    tournamentsWon: 0,
    matchesPlayed: 0,
    matchesWon: 0,
    matchesLost: 0,
    matchesDraw: 0,
    winRate: 0,
  );
}
