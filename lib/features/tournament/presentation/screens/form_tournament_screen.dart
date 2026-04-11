import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/model/enums_tournament.dart';
import '../../../../core/widgets/glow_orb.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../user/data/services/firestore_user_service.dart';
import '../controllers/create_tournament_controller.dart';

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
  final List<_AdminEntry> _extraAdmins = [];


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

  // ── Estado de envío final ──
  // ──────────────────────────────────────────────────────────────
  //  Pasos definidos
  // ──────────────────────────────────────────────────────────────
  static const int _totalSteps = 6;

  bool get _isSubmitting => _createTournamentController.isSubmitting;

  // ──────────────────────────────────────────────────────────────
  //  Lifecycle
  // ──────────────────────────────────────────────────────────────

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
    _adminController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  //  Navegación entre pasos
  // ──────────────────────────────────────────────────────────────

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

  // ──────────────────────────────────────────────────────────────
  //  Validación por paso
  // ──────────────────────────────────────────────────────────────

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
        return true; // Notas opcionales
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
      _completeInfoError =
      completeOk ? null : 'Añade más información sobre el torneo (mín. 100 caracteres).';
    });
    return completeOk;
  }

  bool _validateStep2() {
    final today = DateTime.now();
    final minDate = DateTime(today.year, today.month, today.day);
    final dateOk =
        _selectedDate != null && !_selectedDate!.isBefore(minDate);
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
      // Validación de participantes máximos
      _maxParticipantsError = maxP == null
          ? 'Escribe un número de participantes.'
          : !maxOk
          ? 'Debe haber al menos 2 participantes.'
          : null;

      // Validación de miembros por equipo
      _membersPerTeamError = membersPerTeam == null
          ? 'Escribe cuántos miembros tendrá cada equipo.'
          : !membersOk
          ? 'Cada equipo debe tener al menos 2 miembros.'
          : !relationOk
          ? 'Los miembros por equipo no pueden superar el total de participantes.'
          : null;

      // Validación de tipo de acceso
      _accessTypeError = accessOk ? null : 'Indica quién puede apuntarse.';
    });

    return maxOk && membersOk && relationOk && accessOk;
  }


  // ──────────────────────────────────────────────────────────────
  //  Submit final
  // ──────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final maxParticipants = int.tryParse(_maxParticipantsController.text.trim()) ?? 0;
    final membersPerTeam = int.tryParse(_membersPerTeamController.text.trim()) ?? 0;
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
      _showSnackBar(_createTournamentController.errorMessage ?? 'Error al crear el torneo.', isError: true);
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
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF4D6A),
            ),
            child: const Text('Sí, borrar todo', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.pop(context);
    }
  }

  // ──────────────────────────────────────────────────────────────
  //  Helpers
  // ──────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final today = DateTime.now();
    final initial = _selectedDate ?? DateTime(today.year, today.month, today.day);
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
          setState(() => _adminError = 'No existe un usuario con ese nickname o UID.');
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
        _extraAdmins.add(_AdminEntry(uid: uid!, label: label));
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

  IconData _getAccessTypeIcon(TournamentAccessType type) => switch (type) {
    TournamentAccessType.publicOpen => Icons.public_rounded,
    TournamentAccessType.publicClosed => Icons.lock_open_rounded,
    TournamentAccessType.privateInviteOnly => Icons.mail_lock_rounded,
  };

  IconData _sportIcon(TournamentSport sport) => switch (sport) {
    TournamentSport.football => Icons.sports_soccer_rounded,
    TournamentSport.basketball => Icons.sports_basketball_rounded,
    TournamentSport.volleyball => Icons.sports_volleyball_rounded,
    TournamentSport.tennis => Icons.sports_tennis_rounded,
    TournamentSport.padel => Icons.sports_tennis_rounded,
    TournamentSport.karate => Icons.sports_martial_arts_rounded,
    TournamentSport.brazilianJiuJitsu => Icons.sports_kabaddi_rounded,
  };

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

  // ──────────────────────────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          // Orbes ambiente
          Positioned(
            top: -80,
            left: -60,
            child: GlowOrb(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.35), size: 280),
          ),
          Positioned(
            bottom: 60,
            right: -80,
            child: GlowOrb(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.25), size: 240),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.45,
            left: MediaQuery.of(context).size.width * 0.3,
            child: GlowOrb(
                color: const Color(0xFFFF6B9D).withValues(alpha: 0.15), size: 160),
          ),

          // Contenido
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
                        // ── Header fijo con progreso ──
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: ConstrainedBox(
                            constraints:
                            BoxConstraints(maxWidth: isWide ? 880 : 620),
                            child: _buildHeader(),
                          ),
                        ),

                        // ── Contenido del paso (PageView) ──
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildStepPage(_buildStep0()),
                              _buildStepPage(_buildStep5()),
                              _buildStepPage(_buildStep1()),
                              _buildStepPage(_buildStep2()),
                              _buildStepPage(_buildStep3()),
                              _buildStepPage(_buildStep4()),
                            ],
                          ),
                        ),

                        // ── Botones de navegación fijos ──
                        Padding(
                          padding:
                          const EdgeInsets.fromLTRB(20, 12, 20, 28),
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

  // ──────────────────────────────────────────────────────────────
  //  Header: título de paso + barra de progreso
  // ──────────────────────────────────────────────────────────────

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
        // Botón de descartar 
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: _confirmDiscard,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D6A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF4D6A).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4D6A), size: 16),
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

        // Indicadores de paso
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

        // Paso actual / texto
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

  // ──────────────────────────────────────────────────────────────
  //  Wrapper de página con animación
  // ──────────────────────────────────────────────────────────────

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

  // ──────────────────────────────────────────────────────────────
  //  Botones de navegación
  // ──────────────────────────────────────────────────────────────

  Widget _buildNavButtons() {
    final isLast = _currentStep == _totalSteps - 1;

    return Row(
      children: [
        // Botón Atrás
        if (_currentStep > 0) ...[
          SizedBox(
            height: 52,
            child: _OutlineButton(
              label: 'Atrás',
              icon: Icons.arrow_back_rounded,
              onPressed: _goBack,
            ),
          ),
          const SizedBox(width: 12),
        ],

        // Botón Siguiente / Crear
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

  // ══════════════════════════════════════════════════════════════
  //  PASO 0 — Nombre y descripción
  // ══════════════════════════════════════════════════════════════

  Widget _buildStep0() {
    return _StepCard(
      icon: Icons.drive_file_rename_outline_rounded,
      title: 'Nombre del torneo',
      subtitle: 'Dale una identidad a tu torneo. El nombre es lo primero que verán los participantes.',
      child: Column(
        children: [
          _buildCoverPicker(),
          const SizedBox(height: 18),
          _GlassField(
            controller: _nameController,
            hint: 'Ej. Liga Primavera 2026',
            icon: Icons.emoji_events_rounded,
            label: 'Nombre',
            errorText: _nameError,
            capitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => _nameError = null),
          ),
          const SizedBox(height: 16),
          _GlassField(
            controller: _descriptionController,
            hint:
            'Comenta brevemente en que consiste',
            icon: Icons.notes_rounded,
            label: 'Descripción',
            errorText: _descriptionError,
            maxLines: 4,
            minLines: 4,
            capitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() => _descriptionError = null),
          ),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return _StepCard(
      icon: Icons.text_snippet,
      title: 'Información completa',
      subtitle: 'Especifica toda la información, detalles, reglas, datos, etc... del torneo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GlassField(
            controller: _completeInformation,
            hint: 'Información adicional (mínimo 100 caracteres)\nReglas del torneo, fechas clave...',
            icon: Icons.text_snippet,
            label: 'Información completa',
            errorText: _completeInfoError,
            minLines: 5,
            maxLines: 15,
          )
        ]
      )
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  PASO 1 — Deporte
  // ══════════════════════════════════════════════════════════════

  Widget _buildStep1() {
    return _StepCard(
      icon: Icons.sports_rounded,
      title: '¿Qué deporte?',
      subtitle: 'Selecciona la modalidad deportiva del torneo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth >= 400 ? 2 : 1;
            const spacing = 10.0;
            final w = (c.maxWidth - spacing * (cols - 1)) / cols;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: TournamentSport.values.map((sport) {
                final selected = _selectedSport == sport;
                return SizedBox(
                  width: w,
                  child: _SportChip(
                    title: sport.label,
                    icon: _sportIcon(sport),
                    selected: selected,
                    onTap: () => setState(() {
                      _selectedSport = sport;
                      _sportError = null;
                    }),
                  ),
                );
              }).toList(),
            );
          }),
          if (_sportError != null) ...[
            const SizedBox(height: 10),
            _ErrorText(message: _sportError!),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  PASO 2 — Fecha y lugar
  // ══════════════════════════════════════════════════════════════

  Widget _buildStep2() {
    return _StepCard(
      icon: Icons.event_rounded,
      title: 'Cuándo y dónde',
      subtitle: 'Indica la fecha y el lugar donde se celebrará el torneo.',
      child: Column(
        children: [
          // Selector de fecha
          _FieldLabel(label: 'Fecha del torneo'),
          const SizedBox(height: 8),
          _PickerTile(
            icon: Icons.calendar_month_rounded,
            value: _selectedDate == null
                ? 'Elige una fecha'
                : _formatDate(_selectedDate!),
            isEmpty: _selectedDate == null,
            errorText: _dateError,
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),

          // Campo lugar
          _GlassField(
            controller: _locationController,
            hint: 'Ciudad, pabellón o dirección',
            icon: Icons.location_on_outlined,
            label: 'Lugar',
            errorText: _locationError,
            capitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => _locationError = null),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  PASO 3 — Participantes y acceso
  // ══════════════════════════════════════════════════════════════

  Widget _buildStep3() {
    if (_selectedSport == null) return const SizedBox.shrink();

    final isTeamSport = _isTeamSport(_selectedSport!);

    return _StepCard(
      icon: Icons.groups_2_rounded,
      title: 'Participantes',
      subtitle:
      'Define cuántos pueden apuntarse y quién tiene acceso al torneo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GlassField(
            controller: _maxParticipantsController,
            hint: 'Ej. 16',
            icon: Icons.groups_2_rounded,
            label: isTeamSport? 'Número máximo de equipos' : 'Número máximo de participantes',
            errorText: _maxParticipantsError,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() => _maxParticipantsError = null),
          ),
          const SizedBox(height: 16),
          if (isTeamSport) ...[
            _GlassField(
              controller: _membersPerTeamController,
              hint: 'Ej. 5',
              icon: Icons.group,
              label: 'Miembros por equipo',
              errorText: _membersPerTeamError,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() => _membersPerTeamError = null),
            ),
          ],
          const SizedBox(height: 20),
          _FieldLabel(label: '¿Quién puede apuntarse?'),
          const SizedBox(height: 10),
          ...TournamentAccessType.values.map(
                (type) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AccessCard(
                title: type.label,
                subtitle: type.description,
                icon: _getAccessTypeIcon(type),
                selected: _selectedAccessType == type,
                onTap: () => setState(() {
                  _selectedAccessType = type;
                  _accessTypeError = null;
                }),
              ),
            ),
          ),
          if (_accessTypeError != null) _ErrorText(message: _accessTypeError!),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  PASO 4 — Notas adicionales + resumen
  // ══════════════════════════════════════════════════════════════

  Widget _buildStep4() {
    return _StepCard(
      icon: Icons.sticky_note_2_outlined,
      title: 'Casi listo 🎉',
      subtitle:
      'Revisa el resumen antes de crear el torneo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdminsSection(),
          const SizedBox(height: 24),

          // Resumen
          _SummaryCard(
            name: _nameController.text.trim().isEmpty
                ? '—'
                : _nameController.text.trim(),
            sport: _selectedSport?.label ?? '—',
            date: _selectedDate == null ? '—' : _formatDate(_selectedDate!),
            location: _locationController.text.trim().isEmpty
                ? '—'
                : _locationController.text.trim(),
            participants:
            _maxParticipantsController.text.trim().isEmpty
                ? '—'
                : _maxParticipantsController.text.trim(),
            access: _selectedAccessType?.label ?? '—',
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPicker() {
    final hasImage = _coverBytes != null && _coverBytes!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'Portada'),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.white.withValues(alpha: 0.06),
              child: InkWell(
                onTap: _pickCover,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasImage)
                        Image.memory(_coverBytes!, fit: BoxFit.cover)
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF2B2B53),
                                Color(0xFF12122E),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Opacity(
                              opacity: 0.85,
                              child: Image.asset(
                                'assets/images/LOGO.png',
                                width: 56,
                                height: 56,
                              ),
                            ),
                          ),
                        ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.35),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.black.withValues(alpha: 0.35),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_library_outlined,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                hasImage ? 'Cambiar portada' : 'Elegir portada',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (hasImage)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: InkWell(
                            onTap: _removeCover,
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.35),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminsSection() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final showCreatorChip = currentUid != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.admin_panel_settings_outlined,
                color: Color(0xFF00D4FF), size: 18),
            const SizedBox(width: 10),
            Text(
              'Administradores',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'El creador siempre será admin. Añade otros por nickname o UID.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12.5,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _GlassField(
                controller: _adminController,
                hint: 'Nickname o UID',
                icon: Icons.person_add_alt_1_rounded,
                label: 'Añadir admin (opcional)',
                onChanged: (_) => setState(() => _adminError = null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: _OutlineButton(
            label: _isAddingAdmin ? '...' : 'Añadir',
            icon: Icons.add_rounded,
            onPressed: _isAddingAdmin ? () {} : _addAdmin,
          ),
        ),

        if (_adminError != null) ...[
          const SizedBox(height: 8),
          _ErrorText(message: _adminError!),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (showCreatorChip)
              const _AdminChip(
                label: 'Tú (creador)',
                isFixed: true,
              ),
            ..._extraAdmins.map(
              (admin) => _AdminChip(
                label: admin.label,
                isFixed: false,
                onRemove: () => _removeAdmin(admin.uid),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _isTeamSport(TournamentSport sport) {
    return sport == TournamentSport.football ||
        sport == TournamentSport.basketball ||
        sport == TournamentSport.volleyball;
  }
}

class _AdminEntry {
  const _AdminEntry({required this.uid, required this.label});
  final String uid;
  final String label;
}

class _AdminChip extends StatelessWidget {
  const _AdminChip({
    required this.label,
    required this.isFixed,
    this.onRemove,
  });

  final String label;
  final bool isFixed;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_outlined,
              color: Color(0xFFB0A8FF), size: 16),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!isFixed) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close_rounded,
                    color: Colors.white70, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  WIDGETS REUTILIZABLES
// ════════════════════════════════════════════════════════════════

// ── Tarjeta de paso ──────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6C63FF).withValues(alpha: 0.14),
                const Color(0xFF00D4FF).withValues(alpha: 0.07),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFB0A8FF)],
                          ).createShader(b),
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.58),
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _GlassDivider(),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Campo de texto glassmorphism ─────────────────────────────────

class _GlassField extends StatelessWidget {
  const _GlassField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.label,
    this.errorText,
    this.maxLines = 1,
    this.minLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.capitalization = TextCapitalization.none,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String label;
  final String? errorText;
  final int maxLines;
  final int minLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: errorText != null
                ? const Color(0xFFFF4D6A).withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: errorText != null
                  ? const Color(0xFFFF4D6A).withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.1),
              width: errorText != null ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            minLines: minLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: capitalization,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.32),
                fontSize: 14,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(icon, color: Colors.white38, size: 20),
              ),
              prefixIconConstraints:
              const BoxConstraints(minWidth: 44, minHeight: 44),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          _ErrorText(message: errorText!),
        ],
      ],
    );
  }
}

