import 'package:flutter/material.dart';

import '../../../core/widgets/bar_small_botton.dart';
import '../../tournament/data/model/app_tournament.dart';
import '../data/models/join_request.dart';
import '../presentation/controllers/tournament_join_requests_controller.dart';
import '../presentation/models/join_request_display.dart';
import '../presentation/widgets/join_request_card.dart';

class TournamentJoinRequestsScreen extends StatefulWidget {
  const TournamentJoinRequestsScreen({super.key, required this.tournament});

  final AppTournament tournament;

  @override
  State<TournamentJoinRequestsScreen> createState() =>
      _TournamentJoinRequestsScreenState();
}

class _TournamentJoinRequestsScreenState
    extends State<TournamentJoinRequestsScreen> {
  late final TournamentJoinRequestsController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TournamentJoinRequestsController(tournament: widget.tournament)
          ..addListener(_onChange)
          ..init();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChange)
      ..dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFFF4D6A)
            : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _approve(JoinRequestDisplay display) async {
    final ok = await _confirm(
      title: 'Aprobar solicitud',
      message: 'Se creara una inscripcion activa para ${display.title}.',
      confirmLabel: 'Aprobar',
    );
    if (ok != true) return;
    final success = await _controller.approve(display.request.id);
    _showSnack(
      success
          ? 'Solicitud aprobada correctamente.'
          : _controller.errorMessage ?? 'No se pudo aprobar.',
      isError: !success,
    );
  }

  Future<void> _reject(JoinRequestDisplay display) async {
    final reason = await _askRejectReason();
    if (reason == null) return;
    final success = await _controller.reject(
      display.request.id,
      reason: reason,
    );
    _showSnack(
      success
          ? 'Solicitud rechazada correctamente.'
          : _controller.errorMessage ?? 'No se pudo rechazar.',
      isError: !success,
    );
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<String?> _askRejectReason() {
    final controller = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text(
          'Rechazar solicitud',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Motivo opcional',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  void _showDetails(JoinRequestDisplay display) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111827),
      showDragHandle: true,
      builder: (context) {
        final responses = display.request.responses;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  display.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                if (responses.isEmpty)
                  const Text(
                    'Sin respuestas adicionales.',
                    style: TextStyle(color: Colors.white60),
                  )
                else
                  for (final response in responses) ...[
                    Text(
                      response.fieldLabelSnapshot,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      response.value.toString(),
                      style: const TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: BarSmallBotton(
          icon: Icons.arrow_back_ios_new,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Solicitudes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _Filters(controller: _controller),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return switch (_controller.state) {
      JoinRequestsLoadState.loading => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      ),
      JoinRequestsLoadState.error => _MessageState(
        icon: Icons.error_outline_rounded,
        message: _controller.errorMessage ?? 'No se pudieron cargar.',
      ),
      JoinRequestsLoadState.empty => const _MessageState(
        icon: Icons.inbox_rounded,
        message: 'No hay solicitudes pendientes.',
      ),
      JoinRequestsLoadState.loaded => ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        itemCount: _controller.requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final display = _controller.requests[index];
          return JoinRequestCard(
            display: display,
            isProcessing: _controller.isProcessing(display.request.id),
            onApprove: () => _approve(display),
            onReject: () => _reject(display),
            onTap: () => _showDetails(display),
          );
        },
      ),
    };
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.controller});

  final TournamentJoinRequestsController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _chip(context, 'Pendientes', JoinRequestStatus.pending),
          _chip(context, 'Aprobadas', JoinRequestStatus.approved),
          _chip(context, 'Rechazadas', JoinRequestStatus.rejected),
          _chip(context, 'Todas', null),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, JoinRequestStatus? status) {
    final selected = controller.statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) => controller.watch(status),
        selectedColor: const Color(0xFF6C63FF),
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white38, size: 52),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
