import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../invitation/presentation/controllers/generate_invitation_controller.dart';
import '../../../tournament/data/model/enums_tournament.dart';

import '../../../../core/getColors/getter_colors.dart';
import '../../../../core/widgets/bar_small_botton.dart';
import '../../../../core/widgets/dividers.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/participant_card.dart';
import '../../../../core/widgets/static_location_map.dart';
import '../../../brackets/presentation/widgets/brankets_section.dart';
import '../../../participants/data/models/participant_display.dart';
import '../../../participants/presentation/widgets/participants_section.dart';
import '../../../participants/presentation/widgets/team_card.dart';
import '../../../inscription/screen/tournament_join_requests_screen.dart';
import '../../../tournament/data/model/app_tournament.dart';
import '../../../tournament/presentation/screens/create_tournament/form/widgets/registration_form_builder.dart';
import '../../../tournament/presentation/screens/create_tournament/form/steps/step3_geolocation.dart';
import '../../../user/data/models/app_user.dart';
import '../controllers/tournament_management_controller.dart';
import 'participants_management.dart';

class TournamentManagementScreen extends StatefulWidget {
  const TournamentManagementScreen({super.key, required this.tournament});

  final AppTournament tournament;

  @override
  State<TournamentManagementScreen> createState() =>
      _TournamentManagementScreenState();
}

