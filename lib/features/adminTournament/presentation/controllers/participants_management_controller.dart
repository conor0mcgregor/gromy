import 'package:flutter/foundation.dart';

import '../../../participants/data/models/participant_display.dart';
import '../../../participants/data/services/participant_display_service.dart';
import '../../data/repositories/admin_tournament_repository.dart';
import '../../data/services/firestore_admin_tournament_service.dart';
import '../../domain/use_cases/remove_participant_use_case.dart';
import '../../domain/use_cases/update_participant_category_use_case.dart';

class ParticipantsManagementController extends ChangeNotifier {
  ParticipantsManagementController({
    required this.tournamentId,
    required this.categories,
    AdminTournamentRepository? repository,
    ParticipantDisplayService? participantService,
  }) : _repository = repository ?? FirestoreAdminTournamentService(),
       _participantService = participantService ?? ParticipantDisplayService();

  final String tournamentId;
  final List<String> categories;
  final AdminTournamentRepository _repository;
  final ParticipantDisplayService _participantService;

  List<ParticipantDisplay> _participants = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Set<String> _removingIds = {};
  final Set<String> _updatingCategoryIds = {};

  List<ParticipantDisplay> get participants => _participants;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isRemoving(String participantId) => _removingIds.contains(participantId);
  bool isUpdatingCategory(String participantId) =>
      _updatingCategoryIds.contains(participantId);

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _participants = await _participantService.getParticipants(tournamentId);
    } catch (e) {
      _errorMessage = 'No se pudieron cargar los participantes: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> removeParticipant(String participantId) async {
    _removingIds.add(participantId);
    _errorMessage = null;
    notifyListeners();

    try {
      final useCase = RemoveParticipantUseCase(_repository);
      await useCase.execute(
        tournamentId: tournamentId,
        participantId: participantId,
      );

      _participants.removeWhere((p) => p.participantId == participantId);
      _removingIds.remove(participantId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'No se pudo eliminar el participante: $e';
      _removingIds.remove(participantId);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory({
    required String participantId,
    required String categoryId,
  }) async {
    _updatingCategoryIds.add(participantId);
    _errorMessage = null;
    notifyListeners();

    try {
      final useCase = UpdateParticipantCategoryUseCase(_repository);
      await useCase.execute(
        tournamentId: tournamentId,
        participantId: participantId,
        categoryId: categoryId,
        allowedCategories: categories,
      );

      _participants = _participants
          .map(
            (participant) => participant.participantId == participantId
                ? _copyWithCategory(participant, categoryId)
                : participant,
          )
          .toList(growable: false);

      _updatingCategoryIds.remove(participantId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'No se pudo cambiar la categoría: $e';
      _updatingCategoryIds.remove(participantId);
      notifyListeners();
      return false;
    }
  }

  ParticipantDisplay _copyWithCategory(
    ParticipantDisplay participant,
    String categoryId,
  ) {
    return switch (participant) {
      UserParticipantDisplay(:final user) => UserParticipantDisplay(
        participantId: participant.participantId,
        entityId: participant.entityId,
        entityType: participant.entityType,
        categoryId: categoryId,
        user: user,
      ),
      TeamParticipantDisplay(:final team) => TeamParticipantDisplay(
        participantId: participant.participantId,
        entityId: participant.entityId,
        entityType: participant.entityType,
        categoryId: categoryId,
        team: team,
      ),
    };
  }
}
