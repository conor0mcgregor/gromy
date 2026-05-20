import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/getColors/getter_colors.dart';
import '../../../../../core/widgets/glow_orb.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../../../../inscription/screen/preinscription_screen.dart';
import '../../../../user/data/models/app_user.dart';
import '../../../../user/data/services/firestore_user_service.dart';
import '../../../data/model/app_tournament.dart';
import '../../../data/model/tournament_draft.dart';
import '../../../data/repositories/tournament_draft_repository.dart';
import '../../../data/services/shared_preferences_tournament_draft_repository.dart';
import '../../controllers/create_tournament_controller.dart';
import '../../controllers/tournament_form_controller.dart';

// Importación de los 9 pasos
import 'form/steps/step0_identity.dart';
import 'form/steps/step1_discipline.dart';
import 'form/steps/step2_schedule.dart';
import 'form/steps/step3_geolocation.dart';
import 'form/steps/step4_logistics.dart';
import 'form/steps/step5_rules.dart';
import 'form/steps/step6_categories.dart';
import 'form/steps/step6_staff.dart';
import 'form/steps/step7_review.dart';

// Widgets y helpers
import 'form/widgets/form_helpers.dart';
import 'form/widgets/registration_form_builder.dart';

class FormTournamentScreen extends StatefulWidget {
  const FormTournamentScreen({
    super.key,
    this.initialDraft,
    this.draftRepository,
  });

  final TournamentDraft? initialDraft;
  final TournamentDraftRepository? draftRepository;

  @override
  State<FormTournamentScreen> createState() => _FormTournamentScreenState();
}

