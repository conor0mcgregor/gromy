sealed class AppAccessState {
  const AppAccessState();
}

final class AppAccessUnauthenticated extends AppAccessState {
  const AppAccessUnauthenticated();
}

final class AppAccessAuthenticated extends AppAccessState {
  const AppAccessAuthenticated();
}

final class AppAccessPendingEmailRegistration extends AppAccessState {
  const AppAccessPendingEmailRegistration({
    required this.uid,
    required this.email,
    required this.emailVerified,
    required this.hasPendingProfile,
  });

  final String uid;
  final String email;
  final bool emailVerified;
  final bool hasPendingProfile;
}

final class AppAccessProfileCompletionRequired extends AppAccessState {
  const AppAccessProfileCompletionRequired({
    required this.uid,
    required this.email,
    required this.provider,
    this.photoUrl,
  });

  final String uid;
  final String email;
  final String provider;
  final String? photoUrl;
}
