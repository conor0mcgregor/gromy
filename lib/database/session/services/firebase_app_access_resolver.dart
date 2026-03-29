import 'package:firebase_auth/firebase_auth.dart';

import '../../../features/user/data/repositories/user_repository.dart';
import '../../../features/user/data/services/firestore_user_service.dart';
import '../../registration/repositories/pending_email_registration_store.dart';
import '../../registration/services/shared_preferences_pending_email_registration_store.dart';
import '../models/app_access_state.dart';
import '../repositories/app_access_resolver.dart';

class FirebaseAppAccessResolver implements AppAccessResolver {
  FirebaseAppAccessResolver({
    FirebaseAuth? auth,
    UserRepository? userRepository,
    PendingEmailRegistrationStore? pendingRegistrationStore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _userRepository = userRepository ?? FirestoreUserService(),
        _pendingRegistrationStore = pendingRegistrationStore ??
            SharedPreferencesPendingEmailRegistrationStore();

  final FirebaseAuth _auth;
  final UserRepository _userRepository;
  final PendingEmailRegistrationStore _pendingRegistrationStore;

  @override
  Stream<AppAccessState> watch() async* {
    yield await resolve();
    yield* _auth.userChanges().asyncMap((_) => resolve());
  }

  @override
  Future<AppAccessState> resolve() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const AppAccessUnauthenticated();
    }

    final isEmailPasswordUser = _hasProvider(currentUser, 'password');
    final pendingRegistration = await _pendingRegistrationStore.getByUid(
      currentUser.uid,
    );

    if (isEmailPasswordUser && !currentUser.emailVerified) {
      return AppAccessPendingEmailRegistration(
        uid: currentUser.uid,
        email: currentUser.email ?? pendingRegistration?.email ?? '',
        emailVerified: false,
        hasPendingProfile: pendingRegistration != null,
      );
    }

    final userExists = await _safeUserExists(currentUser.uid);
    if (userExists) {
      return const AppAccessAuthenticated();
    }

    if (isEmailPasswordUser) {
      return AppAccessPendingEmailRegistration(
        uid: currentUser.uid,
        email: currentUser.email ?? pendingRegistration?.email ?? '',
        emailVerified: currentUser.emailVerified,
        hasPendingProfile: pendingRegistration != null,
      );
    }

    return AppAccessProfileCompletionRequired(
      uid: currentUser.uid,
      email: currentUser.email ?? '',
      provider: _resolveProvider(currentUser),
      photoUrl: currentUser.photoURL,
    );
  }

  Future<bool> _safeUserExists(String uid) async {
    try {
      return await _userRepository.userExists(uid);
    } catch (_) {
      return false;
    }
  }

  bool _hasProvider(User user, String providerId) {
    return user.providerData.any((provider) => provider.providerId == providerId);
  }

  String _resolveProvider(User user) {
    if (_hasProvider(user, 'google.com')) {
      return 'google';
    }
    if (_hasProvider(user, 'apple.com')) {
      return 'apple';
    }
    return 'email';
  }
}
