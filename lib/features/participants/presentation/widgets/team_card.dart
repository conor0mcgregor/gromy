import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/widgets/participant_card.dart';
import '../../../../database/team/models/app_team.dart';
import '../../../../features/user/data/models/app_user.dart';
import '../../../../features/user/data/services/firestore_user_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TeamCard  ·  Widget expandible para equipos en la lista de participantes
//
//  Muestra la cabecera del equipo (foto + nombre + nº miembros) y al pulsar
//  expande para mostrar la lista de miembros usando ParticipantCard.
//
//  La carga de usuarios es lazy: solo ocurre la primera vez que se expande,
//  evitando peticiones innecesarias si el usuario no abre el card.
// ─────────────────────────────────────────────────────────────────────────────

class TeamCard extends StatefulWidget {
  const TeamCard({
    super.key,
    required this.team,
    this.initiallyExpanded = false,
  });

  final AppTeam team;
  final bool initiallyExpanded;

  @override
  State<TeamCard> createState() => _TeamCardState();
}

class _TeamCardState extends State<TeamCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  bool _hasLoadedMembers = false;
  bool _isLoadingMembers = false;

  final _userService = FirestoreUserService();
  final Map<String, AppUser?> _memberCache = {};

  late final AnimationController _ctrl;
  late final Animation<double> _expandAnim;
  late final Animation<double> _arrowAnim;
  late final Animation<double> _fadeAnim;

  static const _accentColor = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: _isExpanded ? 1.0 : 0.0,
    );

    _expandAnim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeInOutCubic,
    );

    _arrowAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    if (_isExpanded) _loadMembers();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    if (_hasLoadedMembers || _isLoadingMembers) return;
    if (!mounted) return;
    setState(() => _isLoadingMembers = true);

    for (final uid in widget.team.members) {
      if (!_memberCache.containsKey(uid)) {
        try {
          _memberCache[uid] = await _userService.getUser(uid);
        } catch (_) {
          _memberCache[uid] = null;
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingMembers = false;
        _hasLoadedMembers = true;
      });
    }
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _ctrl.forward();
      _loadMembers();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: 0.08 + _expandAnim.value * 0.06,
                  ),
                  width: 1.1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Cabecera (siempre visible) ─────────────────────
                  _buildHeader(),

                  // ── Lista de miembros (expandible) ─────────────────
                  SizeTransition(
                    sizeFactor: _expandAnim,
                    axisAlignment: -1,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildMembersList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final hasPhoto =
        widget.team.photoUrl != null && widget.team.photoUrl!.isNotEmpty;
    final initial = widget.team.name.isNotEmpty
        ? widget.team.name[0].toUpperCase()
        : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(18),
        splashColor: _accentColor.withValues(alpha: 0.06),
        highlightColor: _accentColor.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // ── Avatar del equipo ────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasPhoto
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                        ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: hasPhoto
                      ? Image.network(
                          widget.team.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _buildTeamInitial(initial),
                        )
                      : _buildTeamInitial(initial),
                ),
              ),
              const SizedBox(width: 14),

              // ── Nombre e info ───────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.team.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.team.members.length} miembro${widget.team.members.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Badge equipo ────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: _accentColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'EQUIPO',
                  style: TextStyle(
                    color: Color(0xFFB0A8FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // ── Flecha ──────────────────────────────────────────
              RotationTransition(
                turns: _arrowAnim,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamInitial(String initial) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divisor
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          color: Colors.white.withValues(alpha: 0.07),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label "Miembros"
              Text(
                'Miembros del equipo',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              if (_isLoadingMembers)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                )
              else
                ...widget.team.members.map((uid) {
                  final user = _memberCache[uid];
                  final isAdmin = widget.team.isAdmin(uid);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ParticipantCard(
                      nickname: user?.nickname ?? uid,
                      displayName: user != null
                          ? '${user.name} ${user.lastName}'.trim()
                          : 'Usuario desconocido',
                      photoUrl: user?.photoUrl,
                      trailing: isAdmin
                          ? _AdminBadge()
                          : null,
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Admin badge pequeño ──────────────────────────────────────────────────────

class _AdminBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF6C63FF).withValues(alpha: 0.18),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.admin_panel_settings_rounded,
            size: 11,
            color: Color(0xFFB0A8FF),
          ),
          SizedBox(width: 3),
          Text(
            'Admin',
            style: TextStyle(
              color: Color(0xFFB0A8FF),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
