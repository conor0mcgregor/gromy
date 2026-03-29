import '../models/pending_email_registration.dart';
import '../models/registration_action_result.dart';

abstract interface class EmailRegistrationRepository {
  Future<RegistrationActionResult> startRegistration({
    required String email,
    required String password,
    required String nickname,
    required String name,
    required String lastName,
  });

  Future<RegistrationActionResult> completeRegistration();

  Future<RegistrationActionResult> resendVerificationEmail();

  Future<PendingEmailRegistration?> getPendingRegistrationForCurrentUser();

  Future<void> clearPendingRegistration();
}
