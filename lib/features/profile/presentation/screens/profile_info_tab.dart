import 'dart:math' as math;
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../account/presentation/widgets/delete_account_dialog.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../tournament/data/model/enums_tournament.dart';
import '../../../user/data/models/app_user.dart';
import '../../../user/data/models/public_user_profile.dart';
import '../../../user/data/models/user_profile_stats.dart';
import '../../../user/data/models/user_tournament_history_entry.dart';
import '../../../user/data/services/firestore_user_service.dart';
import 'edit_profile_screen.dart';
import 'historical_tournaments_screen.dart';
import 'user_tournament_bracket_screen.dart';
import '../../../inscription/screen/preinscription_screen.dart';
import '../../../../core/getColors/getter_colors.dart';
import '../../../tournament/data/services/firestore_tournament_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ProfileInfoTab  ·  Perfil propio rediseñado
// ─────────────────────────────────────────────────────────────────────────────

class ProfileInfoTab extends StatefulWidget {
  const ProfileInfoTab({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ProfileInfoTab> createState() => _ProfileInfoTabState();
}

class _ProfileInfoTabState extends State<ProfileInfoTab>
    with TickerProviderStateMixin {
  static const _historyPreviewCount = 3;

  bool _isLoggingOut = false;
  FirestoreUserService? _userService;
  FirestoreTournamentService? _tournamentService;
  String? _openingTournamentId;

  /// Carga básica del AppUser (email, nombre, etc.)
  late Future<AppUser?> _userFuture;

  /// Carga enriquecida con estadísticas + historial via Cloud Function
  late Future<PublicUserProfile?> _profileFuture;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _loadUser();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _loadUser() {
    final uid = _currentUid();
    _userService ??= FirestoreUserService();
    _tournamentService ??= FirestoreTournamentService();
    if (uid != null) {
      _userFuture = _userService!.getUser(uid);
      _profileFuture = _userService!.getOtherUserPublicProfile(uid);
    } else {
      _userFuture = SynchronousFuture(null);
      _profileFuture = SynchronousFuture(null);
    }
    _entranceController.forward(from: 0);
  }

  String? _currentUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await widget.authController.logout();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo cerrar sesión. Inténtalo de nuevo.'),
          backgroundColor: const Color(0xFFFF4D6A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Future<void> _openDeleteAccountFlow() async {
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteAccountDialog(),
    );

    if (!mounted || deleted != true) return;
    try {
      await widget.authController.logout();
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tu cuenta ha sido eliminada correctamente.'),
        backgroundColor: Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openTournament(UserTournamentHistoryEntry entry) async {
    if (_openingTournamentId != null || entry.tournamentId.isEmpty) return;
    setState(() => _openingTournamentId = entry.tournamentId);
    try {
      final tournament = await _tournamentService!.getTournament(
        entry.tournamentId,
      );
      if (!mounted) return;
      if (tournament == null) {
        _showSnack('No se pudo cargar este torneo.');
        return;
      }
      final uid = _currentUid() ?? '';
      final route = tournament.status == TournamentStatus.completed
          ? MaterialPageRoute(
              builder: (_) => UserTournamentBracketScreen(
                tournament: tournament,
                targetUid: uid,
                userDisplayName: 'Tú',
              ),
            )
          : MaterialPageRoute(
              builder: (_) => PreinscriptionScreen(tournament: tournament),
            );
      await Navigator.of(context).push(route);
    } catch (_) {
      if (mounted) _showSnack('No se pudo abrir el torneo.');
    } finally {
      if (mounted) setState(() => _openingTournamentId = null);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _userFuture,
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const _ProfileLoadingSkeleton();
        }

        if (userSnap.hasError || userSnap.data == null) {
          return _buildErrorState();
        }

        final user = userSnap.data!;

        return FutureBuilder<PublicUserProfile?>(
          future: _profileFuture,
          builder: (context, profileSnap) {
            final profile = profileSnap.data;

            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Cabecera Hero ──────────────────────────────────────
                      _ProfileHeroCard(
                        user: user,
                        profile: profile,
                        onEditTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(uid: user.uid),
                            ),
                          );
                          if (result == true) {
                            setState(_loadUser);
                          }
                        },
                      ),
                      const SizedBox(height: 20),

                      // ── Estadísticas personales ────────────────────────────
                      _StatsSection(
                        stats: profile?.stats ?? UserProfileStats.empty,
                        isLoading: profileSnap.connectionState ==
                            ConnectionState.waiting,
                      ),
                      const SizedBox(height: 20),

                      // ── Historial de torneos ───────────────────────────────
                      _TournamentHistorySection(
                        history: profile?.tournamentHistory ?? [],
                        previewCount: _historyPreviewCount,
                        openingId: _openingTournamentId,
                        isLoading: profileSnap.connectionState ==
                            ConnectionState.waiting,
                        onTap: _openTournament,
                        onSeeAll: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HistoricalTournamentsScreen(uid: user.uid),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Información de cuenta ──────────────────────────────
                      _AccountInfoCard(user: user),
                      const SizedBox(height: 20),

                      // ── Acciones rápidas ───────────────────────────────────
                      _ActionsCard(
                        isLoggingOut: _isLoggingOut,
                        onEditProfile: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileScreen(uid: user.uid),
                            ),
                          );
                          if (result == true) {
                            setState(_loadUser);
                          }
                        },
                        onHistory: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HistoricalTournamentsScreen(uid: user.uid),
                          ),
                        ),
                        onLogout: _handleLogout,
                      ),
                      const SizedBox(height: 20),

