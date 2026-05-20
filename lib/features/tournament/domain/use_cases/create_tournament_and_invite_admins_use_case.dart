import 'package:image_picker/image_picker.dart';

import '../../../../core/models/registration_form.dart';
import '../../../notifications/domain/use_cases/admin_invitation_use_cases.dart';
import '../../data/model/app_tournament.dart';
import '../../data/model/enums_tournament.dart';
import '../../data/repositories/tournament_repository.dart';
import 'create_tournament_use_case.dart';

/// Orquesta la creación del torneo y el envío de invitaciones de administrador.
///
/// El creador queda en [AppTournament.adminIds]. Los demás UIDs se invitan
/// mediante [SendAdminInvitationUseCase] (misma Cloud Function que gestión).
/// Si falla algún envío tras otros correctos, se cancelan las ya creadas.
class CreateTournamentAndInviteAdminsUseCase {
  const CreateTournamentAndInviteAdminsUseCase({
    required TournamentRepository tournamentRepository,
    required SendAdminInvitationUseCase sendAdminInvitation,
    required CancelAdminInvitationUseCase cancelAdminInvitation,
  }) : _tournamentRepository = tournamentRepository,
       _sendAdminInvitation = sendAdminInvitation,
       _cancelAdminInvitation = cancelAdminInvitation;

  final TournamentRepository _tournamentRepository;
  final SendAdminInvitationUseCase _sendAdminInvitation;
  final CancelAdminInvitationUseCase _cancelAdminInvitation;

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
    RegistrationFormSchema registrationForm = const RegistrationFormSchema(),
  }) async {
    final invitees = invitedAdminUserIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e != uid)
        .toSet()
        .toList(growable: false);

    final createUseCase = CreateTournamentUseCase(_tournamentRepository);
    final tournament = await createUseCase(
      uid: uid,
      email: email,
      displayName: displayName,
      name: name,
      description: description,
      allInformation: allInformation,
      scheduledAt: scheduledAt,
      maxParticipants: maxParticipants,
      location: location,
      sport: sport,
      accessType: accessType,
      coverImage: coverImage,
      membersPerTeam: membersPerTeam,
      latitude: latitude,
      longitude: longitude,
      registrationDeadline: registrationDeadline,
      bracketPublishDate: bracketPublishDate,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      contactLinks: contactLinks,
      categories: categories,
      registrationForm: registrationForm,
    );

    final sentNotificationIds = <String>[];
    try {
      for (final invitedUserId in invitees) {
        final notificationId = await _sendAdminInvitation(
          tournamentId: tournament.id,
          invitedUserId: invitedUserId,
        );
        sentNotificationIds.add(notificationId);
      }
    } catch (e) {
      for (final notificationId in sentNotificationIds) {
        try {
          await _cancelAdminInvitation(notificationId: notificationId);
        } catch (_) {}
      }
      rethrow;
    }

    return tournament;
  }
}
