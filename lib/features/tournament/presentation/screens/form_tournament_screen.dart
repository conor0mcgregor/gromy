import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/model/enums_tournament.dart';
import '../../../../core/widgets/glow_orb.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../user/data/services/firestore_user_service.dart';
import '../controllers/create_tournament_controller.dart';

// Importación de pasos refactorizados
import 'form/steps/step0_basic_info.dart';
import 'form/steps/step1_sport.dart';
import 'form/steps/step2_date_location.dart';
import 'form/steps/step3_participants.dart';
import 'form/steps/step4_summary_admins.dart';
import 'form/steps/step5_details.dart';

// Importación de widgets y helpers
import 'form/widgets/form_helpers.dart';

class FormTournamentScreen extends StatefulWidget {
  const FormTournamentScreen({super.key});

  @override
  State<FormTournamentScreen> createState() => _FormTournamentScreenState();
}

class _FormTournamentScreenState extends State<FormTournamentScreen>
    with TickerProviderStateMixin {
  late final CreateTournamentController _createTournamentController;

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

  // ── Paso actual (0-indexed) ──
  int _currentStep = 0;

  // ── Formulario: valores recogidos ──
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _completeInformation = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _membersPerTeamController = TextEditingController();
  final _adminController = TextEditingController();
  DateTime? _selectedDate;
  TournamentSport? _selectedSport;
  TournamentAccessType? _selectedAccessType;

  // ── Portada + administradores ──
  final _imagePicker = ImagePicker();
  XFile? _coverImage;
  Uint8List? _coverBytes;
  bool _isAddingAdmin = false;
  String? _adminError;
  final List<FormAdminEntry> _extraAdmins = [];

  // ── Errores por paso ──
  String? _nameError;
  String? _descriptionError;
  String? _completeInfoError;
  String? _locationError;
  String? _dateError;
  String? _maxParticipantsError;
  String? _membersPerTeamError;
  String? _sportError;
  String? _accessTypeError;

  // ── Pasos definidos ──
  static const int _totalSteps = 6;

  bool get _isSubmitting => _createTournamentController.isSubmitting;

  @override
  void initState() {
    super.initState();
    _createTournamentController = CreateTournamentController()
      ..addListener(() {
        if (mounted) setState(() {});
      });

    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _slideController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _slideController, curve: Curves.easeOutCubic));

    _stepController = AnimationController(
        duration: const Duration(milliseconds: 350), vsync: this);
    _stepFade =
        CurvedAnimation(parent: _stepController, curve: Curves.easeOut);
    _stepSlide =
        Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _stepController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
    _stepController.forward();
  }

  @override
  void dispose() {
    _createTournamentController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _stepController.dispose();
    _pageController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _completeInformation.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _membersPerTeamController.dispose();
    _adminController.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    FocusScope.of(context).unfocus();
    if (!_validateCurrentStep()) return;

    if (_currentStep < _totalSteps - 1) {
      await _animateStepTransition(() {
        setState(() => _currentStep++);
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
    if (_currentStep > 0) {
      FocusScope.of(context).unfocus();
      await _animateStepTransition(() {
        setState(() => _currentStep--);
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
    _stepController.forward();
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _validateStep0();
      case 1:
        return _validateStep5();
      case 2:
        return _validateStep1();
      case 3:
        return _validateStep2();
      case 4:
        return _validateStep3();
      case 5:
        return true; 
      default:
        return true;
    }
  }

  bool _validateStep0() {
    final nameOk = _nameController.text.trim().length >= 3;
    final descOk = _descriptionController.text.trim().length >= 10;
    final coverOk = _coverBytes != null && _coverBytes!.isNotEmpty;
    setState(() {
      _nameError =
          nameOk ? null : 'El nombre debe tener al menos 3 caracteres.';
      _descriptionError =
          descOk ? null : 'Añade una descripción un poco más larga.';
    });
    if (!coverOk) {
      _showSnackBar('Debes añadir una portada para el torneo.', isError: true);
    }
    return nameOk && descOk && coverOk;
  }

  bool _validateStep1() {
    final sportOk = _selectedSport != null;
    setState(() {
      _sportError = sportOk ? null : 'Elige el deporte del torneo.';
    });
    return sportOk;
  }

  bool _validateStep5() {
    final completeOk = _completeInformation.text.trim().length >= 100;
    setState(() {
      _completeInfoError = completeOk
          ? null
          : 'Añade más información sobre el torneo (mín. 100 caracteres).';
    });
    return completeOk;
  }

  bool _validateStep2() {
    final today = DateTime.now();
    final minDate = DateTime(today.year, today.month, today.day);
    final dateOk = _selectedDate != null && !_selectedDate!.isBefore(minDate);
    final locOk = _locationController.text.trim().isNotEmpty;
    setState(() {
      _dateError = _selectedDate == null
          ? 'Elige la fecha del torneo.'
          : !dateOk
              ? 'La fecha debe ser hoy o en el futuro.'
              : null;
      _locationError = locOk ? null : '¿Dónde se juega? Indica el lugar.';
    });
    return dateOk && locOk;
  }

  bool _validateStep3() {
    final maxP = int.tryParse(_maxParticipantsController.text.trim());
    final membersPerTeam = int.tryParse(_membersPerTeamController.text.trim());

    final maxOk = maxP != null && maxP >= 2;
    final membersOk = membersPerTeam != null && membersPerTeam >= 2;
    final relationOk = maxOk && membersOk && membersPerTeam <= maxP;
    final accessOk = _selectedAccessType != null;

    setState(() {
      _maxParticipantsError = maxP == null
          ? 'Escribe un número de participantes.'
          : !maxOk
              ? 'Debe haber al menos 2 participantes.'
              : null;

      _membersPerTeamError = membersPerTeam == null
          ? 'Escribe cuántos miembros tendrá cada equipo.'
          : !membersOk
              ? 'Cada equipo debe tener al menos 2 miembros.'
              : !relationOk
                  ? 'Los miembros por equipo no pueden superar el total de participantes.'
                  : null;

      _accessTypeError = accessOk ? null : 'Indica quién puede apuntarse.';
    });

    return maxOk && membersOk && relationOk && accessOk;
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final maxParticipants =
        int.tryParse(_maxParticipantsController.text.trim()) ?? 0;
    final membersPerTeam =
        int.tryParse(_membersPerTeamController.text.trim()) ?? 0;
    final extraAdminIds =
        _extraAdmins.map((entry) => entry.uid).toList(growable: false);
        
    final success = await _createTournamentController.createTournament(
      name: _nameController.text,
      description: _descriptionController.text,
      allInformation: _completeInformation.text,
      sport: _selectedSport!,
      scheduledAt: _selectedDate!,
      maxParticipants: maxParticipants,
      membersPerTeam: membersPerTeam,
      location: _locationController.text,
      accessType: _selectedAccessType!,
      extraAdminIds: extraAdminIds,
      coverImage: _coverImage,
    );

    if (success) {
      if (mounted) Navigator.pop(context);
      _showSnackBar('Torneo creado con éxito!', isError: false);
    } else {
      _showSnackBar(
          _createTournamentController.errorMessage ??
              'Error al crear el torneo.',
          isError: true);
    }
  }

  Future<void> _confirmDiscard() async {
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
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF4D6A),
            ),
            child: const Text('Sí, borrar todo',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final today = DateTime.now();
    final initial =
        _selectedDate ?? DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
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
          dialogTheme:
              const DialogThemeData(backgroundColor: Color(0xFF101127)),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = picked;
      _dateError = null;
    });
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
        _coverImage = picked;
        _coverBytes = bytes;
      });
    } catch (_) {
      _showSnackBar('No se pudo seleccionar la imagen.', isError: true);
    }
  }

  void _removeCover() {
    setState(() {
      _coverImage = null;
      _coverBytes = null;
    });
  }

  Future<void> _addAdmin() async {
    if (_isAddingAdmin) return;
    FocusScope.of(context).unfocus();
    final raw = _adminController.text.trim();
    if (raw.isEmpty) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      setState(() => _adminError = 'Debes iniciar sesión para asignar admins.');
      return;
    }

    setState(() {
      _isAddingAdmin = true;
      _adminError = null;
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
          setState(() =>
              _adminError = 'No existe un usuario con ese nickname o UID.');
          return;
        }
        uid = raw;
        final user = await userService.getUser(raw);
        label = user != null ? '@${user.nickname}' : raw;
      }


      
      if (uid == currentUid) {
        setState(() => _adminError = 'Ya eres admin por defecto.');
        return;
      }

      if (_extraAdmins.any((e) => e.uid == uid)) {
        setState(() => _adminError = 'Ese usuario ya está añadido.');
        return;
      }

      setState(() {
        _extraAdmins.add(FormAdminEntry(uid: uid!, label: label));
        _adminController.clear();
        _adminError = null;
      });
    } catch (_) {
      setState(() => _adminError = 'No se pudo añadir el admin.');
    } finally {
      if (mounted) {
        setState(() => _isAddingAdmin = false);
      }
    }
  }

  void _removeAdmin(String uid) {
    setState(() {
      _extraAdmins.removeWhere((e) => e.uid == uid);
      _adminError = null;
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.info_outline_rounded
                  : Icons.check_circle_rounded,
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                size: 280),
          ),
          Positioned(
            bottom: 60,
            right: -80,
            child: GlowOrb(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.25),
                size: 240),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.45,
            left: MediaQuery.of(context).size.width * 0.3,
            child: GlowOrb(
                color: const Color(0xFFFF6B9D).withValues(alpha: 0.15),
                size: 160),
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
                            constraints:
                                BoxConstraints(maxWidth: isWide ? 880 : 620),
                            child: _buildHeader(),
                          ),
                        ),
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildStepPage(Step0BasicInfo(
                                nameController: _nameController,
                                descriptionController: _descriptionController,
                                nameError: _nameError,
                                descriptionError: _descriptionError,
                                coverBytes: _coverBytes,
                                onNameChanged: (_) =>
                                    setState(() => _nameError = null),
                                onDescriptionChanged: (_) =>
                                    setState(() => _descriptionError = null),
                                onPickCover: _pickCover,
                                onRemoveCover: _removeCover,
                              )),
                              _buildStepPage(Step5Details(
                                completeInformationController:
                                    _completeInformation,
                                completeInfoError: _completeInfoError,
                                onInfoChanged: (_) =>
                                    setState(() => _completeInfoError = null),
                              )),
                              _buildStepPage(Step1Sport(
                                selectedSport: _selectedSport,
                                sportError: _sportError,
                                onSportChanged: (sport) => setState(() {
                                  _selectedSport = sport;
                                  _sportError = null;
                                }),
                              )),
                              _buildStepPage(Step2DateLocation(
                                selectedDate: _selectedDate,
                                dateError: _dateError,
                                locationController: _locationController,
                                locationError: _locationError,
                                onPickDate: _pickDate,
                                onLocationChanged: (_) =>
                                    setState(() => _locationError = null),
                              )),
                              _buildStepPage(Step3Participants(
                                selectedSport: _selectedSport,
                                maxParticipantsController:
                                    _maxParticipantsController,
                                maxParticipantsError: _maxParticipantsError,
                                membersPerTeamController:
                                    _membersPerTeamController,
                                membersPerTeamError: _membersPerTeamError,
                                selectedAccessType: _selectedAccessType,
                                accessTypeError: _accessTypeError,
                                onMaxParticipantsChanged: (_) =>
                                    setState(() => _maxParticipantsError = null),
                                onMembersPerTeamChanged: (_) =>
                                    setState(() => _membersPerTeamError = null),
                                onAccessTypeChanged: (type) => setState(() {
                                  _selectedAccessType = type;
                                  _accessTypeError = null;
                                }),
                              )),
                              _buildStepPage(Step4SummaryAdmins(
                                name: _nameController.text.trim().isEmpty
                                    ? '—'
                                    : _nameController.text.trim(),
                                sport: _selectedSport?.label ?? '—',
                                date: _selectedDate == null
                                    ? '—'
                                    : _formatDate(_selectedDate!),
                                location:
                                    _locationController.text.trim().isEmpty
                                        ? '—'
                                        : _locationController.text.trim(),
                                participants: _maxParticipantsController.text
                                        .trim()
                                        .isEmpty
                                    ? '—'
                                    : _maxParticipantsController.text.trim(),
                                access: _selectedAccessType?.label ?? '—',
                                adminController: _adminController,
                                adminError: _adminError,
                                isAddingAdmin: _isAddingAdmin,
                                extraAdmins: _extraAdmins,
                                onAdminChanged: (_) =>
                                    setState(() => _adminError = null),
                                onAddAdmin: _addAdmin,
                                onRemoveAdmin: _removeAdmin,
                              )),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth: isWide ? 880 : 620),
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
    );
  }

  Widget _buildHeader() {
    final stepLabels = [
      'Información básica',
      'Toda la información',
      'Deporte',
      'Cuándo y dónde',
      'Participantes',
      'Detalles finales',
    ];

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D6A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color:
                          const Color(0xFFFF4D6A).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFFF4D6A), size: 16),
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
          children: List.generate(_totalSteps, (i) {
            final isActive = i == _currentStep;
            final isDone = i < _currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: isActive || isDone
                      ? const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)])
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
                stepLabels[_currentStep],
                key: ValueKey(_currentStep),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'Paso ${_currentStep + 1} de $_totalSteps',
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

  Widget _buildNavButtons() {
    final isLast = _currentStep == _totalSteps - 1;

    return Row(
      children: [
        if (_currentStep > 0) ...[
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