                      // ── Zona peligrosa ─────────────────────────────────────
                      _DangerZoneCard(
                        onDeleteAccount: _openDeleteAccountFlow,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF4D6A).withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFF4D6A),
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar el perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            _SoberButton(
              label: _isLoggingOut ? 'Cerrando sesión...' : 'Cerrar sesión',
              icon: Icons.logout_rounded,
              color: const Color(0xFFFF4D6A),
              onTap: _isLoggingOut ? null : _handleLogout,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Hero Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.user,
    required this.profile,
    required this.onEditTap,
  });

  final AppUser user;
  final PublicUserProfile? profile;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final fullName = '${user.name} ${user.lastName}'.trim();
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
    final hasPhoto = user.photoUrl != null && user.photoUrl!.trim().isNotEmpty;
    final memberSince = profile?.memberSince ?? user.createdAt;

    return _GlassPanel(
      padding: EdgeInsets.zero,
      borderRadius: 28,
      child: Stack(
        children: [
          // Glow decorativo
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00D4FF).withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    _AvatarWidget(
                      photoUrl: hasPhoto ? user.photoUrl!.trim() : null,
                      initial: initial,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName.isEmpty ? 'Mi Perfil' : fullName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                height: 1.08,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _SoftChip(
                              icon: Icons.alternate_email_rounded,
                              label: user.nickname.isEmpty
                                  ? 'sin-nickname'
                                  : user.nickname,
                              color: const Color(0xFF00D4FF),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Botón editar compacto
                    GestureDetector(
                      onTap: onEditTap,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Badge de tiempo en la app
                _SoftChip(
                  icon: Icons.bolt_rounded,
                  label: _memberSinceLabel(memberSince),
                  color: const Color(0xFFFFB347),
                ),
                // Bio
                if (user.biography != null &&
                    user.biography!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _BioBlock(text: user.biography!.trim()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _memberSinceLabel(DateTime? date) {
    if (date == null) return 'Miembro de Gromy';
    final now = DateTime.now();
    final months = math.max(
      0,
      (now.year - date.year) * 12 + now.month - date.month,
    );
    if (months >= 12) {
      final years = months ~/ 12;
      final rem = months % 12;
      final yLabel = years == 1 ? '1 año' : '$years años';
      if (rem == 0) return 'En Gromy desde hace $yLabel';
      final mLabel = rem == 1 ? '1 mes' : '$rem meses';
      return 'En Gromy desde hace $yLabel y $mLabel';
    }
    if (months > 0) {
      final mLabel = months == 1 ? '1 mes' : '$months meses';
      return 'En Gromy desde hace $mLabel';
    }
    return 'Miembro desde ${DateFormat('MMMM yyyy', 'es').format(date)}';
  }
}

class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({required this.initial, this.photoUrl});

  final String initial;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF00D4FF), Color(0xFFFF6B9D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.38),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF101127),
            image: photoUrl == null
                ? null
                : DecorationImage(
                    image: NetworkImage(photoUrl!),
                    fit: BoxFit.cover,
                  ),
          ),
          child: photoUrl == null
              ? Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _BioBlock extends StatelessWidget {
  const _BioBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              color: Color(0xFFB0A8FF),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Estadísticas personales
// ─────────────────────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.stats, required this.isLoading});

  final UserProfileStats stats;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.auto_graph_rounded,
          title: 'Mis estadísticas',
          subtitle: 'Rendimiento acumulado en torneos.',
          color: const Color(0xFF00D4FF),
        ),
        const SizedBox(height: 14),
        if (isLoading)
          _GlassPanel(
            borderRadius: 22,
            child: const SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00D4FF),
                ),
              ),
            ),
          )
        else
          _StatsGrid(stats: stats),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final UserProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricData(
        'Juegos',
        stats.totalPlayed.toString(),
        Icons.sports_score_rounded,
        const Color(0xFF00D4FF),
      ),
      _MetricData(
        'Win rate',
        '${stats.winRate}%',
        Icons.percent_rounded,
        const Color(0xFF22C55E),
      ),
      _MetricData(
        'Victorias',
        stats.wins.toString(),
        Icons.emoji_events_rounded,
        const Color(0xFFFFB347),
      ),
      _MetricData(
        'Torneos ganados',
        stats.tournamentsWon.toString(),
        Icons.workspace_premium_rounded,
        const Color(0xFFA855F7),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) => SizedBox(
                  width: (constraints.maxWidth - 10) / 2,
                  child: _MetricPill(data: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            data.color.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.032),
          ],
        ),
        border: Border.all(color: data.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: data.color.withValues(alpha: 0.14),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.52),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Historial de torneos (preview inline)
