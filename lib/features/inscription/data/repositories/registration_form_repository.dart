import '../../../../core/models/registration_form.dart';

abstract interface class RegistrationFormRepository {
  Future<RegistrationFormSchema> getActiveForm(String tournamentId);

  Future<void> saveForm({
    required String tournamentId,
    required RegistrationFormSchema form,
    bool incrementVersion = true,
  });
}
