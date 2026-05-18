import '../../domain/models/album_view_models.dart';
import '../db/database.dart';
import '../seeds/wc2026_seed.dart';

enum AlbumFilter { all, missing, duplicates }

class AlbumRepo {
  final AppDatabase db;
  AlbumRepo(this.db);

  Future<int> _activeProfileId() async {
    final p = await (db.select(db.profiles)..where((t) => t.isActive.equals(true))).getSingleOrNull();
    return p?.id ?? (await db.select(db.profiles).get()).first.id;
  }

  Future<int> _albumId() async {
    final a = await (db.select(db.albums)..where((t) => t.code.equals(WC2026Seed.albumCode))).getSingle();
    return a.id;
  }

  /// Returns all sections (specials + 48 nations) with status applied for the active profile.
  Future<List<AlbumSection>> loadSections({
    AlbumFilter filter = AlbumFilter.all,
    String? search,
  }) async {
    final albumId = await _albumId();
    final profileId = await _activeProfileId();

    final stickerRows = await (db.select(db.stickers)..where((s) => s.albumId.equals(albumId))).get();
    final nationRows = await (db.select(db.nations)..where((n) => n.albumId.equals(albumId))).get();
    final collectionRows = await (db.select(db.collections)
          ..where((c) => c.profileId.equals(profileId)))
        .get();

    final statusBySticker = {for (final c in collectionRows) c.stickerId: c};
    final nationById = {for (final n in nationRows) n.id: n};

    StickerView toView(Sticker s) {
      final c = statusBySticker[s.id];
      final status = switch (c?.status ?? 'missing') {
        'owned' => StickerOwnership.owned,
        'duplicate' => StickerOwnership.duplicate,
        _ => StickerOwnership.missing,
      };
      return StickerView(
        id: s.id,
        number: s.number,
        label: s.label,
        type: s.type,
        isFoil: s.isFoil,
        pageNumber: s.pageNumber,
        positionInPage: s.positionInPage,
        nationCode: s.nationId == null ? null : nationById[s.nationId!]?.code,
        status: status,
        duplicateCount: c?.duplicateCount ?? 0,
        playerName: s.playerName,
      );
    }

    bool matchesFilter(StickerView v) {
      switch (filter) {
        case AlbumFilter.all:
          return true;
        case AlbumFilter.missing:
          return v.status == StickerOwnership.missing;
        case AlbumFilter.duplicates:
          return v.status == StickerOwnership.duplicate;
      }
    }

    bool matchesSearch(StickerView v) {
      if (search == null || search.trim().isEmpty) return true;
      final q = search.trim().toLowerCase();
      return v.number.toLowerCase().contains(q) ||
          v.label.toLowerCase().contains(q) ||
          (v.playerName?.toLowerCase().contains(q) ?? false);
    }

    // Build BOTH a filtered and an unfiltered list of views. Sections need
    // both: the filtered list drives which stickers are visible, while the
    // section counts (ownedCount/totalCount) must come from the full set,
    // otherwise "9/9 COMPLETO" shows for every nation when filtering by
    // duplicates (because every visible sticker is non-missing by definition).
    final allViews = stickerRows.map(toView).toList();
    final views = allViews.where(matchesFilter).where(matchesSearch).toList();

    // Section counts come from `allViews` (entire album) so the COMPLETO
    // badge and "X/Y" reflect the section's true progress regardless of
    // which filter is active.
    List<StickerView> filterAndSort(
      bool Function(StickerView) keep, {
      required List<StickerView> source,
    }) {
      final list = source.where(keep).toList()
        ..sort((a, b) => a.positionInPage.compareTo(b.positionInPage));
      return list;
    }

    final introAll = filterAndSort(
        (v) => v.nationCode == null && v.pageNumber == 0,
        source: allViews);
    final legendAll = filterAndSort(
        (v) => v.nationCode == null && v.pageNumber >= 100 && v.pageNumber < 200,
        source: allViews);
    final ccAll = filterAndSort(
        (v) => v.nationCode == null && v.pageNumber >= 200 && v.pageNumber < 300,
        source: allViews);
    final lgdAll = filterAndSort(
        (v) => v.nationCode == null && v.pageNumber >= 300,
        source: allViews);

    final introVisible = filterAndSort(
        (v) => v.nationCode == null && v.pageNumber == 0,
        source: views);
    final legendVisible = filterAndSort(
        (v) => v.nationCode == null && v.pageNumber >= 100 && v.pageNumber < 200,
        source: views);
    final ccVisible = filterAndSort(
        (v) => v.nationCode == null && v.pageNumber >= 200 && v.pageNumber < 300,
        source: views);
    final lgdVisible = filterAndSort(
        (v) => v.nationCode == null && v.pageNumber >= 300,
        source: views);

    // Per-nation maps: visible (post-filter) + total (pre-filter).
    final byNation = <String, List<StickerView>>{};
    for (final v in views.where((v) => v.nationCode != null)) {
      byNation.putIfAbsent(v.nationCode!, () => []).add(v);
    }
    for (final list in byNation.values) {
      list.sort((a, b) => a.positionInPage.compareTo(b.positionInPage));
    }
    final allByNation = <String, List<StickerView>>{};
    for (final v in allViews.where((v) => v.nationCode != null)) {
      allByNation.putIfAbsent(v.nationCode!, () => []).add(v);
    }

    final sections = <AlbumSection>[];

    int ownedOf(List<StickerView> all) =>
        all.where((v) => v.status != StickerOwnership.missing).length;

    if (introVisible.isNotEmpty) {
      sections.add(AlbumSection(
        key: 'FWC',
        title: 'FWC — FIFA WC 2026',
        flag: '🏆',
        ownedCount: ownedOf(introAll),
        totalCount: introAll.length,
        stickers: introVisible,
      ));
    }

    final orderedNations = nationRows.toList()
      ..sort((a, b) => a.orderInAlbum.compareTo(b.orderInAlbum));
    for (final n in orderedNations) {
      final visible = byNation[n.code];
      if (visible == null || visible.isEmpty) continue;
      final all = allByNation[n.code] ?? const <StickerView>[];
      sections.add(AlbumSection(
        key: n.code,
        title: '${n.code} - ${n.name}',
        flag: n.flag,
        ownedCount: ownedOf(all),
        totalCount: all.length,
        stickers: visible,
      ));
    }

    if (legendVisible.isNotEmpty) {
      sections.add(AlbumSection(
        key: 'FWC9+',
        title: 'FWC9+ — Lendas da Copa',
        flag: '⭐',
        ownedCount: ownedOf(legendAll),
        totalCount: legendAll.length,
        stickers: legendVisible,
      ));
    }

    if (ccVisible.isNotEmpty) {
      sections.add(AlbumSection(
        key: 'CC',
        title: 'CC — Coca-Cola',
        flag: '🥤',
        ownedCount: ownedOf(ccAll),
        totalCount: ccAll.length,
        stickers: ccVisible,
      ));
    }

    if (lgdVisible.isNotEmpty) {
      sections.add(AlbumSection(
        key: 'LGD',
        title: 'LGD — Lendários',
        flag: '💎',
        ownedCount: ownedOf(lgdAll),
        totalCount: lgdAll.length,
        stickers: lgdVisible,
      ));
    }

    return sections;
  }

