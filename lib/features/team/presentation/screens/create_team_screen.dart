import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/getColors/getter_colors.dart';
import '../../../../core/widgets/glow_orb.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../user/data/services/firestore_user_service.dart';
import '../controllers/create_team_controller.dart';
import '../controllers/team_form_controller.dart';

// Steps
import 'form/steps/step0_team_identity.dart';
import 'form/steps/step1_team_members.dart';
import 'form/steps/step2_team_review.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CreateTeamScreen  ·  Formulario multi-step de creación de equipo
//
//  Estructura idéntica a FormTournamentScreen:
//  - Header con barra de progreso + botón "Descartar"
//  - PageView con 3 pasos
//  - Botones de navegación Atrás / Siguiente / Crear
// ─────────────────────────────────────────────────────────────────────────────

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen>
    with TickerProviderStateMixin {
  late final CreateTeamController _submitController;
  late final TeamFormController _form;

  // ── Animación de pantalla ──
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // ── Animación de transición entre pasos ──
  late final AnimationController _stepController;
  late final Animation<double> _stepFade;
  late final Animation<Offset> _stepSlide;

  // ── PageController ──
  final _pageController = PageController();
  final _imagePicker = ImagePicker();

  bool _canPop = false;

  bool get _isSubmitting => _submitController.isSubmitting;

  @override
  void initState() {
    super.initState();

    _submitController = CreateTeamController()
      ..addListener(() {
        if (mounted) setState(() {});
      });

    _form = TeamFormController()
      ..addListener(() {
        if (mounted) setState(() {});
      });

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _stepController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _stepFade = CurvedAnimation(parent: _stepController, curve: Curves.easeOut);
    _stepSlide = Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _stepController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
    _stepController.forward();
  }

  @override
  void dispose() {
    _submitController.dispose();
    _form.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _stepController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ── Navegación ─────────────────────────────────────────────────────────────

  Future<void> _goNext() async {
    FocusScope.of(context).unfocus();

    // Si estamos en el último paso, submit
    if (_form.currentStep == TeamFormController.totalSteps - 1) {
      await _submitTeam();
      return;
    }

    if (!_form.validateCurrentStep()) return;

    await _animateStepTransition(() {
      _form.goNext();
      _pageController.animateToPage(
        _form.currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _goBack() async {
    if (_form.currentStep == 0) {
      _confirmDiscard();
      return;
    }

    await _animateStepTransition(() {
      _form.goBack();
      _pageController.animateToPage(
        _form.currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _animateStepTransition(VoidCallback action) async {
    await _stepController.reverse();
    action();
    _stepController.forward();
  }

  Future<void> _submitTeam() async {
    final team = await _submitController.submitTeam(_form);
    if (team != null && mounted) {
      _showSnackBar('¡Equipo creado con éxito!', isError: false);
      Navigator.pop(context, team);
    } else if (_submitController.error != null && mounted) {
      _showSnackBar(_submitController.error!, isError: true);
    }
  }

  // ── Diálogo de salida ──────────────────────────────────────────────────────

  Future<bool> _showExitDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101127),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4D6A)),
            SizedBox(width: 8),
            Text('¿Borrar y salir?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Se eliminarán todos los datos que has introducido. ¿Estás seguro de que quieres salir?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF4D6A),
            ),
            child: const Text(
              'Sí, borrar todo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return confirm == true;
  }

  Future<void> _confirmDiscard() async {
    final bool shouldPop = await _showExitDialog();
    if (shouldPop && mounted) {
      setState(() => _canPop = true);
      Navigator.pop(context);
    }
  }

  // ── Imagen ─────────────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    FocusScope.of(context).unfocus();
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _form.coverBytes = bytes);
    } catch (_) {
      _showSnackBar('No se pudo seleccionar la imagen.', isError: true);
    }
  }

  void _removePhoto() {
    setState(() => _form.coverBytes = null);
  }

  // ── Miembros ───────────────────────────────────────────────────────────────

  Future<void> _addMember() async {
    final raw = _form.memberController.text.trim();
    if (raw.isEmpty) {
      setState(() => _form.memberError = 'Escribe un nickname.');
      return;
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    setState(() {
      _form.isSearchingMember = true;
      _form.memberError = null;
    });

    try {
      final userService = FirestoreUserService();
      final cleanRaw = raw.startsWith('@') ? raw.substring(1) : raw;
      final user = await userService.getUserByNickname(cleanRaw);

      if (user == null) {
        setState(() => _form.memberError = 'No existe un usuario con ese nickname.');
        return;
      }

      if (user.uid == currentUid) {
        setState(() => _form.memberError = 'Tú ya serás añadido automáticamente.');
        return;
      }

      final entry = TeamMemberEntry(
        uid: user.uid,
        nickname: user.nickname,
        displayName: '${user.name} ${user.lastName}'.trim(),
        photoUrl: user.photoUrl,
      );

      final added = _form.addMember(entry);
      if (added) {
        _form.memberController.clear();
      }
    } catch (_) {
      setState(() => _form.memberError = 'Error al buscar el usuario.');
    } finally {
      if (mounted) {
        setState(() => _form.isSearchingMember = false);
      }
    }
  }

  // ── Snackbar ───────────────────────────────────────────────────────────────

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.info_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor:
            isError ? const Color(0xFFFF4D6A) : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final bool shouldPop = await _showExitDialog();
        if (shouldPop) {
          if (context.mounted) {
            setState(() => _canPop = true);
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0A1A),
                    Color(0xFF0D0D2B),
                    Color(0xFF12122E),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -80,
              left: -60,
              child: GlowOrb(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                size: 280,
              ),
            ),
            Positioned(
              bottom: 60,
              right: -80,
              child: GlowOrb(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.25),
                size: 240,
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 860;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isWide ? 880 : 620,
                              ),
                              child: _buildHeader(),
                            ),
                          ),
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _buildStepPage(_buildStep0()),
                                _buildStepPage(_buildStep1()),
                                _buildStepPage(_buildStep2()),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isWide ? 880 : 620,
                                ),
                                child: _buildNavButtons(),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header con barra de progreso ──

  Widget _buildHeader() {
    const stepLabels = ['Identidad', 'Miembros', 'Resumen'];
    final total = TeamFormController.totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: _confirmDiscard,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D6A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFF4D6A).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFFF4D6A),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Descartar',
                      style: TextStyle(
                        color: Color(0xFFFF4D6A),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
              ).createShader(bounds),
              child: const Text(
                'Nuevo equipo',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: Text(
                '${_form.currentStep + 1} / $total',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          stepLabels[_form.currentStep],
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),

        // Barra de progreso
        Row(
          children: List.generate(total, (i) {
            final isActive = i <= _form.currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 3.5,
                margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: isActive
                      ? const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                        )
                      : null,
                  color: isActive ? null : Colors.white.withValues(alpha: 0.1),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Step builders ──

  Widget _buildStep0() => Step0TeamIdentity(
        nameController: _form.nameController,
        nameError: _form.nameError,
        coverBytes: _form.coverBytes,
        onNameChanged: (_) => _form.clearFieldError('name'),
        onPickPhoto: _pickPhoto,
        onRemovePhoto: _removePhoto,
      );

  Widget _buildStep1() => Step1TeamMembers(
        memberController: _form.memberController,
        memberError: _form.memberError,
        isSearching: _form.isSearchingMember,
        members: _form.members,
        onMemberChanged: (_) => _form.clearFieldError('member'),
        onAddMember: _addMember,
        onRemoveMember: (uid) => setState(() => _form.removeMember(uid)),
        onToggleAdmin: (uid) => setState(() => _form.toggleMemberAdmin(uid)),
      );

  Widget _buildStep2() => Step2TeamReview(
        teamName: _form.nameController.text.trim(),
        coverBytes: _form.coverBytes,
        members: _form.members,
      );

  // ── Step page wrapper ──

  Widget _buildStepPage(Widget content) {
    return FadeTransition(
      opacity: _stepFade,
      child: SlideTransition(
        position: _stepSlide,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  // ── Navigation buttons ──

  Widget _buildNavButtons() {
    final isLast = _form.currentStep == TeamFormController.totalSteps - 1;

    return Row(
      children: [
        if (_form.currentStep > 0) ...[
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _goBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Atrás'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: GradientButton(
            label: isLast
                ? (_isSubmitting ? 'Creando equipo...' : 'Crear equipo')
                : 'Siguiente',
            icon: isLast
                ? Icons.groups_rounded
                : Icons.arrow_forward_rounded,
            isLoading: _isSubmitting,
            variant: isLast
                ? GradientButtonVariant.forest
                : GradientButtonVariant.ocean,
            onPressed: _goNext,
          ),
        ),
      ],
    );
  }
}
