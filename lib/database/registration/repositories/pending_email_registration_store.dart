import '../models/pending_email_registration.dart';

abstract interface class PendingEmailRegistrationStore {
  Future<void> save(PendingEmailRegistration registration);

  Future<PendingEmailRegistration?> getByUid(String uid);

  Future<void> deleteByUid(String uid);
}
