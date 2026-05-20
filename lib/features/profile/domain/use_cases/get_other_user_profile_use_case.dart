import '../../../user/data/models/public_user_profile.dart';
import '../../../user/data/repositories/user_repository.dart';
import '../../../user/data/services/firestore_user_service.dart';

class GetOtherUserProfileUseCase {
  GetOtherUserProfileUseCase({UserRepository? repository})
    : _repository = repository ?? FirestoreUserService();

  final UserRepository _repository;

  Future<PublicUserProfile?> execute(String targetUid) {
    return _repository.getOtherUserPublicProfile(targetUid);
  }
}
