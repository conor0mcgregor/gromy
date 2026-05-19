import 'package:flutter/foundation.dart';

import '../../../../database/participant/models/app_participant.dart';
import '../../../../database/team/models/app_team.dart';
import '../../../../features/tournament/data/model/app_tournament.dart';
import '../../../../features/user/data/models/app_user.dart';
import '../../domain/models/registration_draft.dart';
import '../../domain/use_cases/enroll_in_tournament_use_case.dart';
import '../../domain/use_cases/registration_draft_use_case.dart';

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

/// Estados del proceso de guardado de borrador.
enum InscriptionDraftState { idle, saving, saved, error }

class InscriptionController extends ChangeNotifier {
  InscriptionController({
    required this.tournament,
    EnrollInTournamentUseCase? useCase,
    RegistrationDraftUseCase? draftUseCase,
  })  : _useCase = useCase ?? EnrollInTournamentUseCase(),
        _draftUseCase = draftUseCase ?? RegistrationDraftUseCase();

  final AppTournament tournament;
  final EnrollInTournamentUseCase _useCase;
  final RegistrationDraftUseCase _draftUseCase;

  // ── Estado de carga ────────────────────────────────────────────────────────
  InscriptionLoadState loadState = InscriptionLoadState.idle;
  InscriptionSubmitState submitState = InscriptionSubmitState.idle;
  InscriptionDraftState draftState = InscriptionDraftState.idle;

  AppUser? currentUser;
  String? loadError;
  String? submitError;
  String? draftError;

  // ── Estado del formulario ──────────────────────────────────────────────────
  AppTeam? selectedTeam;
  String? teamValidationError;
  String? selectedCategoryId;

  // ── Borrador cargado ───────────────────────────────────────────────────────
  RegistrationDraft? _loadedDraft;

  // ── Computed ───────────────────────────────────────────────────────────────

  bool get isTeamTournament =>
      tournament.membersPerTeam != null && tournament.membersPerTeam! > 0;
  bool get hasCategories => tournament.categories.isNotEmpty;

  bool get canSubmit {
    if (loadState != InscriptionLoadState.loaded) return false;
    if (submitState == InscriptionSubmitState.submitting) return false;
    if (draftState == InscriptionDraftState.saving) return false;
    if (isTeamTournament && selectedTeam == null) return false;
    if (isTeamTournament && teamValidationError != null) return false;
    if (hasCategories && selectedCategoryId == null) return false;
    return true;
  }

  bool get isSavingDraft => draftState == InscriptionDraftState.saving;

  // ── Inicialización ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    loadState = InscriptionLoadState.loading;
    loadError = null;
    notifyListeners();

    try {
      currentUser = await _useCase.getCurrentUser();

      // Intentar cargar borrador existente y pre-rellenar el formulario
      if (currentUser != null) {
        await _loadDraftIfExists();
      }

      loadState = InscriptionLoadState.loaded;
    } catch (e) {
      loadState = InscriptionLoadState.error;
      loadError = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> _loadDraftIfExists() async {
    try {
      final draft = await _draftUseCase.getRegistrationDraft(
        userId: currentUser!.uid,
        tournament: tournament,
      );

      if (draft == null) return;
      _loadedDraft = draft;

      // Pre-rellenar categoría (no requiere datos extra)
      if (draft.selectedCategoryId != null) {
        selectedCategoryId = draft.selectedCategoryId;
      }

      // El equipo se pre-rellena a través de selectTeam() una vez cargados
      // los equipos del usuario (ver _TeamSelector → onTap).
      // Guardamos el teamId en el draft para que _TeamSelector lo use.
    } catch (_) {
      // Error silencioso: el formulario simplemente aparece vacío
    }
  }

  /// ID del equipo que estaba seleccionado en el borrador (para pre-selección
  /// en _TeamSelector una vez se cargue la lista de equipos del usuario).
  String? get draftTeamId => _loadedDraft?.selectedTeamId;

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
        : _useCase.validateTeamEligibility(
            team: team, tournament: tournament);
    notifyListeners();
  }

  // ── Selección de categoría ─────────────────────────────────────────────────

  void selectCategory(String? categoryId) {
    selectedCategoryId = categoryId;
    notifyListeners();
  }

  // ── Guardar borrador ───────────────────────────────────────────────────────

  /// Guarda el estado actual como borrador sin validar campos requeridos.
  Future<void> saveDraft() async {
    if (currentUser == null) return;
    if (draftState == InscriptionDraftState.saving) return;

    draftState = InscriptionDraftState.saving;
    draftError = null;
    notifyListeners();

    try {
      await _draftUseCase.saveRegistrationDraft(
        tournament: tournament,
        selectedTeam: selectedTeam,
        selectedCategoryId: selectedCategoryId,
      );
      draftState = InscriptionDraftState.saved;
    } on DraftTournamentClosedException {
      draftState = InscriptionDraftState.error;
      draftError = 'El plazo de inscripción ha terminado. No se puede guardar el borrador.';
    } catch (e) {
      draftState = InscriptionDraftState.error;
      draftError = 'No se pudo guardar el borrador. Inténtalo de nuevo.';
    }
    notifyListeners();
  }

  /// Auto-save silencioso (llamado desde PopScope al salir de la pantalla).
  /// No actualiza estados ni notifica a la UI.
  Future<void> autoSaveDraftSilent() async {
    if (currentUser == null) return;
    if (submitState == InscriptionSubmitState.success) return;
    if (loadState != InscriptionLoadState.loaded) return;

    // Solo auto-guardar si el usuario seleccionó algo
    if (selectedTeam == null && selectedCategoryId == null) return;

    try {
      await _draftUseCase.saveRegistrationDraft(
        tournament: tournament,
        selectedTeam: selectedTeam,
        selectedCategoryId: selectedCategoryId,
      );
    } catch (_) {
      // Auto-save silencioso: nunca lanza errores al usuario
    }
  }

  // ── Confirmar inscripción ──────────────────────────────────────────────────

  Future<AppParticipant?> confirmEnrollment() async {
    if (!canSubmit) return null;

    submitState = InscriptionSubmitState.submitting;
    submitError = null;
    notifyListeners();

    try {
      final entityId =
          isTeamTournament ? selectedTeam!.id : currentUser!.uid;
      final entityType = isTeamTournament
          ? ParticipantEntityType.team
          : ParticipantEntityType.user;

      final participant = await _useCase.execute(
        tournament: tournament,
        entityId: entityId,
        entityType: entityType,
        categoryId: selectedCategoryId,
      );

      // Eliminar el borrador tras inscripción exitosa
      await _deleteDraftAfterEnrollment();

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

  Future<void> _deleteDraftAfterEnrollment() async {
    if (currentUser == null) return;
    try {
      await _draftUseCase.deleteRegistrationDraft(
        userId: currentUser!.uid,
        tournamentId: tournament.id,
      );
    } catch (_) {
      // El borrado es un paso de limpieza; no afecta al flujo principal
    }
  }

  void resetSubmitState() {
    submitState = InscriptionSubmitState.idle;
    submitError = null;
    notifyListeners();
  }

  void resetDraftState() {
    draftState = InscriptionDraftState.idle;
    draftError = null;
    notifyListeners();
  }
}
