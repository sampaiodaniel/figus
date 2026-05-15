import 'package:drift/drift.dart';

import '../seeds/wc2026_seed.dart';
import 'connection/connection.dart' as conn;
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Albums, Nations, Stickers, Profiles, Collections, Wishlist])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(conn.openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 3) {
            await m.addColumn(stickers, stickers.playerName);
            await m.addColumn(profiles, profiles.favoriteNations);
          }
        },
      );

  Future<void> ensureSeeded() async {
    final existing = await (select(albums)..where((a) => a.code.equals(WC2026Seed.albumCode)))
        .getSingleOrNull();
    if (existing != null) return;

    await transaction(() async {
      final albumId = await into(albums).insert(AlbumsCompanion.insert(
        code: WC2026Seed.albumCode,
        name: WC2026Seed.albumName,
        year: WC2026Seed.albumYear,
        totalStickers: WC2026Seed.stickers.length,
      ));

      final nationIdByCode = <String, int>{};
      for (final n in WC2026Seed.nations) {
        final nid = await into(nations).insert(NationsCompanion.insert(
          albumId: albumId,
          code: n.code,
          name: n.name,
          flag: n.flag,
          orderInAlbum: n.orderInAlbum,
        ));
        nationIdByCode[n.code] = nid;
      }

      for (final s in WC2026Seed.stickers) {
        await into(stickers).insert(StickersCompanion.insert(
          albumId: albumId,
          nationId: Value(s.nationCode == null ? null : nationIdByCode[s.nationCode!]),
          number: s.number,
          type: s.type,
          isFoil: Value(s.isFoil),
          pageNumber: s.pageNumber,
          positionInPage: s.positionInPage,
          label: s.label,
          playerName: Value(s.playerName),
        ));
      }

      await into(profiles).insert(ProfilesCompanion.insert(
        name: 'Eu',
        avatarColor: const Value(0xFF1F66FF),
        isActive: const Value(true),
      ));
    });
  }
}