// ─────────────────────────────────────────────────────────────────────────────

class _TournamentHistorySection extends StatelessWidget {
  const _TournamentHistorySection({
    required this.history,
    required this.previewCount,
    required this.openingId,
    required this.isLoading,
    required this.onTap,
    required this.onSeeAll,
  });

  final List<UserTournamentHistoryEntry> history;
  final int previewCount;
  final String? openingId;
  final bool isLoading;
  final ValueChanged<UserTournamentHistoryEntry> onTap;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final preview = history.take(previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionTitle(
                icon: Icons.workspace_premium_rounded,
                title: 'Mis torneos',
                subtitle: 'Historial de participaciones.',
                color: const Color(0xFFFFB347),
              ),
            ),
            if (history.isNotEmpty)
              GestureDetector(
                onTap: onSeeAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFFFB347).withValues(alpha: 0.12),
                    border: Border.all(
                      color: const Color(0xFFFFB347).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver todos',
                        style: TextStyle(
                          color: Color(0xFFFFB347),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFFFFB347),
                        size: 11,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (isLoading)
          _GlassPanel(
            borderRadius: 22,
            child: const SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFFB347),
                ),
              ),
            ),
          )
        else if (history.isEmpty)
          _EmptyCard(
            icon: Icons.emoji_events_outlined,
            title: 'Aún no hay torneos',
            body: 'Aquí verás tu historial una vez hayas participado.',
          )
        else ...[
          ...preview.map(
            (entry) => _OwnTournamentCard(
              entry: entry,
              isLoading: openingId == entry.tournamentId,
              onTap: () => onTap(entry),
            ),
          ),
          if (history.length > previewCount) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onSeeAll,
              child: _GlassPanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                borderRadius: 18,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: Color(0xFFFFB347),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ver ${history.length - previewCount} torneos más',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _OwnTournamentCard extends StatelessWidget {
  const _OwnTournamentCard({
    required this.entry,
    required this.isLoading,
    required this.onTap,
  });

  final UserTournamentHistoryEntry entry;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sport = TournamentSport.fromValue(entry.sport ?? '');
    final accent = sportColor(sport);
    final status = _historyStatus(entry);
    final dateLabel = entry.scheduledAt == null
        ? 'Fecha por confirmar'
        : DateFormat('d MMM yyyy', 'es').format(entry.scheduledAt!);
    final hasCover =
        entry.coverImageUrl != null && entry.coverImageUrl!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: AnimatedScale(
          scale: isLoading ? 0.985 : 1,
          duration: const Duration(milliseconds: 140),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.09),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Thumbnail lateral
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                      child: SizedBox(
                        width: 80,
                        height: 90,
                        child: hasCover
                            ? Image.network(
                                entry.coverImageUrl!.trim(),
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, e, st) =>
                                    _SportPlaceholderTile(
                                  sport: sport,
                                  accent: accent,
                                ),
                              )
                            : _SportPlaceholderTile(
                                sport: sport,
                                accent: accent,
                              ),
                      ),
                    ),
                    // Contenido
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.tournamentName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                // Badge de resultado
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: status.color.withValues(alpha: 0.15),
                                    border: Border.all(
                                      color:
                                          status.color.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        status.icon,
                                        color: status.color,
                                        size: 11,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        status.label,
                                        style: TextStyle(
                                          color: status.color,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _InfoToken(
                                  icon: Icons.calendar_month_rounded,
                                  label: dateLabel,
                                ),
                                _InfoToken(
                                  icon: Icons.military_tech_rounded,
                                  label: entry.placementLabel.isEmpty
                                      ? status.label
                                      : entry.placementLabel,
                                ),
                                _InfoToken(
                                  icon: entry.tournamentStatus == 'completed'
                                      ? Icons.account_tree_rounded
                                      : Icons.open_in_new_rounded,
                                  label: entry.tournamentStatus == 'completed'
                                      ? 'Ver recorrido'
                                      : 'Ver detalles',
                                  color: accent,
                                ),
                              ],
                            ),
                            if (isLoading) ...[
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                minHeight: 2.5,
                                color: accent,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SportPlaceholderTile extends StatelessWidget {
  const _SportPlaceholderTile({required this.sport, required this.accent});

  final TournamentSport sport;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.35),
            const Color(0xFF11142F),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _sportIcon(sport),
          color: Colors.white.withValues(alpha: 0.3),
          size: 28,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Información de cuenta
// ─────────────────────────────────────────────────────────────────────────────

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${user.createdAt.day.toString().padLeft(2, '0')}/${user.createdAt.month.toString().padLeft(2, '0')}/${user.createdAt.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.manage_accounts_rounded,
          title: 'Cuenta',
          subtitle: 'Información de tu cuenta.',
          color: const Color(0xFF6C63FF),
        ),
        const SizedBox(height: 14),
        _GlassPanel(
          padding: EdgeInsets.zero,
          borderRadius: 22,
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'Correo electrónico',
                value: user.email,
                iconColor: const Color(0xFF6C63FF),
              ),
              _Divider(),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Miembro desde',
                value: dateStr,
                iconColor: const Color(0xFFFFB347),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: iconColor.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.48),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Acciones rápidas
