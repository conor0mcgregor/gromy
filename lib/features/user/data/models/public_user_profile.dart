import 'public_app_user.dart';
import 'user_profile_stats.dart';
import 'user_sport_stats.dart';
import 'user_tournament_history_entry.dart';

/// Perfil publico enriquecido con estadisticas e historial de torneos.
class PublicUserProfile {
  const PublicUserProfile({
    required this.user,
    this.memberSince,
    this.stats = UserProfileStats.empty,
    this.sportsStats = const {},
    this.tournamentHistory = const [],
  });

  final PublicAppUser user;
  final DateTime? memberSince;
  final UserProfileStats stats;
  final Map<String, UserSportStats> sportsStats;
  final List<UserTournamentHistoryEntry> tournamentHistory;

  factory PublicUserProfile.fromMap(Map<String, dynamic> map) {
    final statsMap = map['stats'];
    final sportsStatsMap = map['sportsStats'];
    final historyList = map['tournamentHistory'];

    final parsedSportsStats = <String, UserSportStats>{};
    if (sportsStatsMap is Map) {
      sportsStatsMap.forEach((key, value) {
        if (value is Map) {
          parsedSportsStats[key.toString()] = UserSportStats.fromMap(
            Map<String, dynamic>.from(value),
          );
        }
      });
    }

    return PublicUserProfile(
      user: PublicAppUser.fromMap(map),
      memberSince: map['memberSince'] != null
          ? DateTime.tryParse(map['memberSince'] as String)
          : null,
      stats: statsMap is Map
          ? UserProfileStats.fromMap(Map<String, dynamic>.from(statsMap))
          : UserProfileStats.empty,
      sportsStats: parsedSportsStats,
      tournamentHistory: historyList is List
          ? historyList
                .whereType<Map>()
                .map(
                  (item) => UserTournamentHistoryEntry.fromMap(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }
}