// ── Selector de fecha (tile) ─────────────────────────────────────

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.value,
    required this.isEmpty,
    required this.onTap,
    this.errorText,
  });

  final IconData icon;
  final String value;
  final bool isEmpty;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: errorText != null
                  ? const Color(0xFFFF4D6A).withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.07),
              border: Border.all(
                color: errorText != null
                    ? const Color(0xFFFF4D6A).withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.1),
                width: errorText != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white38, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: isEmpty
                          ? Colors.white.withValues(alpha: 0.32)
                          : Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white38),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          _ErrorText(message: errorText!),
        ],
      ],
    );
  }
}

// ── Chip de deporte ───────────────────────────────────────────────

class _SportChip extends StatelessWidget {
  const _SportChip({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selected
                ? const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.09),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.07),
                ),
                child: Icon(icon, color: Colors.white, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white
                        .withValues(alpha: selected ? 1.0 : 0.85),
                    fontSize: 13,
                    fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 15),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tarjeta de tipo de acceso ────────────────────────────────────

class _AccessCard extends StatelessWidget {
  const _AccessCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: selected
                ? const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)])
                : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.28)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.24),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: selected
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 0.06),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12,
                            height: 1.3)),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: Colors.white.withValues(alpha: selected ? 1 : 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Resumen final ────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.name,
    required this.sport,
    required this.date,
    required this.location,
    required this.participants,
    required this.access,
  });

  final String name;
  final String sport;
  final String date;
  final String location;
  final String participants;
  final String access;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded,
                  color: Color(0xFF00D4FF), size: 18),
              const SizedBox(width: 8),
              Text(
                'Resumen del torneo',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SummaryRow(label: 'Nombre', value: name),
          _SummaryRow(label: 'Deporte', value: sport),
          _SummaryRow(label: 'Fecha', value: date),
          _SummaryRow(label: 'Lugar', value: location),
          _SummaryRow(label: 'Participantes', value: participants),
          _SummaryRow(label: 'Acceso', value: access, isLast: true),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.06),
              thickness: 1),
      ],
    );
  }
}

// ── Botón outline ────────────────────────────────────────────────

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            color: Colors.white.withValues(alpha: 0.05),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white60, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pequeños helpers ─────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      color: Colors.white.withValues(alpha: 0.72),
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 1),
        child: Icon(Icons.error_outline_rounded,
            color: Color(0xFFFF4D6A), size: 13),
      ),
      const SizedBox(width: 5),
      Expanded(
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFFFF4D6A),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}

class _GlassDivider extends StatelessWidget {
  const _GlassDivider();

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ),
    ),
  );
}
