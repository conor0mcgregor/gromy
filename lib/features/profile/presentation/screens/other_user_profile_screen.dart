import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../user/data/models/public_user_profile.dart';
import '../controllers/other_user_profile_controller.dart';
import '../widgets/profile_stats_grid.dart';
import '../widgets/tournament_history_card.dart';

class OtherUserProfileScreen extends StatefulWidget {
  const OtherUserProfileScreen({super.key, required this.targetUid});

  final String targetUid;

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  late final OtherUserProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OtherUserProfileController(targetUid: widget.targetUid)
      ..addListener(_onChanged);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      body: _controller.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            )
          : _controller.errorMessage != null || _controller.profile == null
          ? _buildError(_controller.errorMessage)
          : _buildContent(_controller.profile!),
    );
  }

  Widget _buildError(String? message) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message ?? 'Perfil no disponible',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PublicUserProfile profile) {
    final user = profile.user;
    final memberSince = profile.memberSince != null
        ? DateFormat('MMMM yyyy', 'es').format(profile.memberSince!)
        : null;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: const Color(0xFF0F0C29),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2B2A63), Color(0xFF0F0C29)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _Avatar(photoUrl: user.photoUrl),
                  const SizedBox(height: 14),
                  Text(
                    '${user.name} ${user.lastName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user.nickname}',
                    style: const TextStyle(
                      color: Color(0xFF00D4FF),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (memberSince != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Miembro desde $memberSince',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (user.biography != null && user.biography!.isNotEmpty) ...[
                _SectionTitle('Biografia'),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    user.biography!,
                    style: const TextStyle(
                      color: Colors.white,
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _SectionTitle('Estadisticas'),
              const SizedBox(height: 12),
              ProfileStatsGrid(stats: profile.stats),
              if (profile.stats.tournamentsWon > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD166).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD166).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFFFD166),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${profile.stats.tournamentsWon} torneo(s) ganado(s)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              _SectionTitle('Historial de torneos'),
              const SizedBox(height: 12),
              if (profile.tournamentHistory.isEmpty)
                _EmptyHistory()
              else
                ...profile.tournamentHistory.map(
                  (entry) => TournamentHistoryCard(entry: entry),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF00D4FF).withValues(alpha: 0.6),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        image: photoUrl != null
            ? DecorationImage(
                image: NetworkImage(photoUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: photoUrl == null
          ? const Icon(Icons.person_rounded, size: 52, color: Colors.white)
          : null,
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 48,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sin historial todavia',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cuando participe en torneos, apareceran aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
