import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/model/app_tournament.dart';
import '../../data/model/enums_tournament.dart';
import '../../../notifications/data/repository/admin_invitation_repository_impl.dart';
import '../../../notifications/domain/use_cases/admin_invitation_use_cases.dart';
import '../../data/repositories/tournament_repository.dart';
import '../../data/services/firestore_tournament_service.dart';
import '../../data/services/tournament_storage_service.dart';
import '../../domain/use_cases/create_tournament_and_invite_admins_use_case.dart';
import '../../../user/data/services/firestore_user_service.dart';

/// Controlador de la pantalla de creación de torneos.
///
/// SRP: gestiona exclusivamente el estado de la UI y la coordinación con el
/// repositorio. No contiene lógica de Storage ni de Firestore directamente.
/// DIP: depende de [TournamentRepository], no de implementaciones concretas.
class CreateTournamentController extends ChangeNotifier {
  CreateTournamentController({
    TournamentRepository? tournamentRepository,
    FirebaseAuth? auth,
  }) : _tournamentRepositoryOverride = tournamentRepository,
       _authOverride = auth;

  TournamentRepository? _tournamentRepositoryOverride;
  FirebaseAuth? _authOverride;

  TournamentRepository get _tournamentRepository =>
      _tournamentRepositoryOverride ??= FirestoreTournamentService();

  FirebaseAuth get _auth => _authOverride ??= FirebaseAuth.instance;

  bool _isSubmitting = false;
  bool _isCheckingDuplicate = false;
  String? _errorMessage;
  String? _duplicateCheckErrorMessage;
  AppTournament? _lastCreatedTournament;
  AppTournament? _duplicateTournament;
  int _duplicateCheckRequestId = 0;

  bool get isSubmitting => _isSubmitting;
  bool get isCheckingDuplicate => _isCheckingDuplicate;
  String? get errorMessage => _errorMessage;
  String? get duplicateCheckErrorMessage => _duplicateCheckErrorMessage;
  AppTournament? get lastCreatedTournament => _lastCreatedTournament;

  /// Torneo existente que genera conflicto de duplicado.
  /// Es `null` cuando no hay conflicto o tras llamar a [clearDuplicate].
  AppTournament? get duplicateTournament => _duplicateTournament;

  /// Limpia el estado de duplicado (p.ej. al cerrar el aviso).
  void clearDuplicate() {
    _duplicateTournament = null;
    _duplicateCheckErrorMessage = null;
    notifyListeners();
  }

  /// Busca posibles duplicados para mostrar un aviso no bloqueante en el flujo.
  Future<void> checkDuplicateTournament({
    required DateTime scheduledAt,
    required String location,
  }) async {
    final normalizedLocation = location.trim();
    if (normalizedLocation.isEmpty) {
      clearDuplicate();
      return;
    }

    final requestId = ++_duplicateCheckRequestId;
    _isCheckingDuplicate = true;
    _duplicateCheckErrorMessage = null;
    notifyListeners();

    try {
      final duplicate = await _tournamentRepository.findDuplicateTournament(
        scheduledAt: scheduledAt,
        location: normalizedLocation,
      );
      if (requestId != _duplicateCheckRequestId) return;
      _duplicateTournament = duplicate;
    } catch (_) {
      if (requestId != _duplicateCheckRequestId) return;
      _duplicateTournament = null;
      _duplicateCheckErrorMessage =
          'No se pudo verificar si ya existe un torneo similar. Puedes continuar.';
    } finally {
      if (requestId == _duplicateCheckRequestId) {
        _isCheckingDuplicate = false;
        notifyListeners();
      }
    }
  }

  Future<bool> createTournament({
    required String name,
    required String description,
    required String allInformation,
    required DateTime scheduledAt,
    required int maxParticipants,
    required String location,
    required TournamentSport sport,
    required TournamentAccessType accessType,
    List<String> invitedAdminUserIds = const [],
    XFile? coverImage,
    int? membersPerTeam,
    double? latitude,
    double? longitude,
    DateTime? registrationDeadline,
    DateTime? bracketPublishDate,
    String? contactEmail,
    String? contactPhone,
    List<String> contactLinks = const [],
    List<String> categories = const [],
  }) async {
    _setSubmitting(true);
    _clearError();

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _errorMessage = 'Debes iniciar sesión para crear un torneo.';
        return false;
      }

