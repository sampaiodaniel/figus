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

    // Group by section: specials (FWC) first, then by nation order.
    final specials = views.where((v) => v.nationCode == null).toList()
      ..sort((a, b) {
        if (a.pageNumber != b.pageNumber) return a.pageNumber.compareTo(b.pageNumber);
        return a.positionInPage.compareTo(b.positionInPage);
      });

    final byNation = <String, List<StickerView>>{};
    for (final v in views.where((v) => v.nationCode != null)) {
      byNation.putIfAbsent(v.nationCode!, () => []).add(v);
    }
    for (final list in byNation.values) {
      list.sort((a, b) => a.positionInPage.compareTo(b.positionInPage));
    }

    final sections = <AlbumSection>[];

    if (specials.isNotEmpty) {
      final ownedSpecials = specials.where((v) => v.status != StickerOwnership.missing).length;
      sections.add(AlbumSection(
        key: 'FWC',
        title: 'FIFA — Especiais',
        flag: '🏆',
        ownedCount: ownedSpecials,
        totalCount: specials.length,
        stickers: specials,
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

    return AlbumStats(
      total: stickerRows.length,
      owned: owned,
      missing: stickerRows.length - owned,
      duplicates: duplicates,
      foilOwned: foilOwned,
      foilTotal: foilTotal,
    );
  }
}