class _TournamentManagementScreenState extends State<TournamentManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TournamentManagementController _ctrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  final _imagePicker = ImagePicker();
  final _categoryCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  GenerateInvitationController? _invitationCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TournamentManagementController(tournament: widget.tournament)
      ..addListener(_onCtrlChange);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    // Preparar controller de invitaciones solo si el torneo es privado
    if (widget.tournament.accessType ==
        TournamentAccessType.privateInviteOnly) {
      _invitationCtrl = GenerateInvitationController(
        tournamentId: widget.tournament.id,
        organizerUid: widget.tournament.organizerUid,
      )..addListener(_onCtrlChange);
    }
  }

  void _onCtrlChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_onCtrlChange)
      ..dispose();
    _invitationCtrl
      ?..removeListener(_onCtrlChange)
      ..dispose();
    _fadeCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate({
    DateTime? initial,
    required String helpText,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: helpText,
      confirmText: 'Siguiente',
      cancelText: 'Cancelar',
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6C63FF),
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
      initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
      helpText: helpText,
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6C63FF),
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
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked != null) _ctrl.setCoverImage(picked);
  }

  void _addCategory() {
    final value = _categoryCtrl.text.trim();
    if (value.isEmpty) return;
    _ctrl.addCategory(value);
    _categoryCtrl.clear();
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
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

  Future<bool> _confirm({
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101127),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Row(
          children: [
            Icon(
              destructive
                  ? Icons.warning_amber_rounded
                  : Icons.help_outline_rounded,
              color: destructive
                  ? const Color(0xFFFF4D6A)
                  : const Color(0xFF6C63FF),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: destructive
                  ? const Color(0xFFFF4D6A)
                  : const Color(0xFF6C63FF),
            ),
            child: Text(
              confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _handleSave() async {
    FocusScope.of(context).unfocus();
    if (!_ctrl.validate()) {
      _showSnack('Revisa los errores en el formulario', isError: true);
      return;
    }

    final confirmed = await _confirm(
      title: 'Guardar cambios',
      message: '¿Seguro que quieres guardar los cambios?',
      confirmLabel: 'Guardar',
    );
    if (!confirmed) return;

    final ok = await _ctrl.saveChanges();
    _showSnack(
      ok
          ? 'Cambios guardados correctamente'
          : (_ctrl.errorMessage ?? 'Error al guardar'),
      isError: !ok,
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await _confirm(
      title: 'Eliminar torneo',
      message:
          'Esta accion es irreversible. Se eliminaran todos los datos y participantes del torneo.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) return;

    final ok = await _ctrl.deleteTournament();
    if (ok && mounted) {
      Navigator.pop(context);
      _showSnack('Torneo eliminado');
    } else if (!ok) {
      _showSnack(_ctrl.errorMessage ?? 'Error al eliminar', isError: true);
    }
  }

  // ignore: unused_element
  Future<void> _handleRemoveParticipant(dynamic participant) async {
    final confirmed = await _confirm(
      title: 'Eliminar participante',
      message: '¿Seguro que quieres eliminar este participante?',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) return;

    final ok = await _ctrl.removeParticipant(participant.participantId);
    _showSnack(
      ok
          ? 'Participante eliminado'
          : (_ctrl.errorMessage ?? 'No se pudo eliminar'),
      isError: !ok,
    );
  }

  void _openLocationPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 18,
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Cambiar ubicación',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _GlassIconButton(
                            icon: Icons.close_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Step3Geolocation(
                        locationController: _ctrl.locationCtrl,
                        locationError: _ctrl.locationError,
                        latitude: _ctrl.edited.latitude,
                        longitude: _ctrl.edited.longitude,
                        suggestions: _ctrl.locationSuggestions,
                        isSearching: _ctrl.isSearchingLocation,
                        onQueryChanged: _ctrl.onLocationQueryChanged,
                        onSuggestionSelected: _ctrl.selectLocation,
                        onMapTap: _ctrl.onMapTap,
                        resolvedAddress: _ctrl.locationCtrl.text,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tournament = _ctrl.original;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Background(),
          AbsorbPointer(
            absorbing: _ctrl.isBusy,
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    _buildAppBar(tournament),
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                          children: [
                            _buildCoverSection(),
                            const SizedBox(height: 24),
                            _buildInfoSection(),
                            const SizedBox(height: 20),
                            _buildParticipantsSection(),
                            const SizedBox(height: 10),
                            BracketsSection(
                              tournamentId: widget.tournament.id,
                              isAdmin: true,
                            ),
                            const SizedBox(height: 20),
                            _buildScheduleSection(),
                            const SizedBox(height: 20),
                            _buildLogisticsSection(),
                            const SizedBox(height: 20),
                            _buildLocationSection(),
                            const SizedBox(height: 20),
                            _buildContactSection(),
                            const SizedBox(height: 20),
                            _buildLinksSection(),
                            const SizedBox(height: 20),
                            _buildCategoriesSection(),
                            const SizedBox(height: 20),
                            _buildRegistrationFormSection(),
                            const SizedBox(height: 20),
                            _buildAdminsSection(),
                            const SizedBox(height: 20),
                            if (_invitationCtrl != null)
                              _buildPlayerInvitationSection(),
                            if (_invitationCtrl != null)
                              const SizedBox(height: 20),
                            if (_ctrl.isCreator && _invitationCtrl != null)
                              _buildInvitationLinkSection(),
                            if (_ctrl.isCreator && _invitationCtrl != null)
                              const SizedBox(height: 20),
                            if (_ctrl.isCreator) _buildDangerZone(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomBar()),
          if (_ctrl.isBusy) const _BlockingLoader(),
        ],
      ),
    );
  }

  Widget _buildAppBar(AppTournament t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión del torneo',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  t.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          _RoleBadge(isCreator: _ctrl.isCreator),
        ],
      ),
    );
  }

  Widget _buildCoverSection() {
    final hasNew = _ctrl.newCoverImage != null;
    final existingUrl = _ctrl.edited.portadaUrl;

    return GestureDetector(
      onTap: _pickCover,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: hasNew
                  ? FutureBuilder<Uint8List>(
                      future: _ctrl.newCoverImage!.readAsBytes(),
                      builder: (ctx, snap) {
                        if (!snap.hasData) return _coverPlaceholder();
                        return Image.memory(snap.data!, fit: BoxFit.cover);
                      },
                    )
                  : (existingUrl != null && existingUrl.isNotEmpty
                        ? Image.network(
                            existingUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, s) => _coverPlaceholder(),
                          )
                        : _coverPlaceholder()),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Cambiar portada',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder() => Container(
    color: const Color(0xFF1A1A3A),
    child: Center(
      child: Icon(
        Icons.image_rounded,
        size: 48,
        color: Colors.white.withValues(alpha: 0.2),
      ),
    ),
  );

  Widget _buildInfoSection() {
    return _buildSection(
      icon: Icons.badge_rounded,
      title: 'Información',
      color: const Color(0xFF6C63FF),
      children: [
        GlassTextField(
          controller: _ctrl.nameCtrl,
          hint: 'Nombre del torneo',
          icon: Icons.emoji_events_rounded,
          textCapitalization: TextCapitalization.words,
          errorText: _ctrl.nameError,
        ),
        const SizedBox(height: 12),
        GlassTextField(
          controller: _ctrl.descriptionCtrl,
          hint: 'Descripción',
          icon: Icons.notes_rounded,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          errorText: _ctrl.descriptionError,
        ),
        const SizedBox(height: 12),
        GlassTextField(
          controller: _ctrl.allInfoCtrl,
          hint: 'Reglamento / información adicional',
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          errorText: _ctrl.allInfoError,
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    return _buildSection(
      icon: Icons.calendar_month_rounded,
      title: 'Cronograma',
      color: const Color(0xFFA855F7),
      children: [
        _DatePickerField(
          label: 'Fecha del evento',
          value: _ctrl.edited.scheduledAt,
          errorText: _ctrl.eventDateError,
          onPick: () async {
            final date = await _pickDate(
              initial: _ctrl.edited.scheduledAt,
              helpText: 'Fecha y hora del evento',
            );
            if (date != null) _ctrl.updateScheduledAt(date);
          },
        ),
        const SizedBox(height: 12),
        _DatePickerField(
          label: 'Límite de inscripción',
          value: _ctrl.edited.registrationDeadline,
          errorText: _ctrl.registrationDeadlineError,
          optional: true,
          onPick: () async {
            final date = await _pickDate(
              initial: _ctrl.edited.registrationDeadline,
              helpText: 'Cierre de inscripciones',
            );
            if (date != null) _ctrl.updateRegistrationDeadline(date);
          },
          onClear: () => _ctrl.updateRegistrationDeadline(null),
        ),
        const SizedBox(height: 12),
        _DatePickerField(
          label: 'Publicación de cuadros',
          value: _ctrl.edited.bracketPublishDate,
          errorText: _ctrl.bracketPublishDateError,
          optional: true,
          onPick: () async {
            final date = await _pickDate(
              initial: _ctrl.edited.bracketPublishDate,
              helpText: 'Cuándo se publican los cuadros',
            );
            if (date != null) _ctrl.updateBracketPublishDate(date);
          },
          onClear: () => _ctrl.updateBracketPublishDate(null),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Estado de Inscripciones',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _ctrl.edited.status == TournamentStatus.registration
                          ? 'Abiertas (Público puede inscribirse)'
                          : 'Cerradas (No se permiten más inscripciones)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            _ctrl.edited.status == TournamentStatus.registration
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFFF4D6A),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: _ctrl.edited.status == TournamentStatus.registration,
                activeThumbColor: const Color(0xFF6C63FF),
                onChanged: (_) => _ctrl.toggleRegistrationStatus(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogisticsSection() {
    return _buildSection(
      icon: Icons.tune_rounded,
      title: 'Logística',
      color: const Color(0xFFFFB347),
      children: [
        GlassTextField(
          controller: _ctrl.maxParticipantsCtrl,
          hint: 'Máx. participantes',
          icon: Icons.people_alt_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          errorText: _ctrl.maxParticipantsError,
        ),
        const SizedBox(height: 12),
        GlassTextField(
          controller: _ctrl.membersPerTeamCtrl,
          hint: 'Miembros por equipo (0 = individual)',
          icon: Icons.group_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          errorText: _ctrl.membersPerTeamError,
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    final lat = _ctrl.edited.latitude;
    final lng = _ctrl.edited.longitude;

    return _buildSection(
      icon: Icons.location_on_rounded,
      title: 'Ubicación',
      color: const Color(0xFF22C55E),
      children: [
        if (lat != null && lng != null)
          StaticLocationMap(
            latitude: lat,
            longitude: lng,
            height: 220,
            borderRadius: 18,
            locationLabel: _ctrl.locationCtrl.text.isEmpty
                ? 'Ubicación del torneo'
                : _ctrl.locationCtrl.text,
          )
        else
          _MutedPanel(
            icon: Icons.map_outlined,
            text: 'No hay coordenadas guardadas para este torneo.',
          ),
        const SizedBox(height: 12),
        GlassTextField(
          controller: _ctrl.locationCtrl,
          hint: 'Dirección / lugar',
          icon: Icons.place_rounded,
          textCapitalization: TextCapitalization.words,
          errorText: _ctrl.locationError,
        ),
        const SizedBox(height: 12),
        GradientButton(
          label: 'Cambiar ubicación',
          icon: Icons.map_rounded,
          onPressed: _openLocationPicker,
          variant: GradientButtonVariant.simple,
          size: GradientButtonSize.small,
          textColor: Colors.black,
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return _buildSection(
      icon: Icons.support_agent_rounded,
      title: 'Contacto',
      color: const Color(0xFF00D4FF),
      children: [
        GlassTextField(
          controller: _ctrl.contactEmailCtrl,
          hint: 'Email de contacto',
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
          errorText: _ctrl.contactEmailError,
        ),
        const SizedBox(height: 12),
        GlassTextField(
          controller: _ctrl.contactPhoneCtrl,
          hint: 'Teléfono de contacto',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildLinksSection() {
    return _buildSection(
      icon: Icons.link_rounded,
      title: 'Enlaces',
      color: const Color(0xFF14B8A6),
      children: [
        ...List.generate(_ctrl.contactLinkCtrls.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _ctrl.contactLinkCtrls.length - 1 ? 0 : 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: GlassTextField(
                    controller: _ctrl.contactLinkCtrls[index],
                    hint: 'https://...',
                    icon: Icons.link_rounded,
                    keyboardType: TextInputType.url,
                  ),
                ),
                const SizedBox(width: 8),
                _GlassIconButton(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFFF4D6A),
                  onTap: _ctrl.contactLinkCtrls.length <= 1
                      ? null
                      : () => _ctrl.removeContactLinkField(index),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        _InlineAction(
          icon: Icons.add_rounded,
          label: 'Añadir enlace',
          onTap: _ctrl.addContactLinkField,
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return _buildSection(
      icon: Icons.label_rounded,
      title: 'Categorías',
      color: const Color(0xFFFF6B9D),
      children: [
        Row(
          children: [
            Expanded(
              child: GlassTextField(
                controller: _categoryCtrl,
                hint: 'Nueva categoría',
                icon: Icons.new_label_rounded,
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: 10),
            _GlassIconButton(
              icon: Icons.add_rounded,
              onTap: _addCategory,
              color: const Color(0xFF6C63FF),
            ),
          ],
        ),
        if (_ctrl.editedCategories.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ctrl.editedCategories
                .map(
                  (category) => _CategoryChip(
                    label: category,
                    onDelete: () => _ctrl.removeCategory(category),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildRegistrationFormSection() {
    return RegistrationFormBuilder(
      schema: _ctrl.edited.registrationForm,
      errorText: _ctrl.registrationFormError,
      onUpsertField: _ctrl.upsertRegistrationField,
      onRemoveField: _ctrl.removeRegistrationField,
      onToggleField: _ctrl.toggleRegistrationField,
      onMoveField: _ctrl.moveRegistrationField,
    );
  }

  Widget _buildParticipantsSection() {
    return Column(
      children: [
        LineDivider(color: Colors.white),
        const SizedBox(height: 32),
        GradientButton(
          label: 'Revisar solicitudes de inscripcion',
          icon: Icons.pending_actions_rounded,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TournamentJoinRequestsScreen(tournament: _ctrl.edited),
              ),
            );
          },
          variant: GradientButtonVariant.select,
          size: GradientButtonSize.large,
        ),
        const SizedBox(height: 16),
        ParticipantsSection(
          tournament: _ctrl.edited,
          enableManagementNavigation: true,
          managementScreenBuilder: (_) => ParticipantsManagementScreen(
            tournamentId: _ctrl.edited.id,
            tournamentName: _ctrl.edited.name,
            isTeamTournament: _ctrl.isTeamTournament,
            categories: _ctrl.editedCategories,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminsSection() {
    final canManage = _ctrl.isCreator;

    return _buildSection(
      icon: Icons.admin_panel_settings_rounded,
      title: 'Administradores',
      color: const Color(0xFFF97316),
      children: [
        if (!canManage) ...[
          const _MutedPanel(
            icon: Icons.lock_outline_rounded,
            text: 'Solo el creador puede gestionar administradores',
          ),
          const SizedBox(height: 12),
        ],
        // ── Campo de búsqueda + botón enviar invitación ─────────────────────
        if (canManage) ...[
          Row(
            children: [
              Expanded(
                child: GlassTextField(
                  controller: _ctrl.adminLookupCtrl,
                  hint: 'UID, nickname o email',
                  icon: Icons.person_add_alt_1_rounded,
                  enabled: canManage && !_ctrl.isAddingAdmin,
                ),
              ),
              const SizedBox(width: 10),
              _GlassIconButton(
                icon: _ctrl.isAddingAdmin
                    ? Icons.hourglass_top_rounded
                    : Icons.send_rounded,
                onTap: canManage && !_ctrl.isAddingAdmin
                    ? () async {
                        final ok = await _ctrl.addAdminFromInput();
                        if (ok) {
                          _showSnack('Invitación enviada correctamente');
                        } else if (_ctrl.adminError != null) {
                          _showSnack(_ctrl.adminError!, isError: true);
                        }
                      }
                    : null,
                color: const Color(0xFFF97316),
              ),
            ],
          ),
          if (_ctrl.adminError != null) ...[
            _SectionErrorText(message: _ctrl.adminError!),
          ],
          const SizedBox(height: 6),
          // Nota explicativa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFF97316).withValues(alpha: 0.08),
              border: Border.all(
                color: const Color(0xFFF97316).withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: const Color(0xFFF97316).withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Se enviará una invitación. El usuario debe aceptarla para ser admin.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Administradores activos ─────────────────────────────────────────
        if (_ctrl.loadingAdmins)
          const _SectionLoading(label: 'Cargando administradores...')
        else
          ..._ctrl.adminUsers.map(
            (admin) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AdminTile(
                admin: admin,
                isCreator: admin.uid == _ctrl.original.organizerUid,
                canRemove:
                    canManage && admin.uid != _ctrl.original.organizerUid,
                onRemove: () => _ctrl.removeAdminLocally(admin.uid),
              ),
            ),
          ),

        // ── Invitaciones pendientes ─────────────────────────────────────────
        if (_ctrl.pendingInvitations.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                ),
                child: const Text(
                  'PENDIENTES',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF59E0B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_ctrl.pendingInvitations.length} invitación(es) enviada(s)',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._ctrl.pendingInvitations.map(
            (inv) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PendingInvitationTile(
                invitation: inv,
                canCancel: canManage,
                onCancel: () => _ctrl.cancelPendingInvitation(inv.userId),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlayerInvitationSection() {
    return _buildSection(
      icon: Icons.person_add_alt_1_rounded,
      title: 'Invitar jugadores',
      color: const Color(0xFF8B5CF6),
      children: [
        GlassTextField(
          controller: _ctrl.playerInviteLookupCtrl,
          hint: '@nickname',
          icon: Icons.search_rounded,
          enabled: !_ctrl.isSendingPlayerInvite,
          onChanged: _ctrl.onPlayerInviteQueryChanged,
        ),
        if (_ctrl.playerInviteError != null) ...[
          _SectionErrorText(message: _ctrl.playerInviteError!),
        ],
        if (_ctrl.isSearchingPlayerInvite) ...[
          const SizedBox(height: 10),
          const _SectionLoading(label: 'Buscando jugadores...'),
        ],
        if (!_ctrl.isSearchingPlayerInvite &&
            _ctrl.playerInviteLookupCtrl.text.trim().length >= 2 &&
            _ctrl.playerInviteSuggestions.isEmpty) ...[
          const SizedBox(height: 10),
          const _MutedPanel(
            icon: Icons.search_off_rounded,
            text: 'No hay jugadores con ese nickname.',
          ),
        ],
        if (_ctrl.playerInviteSuggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._ctrl.playerInviteSuggestions.map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PlayerInviteTile(
                user: user,
                isSending: _ctrl.isSendingPlayerInvite,
                onInvite: () async {
                  final ok = await _ctrl.sendPlayerInvitation(user);
                  if (ok) {
                    _showSnack('Invitación enviada a @${user.nickname}');
                  }
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Sección: Enlace de Invitación (solo torneos privados + creador) ─────

  Widget _buildInvitationLinkSection() {
    final inv = _invitationCtrl!;
    return _buildSection(
      icon: Icons.link_rounded,
      title: 'Enlace de invitación',
      color: const Color(0xFF00D4FF),
      children: [
        // Descripción
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF00D4FF).withValues(alpha: 0.06),
            border: Border.all(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: const Color(0xFF00D4FF).withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Genera un enlace seguro para invitar a personas a este torneo privado. '
                  'El enlace expira en 30 días y puede revocarse en cualquier momento.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.55),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Mostrar enlace generado o botón de generar
        if (inv.hasLink) ...[
          // Caja del enlace
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: const Color(0xFF22C55E).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    inv.invitationLink,
                    style: const TextStyle(
                      color: Color(0xFF22C55E),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                // Botón copiar
                GestureDetector(
                  onTap: inv.isBusy ? null : inv.copyLinkToClipboard,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: inv.copiedToClipboard
                        ? const Icon(
                            Icons.check_circle_rounded,
                            key: ValueKey('check'),
                            color: Color(0xFF22C55E),
                            size: 22,
                          )
                        : Icon(
                            Icons.copy_rounded,
                            key: const ValueKey('copy'),
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 22,
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (inv.copiedToClipboard) ...[
            const SizedBox(height: 6),
            Text(
              '¡Enlace copiado al portapapeles!',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF22C55E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Acciones: revocar
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: inv.isRevoking ? 'Revocando...' : 'Revocar enlace',
                  icon: Icons.block_rounded,
                  isLoading: inv.isRevoking,
                  onPressed: inv.isBusy
                      ? null
                      : () => _handleRevokeInvitation(inv),
                  variant: GradientButtonVariant.danger,
                  size: GradientButtonSize.small,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  label: 'Nuevo enlace',
                  icon: Icons.refresh_rounded,
                  onPressed: inv.isBusy
                      ? null
                      : () => _handleGenerateInvitation(inv),
                  variant: GradientButtonVariant.ocean,
                  size: GradientButtonSize.small,
                ),
              ),
            ],
          ),
        ] else ...[
          // Botón generar
          GradientButton(
            label: inv.isGenerating
                ? 'Generando enlace...'
                : 'Generar enlace de invitación',
            icon: Icons.add_link_rounded,
            isLoading: inv.isGenerating,
            onPressed: inv.isGenerating
                ? null
                : () => _handleGenerateInvitation(inv),
            variant: GradientButtonVariant.ocean,
            size: GradientButtonSize.medium,
          ),
        ],

        // Error de invitación
        if (inv.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            inv.errorMessage!,
            style: const TextStyle(color: Color(0xFFFF4D6A), fontSize: 12),
          ),
        ],
      ],
    );
  }

  Future<void> _handleGenerateInvitation(
    GenerateInvitationController inv,
  ) async {
    await inv.generateLink();
    if (inv.errorMessage != null && mounted) {
      _showSnack(inv.errorMessage!, isError: true);
    } else if (mounted && inv.hasLink) {
      _showSnack('Enlace de invitación generado');
    }
  }

  Future<void> _handleRevokeInvitation(GenerateInvitationController inv) async {
    final confirmed = await _confirm(
      title: 'Revocar enlace',
      message:
          '¿Seguro que quieres revocar este enlace? Los usuarios que lo tengan no podrán usarlo.',
      confirmLabel: 'Revocar',
      destructive: true,
    );
    if (!confirmed) return;

    final ok = await inv.revokeLink();
    if (mounted) {
      _showSnack(
        ok
            ? 'Enlace revocado correctamente'
            : (inv.errorMessage ?? 'Error al revocar'),
        isError: !ok,
      );
    }
  }

  Widget _buildDangerZone() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.red.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: _buildSection(
            icon: Icons.warning_amber_rounded,
            title: 'Zona peligrosa',
            color: const Color(0xFFFF4D6A),
            children: [
              Text(
                'Eliminar el torneo es una acción permanente e irreversible.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: _ctrl.isDeleting ? 'Eliminando...' : 'Eliminar torneo',
                icon: Icons.delete_forever_rounded,
                isLoading: _ctrl.isDeleting,
                onPressed: _ctrl.isDeleting ? null : _handleDelete,
                variant: GradientButtonVariant.danger,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LineDivider(color: color),
        const SizedBox(height: 32),
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBottomBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A1A).withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
            ),
          ),
          child: GradientButton(
            label: _ctrl.isSaving ? 'Guardando...' : 'Guardar cambios',
            icon: Icons.save_rounded,
            isLoading: _ctrl.isSaving,
            onPressed: _ctrl.isSaving ? null : _handleSave,
            variant: GradientButtonVariant.violet,
            size: GradientButtonSize.large,
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ParticipantsManagementList extends StatelessWidget {
  const _ParticipantsManagementList({
    required this.participants,
    required this.categories,
    required this.isTeamTournament,
    required this.onRemove,
  });

  final List<ParticipantDisplay> participants;
  final List<String> categories;
  final bool isTeamTournament;
  final ValueChanged<ParticipantDisplay> onRemove;

  static const _withoutCategory = '__without_category__';

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Column(
        children: participants
            .map(
              (participant) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ParticipantManagementItem(
                  participant: participant,
                  isTeamTournament: isTeamTournament,
                  onRemove: () => onRemove(participant),
                ),
              ),
            )
            .toList(),
      );
    }

    final grouped = <String, List<ParticipantDisplay>>{};
    for (final participant in participants) {
      final key = participant.categoryId ?? _withoutCategory;
      grouped.putIfAbsent(key, () => []).add(participant);
    }

    final orderedKeys = [
      ...categories.where(grouped.containsKey),
      if (grouped.containsKey(_withoutCategory)) _withoutCategory,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...orderedKeys.map((key) {
          final items = grouped[key]!;
          final label = key == _withoutCategory ? 'Sin categoría' : key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryHeader(label: label, count: items.length),
                const SizedBox(height: 10),
                ...items.map(
                  (participant) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ParticipantManagementItem(
                      participant: participant,
                      isTeamTournament: isTeamTournament,
                      onRemove: () => onRemove(participant),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ParticipantManagementItem extends StatelessWidget {
  const _ParticipantManagementItem({
    required this.participant,
    required this.isTeamTournament,
    required this.onRemove,
  });

  final ParticipantDisplay participant;
  final bool isTeamTournament;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: switch (participant) {
            UserParticipantDisplay(:final user) => ParticipantCard(
              nickname: user.nickname,
              displayName: '${user.name} ${user.lastName}'.trim(),
              photoUrl: user.photoUrl,
            ),
            TeamParticipantDisplay(:final team) => TeamCard(team: team),
          },
        ),
        const SizedBox(width: 8),
        BarSmallBotton(icon: Icons.delete_outline_rounded, onTap: onRemove),
      ],
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.admin,
    required this.isCreator,
    required this.canRemove,
    required this.onRemove,
  });

  final TournamentAdminView admin;
  final bool isCreator;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(
            isCreator
                ? Icons.verified_user_outlined
                : Icons.admin_panel_settings_outlined,
            color: isCreator
                ? const Color(0xFF6C63FF)
                : const Color(0xFFF97316),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  isCreator ? 'Creador' : 'Admin',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          if (canRemove)
            _GlassIconButton(
              icon: Icons.delete_outline_rounded,
              color: const Color(0xFFFF4D6A),
              onTap: onRemove,
            ),
        ],
      ),
    );
  }
}

class _PendingInvitationTile extends StatelessWidget {
  const _PendingInvitationTile({
    required this.invitation,
    required this.canCancel,
    required this.onCancel,
  });

  final PendingAdminInvitation invitation;
  final bool canCancel;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.pending_outlined,
            color: const Color(0xFFF59E0B).withValues(alpha: 0.8),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  ),
                  child: const Text(
                    'Invitación enviada',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (canCancel)
            _GlassIconButton(
              icon: Icons.cancel_outlined,
              color: const Color(0xFF64748B),
              onTap: onCancel,
            ),
        ],
      ),
    );
  }
}

class _PlayerInviteTile extends StatelessWidget {
  const _PlayerInviteTile({
    required this.user,
    required this.isSending,
    required this.onInvite,
  });

  final AppUser user;
  final bool isSending;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final fullName = '${user.name} ${user.lastName}'.trim();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
            child: Text(
              user.nickname.isEmpty ? '?' : user.nickname[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@${user.nickname}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (fullName.isNotEmpty)
                  Text(
                    fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          _GlassIconButton(
            icon: isSending ? Icons.hourglass_top_rounded : Icons.send_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: isSending ? null : onInvite,
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap, this.color});

  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: color ?? Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.isCreator});

  final bool isCreator;

  @override
  Widget build(BuildContext context) {
    final color = isCreator ? const Color(0xFF6C63FF) : const Color(0xFF00D4FF);
    final label = isCreator ? 'Creador' : 'Admin';
    final icon = isCreator
        ? Icons.verified_user_outlined
        : Icons.admin_panel_settings_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onPick,
    this.optional = false,
    this.onClear,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final bool optional;
  final VoidCallback? onClear;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final formatted = value != null
        ? DateFormat("dd 'de' MMMM, yyyy - HH:mm", 'es').format(value!)
        : (optional ? 'Sin definir' : 'Seleccionar fecha');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onPick,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white38,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatted,
                        style: TextStyle(
                          color: value != null
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (optional && value != null && onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 18,
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFF4D6A),
                size: 13,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  errorText!,
                  style: const TextStyle(
                    color: Color(0xFFFF4D6A),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.onDelete});

  final String label;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFFF6B9D).withValues(alpha: 0.12),
        border: Border.all(
          color: const Color(0xFFFF6B9D).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close_rounded,
              size: 15,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.07),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionErrorText extends StatelessWidget {
  const _SectionErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: Color(0xFFFF4D6A),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFF4D6A),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MutedPanel extends StatelessWidget {
  const _MutedPanel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.58),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
        ),
      ],
    );
  }
}

class _BlockingLoader extends StatelessWidget {
  const _BlockingLoader();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF101127).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  SizedBox(height: 14),
                  Text(
                    'Aplicando cambios...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0A1A), Color(0xFF0D0D2B), Color(0xFF12122E)],
        ),
      ),
    );
  }
}
