import 'package:drift/drift.dart';

import '../db/database.dart';

class ProfileRepo {
  final AppDatabase db;
  ProfileRepo(this.db);

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

  Future<void> rename(int id, String name) async {
    await (db.update(db.profiles)..where((p) => p.id.equals(id)))
        .write(ProfilesCompanion(name: Value(name)));
  }

  /// Returns the current set of nation codes favorited by the active profile.
  Future<Set<String>> favoriteNations() async {
    final p = await active();
    return _parseFavorites(p.favoriteNations);
  }

  Future<void> setFavoriteNations(Set<String> codes) async {
    final p = await active();
    await (db.update(db.profiles)..where((x) => x.id.equals(p.id))).write(
      ProfilesCompanion(favoriteNations: Value(codes.join(','))),
    );
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
