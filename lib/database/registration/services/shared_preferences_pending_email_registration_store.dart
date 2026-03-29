import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pending_email_registration.dart';
import '../repositories/pending_email_registration_store.dart';

class SharedPreferencesPendingEmailRegistrationStore
    implements PendingEmailRegistrationStore {
  SharedPreferencesPendingEmailRegistrationStore({
    Future<SharedPreferences>? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance();

  static const String _keyPrefix = 'pending_email_registration:';

  final Future<SharedPreferences> _preferences;

  @override
  Future<void> save(PendingEmailRegistration registration) async {
    final prefs = await _preferences;
    await prefs.setString(
      _keyFor(registration.uid),
      jsonEncode(registration.toJson()),
    );
  }

  @override
  Future<PendingEmailRegistration?> getByUid(String uid) async {
    final prefs = await _preferences;
    final rawRegistration = prefs.getString(_keyFor(uid));
    if (rawRegistration == null || rawRegistration.isEmpty) {
      return null;
    }

    return PendingEmailRegistration.fromJson(
      jsonDecode(rawRegistration) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteByUid(String uid) async {
    final prefs = await _preferences;
    await prefs.remove(_keyFor(uid));
  }

  String _keyFor(String uid) => '$_keyPrefix$uid';
}
