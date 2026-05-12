import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../user/data/models/app_user.dart';
import '../../../user/data/repositories/user_repository.dart';
import '../../../user/data/services/firestore_user_service.dart';
import '../../../user/data/services/user_storage_service.dart';
import '../../../user/data/services/firebase_user_storage_service.dart';

class EditProfileController extends ChangeNotifier {
  EditProfileController({
    required this.uid,
    UserRepository? userRepository,
    UserStorageService? storageService,
  })  : _userRepo = userRepository ?? FirestoreUserService(),
        _storageService = storageService ?? FirebaseUserStorageService();

  final String uid;
  final UserRepository _userRepo;
  final UserStorageService _storageService;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  String? _errorMessage;
  AppUser? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppUser? get user => _user;

  Future<void> loadUser() async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _userRepo.getUser(uid);
      if (_user == null) {
        _errorMessage = 'Usuario no encontrado.';
      }
    } catch (e) {
      _errorMessage = 'Error al cargar perfil: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<XFile?> pickImage() async {
    try {
      // Aplicar compresión y límite de tamaño
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );
    } catch (e) {
      _errorMessage = 'No se pudo seleccionar la imagen: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> saveProfile({
    required String name,
    required String lastName,
    required String nickname,
    required String biography,
    XFile? newImage,
  }) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final normalizedNickname = nickname.trim().toLowerCase();

      // Si cambió el nickname, verificar unicidad
      if (normalizedNickname != _user!.nickname.toLowerCase()) {
        final available = await _userRepo.isNicknameAvailable(normalizedNickname);
        if (!available) {
          _errorMessage = 'El alias ya está en uso. Por favor, elige otro.';
          _setLoading(false);
          return false;
        }
      }

      String? photoUrl = _user!.photoUrl;
      if (newImage != null) {
        photoUrl = await _storageService.uploadProfileImage(
          uid: uid,
          image: newImage,
        );
      }

      final updatedUser = _user!.copyWith(
        name: name.trim(),
        lastName: lastName.trim(),
        nickname: normalizedNickname,
        photoUrl: photoUrl,
        biography: biography.trim(),
      );

      await _userRepo.updateUser(updatedUser);
      _user = updatedUser;

      return true;
    } catch (e) {
      _errorMessage = 'Error al guardar el perfil: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
