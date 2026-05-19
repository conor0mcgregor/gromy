import '../model/tournament_draft.dart';

abstract interface class TournamentDraftRepository {
  Future<TournamentDraft> saveDraft(TournamentDraft draft);

  Future<List<TournamentDraft>> getDraftsForOwner(String ownerUid);

  Future<void> deleteDraft(String draftId);
}
