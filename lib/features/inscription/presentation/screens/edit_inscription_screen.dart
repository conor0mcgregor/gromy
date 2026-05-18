import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/registration_form_builder.dart';
import '../../../../core/widgets/bar_small_botton.dart';
import '../../../../database/participant/models/app_participant.dart';
import '../../../../features/tournament/data/model/app_tournament.dart';
import '../controllers/edit_inscription_controller.dart';

// ════════════════════════════════════════════════════════════════
//  EDIT INSCRIPTION SCREEN
//  Permite editar una inscripción existente bajo reglas de negocio.
// ════════════════════════════════════════════════════════════════

class EditInscriptionScreen extends StatefulWidget {
  const EditInscriptionScreen({
    super.key,
    required this.tournament,
    required this.participant,
    required this.currentUserId,
  });

  final AppTournament tournament;
  final AppParticipant participant;
  final String currentUserId;

  @override
  State<EditInscriptionScreen> createState() => _EditInscriptionScreenState();
}

class _EditInscriptionScreenState extends State<EditInscriptionScreen> {
  late final EditInscriptionController _ctrl;

  static const Color _bg = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _ctrl = EditInscriptionController(
      tournament: widget.tournament,
      participant: widget.participant,
      currentUserId: widget.currentUserId,
    );
    _ctrl.addListener(_onControllerChange);
    _ctrl.initialize();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerChange);
    _ctrl.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (!mounted) return;
    setState(() {});

    if (_ctrl.saveState == EditSaveState.success) {
      _showSuccessAndPop();
    } else if (_ctrl.saveState == EditSaveState.error &&
        _ctrl.saveError != null) {
      _showErrorSnackbar(_ctrl.saveError!);
      _ctrl.resetSaveState();
    }
  }

  void _showSuccessAndPop() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Inscripción actualizada correctamente.'),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.of(context).pop(true);
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF4D6A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BarSmallBotton(
          icon: Icons.arrow_back_ios_new,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Editar inscripción',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_ctrl.loadState == EditLoadState.loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      );
    }

    // Si no es editable, mostrar mensaje de restricción.
    if (_ctrl.editabilityError != null) {
      return _buildNotEditableMessage();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background glow
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        // Content
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tournament info header
              _buildTournamentHeader(),
              const SizedBox(height: 24),

              // Category selector (if applicable)
              if (widget.tournament.categories.isNotEmpty) ...[
                _buildCategorySelector(),
                const SizedBox(height: 24),
              ],

              // Registration form fields
              if (_ctrl.formSchema != null &&
                  _ctrl.formSchema!.hasActiveFields)
                RegistrationFormBuilder(
                  schema: _ctrl.formSchema!,
                  responses: _ctrl.responses,
                  onResponseChanged: _ctrl.updateResponse,
                  errors: _ctrl.fieldErrors,
                ),
            ],
          ),
        ),
        // Save button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _bg.withValues(alpha: 0),
                  _bg,
                ],
              ),
            ),
            child: GradientButton(
              label: 'Guardar cambios',
              icon: Icons.save_rounded,
              isLoading: _ctrl.saveState == EditSaveState.saving,
              onPressed: _ctrl.canSave ? () => _ctrl.saveChanges() : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotEditableMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: const Color(0xFFFFB347).withValues(alpha: 0.7),
              size: 56,
            ),
            const SizedBox(height: 20),
            Text(
              'Inscripción no editable',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _ctrl.editabilityError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: 'Volver',
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).pop(),
              width: 160,
              size: GradientButtonSize.small,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Color(0xFF6C63FF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tournament.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Editando datos de inscripción',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoría',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: widget.tournament.categories.map((cat) {
            final isSelected = _ctrl.selectedCategoryId == cat;
            return GestureDetector(
              onTap: () => _ctrl.selectCategory(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected
                      ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6C63FF)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF6C63FF)
                        : Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
