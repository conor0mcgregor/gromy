import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/tournament_draft.dart';
import '../repositories/tournament_draft_repository.dart';

class SharedPreferencesTournamentDraftRepository
    implements TournamentDraftRepository {
  SharedPreferencesTournamentDraftRepository({
    Future<SharedPreferences>? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance();

  static const String _key = 'tournament_drafts';

  final Future<SharedPreferences> _preferences;

  @override
  Future<TournamentDraft> saveDraft(TournamentDraft draft) async {
    final prefs = await _preferences;
    final drafts = await _readDrafts(prefs);
    final id = draft.id.isEmpty ? _newId() : draft.id;
    final draftToSave = draft.copyWith(id: id, updatedAt: DateTime.now());

    final index = drafts.indexWhere((entry) => entry.id == id);
    if (index >= 0) {
      drafts[index] = draftToSave;
    } else {
      drafts.add(draftToSave);
    }

    await _writeDrafts(prefs, drafts);
    return draftToSave;
  }

  @override
  Future<List<TournamentDraft>> getDraftsForOwner(String ownerUid) async {
    if (ownerUid.trim().isEmpty) return const [];
    final prefs = await _preferences;
    final drafts = await _readDrafts(prefs);
    return drafts.where((draft) => draft.ownerUid == ownerUid).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<void> deleteDraft(String draftId) async {
    final prefs = await _preferences;
    final drafts = await _readDrafts(prefs)
      ..removeWhere((draft) => draft.id == draftId);
    await _writeDrafts(prefs, drafts);
  }

  Future<List<TournamentDraft>> _readDrafts(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <TournamentDraft>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <TournamentDraft>[];
      final drafts = <TournamentDraft>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          drafts.add(TournamentDraft.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {}
      }
      return drafts;
    } catch (_) {
      return <TournamentDraft>[];
    }
  }

  Future<void> _writeDrafts(
    SharedPreferences prefs,
    List<TournamentDraft> drafts,
  ) {
    return prefs.setString(
      _key,
      jsonEncode(drafts.map((draft) => draft.toJson()).toList()),
    );
  }

  String _newId() => 'draft_${DateTime.now().microsecondsSinceEpoch}';
}
