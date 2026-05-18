import 'package:flutter/foundation.dart';

import '../../../../database/participant/models/app_participant.dart';
import '../../../../database/team/models/app_team.dart';
import '../../../../features/tournament/data/model/app_tournament.dart';
import '../../../../features/user/data/models/app_user.dart';
import '../../../../core/widgets/registration_form_builder.dart';
import '../../domain/models/registration_form_schema.dart';
import '../../domain/models/registration_response.dart';
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
    EnrollInTournamentUseCase? useCase,
  }) : _useCase = useCase ?? EnrollInTournamentUseCase();

  final AppTournament tournament;
  final EnrollInTournamentUseCase _useCase;

  // ── Estado de carga ────────────────────────────────────────────────────────
  InscriptionLoadState loadState = InscriptionLoadState.idle;
  InscriptionSubmitState submitState = InscriptionSubmitState.idle;

  AppUser? currentUser;
  String? loadError;
  String? submitError;

  // ── Estado del formulario ──────────────────────────────────────────────────
  AppTeam? selectedTeam;
  String? teamValidationError;
  String? selectedCategoryId;

  // ── Campos adicionales del formulario ──────────────────────────────────────
  RegistrationFormSchema? get formSchema => tournament.registrationForm;
  bool get hasRegistrationForm => tournament.hasRegistrationForm;
  Map<String, dynamic> formResponses = {};
  Map<String, String> formFieldErrors = {};

  // ── Computed ───────────────────────────────────────────────────────────────

  bool get isTeamTournament => tournament.membersPerTeam != null && tournament.membersPerTeam! > 0;
  bool get hasCategories => tournament.categories.isNotEmpty;

  bool get canSubmit {
    if (loadState != InscriptionLoadState.loaded) return false;
    if (submitState == InscriptionSubmitState.submitting) return false;
    if (isTeamTournament && selectedTeam == null) return false;
    if (isTeamTournament && teamValidationError != null) return false;
    if (hasCategories && selectedCategoryId == null) return false;
    if (formFieldErrors.isNotEmpty) return false;
    return true;
  }

  // ── Campos adicionales ─────────────────────────────────────────────────────

  void updateFormResponse(String fieldId, dynamic value) {
    formResponses[fieldId] = value;
    formFieldErrors.remove(fieldId);
    notifyListeners();
  }

  bool validateFormFields() {
    if (!hasRegistrationForm) return true;
    formFieldErrors = RegistrationFormBuilder.validateAll(formSchema!, formResponses);
    notifyListeners();
    return formFieldErrors.isEmpty;
  }

  // ── Inicialización ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    loadState = InscriptionLoadState.loading;
    loadError = null;
    notifyListeners();

    try {
      currentUser = await _useCase.getCurrentUser();
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

  // ── Confirmar inscripción ──────────────────────────────────────────────────

  Future<AppParticipant?> confirmEnrollment() async {
    if (!validateFormFields()) return null;
    if (!canSubmit) return null;

    submitState = InscriptionSubmitState.submitting;
    submitError = null;
    notifyListeners();

    try {
      final entityId = isTeamTournament ? selectedTeam!.id : currentUser!.uid;
      final entityType = isTeamTournament
          ? ParticipantEntityType.team
          : ParticipantEntityType.user;

      // Convertir respuestas del formulario.
      final responses = hasRegistrationForm
          ? RegistrationFormBuilder.toResponses(formSchema!, formResponses)
          : <RegistrationResponse>[];

      final participant = await _useCase.execute(
        tournament: tournament,
        entityId: entityId,
        entityType: entityType,
        categoryId: selectedCategoryId,
        responses: responses,
        registrationFormVersion: formSchema?.version,
      );

      submitState = InscriptionSubmitState.success;
      notifyListeners();
      return participant;
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
}
