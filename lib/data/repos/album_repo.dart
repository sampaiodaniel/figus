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

    final views = stickerRows.map(toView).where(matchesFilter).where(matchesSearch).toList();

    // Specials by pageNumber range:
    //   0        → FWC intro (FWC00–FWC8)
    //   100–199  → FWC9+ legends
    //   200–299  → CC (Coca-Cola)
    //   300+     → Lendários (LGD)
    final introSpecials = views
        .where((v) => v.nationCode == null && v.pageNumber == 0)
        .toList()
      ..sort((a, b) => a.positionInPage.compareTo(b.positionInPage));
    final legendSpecials = views
        .where((v) => v.nationCode == null && v.pageNumber >= 100 && v.pageNumber < 200)
        .toList()
      ..sort((a, b) => a.positionInPage.compareTo(b.positionInPage));
    final ccSpecials = views
        .where((v) => v.nationCode == null && v.pageNumber >= 200 && v.pageNumber < 300)
        .toList()
      ..sort((a, b) => a.positionInPage.compareTo(b.positionInPage));
    final legendaryStickers = views
        .where((v) => v.nationCode == null && v.pageNumber >= 300)
        .toList()
      ..sort((a, b) => a.positionInPage.compareTo(b.positionInPage));

    final byNation = <String, List<StickerView>>{};
    for (final v in views.where((v) => v.nationCode != null)) {
      byNation.putIfAbsent(v.nationCode!, () => []).add(v);
    }
    for (final list in byNation.values) {
      list.sort((a, b) => a.positionInPage.compareTo(b.positionInPage));
    }

    final sections = <AlbumSection>[];

    if (introSpecials.isNotEmpty) {
      final owned = introSpecials.where((v) => v.status != StickerOwnership.missing).length;
      sections.add(AlbumSection(
        key: 'FWC',
        title: 'FWC — FIFA WC 2026',
        flag: '🏆',
        ownedCount: owned,
        totalCount: introSpecials.length,
        stickers: introSpecials,
      ));
    }

    final orderedNations = nationRows.toList()..sort((a, b) => a.orderInAlbum.compareTo(b.orderInAlbum));
    for (final n in orderedNations) {
      final list = byNation[n.code];
      if (list == null || list.isEmpty) continue;
      final owned = list.where((v) => v.status != StickerOwnership.missing).length;
      sections.add(AlbumSection(
        key: n.code,
        title: '${n.code} - ${n.name}',
        flag: n.flag,
        ownedCount: owned,
        totalCount: list.length,
        stickers: list,
      ));
    }

    if (legendSpecials.isNotEmpty) {
      final owned = legendSpecials.where((v) => v.status != StickerOwnership.missing).length;
      sections.add(AlbumSection(
        key: 'FWC9+',
        title: 'FWC9+ — Lendas da Copa',
        flag: '⭐',
        ownedCount: owned,
        totalCount: legendSpecials.length,
        stickers: legendSpecials,
      ));
    }

    if (ccSpecials.isNotEmpty) {
      final owned = ccSpecials.where((v) => v.status != StickerOwnership.missing).length;
      sections.add(AlbumSection(
        key: 'CC',
        title: 'CC — Coca-Cola',
        flag: '🥤',
        ownedCount: owned,
        totalCount: ccSpecials.length,
        stickers: ccSpecials,
      ));
    }

    if (legendaryStickers.isNotEmpty) {
      final owned = legendaryStickers.where((v) => v.status != StickerOwnership.missing).length;
      sections.add(AlbumSection(
        key: 'LGD',
        title: 'LGD — Lendários',
        flag: '💎',
        ownedCount: owned,
        totalCount: legendaryStickers.length,
        stickers: legendaryStickers,
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
    for (final s in stickerRows) {
      if (s.isFoil) foilTotal++;
      final c = statusBySticker[s.id];
      if (c == null) continue;
      if (c.status == 'owned' || c.status == 'duplicate') {
        owned++;
        if (s.isFoil) foilOwned++;
      }
      if (c.status == 'duplicate') duplicates += c.duplicateCount;
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

    return AlbumStats(
      total: stickerRows.length,
      owned: owned,
      missing: stickerRows.length - owned,
      duplicates: duplicates,
      foilOwned: foilOwned,
      foilTotal: foilTotal,
      collectedThisWeek: collectedThisWeek,
      activeDays: activeDays,
      daysCollecting: daysCollecting,
      streak: streak,
    );
  }
}
