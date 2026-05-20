import 'package:flutter/material.dart';

import '../../../core/getColors/getter_colors.dart';
import '../../../core/widgets/bar_small_botton.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../database/participant/models/app_participant.dart';
import '../../../features/tournament/data/model/app_tournament.dart';
import '../domain/use_cases/edit_inscription_use_case.dart';
import '../presentation/controllers/edit_inscription_controller.dart';
import '../presentation/widgets/dynamic_registration_field.dart';

class EditInscriptionScreen extends StatefulWidget {
  const EditInscriptionScreen({
    super.key,
    required this.tournament,
    required this.participant,
  });

  final AppTournament tournament;
  final AppParticipant participant;

  @override
  State<EditInscriptionScreen> createState() => _EditInscriptionScreenState();
}

class _EditInscriptionScreenState extends State<EditInscriptionScreen> {
  late final EditInscriptionController _ctrl;
  late final TextEditingController _notesController;
  late final TextEditingController _complementaryController;

  static const _bg = Color(0xFF0F172A);
  static const _accent = Color(0xFF6C63FF);
  static const _error = Color(0xFFFF4D6A);

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _complementaryController = TextEditingController();
    _ctrl = EditInscriptionController(
      tournament: widget.tournament,
      initialParticipant: widget.participant,
    );
    _ctrl.addListener(_onControllerChanged);
    _ctrl.initialize();
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_onControllerChanged)
      ..dispose();
    _notesController.dispose();
    _complementaryController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (_notesController.text != _ctrl.notes) {
      _notesController.text = _ctrl.notes;
    }
    if (_complementaryController.text != _ctrl.complementaryInfo) {
      _complementaryController.text = _ctrl.complementaryInfo;
    }
    setState(() {});

    if (_ctrl.submitState == EditInscriptionSubmitState.success) {
      final message = _ctrl.lastSaveRequiredReview
          ? 'Tus cambios se han guardado y quedan pendientes de revision por el organizador.'
          : 'Inscripcion actualizada correctamente.';
      _showSnack(message, isError: false);
      Navigator.of(context).pop(true);
    } else if (_ctrl.submitState == EditInscriptionSubmitState.error &&
        _ctrl.submitError != null) {
      _showSnack(_ctrl.submitError!, isError: true);
      _ctrl.resetSubmitState();
    }
  }

  Future<bool> _confirmLeave() async {
    if (!_ctrl.hasUnsavedChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Descartar cambios',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tienes cambios sin guardar. Si sales ahora se perderan.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Salir',
              style: TextStyle(color: _error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return result == true;
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _error : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmLeave() && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          leading: BarSmallBotton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () async {
              final navigator = Navigator.of(context);
              if (await _confirmLeave() && mounted) {
                navigator.maybePop();
              }
            },
          ),
          title: const Text(
            'Editar inscripcion',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return switch (_ctrl.loadState) {
      EditInscriptionLoadState.idle ||
      EditInscriptionLoadState.loading => const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5, color: _accent),
      ),
      EditInscriptionLoadState.error => _MessageState(
        icon: Icons.error_outline_rounded,
        title: 'No se pudo cargar',
        message: _ctrl.loadError ?? 'Error desconocido',
        color: _error,
      ),
      EditInscriptionLoadState.loaded => _buildLoaded(),
    };
  }

  Widget _buildLoaded() {
    final availability = _ctrl.availability;
    final warning = availability?.reason.message ?? '';
    final isSaving = _ctrl.submitState == EditInscriptionSubmitState.submitting;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TournamentHeader(tournament: widget.tournament),
          const SizedBox(height: 20),
          if (warning.isNotEmpty)
            _StatusBanner(
              message: warning,
              isBlocking: availability?.canEdit != true,
            ),
          if (warning.isNotEmpty) const SizedBox(height: 20),
          _SectionTitle(
            label: 'Datos no editables',
            icon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 12),
          _LockedDataCard(participant: _ctrl.participant!),
          const SizedBox(height: 24),
          _SectionTitle(
            label: 'Informacion complementaria',
            icon: Icons.notes_rounded,
          ),
          const SizedBox(height: 12),
          _TextArea(
            controller: _notesController,
            label: 'Observaciones',
            enabled: _ctrl.canEdit,
            onChanged: _ctrl.updateNotes,
          ),
          const SizedBox(height: 12),
          _TextArea(
            controller: _complementaryController,
            label: 'Informacion complementaria',
            enabled: _ctrl.canEdit,
            onChanged: _ctrl.updateComplementaryInfo,
          ),
          if (_ctrl.hasAdditionalFields) ...[
            const SizedBox(height: 24),
            _SectionTitle(
              label: 'Campos adicionales',
              icon: Icons.dynamic_form_rounded,
            ),
            const SizedBox(height: 12),
            _AdditionalFieldsSection(ctrl: _ctrl),
          ],
          if (!_ctrl.hasAdditionalFields) ...[
            const SizedBox(height: 24),
            const _MessageState(
              icon: Icons.fact_check_outlined,
              title: 'Sin campos adicionales',
              message: 'Esta inscripcion no tiene respuestas dinamicas.',
              color: _accent,
              compact: true,
            ),
          ],
          const SizedBox(height: 28),
          if (_ctrl.registrationErrors.isNotEmpty)
            const _HintRow(
              text: 'Completa los campos obligatorios antes de guardar.',
              color: _error,
            ),
          GradientButton(
            label: isSaving ? 'Guardando...' : 'Guardar cambios',
            icon: isSaving ? Icons.hourglass_top_rounded : Icons.save_rounded,
            isLoading: isSaving,
            variant: GradientButtonVariant.forest,
            size: GradientButtonSize.large,
            onPressed: _ctrl.canSubmit ? _ctrl.save : null,
          ),
        ],
      ),
    );
  }
}

