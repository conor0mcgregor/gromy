import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../core/models/registration_form.dart';
import '../../../../database/participant/models/app_participant.dart';
import '../../../../database/participant/repositories/participant_repository.dart';
import '../../../../database/participant/services/firestore_participant_service.dart';
import '../helpers/tournament_collection_resolver.dart';
import '../model/app_tournament.dart';
import '../model/enums_tournament.dart';
import '../repositories/tournament_repository.dart';
import 'firebase_tournament_storage_service.dart';
import 'tournament_storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FirestoreTournamentService  ·  Capa de datos
//
//  Implementa [TournamentRepository] usando Firestore como backend.
//
//  SRP: delega la gestión de Storage en [TournamentStorageService] y la de
//       participantes en [ParticipantRepository].
//  DIP: depende de abstracciones, no de implementaciones concretas.
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreTournamentService implements TournamentRepository {
  FirestoreTournamentService({
    FirebaseFirestore? firestore,
    TournamentStorageService? storageService,
    ParticipantRepository? participantRepository,
    TournamentCollectionResolver? tournamentResolver,
  }) : _db =
           firestore ??
           FirebaseFirestore.instanceFor(
             app: Firebase.app(),
             databaseId: 'gromy-db',
           ),
       _storageService = storageService ?? FirebaseTournamentStorageService(),
       _participantRepo =
           participantRepository ?? FirestoreParticipantService(),
       _tournamentResolver =
           tournamentResolver ??
           TournamentCollectionResolver(firestore: firestore);

  final FirebaseFirestore _db;
  final TournamentStorageService _storageService;
  final ParticipantRepository _participantRepo;
  final TournamentCollectionResolver _tournamentResolver;

  CollectionReference<Map<String, dynamic>> get _tournaments =>
      _db.collection('tournaments');

  CollectionReference<Map<String, dynamic>> get _privateTournaments =>
      _db.collection('private_tournaments');

  Future<DocumentReference<Map<String, dynamic>>> _getTournamentDoc(
    String id,
  ) => _tournamentResolver.referenceFor(id);

  // ── Creación ───────────────────────────────────────────────────────────────

  @override
  Future<AppTournament> createTournament(AppTournament tournament) async {
    final collection =
        tournament.accessType == TournamentAccessType.privateInviteOnly
        ? _privateTournaments
        : _tournaments;
    final docRef = tournament.id.isEmpty
        ? collection.doc()
        : collection.doc(tournament.id);
    final tournamentToSave = tournament.copyWith(
      id: docRef.id,
      status: TournamentStatus.registration,
    );

    await docRef
        .set(tournamentToSave.toMap())
        .timeout(const Duration(seconds: 10));

    return tournamentToSave;
  }

  @override
  Future<AppTournament> createTournamentWithCover({
    required AppTournament tournament,
    required XFile coverImage,
  }) async {
    // 1. Reservar un ID en Firestore para usarlo en la ruta de Storage.
    final collection =
        tournament.accessType == TournamentAccessType.privateInviteOnly
        ? _privateTournaments
        : _tournaments;
    final docRef = tournament.id.isEmpty
        ? collection.doc()
        : collection.doc(tournament.id);

    // 2. Subir imagen y obtener URL de descarga.
    final downloadUrl = await _storageService.uploadCoverImage(
      tournamentId: docRef.id,
      ownerUid: tournament.organizerUid,
      image: coverImage,
    );

    // 3. Asignar la URL al torneo y persistir.
    final tournamentToSave = tournament.copyWith(
      id: docRef.id,
      portadaUrl: downloadUrl,
      status: TournamentStatus.registration,
    );

    await docRef
        .set(tournamentToSave.toMap())
        .timeout(const Duration(seconds: 10));

    return tournamentToSave;
  }

  // ── Lectura ────────────────────────────────────────────────────────────────

  /// Stream de torneos públicos y activos en el feed principal.
  ///
  /// Filtra directamente en Firestore por los estados del feed activo
  /// (registration e in_progress), excluyendo completed, draft y cancelled.
  Stream<List<AppTournament>> _watchAllPublicTournaments() {
    // Filtramos por los dos estados que deben aparecer en el feed
    return _tournaments
        .where('status', whereIn: ['registration', 'in_progress'])
        .snapshots()
        .map((snapshot) {
          final list = <AppTournament>[];
          for (final doc in snapshot.docs) {
            try {
              final tournament = AppTournament.fromMap(doc.data());
              list.add(tournament);
            } catch (e) {
              // ignore: avoid_print
              print('Error mapeando torneo: $e');
            }
          }
          return list;
        });
  }

  @override
  Stream<List<AppTournament>> watchTournaments() {
    return _watchAllPublicTournaments().map((all) {
      final pastThreshold = DateTime.now().subtract(const Duration(days: 1));
      // Excluimos torneos cuya fecha ya pasó (salvo in_progress que puede
      // seguir activo aunque la fecha haya pasado)
      final active = all.where((t) {
        if (t.status == TournamentStatus.in_progress) return true;
        return !t.scheduledAt.isBefore(pastThreshold);
      }).toList();
      active.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      return active;
    });
  }

  Stream<List<AppTournament>> _watchPrivateTournaments() {
    return _privateTournaments.snapshots().map((snapshot) {
      final list = <AppTournament>[];
      for (final doc in snapshot.docs) {
        try {
          list.add(AppTournament.fromMap(doc.data()));
        } catch (e) {
          // ignore: avoid_print
          print('Error mapeando torneo privado: $e');
        }
      }
      return list;
    });
  }

  @override
  Stream<List<AppTournament>> watchMyTournaments(String uid) {
    return Rx.combineLatest2(
      _watchAllPublicTournaments(),
      _watchPrivateTournaments(),
      (List<AppTournament> public, List<AppTournament> private) {
        final all = [...public, ...private];
        return all.where((t) => t.organizerUid == uid).toList()
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      },
    );
  }

  @override
  Stream<List<AppTournament>> watchTournamentsAdmin(String uid) {
    return Rx.combineLatest2(
      _watchAllPublicTournaments(),
      _watchPrivateTournaments(),
      (List<AppTournament> public, List<AppTournament> private) {
        final all = [...public, ...private];
        return all.where((t) => t.adminIds.contains(uid)).toList()
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      },
    );
  }

  /// Stream de torneos completados/cancelados donde el usuario es creador o admin.
  ///
  /// Consulta Firestore filtrando por los estados que no aparecen en el feed
  /// principal: completed y cancelled.
  Stream<List<AppTournament>> _watchCompletedOrCancelledPublic() {
    return _tournaments
        .where('status', whereIn: ['completed', 'cancelled'])
        .snapshots()
        .map((snapshot) {
          final list = <AppTournament>[];
          for (final doc in snapshot.docs) {
            try {
              list.add(AppTournament.fromMap(doc.data()));
            } catch (e) {
              // ignore: avoid_print
              print('Error mapeando torneo completado: $e');
            }
          }
          return list;
        });
  }

  @override
  Stream<List<AppTournament>> watchMyCompletedTournaments(String uid) {
    return Rx.combineLatest2(
      _watchCompletedOrCancelledPublic(),
      _watchPrivateTournaments(),
      (List<AppTournament> completed, List<AppTournament> private) {
        // Incluir privados con estado completado/cancelado
        final completedPrivate = private.where(
          (t) =>
              t.status == TournamentStatus.completed ||
              t.status == TournamentStatus.cancelled,
        );
        final all = [...completed, ...completedPrivate];
        // Filtrar solo los que el uid creó o administra
        return all
            .where(
              (t) => t.organizerUid == uid || t.adminIds.contains(uid),
            )
            .fold<List<AppTournament>>(
              [],
              (acc, t) {
                if (!acc.any((e) => e.id == t.id)) acc.add(t);
                return acc;
              },
            )
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      },
    );
  }

  // ── Participantes (delegación en ParticipantRepository) ───────────────────

  @override
  Future<AppTournament?> getTournament(String tournamentId) async {
    final lookup = await _tournamentResolver.lookup(tournamentId);
    final data = lookup?.data;
    if (lookup == null || data == null) return null;
    return AppTournament.fromMap(data);
  }

  @override
  Future<AppParticipant> joinTournament({
    required String tournamentId,
    required String entityId,
    required ParticipantEntityType entityType,
    ParticipantStatus status = ParticipantStatus.pending,
    String? categoryId,
    int registrationFormVersion = 1,
    List<RegistrationResponse> registrationResponses = const [],
  }) async {
    final docRef = await _getTournamentDoc(tournamentId);
    final doc = await docRef.get();
    if (doc.exists && doc.data() != null) {
      final t = AppTournament.fromMap(doc.data()!);
      final pastThreshold = DateTime.now().subtract(const Duration(days: 1));
      if (t.scheduledAt.isBefore(pastThreshold)) {
        throw Exception(
          'El torneo ha finalizado, ya no se admiten inscripciones.',
        );
      }
    } else {
      throw Exception('El torneo no existe.');
    }
    return _participantRepo.joinTournament(
      tournamentId: tournamentId,
      entityId: entityId,
      entityType: entityType,
      status: status,
      categoryId: categoryId,
      registrationFormVersion: registrationFormVersion,
      registrationResponses: registrationResponses,
    );
  }

  @override
  Future<List<AppParticipant>> getParticipants(String tournamentId) {
    return _participantRepo.getParticipants(tournamentId);
  }

  @override
  Stream<List<AppParticipant>> watchParticipants(String tournamentId) {
    return _participantRepo.watchParticipants(tournamentId);
  }

  @override
  Stream<List<AppTournament>> watchEnrolledTournaments(String uid) {
    return _participantRepo.watchEnrolledParticipants(uid).asyncMap((
      participants,
    ) async {
      final tournaments = <AppTournament>[];
      for (final p in participants) {
        try {
          var doc = await _tournaments.doc(p.tournamentId).get();
          if (!doc.exists) {
            doc = await _privateTournaments.doc(p.tournamentId).get();
          }
          if (doc.exists && doc.data() != null) {
            final tournament = AppTournament.fromMap(doc.data()!);
            tournaments.add(tournament);
          }
        } catch (e) {
          // ignore: avoid_print
          print('Error fetching tournament for participant: $e');
        }
      }
      final byId = <String, AppTournament>{};
      for (final tournament in tournaments) {
        byId[tournament.id] = tournament;
      }
      final deduped = byId.values.toList(growable: false)
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      return deduped;
    });
  }

  @override
  Stream<List<AppTournament>> watchHistoricalTournaments(String uid) {
    return _participantRepo.watchEnrolledParticipants(uid).asyncMap((
      participants,
    ) async {
      final tournaments = <AppTournament>[];
      // Excluir participaciones rechazadas o canceladas
      final validParticipants = participants
          .where((p) => p.status != ParticipantStatus.rejected)
          .toList();
      final pastThreshold = DateTime.now().subtract(const Duration(days: 1));

      for (final p in validParticipants) {
        try {
          var doc = await _tournaments.doc(p.tournamentId).get();
          if (!doc.exists) {
            doc = await _privateTournaments.doc(p.tournamentId).get();
          }
          if (doc.exists && doc.data() != null) {
            final t = AppTournament.fromMap(doc.data()!);
            // Incluir en el historial si:
            //   (a) el torneo está explícitamente completado, O
            //   (b) la fecha de celebración ya ha pasado
            final isCompleted = t.status == TournamentStatus.completed;
            final isPast = t.scheduledAt.isBefore(pastThreshold);
            if (isCompleted || isPast) {
              tournaments.add(t);
            }
          }
        } catch (e) {
          // ignore: avoid_print
          print('Error fetching historical tournament: $e');
        }
      }
      tournaments.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      return tournaments;
    });
  }

  @override
  Future<void> cancelInscription({
    required String tournamentId,
    required String participantId,
  }) async {
    await _db.runTransaction((transaction) async {
      DocumentReference<Map<String, dynamic>> tournamentRef = _tournaments.doc(
        tournamentId,
      );
      DocumentSnapshot<Map<String, dynamic>> tournamentDoc = await transaction
          .get(tournamentRef);
      if (!tournamentDoc.exists) {
        tournamentRef = _privateTournaments.doc(tournamentId);
        tournamentDoc = await transaction.get(tournamentRef);
        if (!tournamentDoc.exists) {
          throw Exception('El torneo no existe.');
        }
      }

      var participantRef = tournamentRef
          .collection('participants')
          .doc(participantId);
      var participantDoc = await transaction.get(participantRef);
      if (!participantDoc.exists &&
          tournamentRef.parent.id == 'private_tournaments') {
        final legacyParticipantRef = _tournaments
            .doc(tournamentId)
            .collection('participants')
            .doc(participantId);
        final legacyParticipantDoc = await transaction.get(
          legacyParticipantRef,
        );
        if (legacyParticipantDoc.exists) {
          participantRef = legacyParticipantRef;
          participantDoc = legacyParticipantDoc;
        }
      }
      if (!participantDoc.exists) {
        throw Exception(
          'El participante ya no está inscrito o la inscripción ya fue cancelada.',
        );
      }

      final data = tournamentDoc.data();
      final currentCount = data?['participantCount'] as int? ?? 0;

      transaction.delete(participantRef);

      if (currentCount > 0) {
        transaction.update(tournamentRef, {
          'participantCount': currentCount - 1,
        });
      }
    });
  }

  @override
  Future<void> incrementParticipantCount(String tournamentId) async {
    final ref = await _getTournamentDoc(tournamentId);
    await ref.update({'participantCount': FieldValue.increment(1)});
  }

  @override
  Future<void> decrementParticipantCount(String tournamentId) async {
    final ref = await _getTournamentDoc(tournamentId);
    await ref.update({'participantCount': FieldValue.increment(-1)});
  }

  // ── Validación de duplicados ───────────────────────────────────────────────

  @override
  Future<AppTournament?> findDuplicateTournament({
    required DateTime scheduledAt,
    required String location,
  }) async {
    // Rango del día natural seleccionado para acotar la consulta; el filtrado
    // final exige el mismo instante y la misma ubicación normalizada.
    final dayStart = DateTime(
      scheduledAt.year,
      scheduledAt.month,
      scheduledAt.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));

    final snapshot = await _tournaments
        .where(
          'scheduledAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart),
        )
        .where('scheduledAt', isLessThan: Timestamp.fromDate(dayEnd))
        .get()
        .timeout(const Duration(seconds: 10));

    final normalizedLocation = location.trim().toLowerCase();

    for (final doc in snapshot.docs) {
      try {
        final t = AppTournament.fromMap(doc.data());
        if (!t.isPubliclyVisible) continue;
        final sameScheduledAt =
            t.scheduledAt.millisecondsSinceEpoch ==
            scheduledAt.millisecondsSinceEpoch;
        final sameLocation =
            t.location.trim().toLowerCase() == normalizedLocation;
        if (sameScheduledAt && sameLocation) return t;
      } catch (_) {
        // Ignorar documentos con formato incorrecto.
      }
    }
    return null;
  }
}
