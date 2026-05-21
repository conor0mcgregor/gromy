import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../../database/participant/models/app_participant.dart';
import '../../../../../database/participant/services/firestore_participant_service.dart';
import '../../../../../database/team/models/app_team.dart';
import '../../../../../database/team/services/firestore_team_service.dart';
import '../../../../events/presentation/controllers/events_controller.dart';
import '../../../../events/presentation/screens/events_screen.dart';
import '../../../../home/presentation/widgets/tournament_card.dart';
import '../../../../inscription/data/models/join_request.dart';
import '../../../../inscription/screen/preinscription_screen.dart';
import '../../../../notifications/domain/entities/notification_type.dart';
import '../../../data/model/app_tournament.dart';
import '../../../data/services/firestore_tournament_service.dart';
import '../history/historical_tournaments_screen.dart';

class InscribedTournamentsTab extends StatefulWidget {
  const InscribedTournamentsTab({super.key, required this.controller});

  final EventsController controller;

  @override
  State<InscribedTournamentsTab> createState() =>
      _InscribedTournamentsTabState();
}

class _InscribedTournamentsTabState extends State<InscribedTournamentsTab> {
  final _participantService = FirestoreParticipantService();
  final _tournamentService = FirestoreTournamentService();
  final _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'gromy-db',
  );

  @override
  Widget build(BuildContext context) {
    final uid = widget.controller.currentUid;

    if (uid == null) {
      return const EventsEmptyState(
        title: 'Inicia sesion',
        message: 'Necesitas iniciar sesion para ver tus inscripciones.',
        icon: Icons.lock_outline_rounded,
      );
    }

    return StreamBuilder<List<_EnrollmentEntry>>(
      stream: _watchEntries(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              _OldInscriptionsButton(
                onTap: () => _openHistoricalInscriptions(context),
              ),
              const Expanded(child: EventsLoadingState()),
            ],
          );
        }

        if (snapshot.hasError) {
          return Column(
            children: [
              _OldInscriptionsButton(
                onTap: () => _openHistoricalInscriptions(context),
              ),
              Expanded(child: EventsErrorState(message: '${snapshot.error}')),
            ],
          );
        }

        final entries = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OldInscriptionsButton(
              onTap: () => _openHistoricalInscriptions(context),
            ),
            Expanded(
              child: entries.isEmpty
                  ? const EventsEmptyState(
                      title: 'Sin inscripciones activas',
                      message:
                          'No tienes torneos en curso ni pendientes. '
                          'Consulta tus torneos finalizados en el historial.',
                      icon: Icons.how_to_reg_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _EnrollmentCard(
                          entry: entry,
                          animationDelay: Duration(milliseconds: 70 * index),
                          onTap: () => _navigateToDetail(context, entry, uid),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _openHistoricalInscriptions(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HistoricalTournamentsScreen(),
      ),
    );
  }

  Stream<List<_EnrollmentEntry>> _watchEntries(String uid) {
    final participantsStream = _participantService.watchEnrolledParticipants(
      uid,
    );
    final requestsStream = _db
        .collectionGroup('joinRequests')
        .where('requestedBy', isEqualTo: uid)
        .where('status', isEqualTo: JoinRequestStatus.pending.name)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['requestId'] = data['requestId'] ?? doc.id;
            return JoinRequest.fromMap(data);
          }).toList(),
        );
    final invitationsStream = _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where(
          'type',
          whereIn: [
            NotificationType.tournamentInvitation,
            NotificationType.invitation,
          ],
        )
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                final invitation = Map<String, dynamic>.from(
                  data['data'] as Map? ?? {},
                );
                invitation['notificationId'] = doc.id;
                return invitation;
              })
              .where((data) {
                final status = data['status']?.toString() ?? 'pending';
                return data['tournamentId'] != null &&
                    (status == 'pending' || status == 'accepted');
              })
              .toList();
        });

    return Rx.combineLatest3(
      participantsStream,
      requestsStream,
      invitationsStream,
      (
        List<AppParticipant> participants,
        List<JoinRequest> requests,
        List<Map<String, dynamic>> invitations,
      ) async {
        final byTournamentId = <String, _EnrollmentSeed>{};

        for (final participant in participants) {
          byTournamentId[participant.tournamentId] = _EnrollmentSeed(
            tournamentId: participant.tournamentId,
            participant: participant,
            state: _entryStateFromParticipant(participant),
          );
        }

        for (final request in requests) {
          byTournamentId.putIfAbsent(
            request.tournamentId,
            () => _EnrollmentSeed(
              tournamentId: request.tournamentId,
              request: request,
              state: _EnrollmentEntryState.pendingApproval,
            ),
          );
        }

        for (final invitation in invitations) {
          final tournamentId = invitation['tournamentId']?.toString();
          if (tournamentId == null || tournamentId.isEmpty) continue;
          byTournamentId.putIfAbsent(
            tournamentId,
            () => _EnrollmentSeed(
              tournamentId: tournamentId,
              invitation: invitation,
              state: _EnrollmentEntryState.invited,
            ),
          );
        }

        final entries = <_EnrollmentEntry>[];
        for (final seed in byTournamentId.values) {
          final tournament = await _tournamentService.getTournament(
            seed.tournamentId,
          );
          if (tournament == null) continue;
          if (tournament.status.isExcludedFromActiveEnrollments) continue;
          entries.add(_EnrollmentEntry(tournament: tournament, seed: seed));
        }
        entries.sort(
          (a, b) =>
              b.tournament.scheduledAt.compareTo(a.tournament.scheduledAt),
        );
        return entries;
      },
    ).asyncMap((future) => future);
  }

  _EnrollmentEntryState _entryStateFromParticipant(AppParticipant participant) {
    return switch (participant.status) {
      ParticipantStatus.approved ||
      ParticipantStatus.active => _EnrollmentEntryState.confirmed,
      ParticipantStatus.pendingReview => _EnrollmentEntryState.pendingReview,
      ParticipantStatus.pending => _EnrollmentEntryState.pendingConfirmation,
      ParticipantStatus.cancelled ||
      ParticipantStatus.rejected => _EnrollmentEntryState.pendingConfirmation,
    };
  }

  Future<void> _navigateToDetail(
    BuildContext context,
    _EnrollmentEntry entry,
    String uid,
  ) async {
    final tournament = entry.tournament;
    AppParticipant? participant = entry.seed.participant;
    AppTeam? enrolledTeam;
    bool canCancel = participant?.entityType == ParticipantEntityType.user;

    try {
      final participants = await _participantService.getParticipants(
        tournament.id,
      );

      participant ??= participants
          .where(
            (p) =>
                p.entityId == uid && p.entityType == ParticipantEntityType.user,
          )
          .firstOrNull;

      if (participant != null) {
        canCancel = participant.entityType == ParticipantEntityType.user;
      } else {
        final teamService = FirestoreTeamService();
        final myTeams = await teamService.watchTeamsByMember(uid).first;
        final myTeamIds = myTeams.map((t) => t.id).toSet();

        participant = participants
            .where(
              (p) =>
                  myTeamIds.contains(p.entityId) &&
                  p.entityType == ParticipantEntityType.team,
            )
            .firstOrNull;

        if (participant != null) {
          enrolledTeam = myTeams.firstWhere(
            (t) => t.id == participant!.entityId,
          );
          canCancel = enrolledTeam.isAdmin(uid);
        }
      }
    } catch (_) {}

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreinscriptionScreen(
          tournament: tournament,
          initialIsEnrolled: participant == null ? null : true,
          initialParticipant: participant,
          initialEnrolledTeam: enrolledTeam,
          initialCanCancelTeam: canCancel,
          invitationNotificationId: entry.seed.invitation?['notificationId']
              ?.toString(),
        ),
      ),
    );
  }
}

