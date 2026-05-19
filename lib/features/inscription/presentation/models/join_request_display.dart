import '../../../../database/team/models/app_team.dart';
import '../../../user/data/models/app_user.dart';
import '../../data/models/join_request.dart';

class JoinRequestDisplay {
  const JoinRequestDisplay({
    required this.request,
    required this.title,
    this.subtitle,
    this.avatarUrl,
    this.user,
    this.team,
  });

  final JoinRequest request;
  final String title;
  final String? subtitle;
  final String? avatarUrl;
  final AppUser? user;
  final AppTeam? team;
}
