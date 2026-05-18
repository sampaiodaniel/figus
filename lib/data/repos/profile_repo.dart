import 'package:drift/drift.dart';

import '../db/database.dart';
import 'sync_repo.dart';

class ProfileRepo {
  final AppDatabase db;
  final SyncRepo? sync;
  ProfileRepo(this.db, {this.sync});

  Future<List<Profile>> all() => db.select(db.profiles).get();

  Future<Profile> active() async {
    final p = await (db.select(db.profiles)..where((t) => t.isActive.equals(true))).getSingleOrNull();
    if (p != null) return p;
    final any = await db.select(db.profiles).get();
    if (any.isEmpty) throw StateError('No profiles');
    await setActive(any.first.id);
    return any.first;
  }

  Future<int> create(String name, {int avatarColor = 0xFF1F66FF}) async {
    return db.into(db.profiles).insert(ProfilesCompanion.insert(
          name: name,
          avatarColor: Value(avatarColor),
        ));
  }

  Future<void> setActive(int id) async {
    await db.transaction(() async {
      await db.update(db.profiles).write(const ProfilesCompanion(isActive: Value(false)));
      await (db.update(db.profiles)..where((p) => p.id.equals(id)))
          .write(const ProfilesCompanion(isActive: Value(true)));
    });
  }

  /// [pushToCloud] is false when applying a name pulled from the cloud,
  /// so we don't bounce it right back.
  Future<void> rename(int id, String name, {bool pushToCloud = true}) async {
    await (db.update(db.profiles)..where((p) => p.id.equals(id)))
        .write(ProfilesCompanion(name: Value(name)));
    if (pushToCloud && sync != null) {
      // Only the active profile name is mirrored to the cloud — that's the
      // identity the user sees on the other devices.
      final activeProfile = await active();
      if (activeProfile.id == id) {
        // ignore: discarded_futures
        sync!.pushUserSettings(profileName: name);
      }
    }
  }

  /// Returns the current set of nation codes favorited by the active profile.
  Future<Set<String>> favoriteNations() async {
    final p = await active();
    return _parseFavorites(p.favoriteNations);
  }

  Future<void> setFavoriteNations(Set<String> codes, {bool pushToCloud = true}) async {
    final p = await active();
    await (db.update(db.profiles)..where((x) => x.id.equals(p.id))).write(
      ProfilesCompanion(favoriteNations: Value(codes.join(','))),
    );
    if (pushToCloud && sync != null) {
      // ignore: discarded_futures
      sync!.pushUserSettings(favoriteNations: codes.toList());
    }
  }

  /// Set the avatar id for the active profile. Auto-syncs to cloud when
  /// signed in so the choice follows the user across devices.
  Future<void> setAvatarEmoji(String emoji, {bool pushToCloud = true}) async {
    final p = await active();
    await (db.update(db.profiles)..where((x) => x.id.equals(p.id))).write(
      ProfilesCompanion(avatarEmoji: Value(emoji)),
    );
    if (pushToCloud && sync != null) {
      // ignore: discarded_futures
      sync!.pushUserSettings(avatar: emoji);
    }
  }

  Future<void> toggleFavoriteNation(String code) async {
    final favs = await favoriteNations();
    if (favs.contains(code)) {
      favs.remove(code);
    } else {
      favs.add(code);
    }
    await setFavoriteNations(favs);
  }

  static Set<String> _parseFavorites(String raw) {
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  Future<void> delete(int id) async {
    final all = await db.select(db.profiles).get();
    if (all.length <= 1) return; // never delete the last profile
    await db.transaction(() async {
      await (db.delete(db.collections)..where((c) => c.profileId.equals(id))).go();
      await (db.delete(db.profiles)..where((p) => p.id.equals(id))).go();
      final remaining = await db.select(db.profiles).get();
      await setActive(remaining.first.id);
    });
  }
}
