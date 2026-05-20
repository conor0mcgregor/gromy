import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/models/registration_form.dart';
import '../../data/model/enums_tournament.dart';
import '../../data/model/tournament_draft.dart';
import '../../data/services/geocoding_service.dart';

/// Entrada de administrador: UID + etiqueta visible.
class FormAdminEntry {
  const FormAdminEntry({required this.uid, required this.label});

  final String uid;
  final String label;
}

/// Controlador que centraliza todo el estado del formulario de creación de
/// torneos (8 pasos).
///
/// SRP: gestiona únicamente los valores del formulario, la validación por paso
/// y la búsqueda de ubicación. No contiene lógica de persistencia.
class TournamentFormController extends ChangeNotifier {
  TournamentFormController({GeocodingService? geocodingService})
    : _geocodingService = geocodingService ?? GeocodingService() {
    for (final controller in [
      nameController,
      descriptionController,
      locationController,
      maxParticipantsController,
      membersPerTeamController,
      rulesController,
      categoryController,
      adminController,
      contactEmailController,
      contactPhoneController,
      ...contactLinkControllers,
    ]) {
      controller.addListener(notifyListeners);
    }
  }

  final GeocodingService _geocodingService;

  // Step 0: Identidad
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  XFile? coverImage;
  Uint8List? coverBytes;
  String? nameError;
  String? descriptionError;

  // Step 1: Disciplina
  TournamentSport? selectedSport;
  String? sportError;

  /// `true` si la disciplina elegida obliga modalidad por equipos (fútbol, etc.).
  bool get isTeamModeLockedByDiscipline =>
      selectedSport?.isTeamOnlyDiscipline ?? false;

  // Step 2: Cronograma
  DateTime? eventDate;
  DateTime? registrationDeadline;
  DateTime? bracketPublishDate;
  String? eventDateError;
  String? registrationDeadlineError;
  String? bracketPublishDateError;

  // Step 3: Geolocalización
  final locationController = TextEditingController();
  String? locationError;
  double? latitude;
  double? longitude;
  List<GeocodingResult> locationSuggestions = [];
  bool isSearchingLocation = false;
  Timer? _debounce;
  int _locationSearchRequestId = 0;
  int _reverseGeocodeRequestId = 0;

  // Step 4: Logística y Privacidad
  final maxParticipantsController = TextEditingController();
  final membersPerTeamController = TextEditingController();
  TournamentAccessType? selectedAccessType;
  String? maxParticipantsError;
  String? membersPerTeamError;
  String? accessTypeError;

  // Step 5: Reglamento
  final rulesController = TextEditingController();
  String? rulesError;

  // Step 6: Categorías
  /// Controller del campo de texto para introducir el nombre de la categoría.
  final categoryController = TextEditingController();

  /// Lista de categorías añadidas por el usuario (opcional).
  final List<String> categories = [];

  RegistrationFormSchema registrationForm = const RegistrationFormSchema();
  String? registrationFormError;

  // Step 7: Staff y Soporte
  final adminController = TextEditingController();
  final contactEmailController = TextEditingController();
  final contactPhoneController = TextEditingController();
  final List<TextEditingController> contactLinkControllers = [
    TextEditingController(),
  ];
  final List<FormAdminEntry> extraAdmins = [];
  bool isAddingAdmin = false;
  String? adminError;
  String? contactEmailError;

  // Navegación
  static const int totalSteps = 10;
  int currentStep = 0;

  bool isTeamSport = false;

  bool get hasMeaningfulDraftInput {
    return nameController.text.trim().isNotEmpty ||
        descriptionController.text.trim().isNotEmpty ||
        coverImage != null ||
        selectedSport != null ||
        eventDate != null ||
        locationController.text.trim().isNotEmpty ||
        maxParticipantsController.text.trim().isNotEmpty ||
        membersPerTeamController.text.trim().isNotEmpty ||
        selectedAccessType != null ||
        rulesController.text.trim().isNotEmpty ||
        categories.isNotEmpty ||
        contactEmailController.text.trim().isNotEmpty ||
        contactPhoneController.text.trim().isNotEmpty ||
        contactLinks.isNotEmpty ||
        extraAdmins.isNotEmpty;
  }

