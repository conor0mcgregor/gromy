import 'package:flutter/foundation.dart';

import '../../../../core/models/registration_form.dart';
import '../../../../database/participant/models/app_participant.dart';
import '../../../../database/team/models/app_team.dart';
import '../../../../features/tournament/data/model/app_tournament.dart';
import '../../../../features/tournament/data/model/enums_tournament.dart';
import '../../../../features/user/data/models/app_user.dart';
import '../../../notifications/data/repository/tournament_invitation_repository_impl.dart';
import '../../data/models/join_request.dart';
import '../../domain/use_cases/create_join_request_use_case.dart';
import '../../domain/use_cases/enroll_in_tournament_use_case.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  InscriptionController  ·  Presentación (ViewModel / Controller)
//
//  Gestiona el estado del formulario de inscripción.
//  Separa completamente la lógica de negocio de los widgets.
//
//  SRP: única responsabilidad → gestionar el estado de la inscripción.
//  OCP: el estado se extiende añadiendo nuevos campos sin romper lo existente.
// ─────────────────────────────────────────────────────────────────────────────

/// Estados posibles de la carga inicial.
enum InscriptionLoadState { idle, loading, loaded, error }

/// Estados del proceso de envío.
enum InscriptionSubmitState { idle, submitting, success, error }

class InscriptionController extends ChangeNotifier {
  InscriptionController({
    required this.tournament,
    this.invitationNotificationId,
    EnrollInTournamentUseCase? useCase,
    CreateJoinRequestUseCase? createJoinRequestUseCase,
    CloudFunctionTournamentInvitationRepository? invitationRepository,
  }) : _useCase = useCase ?? EnrollInTournamentUseCase(),
       _createJoinRequestUseCase =
           createJoinRequestUseCase ?? CreateJoinRequestUseCase(),
       _invitationRepository = invitationRepository;

  final AppTournament tournament;
  final String? invitationNotificationId;
  final EnrollInTournamentUseCase _useCase;
  final CreateJoinRequestUseCase _createJoinRequestUseCase;
  final CloudFunctionTournamentInvitationRepository? _invitationRepository;

  // ── Estado de carga ────────────────────────────────────────────────────────
  InscriptionLoadState loadState = InscriptionLoadState.idle;
  InscriptionSubmitState submitState = InscriptionSubmitState.idle;

  AppUser? currentUser;
  String? loadError;
  String? submitError;
  bool submittedJoinRequest = false;

  // ── Estado del formulario ──────────────────────────────────────────────────
  AppTeam? selectedTeam;
  String? teamValidationError;
  String? selectedCategoryId;
  final Map<String, dynamic> registrationValues = {};
  Map<String, String> registrationErrors = {};

  // ── Computed ───────────────────────────────────────────────────────────────

  bool get isTeamTournament =>
      tournament.membersPerTeam != null && tournament.membersPerTeam! > 0;
  bool get hasCategories => tournament.categories.isNotEmpty;
  RegistrationFormSchema get registrationForm => tournament.registrationForm;
  bool get hasAdditionalFields => registrationForm.activeFields.isNotEmpty;

  bool get canSubmit {
    if (loadState != InscriptionLoadState.loaded) return false;
    if (submitState == InscriptionSubmitState.submitting) return false;
    if (isTeamTournament && selectedTeam == null) return false;
    if (isTeamTournament && teamValidationError != null) return false;
    if (hasCategories && selectedCategoryId == null) return false;
    if (registrationErrors.isNotEmpty) return false;
    return true;
  }

  // ── Inicialización ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    loadState = InscriptionLoadState.loading;
    loadError = null;
    notifyListeners();

    try {
      currentUser = await _useCase.getCurrentUser();
      _initializeAdditionalFieldValues();
      loadState = InscriptionLoadState.loaded;
    } catch (e) {
      loadState = InscriptionLoadState.error;
      loadError = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  // ── Obtener equipos ────────────────────────────────────────────────────────

  Stream<List<AppTeam>> watchUserTeams() {
    final uid = currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _useCase.watchUserTeams(uid);
  }

  // ── Selección de equipo ────────────────────────────────────────────────────

  void selectTeam(AppTeam? team) {
    selectedTeam = team;
    teamValidationError = team == null
        ? null
        : _useCase.validateTeamEligibility(team: team, tournament: tournament);
    notifyListeners();
  }

  // ── Selección de categoría ─────────────────────────────────────────────────

  void selectCategory(String? categoryId) {
    selectedCategoryId = categoryId;
    notifyListeners();
  }

  void updateRegistrationValue(String fieldId, dynamic value) {
    registrationValues[fieldId] = value;
    registrationErrors = RegistrationFormValidator.validateResponses(
      schema: registrationForm,
      values: registrationValues,
    );
    notifyListeners();
  }

  void _initializeAdditionalFieldValues() {
    for (final field in registrationForm.activeFields) {
      registrationValues.putIfAbsent(
        field.id,
        () => field.type == RegistrationFieldType.checkbox ? false : null,
      );
    }
    registrationErrors = RegistrationFormValidator.validateResponses(
      schema: registrationForm,
      values: registrationValues,
    );
  }

  // ── Confirmar inscripción ──────────────────────────────────────────────────

  Future<Object?> confirmEnrollment() async {
    registrationErrors = RegistrationFormValidator.validateResponses(
      schema: registrationForm,
      values: registrationValues,
    );
    if (registrationErrors.isNotEmpty) {
      notifyListeners();
      return null;
    }
    if (!canSubmit) return null;

    submitState = InscriptionSubmitState.submitting;
    submitError = null;
    notifyListeners();

    try {
      final entityId = isTeamTournament ? selectedTeam!.id : currentUser!.uid;
      final entityType = isTeamTournament
          ? ParticipantEntityType.team
          : ParticipantEntityType.user;

      final Object result;
      if (tournament.accessType == TournamentAccessType.publicOpen) {
        result = await _useCase.execute(
          tournament: tournament,
          entityId: entityId,
          entityType: entityType,
          categoryId: selectedCategoryId,
          registrationValues: registrationValues,
        );
        submittedJoinRequest = false;
      } else {
        final JoinRequest request = await _createJoinRequestUseCase.execute(
          tournament: tournament,
          entityId: entityId,
          entityType: entityType,
          requestedBy: currentUser!,
          categoryId: selectedCategoryId,
          registrationValues: registrationValues,
        );
        result = request;
        submittedJoinRequest = true;
      }

      await _acceptInvitationIfNeeded();

      submitState = InscriptionSubmitState.success;
      notifyListeners();
      return result;
    } on AlreadyEnrolledException {
      submitState = InscriptionSubmitState.error;
      submitError = 'Ya estás inscrito en este torneo.';
      notifyListeners();
      return null;
    } catch (e) {
      submitState = InscriptionSubmitState.error;
      submitError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  void resetSubmitState() {
    submitState = InscriptionSubmitState.idle;
    submitError = null;
    notifyListeners();
  }

  Future<void> _acceptInvitationIfNeeded() async {
    final notificationId = invitationNotificationId;
    if (notificationId == null || notificationId.isEmpty) return;
    final repository =
        _invitationRepository ?? CloudFunctionTournamentInvitationRepository();
    await repository.acceptInvitation(notificationId: notificationId);
  }
}
