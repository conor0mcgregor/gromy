import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/model/enums_tournament.dart';
import '../../data/services/geocoding_service.dart';

/// Entrada de administrador: UID + etiqueta visible.
class FormAdminEntry {
  const FormAdminEntry({required this.uid, required this.label});
  final String uid;
  final String label;
}

/// Controlador que centraliza TODO el estado del formulario de creación de
/// torneos (8 pasos).
///
/// SRP: gestiona únicamente los valores del formulario, la validación por paso
/// y la búsqueda de ubicación. No contiene lógica de persistencia (esa vive en
/// [CreateTournamentController]).
class TournamentFormController extends ChangeNotifier {
  TournamentFormController({GeocodingService? geocodingService})
      : _geocodingService = geocodingService ?? GeocodingService();

  final GeocodingService _geocodingService;

  // ── Step 0: Identidad ────────────────────────────────────────
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  XFile? coverImage;
  Uint8List? coverBytes;
  String? nameError;
  String? descriptionError;

  // ── Step 1: Disciplina ───────────────────────────────────────
  TournamentSport? selectedSport;
  String? sportError;

  // ── Step 2: Cronograma ───────────────────────────────────────
  DateTime? eventDate;
  DateTime? registrationDeadline;
  DateTime? bracketPublishDate;
  String? eventDateError;
  String? registrationDeadlineError;
  String? bracketPublishDateError;

  // ── Step 3: Geolocalización ──────────────────────────────────
  final locationController = TextEditingController();
  String? locationError;
  double? latitude;
  double? longitude;
  List<GeocodingResult> locationSuggestions = [];
  bool isSearchingLocation = false;
  Timer? _debounce;

  // ── Step 4: Logística y Privacidad ───────────────────────────
  final maxParticipantsController = TextEditingController();
  final membersPerTeamController = TextEditingController();
  TournamentAccessType? selectedAccessType;
  String? maxParticipantsError;
  String? membersPerTeamError;
  String? accessTypeError;

  // ── Step 5: Reglamento ───────────────────────────────────────
  final rulesController = TextEditingController();
  String? rulesError;

  // ── Step 6: Staff y Soporte ──────────────────────────────────
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

  // ── Navegación ───────────────────────────────────────────────
  static const int totalSteps = 8;
  int currentStep = 0;

  // ── Helpers para deporte ─────────────────────────────────────
  bool get isTeamSport =>
      selectedSport == TournamentSport.football ||
      selectedSport == TournamentSport.basketball ||
      selectedSport == TournamentSport.volleyball;

  // ── Navegación ───────────────────────────────────────────────

  bool canGoNext() => validateCurrentStep();

  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      currentStep = step;
      notifyListeners();
    }
  }

  // ── Validación ───────────────────────────────────────────────

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
        return _validateStaff();
      case 7:
        return true; // Review — always valid
      default:
        return true;
    }
  }

  bool _validateIdentity() {
    final nameOk = nameController.text.trim().length >= 3;
    final descOk = descriptionController.text.trim().length >= 10;
    final coverOk = coverBytes != null && coverBytes!.isNotEmpty;

    nameError = nameOk ? null : 'El nombre debe tener al menos 3 caracteres.';
    descriptionError =
        descOk ? null : 'Añade una descripción un poco más larga (mín. 10).';

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

    // registrationDeadline es opcional pero, si existe, debe ser antes del
    // evento.
    if (registrationDeadline != null && eventDate != null) {
      if (registrationDeadline!.isAfter(eventDate!)) {
        registrationDeadlineError =
            'El límite de inscripción debe ser antes del evento.';
      } else {
        registrationDeadlineError = null;
      }
    } else {
      registrationDeadlineError = null;
    }

    // bracketPublishDate es opcional.
    if (bracketPublishDate != null && eventDate != null) {
      if (bracketPublishDate!.isAfter(eventDate!)) {
        bracketPublishDateError =
            'Los cuadros deben publicarse antes del evento.';
      } else {
        bracketPublishDateError = null;
      }
    } else {
      bracketPublishDateError = null;
    }

    notifyListeners();
    return dateOk &&
        registrationDeadlineError == null &&
        bracketPublishDateError == null;
  }

  bool _validateGeolocation() {
    final locOk = locationController.text.trim().isNotEmpty;
    locationError = locOk ? null : '¿Dónde se juega? Indica el lugar.';
    notifyListeners();
    return locOk;
  }

  bool _validateLogistics() {
    final maxP = int.tryParse(maxParticipantsController.text.trim());
    final membersPerTeam =
        int.tryParse(membersPerTeamController.text.trim());

    final maxOk = maxP != null && maxP >= 2;
    final accessOk = selectedAccessType != null;

    maxParticipantsError = maxP == null
        ? 'Escribe un número de participantes.'
        : !maxOk
            ? 'Debe haber al menos 2 participantes.'
            : null;

    if (isTeamSport) {
      final membersOk = membersPerTeam != null && membersPerTeam >= 2;
      final relationOk = maxOk && membersOk && (membersPerTeam ?? 0) <= (maxP ?? 0);

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
    } else {
      membersPerTeamError = null;
      accessTypeError = accessOk ? null : 'Indica quién puede apuntarse.';
      notifyListeners();
      return maxOk && accessOk;
    }
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  // ── Geolocalización ──────────────────────────────────────────

  void onLocationQueryChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 3) {
      locationSuggestions = [];
      notifyListeners();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchLocation(query);
    });
  }

  Future<void> _searchLocation(String query) async {
    isSearchingLocation = true;
    notifyListeners();

    locationSuggestions = await _geocodingService.search(query);

    isSearchingLocation = false;
    notifyListeners();
  }

  void selectLocation(GeocodingResult result) {
    locationController.text = result.displayName;
    latitude = result.latitude;
    longitude = result.longitude;
    locationSuggestions = [];
    locationError = null;
    notifyListeners();
  }

  Future<void> onMapTap(double lat, double lng) async {
    latitude = lat;
    longitude = lng;
    notifyListeners();

    final address = await _geocodingService.reverseGeocode(lat, lng);
    if (address != null) {
      locationController.text = address;
      locationError = null;
    }
    notifyListeners();
  }

  // ── Contact links ────────────────────────────────────────────

  void addContactLink() {
    contactLinkControllers.add(TextEditingController());
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
      .map((c) => c.text.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  // ── Clearers ─────────────────────────────────────────────────

  void clearFieldError(String field) {
    switch (field) {
      case 'name':
        nameError = null;
      case 'description':
        descriptionError = null;
      case 'sport':
        sportError = null;
      case 'eventDate':
        eventDateError = null;
      case 'registrationDeadline':
        registrationDeadlineError = null;
      case 'bracketPublishDate':
        bracketPublishDateError = null;
      case 'location':
        locationError = null;
      case 'maxParticipants':
        maxParticipantsError = null;
      case 'membersPerTeam':
        membersPerTeamError = null;
      case 'accessType':
        accessTypeError = null;
      case 'rules':
        rulesError = null;
      case 'admin':
        adminError = null;
      case 'contactEmail':
        contactEmailError = null;
    }
    notifyListeners();
  }

  // ── Formatting ───────────────────────────────────────────────

  String formatDate(DateTime date) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
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
    adminController.dispose();
    contactEmailController.dispose();
    contactPhoneController.dispose();
    for (final c in contactLinkControllers) {
      c.dispose();
    }
    _geocodingService.dispose();
    super.dispose();
  }
}
