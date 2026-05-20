class UserProfileStats {
  const UserProfileStats({
    required this.totalPlayed,
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.tournamentsWon,
  });

  final int totalPlayed;
  final int wins;
  final int losses;
  final int winRate;
  final int tournamentsWon;

  factory UserProfileStats.fromMap(Map<String, dynamic> map) {
    return UserProfileStats(
      totalPlayed: (map['totalPlayed'] as num?)?.toInt() ?? 0,
      wins: (map['wins'] as num?)?.toInt() ?? 0,
      losses: (map['losses'] as num?)?.toInt() ?? 0,
      winRate: (map['winRate'] as num?)?.toInt() ?? 0,
      tournamentsWon: (map['tournamentsWon'] as num?)?.toInt() ?? 0,
    );
  }

  static const empty = UserProfileStats(
    totalPlayed: 0,
    wins: 0,
    losses: 0,
    winRate: 0,
    tournamentsWon: 0,
  );
}
