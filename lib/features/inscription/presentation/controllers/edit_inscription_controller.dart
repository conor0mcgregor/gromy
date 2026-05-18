import 'package:flutter/foundation.dart';

import '../../../../database/participant/models/app_participant.dart';
import '../../../../features/inscription/domain/models/registration_form_schema.dart';
import '../../../../features/inscription/domain/models/registration_response.dart';
import '../../../../features/tournament/data/model/app_tournament.dart';
import '../../domain/use_cases/edit_inscription_use_case.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  EditInscriptionController  ·  Presentación
//
//  Gestiona el estado del formulario de edición de inscripción.
// ─────────────────────────────────────────────────────────────────────────────

enum EditLoadState { idle, loading, loaded, error }
enum EditSaveState { idle, saving, success, error }

class EditInscriptionController extends ChangeNotifier {
  EditInscriptionController({
    required this.tournament,
    required this.participant,
    required this.currentUserId,
    EditInscriptionUseCase? useCase,
  })  : _useCase = useCase ?? EditInscriptionUseCase();

  final AppTournament tournament;
  final AppParticipant participant;
  final String currentUserId;
  final EditInscriptionUseCase _useCase;

  EditLoadState loadState = EditLoadState.idle;
  EditSaveState saveState = EditSaveState.idle;

  String? editabilityError;
  String? saveError;

  /// Respuestas actuales del formulario (fieldId → value).
  Map<String, dynamic> responses = {};

  /// Errores de validación de campos.
  Map<String, String> fieldErrors = {};

  /// Categoría seleccionada.
  String? selectedCategoryId;

  /// Esquema del formulario para la versión usada.
  RegistrationFormSchema? formSchema;

  bool get canSave =>
      loadState == EditLoadState.loaded &&
      saveState != EditSaveState.saving &&
      editabilityError == null &&
      fieldErrors.isEmpty;

  /// Inicializa el controlador cargando datos.
  void initialize() {
    loadState = EditLoadState.loading;
    notifyListeners();

    // Verificar editabilidad.
    editabilityError = _useCase.canEdit(
      tournament: tournament,
      participant: participant,
      currentUserId: currentUserId,
    );

    // Cargar respuestas existentes.
    for (final response in participant.responses) {
      responses[response.fieldId] = response.value;
    }

    // Cargar categoría.
    selectedCategoryId = participant.categoryId;

    // Cargar esquema del formulario.
    formSchema = tournament.registrationForm;

    loadState = EditLoadState.loaded;
    notifyListeners();
  }

  /// Actualiza una respuesta del formulario.
  void updateResponse(String fieldId, dynamic value) {
    responses[fieldId] = value;
    // Limpiar error del campo.
    fieldErrors.remove(fieldId);
    notifyListeners();
  }

  /// Selecciona una categoría.
  void selectCategory(String? categoryId) {
    selectedCategoryId = categoryId;
    notifyListeners();
  }

  /// Valida todos los campos y devuelve si son válidos.
  bool validateAll() {
    if (formSchema == null) return true;

    fieldErrors = {};
    for (final field in formSchema!.activeFields) {
      final error = field.validateValue(responses[field.id]);
      if (error != null) {
        fieldErrors[field.id] = error;
      }
    }
    notifyListeners();
    return fieldErrors.isEmpty;
  }

  /// Guarda los cambios.
  Future<AppParticipant?> saveChanges() async {
    if (!validateAll()) return null;

    saveState = EditSaveState.saving;
    saveError = null;
    notifyListeners();

    try {
      // Convertir respuestas.
      final responseList = <RegistrationResponse>[];
      if (formSchema != null) {
        for (final field in formSchema!.activeFields) {
          if (responses.containsKey(field.id)) {
            responseList.add(
              RegistrationResponse.fromField(field, responses[field.id]),
            );
          }
        }
      }

      final updated = await _useCase.execute(
        tournament: tournament,
        participant: participant,
        currentUserId: currentUserId,
        updatedResponses: responseList,
        updatedCategoryId: selectedCategoryId,
      );

      saveState = EditSaveState.success;
      notifyListeners();
      return updated;
    } catch (e) {
      saveState = EditSaveState.error;
      saveError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  void resetSaveState() {
    saveState = EditSaveState.idle;
    saveError = null;
    notifyListeners();
  }
}
