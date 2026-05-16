import 'package:drift/drift.dart';

import '../db/database.dart';
import 'sync_repo.dart';

/// Mutates ownership for a single sticker.
/// UX from refs:  tap → owned · tap again → duplicate (+1) · long press → missing.
class CollectionRepo {
  final AppDatabase db;
  final SyncRepo? sync;
  CollectionRepo(this.db, {this.sync});

  Future<int> _activeProfileId() async {
    final p = await (db.select(db.profiles)..where((t) => t.isActive.equals(true))).getSingleOrNull();
    return p?.id ?? (await db.select(db.profiles).get()).first.id;
  }

  Future<Collection?> _entry(int profileId, int stickerId) async {
    return (db.select(db.collections)
          ..where((c) => c.profileId.equals(profileId) & c.stickerId.equals(stickerId)))
        .getSingleOrNull();
  }

  Future<void> _localUpsert(int profileId, int stickerId, String status, int dupCount) async {
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

  Future<void> _upsert(int profileId, int stickerId, String status, int dupCount) async {
    await _localUpsert(profileId, stickerId, status, dupCount);
    if (sync != null) {
      final sticker = await (db.select(db.stickers)..where((s) => s.id.equals(stickerId)))
          .getSingleOrNull();
      if (sticker != null) {
        sync!.pushEntry(sticker.number, status, dupCount);
      }
    }
  }

  /// Apply remote entries pulled from Supabase without re-pushing them (avoids loop).
  Future<void> applyRemoteEntries(
      Map<String, ({String status, int dupCount})> remote) async {
    if (remote.isEmpty) return;
    final pid = await _activeProfileId();
    final all = await db.select(db.stickers).get();
    final byNumber = {for (final s in all) s.number: s};
    await db.transaction(() async {
      for (final entry in remote.entries) {
        final sticker = byNumber[entry.key];
        if (sticker == null) continue;
        await _localUpsert(pid, sticker.id, entry.value.status, entry.value.dupCount);
      }
    });
  }

  /// Result of a bulk push: how many rows actually represent things the user
  /// has (owned + duplicates) vs the raw row count we pushed (including
  /// missing markers needed for sync correctness).
  ///
  /// We pass both back so the UI can show user-friendly numbers while the
  /// repo still pushes the full set needed for cross-device consistency.
  Future<({int totalRows, int markedStickers})> pushAllLocal() async {
    if (sync == null || !sync!.isSignedIn) {
      return (totalRows: 0, markedStickers: 0);
    }
    final pid = await _activeProfileId();
    final entries = await (db.select(db.collections)
          ..where((c) => c.profileId.equals(pid)))
        .get();
    if (entries.isEmpty) return (totalRows: 0, markedStickers: 0);
    final stickers = await db.select(db.stickers).get();
    final byId = {for (final s in stickers) s.id: s};
    final payload = <({String stickerNumber, String status, int dupCount})>[];
    var marked = 0;
    for (final e in entries) {
      final sticker = byId[e.stickerId];
      if (sticker == null) continue;
      payload.add((
        stickerNumber: sticker.number,
        status: e.status,
        dupCount: e.duplicateCount,
      ));
      if (e.status == 'owned' || e.status == 'duplicate') marked++;
    }
    final ok = await sync!.pushEntriesBulk(payload);
    return (
      totalRows: ok ? payload.length : 0,
      markedStickers: ok ? marked : 0,
    );
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

  /// Import a full Figuritas-format export.
  ///
  /// [faltantes] — sticker codes the user is missing.
  /// [repetidas] — sticker codes that are duplicates, mapped to extra count.
  /// Only stickers whose code prefix (e.g. "BRA", "FWC") appears in the export
  /// are touched — this prevents LGD/CC-only stickers from being wrongly marked
  /// owned when the Figuritas export doesn't cover those sections.
  ///
  /// Returns {'owned': N, 'dupes': N} (owned = exactly-once; dupes = extra copies total).
  Future<Map<String, int>> bulkImportFiguritas({
    required Set<String> faltantes,
    required Map<String, int> repetidas,
  }) async {
    final pid = await _activeProfileId();
    final all = await db.select(db.stickers).get();

    String prefix(String code) =>
        RegExp(r'^[A-Za-z]+').firstMatch(code)?.group(0)?.toUpperCase() ?? code;

    final knownPrefixes = <String>{
      ...faltantes.map(prefix),
      ...repetidas.keys.map(prefix),
    };

    var ownedCount = 0, dupesCount = 0;
    await db.transaction(() async {
      for (final s in all) {
        final code = s.number;
        if (faltantes.contains(code)) {
          await _upsert(pid, s.id, 'missing', 0);
        } else if (repetidas.containsKey(code)) {
          final extras = repetidas[code]!;
          await _upsert(pid, s.id, 'duplicate', extras);
          dupesCount += extras;
        } else if (knownPrefixes.contains(prefix(code))) {
          await _upsert(pid, s.id, 'owned', 0);
          ownedCount++;
        }
        // Unknown prefix (LGD, CC when not in export) — leave untouched
      }
    });
    return {'owned': ownedCount, 'dupes': dupesCount};
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
