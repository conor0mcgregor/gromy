import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/widgets/bar_small_botton.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/getColors/getter_colors.dart';
import '../../../../core/widgets/account_deletion_widgets.dart';
import '../controllers/delete_account_controller.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key, required this.userId});
  final String userId;
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  late final DeleteAccountController _ctrl;
  static const Color _bg = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _ctrl = DeleteAccountController(userId: widget.userId);
    _ctrl.addListener(() { if (mounted) setState(() {}); });
    _ctrl.checkEligibility();
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
        title: Text('Eliminar cuenta', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 18, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_ctrl.checkState == DeletionCheckState.checking) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
    }
    if (_ctrl.executeState == DeletionExecuteState.success) {
      return _buildSuccessState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Warning icon
        Center(child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF4D6A).withValues(alpha: 0.1)),
          child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFFF4D6A), size: 48),
        )),
        const SizedBox(height: 24),
        Center(child: Text('¿Estás seguro?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 24, fontWeight: FontWeight.w800))),
        const SizedBox(height: 8),
        Center(child: Text('Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14))),
        const SizedBox(height: 28),

        // Warning card
        const DeleteAccountWarningCard(),
        const SizedBox(height: 20),

        // Blocking reasons
        if (_ctrl.eligibility != null && _ctrl.eligibility!.hasBlockingReasons) ...[
          Text('No puedes eliminar la cuenta todavía',
            style: TextStyle(color: const Color(0xFFFF4D6A).withValues(alpha: 0.9), fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...(_ctrl.eligibility!.blockingReasons.map((r) => BlockingReasonCard(reason: r))),
          const SizedBox(height: 20),
        ],

        // Confirmation checkbox
        if (_ctrl.eligibility != null && _ctrl.eligibility!.canDelete) ...[
          GestureDetector(
            onTap: () => _ctrl.toggleConfirmation(!_ctrl.confirmationChecked),
            child: Row(children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _ctrl.confirmationChecked ? const Color(0xFFFF4D6A) : Colors.white.withValues(alpha: 0.2), width: 1.5),
                  color: _ctrl.confirmationChecked ? const Color(0xFFFF4D6A).withValues(alpha: 0.2) : Colors.transparent,
                ),
                child: _ctrl.confirmationChecked ? const Icon(Icons.check_rounded, color: Color(0xFFFF4D6A), size: 16) : null,
              ),
              const SizedBox(width: 12),
              Flexible(child: Text('Entiendo las consecuencias y deseo eliminar mi cuenta.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13))),
            ]),
          ),
          const SizedBox(height: 24),
          // Delete button
          GradientButton(
            label: 'Eliminar mi cuenta',
            icon: Icons.delete_forever_rounded,
            variant: GradientButtonVariant.sunset,
            isLoading: _ctrl.executeState == DeletionExecuteState.executing,
            onPressed: _ctrl.canDelete ? () => _ctrl.executeDelete() : null,
          ),
        ],

        // Error
        if (_ctrl.error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFFFF4D6A).withValues(alpha: 0.1)),
            child: Text(_ctrl.error!, style: const TextStyle(color: Color(0xFFFF4D6A), fontSize: 13)),
          ),
        ],
      ]),
    );
  }

  Widget _buildSuccessState() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF22C55E), size: 64),
      const SizedBox(height: 20),
      Text('Cuenta eliminada', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Text('Tu cuenta ha sido eliminada correctamente.', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14)),
    ]));
  }
}
