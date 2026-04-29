import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/widgets/bar_small_botton.dart';
import '../../../../core/widgets/participant_card.dart';
import '../../../participants/data/models/participant_display.dart';
import '../../../participants/presentation/widgets/team_card.dart';
import '../controllers/participants_management_controller.dart';

class ParticipantsManagementScreen extends StatefulWidget {
  const ParticipantsManagementScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    required this.isTeamTournament,
    required this.categories,
  });

  final String tournamentId;
  final String tournamentName;
  final bool isTeamTournament;
  final List<String> categories;

  @override
  State<ParticipantsManagementScreen> createState() =>
      _ParticipantsManagementScreenState();
}

class _ParticipantsManagementScreenState
    extends State<ParticipantsManagementScreen>
    with SingleTickerProviderStateMixin {
  late final ParticipantsManagementController _ctrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = ParticipantsManagementController(
      tournamentId: widget.tournamentId,
      categories: widget.categories,
    )..addListener(_onCtrlChanged);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _ctrl.load();
  }

  void _onCtrlChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_onCtrlChanged)
      ..dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFFF4D6A)
            : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<bool> _confirmRemove() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _DarkDialog(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFFF4D6A),
        title: 'Eliminar participante',
        content: '¿Seguro que quieres eliminar este participante?',
        confirmLabel: 'Eliminar',
      ),
    );
    return result == true;
  }

  Future<void> _removeParticipant(ParticipantDisplay participant) async {
    if (!await _confirmRemove()) return;

    final ok = await _ctrl.removeParticipant(participant.participantId);
    _showSnack(
      ok
          ? 'Participante eliminado'
          : (_ctrl.errorMessage ?? 'No se pudo eliminar el participante'),
      isError: !ok,
    );
  }

  Future<void> _showCategoryDialog(ParticipantDisplay participant) async {
    if (widget.categories.isEmpty) return;

    var selected = participant.categoryId;
    if (selected == null || !widget.categories.contains(selected)) {
      selected = widget.categories.first;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        var localSelected = selected!;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF101127),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.tune_rounded, color: Color(0xFF6C63FF)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cambiar categoría',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categoría actual',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    participant.categoryId ?? 'Sin categoría',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...widget.categories.map((category) {
                    final isSelected = localSelected == category;
                    return InkWell(
                      onTap: () =>
                          setDialogState(() => localSelected = category),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: isSelected
                                  ? const Color(0xFF6C63FF)
                                  : Colors.white38,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                category,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, localSelected),
                  child: const Text(
                    'Confirmar',
                    style: TextStyle(
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || result == participant.categoryId) return;
    final ok = await _ctrl.updateCategory(
      participantId: participant.participantId,
      categoryId: result,
    );
    _showSnack(
      ok
          ? 'Categoría actualizada'
          : (_ctrl.errorMessage ?? 'No se pudo cambiar la categoría'),
      isError: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Background(),
          SafeArea(
            child: FadeTransition(opacity: _fadeAnim, child: _buildBody()),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AppBar(
            backgroundColor: const Color(0xFF0A0A1A).withValues(alpha: 0.7),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: BarSmallBotton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Gestionar participantes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.tournamentName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_ctrl.isLoading) {
      return const _LoadingView();
    }

    if (_ctrl.errorMessage != null && _ctrl.participants.isEmpty) {
      return _ErrorView(message: _ctrl.errorMessage!, onRetry: _ctrl.load);
    }

    if (_ctrl.participants.isEmpty) {
      return _EmptyView(isTeamTournament: widget.isTeamTournament);
    }

    return _ParticipantsManagementList(
      participants: _ctrl.participants,
      categories: widget.categories,
      isTeamTournament: widget.isTeamTournament,
      isRemoving: _ctrl.isRemoving,
      isUpdatingCategory: _ctrl.isUpdatingCategory,
      onRemove: _removeParticipant,
      onChangeCategory: _showCategoryDialog,
    );
  }
}

class _ParticipantsManagementList extends StatelessWidget {
  const _ParticipantsManagementList({
    required this.participants,
    required this.categories,
    required this.isTeamTournament,
    required this.isRemoving,
    required this.isUpdatingCategory,
    required this.onRemove,
    required this.onChangeCategory,
  });

  final List<ParticipantDisplay> participants;
  final List<String> categories;
  final bool isTeamTournament;
  final bool Function(String participantId) isRemoving;
  final bool Function(String participantId) isUpdatingCategory;
  final ValueChanged<ParticipantDisplay> onRemove;
  final ValueChanged<ParticipantDisplay> onChangeCategory;

  static const _withoutCategory = '__without_category__';

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return _FlatList(
        participants: participants,
        hasCategories: false,
        isTeamTournament: isTeamTournament,
        isRemoving: isRemoving,
        isUpdatingCategory: isUpdatingCategory,
        onRemove: onRemove,
        onChangeCategory: onChangeCategory,
      );
    }

    final grouped = <String, List<ParticipantDisplay>>{};
    for (final participant in participants) {
      final key = participant.categoryId ?? _withoutCategory;
      grouped.putIfAbsent(key, () => []).add(participant);
    }

    final orderedKeys = [
      ...categories.where(grouped.containsKey),
      if (grouped.containsKey(_withoutCategory)) _withoutCategory,
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: orderedKeys.length,
      itemBuilder: (context, sectionIndex) {
        final key = orderedKeys[sectionIndex];
        final items = grouped[key]!;
        final label = key == _withoutCategory ? 'Sin categoría' : key;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sectionIndex > 0) const SizedBox(height: 24),
            _CategoryHeader(label: label, count: items.length),
            const SizedBox(height: 12),
            ...items.map(
              (participant) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ParticipantManagementItem(
                  participant: participant,
                  hasCategories: true,
                  isTeamTournament: isTeamTournament,
                  isRemoving: isRemoving(participant.participantId),
                  isUpdatingCategory: isUpdatingCategory(
                    participant.participantId,
                  ),
                  onRemove: () => onRemove(participant),
                  onChangeCategory: () => onChangeCategory(participant),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FlatList extends StatelessWidget {
  const _FlatList({
    required this.participants,
    required this.hasCategories,
    required this.isTeamTournament,
    required this.isRemoving,
    required this.isUpdatingCategory,
    required this.onRemove,
    required this.onChangeCategory,
  });

  final List<ParticipantDisplay> participants;
  final bool hasCategories;
  final bool isTeamTournament;
  final bool Function(String participantId) isRemoving;
  final bool Function(String participantId) isUpdatingCategory;
  final ValueChanged<ParticipantDisplay> onRemove;
  final ValueChanged<ParticipantDisplay> onChangeCategory;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: participants.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final participant = participants[index];
        return _ParticipantManagementItem(
          participant: participant,
          hasCategories: hasCategories,
          isTeamTournament: isTeamTournament,
          isRemoving: isRemoving(participant.participantId),
          isUpdatingCategory: isUpdatingCategory(participant.participantId),
          onRemove: () => onRemove(participant),
          onChangeCategory: () => onChangeCategory(participant),
        );
      },
    );
  }
}

class _ParticipantManagementItem extends StatelessWidget {
  const _ParticipantManagementItem({
    required this.participant,
    required this.hasCategories,
    required this.isTeamTournament,
    required this.isRemoving,
    required this.isUpdatingCategory,
    required this.onRemove,
    required this.onChangeCategory,
  });

  final ParticipantDisplay participant;
  final bool hasCategories;
  final bool isTeamTournament;
  final bool isRemoving;
  final bool isUpdatingCategory;
  final VoidCallback onRemove;
  final VoidCallback onChangeCategory;

  @override
  Widget build(BuildContext context) {
    final isBusy = isRemoving || isUpdatingCategory;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: switch (participant) {
            UserParticipantDisplay(:final user) => ParticipantCard(
              nickname: user.nickname,
              displayName: '${user.name} ${user.lastName}'.trim(),
              photoUrl: user.photoUrl,
            ),
            TeamParticipantDisplay(:final team) => TeamCard(team: team),
          },
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            BarSmallBotton(
              icon: isRemoving
                  ? Icons.hourglass_top_rounded
                  : Icons.delete_outline_rounded,
              iconColor: const Color(0xFFFF4D6A),
              backgroundColor: const Color(0xFFFF4D6A).withValues(alpha: 0.14),
              onTap: isBusy ? () {} : onRemove,
            ),
            if (hasCategories) ...[
              const SizedBox(height: 8),
              BarSmallBotton(
                icon: isUpdatingCategory
                    ? Icons.hourglass_top_rounded
                    : Icons.tune_rounded,
                iconColor: const Color(0xFF6C63FF),
                backgroundColor: const Color(
                  0xFF6C63FF,
                ).withValues(alpha: 0.14),
                onTap: isBusy ? () {} : onChangeCategory,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.07),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DarkDialog extends StatelessWidget {
  const _DarkDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
    required this.confirmLabel,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF101127),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      title: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      content: Text(content, style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.white54),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmLabel,
            style: TextStyle(color: iconColor, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando participantes...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.isTeamTournament});

  final bool isTeamTournament;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isTeamTournament
                  ? Icons.groups_2_outlined
                  : Icons.person_search_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              isTeamTournament
                  ? 'Aún no hay equipos inscritos'
                  : 'Aún no hay participantes',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0A1A), Color(0xFF0D0D2B), Color(0xFF12122E)],
        ),
      ),
    );
  }
}
