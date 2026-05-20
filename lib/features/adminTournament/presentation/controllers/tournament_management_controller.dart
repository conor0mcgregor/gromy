import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/models/registration_form.dart';
import '../../../notifications/data/repository/admin_invitation_repository_impl.dart';
import '../../../notifications/data/repository/tournament_invitation_repository_impl.dart';
import '../../../notifications/domain/use_cases/admin_invitation_use_cases.dart';
import '../../../participants/data/models/participant_display.dart';
import '../../../participants/data/services/participant_display_service.dart';
import '../../../tournament/data/model/app_tournament.dart';
import '../../../tournament/data/model/enums_tournament.dart';
import '../../../tournament/data/services/firebase_tournament_storage_service.dart';
import '../../../tournament/data/services/geocoding_service.dart';
import '../../../tournament/data/services/tournament_storage_service.dart';
import '../../../user/data/models/app_user.dart';
import '../../../user/data/services/firestore_user_service.dart';
import '../../data/repositories/admin_tournament_repository.dart';
import '../../data/services/firestore_admin_tournament_service.dart';
import '../../domain/use_cases/delete_tournament_use_case.dart';
import '../../domain/use_cases/migrate_category_participants_use_case.dart';
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

class PendingAdminInvitation {
  const PendingAdminInvitation({
    required this.userId,
    required this.label,
    required this.isPersisted,
    this.notificationId,
    this.email,
  });

  final String userId;
  final String label;
  final bool isPersisted;
  final String? notificationId;
  final String? email;

  PendingAdminInvitation copyWith({
    String? userId,
    String? label,
    bool? isPersisted,
    String? notificationId,
    String? email,
  }) {
    return PendingAdminInvitation(
      userId: userId ?? this.userId,
      label: label ?? this.label,
      isPersisted: isPersisted ?? this.isPersisted,
      notificationId: notificationId ?? this.notificationId,
      email: email ?? this.email,
    );
  }
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
    playerInviteLookupCtrl = TextEditingController();

    final links = tournament.contactLinks.isEmpty
        ? const ['']
        : tournament.contactLinks;
    contactLinkCtrls = links
        .map((link) => TextEditingController(text: link))
        .toList(growable: true);

