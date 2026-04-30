import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../participants/data/models/participant_display.dart';
import '../../../participants/data/services/participant_display_service.dart';
import '../../../tournament/data/model/app_tournament.dart';
import '../../../tournament/data/services/firebase_tournament_storage_service.dart';
import '../../../tournament/data/services/geocoding_service.dart';
import '../../../tournament/data/services/tournament_storage_service.dart';
import '../../../user/data/models/app_user.dart';
import '../../../user/data/services/firestore_user_service.dart';
import '../../data/repositories/admin_tournament_repository.dart';
import '../../data/services/firestore_admin_tournament_service.dart';
import '../../domain/use_cases/delete_tournament_use_case.dart';
import '../../domain/use_cases/remove_participant_use_case.dart';
import '../../domain/use_cases/update_tournament_use_case.dart';

enum ManagementRole { creator, admin }

class TournamentAdminView {
  const TournamentAdminView({
    required this.uid,
    required this.label,
    this.email,
  });

  final String uid;
  final String label;
  final String? email;
}

class TournamentManagementController extends ChangeNotifier {
  TournamentManagementController({
    required AppTournament tournament,
    AdminTournamentRepository? repository,
    TournamentStorageService? storageService,
    FirestoreUserService? userService,
    ParticipantDisplayService? participantService,
    GeocodingService? geocodingService,
    FirebaseAuth? auth,
  }) : _repository = repository ?? FirestoreAdminTournamentService(),
       _storageService = storageService ?? FirebaseTournamentStorageService(),
       _userService = userService ?? FirestoreUserService(),
       _participantService = participantService ?? ParticipantDisplayService(),
       _geocodingService = geocodingService ?? GeocodingService(),
       _original = tournament,
       _edited = tournament {
    _currentUid = (auth ?? FirebaseAuth.instance).currentUser?.uid ?? '';
    _role = _currentUid == tournament.organizerUid
        ? ManagementRole.creator
        : ManagementRole.admin;

    nameCtrl = TextEditingController(text: tournament.name);
    descriptionCtrl = TextEditingController(text: tournament.description);
    allInfoCtrl = TextEditingController(text: tournament.allInformation);
    locationCtrl = TextEditingController(text: tournament.location);
    maxParticipantsCtrl = TextEditingController(
      text: tournament.maxParticipants.toString(),
    );
    membersPerTeamCtrl = TextEditingController(
      text: (tournament.membersPerTeam ?? 0).toString(),
    );
    contactEmailCtrl = TextEditingController(
      text: tournament.contactEmail ?? '',
    );
    contactPhoneCtrl = TextEditingController(
      text: tournament.contactPhone ?? '',
    );
    adminLookupCtrl = TextEditingController();

    final links = tournament.contactLinks.isEmpty
        ? const ['']
        : tournament.contactLinks;
    contactLinkCtrls = links
        .map((link) => TextEditingController(text: link))
        .toList(growable: true);

    _editedCategories = List<String>.from(tournament.categories);
    _loadParticipants();
    _loadAdminUsers();
  }

  final AdminTournamentRepository _repository;
  final TournamentStorageService _storageService;
  final FirestoreUserService _userService;
  final ParticipantDisplayService _participantService;
  final GeocodingService _geocodingService;

  late final String _currentUid;
  late final ManagementRole _role;

  AppTournament _original;
  AppTournament _edited;
  XFile? _newCoverImage;

  bool _isSaving = false;
  bool _isDeleting = false;
  bool _loadingParticipants = true;
  bool _loadingAdmins = true;
  bool _isAddingAdmin = false;
  bool _isSearchingLocation = false;
  String? _errorMessage;
  String? _successMessage;
  String? _adminError;
  String? _nameError;
  String? _descriptionError;
  String? _allInfoError;
  String? _eventDateError;
  String? _registrationDeadlineError;
  String? _bracketPublishDateError;
  String? _locationError;
  String? _maxParticipantsError;
  String? _membersPerTeamError;
  String? _contactEmailError;

