import 'package:flutter/material.dart';

import '../../../user/data/models/user_profile_stats.dart';

class ProfileStatsGrid extends StatelessWidget {
  const ProfileStatsGrid({super.key, required this.stats});

  final UserProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem('Jugados', stats.totalPlayed, Icons.sports_esports_rounded),
      _StatItem('Victorias', stats.wins, Icons.emoji_events_rounded),
      _StatItem('Derrotas', stats.losses, Icons.close_rounded),
      _StatItem('Win rate', stats.winRate, Icons.percent_rounded, suffix: '%'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6C63FF).withValues(alpha: 0.22),
                const Color(0xFF00D4FF).withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, color: const Color(0xFF00D4FF), size: 22),
              const Spacer(),
              Text(
                '${item.value}${item.suffix ?? ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem {
  const _StatItem(this.label, this.value, this.icon, {this.suffix});

  final String label;
  final int value;
  final IconData icon;
  final String? suffix;
}