class _AdditionalFieldsSection extends StatelessWidget {
  const _AdditionalFieldsSection({required this.ctrl});

  final EditInscriptionController ctrl;

  @override
  Widget build(BuildContext context) {
    final fields = ctrl.registrationForm.activeFields;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            DynamicRegistrationField(
              field: fields[i],
              value: ctrl.registrationValues[fields[i].id],
              errorText: ctrl.registrationErrors[fields[i].id],
              enabled: ctrl.canEdit,
              onChanged: (value) =>
                  ctrl.updateRegistrationValue(fields[i].id, value),
            ),
            if (i < fields.length - 1) ...[
              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              const SizedBox(height: 16),
            ],
          ],
        ],
      ),
    );
  }
}

class _TextArea extends StatelessWidget {
  const _TextArea({
    required this.controller,
    required this.label,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: TextField(
        controller: controller,
        enabled: enabled,
        minLines: 3,
        maxLines: 5,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF6C63FF)),
          ),
        ),
      ),
    );
  }
}

class _TournamentHeader extends StatelessWidget {
  const _TournamentHeader({required this.tournament});

  final AppTournament tournament;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Color(0xFF6C63FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tournament.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Inscripcion activa',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
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

class _LockedDataCard extends StatelessWidget {
  const _LockedDataCard({required this.participant});

  final AppParticipant participant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          _LockedRow(
            label: participant.entityType == ParticipantEntityType.team
                ? 'Equipo inscrito'
                : 'Usuario inscrito',
            value: participant.entityId,
          ),
          const SizedBox(height: 10),
          _LockedRow(
            label: 'Modalidad',
            value: participant.entityType == ParticipantEntityType.team
                ? 'Equipo'
                : 'Individual',
          ),
          if (participant.categoryId != null) ...[
            const SizedBox(height: 10),
            _LockedRow(label: 'Categoria', value: participant.categoryId!),
          ],
        ],
      ),
    );
  }
}

class _LockedRow extends StatelessWidget {
  const _LockedRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.lock_outline_rounded, size: 15, color: Colors.white38),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6C63FF)),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.isBlocking});

  final String message;
  final bool isBlocking;

  @override
  Widget build(BuildContext context) {
    final color = isBlocking
        ? const Color(0xFFFF4D6A)
        : const Color(0xFFFFB347);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isBlocking ? Icons.block_rounded : Icons.info_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 18 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 34 : 54, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(18),
    color: Colors.white.withValues(alpha: 0.04),
    border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
  );
}
