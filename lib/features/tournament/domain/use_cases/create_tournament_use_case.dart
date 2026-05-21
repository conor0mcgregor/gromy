import 'package:image_picker/image_picker.dart';

import '../../../../core/models/registration_form.dart';
import '../../data/model/app_tournament.dart';
import '../../data/model/enums_tournament.dart';
import '../../data/repositories/tournament_repository.dart';

class CreateTournamentUseCase {
  const CreateTournamentUseCase(this._repository);

  final TournamentRepository _repository;

  Future<AppTournament> call({
    required String uid,
    required String? email,
    required String? displayName,
    required String name,
    required String description,
    required String allInformation,
    required DateTime scheduledAt,
    required int maxParticipants,
    required String location,
    required TournamentSport sport,
    required TournamentAccessType accessType,
    required int maxMatchDurationMinutes,
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
    RegistrationFormSchema registrationForm = const RegistrationFormSchema(),
  }) async {
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
      throw ArgumentError('Completa los campos obligatorios del torneo.');
    }

    if (maxParticipants < 2) {
      throw ArgumentError('El máximo de participantes debe ser al menos 2.');
    }

    if (membersPerTeam != null && membersPerTeam < 2) {
      throw ArgumentError(
        'El número de miembros por equipo debe ser al menos 2.',
      );
    }

    if (normalizedDate.isBefore(minDate)) {
      throw ArgumentError('Selecciona una fecha válida para el torneo.');
    }

    final formErrors = RegistrationFormValidator.validateSchema(
      registrationForm,
    );
    if (formErrors.isNotEmpty) {
      throw ArgumentError(formErrors.first);
    }

    // Solo el creador es administrador real. Más admins vía invitación.
    final adminIds = <String>[uid];

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
      latitude: latitude,
      longitude: longitude,
      sport: sport,
      accessType: accessType,
      maxMatchDurationMinutes: maxMatchDurationMinutes,
      status: TournamentStatus.registration,
      organizerUid: uid,
      organizerEmail: email?.trim().isEmpty == true ? null : email?.trim(),
      organizerDisplayName: displayName?.trim().isEmpty == true
          ? null
          : displayName?.trim(),
      adminIds: adminIds,
      participantCount: 0,
      registrationDeadline: registrationDeadline,
      bracketPublishDate: bracketPublishDate,
      contactEmail: contactEmail?.trim(),
      contactPhone: contactPhone?.trim(),
      contactLinks: contactLinks,
      categories: categories,
      registrationForm: registrationForm.copyWith(version: 1),
      createdAt: now,
      updatedAt: now,
    );

    if (coverImage != null) {
      return await _repository.createTournamentWithCover(
        tournament: tournament,
        coverImage: coverImage,
      );
    } else {
      return await _repository.createTournament(tournament);
    }
  }
}