// ─────────────────────────────────────────────────────────────────────────────

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({
    required this.isLoggingOut,
    required this.onEditProfile,
    required this.onHistory,
    required this.onLogout,
  });

  final bool isLoggingOut;
  final VoidCallback onEditProfile;
  final VoidCallback onHistory;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.settings_rounded,
          title: 'Ajustes rápidos',
          subtitle: 'Acciones de perfil y sesión.',
          color: const Color(0xFF22C55E),
        ),
        const SizedBox(height: 14),
        _GlassPanel(
          padding: EdgeInsets.zero,
          borderRadius: 22,
          child: Column(
            children: [
              _ActionTile(
                icon: Icons.edit_rounded,
                label: 'Editar perfil',
                subtitle: 'Nombre, foto, biografía…',
                iconColor: const Color(0xFF6C63FF),
                onTap: onEditProfile,
              ),
              _Divider(),
              _ActionTile(
                icon: Icons.history_rounded,
                label: 'Historial de torneos',
                subtitle: 'Ver todos los torneos en los que participé.',
                iconColor: const Color(0xFFFFB347),
                onTap: onHistory,
              ),
              _Divider(),
              _ActionTile(
                icon: Icons.logout_rounded,
                label: isLoggingOut ? 'Cerrando sesión…' : 'Cerrar sesión',
                subtitle: 'Salir de tu cuenta en este dispositivo.',
                iconColor: const Color(0xFFFF4D6A),
                onTap: isLoggingOut ? null : onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: iconColor.withValues(alpha: 0.06),
        highlightColor: iconColor.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: iconColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.42),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.25),
                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Zona peligrosa
// ─────────────────────────────────────────────────────────────────────────────

class _DangerZoneCard extends StatelessWidget {
  const _DangerZoneCard({required this.onDeleteAccount});

  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D6A).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFF4D6A).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFFF4D6A).withValues(alpha: 0.14),
                ),
                child: const Icon(
                  Icons.dangerous_rounded,
                  color: Color(0xFFFF8A8A),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Zona peligrosa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Text(
            'Elimina permanentemente tu cuenta y todos tus datos de la plataforma. Esta acción no se puede deshacer.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          _SoberButton(
            label: 'Eliminar cuenta',
            icon: Icons.delete_forever_rounded,
            color: const Color(0xFFFF4D6A),
            onTap: onDeleteAccount,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Botón sobrio (sin animaciones de gradiente)
// ─────────────────────────────────────────────────────────────────────────────

class _SoberButton extends StatelessWidget {
  const _SoberButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: color.withValues(alpha: 0.1),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Loading skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileLoadingSkeleton extends StatelessWidget {
  const _ProfileLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
      child: Column(
        children: [
          _GlassPanel(
            padding: const EdgeInsets.all(20),
            borderRadius: 28,
            child: Column(
              children: [
                Row(
                  children: [
                    const _Skeleton(width: 96, height: 96, radius: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _Skeleton(width: double.infinity, height: 24),
                          SizedBox(height: 10),
                          _Skeleton(width: 130, height: 20),
                          SizedBox(height: 8),
                          _Skeleton(width: 170, height: 18),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _Skeleton(width: double.infinity, height: 64),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _GlassPanel(
            borderRadius: 22,
            child: const _Skeleton(width: double.infinity, height: 150),
          ),
          const SizedBox(height: 20),
          _GlassPanel(
            borderRadius: 22,
            child: const _Skeleton(width: double.infinity, height: 200),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatefulWidget {
  const _Skeleton({required this.width, required this.height, this.radius = 14});

  final double width;
  final double height;
  final double radius;

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.035, end: 0.09).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          color: Colors.white.withValues(alpha: _anim.value),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.072),
                Colors.white.withValues(alpha: 0.025),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.07),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: color.withValues(alpha: 0.14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.44),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      borderRadius: 22,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C63FF).withValues(alpha: 0.22),
                  const Color(0xFF00D4FF).withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.55),
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.44),
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoToken extends StatelessWidget {
  const _InfoToken({
    required this.icon,
    required this.label,
    this.color = const Color(0xFFB0A8FF),
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Data class helpers
// ─────────────────────────────────────────────────────────────────────────────

class _MetricData {
  const _MetricData(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _HistoryVisualStatus {
  const _HistoryVisualStatus(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

_HistoryVisualStatus _historyStatus(UserTournamentHistoryEntry entry) {
  return switch (entry.resultStatus) {
    TournamentResultStatus.won => const _HistoryVisualStatus(
      'Ganado',
      Icons.emoji_events_rounded,
      Color(0xFFFFD166),
    ),
    TournamentResultStatus.eliminated => const _HistoryVisualStatus(
      'Eliminado',
      Icons.flag_rounded,
      Color(0xFFFF4D6A),
    ),
    TournamentResultStatus.pending => const _HistoryVisualStatus(
      'En curso',
      Icons.hourglass_top_rounded,
      Color(0xFF00D4FF),
    ),
    TournamentResultStatus.participated => const _HistoryVisualStatus(
      'Participado',
      Icons.check_circle_rounded,
      Color(0xFF6C63FF),
    ),
  };
}

IconData _sportIcon(TournamentSport sport) {
  return switch (sport) {
    TournamentSport.football => Icons.sports_soccer_rounded,
    TournamentSport.basketball => Icons.sports_basketball_rounded,
    TournamentSport.volleyball => Icons.sports_volleyball_rounded,
    TournamentSport.tennis => Icons.sports_tennis_rounded,
    TournamentSport.padel => Icons.sports_tennis_rounded,
    TournamentSport.karate => Icons.sports_martial_arts_rounded,
    TournamentSport.brazilianJiuJitsu => Icons.sports_mma_rounded,
  };
}
