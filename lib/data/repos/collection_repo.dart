import 'package:drift/drift.dart';

import '../db/database.dart';

/// Mutates ownership for a single sticker.
/// UX from refs:  tap → owned · tap again → duplicate (+1) · long press → missing.
class CollectionRepo {
  final AppDatabase db;
  CollectionRepo(this.db);

  Future<int> _activeProfileId() async {
    final p = await (db.select(db.profiles)..where((t) => t.isActive.equals(true))).getSingleOrNull();
    return p?.id ?? (await db.select(db.profiles).get()).first.id;
  }

  Future<Collection?> _entry(int profileId, int stickerId) async {
    return (db.select(db.collections)
          ..where((c) => c.profileId.equals(profileId) & c.stickerId.equals(stickerId)))
        .getSingleOrNull();
  }

  Future<void> _upsert(int profileId, int stickerId, String status, int dupCount) async {
    final existing = await _entry(profileId, stickerId);
    if (existing == null) {
      await db.into(db.collections).insert(CollectionsCompanion.insert(
            profileId: profileId,
            stickerId: stickerId,
            status: Value(status),
            duplicateCount: Value(dupCount),
          ));
    } else {
      await (db.update(db.collections)..where((c) => c.id.equals(existing.id))).write(
        CollectionsCompanion(
          status: Value(status),
          duplicateCount: Value(dupCount),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> tapSticker(int stickerId) async {
    final pid = await _activeProfileId();
    final e = await _entry(pid, stickerId);
    if (e == null || e.status == 'missing') {
      await _upsert(pid, stickerId, 'owned', 0);
    } else if (e.status == 'owned') {
      await _upsert(pid, stickerId, 'duplicate', 1);
    } else {
      await _upsert(pid, stickerId, 'duplicate', e.duplicateCount + 1);
    }
  }

  Future<void> removeSticker(int stickerId) async {
    final pid = await _activeProfileId();
    final e = await _entry(pid, stickerId);
    if (e == null || e.status == 'missing') return;
    if (e.status == 'duplicate') {
      final next = e.duplicateCount - 1;
      if (next <= 0) {
        await _upsert(pid, stickerId, 'owned', 0);
      } else {
        await _upsert(pid, stickerId, 'duplicate', next);
      }
    } else {
      await _upsert(pid, stickerId, 'missing', 0);
    }
  }

  /// Updates the player/label name shown under the number on each card.
  Future<void> setPlayerName(int stickerId, String? name) async {
    final value = (name == null || name.trim().isEmpty) ? null : name.trim();
    await (db.update(db.stickers)..where((s) => s.id.equals(stickerId)))
        .write(StickersCompanion(playerName: Value(value)));
  }

  /// Bulk-update player names from a `code,name` pair map, e.g.
  ///   {'BRA1': 'Alisson', 'BRA2': 'Marquinhos', ...}
  Future<int> bulkSetPlayerNames(Map<String, String> codeToName) async {
    var updated = 0;
    final all = await db.select(db.stickers).get();
    final byNumber = {for (final s in all) s.number.toUpperCase(): s};
    await db.transaction(() async {
      for (final entry in codeToName.entries) {
        final s = byNumber[entry.key.toUpperCase()];
        if (s == null) continue;
        final v = entry.value.trim();
        await (db.update(db.stickers)..where((x) => x.id.equals(s.id)))
            .write(StickersCompanion(playerName: Value(v.isEmpty ? null : v)));
        updated++;
      }
    });
    return updated;
  }
}