  Future<AlbumStats> loadStats() async {
    final albumId = await _albumId();
    final profileId = await _activeProfileId();

    final stickerRows = await (db.select(db.stickers)..where((s) => s.albumId.equals(albumId))).get();
    final collectionRows = await (db.select(db.collections)
          ..where((c) => c.profileId.equals(profileId)))
        .get();
    final statusBySticker = {for (final c in collectionRows) c.stickerId: c};

    var owned = 0;
    var duplicates = 0;
    var foilOwned = 0;
    var foilTotal = 0;
    var foilDuplicateStickers = 0;
    var foilExtraCopies = 0;
    for (final s in stickerRows) {
      if (s.isFoil) foilTotal++;
      final c = statusBySticker[s.id];
      if (c == null) continue;
      if (c.status == 'owned' || c.status == 'duplicate') {
        owned++;
        if (s.isFoil) foilOwned++;
      }
      if (c.status == 'duplicate') {
        duplicates += c.duplicateCount;
        if (s.isFoil) {
          foilDuplicateStickers++;
          foilExtraCopies += c.duplicateCount;
        }
      }
    }

    // Temporal stats — only owned/duplicate entries have meaningful timestamps
    final activeRows = collectionRows
        .where((c) => c.status == 'owned' || c.status == 'duplicate')
        .toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));

    final collectedThisWeek =
        activeRows.where((c) => !c.updatedAt.isBefore(weekAgo)).length;

    String _dayKey(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final activeDateStrings =
        activeRows.map((c) => _dayKey(c.updatedAt)).toSet();
    final activeDays = activeDateStrings.length;

    int daysCollecting = 0;
    if (activeRows.isNotEmpty) {
      final first = activeRows
          .map((c) => c.updatedAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      daysCollecting =
          today.difference(DateTime(first.year, first.month, first.day)).inDays + 1;
    }

    int streak = 0;
    if (activeDateStrings.isNotEmpty) {
      var checkDay = today;
      if (!activeDateStrings.contains(_dayKey(checkDay))) {
        checkDay = today.subtract(const Duration(days: 1));
      }
      while (activeDateStrings.contains(_dayKey(checkDay))) {
        streak++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      }
    }

    // Last 4 weeks of activity (week 0 = current week).
    final weeklyHistory = <int>[0, 0, 0, 0];
    for (final c in activeRows) {
      final ts = DateTime(c.updatedAt.year, c.updatedAt.month, c.updatedAt.day);
      final daysAgo = today.difference(ts).inDays;
      if (daysAgo < 0 || daysAgo >= 28) continue;
      final weekIndex = 3 - (daysAgo ~/ 7).clamp(0, 3);
      weeklyHistory[weekIndex]++;
    }

    // Day-of-week distribution (1=Mon … 7=Sun) → best day all-time.
    final dowCounts = <int, int>{};
    for (final c in activeRows) {
      final dow = c.updatedAt.weekday;
      dowCounts[dow] = (dowCounts[dow] ?? 0) + 1;
    }
    MapEntry<int, int>? bestDow;
    for (final e in dowCounts.entries) {
      if (bestDow == null || e.value > bestDow.value) bestDow = e;
    }

    return AlbumStats(
      total: stickerRows.length,
      owned: owned,
      missing: stickerRows.length - owned,
      duplicates: duplicates,
      foilOwned: foilOwned,
      foilTotal: foilTotal,
      foilDuplicateStickers: foilDuplicateStickers,
      foilExtraCopies: foilExtraCopies,
      collectedThisWeek: collectedThisWeek,
      activeDays: activeDays,
      daysCollecting: daysCollecting,
      streak: streak,
      weeklyHistory: weeklyHistory,
      bestDayOfWeek: bestDow?.key,
      bestDayOfWeekCount: bestDow?.value ?? 0,
    );
  }
}
