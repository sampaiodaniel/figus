import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/providers.dart';

/// Result of a [StreakService.recordOpen] call so the UI can react with
/// snackbars / badges / confetti.
class StreakUpdate {
  final int currentStreak;
  final bool justIncremented;
  final bool usedFreeze;
  final int freezesUsedThisMonth;
  final int? milestoneReached;

  const StreakUpdate({
    required this.currentStreak,
    required this.justIncremented,
    required this.usedFreeze,
    required this.freezesUsedThisMonth,
    this.milestoneReached,
  });
}

/// Tracks daily-open streak per profile. Mechanics inspired by Duolingo:
/// 3 automatic "freezes" per month forgive a missed day, so weekend casuals
/// don't get punished. Hits reset on a 2-day gap with no freeze remaining.
class StreakService {
  final AppDatabase db;
  StreakService(this.db);

  static const _freezesPerMonth = 3;
  static const _milestones = <int>{3, 7, 14, 30, 60};

  Future<Streak?> current(int profileId) {
    return (db.select(db.streaks)..where((s) => s.profileId.equals(profileId)))
        .getSingleOrNull();
  }

  Future<StreakUpdate> recordOpen(int profileId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final existing = await current(profileId);
    if (existing == null) {
      await db.into(db.streaks).insert(StreaksCompanion.insert(
            profileId: profileId,
            currentStreak: const Value(1),
            longestStreak: const Value(1),
            lastOpenAt: Value(now),
            freezesMonthKey: Value(monthKey),
          ));
      return const StreakUpdate(
        currentStreak: 1,
        justIncremented: true,
        usedFreeze: false,
        freezesUsedThisMonth: 0,
        milestoneReached: 1,
      );
    }

    final lastOpen = existing.lastOpenAt;
    final lastDay = lastOpen == null
        ? null
        : DateTime(lastOpen.year, lastOpen.month, lastOpen.day);
    final gap = lastDay == null ? 999 : today.difference(lastDay).inDays;

    var freezesUsed = existing.freezesUsedThisMonth;
    if (existing.freezesMonthKey != monthKey) {
      // New month — reset freezes.
      freezesUsed = 0;
    }

    if (gap == 0) {
      // Same calendar day, but month flag may have rolled — keep numbers sane.
      if (freezesUsed != existing.freezesUsedThisMonth ||
          existing.freezesMonthKey != monthKey) {
        await _writeStreak(profileId,
            current: existing.currentStreak,
            lastOpen: lastOpen!,
            monthKey: monthKey,
            freezesUsed: freezesUsed);
      }
      return StreakUpdate(
        currentStreak: existing.currentStreak,
        justIncremented: false,
        usedFreeze: false,
        freezesUsedThisMonth: freezesUsed,
      );
    }

    if (gap == 1) {
      final next = existing.currentStreak + 1;
      final longest = next > existing.longestStreak ? next : existing.longestStreak;
      await _writeStreak(profileId,
          current: next,
          longest: longest,
          lastOpen: now,
          monthKey: monthKey,
          freezesUsed: freezesUsed);
      return StreakUpdate(
        currentStreak: next,
        justIncremented: true,
        usedFreeze: false,
        freezesUsedThisMonth: freezesUsed,
        milestoneReached: _milestones.contains(next) ? next : null,
      );
    }

    if (gap == 2 && freezesUsed < _freezesPerMonth) {
      final next = existing.currentStreak + 1;
      final longest = next > existing.longestStreak ? next : existing.longestStreak;
      await _writeStreak(profileId,
          current: next,
          longest: longest,
          lastOpen: now,
          monthKey: monthKey,
          freezesUsed: freezesUsed + 1);
      return StreakUpdate(
        currentStreak: next,
        justIncremented: true,
        usedFreeze: true,
        freezesUsedThisMonth: freezesUsed + 1,
        milestoneReached: _milestones.contains(next) ? next : null,
      );
    }

    // Reset.
    await _writeStreak(profileId,
        current: 1,
        lastOpen: now,
        monthKey: monthKey,
        freezesUsed: freezesUsed);
    return StreakUpdate(
      currentStreak: 1,
      justIncremented: false,
      usedFreeze: false,
      freezesUsedThisMonth: freezesUsed,
    );
  }

  Future<void> _writeStreak(
    int profileId, {
    required int current,
    int? longest,
    required DateTime lastOpen,
    required String monthKey,
    required int freezesUsed,
  }) async {
    await (db.update(db.streaks)..where((s) => s.profileId.equals(profileId)))
        .write(StreaksCompanion(
      currentStreak: Value(current),
      longestStreak:
          longest != null ? Value(longest) : const Value.absent(),
      lastOpenAt: Value(lastOpen),
      freezesUsedThisMonth: Value(freezesUsed),
      freezesMonthKey: Value(monthKey),
      updatedAt: Value(DateTime.now()),
    ));
  }
}

final streakServiceProvider = Provider<StreakService>(
    (ref) => StreakService(ref.watch(databaseProvider)));

/// Re-fetches the streak row reactively — bumped after every [recordOpen].
final streakVersionProvider = StateProvider<int>((_) => 0);

final currentStreakProvider = FutureProvider.autoDispose<Streak?>((ref) async {
  ref.watch(streakVersionProvider);
  final pid = (await ref.watch(profileRepoProvider).active()).id;
  return ref.watch(streakServiceProvider).current(pid);
});