      final coverPath = coverImage?.path;
      developer.log(
        'Create tournament submit | uid=${currentUser.uid} '
        'email=${currentUser.email ?? "(null)"} '
        'isAnonymous=${currentUser.isAnonymous} '
        'hasCover=${coverImage != null} coverPath=${coverPath?.isEmpty == true ? "(path vacío)" : coverPath ?? "(null)"} '
        'coverMime=${coverImage?.mimeType ?? "(null)"}',
        name: 'CreateTournamentController',
      );

      // Obtenemos el nombre a mostrar del usuario. Fallback a Firestore si no está en Auth.
      String? displayName = currentUser.displayName;
      if (displayName == null || displayName.trim().isEmpty) {
        try {
          final userService = FirestoreUserService();
          final appUser = await userService.getUser(currentUser.uid);
          if (appUser != null) {
            final fullName = '${appUser.name} ${appUser.lastName}'.trim();
            displayName = fullName.isNotEmpty ? fullName : appUser.nickname;
          }
        } catch (e) {
          developer.log('Error fetching user display name from Firestore: $e');
        }
      }

      final invitationRepo = CloudFunctionAdminInvitationRepository();
      final useCase = CreateTournamentAndInviteAdminsUseCase(
        tournamentRepository: _tournamentRepository,
        sendAdminInvitation: SendAdminInvitationUseCase(invitationRepo),
        cancelAdminInvitation: CancelAdminInvitationUseCase(invitationRepo),
      );

      _lastCreatedTournament = await useCase(
        uid: currentUser.uid,
        email: currentUser.email,
        displayName: displayName,
        name: name,
        description: description,
        allInformation: allInformation,
        scheduledAt: scheduledAt,
        maxParticipants: maxParticipants,
        membersPerTeam: membersPerTeam,
        location: location,
        latitude: latitude,
        longitude: longitude,
        sport: sport,
        accessType: accessType,
        invitedAdminUserIds: invitedAdminUserIds,
        coverImage: coverImage,
        registrationDeadline: registrationDeadline,
        bracketPublishDate: bracketPublishDate,
        contactEmail: contactEmail,
        contactPhone: contactPhone,
        contactLinks: contactLinks,
        categories: categories,
      );

      return true;
    } on ArgumentError catch (error) {
      _errorMessage = error.message;
      return false;
    } on StorageUploadException catch (e, stackTrace) {
      developer.log(
        'StorageUploadException creating tournament | message=${e.message}',
        name: 'CreateTournamentController',
        error: e.cause ?? e,
        stackTrace: stackTrace,
      );
      _errorMessage = e.message;
      return false;
    } on FirebaseException catch (error, stackTrace) {
      developer.log(
        'FirebaseException creating tournament | code=${error.code} '
        'message=${error.message ?? "(null)"} plugin=${error.plugin}',
        name: 'CreateTournamentController',
        error: error,
        stackTrace: stackTrace,
      );
      _errorMessage = _firebaseErrorMessage(error.code);
      return false;
    } catch (e, stackTrace) {
      developer.log(
        'Unexpected error creating tournament',
        name: 'CreateTournamentController',
        error: e,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Error inesperado: $e';
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  String _firebaseErrorMessage(String code) {
    return switch (code) {
      'permission-denied' =>
        'Firestore rechazó la operación. Revisa las reglas de seguridad.',
      'unavailable' =>
        'Firestore no está disponible ahora mismo. Inténtalo de nuevo.',
      'failed-precondition' =>
        'Firestore no está listo todavía para guardar torneos.',
      'deadline-exceeded' =>
        'La operación tardó demasiado. Inténtalo otra vez.',
      _ => 'No se pudo guardar el torneo en Firebase.',
    };
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
