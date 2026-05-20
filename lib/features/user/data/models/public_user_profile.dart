import 'public_app_user.dart';
import 'user_profile_stats.dart';
import 'user_tournament_history_entry.dart';

/// Perfil publico enriquecido con estadisticas e historial de torneos.
class PublicUserProfile {
  const PublicUserProfile({
    required this.user,
    this.memberSince,
    this.stats = UserProfileStats.empty,
    this.tournamentHistory = const [],
  });

  final PublicAppUser user;
  final DateTime? memberSince;
  final UserProfileStats stats;
  final List<UserTournamentHistoryEntry> tournamentHistory;

  factory PublicUserProfile.fromMap(Map<String, dynamic> map) {
    final statsMap = map['stats'];
    final historyList = map['tournamentHistory'];

    return PublicUserProfile(
      user: PublicAppUser.fromMap(map),
      memberSince: map['memberSince'] != null
          ? DateTime.tryParse(map['memberSince'] as String)
          : null,
      stats: statsMap is Map
          ? UserProfileStats.fromMap(Map<String, dynamic>.from(statsMap))
          : UserProfileStats.empty,
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