class _FormTournamentScreenState extends State<FormTournamentScreen>
    with TickerProviderStateMixin {
  late final CreateTournamentController _submitController;
  late final TournamentFormController _form;
  late final TournamentDraftRepository _draftRepository;

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
  String? _acknowledgedDuplicateWarningKey;
  bool _isShowingDuplicateWarningPopup = false;
  String? _localDraftId;
  Timer? _autosaveTimer;
  bool _isSavingDraft = false;
  bool _hasUnsavedLocalChanges = false;
  bool _isApplyingDraft = false;
  String? _autosaveMessage;
  bool _autosaveFailed = false;

  bool get _isSubmitting => _submitController.isSubmitting;
  bool get _hasSavedDraft => _localDraftId != null;

  @override
  void initState() {
    super.initState();

    _submitController = CreateTournamentController()
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _draftRepository =
        widget.draftRepository ?? SharedPreferencesTournamentDraftRepository();
    _localDraftId = widget.initialDraft?.id;

    _form = TournamentFormController()
      ..addListener(() {
        if (!_isApplyingDraft && _form.hasMeaningfulDraftInput) {
          _hasUnsavedLocalChanges = true;
        }
        if (mounted) setState(() {});
        _scheduleAutosave();
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

    if (widget.initialDraft != null) {
      unawaited(_loadInitialDraft(widget.initialDraft!));
    }
  }

  @override
  void dispose() {
    _submitController.dispose();
    _autosaveTimer?.cancel();
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

    final duplicate = await _checkDuplicate();
    if (duplicate != null) {
      final acknowledged = await _showDuplicateWarningPopupIfNeeded(duplicate);
      if (!acknowledged) return;
    }

    await _saveLocalDraft(showFeedback: false);

    final maxParticipants =
        int.tryParse(_form.maxParticipantsController.text.trim()) ?? 0;
    final membersPerTeam = int.tryParse(
      _form.membersPerTeamController.text.trim(),
    );
    final invitedAdminUserIds = _form.extraAdmins
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
      invitedAdminUserIds: invitedAdminUserIds,
      coverImage: _form.coverImage,
      latitude: _form.latitude,
      longitude: _form.longitude,
      registrationDeadline: _form.registrationDeadline,
      bracketPublishDate: _form.bracketPublishDate,
      contactEmail: _form.contactEmailController.text.trim(),
      contactPhone: _form.contactPhoneController.text.trim(),
      contactLinks: _form.contactLinks,
      categories: _form.categories,
      registrationForm: _form.registrationForm,
    );

    if (success) {
      if (_localDraftId != null) {
        await _draftRepository.deleteDraft(_localDraftId!);
      }
      if (mounted) {
        setState(() {
          _canPop = true;
        });
        Navigator.pop(context);
      }
      _showSnackBar('Torneo creado con éxito!', isError: false);
    } else {
      // ── Duplicado detectado: mostrar aviso específico ────────────────────
      final duplicate = _submitController.duplicateTournament;
      if (duplicate != null && mounted) {
        await _showDuplicateWarning(duplicate);
      } else {
        // Error genérico (Firebase, red, validación, etc.)
        _showSnackBar(
          '${_submitController.errorMessage ?? 'Error al crear el torneo.'} '
          'Tu borrador local sigue guardado.',
          isError: true,
        );
      }
    }
  }

  Future<void> _loadInitialDraft(TournamentDraft draft) async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null || draft.ownerUid != currentUid) {
        _showSnackBar(
          'No puedes editar un borrador de otro usuario.',
          isError: true,
        );
        return;
      }
      _isApplyingDraft = true;
      await _form.loadDraft(draft);
      _isApplyingDraft = false;
      _hasUnsavedLocalChanges = false;
      if (mounted) {
        _showSnackBar('Borrador local cargado.', isError: false);
      }
    } catch (_) {
      _isApplyingDraft = false;
      _showSnackBar('No se pudo cargar el borrador local.', isError: true);
    }
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    if (!_form.hasMeaningfulDraftInput) return;
    _autosaveTimer = Timer(const Duration(seconds: 2), () {
      unawaited(_saveLocalDraft(showFeedback: false, isAutosave: true));
    });
  }

  void _markDraftDirtyAndScheduleAutosave() {
    if (!_form.hasMeaningfulDraftInput) return;
    _hasUnsavedLocalChanges = true;
    _scheduleAutosave();
  }

  Future<bool> _saveLocalDraft({
    required bool showFeedback,
    bool isAutosave = false,
  }) async {
    if (_isSavingDraft) return false;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      if (showFeedback) {
        _showSnackBar(
          'Debes iniciar sesión para guardar un borrador.',
          isError: true,
        );
      }
      return false;
    }
    if (!_form.hasMeaningfulDraftInput) {
      if (showFeedback) {
        _showSnackBar('Añade algún dato antes de guardar.', isError: true);
      }
      return false;
    }

    setState(() {
      _isSavingDraft = true;
      _autosaveMessage = isAutosave ? 'Autoguardando...' : null;
      _autosaveFailed = false;
    });

    try {
      final saved = await _draftRepository.saveDraft(
        _form.toDraft(ownerUid: currentUid, draftId: _localDraftId),
      );
      _localDraftId = saved.id;
      _hasUnsavedLocalChanges = false;
      if (!mounted) return true;
      setState(() {
        _autosaveMessage = isAutosave
            ? 'Borrador local guardado'
            : 'Guardado como borrador local';
        _autosaveFailed = false;
      });
      if (showFeedback) {
        _showSnackBar('Borrador guardado localmente.', isError: false);
      }
      return true;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        _autosaveMessage = 'No se pudo autoguardar';
        _autosaveFailed = true;
      });
      if (showFeedback) {
        _showSnackBar('No se pudo guardar el borrador local.', isError: true);
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _isSavingDraft = false);
      }
    }
  }

  Future<void> _handleSaveDraftPressed() async {
    final saved = await _saveLocalDraft(showFeedback: false);
    if (!saved || !mounted) return;
    await _showDraftSavedDialog();
  }

  Future<void> _showDraftSavedDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101127),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Text(
          'Borrador guardado',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tu borrador de torneo se ha guardado localmente. Puedes seguir editándolo más tarde.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Seguir editando',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _leaveKeepingDraft();
            },
            child: const Text(
              'Salir y conservar',
              style: TextStyle(
                color: Color(0xFF00D4FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Diálogos ───────────────────────────────────────────────

  /// Muestra el aviso de torneo duplicado en un bottom-sheet glass.
  ///
  /// Ofrece dos acciones:
  /// 1. Ver el torneo existente → navega a [DemoEnrollScreen].
  /// 2. Modificar datos → cierra el sheet (el formulario queda abierto).
  Future<void> _showDuplicateWarning(AppTournament duplicate) async {
    _submitController.clearDuplicate();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DuplicateWarningSheet(
        duplicate: duplicate,
        onViewTournament: () {
          Navigator.pop(ctx); // cierra el sheet
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PreinscriptionScreen(tournament: duplicate),
            ),
          );
        },
        onModify: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<bool> _showDuplicateWarningPopupIfNeeded(
    AppTournament duplicate,
  ) async {
    final eventDate = _form.eventDate;
    final location = _form.locationController.text.trim();
    if (eventDate == null || location.isEmpty) return true;

    final key = _duplicateWarningKey(eventDate: eventDate, location: location);
    if (_acknowledgedDuplicateWarningKey == key ||
        _isShowingDuplicateWarningPopup ||
        !mounted) {
      return true;
    }

    _isShowingDuplicateWarningPopup = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _DuplicateWarningSheet(
          duplicate: duplicate,
          onViewTournament: () {
            _acknowledgedDuplicateWarningKey = key;
            Navigator.pop(ctx);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PreinscriptionScreen(tournament: duplicate),
              ),
            );
          },
          onModify: () {
            _acknowledgedDuplicateWarningKey = key;
            Navigator.pop(ctx);
          },
        ),
      );
    } finally {
      _isShowingDuplicateWarningPopup = false;
    }
    return _acknowledgedDuplicateWarningKey == key;
  }

  String _duplicateWarningKey({
    required DateTime eventDate,
    required String location,
  }) {
    return '${eventDate.millisecondsSinceEpoch}|${location.trim().toLowerCase()}';
  }

  void _openExistingTournament(AppTournament duplicate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreinscriptionScreen(tournament: duplicate),
      ),
    );
  }

  bool _canPop = false;

  Future<void> _handleBackNavigation() async {
    if (!_form.hasMeaningfulDraftInput) {
      _leaveKeepingDraft();
      return;
    }

    if (_hasSavedDraft && !_hasUnsavedLocalChanges) {
      _leaveKeepingDraft();
      return;
    }

    await _showUnsavedChangesDialog();
  }

  void _leaveKeepingDraft() {
    if (!mounted) return;
    setState(() {
      _canPop = true;
    });
    Navigator.pop(context);
  }

  Future<void> _showUnsavedChangesDialog() async {
    FocusScope.of(context).unfocus();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101127),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Row(
          children: [
            const Icon(Icons.save_outlined, color: Color(0xFF00D4FF)),
            const SizedBox(width: 8),
            Expanded( // Mantenemos el Expanded para que sepa dónde está la pared
              child: Text(
                'Cambios sin guardar',
                style: const TextStyle(color: Colors.white),
                softWrap: true, // Le permite romper la línea y bajar cuando no cabe
                maxLines: 2,    // Permite que ocupe hasta 2 renglones
              ),
            )
          ],
        ),
        content: const Text(
          'Puedes guardar el borrador local antes de salir, descartarlo definitivamente o seguir editando.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Seguir editando',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _discardDraftAndLeave();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF4D6A),
            ),
            child: const Text(
              'Descartar borrador',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final saved = await _saveLocalDraft(showFeedback: false);
              if (saved) {
                _leaveKeepingDraft();
              }
            },
            child: const Text(
              'Guardar y salir',
              style: TextStyle(
                color: Color(0xFF00D4FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDiscard() async {
    FocusScope.of(context).unfocus();
    final bool? shouldDiscard = await showDialog<bool>(
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
            Text('¿Descartar borrador?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          _hasSavedDraft
              ? 'Se eliminará el borrador local guardado y perderás los cambios de este formulario.'
              : 'Se eliminarán todos los datos que has introducido en este formulario.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Seguir editando',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF4D6A),
            ),
            child: const Text(
              'Sí, descartar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldDiscard == true) {
      await _discardDraftAndLeave();
    }
  }

  Future<void> _discardDraftAndLeave() async {
    _autosaveTimer?.cancel();
    final draftId = _localDraftId;
    if (draftId != null) {
      await _draftRepository.deleteDraft(draftId);
    }
    if (!mounted) return;
    setState(() {
      _localDraftId = null;
      _hasUnsavedLocalChanges = false;
      _canPop = true;
    });
    Navigator.pop(context);
  }

  Future<DateTime?> _pickDateTime({DateTime? initialDate, required String helpText}) async {
    FocusScope.of(context).unfocus();
    final today = DateTime.now();
    final initial = initialDate ?? DateTime(today.year, today.month, today.day, 10, 0);

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 3),
      helpText: helpText,
      confirmText: 'Siguiente',
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

    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: helpText,
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

    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
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
      developer.log(
        'Tournament cover selected | path=${picked.path.isEmpty ? "(path vacío)" : picked.path} '
        'mimeType=${picked.mimeType ?? "(null)"} bytes=${bytes.length}',
        name: 'FormTournamentScreen',
      );
      if (!mounted) return;
      setState(() {
        _form.coverImage = picked;
        _form.coverBytes = bytes;
      });
      _markDraftDirtyAndScheduleAutosave();
    } catch (error, stackTrace) {
      developer.log(
        'Error selecting tournament cover',
        name: 'FormTournamentScreen',
        error: error,
        stackTrace: stackTrace,
      );
      _showSnackBar('No se pudo seleccionar la imagen.', isError: true);
    }
  }

  void _removeCover() {
    setState(() {
      _form.coverImage = null;
      _form.coverBytes = null;
    });
    _markDraftDirtyAndScheduleAutosave();
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

      final AppUser? resolvedUser;
      if (raw.contains('@')) {
        resolvedUser = await userService.getUserByEmail(raw);
      } else {
        final cleanRaw = raw.startsWith('@') ? raw.substring(1) : raw;
        final byNickname = await userService.getUserByNickname(cleanRaw);
        if (byNickname != null) {
          resolvedUser = byNickname;
        } else if (await userService.userExists(raw)) {
          resolvedUser = await userService.getUser(raw);
        } else {
          resolvedUser = null;
        }
      }

      if (resolvedUser == null) {
        setState(
          () => _form.adminError =
              'No existe un usuario con ese email, nickname o UID.',
        );
        return;
      }

      final uid = resolvedUser.uid;
      final label = '@${resolvedUser.nickname}';

      if (uid == currentUid) {
        setState(() => _form.adminError = 'Ya eres admin por defecto.');
        return;
      }

      if (_form.extraAdmins.any((e) => e.uid == uid)) {
        setState(
          () => _form.adminError =
              'Ese usuario ya está en la lista de invitaciones.',
        );
        return;
      }

      setState(() {
        _form.extraAdmins.add(FormAdminEntry(uid: uid, label: label));
        _form.adminController.clear();
        _form.adminError = null;
      });
      _markDraftDirtyAndScheduleAutosave();
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
    _markDraftDirtyAndScheduleAutosave();
  }

  void _addCategory() {
    final raw = _form.categoryController.text.trim();
    if (raw.isEmpty) {
      _showSnackBar(
        'Escribe el nombre de la categoría primero.',
        isError: true,
      );
      return;
    }
    final added = _form.addCategory(raw);
    if (added) {
      _form.categoryController.clear();
      FocusScope.of(context).unfocus();
      _markDraftDirtyAndScheduleAutosave();
    } else {
      _showSnackBar('Esa categoría ya ha sido añadida.', isError: true);
    }
  }

  void _removeCategory(String name) {
    _form.removeCategory(name);
    _markDraftDirtyAndScheduleAutosave();
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
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        await _handleBackNavigation();
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
                                _buildStepPage(_buildStep6Categories()),
                                _buildStepPage(_buildStep7RegistrationForm()),
                                _buildStepPage(_buildStep7Staff()),
                                _buildStepPage(_buildStep8Review()),
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
    const stepLabels = [
      'Identidad',
      'Disciplina',
      'Cronograma',
      'Geolocalización',
      'Logística y Privacidad',
      'Reglamento',
      'Categorías',
      'InscripciÃ³n',
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
            if (_autosaveMessage != null) ...[
              Flexible(
                child: Text(
                  _autosaveMessage!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _autosaveFailed
                        ? const Color(0xFFFFB347)
                        : Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            InkWell(
              onTap: _isSavingDraft ? null : _handleSaveDraftPressed,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isSavingDraft ? Icons.sync_rounded : Icons.save_outlined,
                      color: const Color(0xFF00D4FF),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isSavingDraft ? 'Guardando...' : 'Guardar borrador',
                      style: const TextStyle(
                        color: Color(0xFF00D4FF),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
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
      final picked = await _pickDateTime(
        initialDate: _form.eventDate,
        helpText: 'Selecciona la fecha y hora del evento',
      );
      if (picked != null && mounted) {
        setState(() {
          _form.eventDate = picked;
          _form.eventDateError = null;
          _acknowledgedDuplicateWarningKey = null;
        });
        _markDraftDirtyAndScheduleAutosave();
      }
    },
    registrationDeadline: _form.registrationDeadline,
    registrationDeadlineError: _form.registrationDeadlineError,
    onPickRegistrationDeadline: () async {
      final picked = await _pickDateTime(
        initialDate: _form.registrationDeadline,
        helpText: 'Cierre de inscripciones',
      );
      if (picked != null && mounted) {
        setState(() {
          _form.registrationDeadline = picked;
          _form.registrationDeadlineError = null;
        });
        _markDraftDirtyAndScheduleAutosave();
      }
    },
    bracketPublishDate: _form.bracketPublishDate,
    bracketPublishDateError: _form.bracketPublishDateError,
    onPickBracketPublishDate: () async {
      final picked = await _pickDateTime(
        initialDate: _form.bracketPublishDate,
        helpText: 'Cuándo se publican los cuadros',
      );
      if (picked != null && mounted) {
        setState(() {
          _form.bracketPublishDate = picked;
          _form.bracketPublishDateError = null;
        });
        _markDraftDirtyAndScheduleAutosave();
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
    duplicateTournament: _submitController.duplicateTournament,
    isCheckingDuplicate: _submitController.isCheckingDuplicate,
    duplicateCheckErrorMessage: _submitController.duplicateCheckErrorMessage,
    onViewDuplicateTournament: _openExistingTournament,
    onQueryChanged: (query) {
      _form.clearFieldError('location');
      _form.onLocationQueryChanged(query);
      _acknowledgedDuplicateWarningKey = null;
      if (_submitController.duplicateTournament != null) {
        _submitController.clearDuplicate();
      }
    },
    onSuggestionSelected: (result) {
      _form.selectLocation(result);
      setState(() {});
      _markDraftDirtyAndScheduleAutosave();
    },
    onMapTap: (lat, lng) async {
      await _form.onMapTap(lat, lng);
      _markDraftDirtyAndScheduleAutosave();
    },
  );

  Future<AppTournament?> _checkDuplicate() async {
    if (_form.eventDate != null &&
        _form.locationController.text.trim().isNotEmpty) {
      await _submitController.checkDuplicateTournament(
        scheduledAt: _form.eventDate!,
        location: _form.locationController.text,
      );
      return _submitController.duplicateTournament;
    }
    return null;
  }

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
    onAccessTypeChanged: (type) {
      setState(() {
        _form.selectedAccessType = type;
        _form.accessTypeError = null;
      });
      _markDraftDirtyAndScheduleAutosave();
    },
  );

  Widget _buildStep5() => Step5Rules(
    rulesController: _form.rulesController,
    rulesError: _form.rulesError,
    onRulesChanged: (_) => _form.clearFieldError('rules'),
  );

  Widget _buildStep6Categories() => Step6Categories(
    categoryController: _form.categoryController,
    categories: _form.categories,
    onAddCategory: _addCategory,
    onRemoveCategory: _removeCategory,
  );

  Widget _buildStep7RegistrationForm() => RegistrationFormBuilder(
    schema: _form.registrationForm,
    errorText: _form.registrationFormError,
    onUpsertField: _form.upsertRegistrationField,
    onRemoveField: _form.removeRegistrationField,
    onToggleField: _form.toggleRegistrationField,
    onMoveField: _form.moveRegistrationField,
  );

  Widget _buildStep7Staff() => Step6Staff(
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
    onAddContactLink: () {
      setState(() => _form.addContactLink());
      _markDraftDirtyAndScheduleAutosave();
    },
    onRemoveContactLink: (i) {
      setState(() => _form.removeContactLink(i));
      _markDraftDirtyAndScheduleAutosave();
    },
  );

  Widget _buildStep8Review() => Step7Review(
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
    categories: _form.categories,
    contactEmail: _form.contactEmailController.text.trim().isEmpty
        ? '—'
        : _form.contactEmailController.text.trim(),
    contactPhone: _form.contactPhoneController.text.trim().isEmpty
        ? null
        : _form.contactPhoneController.text.trim(),
    contactLinks: _form.contactLinks,
    registrationFields: _form.registrationForm.activeFields.length,
    pendingAdminLabels: _form.extraAdmins
        .map((a) => a.label)
        .toList(growable: false),
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

// ════════════════════════════════════════════════════════════════
//  _DuplicateWarningSheet
//
//  Bottom-sheet que avisa al organizador de que ya existe un torneo
//  con la misma fecha, hora de inicio y lugar. Ofrece dos acciones:
//    1. Ver el torneo existente.
//    2. Entendido, continuar (cierra el sheet).
// ════════════════════════════════════════════════════════════════

class _DuplicateWarningSheet extends StatelessWidget {
  const _DuplicateWarningSheet({
    required this.duplicate,
    required this.onViewTournament,
    required this.onModify,
  });

  final AppTournament duplicate;
  final VoidCallback onViewTournament;
  final VoidCallback onModify;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Empuja el sheet por encima del teclado si estuviese abierto.
      padding: MediaQuery.viewInsetsOf(context),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D2B),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 24),

            // Icono de advertencia
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFB347).withValues(alpha: 0.25),
                    const Color(0xFFFF4D6A).withValues(alpha: 0.15),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFFFB347).withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFFB347),
                size: 32,
              ),
            ),
            const SizedBox(height: 18),

            // Título
            const Text(
              'Torneo duplicado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Descripción
            Text(
              'Ya existe un torneo programado con la misma fecha, hora de inicio y lugar.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Puedes continuar igualmente, pero confirma que has revisado este aviso para evitar crear un duplicado.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Tarjeta del torneo en conflicto
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(
                  color: const Color(0xFFFFB347).withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFFFB347),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          duplicate.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.white.withValues(alpha: 0.4),
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          duplicate.location,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white.withValues(alpha: 0.4),
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(duplicate.scheduledAt),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botón principal: ver torneo existente
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: 'Ver torneo existente',
                icon: Icons.open_in_new_rounded,
                variant: GradientButtonVariant.sunset,
                size: GradientButtonSize.large,
                onPressed: onViewTournament,
              ),
            ),
            const SizedBox(height: 10),

            // Botón secundario: continuar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onModify,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Entendido, continuar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}
