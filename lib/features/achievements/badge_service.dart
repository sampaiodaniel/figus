import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/providers.dart';

/// Checks every achievement against the current profile state and inserts
/// freshly-unlocked ones into the `badges` table. Idempotent — the unique
/// (profileId, badgeId) key prevents duplicate inserts.
class BadgeService {
  final AppDatabase db;
  BadgeService(this.db);

  Future<Set<String>> earnedFor(int profileId) async {
    final rows = await (db.select(db.badges)
          ..where((b) => b.profileId.equals(profileId)))
        .get();
    return rows.map((b) => b.badgeId).toSet();
  }

  /// Returns the set of newly-earned badge ids (caller can show a snackbar).
  Future<Set<String>> recheckAll(int profileId) async {
    final earned = await earnedFor(profileId);
    final newly = <String>{};

    Future<void> award(String id) async {
      if (earned.contains(id) || newly.contains(id)) return;
      await db.into(db.badges).insert(
            BadgesCompanion.insert(profileId: profileId, badgeId: id),
            mode: InsertMode.insertOrIgnore,
          );
      newly.add(id);
    }

    // ── Streak ───────────────────────────────────────────────────────────────
    final streak = await (db.select(db.streaks)
          ..where((s) => s.profileId.equals(profileId)))
        .getSingleOrNull();
    if (streak != null) {
      final best = streak.longestStreak;
      if (best >= 3) await award('streak_3');
      if (best >= 7) await award('streak_7');
      if (best >= 14) await award('streak_14');
      if (best >= 30) await award('streak_30');
      if (best >= 60) await award('streak_60');
    }

    // ── Collection (sticker counts) ──────────────────────────────────────────
    // owned + duplicate both count as "has the sticker".
    final ownedCol = db.collections.id.count();
    final ownedResult = await (db.selectOnly(db.collections)
          ..addColumns([ownedCol])
          ..where(db.collections.profileId.equals(profileId) &
              db.collections.status.isIn(['owned', 'duplicate'])))
        .getSingle();
    final ownedCount = ownedResult.read(ownedCol) ?? 0;

    if (ownedCount >= 1) await award('first_sticker');
    if (ownedCount >= 10) await award('ten_stickers');
    if (ownedCount >= 100) await award('hundred_stickers');
    if (ownedCount >= 490) await award('half_album');

    final totalCol = db.stickers.id.count();
    final totalResult = await (db.selectOnly(db.stickers)..addColumns([totalCol]))
        .getSingle();
    final totalCount = totalResult.read(totalCol) ?? 0;
    if (totalCount > 0 && ownedCount >= totalCount) {
      await award('complete_album');
    }

    // ── Nations (complete = all stickers in a nation owned) ──────────────────
    // Compute owned-per-nation vs total-per-nation in 1 round trip each.
    final nationsList = await db.select(db.nations).get();
    var completedNations = 0;
    for (final n in nationsList) {
      final nationOwnedCol = db.collections.id.count();
      final nationOwnedResult = await (db.selectOnly(db.collections).join([
        innerJoin(db.stickers,
            db.stickers.id.equalsExp(db.collections.stickerId)),
      ])
            ..addColumns([nationOwnedCol])
            ..where(db.collections.profileId.equals(profileId) &
                db.collections.status.isIn(['owned', 'duplicate']) &
                db.stickers.nationId.equals(n.id)))
          .getSingle();
      final nationOwned = nationOwnedResult.read(nationOwnedCol) ?? 0;

      final nationTotalCol = db.stickers.id.count();
      final nationTotalResult = await (db.selectOnly(db.stickers)
            ..addColumns([nationTotalCol])
            ..where(db.stickers.nationId.equals(n.id)))
          .getSingle();
      final nationTotal = nationTotalResult.read(nationTotalCol) ?? 0;
      if (nationTotal > 0 && nationOwned >= nationTotal) completedNations++;
    }
    if (completedNations >= 1) await award('complete_one_nation');
    if (completedNations >= 5) await award('complete_five_nations');
    if (nationsList.isNotEmpty && completedNations >= nationsList.length) {
      await award('complete_all_nations');
    }

    // ── Foils ────────────────────────────────────────────────────────────────
    final foilOwnedCol = db.collections.id.count();
    final foilOwnedResult = await (db.selectOnly(db.collections).join([
      innerJoin(db.stickers,
          db.stickers.id.equalsExp(db.collections.stickerId)),
    ])
          ..addColumns([foilOwnedCol])
          ..where(db.collections.profileId.equals(profileId) &
              db.collections.status.isIn(['owned', 'duplicate']) &
              db.stickers.isFoil.equals(true)))
        .getSingle();
    final foilOwned = foilOwnedResult.read(foilOwnedCol) ?? 0;
    if (foilOwned >= 1) await award('first_foil');
    if (foilOwned >= 10) await award('ten_foils');

    final foilTotalCol = db.stickers.id.count();
    final foilTotalResult = await (db.selectOnly(db.stickers)
          ..addColumns([foilTotalCol])
          ..where(db.stickers.isFoil.equals(true)))
        .getSingle();
    final foilTotal = foilTotalResult.read(foilTotalCol) ?? 0;
    if (foilTotal > 0 && foilOwned >= foilTotal) await award('all_foils');

    // ── Pioneer (always granted on first recheck — celebrates early users) ──
    await award('figus_pioneer');

    return newly;
  }

  /// Manual award — for events that aren't easy to detect by polling
  /// (first OCR scan, first share). Caller is responsible for triggering.
  Future<void> award(int profileId, String badgeId) async {
    await db.into(db.badges).insert(
          BadgesCompanion.insert(profileId: profileId, badgeId: badgeId),
          mode: InsertMode.insertOrIgnore,
        );
  }
}

final badgeServiceProvider =
    Provider<BadgeService>((ref) => BadgeService(ref.watch(databaseProvider)));

/// Version counter to invalidate downstream providers after a recheck.
final badgesVersionProvider = StateProvider<int>((_) => 0);

final earnedBadgesProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  ref.watch(badgesVersionProvider);
  final pid = (await ref.watch(profileRepoProvider).active()).id;
  return ref.watch(badgeServiceProvider).earnedFor(pid);
});
