import 'package:gromy/features/auth/data/models/auth_result.dart';
import 'package:gromy/features/auth/data/repositories/auth_repository.dart';
import 'package:gromy/features/user/data/models/app_user.dart';
import 'package:gromy/features/user/data/repositories/user_repository.dart';

typedef EmailAuthHandler =
    Future<AuthResult> Function(String email, String password);
typedef SocialAuthHandler = Future<AuthResult> Function();
typedef SignOutHandler = Future<void> Function();
typedef NicknameAvailabilityHandler = Future<bool> Function(String nickname);
typedef CreateUserHandler = Future<void> Function(AppUser user);
typedef GetUserHandler = Future<AppUser?> Function(String uid);
typedef UserExistsHandler = Future<bool> Function(String uid);

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.onSignInWithEmail,
    this.onRegisterWithEmail,
    this.onSignInWithGoogle,
    this.onSignInWithApple,
    this.onSignOut,
  });

  final EmailAuthHandler? onSignInWithEmail;
  final EmailAuthHandler? onRegisterWithEmail;
  final SocialAuthHandler? onSignInWithGoogle;
  final SocialAuthHandler? onSignInWithApple;
  final SignOutHandler? onSignOut;

  int signInWithEmailCalls = 0;
  int registerWithEmailCalls = 0;
  int signInWithGoogleCalls = 0;
  int signInWithAppleCalls = 0;
  int signOutCalls = 0;

  String? lastEmail;
  String? lastPassword;

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    signInWithEmailCalls++;
    lastEmail = email;
    lastPassword = password;
    return onSignInWithEmail?.call(email, password) ?? AuthSuccess();
  }

  @override
  Future<AuthResult> registerWithEmail(String email, String password) async {
    registerWithEmailCalls++;
    lastEmail = email;
    lastPassword = password;
    return onRegisterWithEmail?.call(email, password) ?? AuthSuccess();
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    signInWithGoogleCalls++;
    return onSignInWithGoogle?.call() ?? AuthSuccess();
  }

  @override
  Future<AuthResult> signInWithApple() async {
    signInWithAppleCalls++;
    return onSignInWithApple?.call() ?? AuthSuccess();
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    await (onSignOut?.call() ?? Future<void>.value());
  }
}

class FakeUserRepository implements UserRepository {
  FakeUserRepository({
    this.onCreateUser,
    this.onGetUser,
    this.onUserExists,
    this.onIsNicknameAvailable,
  });

  final CreateUserHandler? onCreateUser;
  final GetUserHandler? onGetUser;
  final UserExistsHandler? onUserExists;
  final NicknameAvailabilityHandler? onIsNicknameAvailable;

  int createUserCalls = 0;
  int getUserCalls = 0;
  int userExistsCalls = 0;
  int isNicknameAvailableCalls = 0;

  AppUser? lastCreatedUser;
  String? lastNicknameChecked;
  String? lastUidRead;
  String? lastUidExists;

  @override
  Future<void> createUser(AppUser user) async {
    createUserCalls++;
    lastCreatedUser = user;
    await (onCreateUser?.call(user) ?? Future<void>.value());
  }

  @override
  Future<AppUser?> getUser(String uid) async {
    getUserCalls++;
    lastUidRead = uid;
    return onGetUser?.call(uid);
  }

  @override
  Future<bool> userExists(String uid) async {
    userExistsCalls++;
    lastUidExists = uid;
    return onUserExists?.call(uid) ?? false;
  }

  @override
  Future<bool> isNicknameAvailable(String nickname) async {
    isNicknameAvailableCalls++;
    lastNicknameChecked = nickname;
    return onIsNicknameAvailable?.call(nickname) ?? true;
  }
}
