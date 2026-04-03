import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/model/app_tournament.dart';
import '../../data/model/enums_tournament.dart';
import '../../data/repositories/tournament_repository.dart';
import '../../data/services/firestore_tournament_service.dart';

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
  String? _errorMessage;
  AppTournament? _lastCreatedTournament;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  AppTournament? get lastCreatedTournament => _lastCreatedTournament;

  Future<bool> createTournament({
    required String name,
    required String description,
    required DateTime scheduledAt,
    required int maxParticipants,
    required String location,
    required TournamentSport sport,
    required TournamentAccessType accessType,
    String? additionalInfo,
  }) async {
    _setSubmitting(true);
    _clearError();

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _errorMessage = 'Debes iniciar sesion para crear un torneo.';
        return false;
      }

      final normalizedName = name.trim();
      final normalizedDescription = description.trim();
      final normalizedLocation = location.trim();
      final normalizedInfo = _normalizeOptional(additionalInfo);
      final normalizedDate = DateTime(
        scheduledAt.year,
        scheduledAt.month,
        scheduledAt.day,
      );
      final today = DateTime.now();
      final minDate = DateTime(today.year, today.month, today.day);

      if (normalizedName.isEmpty ||
          normalizedDescription.isEmpty ||
          normalizedLocation.isEmpty) {
        _errorMessage = 'Completa los campos obligatorios del torneo.';
        return false;
      }

      if (maxParticipants < 2) {
        _errorMessage = 'El maximo de participantes debe ser al menos 2.';
        return false;
      }

      if (normalizedDate.isBefore(minDate)) {
        _errorMessage = 'Selecciona una fecha valida para el torneo.';
        return false;
      }

      final now = DateTime.now();
      final tournament = AppTournament(
        id: '',
        name: normalizedName,
        description: normalizedDescription,
        scheduledAt: normalizedDate,
        maxParticipants: maxParticipants,
        location: normalizedLocation,
        sport: sport,
        accessType: accessType,
        organizerUid: currentUser.uid,
        organizerEmail: _normalizeOptional(currentUser.email),
        organizerDisplayName: _normalizeOptional(currentUser.displayName),
        adminIds: [currentUser.uid],
        participantCount: 0,
        additionalInfo: normalizedInfo,
        createdAt: now,
        updatedAt: now,
      );

      _lastCreatedTournament = await _tournamentRepository.createTournament(
        tournament,
      );
      return true;
    } on FirebaseException catch (error) {
      _errorMessage = _firebaseErrorMessage(error.code);
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo crear el torneo. Intentalo de nuevo.';
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  String _firebaseErrorMessage(String code) {
    return switch (code) {
      'permission-denied' =>
        'Firestore rechazo la operacion. Revisa las reglas de seguridad.',
      'unavailable' =>
        'Firestore no esta disponible ahora mismo. Intentalo de nuevo.',
      'failed-precondition' =>
        'Firestore no esta listo todavia para guardar torneos.',
      'deadline-exceeded' =>
        'La operacion tardo demasiado. Intentalo otra vez.',
      _ => 'No se pudo guardar el torneo en Firebase.',
    };
  }

  String? _normalizeOptional(String? value) {
    if (value == null) {
      return null;
    }

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
