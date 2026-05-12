import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/bracket_repository.dart';
import '../../data/services/firestore_bracket_service.dart';
import '../screens/bracket_not_published_screen.dart';
import '../screens/bracket_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  BracketsSection  ·  Widget reutilizable
//
//  Card que aparece en preinscription_screen para navegar al bracket.
//  - Si el bracket está publicado → abre BracketScreen
//  - Si no está publicado → abre BracketNotPublishedScreen
// ─────────────────────────────────────────────────────────────────────────────

class BracketsSection extends StatefulWidget {
  const BracketsSection({
    super.key,
    required this.tournamentId,
    this.isAdmin = false,
  });

  final String tournamentId;
  final bool isAdmin;

  @override
  State<BracketsSection> createState() => _BracketsSectionState();
}

class _BracketsSectionState extends State<BracketsSection> {
  // Constantes de diseño
  static const _borderRadius = 20.0;
  static const _primaryColor = Color(0xFF27D3F5);
  static const _iconSize = 18.0;
  static const _iconContainerSize = 36.0;

  // Colores con opacidad
  Color get _splashColor => _primaryColor.withValues(alpha: 0.1);
  Color get _highlightColor => _primaryColor.withValues(alpha: 0.05);
  Color get _containerColor => Colors.white.withValues(alpha: 0.05);
  Color get _borderColor => Colors.white.withValues(alpha: 0.08);
  Color get _iconBackgroundColor => _primaryColor.withValues(alpha: 0.15);
  Color get _textColor => Colors.white.withValues(alpha: 0.9);
  Color get _chevronColor => Colors.white.withValues(alpha: 0.3);

  // Estado del bracket
  late final BracketRepository _repository;
  bool _hasPublishedBracket = false;
  bool _hasDraftBracket = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _repository = FirestoreBracketService();
    _watchBracketStatus();
  }

  void _watchBracketStatus() {
    _subscription = _repository.watchBrackets(widget.tournamentId).listen((
      brackets,
    ) {
      if (!mounted) return;
      setState(() {
        _hasPublishedBracket = brackets.any((b) => b.status.isPubliclyVisible);
        _hasDraftBracket = brackets.any((b) => b.status.isDraft);
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _navigateToBracket() {
    if (widget.isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BracketScreen(tournamentId: widget.tournamentId, isAdmin: true),
        ),
      );
    } else if (_hasPublishedBracket) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BracketScreen(
            tournamentId: widget.tournamentId,
            isAdmin: widget.isAdmin,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BracketNotPublishedScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent, child: _buildInkWell());
  }

  Widget _buildInkWell() {
    return InkWell(
      borderRadius: BorderRadius.circular(_borderRadius),
      splashColor: _splashColor,
      highlightColor: _highlightColor,
      onTap: _navigateToBracket,
      child: _buildClipRect(),
    );
  }

  Widget _buildClipRect() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_borderRadius),
      child: _buildContainer(),
    );
  }

  Widget _buildContainer() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        color: _containerColor,
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (_hasPublishedBracket || _hasDraftBracket) ...[
            const SizedBox(height: 10),
            _buildStatusIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildIconContainer(),
        const SizedBox(width: 12),
        _buildTitle(),
        const SizedBox(width: 6),
        _buildChevron(),
      ],
    );
  }

  Widget _buildIconContainer() {
    return Container(
      width: _iconContainerSize,
      height: _iconContainerSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        color: _iconBackgroundColor,
      ),
      child: const Icon(
        Icons.account_tree,
        size: _iconSize,
        color: _primaryColor,
      ),
    );
  }

  Widget _buildTitle() {
    return Expanded(
      child: Text(
        'Enfrentamientos',
        style: TextStyle(
          color: _textColor,
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildChevron() {
    return Icon(
      Icons.chevron_right_rounded,
      size: _iconSize,
      color: _chevronColor,
    );
  }

  Widget _buildStatusIndicator() {
    final Color statusColor;
    final String statusText;

    if (_hasPublishedBracket) {
      statusColor = const Color(0xFF22C55E);
      statusText = 'Disponible';
    } else if (_hasDraftBracket && widget.isAdmin) {
      statusColor = const Color(0xFFF59E0B);
      statusText = 'Borrador';
    } else {
      statusColor = Colors.white.withValues(alpha: 0.3);
      statusText = 'Pendiente';
    }

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
        ),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
