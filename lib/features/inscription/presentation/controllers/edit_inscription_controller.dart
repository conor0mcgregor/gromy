import 'package:flutter/foundation.dart';

import '../../../../core/models/registration_form.dart';
import '../../../../database/participant/models/app_participant.dart';
import '../../../tournament/data/model/app_tournament.dart';
import '../../domain/use_cases/edit_inscription_use_case.dart';

enum EditInscriptionLoadState { idle, loading, loaded, error }

enum EditInscriptionSubmitState { idle, submitting, success, error }

class EditInscriptionController extends ChangeNotifier {
  EditInscriptionController({
    required this.tournament,
    required this.initialParticipant,
    EditInscriptionUseCase? useCase,
  }) : _useCase = useCase ?? EditInscriptionUseCase();

  final AppTournament tournament;
  final AppParticipant initialParticipant;
  final EditInscriptionUseCase _useCase;

  EditInscriptionLoadState loadState = EditInscriptionLoadState.idle;
  EditInscriptionSubmitState submitState = EditInscriptionSubmitState.idle;

  AppParticipant? participant;
  EditInscriptionAvailability? availability;
  String? loadError;
  String? submitError;
  bool lastSaveRequiredReview = false;

  final Map<String, dynamic> registrationValues = {};
  Map<String, String> registrationErrors = {};
  String notes = '';
  String complementaryInfo = '';
  bool hasUnsavedChanges = false;

  RegistrationFormSchema get registrationForm => tournament.registrationForm;
  bool get hasAdditionalFields => registrationForm.activeFields.isNotEmpty;
  bool get canEdit => availability?.canEdit == true;
  bool get canSubmit {
    return loadState == EditInscriptionLoadState.loaded &&
        submitState != EditInscriptionSubmitState.submitting &&
        canEdit &&
        registrationErrors.isEmpty &&
        hasUnsavedChanges;
  }

  Future<void> initialize() async {
    loadState = EditInscriptionLoadState.loading;
    loadError = null;
    notifyListeners();

    try {
      participant =
          await _useCase.getParticipant(
            tournamentId: tournament.id,
            participantId: initialParticipant.id,
          ) ??
          initialParticipant;
      _seedValues(participant!);
      availability = await _useCase.checkEditable(
        tournament: tournament,
        participant: participant!,
      );
      loadState = EditInscriptionLoadState.loaded;
    } catch (e) {
      loadState = EditInscriptionLoadState.error;
      loadError = _cleanError(e);
    }
    notifyListeners();
  }

  void updateRegistrationValue(String fieldId, dynamic value) {
    registrationValues[fieldId] = value;
    registrationErrors = RegistrationFormValidator.validateResponses(
      schema: registrationForm,
      values: registrationValues,
    );
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void updateNotes(String value) {
    notes = value;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  void updateComplementaryInfo(String value) {
    complementaryInfo = value;
    hasUnsavedChanges = true;
    notifyListeners();
  }

  Future<bool> save() async {
    registrationErrors = RegistrationFormValidator.validateResponses(
      schema: registrationForm,
      values: registrationValues,
    );
    if (!canSubmit) {
      notifyListeners();
      return false;
    }

    submitState = EditInscriptionSubmitState.submitting;
    submitError = null;
    notifyListeners();

    try {
      final result = await _useCase.saveChanges(
        tournamentId: tournament.id,
        participantId: participant!.id,
        registrationValues: registrationValues,
        notes: notes,
        complementaryInfo: complementaryInfo,
      );
      lastSaveRequiredReview = result.requiresReview;
      submitState = EditInscriptionSubmitState.success;
      hasUnsavedChanges = false;
      notifyListeners();
      return true;
    } catch (e) {
      submitState = EditInscriptionSubmitState.error;
      submitError = _cleanError(e);
      notifyListeners();
      return false;
    }
  }

  void resetSubmitState() {
    submitState = EditInscriptionSubmitState.idle;
    submitError = null;
    notifyListeners();
  }

  void _seedValues(AppParticipant source) {
    final savedValues = {
      for (final response in source.registrationResponses)
        response.fieldId: response.value,
    };
    for (final field in registrationForm.activeFields) {
      registrationValues[field.id] =
          savedValues[field.id] ??
          (field.type == RegistrationFieldType.checkbox ? false : null);
    }
    notes = source.notes ?? '';
    complementaryInfo = source.complementaryInfo ?? '';
    registrationErrors = RegistrationFormValidator.validateResponses(
      schema: registrationForm,
      values: registrationValues,
    );
    hasUnsavedChanges = false;
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
