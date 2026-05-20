import 'package:flutter/material.dart';

import '../../../../core/getColors/getter_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../data/models/account_deletion_result.dart';
import '../controllers/delete_account_controller.dart';
import 'blocking_reason_card.dart';
import 'delete_account_warning_card.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  late final DeleteAccountController _controller;
  final _passwordController = TextEditingController();
  bool _accepted = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = DeleteAccountController()..addListener(_onChange);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _delete() async {
    final password = _controller.requiresPassword
        ? _passwordController.text
        : null;
    final result = await _controller.deleteAccount(password: password);
    if (!mounted) return;

    switch (result) {
      case AccountDeletionSuccess():
        Navigator.of(context).pop(true);
      case AccountDeletionBlocked(:final message):
      case AccountDeletionFailure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFFFF4D6A),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final needsPassword = _controller.requiresPassword;
    final passwordReady = !needsPassword || _passwordController.text.isNotEmpty;
    final canSubmit =
        state?.canDelete == true &&
        _accepted &&
        passwordReady &&
        !_controller.isDeleting;

    return Dialog(
      backgroundColor: const Color(0xFF15152B),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.delete_forever_rounded,
                    color: Color(0xFFFF8A8A),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Eliminar cuenta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _controller.isDeleting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white70,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const DeleteAccountWarningCard(),
              const SizedBox(height: 18),
              if (_controller.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
                  ),
                )
              else if (_controller.errorMessage != null && state == null)
                Text(
                  _controller.errorMessage!,
                  style: const TextStyle(color: Color(0xFFFF8A8A)),
                )
              else if (state != null) ...[
                if (!state.canDelete) ...[
                  const Text(
                    'No puedes eliminar la cuenta todavia. Revisa los motivos indicados.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...state.blockingReasons.map(
                    (reason) => BlockingReasonCard(reason: reason),
                  ),
                ] else ...[
                  const Text(
                    'Se eliminaran tu cuenta y todos tus datos de la plataforma. Esta accion no se puede deshacer.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (needsPassword) ...[
                    if (_controller.userEmail != null)
                      Text(
                        'Confirma con la contrasena de ${_controller.userEmail}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !_controller.isDeleting,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Contrasena actual',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ] else
                    const Text(
                      'Al confirmar, se desvinculara totalmente la cuneta con la plataforma.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                ],
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _accepted,
                  onChanged: state.canDelete && !_controller.isDeleting
                      ? (value) => setState(() => _accepted = value ?? false)
                      : null,
                  activeColor: const Color(0xFFFF4D6A),
                  checkColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Entiendo que mi cuenta y datos se eliminaran permanentemente.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _controller.isDeleting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GradientButton(
                        onPressed: canSubmit ? _delete : null,
                        label: _controller.isDeleting
                            ? 'Eliminando...'
                            : 'Eliminar mi cuenta',
                        isLoading: _controller.isDeleting,
                        icon: Icons.delete_forever_rounded,
                        variant: GradientButtonVariant.danger,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
