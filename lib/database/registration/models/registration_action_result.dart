sealed class RegistrationActionResult {
  const RegistrationActionResult();
}

final class RegistrationActionSuccess extends RegistrationActionResult {
  const RegistrationActionSuccess();
}

final class RegistrationActionFailure extends RegistrationActionResult {
  const RegistrationActionFailure(this.message);

  final String message;
}