  List<ParticipantDisplay> _participants = [];
  List<TournamentAdminView> _adminUsers = [];
  List<String> _editedCategories = [];
  List<GeocodingResult> _locationSuggestions = [];
  Timer? _locationDebounce;
  int _locationSearchRequestId = 0;
  int _reverseGeocodeRequestId = 0;

  late final TextEditingController nameCtrl;
  late final TextEditingController descriptionCtrl;
  late final TextEditingController allInfoCtrl;
  late final TextEditingController locationCtrl;
  late final TextEditingController maxParticipantsCtrl;
  late final TextEditingController membersPerTeamCtrl;
  late final TextEditingController contactEmailCtrl;
  late final TextEditingController contactPhoneCtrl;
  late final TextEditingController adminLookupCtrl;
  late final List<TextEditingController> contactLinkCtrls;

  String get currentUid => _currentUid;
  ManagementRole get role => _role;
  bool get isCreator => _role == ManagementRole.creator;
  bool get isAdmin => _role == ManagementRole.admin;
  bool get isBusy => _isSaving || _isDeleting;
  AppTournament get original => _original;
  AppTournament get edited => _edited;
  XFile? get newCoverImage => _newCoverImage;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  bool get loadingParticipants => _loadingParticipants;
  bool get loadingAdmins => _loadingAdmins;
  bool get isAddingAdmin => _isAddingAdmin;
  bool get isSearchingLocation => _isSearchingLocation;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get adminError => _adminError;
  String? get nameError => _nameError;
  String? get descriptionError => _descriptionError;
  String? get allInfoError => _allInfoError;
  String? get eventDateError => _eventDateError;
  String? get registrationDeadlineError => _registrationDeadlineError;
  String? get bracketPublishDateError => _bracketPublishDateError;
  String? get locationError => _locationError;
  String? get maxParticipantsError => _maxParticipantsError;
  String? get membersPerTeamError => _membersPerTeamError;
  String? get contactEmailError => _contactEmailError;
  List<ParticipantDisplay> get participants => _participants;
  List<TournamentAdminView> get adminUsers => _adminUsers;
  List<String> get editedCategories => _editedCategories;
  List<GeocodingResult> get locationSuggestions => _locationSuggestions;

  bool get isTeamTournament => (_edited.membersPerTeam ?? 0) > 1;

  bool get hasChanges {
    _syncFromControllers();
    return _newCoverImage != null || _tournamentChanged(_original, _edited);
  }

  Future<void> _loadParticipants() async {
    _loadingParticipants = true;
    notifyListeners();
    try {
      _participants = await _participantService.getParticipants(_original.id);
    } catch (e) {
      _errorMessage = 'Error cargando participantes: $e';
    }
    _loadingParticipants = false;
    notifyListeners();
  }

  Future<void> _loadAdminUsers() async {
    _loadingAdmins = true;
    notifyListeners();
    try {
      _adminUsers = await _resolveAdmins(_edited.adminIds);
    } catch (e) {
      _errorMessage = 'Error cargando administradores: $e';
    }
    _loadingAdmins = false;
    notifyListeners();
  }

  Future<List<TournamentAdminView>> _resolveAdmins(
    List<String> adminIds,
  ) async {
    final resolved = <TournamentAdminView>[];
    for (final uid in adminIds) {
      final user = await _userService.getUser(uid);
      resolved.add(_adminView(uid, user));
    }
    return resolved;
  }

  TournamentAdminView _adminView(String uid, AppUser? user) {
    if (user == null) {
      return TournamentAdminView(uid: uid, label: uid);
    }
    final fullName = '${user.name} ${user.lastName}'.trim();
    final label = fullName.isEmpty
        ? user.nickname
        : '$fullName (@${user.nickname})';
    return TournamentAdminView(uid: uid, label: label, email: user.email);
  }

