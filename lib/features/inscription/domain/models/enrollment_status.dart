import '../../../../database/participant/models/app_participant.dart';
import '../../../../database/team/models/app_team.dart';

class EnrollmentStatus {
  final bool isEnrolled;
  final AppParticipant? participant;
  final AppTeam? enrolledTeam;
  final bool canCancel;

  EnrollmentStatus({
    required this.isEnrolled,
    this.participant,
    this.enrolledTeam,
    this.canCancel = false,
  });

  factory EnrollmentStatus.notEnrolled() => EnrollmentStatus(isEnrolled: false);
}
