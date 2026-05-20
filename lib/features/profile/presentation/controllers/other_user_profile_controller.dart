import 'package:flutter/material.dart';

import '../../../user/data/models/public_user_profile.dart';
import '../../domain/use_cases/get_other_user_profile_use_case.dart';

class OtherUserProfileController extends ChangeNotifier {
  OtherUserProfileController({
    required this.targetUid,
    GetOtherUserProfileUseCase? useCase,
  }) : _useCase = useCase ?? GetOtherUserProfileUseCase();

  final String targetUid;
  final GetOtherUserProfileUseCase _useCase;

  PublicUserProfile? profile;
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      profile = await _useCase.execute(targetUid);
      if (profile == null) {
        errorMessage = 'Este perfil es privado o no esta disponible.';
      }
    } catch (_) {
      errorMessage = 'No se pudo cargar el perfil.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