  TournamentDraft toDraft({required String ownerUid, String? draftId}) {
    return TournamentDraft(
      id: draftId ?? '',
      ownerUid: ownerUid,
      updatedAt: DateTime.now(),
      name: nameController.text,
      description: descriptionController.text,
      coverImagePath: coverImage?.path,
      sport: selectedSport,
      isTeamSport: isTeamSport,
      eventDate: eventDate,
      registrationDeadline: registrationDeadline,
      bracketPublishDate: bracketPublishDate,
      location: locationController.text,
      latitude: latitude,
      longitude: longitude,
      maxParticipants: int.tryParse(maxParticipantsController.text.trim()),
      membersPerTeam: int.tryParse(membersPerTeamController.text.trim()),
      accessType: selectedAccessType,
      rules: rulesController.text,
      categories: List<String>.from(categories),
      contactEmail: contactEmailController.text,
      contactPhone: contactPhoneController.text,
      contactLinks: contactLinks,
      extraAdminUids: extraAdmins.map((entry) => entry.uid).toList(),
      extraAdminLabels: extraAdmins.map((entry) => entry.label).toList(),
    );
  }

  Future<void> loadDraft(TournamentDraft draft) async {
    nameController.text = draft.name ?? '';
    descriptionController.text = draft.description ?? '';
    if (draft.coverImagePath != null) {
      coverImage = XFile(draft.coverImagePath!);
      try {
        coverBytes = await coverImage!.readAsBytes();
      } catch (_) {
        coverImage = null;
        coverBytes = null;
      }
    }
    selectedSport = draft.sport;
    isTeamSport = draft.isTeamSport;
    eventDate = draft.eventDate;
    registrationDeadline = draft.registrationDeadline;
    bracketPublishDate = draft.bracketPublishDate;
    locationController.text = draft.location ?? '';
    latitude = draft.latitude;
    longitude = draft.longitude;
    maxParticipantsController.text = draft.maxParticipants?.toString() ?? '';
    membersPerTeamController.text = draft.membersPerTeam?.toString() ?? '';
    selectedAccessType = draft.accessType;
    rulesController.text = draft.rules ?? '';
    categories
      ..clear()
      ..addAll(draft.categories);
    contactEmailController.text = draft.contactEmail ?? '';
    contactPhoneController.text = draft.contactPhone ?? '';
    for (final controller in contactLinkControllers) {
      controller.dispose();
    }
    contactLinkControllers
      ..clear()
      ..addAll(
        (draft.contactLinks.isEmpty ? [''] : draft.contactLinks).map(
          (value) =>
              TextEditingController(text: value)..addListener(notifyListeners),
        ),
      );
    extraAdmins
      ..clear()
      ..addAll(
        List.generate(draft.extraAdminUids.length, (index) {
          final label = index < draft.extraAdminLabels.length
              ? draft.extraAdminLabels[index]
              : draft.extraAdminUids[index];
          return FormAdminEntry(uid: draft.extraAdminUids[index], label: label);
        }),
      );
    notifyListeners();
  }

  /// Actualiza la disciplina y sincroniza [isTeamSport] con reglas por deporte.
  void selectSport(TournamentSport sport) {
    selectedSport = sport;
    sportError = null;
    if (sport.isTeamOnlyDiscipline) {
      isTeamSport = true;
    }
    notifyListeners();
  }

  /// Cambia la modalidad equipos / individual (ignorado si la disciplina lo fija).
  void setTeamTournament(bool value) {
    if (isTeamModeLockedByDiscipline) return;
    isTeamSport = value;
    notifyListeners();
  }