class _OldInscriptionsButton extends StatelessWidget {
  const _OldInscriptionsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
          highlightColor: const Color(0xFF6C63FF).withValues(alpha: 0.05),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.14),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Color(0xFFB0A8FF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Mis antiguas inscripciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.45),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _EnrollmentEntryState {
  confirmed,
  pendingApproval,
  pendingConfirmation,
  pendingReview,
  invited,
}

class _EnrollmentSeed {
  const _EnrollmentSeed({
    required this.tournamentId,
    required this.state,
    this.participant,
    this.request,
    this.invitation,
  });

  final String tournamentId;
  final _EnrollmentEntryState state;
  final AppParticipant? participant;
  final JoinRequest? request;
  final Map<String, dynamic>? invitation;
}

class _EnrollmentEntry {
  const _EnrollmentEntry({required this.tournament, required this.seed});

  final AppTournament tournament;
  final _EnrollmentSeed seed;
}

class _EnrollmentCard extends StatelessWidget {
  const _EnrollmentCard({
    required this.entry,
    required this.animationDelay,
    required this.onTap,
  });

  final _EnrollmentEntry entry;
  final Duration animationDelay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(entry.seed.state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: _StatusPill(style: style),
        ),
        TournamentCard(
          tournament: entry.tournament,
          animationDelay: animationDelay,
          onTap: onTap,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  _StatusStyle _statusStyle(_EnrollmentEntryState state) {
    return switch (state) {
      _EnrollmentEntryState.confirmed => const _StatusStyle(
        label: 'Confirmado',
        icon: Icons.verified_rounded,
        color: Color(0xFF22C55E),
      ),
      _EnrollmentEntryState.pendingApproval => const _StatusStyle(
        label: 'Esperando confirmacion',
        icon: Icons.pending_actions_rounded,
        color: Color(0xFFF59E0B),
      ),
      _EnrollmentEntryState.pendingConfirmation => const _StatusStyle(
        label: 'Esperando confirmacion',
        icon: Icons.hourglass_top_rounded,
        color: Color(0xFF38BDF8),
      ),
      _EnrollmentEntryState.pendingReview => const _StatusStyle(
        label: 'En revision',
        icon: Icons.manage_search_rounded,
        color: Color(0xFFA855F7),
      ),
      _EnrollmentEntryState.invited => const _StatusStyle(
        label: 'Invitado',
        icon: Icons.mail_rounded,
        color: Color(0xFF8B5CF6),
      ),
    };
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.style});

  final _StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        color: style.color.withValues(alpha: 0.12),
        border: Border.all(color: style.color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 13, color: style.color),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: TextStyle(
              color: style.color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