  void _syncFromControllers() {
    _edited = _copyEdited(
      name: nameCtrl.text.trim(),
      description: descriptionCtrl.text.trim(),
      allInformation: allInfoCtrl.text.trim(),
      location: locationCtrl.text.trim(),
      maxParticipants:
          int.tryParse(maxParticipantsCtrl.text.trim()) ??
          _original.maxParticipants,
      membersPerTeam: int.tryParse(membersPerTeamCtrl.text.trim()),
      contactEmail: _emptyToNull(contactEmailCtrl.text),
      setContactEmail: true,
      contactPhone: _emptyToNull(contactPhoneCtrl.text),
      setContactPhone: true,
      contactLinks: _contactLinksFromControllers(),
      categories: List<String>.from(_editedCategories),
    );
  }

  List<String> _contactLinksFromControllers() {
    return contactLinkCtrls
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void updateScheduledAt(DateTime date) {
    _edited = _copyEdited(scheduledAt: date);
    notifyListeners();
  }

  void updateRegistrationDeadline(DateTime? date) {
    _edited = _copyEdited(
      registrationDeadline: date,
      setRegistrationDeadline: true,
    );
    notifyListeners();
  }

  void updateBracketPublishDate(DateTime? date) {
    _edited = _copyEdited(
      bracketPublishDate: date,
      setBracketPublishDate: true,
    );
    notifyListeners();
  }

  void updateLocation({
    required double lat,
    required double lng,
    String? address,
  }) {
    _edited = _copyEdited(
      latitude: lat,
      longitude: lng,
      setCoordinates: true,
      location: address ?? _edited.location,
    );
    if (address != null) locationCtrl.text = address;
    notifyListeners();
  }

  void setCoverImage(XFile image) {
    _newCoverImage = image;
    notifyListeners();
  }

  void addCategory(String category) {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;
    if (_editedCategories.any(
      (c) => c.toLowerCase() == trimmed.toLowerCase(),
    )) {
      return;
    }
    _editedCategories.add(trimmed);
    notifyListeners();
  }

  void removeCategory(String category) {
    _editedCategories.remove(category);
    notifyListeners();
  }

  void addContactLinkField() {
    contactLinkCtrls.add(TextEditingController());
    notifyListeners();
  }

  void removeContactLinkField(int index) {
    if (contactLinkCtrls.length <= 1) return;
    if (index < 0 || index >= contactLinkCtrls.length) return;
    contactLinkCtrls[index].dispose();
    contactLinkCtrls.removeAt(index);
    notifyListeners();
  }

  bool validate() {
    _clearValidationErrors();

    final infoOk = _validateInfo();
    final datesOk = _validateDates();
    final logisticsOk = _validateLogistics();
    final contactOk = _validateContact();
    final locationOk = _validateLocation();

    notifyListeners();
    return infoOk && datesOk && logisticsOk && contactOk && locationOk;
  }

  void _clearValidationErrors() {
    _nameError = null;
    _descriptionError = null;
    _allInfoError = null;
    _eventDateError = null;
    _registrationDeadlineError = null;
    _bracketPublishDateError = null;
    _locationError = null;
    _maxParticipantsError = null;
    _membersPerTeamError = null;
    _contactEmailError = null;
  }

  bool _validateInfo() {
    final name = nameCtrl.text.trim();
    final desc = descriptionCtrl.text.trim();
    final info = allInfoCtrl.text.trim();

    bool ok = true;

    if (name.length < 3) {
      _nameError = 'El nombre debe tener al menos 3 caracteres.';
      ok = false;
    }

    if (desc.length < 10) {
      _descriptionError = 'Añade una descripción un poco más larga (mín. 10).';
      ok = false;
    }

    if (info.length < 100) {
      _allInfoError =
          'Añade más información sobre las reglas (mín. 100 caracteres).';
      ok = false;
    }

    return ok;
  }

  bool _validateDates() {
    final eventDate = _edited.scheduledAt;
    final deadline = _edited.registrationDeadline;
    final brackets = _edited.bracketPublishDate;

    bool ok = true;

    // La fecha del evento es obligatoria en el modelo, pero validamos que no sea pasada si se cambia
    final today = DateTime.now();
    final minDate = DateTime(today.year, today.month, today.day);

    if (eventDate.isBefore(minDate)) {
      _eventDateError = 'La fecha debe ser hoy o en el futuro.';
      ok = false;
    }

    if (deadline != null && deadline.isAfter(eventDate)) {
      _registrationDeadlineError =
          'El límite de inscripción debe ser antes del evento.';
      ok = false;
    }

    if (deadline != null && deadline.isBefore(minDate)) {
      _registrationDeadlineError =
      'El límite de inscripción debe ser hoy o en el futuro.';
      ok = false;
    }

    if (brackets != null && brackets.isAfter(eventDate)) {
      _bracketPublishDateError =
          'Los cuadros deben publicarse antes del evento.';
      ok = false;
    }

    if (brackets != null && brackets.isBefore(minDate)) {
      _bracketPublishDateError =
      'Los cuadros deben publicarse hoy o en el futuro.';
      ok = false;
    }


    return ok;
  }

  bool _validateLogistics() {
    final maxPart = int.tryParse(maxParticipantsCtrl.text.trim());
    final members = int.tryParse(membersPerTeamCtrl.text.trim());

    bool ok = true;

    if (maxPart == null || maxPart < 2) {
      _maxParticipantsError = 'Debe haber al menos 2 participantes.';
      ok = false;
    }

    if (isTeamTournament) {
      if (members == null || members < 2) {
        _membersPerTeamError = 'Cada equipo debe tener al menos 2 miembros.';
        ok = false;
      } else if (maxPart != null && members > maxPart) {
        _membersPerTeamError =
            'Los miembros por equipo no pueden superar el total.';
        ok = false;
      }
    }

    return ok;
  }

  bool _validateContact() {
    final email = contactEmailCtrl.text.trim();
    if (email.isEmpty) {
      _contactEmailError = 'El email de contacto es obligatorio.';
      return false;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      _contactEmailError = 'Introduce un email válido.';
      return false;
    }

    return true;
  }

  bool _validateLocation() {
    final hasText = locationCtrl.text.trim().isNotEmpty;
    final hasCoords = _edited.latitude != null && _edited.longitude != null;

    if (!hasText) {
      _locationError = '¿Dónde se juega? Indica el lugar.';
      return false;
    }

    if (!hasCoords) {
      _locationError = 'Selecciona una ubicación válida en el mapa.';
      return false;
    }

    return true;
  }


  Future<bool> addAdminFromInput() async {
    if (!isCreator) {
      _adminError = 'Solo el creador puede gestionar administradores';
      notifyListeners();
      return false;
    }

    final query = adminLookupCtrl.text.trim();
    if (query.isEmpty) {
      _adminError = 'Introduce un UID, nickname o email.';
      notifyListeners();
      return false;
    }

    _isAddingAdmin = true;
    _adminError = null;
    notifyListeners();

    try {
      final user = await _findUser(query);
      if (user == null) {
        _adminError = 'No se encontro un usuario con esos datos.';
        _isAddingAdmin = false;
        notifyListeners();
        return false;
      }

      if (_edited.adminIds.contains(user.uid)) {
        _adminError = 'Este usuario ya es administrador.';
        _isAddingAdmin = false;
        notifyListeners();
        return false;
      }

      final ids = List<String>.from(_edited.adminIds)..add(user.uid);
      _edited = _copyEdited(adminIds: ids);
      _adminUsers.add(_adminView(user.uid, user));
      adminLookupCtrl.clear();
      _isAddingAdmin = false;
      notifyListeners();
      return true;
    } catch (e) {
      _adminError = 'Error buscando usuario: $e';
      _isAddingAdmin = false;
      notifyListeners();
      return false;
    }
  }

  Future<AppUser?> _findUser(String query) async {
    if (query.contains('@')) {
      return _userService.getUserByEmail(query);
    }

    final byUid = await _userService.getUser(query);
    if (byUid != null) return byUid;

    return _userService.getUserByNickname(query);
  }

  void removeAdminLocally(String adminUid) {
    if (!isCreator) {
      _adminError = 'Solo el creador puede gestionar administradores';
      notifyListeners();
      return;
    }
    if (adminUid == _original.organizerUid) {
      _adminError = 'No se puede eliminar al creador.';
      notifyListeners();
      return;
    }

    final ids = List<String>.from(_edited.adminIds)..remove(adminUid);
    _edited = _copyEdited(adminIds: ids);
    _adminUsers.removeWhere((admin) => admin.uid == adminUid);
    _adminError = null;
    notifyListeners();
  }

  void onLocationQueryChanged(String query) {
    _locationDebounce?.cancel();
    _locationSearchRequestId++;

    final trimmed = query.trim();
    if (trimmed.length < 3) {
      _locationSuggestions = [];
      _isSearchingLocation = false;
      notifyListeners();
      return;
    }

    _locationDebounce = Timer(const Duration(milliseconds: 400), () {
      _searchLocation(trimmed);
    });
  }

  Future<void> _searchLocation(String query) async {
    final requestId = ++_locationSearchRequestId;
    _isSearchingLocation = true;
    notifyListeners();

    final results = await _geocodingService.search(query);
    if (requestId != _locationSearchRequestId) return;

    _locationSuggestions = results;
    _isSearchingLocation = false;
    notifyListeners();
  }

  void selectLocation(GeocodingResult result) {
    _locationSearchRequestId++;
    _reverseGeocodeRequestId++;
    locationCtrl.text = result.displayName;
    _locationSuggestions = [];
    _locationError = null;
    updateLocation(
      lat: result.latitude,
      lng: result.longitude,
      address: result.displayName,
    );
  }

  Future<void> onMapTap(double lat, double lng) async {
    final requestId = ++_reverseGeocodeRequestId;

    _locationSuggestions = [];
    _locationError = null;
    updateLocation(lat: lat, lng: lng);

    final address = await _geocodingService.reverseGeocode(lat, lng);
    if (requestId != _reverseGeocodeRequestId) return;

    updateLocation(
      lat: lat,
      lng: lng,
      address: address?.trim().isNotEmpty == true
          ? address
          : 'Ubicacion seleccionada (${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)})',
    );
  }

  Future<bool> saveChanges() async {
    if (!validate()) return false;

    _syncFromControllers();
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      var updated = _edited;
      if (_newCoverImage != null) {
        final url = await _storageService.uploadCoverImage(
          tournamentId: updated.id,
          image: _newCoverImage!,
        );
        updated = _copyEdited(portadaUrl: url);
        _edited = updated;
      }

      final useCase = UpdateTournamentUseCase(_repository);
      await useCase.execute(
        original: _original,
        updated: updated,
        callerUid: _currentUid,
      );

      _original = updated.copyWith(updatedAt: DateTime.now());
      _newCoverImage = null;
      _successMessage = 'Cambios guardados correctamente.';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al guardar: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeParticipant(String participantId) async {
    try {
      final useCase = RemoveParticipantUseCase(_repository);
      await useCase.execute(
        tournamentId: _original.id,
        participantId: participantId,
      );

      _participants.removeWhere((p) => p.participantId == participantId);
      final newCount = (_original.participantCount - 1).clamp(0, 999999);
      _original = _original.copyWith(participantCount: newCount);
      _edited = _copyEdited(participantCount: newCount);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar participante: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTournament() async {
    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final useCase = DeleteTournamentUseCase(_repository);
      await useCase.execute(
        tournamentId: _original.id,
        callerUid: _currentUid,
        creatorUid: _original.organizerUid,
      );

      if (_original.portadaUrl != null) {
        try {
          await _storageService.deleteCoverImage(_original.id);
        } catch (_) {
          // La eliminacion del torneo ya se completo; la portada no bloquea.
        }
      }

      _isDeleting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar torneo: $e';
      _isDeleting = false;
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    _adminError = null;
    _clearValidationErrors();
    notifyListeners();
  }

  AppTournament _copyEdited({
    String? name,
    String? description,
    String? allInformation,
    DateTime? scheduledAt,
    int? maxParticipants,
    int? membersPerTeam,
    String? location,
    double? latitude,
    double? longitude,
    bool setCoordinates = false,
    DateTime? registrationDeadline,
    bool setRegistrationDeadline = false,
    DateTime? bracketPublishDate,
    bool setBracketPublishDate = false,
    String? contactEmail,
    bool setContactEmail = false,
    String? contactPhone,
    bool setContactPhone = false,
    List<String>? contactLinks,
    List<String>? categories,
    List<String>? adminIds,
    String? portadaUrl,
    int? participantCount,
  }) {
    return AppTournament(
      id: _edited.id,
      name: name ?? _edited.name,
      description: description ?? _edited.description,
      allInformation: allInformation ?? _edited.allInformation,
      scheduledAt: scheduledAt ?? _edited.scheduledAt,
      maxParticipants: maxParticipants ?? _edited.maxParticipants,
      location: location ?? _edited.location,
      sport: _edited.sport,
      accessType: _edited.accessType,
      organizerUid: _edited.organizerUid,
      adminIds: adminIds ?? _edited.adminIds,
      createdAt: _edited.createdAt,
      updatedAt: _edited.updatedAt,
      portadaUrl: portadaUrl ?? _edited.portadaUrl,
      additionalInfo: _edited.additionalInfo,
      organizerEmail: _edited.organizerEmail,
      organizerDisplayName: _edited.organizerDisplayName,
      participantCount: participantCount ?? _edited.participantCount,
      membersPerTeam: membersPerTeam ?? _edited.membersPerTeam,
      latitude: setCoordinates ? latitude : _edited.latitude,
      longitude: setCoordinates ? longitude : _edited.longitude,
      registrationDeadline: setRegistrationDeadline
          ? registrationDeadline
          : _edited.registrationDeadline,
      bracketPublishDate: setBracketPublishDate
          ? bracketPublishDate
          : _edited.bracketPublishDate,
      contactEmail: setContactEmail ? contactEmail : _edited.contactEmail,
      contactPhone: setContactPhone ? contactPhone : _edited.contactPhone,
      contactLinks: contactLinks ?? _edited.contactLinks,
      categories: categories ?? _edited.categories,
    );
  }

  bool _tournamentChanged(AppTournament a, AppTournament b) {
    return a.name != b.name ||
        a.description != b.description ||
        a.allInformation != b.allInformation ||
        a.scheduledAt != b.scheduledAt ||
        a.maxParticipants != b.maxParticipants ||
        a.membersPerTeam != b.membersPerTeam ||
        a.location != b.location ||
        a.latitude != b.latitude ||
        a.longitude != b.longitude ||
        a.portadaUrl != b.portadaUrl ||
        a.registrationDeadline != b.registrationDeadline ||
        a.bracketPublishDate != b.bracketPublishDate ||
        a.contactEmail != b.contactEmail ||
        a.contactPhone != b.contactPhone ||
        a.participantCount != b.participantCount ||
        !_listEquals(a.contactLinks, b.contactLinks) ||
        !_listEquals(a.categories, b.categories) ||
        !_listEquals(a.adminIds, b.adminIds);
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _locationDebounce?.cancel();
    nameCtrl.dispose();
    descriptionCtrl.dispose();
    allInfoCtrl.dispose();
    locationCtrl.dispose();
    maxParticipantsCtrl.dispose();
    membersPerTeamCtrl.dispose();
    contactEmailCtrl.dispose();
    contactPhoneCtrl.dispose();
    adminLookupCtrl.dispose();
    for (final controller in contactLinkCtrls) {
      controller.dispose();
    }
    _geocodingService.dispose();
    super.dispose();
  }
}
