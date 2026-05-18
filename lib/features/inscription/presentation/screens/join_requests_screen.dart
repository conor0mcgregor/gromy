import 'package:flutter/material.dart';
import '../../../../core/widgets/bar_small_botton.dart';
import '../../../../core/widgets/join_request_card.dart';
import '../../../../features/inscription/domain/models/join_request.dart';
import '../../../../features/tournament/data/model/app_tournament.dart';
import '../controllers/join_requests_controller.dart';

class JoinRequestsScreen extends StatefulWidget {
  const JoinRequestsScreen({super.key, required this.tournament, required this.currentUserId});
  final AppTournament tournament;
  final String currentUserId;
  @override
  State<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends State<JoinRequestsScreen> {
  late final JoinRequestsController _ctrl;
  bool _showAll = false;
  static const Color _bg = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _ctrl = JoinRequestsController(tournament: widget.tournament, currentUserId: widget.currentUserId);
    _ctrl.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: BarSmallBotton(icon: Icons.arrow_back_ios_new, onTap: () => Navigator.of(context).maybePop()),
        title: Text('Solicitudes', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          Padding(padding: const EdgeInsets.only(right: 8), child: TextButton(
            onPressed: () => setState(() => _showAll = !_showAll),
            child: Text(_showAll ? 'Pendientes' : 'Todas', style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 13, fontWeight: FontWeight.w600)),
          )),
        ],
      ),
      body: StreamBuilder<List<JoinRequest>>(
        stream: _showAll ? _ctrl.watchAllRequests() : _ctrl.watchPendingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inbox_rounded, color: Colors.white.withValues(alpha: 0.15), size: 64),
              const SizedBox(height: 16),
              Text(_showAll ? 'No hay solicitudes.' : 'No hay solicitudes pendientes.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 15)),
            ]));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Padding(padding: const EdgeInsets.only(bottom: 12), child: FutureBuilder<String>(
                future: _ctrl.getEntityName(request),
                builder: (context, nameSnap) => JoinRequestCard(
                  request: request, entityName: nameSnap.data,
                  isLoading: _ctrl.processingIds.contains(request.id),
                  onApprove: () => _ctrl.approveRequest(request),
                  onReject: () => _showRejectDialog(request),
                ),
              ));
            },
          );
        },
      ),
    );
  }

  Future<void> _showRejectDialog(JoinRequest request) async {
    final rc = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Rechazar solicitud', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      content: TextField(controller: rc, maxLines: 3, style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(hintText: 'Motivo (opcional)', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          filled: true, fillColor: Colors.white.withValues(alpha: 0.06), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rechazar', style: TextStyle(color: Color(0xFFFF4D6A), fontWeight: FontWeight.w700))),
      ],
    ));
    if (confirmed == true) { _ctrl.rejectRequest(request, reason: rc.text.trim().isNotEmpty ? rc.text.trim() : null); }
    rc.dispose();
  }
}
