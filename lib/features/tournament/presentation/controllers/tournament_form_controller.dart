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

/// Controlador que centraliza todo el estado del formulario de creación de
/// torneos (8 pasos).
///
/// SRP: gestiona únicamente los valores del formulario, la validación por paso
/// y la búsqueda de ubicación. No contiene lógica de persistencia.
class TournamentFormController extends ChangeNotifier {
  TournamentFormController({GeocodingService? geocodingService})
    : _geocodingService = geocodingService ?? GeocodingService();

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

  // Step 6: Staff y Soporte
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
  static const int totalSteps = 8;
  int currentStep = 0;

  bool get isTeamSport =>
      selectedSport == TournamentSport.football ||
      selectedSport == TournamentSport.basketball ||
      selectedSport == TournamentSport.volleyball;

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
        return _validateStaff();
      case 7:
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
      .map((controller) => controller.text.trim())
      .where((value) => value.isNotEmpty)
      .toList();

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

    for (final controller in contactLinkControllers) {
      controller.dispose();
    }

    _geocodingService.dispose();
    super.dispose();
  }
}