    _editedCategories = List<String>.from(tournament.categories);
    _loadParticipants();
    _loadAdminUsers();
    _tryFixOrganizerName();
  }

  void _tryFixOrganizerName() async {
    if (_original.organizerDisplayName == null ||
        _original.organizerDisplayName!.isEmpty) {
      try {
        final user = await _userService.getUser(_original.organizerUid);
        if (user != null) {
          final fullName = '${user.name} ${user.lastName}'.trim();
          final displayName = fullName.isNotEmpty ? fullName : user.nickname;
          _original = _original.copyWith(organizerDisplayName: displayName);
          _edited = _edited.copyWith(organizerDisplayName: displayName);
          notifyListeners();
        }
      } catch (e) {
        developer.log('Error fixing organizer name: $e');
      }
    }
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
  bool _isSearchingPlayerInvite = false;
  bool _isSendingPlayerInvite = false;
  bool _isSearchingLocation = false;
  String? _errorMessage;
  String? _successMessage;
  String? _adminError;
  String? _playerInviteError;
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
  String? _registrationFormError;

  List<ParticipantDisplay> _participants = [];
  List<TournamentAdminView> _adminUsers = [];
  List<PendingAdminInvitation> _pendingInvitations = [];
  final Map<String, TournamentAdminView> _adminDirectory = {};
  final Map<String, PendingAdminInvitation> _stagedInvitationsByUserId = {};
  final Map<String, PendingAdminInvitation> _persistedInvitationsByUserId = {};
  final Set<String> _removedAdminIds = {};
  final Set<String> _cancelledInvitationIds = {};
  List<String> _editedCategories = [];
  List<GeocodingResult> _locationSuggestions = [];
  List<AppUser> _playerInviteSuggestions = [];
  Timer? _locationDebounce;
  Timer? _playerInviteDebounce;
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
  late final TextEditingController playerInviteLookupCtrl;
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
  bool get isSearchingPlayerInvite => _isSearchingPlayerInvite;
  bool get isSendingPlayerInvite => _isSendingPlayerInvite;
  bool get isSearchingLocation => _isSearchingLocation;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get adminError => _adminError;
  String? get playerInviteError => _playerInviteError;
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
  String? get registrationFormError => _registrationFormError;
  List<ParticipantDisplay> get participants => _participants;
  List<TournamentAdminView> get adminUsers => _adminUsers;
  List<PendingAdminInvitation> get pendingInvitations => _pendingInvitations;
  List<String> get removedAdmins => _removedAdminIds.toList(growable: false);
  List<String> get addedAdmins =>
      _stagedInvitationsByUserId.keys.toList(growable: false);
  List<String> get editedCategories => _editedCategories;
  List<GeocodingResult> get locationSuggestions => _locationSuggestions;
  List<AppUser> get playerInviteSuggestions => _playerInviteSuggestions;

  bool get isTeamTournament => (_edited.membersPerTeam ?? 0) > 1;

  bool get hasChanges {
    _syncFromControllers();
    return _newCoverImage != null ||
        _tournamentChanged(_original, _edited) ||
        _removedAdminIds.isNotEmpty ||
        _stagedInvitationsByUserId.isNotEmpty ||
        _cancelledInvitationIds.isNotEmpty;
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
      final resolved = await _resolveAdmins(_original.adminIds);
      _adminDirectory
        ..clear()
        ..addEntries(resolved.map((admin) => MapEntry(admin.uid, admin)));
      _rebuildLocalAdminState();
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

  List<String> get _effectiveAdminIds => _original.adminIds
      .where((uid) => !_removedAdminIds.contains(uid))
      .toList(growable: false);

  void _rebuildLocalAdminState() {
    _adminUsers = _effectiveAdminIds
        .map(
          (uid) =>
              _adminDirectory[uid] ?? TournamentAdminView(uid: uid, label: uid),
        )
        .toList(growable: false);

    _pendingInvitations = [
      ..._persistedInvitationsByUserId.values.where(
        (invitation) =>
            invitation.notificationId == null ||
            !_cancelledInvitationIds.contains(invitation.notificationId),
      ),
      ..._stagedInvitationsByUserId.values,
    ];
    _edited = _copyEdited(adminIds: _effectiveAdminIds);
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
      adminIds: _effectiveAdminIds,
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

  int participantCountInCategory(String category) {
    return _participants.where((p) => p.categoryId == category).length;
  }

  List<String> categoriesExcept(String category) {
    return _editedCategories.where((c) => c != category).toList(growable: false);
  }

  void revertLocation({
    required String location,
    double? latitude,
    double? longitude,
  }) {
    locationCtrl.text = location;
    _edited = _copyEdited(
      location: location,
      latitude: latitude,
      longitude: longitude,
      setCoordinates: true,
    );
    _locationSuggestions = [];
    _locationError = null;
    notifyListeners();
  }

  Future<bool> migrateAndRemoveCategory({
    required String sourceCategory,
    required String targetCategory,
  }) async {
    _errorMessage = null;
    _isSaving = true;
    notifyListeners();

    try {
      final count = participantCountInCategory(sourceCategory);
      if (count > 0) {
        final useCase = MigrateCategoryParticipantsUseCase(_repository);
        await useCase.execute(
          tournamentId: _original.id,
          sourceCategory: sourceCategory,
          targetCategory: targetCategory,
          allowedCategories: _editedCategories,
        );

        _participants = _participants
            .map(
              (participant) => participant.categoryId == sourceCategory
                  ? _copyParticipantCategory(participant, targetCategory)
                  : participant,
            )
            .toList(growable: false);
      }

      removeCategory(sourceCategory);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error al eliminar categoría: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  ParticipantDisplay _copyParticipantCategory(
    ParticipantDisplay participant,
    String categoryId,
  ) {
    return switch (participant) {
      UserParticipantDisplay(:final user) => UserParticipantDisplay(
        participantId: participant.participantId,
        entityId: participant.entityId,
        entityType: participant.entityType,
        categoryId: categoryId,
        user: user,
      ),
      TeamParticipantDisplay(:final team) => TeamParticipantDisplay(
        participantId: participant.participantId,
        entityId: participant.entityId,
        entityType: participant.entityType,
        categoryId: categoryId,
        team: team,
      ),
    };
  }

  void upsertRegistrationField(RegistrationField field) {
    final normalized = _normalizeRegistrationField(field);
    final fields = [..._edited.registrationForm.fields];
    final index = fields.indexWhere((item) => item.id == normalized.id);
    if (index >= 0) {
      fields[index] = normalized.copyWith(updatedAt: DateTime.now());
    } else {
      fields.add(normalized.copyWith(order: fields.length));
    }
    _edited = _copyEdited(
      registrationForm: _edited.registrationForm.copyWith(
        fields: _withOrderedFields(fields),
      ),
    );
    _registrationFormError = null;
    notifyListeners();
  }

  void removeRegistrationField(String id) {
    final fields = _edited.registrationForm.fields
        .where((field) => field.id != id)
        .toList(growable: false);
    _edited = _copyEdited(
      registrationForm: _edited.registrationForm.copyWith(
        fields: _withOrderedFields(fields),
      ),
    );
    _registrationFormError = null;
    notifyListeners();
  }

  void toggleRegistrationField(String id, bool enabled) {
    final fields = _edited.registrationForm.fields.map((field) {
      if (field.id != id) return field;
      return field.copyWith(enabled: enabled, updatedAt: DateTime.now());
    }).toList();
    _edited = _copyEdited(
      registrationForm: _edited.registrationForm.copyWith(
        fields: _withOrderedFields(fields),
      ),
    );
    _registrationFormError = null;
    notifyListeners();
  }

  void moveRegistrationField(String id, int delta) {
    final fields = [..._edited.registrationForm.fields]
      ..sort((a, b) => a.order.compareTo(b.order));
    final index = fields.indexWhere((field) => field.id == id);
    if (index < 0) return;
    final target = index + delta;
    if (target < 0 || target >= fields.length) return;
    final field = fields.removeAt(index);
    fields.insert(target, field);
    _edited = _copyEdited(
      registrationForm: _edited.registrationForm.copyWith(
        fields: _withOrderedFields(fields),
      ),
    );
    _registrationFormError = null;
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
    final registrationFormOk = _validateRegistrationForm();

    notifyListeners();
    return infoOk &&
        datesOk &&
        logisticsOk &&
        contactOk &&
        locationOk &&
        registrationFormOk;
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
    _registrationFormError = null;
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

  bool _validateRegistrationForm() {
    final errors = RegistrationFormValidator.validateSchema(
      _edited.registrationForm,
    );
    _registrationFormError = errors.isEmpty ? null : errors.first;
    return errors.isEmpty;
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
    _playerInviteError = null;
    notifyListeners();

    try {
      debugPrint(
        '[TournamentManagementController] stageAdminChange '
        'query="$query" tournamentId=${_original.id}',
      );

      final user = await _findUser(query);
      if (user == null) {
        _adminError = 'No se encontro un usuario con esos datos.';
        _isAddingAdmin = false;
        notifyListeners();
        return false;
      }

      final restoredAdmin = _removedAdminIds.remove(user.uid);
      if (restoredAdmin) {
        _adminDirectory[user.uid] = _adminView(user.uid, user);
        adminLookupCtrl.clear();
        _adminError = null;
        _isAddingAdmin = false;
        _rebuildLocalAdminState();
        notifyListeners();
        return true;
      }

      if (_effectiveAdminIds.contains(user.uid)) {
        _adminError = 'Este usuario ya es administrador.';
        _isAddingAdmin = false;
        notifyListeners();
        return false;
      }

      if (_persistedInvitationsByUserId.containsKey(user.uid) ||
          _stagedInvitationsByUserId.containsKey(user.uid)) {
        _adminError = 'Este usuario ya tiene una invitacion pendiente.';
        _isAddingAdmin = false;
        notifyListeners();
        return false;
      }

      final fullName = '${user.name} ${user.lastName}'.trim();
      final label = fullName.isEmpty
          ? user.nickname
          : '$fullName (@${user.nickname})';

      _stagedInvitationsByUserId[user.uid] = PendingAdminInvitation(
        userId: user.uid,
        label: label,
        email: user.email,
        isPersisted: false,
      );
      _adminDirectory[user.uid] = _adminView(user.uid, user);

      adminLookupCtrl.clear();
      _adminError = null;
      _isAddingAdmin = false;
      _rebuildLocalAdminState();
      notifyListeners();
      return true;
    } catch (e) {
      _adminError = e.toString().replaceFirst('Exception: ', '');
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

  void onPlayerInviteQueryChanged(String query) {
    _playerInviteDebounce?.cancel();
    _playerInviteError = null;
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      _playerInviteSuggestions = [];
      _isSearchingPlayerInvite = false;
      notifyListeners();
      return;
    }

    _playerInviteDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchPlayerInvite(trimmed);
    });
  }

  Future<void> _searchPlayerInvite(String query) async {
    _isSearchingPlayerInvite = true;
    _playerInviteError = null;
    notifyListeners();

    try {
      final users = await _userService.searchUsersByNicknamePrefix(query);
      _playerInviteSuggestions = users
          .where((user) => user.uid != _currentUid)
          .toList(growable: false);
    } catch (e) {
      _playerInviteError = 'No se pudo buscar jugadores. Inténtalo de nuevo.';
      _playerInviteSuggestions = [];
    }

    _isSearchingPlayerInvite = false;
    notifyListeners();
  }

  Future<bool> sendPlayerInvitation(AppUser user) async {
    if (_edited.accessType != TournamentAccessType.privateInviteOnly) {
      _playerInviteError =
          'Las invitaciones directas solo están disponibles en torneos privados.';
      notifyListeners();
      return false;
    }

    if (_isSendingPlayerInvite) return false;
    _isSendingPlayerInvite = true;
    _playerInviteError = null;
    _adminError = null;
    notifyListeners();

    try {
      final repository = CloudFunctionTournamentInvitationRepository();
      await repository.sendInvitation(
        tournamentId: _original.id,
        invitedUserId: user.uid,
      );
      playerInviteLookupCtrl.clear();
      _playerInviteSuggestions = [];
      _isSendingPlayerInvite = false;
      notifyListeners();
      return true;
    } catch (e) {
      _playerInviteError = _errorMessageFrom(e);
      _isSendingPlayerInvite = false;
      notifyListeners();
      return false;
    }
  }

  String _errorMessageFrom(Object error) {
    if (error is Exception) {
      final message = error.toString().replaceFirst('Exception: ', '').trim();
      if (message.isNotEmpty) return message;
    }
    return 'No se pudo enviar la invitación. Inténtalo de nuevo.';
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

    if (_stagedInvitationsByUserId.remove(adminUid) != null) {
      _adminError = null;
      _rebuildLocalAdminState();
      notifyListeners();
      return;
    }

    if (!_effectiveAdminIds.contains(adminUid)) {
      _adminError =
          'Ese usuario ya no figura como administrador en el formulario.';
      notifyListeners();
      return;
    }

    _removedAdminIds.add(adminUid);
    _adminError = null;
    _rebuildLocalAdminState();
    notifyListeners();
  }

  Future<bool> cancelPendingInvitation(String userId) async {
    if (!isCreator) {
      _adminError = 'Solo el creador puede cancelar invitaciones.';
      notifyListeners();
      return false;
    }

    final invitation = _pendingInvitations.firstWhere(
      (inv) => inv.userId == userId,
      orElse: () => const PendingAdminInvitation(
        userId: '',
        label: '',
        isPersisted: false,
      ),
    );

    if (invitation.userId.isEmpty) {
      _stagedInvitationsByUserId.remove(userId);
      _persistedInvitationsByUserId.remove(userId);
      _rebuildLocalAdminState();
      notifyListeners();
      return true;
    }

    if (!invitation.isPersisted) {
      _stagedInvitationsByUserId.remove(userId);
    } else {
      if (invitation.notificationId != null) {
        _cancelledInvitationIds.add(invitation.notificationId!);
      }
      _persistedInvitationsByUserId.remove(userId);
    }

    _rebuildLocalAdminState();
    notifyListeners();
    return true;
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
    _rebuildLocalAdminState();
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final invitationRepo = CloudFunctionAdminInvitationRepository();
    final sendUseCase = SendAdminInvitationUseCase(invitationRepo);
    final cancelUseCase = CancelAdminInvitationUseCase(invitationRepo);
    final createdInvitationIds = <String, String>{};

    try {
      var updated = _edited;
      if (_newCoverImage != null) {
        final url = await _storageService.uploadCoverImage(
          tournamentId: updated.id,
          ownerUid: _currentUid,
          image: _newCoverImage!,
        );
        updated = _copyEdited(portadaUrl: url, adminIds: _effectiveAdminIds);
        _edited = updated;
      }

      for (final invitation in _stagedInvitationsByUserId.values) {
        final notificationId = await sendUseCase(
          tournamentId: _original.id,
          invitedUserId: invitation.userId,
        );
        createdInvitationIds[invitation.userId] = notificationId;
      }

      for (final notificationId in _cancelledInvitationIds) {
        await cancelUseCase(notificationId: notificationId);
      }

      final useCase = UpdateTournamentUseCase(_repository);
      await useCase.execute(
        original: _original,
        updated: updated,
        callerUid: _currentUid,
      );

      _original = updated.copyWith(updatedAt: DateTime.now());
      _persistedInvitationsByUserId.addEntries(
        _stagedInvitationsByUserId.entries.map(
          (entry) => MapEntry(
            entry.key,
            entry.value.copyWith(
              isPersisted: true,
              notificationId: createdInvitationIds[entry.key],
            ),
          ),
        ),
      );
      _stagedInvitationsByUserId.clear();
      _removedAdminIds.clear();
      _cancelledInvitationIds.clear();
      _rebuildLocalAdminState();
      _newCoverImage = null;
      _successMessage = 'Cambios guardados correctamente.';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      for (final notificationId in createdInvitationIds.values) {
        try {
          await cancelUseCase(notificationId: notificationId);
        } catch (_) {}
      }
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
        } catch (_) {}
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
    _playerInviteError = null;
    _clearValidationErrors();
    notifyListeners();
  }

  void toggleRegistrationStatus() {
    final nextStatus = _edited.status == TournamentStatus.registration
        ? TournamentStatus.in_progress
        : TournamentStatus.registration;
    _edited = _copyEdited(status: nextStatus);
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
    TournamentStatus? status,
    RegistrationFormSchema? registrationForm,
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
      status: status ?? _edited.status,
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
      registrationForm: registrationForm ?? _edited.registrationForm,
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
        a.organizerDisplayName != b.organizerDisplayName ||
        a.organizerEmail != b.organizerEmail ||
        a.status != b.status ||
        !_listEquals(a.contactLinks, b.contactLinks) ||
        !_listEquals(a.categories, b.categories) ||
        !_registrationFormsEqual(a.registrationForm, b.registrationForm) ||
        !_listEquals(a.adminIds, b.adminIds);
  }

  bool _registrationFormsEqual(
    RegistrationFormSchema a,
    RegistrationFormSchema b,
  ) {
    if (a.version != b.version || a.fields.length != b.fields.length) {
      return false;
    }
    for (var i = 0; i < a.fields.length; i++) {
      final left = a.fields[i];
      final right = b.fields[i];
      if (left.id != right.id ||
          left.label != right.label ||
          left.description != right.description ||
          left.type != right.type ||
          left.required != right.required ||
          left.order != right.order ||
          left.enabled != right.enabled ||
          left.createdAt != right.createdAt ||
          left.updatedAt != right.updatedAt ||
          !_listEquals(left.options, right.options)) {
        return false;
      }
    }
    return true;
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
    _playerInviteDebounce?.cancel();
    nameCtrl.dispose();
    descriptionCtrl.dispose();
    allInfoCtrl.dispose();
    locationCtrl.dispose();
    maxParticipantsCtrl.dispose();
    membersPerTeamCtrl.dispose();
    contactEmailCtrl.dispose();
    contactPhoneCtrl.dispose();
    adminLookupCtrl.dispose();
    playerInviteLookupCtrl.dispose();
    for (final controller in contactLinkCtrls) {
      controller.dispose();
    }
    _geocodingService.dispose();
    super.dispose();
  }
}
