import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/glow_orb.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../user/data/services/firestore_user_service.dart';
import '../controllers/create_tournament_controller.dart';
import '../controllers/tournament_form_controller.dart';

// Importación de los 8 pasos
import 'form/steps/step0_identity.dart';
import 'form/steps/step1_discipline.dart';
import 'form/steps/step2_schedule.dart';
import 'form/steps/step3_geolocation.dart';
import 'form/steps/step4_logistics.dart';
import 'form/steps/step5_rules.dart';
import 'form/steps/step6_staff.dart';
import 'form/steps/step7_review.dart';

// Widgets y helpers
import 'form/widgets/form_helpers.dart';

class FormTournamentScreen extends StatefulWidget {
  const FormTournamentScreen({super.key});

  @override
  State<FormTournamentScreen> createState() => _FormTournamentScreenState();
}

class _FormTournamentScreenState extends State<FormTournamentScreen>
    with TickerProviderStateMixin {
  late final CreateTournamentController _submitController;
  late final TournamentFormController _form;

  // ── Controladores de animación de pantalla ──
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // ── Controlador de animación de transición entre pasos ──
  late final AnimationController _stepController;
  late final Animation<double> _stepFade;
  late final Animation<Offset> _stepSlide;

  // ── PageController para deslizar entre pasos ──
  final _pageController = PageController();

  // ── Portada ──
  final _imagePicker = ImagePicker();

  bool get _isSubmitting => _submitController.isSubmitting;

  @override
  void initState() {
    super.initState();

    _submitController = CreateTournamentController()
      ..addListener(() {
        if (mounted) setState(() {});
      });

    _form = TournamentFormController()
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

  // ── Navegación ─────────────────────────────────────────────

  Future<void> _goNext() async {
    FocusScope.of(context).unfocus();

    // Validación especial para portada en step 0
    if (_form.currentStep == 0) {
      if (!_form.validateCurrentStep()) {
        if (_form.coverBytes == null || _form.coverBytes!.isEmpty) {
          _showSnackBar(
            'Debes añadir una portada para el torneo.',
            isError: true,
          );
        }
        return;
      }
      if (_form.coverBytes == null || _form.coverBytes!.isEmpty) {
        _showSnackBar(
          'Debes añadir una portada para el torneo.',
          isError: true,
        );
        return;
      }
    } else if (!_form.validateCurrentStep()) {
      return;
    }

    if (_form.currentStep < TournamentFormController.totalSteps - 1) {
      await _animateStepTransition(() {
        _form.currentStep++;
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      });
    } else {
      await _handleSubmit();
    }
  }

  Future<void> _goBack() async {
    if (_form.currentStep > 0) {
      FocusScope.of(context).unfocus();
      await _animateStepTransition(() {
        _form.currentStep--;
        _pageController.previousPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  Future<void> _animateStepTransition(VoidCallback action) async {
    await _stepController.reverse();
    action();
    setState(() {});
    _stepController.forward();
  }

  // ── Submit ─────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final maxParticipants =
        int.tryParse(_form.maxParticipantsController.text.trim()) ?? 0;
    final membersPerTeam = int.tryParse(
      _form.membersPerTeamController.text.trim(),
    );
    final extraAdminIds = _form.extraAdmins
        .map((entry) => entry.uid)
        .toList(growable: false);

    final success = await _submitController.createTournament(
      name: _form.nameController.text,
      description: _form.descriptionController.text,
      allInformation: _form.rulesController.text,
      sport: _form.selectedSport!,
      scheduledAt: _form.eventDate!,
      maxParticipants: maxParticipants,
      membersPerTeam: membersPerTeam,
      location: _form.locationController.text,
      accessType: _form.selectedAccessType!,
      extraAdminIds: extraAdminIds,
      coverImage: _form.coverImage,
      latitude: _form.latitude,
      longitude: _form.longitude,
      registrationDeadline: _form.registrationDeadline,
      bracketPublishDate: _form.bracketPublishDate,
      contactEmail: _form.contactEmailController.text.trim(),
      contactPhone: _form.contactPhoneController.text.trim(),
      contactLinks: _form.contactLinks,
    );

    if (success) {
      if (mounted) {
        setState(() {
          _canPop = true;
        });
        Navigator.pop(context);
      }
      _showSnackBar('Torneo creado con éxito!', isError: false);
    } else {
      _showSnackBar(
        _submitController.errorMessage ?? 'Error al crear el torneo.',
        isError: true,
      );
    }
  }

  // ── Diálogos ───────────────────────────────────────────────

  bool _canPop = false;

  Future<bool> _showExitDialog() async {
    FocusScope.of(context).unfocus();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101127),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
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
      setState(() {
        _canPop = true;
      });
      Navigator.pop(context);
    }
  }

  Future<DateTime?> _pickDate({DateTime? initialDate}) async {
    FocusScope.of(context).unfocus();
    final today = DateTime.now();
    final initial = initialDate ?? DateTime(today.year, today.month, today.day);
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 3),
      helpText: '¿Cuándo se celebra el torneo?',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6C63FF),
            secondary: Color(0xFF00D4FF),
            surface: Color(0xFF12122E),
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF101127),
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  Future<void> _pickCover() async {
    FocusScope.of(context).unfocus();
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _form.coverImage = picked;
        _form.coverBytes = bytes;
      });
    } catch (_) {
      _showSnackBar('No se pudo seleccionar la imagen.', isError: true);
    }
  }

  void _removeCover() {
    setState(() {
      _form.coverImage = null;
      _form.coverBytes = null;
    });
  }

  Future<void> _addAdmin() async {
    if (_form.isAddingAdmin) return;
    FocusScope.of(context).unfocus();
    final raw = _form.adminController.text.trim();
    if (raw.isEmpty) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      setState(
        () => _form.adminError = 'Debes iniciar sesión para asignar admins.',
      );
      return;
    }

    setState(() {
      _form.isAddingAdmin = true;
      _form.adminError = null;
    });

    try {
      final userService = FirestoreUserService();

      String? uid;
      String label = raw;

      final cleanRaw = raw.startsWith('@') ? raw.substring(1) : raw;
      final userByNickname = await userService.getUserByNickname(cleanRaw);

      if (userByNickname != null) {
        uid = userByNickname.uid;
        label = '@${userByNickname.nickname}';
      } else {
        final exists = await userService.userExists(raw);
        if (!exists) {
          setState(
            () => _form.adminError =
                'No existe un usuario con ese nickname o UID.',
          );
          return;
        }
        uid = raw;
        final user = await userService.getUser(raw);
        label = user != null ? '@${user.nickname}' : raw;
      }

      if (uid == currentUid) {
        setState(() => _form.adminError = 'Ya eres admin por defecto.');
        return;
      }

      if (_form.extraAdmins.any((e) => e.uid == uid)) {
        setState(() => _form.adminError = 'Ese usuario ya está añadido.');
        return;
      }

      setState(() {
        _form.extraAdmins.add(FormAdminEntry(uid: uid!, label: label));
        _form.adminController.clear();
        _form.adminError = null;
      });
    } catch (_) {
      setState(() => _form.adminError = 'No se pudo añadir el admin.');
    } finally {
      if (mounted) {
        setState(() => _form.isAddingAdmin = false);
      }
    }
  }

  void _removeAdmin(String uid) {
    setState(() {
      _form.extraAdmins.removeWhere((e) => e.uid == uid);
      _form.adminError = null;
    });
  }

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
        backgroundColor: isError
            ? const Color(0xFFFF4D6A)
            : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        final bool shouldPop = await _showExitDialog();
        if (shouldPop) {
          if (context.mounted) {
            setState(() {
              _canPop = true;
            });
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
          Positioned(
            top: MediaQuery.of(context).size.height * 0.45,
            left: MediaQuery.of(context).size.width * 0.3,
            child: GlowOrb(
              color: const Color(0xFFFF6B9D).withValues(alpha: 0.15),
              size: 160,
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
                              _buildStepPage(_buildStep3()),
                              _buildStepPage(_buildStep4()),
                              _buildStepPage(_buildStep5()),
                              _buildStepPage(_buildStep6()),
                              _buildStepPage(_buildStep7()),
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
    ));
  }

  // ── Header con barra de progreso ──

  Widget _buildHeader() {
    const stepLabels = [
      'Identidad',
      'Disciplina',
      'Cronograma',
      'Geolocalización',
      'Logística y Privacidad',
      'Reglamento',
      'Staff y Soporte',
      'Review',
    ];

    final total = TournamentFormController.totalSteps;

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
          children: List.generate(total, (i) {
            final isActive = i == _form.currentStep;
            final isDone = i < _form.currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: isActive || isDone
                      ? const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                        )
                      : null,
                  color: isActive || isDone
                      ? null
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                stepLabels[_form.currentStep],
                key: ValueKey(_form.currentStep),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'Paso ${_form.currentStep + 1} de $total',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Step builders ──

  Widget _buildStep0() => Step0Identity(
    nameController: _form.nameController,
    descriptionController: _form.descriptionController,
    nameError: _form.nameError,
    descriptionError: _form.descriptionError,
    coverBytes: _form.coverBytes,
    onNameChanged: (_) => _form.clearFieldError('name'),
    onDescriptionChanged: (_) => _form.clearFieldError('description'),
    onPickCover: _pickCover,
    onRemoveCover: _removeCover,
  );

  Widget _buildStep1() => Step1Discipline(
    selectedSport: _form.selectedSport,
    sportError: _form.sportError,
    onSportChanged: _form.selectSport,
    isTeamSport: _form.isTeamSport,
    teamModeLockedByDiscipline: _form.isTeamModeLockedByDiscipline,
    onTeamTournamentChanged: _form.setTeamTournament,
  );

  Widget _buildStep2() => Step2Schedule(
    eventDate: _form.eventDate,
    eventDateError: _form.eventDateError,
    onPickEventDate: () async {
      final picked = await _pickDate(initialDate: _form.eventDate);
      if (picked != null && mounted) {
        setState(() {
          _form.eventDate = picked;
          _form.eventDateError = null;
        });
      }
    },
    registrationDeadline: _form.registrationDeadline,
    registrationDeadlineError: _form.registrationDeadlineError,
    onPickRegistrationDeadline: () async {
      final picked = await _pickDate(initialDate: _form.registrationDeadline);
      if (picked != null && mounted) {
        setState(() {
          _form.registrationDeadline = picked;
          _form.registrationDeadlineError = null;
        });
      }
    },
    bracketPublishDate: _form.bracketPublishDate,
    bracketPublishDateError: _form.bracketPublishDateError,
    onPickBracketPublishDate: () async {
      final picked = await _pickDate(initialDate: _form.bracketPublishDate);
      if (picked != null && mounted) {
        setState(() {
          _form.bracketPublishDate = picked;
          _form.bracketPublishDateError = null;
        });
      }
    },
    formatDate: _form.formatDate,
  );

  Widget _buildStep3() => Step3Geolocation(
    locationController: _form.locationController,
    locationError: _form.locationError,
    latitude: _form.latitude,
    longitude: _form.longitude,
    suggestions: _form.locationSuggestions,
    isSearching: _form.isSearchingLocation,
    resolvedAddress: _form.locationController.text.trim().isNotEmpty
        ? _form.locationController.text.trim()
        : null,
    onQueryChanged: (query) {
      _form.clearFieldError('location');
      _form.onLocationQueryChanged(query);
    },
    onSuggestionSelected: (result) {
      _form.selectLocation(result);
      setState(() {});
    },
    onMapTap: (lat, lng) {
      _form.onMapTap(lat, lng);
    },
  );

  Widget _buildStep4() => Step4Logistics(
    selectedSport: _form.selectedSport,
    isTeamSport: _form.isTeamSport,
    maxParticipantsController: _form.maxParticipantsController,
    maxParticipantsError: _form.maxParticipantsError,
    onMaxParticipantsChanged: (_) => _form.clearFieldError('maxParticipants'),
    membersPerTeamController: _form.membersPerTeamController,
    membersPerTeamError: _form.membersPerTeamError,
    onMembersPerTeamChanged: (_) => _form.clearFieldError('membersPerTeam'),
    selectedAccessType: _form.selectedAccessType,
    accessTypeError: _form.accessTypeError,
    onAccessTypeChanged: (type) => setState(() {
      _form.selectedAccessType = type;
      _form.accessTypeError = null;
    }),
  );

  Widget _buildStep5() => Step5Rules(
    rulesController: _form.rulesController,
    rulesError: _form.rulesError,
    onRulesChanged: (_) => _form.clearFieldError('rules'),
  );

  Widget _buildStep6() => Step6Staff(
    adminController: _form.adminController,
    adminError: _form.adminError,
    isAddingAdmin: _form.isAddingAdmin,
    extraAdmins: _form.extraAdmins,
    onAdminChanged: (_) => _form.clearFieldError('admin'),
    onAddAdmin: _addAdmin,
    onRemoveAdmin: _removeAdmin,
    contactEmailController: _form.contactEmailController,
    contactEmailError: _form.contactEmailError,
    onContactEmailChanged: (_) => _form.clearFieldError('contactEmail'),
    contactPhoneController: _form.contactPhoneController,
    onContactPhoneChanged: (_) {},
    contactLinkControllers: _form.contactLinkControllers,
    onAddContactLink: () => setState(() => _form.addContactLink()),
    onRemoveContactLink: (i) => setState(() => _form.removeContactLink(i)),
  );

  Widget _buildStep7() => Step7Review(
    coverBytes: _form.coverBytes,
    name: _form.nameController.text.trim().isEmpty
        ? '—'
        : _form.nameController.text.trim(),
    description: _form.descriptionController.text.trim().isEmpty
        ? '—'
        : _form.descriptionController.text.trim(),
    sport: _form.selectedSport?.label ?? '—',
    eventDate: _form.eventDate == null
        ? '—'
        : _form.formatDate(_form.eventDate!),
    registrationDeadline: _form.registrationDeadline != null
        ? _form.formatDate(_form.registrationDeadline!)
        : null,
    bracketPublishDate: _form.bracketPublishDate != null
        ? _form.formatDate(_form.bracketPublishDate!)
        : null,
    location: _form.locationController.text.trim().isEmpty
        ? '—'
        : _form.locationController.text.trim(),
    hasCoordinates: _form.latitude != null && _form.longitude != null,
    maxParticipants: _form.maxParticipantsController.text.trim().isEmpty
        ? '—'
        : _form.maxParticipantsController.text.trim(),
    membersPerTeam: _form.isTeamSport
        ? (_form.membersPerTeamController.text.trim().isEmpty
              ? '—'
              : _form.membersPerTeamController.text.trim())
        : null,
    accessType: _form.selectedAccessType?.label ?? '—',
    rulesPreview: _form.rulesController.text.trim().isEmpty
        ? '—'
        : _form.rulesController.text.trim(),
    contactEmail: _form.contactEmailController.text.trim().isEmpty
        ? '—'
        : _form.contactEmailController.text.trim(),
    contactPhone: _form.contactPhoneController.text.trim().isEmpty
        ? null
        : _form.contactPhoneController.text.trim(),
    contactLinks: _form.contactLinks,
    admins: ['Tú (creador)', ..._form.extraAdmins.map((a) => a.label)],
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
    final isLast = _form.currentStep == TournamentFormController.totalSteps - 1;

    return Row(
      children: [
        if (_form.currentStep > 0) ...[
          SizedBox(
            height: 52,
            child: OutlineButton(
              label: 'Atrás',
              icon: Icons.arrow_back_rounded,
              onPressed: _goBack,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: GradientButton(
            label: isLast
                ? (_isSubmitting ? 'Creando torneo...' : 'Crear torneo')
                : 'Siguiente',
            icon: isLast
                ? Icons.emoji_events_rounded
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
