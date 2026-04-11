import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/model/app_tournament.dart';
import '../../data/model/enums_tournament.dart';
import '../../data/repositories/tournament_repository.dart';
import '../../data/services/firestore_tournament_service.dart';

/// Controlador de la pantalla de creación de torneos.
///
/// SRP: gestiona exclusivamente el estado de la UI y la coordinación con el
/// repositorio. No contiene lógica de Storage ni de Firestore directamente.
/// DIP: depende de [TournamentRepository], no de implementaciones concretas.
class CreateTournamentController extends ChangeNotifier {
  CreateTournamentController({
    TournamentRepository? tournamentRepository,
    FirebaseAuth? auth,
  })  : _tournamentRepositoryOverride = tournamentRepository,
        _authOverride = auth;

  TournamentRepository? _tournamentRepositoryOverride;
  FirebaseAuth? _authOverride;

  TournamentRepository get _tournamentRepository =>
      _tournamentRepositoryOverride ??= FirestoreTournamentService();

  FirebaseAuth get _auth => _authOverride ??= FirebaseAuth.instance;

  bool _isSubmitting = false;
  String? _errorMessage;
  AppTournament? _lastCreatedTournament;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  AppTournament? get lastCreatedTournament => _lastCreatedTournament;

  /// Crea un torneo, con o sin imagen de portada.
  ///
  /// Si [coverImage] no es null, se sube la imagen a Storage y se guarda la
  /// URL en el modelo antes de persistir en Firestore.
  Future<bool> createTournament({
    required String name,
    required String description,
    required String allInformation,
    required DateTime scheduledAt,
    required int maxParticipants,
    required String location,
    required TournamentSport sport,
    required TournamentAccessType accessType,
    List<String> extraAdminIds = const [],
    XFile? coverImage,
    int? membersPerTeam,
  }) async {
    _setSubmitting(true);
    _clearError();

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _errorMessage = 'Debes iniciar sesión para crear un torneo.';
        return false;
      }

      final normalizedName = name.trim();
      final normalizedDescription = description.trim();
      final normalizedLocation = location.trim();
      final normalizedAllInfo = allInformation.trim();
      final normalizedDate = DateTime(
        scheduledAt.year,
        scheduledAt.month,
        scheduledAt.day,
      );
      final today = DateTime.now();
      final minDate = DateTime(today.year, today.month, today.day);

      if (normalizedName.isEmpty ||
          normalizedDescription.isEmpty ||
          normalizedAllInfo.isEmpty ||
          normalizedLocation.isEmpty) {
        _errorMessage = 'Completa los campos obligatorios del torneo.';
        return false;
      }

      if (maxParticipants < 2) {
        _errorMessage = 'El máximo de participantes debe ser al menos 2.';
        return false;
      }

      if (membersPerTeam != null && membersPerTeam < 2) {
        _errorMessage = 'El número de miembros por equipo debe ser al menos 2.';
        return false;
      }

      if (normalizedDate.isBefore(minDate)) {
        _errorMessage = 'Selecciona una fecha válida para el torneo.';
        return false;
      }

      // El creador siempre es admin; se combinan los extras sin duplicados.
      final allAdminIds = <String>{
        currentUser.uid,
        ...extraAdminIds,
      }.toList();

      final now = DateTime.now();
      final tournament = AppTournament(
        id: '',
        name: normalizedName,
        description: normalizedDescription,
        allInformation: normalizedAllInfo,
        scheduledAt: normalizedDate,
        maxParticipants: maxParticipants,
        membersPerTeam: membersPerTeam,
        location: normalizedLocation,
        sport: sport,
        accessType: accessType,
        organizerUid: currentUser.uid,
        organizerEmail: _normalizeOptional(currentUser.email),
        organizerDisplayName: _normalizeOptional(currentUser.displayName),
        adminIds: allAdminIds,
        participantCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      if (coverImage != null) {
        _lastCreatedTournament =
            await _tournamentRepository.createTournamentWithCover(
          tournament: tournament,
          coverImage: coverImage,
        );
      } else {
        _lastCreatedTournament =
            await _tournamentRepository.createTournament(tournament);
      }

      return true;
    } on FirebaseException catch (error) {
      _errorMessage = _firebaseErrorMessage(error.code);
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo crear el torneo. Inténtalo de nuevo.';
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

  String? _normalizeOptional(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
