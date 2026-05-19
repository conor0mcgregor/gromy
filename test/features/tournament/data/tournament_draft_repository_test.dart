import 'package:flutter_test/flutter_test.dart';
import 'package:gromy/features/tournament/data/model/enums_tournament.dart';
import 'package:gromy/features/tournament/data/model/tournament_draft.dart';
import 'package:gromy/features/tournament/data/services/shared_preferences_tournament_draft_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves a partial tournament as a local draft', () async {
    final repository = SharedPreferencesTournamentDraftRepository();

    final saved = await repository.saveDraft(
      TournamentDraft(
        id: '',
        ownerUid: 'owner-1',
        updatedAt: DateTime(2026),
        name: 'Liga sin terminar',
      ),
    );

    final drafts = await repository.getDraftsForOwner('owner-1');

    expect(saved.id, isNotEmpty);
    expect(drafts, hasLength(1));
    expect(drafts.single.name, 'Liga sin terminar');
    expect(drafts.single.ownerUid, 'owner-1');
  });

  test('persists drafts across repository instances', () async {
    final firstRepository = SharedPreferencesTournamentDraftRepository();
    await firstRepository.saveDraft(
      TournamentDraft(
        id: '',
        ownerUid: 'owner-1',
        updatedAt: DateTime(2026),
        sport: TournamentSport.padel,
      ),
    );

    final secondRepository = SharedPreferencesTournamentDraftRepository();
    final drafts = await secondRepository.getDraftsForOwner('owner-1');

    expect(drafts, hasLength(1));
    expect(drafts.single.sport, TournamentSport.padel);
  });

  test(
    'does not expose orphan or other-user drafts to the current owner',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'tournament_drafts',
        '[{"id":"orphan","name":"bad"},'
            '{"id":"other","ownerUid":"owner-2","updatedAt":"2026-05-19T10:00:00"}]',
      );

      final repository = SharedPreferencesTournamentDraftRepository();
      final drafts = await repository.getDraftsForOwner('owner-1');

      expect(drafts, isEmpty);
    },
  );

  test('removes local draft after successful conversion', () async {
    final repository = SharedPreferencesTournamentDraftRepository();
    final saved = await repository.saveDraft(
      TournamentDraft(id: '', ownerUid: 'owner-1', updatedAt: DateTime(2026)),
    );

    await repository.deleteDraft(saved.id);

    expect(await repository.getDraftsForOwner('owner-1'), isEmpty);
  });

  test('keeps a saved draft when the user leaves without discarding', () async {
    final repository = SharedPreferencesTournamentDraftRepository();
    await repository.saveDraft(
      TournamentDraft(
        id: '',
        ownerUid: 'owner-1',
        updatedAt: DateTime(2026),
        name: 'Draft to keep',
      ),
    );

    final reopenedRepository = SharedPreferencesTournamentDraftRepository();
    final drafts = await reopenedRepository.getDraftsForOwner('owner-1');

    expect(drafts, hasLength(1));
    expect(drafts.single.name, 'Draft to keep');
  });

  test(
    'discard deletes the saved local draft only when explicitly called',
    () async {
      final repository = SharedPreferencesTournamentDraftRepository();
      final saved = await repository.saveDraft(
        TournamentDraft(
          id: '',
          ownerUid: 'owner-1',
          updatedAt: DateTime(2026),
          name: 'Draft to discard',
        ),
      );

      expect(await repository.getDraftsForOwner('owner-1'), hasLength(1));

      await repository.deleteDraft(saved.id);

      expect(await repository.getDraftsForOwner('owner-1'), isEmpty);
    },
  );
}
