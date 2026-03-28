import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gromy/features/user/data/models/app_user.dart';

void main() {
  group('AppUser', () {
    test('serializes and deserializes without losing information', () {
      final createdAt = DateTime(2026, 3, 28, 10, 15, 0);
      final user = AppUser(
        uid: 'uid-123',
        email: 'ana@example.com',
        nickname: 'anita',
        name: 'Ana',
        lastName: 'Lopez',
        provider: 'google',
        createdAt: createdAt,
        photoUrl: 'https://example.com/photo.png',
      );

      final map = user.toMap();
      final hydrated = AppUser.fromMap(map);

      expect(map['createdAt'], isA<Timestamp>());
      expect(hydrated.uid, user.uid);
      expect(hydrated.email, user.email);
      expect(hydrated.nickname, user.nickname);
      expect(hydrated.name, user.name);
      expect(hydrated.lastName, user.lastName);
      expect(hydrated.provider, user.provider);
      expect(hydrated.photoUrl, user.photoUrl);
      expect(hydrated.createdAt, createdAt);
    });

    test('copyWith overrides only editable fields', () {
      final user = AppUser(
        uid: 'uid-123',
        email: 'ana@example.com',
        nickname: 'anita',
        name: 'Ana',
        lastName: 'Lopez',
        provider: 'email',
        createdAt: DateTime(2026, 3, 28),
        photoUrl: null,
      );

      final updated = user.copyWith(
        nickname: 'ana_pro',
        name: 'Ana Maria',
        photoUrl: 'https://example.com/avatar.png',
      );

      expect(updated.uid, user.uid);
      expect(updated.email, user.email);
      expect(updated.provider, user.provider);
      expect(updated.createdAt, user.createdAt);
      expect(updated.lastName, user.lastName);
      expect(updated.nickname, 'ana_pro');
      expect(updated.name, 'Ana Maria');
      expect(updated.photoUrl, 'https://example.com/avatar.png');
    });
  });
}