  bool canGoNext() => validateCurrentStep();

  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      currentStep = step;
      notifyListeners();
    }
  }

  bool validateCurrentStep() {
    switch (currentStep) {
      case 0:
        return _validateIdentity();
      case 1:
        return _validateDiscipline();
      case 2:
        return _validateSchedule();
      case 3:
        return _validateGeolocation();
      case 4:
        return _validateLogistics();
      case 5:
        return _validateRules();
      case 6:
        // Categorías es opcional: siempre se puede avanzar.
        return true;
      case 7:
        return _validateRegistrationForm();
      case 8:
        return _validateStaff();
      case 9:
        return true;
      default:
        return true;
    }
  }

  bool _validateIdentity() {
    final nameOk = nameController.text.trim().length >= 3;
    final descOk = descriptionController.text.trim().length >= 10;
    final coverOk = coverBytes != null && coverBytes!.isNotEmpty;

    nameError = nameOk ? null : 'El nombre debe tener al menos 3 caracteres.';
    descriptionError = descOk
        ? null
        : 'Añade una descripción un poco más larga (mín. 10).';

    notifyListeners();
    return nameOk && descOk && coverOk;
  }

  bool _validateDiscipline() {
    final ok = selectedSport != null;
    sportError = ok ? null : 'Elige el deporte del torneo.';
    notifyListeners();
    return ok;
  }

  bool _validateSchedule() {
    final today = DateTime.now();
    final minDate = DateTime(today.year, today.month, today.day);

    final dateOk = eventDate != null && !eventDate!.isBefore(minDate);
    eventDateError = eventDate == null
        ? 'Elige la fecha del torneo.'
        : !dateOk
        ? 'La fecha debe ser hoy o en el futuro.'
        : null;

    if (registrationDeadline != null && eventDate != null) {
      registrationDeadlineError = registrationDeadline!.isAfter(eventDate!)
          ? 'El límite de inscripción debe ser antes del evento.'
          : null;
    } else {
      registrationDeadlineError = null;
    }

    if (bracketPublishDate != null && eventDate != null) {
      bracketPublishDateError = bracketPublishDate!.isAfter(eventDate!)
          ? 'Los cuadros deben publicarse antes del evento.'
          : null;
    } else {
      bracketPublishDateError = null;
    }

    notifyListeners();
    return dateOk &&
        registrationDeadlineError == null &&
        bracketPublishDateError == null;
  }

  bool _validateGeolocation() {
    final hasText = locationController.text.trim().isNotEmpty;
    final hasCoordinates = latitude != null && longitude != null;
    final locOk = hasText && hasCoordinates;

    locationError = switch ((hasText, hasCoordinates)) {
      (false, _) => '¿Dónde se juega? Indica el lugar.',
      (true, false) =>
        'Selecciona una sugerencia o fija el punto en el mapa para guardar coordenadas reales.',
      (true, true) => null,
    };

    notifyListeners();
    return locOk;
  }

  bool _validateLogistics() {
    final maxParticipants = int.tryParse(maxParticipantsController.text.trim());
    final membersPerTeam = int.tryParse(membersPerTeamController.text.trim());

    final maxOk = maxParticipants != null && maxParticipants >= 2;
    final accessOk = selectedAccessType != null;

    maxParticipantsError = maxParticipants == null
        ? 'Escribe un número de participantes.'
        : !maxOk
        ? 'Debe haber al menos 2 participantes.'
        : null;

    if (isTeamSport) {
      final membersOk = membersPerTeam != null && membersPerTeam >= 2;
      final relationOk =
          maxOk && membersOk && membersPerTeam <= maxParticipants;

      membersPerTeamError = membersPerTeam == null
          ? 'Escribe cuántos miembros tendrá cada equipo.'
          : !membersOk
          ? 'Cada equipo debe tener al menos 2 miembros.'
          : !relationOk
          ? 'Los miembros por equipo no pueden superar el total de participantes.'
          : null;

      accessTypeError = accessOk ? null : 'Indica quién puede apuntarse.';
      notifyListeners();
      return maxOk && membersOk && relationOk && accessOk;
    }

    membersPerTeamError = null;
    accessTypeError = accessOk ? null : 'Indica quién puede apuntarse.';
    notifyListeners();
    return maxOk && accessOk;
  }

  bool _validateRules() {
    final ok = rulesController.text.trim().length >= 100;
    rulesError = ok
        ? null
        : 'Añade más información sobre las reglas (mín. 100 caracteres).';
    notifyListeners();
    return ok;
  }

  bool _validateStaff() {
    final emailRaw = contactEmailController.text.trim();
    final emailOk = emailRaw.isNotEmpty && _isValidEmail(emailRaw);
    contactEmailError = emailRaw.isEmpty
        ? 'El email de contacto es obligatorio.'
        : !emailOk
        ? 'Introduce un email válido.'
        : null;
    notifyListeners();
    return emailOk;
  }

  bool _validateRegistrationForm() {
    final errors = RegistrationFormValidator.validateSchema(registrationForm);
    registrationFormError = errors.isEmpty ? null : errors.first;
    notifyListeners();
    return errors.isEmpty;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  // Geolocalización
  void onLocationQueryChanged(String query) {
    _debounce?.cancel();
    _locationSearchRequestId++;

    latitude = null;
    longitude = null;

    final trimmed = query.trim();
    if (trimmed.length < 3) {
      locationSuggestions = [];
      isSearchingLocation = false;
      notifyListeners();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchLocation(trimmed);
    });
  }

  Future<void> _searchLocation(String query) async {
    final requestId = ++_locationSearchRequestId;
    isSearchingLocation = true;
    notifyListeners();

    final results = await _geocodingService.search(query);
    if (requestId != _locationSearchRequestId) return;

    locationSuggestions = results;
    isSearchingLocation = false;
    notifyListeners();
  }

  void selectLocation(GeocodingResult result) {
    _locationSearchRequestId++;
    _reverseGeocodeRequestId++;

    locationController.text = result.displayName;
    latitude = result.latitude;
    longitude = result.longitude;
    locationSuggestions = [];
    locationError = null;
    notifyListeners();
  }

  Future<void> onMapTap(double lat, double lng) async {
    final requestId = ++_reverseGeocodeRequestId;

    latitude = lat;
    longitude = lng;
    locationSuggestions = [];
    locationError = null;
    notifyListeners();

    final address = await _geocodingService.reverseGeocode(lat, lng);
    if (requestId != _reverseGeocodeRequestId) return;

    if (address != null && address.trim().isNotEmpty) {
      locationController.text = address;
      locationError = null;
    } else {
      locationController.text =
          'Ubicación seleccionada (${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})';
    }

    notifyListeners();
  }

  // Contact links
  void addContactLink() {
    contactLinkControllers.add(
      TextEditingController()..addListener(notifyListeners),
    );
    notifyListeners();
  }

  void removeContactLink(int index) {
    if (index >= 0 && index < contactLinkControllers.length) {
      contactLinkControllers[index].dispose();
      contactLinkControllers.removeAt(index);
      notifyListeners();
    }
  }

  List<String> get contactLinks => contactLinkControllers
      .map((controller) => controller.text.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  // Categorías
  /// Añade una categoría si no está vacía y no existe ya.
  /// Devuelve [true] si se añadió, [false] si se rechazó (vacía o duplicada).
  bool addCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final lowerTrimmed = trimmed.toLowerCase();
    if (categories.any((c) => c.toLowerCase() == lowerTrimmed)) return false;
    categories.add(trimmed);
    notifyListeners();
    return true;
  }

  /// Elimina la categoría con ese nombre exacto.
  void removeCategory(String name) {
    categories.remove(name);
    notifyListeners();
  }

  void upsertRegistrationField(RegistrationField field) {
    final normalized = _normalizeRegistrationField(field);
    final fields = [...registrationForm.fields];
    final index = fields.indexWhere((item) => item.id == normalized.id);
    if (index >= 0) {
      fields[index] = normalized.copyWith(updatedAt: DateTime.now());
    } else {
      fields.add(normalized.copyWith(order: fields.length));
    }
    registrationForm = registrationForm.copyWith(
      fields: _withOrderedFields(fields),
    );
    registrationFormError = null;
    notifyListeners();
  }

  void removeRegistrationField(String id) {
    final fields = registrationForm.fields
        .where((field) => field.id != id)
        .toList(growable: false);
    registrationForm = registrationForm.copyWith(
      fields: _withOrderedFields(fields),
    );
    registrationFormError = null;
    notifyListeners();
  }

  void toggleRegistrationField(String id, bool enabled) {
    final fields = registrationForm.fields.map((field) {
      if (field.id != id) return field;
      return field.copyWith(enabled: enabled, updatedAt: DateTime.now());
    }).toList();
    registrationForm = registrationForm.copyWith(
      fields: _withOrderedFields(fields),
    );
    registrationFormError = null;
    notifyListeners();
  }

  void moveRegistrationField(String id, int delta) {
    final fields = [...registrationForm.fields]
      ..sort((a, b) => a.order.compareTo(b.order));
    final index = fields.indexWhere((field) => field.id == id);
    if (index < 0) return;
    final target = index + delta;
    if (target < 0 || target >= fields.length) return;
    final field = fields.removeAt(index);
    fields.insert(target, field);
    registrationForm = registrationForm.copyWith(
      fields: _withOrderedFields(fields),
    );
    registrationFormError = null;
    notifyListeners();
  }

  RegistrationField _normalizeRegistrationField(RegistrationField field) {
    final options = field.type.usesOptions
        ? field.options
              .map((option) => option.trim())
              .where((option) => option.isNotEmpty)
              .toSet()
              .toList()
        : <String>[];
    return field.copyWith(
      label: field.label.trim(),
      description: field.description?.trim().isEmpty == true
          ? null
          : field.description?.trim(),
      options: options,
    );
  }

  List<RegistrationField> _withOrderedFields(List<RegistrationField> fields) {
    final sorted = [...fields]..sort((a, b) => a.order.compareTo(b.order));
    return [
      for (var i = 0; i < sorted.length; i++) sorted[i].copyWith(order: i),
    ];
  }

  // Helpers
  void clearFieldError(String field) {
    switch (field) {
      case 'name':
        nameError = null;
        break;
      case 'description':
        descriptionError = null;
        break;
      case 'sport':
        sportError = null;
        break;
      case 'eventDate':
        eventDateError = null;
        break;
      case 'registrationDeadline':
        registrationDeadlineError = null;
        break;
      case 'bracketPublishDate':
        bracketPublishDateError = null;
        break;
      case 'location':
        locationError = null;
        break;
      case 'maxParticipants':
        maxParticipantsError = null;
        break;
      case 'membersPerTeam':
        membersPerTeamError = null;
        break;
      case 'accessType':
        accessTypeError = null;
        break;
      case 'rules':
        rulesError = null;
        break;
      case 'admin':
        adminError = null;
        break;
      case 'registrationForm':
        registrationFormError = null;
        break;
      case 'contactEmail':
        contactEmailError = null;
        break;
    }

    notifyListeners();
  }

  String formatDate(DateTime date) {
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

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} de ${months[date.month - 1]} de ${date.year}, $hour:$minute';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    nameController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    maxParticipantsController.dispose();
    membersPerTeamController.dispose();
    rulesController.dispose();
    categoryController.dispose();
    adminController.dispose();
    contactEmailController.dispose();
    contactPhoneController.dispose();

    for (final controller in contactLinkControllers) {
      controller.dispose();
    }

    _geocodingService.dispose();
    super.dispose();
  }
}
