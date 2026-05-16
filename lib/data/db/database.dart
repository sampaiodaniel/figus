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
  int get schemaVersion => 7;

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
          if (from < 4) {
            // Fix nation ordering to match printed album sequence.
            const nationOrder = [
              'MEX', 'RSA', 'KOR', 'CZE', 'CAN', 'BIH', 'QAT', 'SUI', 'BRA', 'MAR',
              'HAI', 'SCO', 'USA', 'PAR', 'AUS', 'TUR', 'GER', 'CUW', 'CIV', 'ECU',
              'NED', 'JPN', 'SWE', 'TUN', 'BEL', 'EGY', 'IRN', 'NZL', 'ESP', 'CPV',
              'KSA', 'URU', 'FRA', 'SEN', 'IRQ', 'NOR', 'ARG', 'ALG', 'AUT', 'JOR',
              'POR', 'COD', 'UZB', 'COL', 'ENG', 'CRO', 'GHA', 'PAN',
            ];
            for (var i = 0; i < nationOrder.length; i++) {
              await customUpdate(
                'UPDATE nations SET order_in_album = ? WHERE code = ?',
                variables: [Variable.withInt(i), Variable.withString(nationOrder[i])],
                updates: {nations},
              );
            }
            for (final entry in WC2026Seed.playerNames.entries) {
              final code = entry.key;
              final names = entry.value;
              for (var i = 0; i < names.length; i++) {
                final stickerNum = '$code${i + 2}';
                await customUpdate(
                  'UPDATE stickers SET player_name = ? WHERE number = ?',
                  variables: [Variable.withString(names[i]), Variable.withString(stickerNum)],
                  updates: {stickers},
                );
              }
            }
          }
          if (from < 5) {
            // Insert CC (Coca-Cola) stickers for users who already have the album seeded.
            final albumRow = await (select(albums)
                  ..where((a) => a.code.equals(WC2026Seed.albumCode)))
                .getSingleOrNull();
            if (albumRow != null) {
              final ccStickers = WC2026Seed.stickers.where((s) => s.number.startsWith('CC'));
              for (final s in ccStickers) {
                final exists = await (select(stickers)
                      ..where((st) => st.number.equals(s.number)))
                    .getSingleOrNull();
                if (exists == null) {
                  await into(stickers).insert(StickersCompanion.insert(
                    albumId: albumRow.id,
                    nationId: const Value(null),
                    number: s.number,
                    type: s.type,
                    isFoil: Value(s.isFoil),
                    pageNumber: s.pageNumber,
                    positionInPage: s.positionInPage,
                    label: s.label,
                    playerName: const Value(null),
                  ));
                }
              }
            }
          }
          if (from < 6) {
            // Insert CC10-CC14 and all Legendary stickers for existing users.
            final albumRow = await (select(albums)
                  ..where((a) => a.code.equals(WC2026Seed.albumCode)))
                .getSingleOrNull();
            if (albumRow != null) {
              // Extra CC stickers (CC10-CC14) missed by v5 migration.
              final newCcStickers = WC2026Seed.stickers.where(
                (s) => s.number.startsWith('CC') && int.tryParse(s.number.substring(2) ) != null && int.parse(s.number.substring(2)) >= 10,
              );
              for (final s in newCcStickers) {
                final exists = await (select(stickers)..where((st) => st.number.equals(s.number))).getSingleOrNull();
                if (exists == null) {
                  await into(stickers).insert(StickersCompanion.insert(
                    albumId: albumRow.id,
                    nationId: const Value(null),
                    number: s.number,
                    type: s.type,
                    isFoil: Value(s.isFoil),
                    pageNumber: s.pageNumber,
                    positionInPage: s.positionInPage,
                    label: s.label,
                    playerName: const Value(null),
                  ));
                }
              }
              final lgdStickers = WC2026Seed.stickers.where((s) => s.number.startsWith('LGD'));
              for (final s in lgdStickers) {
                final exists = await (select(stickers)
                      ..where((st) => st.number.equals(s.number)))
                    .getSingleOrNull();
                if (exists == null) {
                  await into(stickers).insert(StickersCompanion.insert(
                    albumId: albumRow.id,
                    nationId: const Value(null),
                    number: s.number,
                    type: s.type,
                    isFoil: Value(s.isFoil),
                    pageNumber: s.pageNumber,
                    positionInPage: s.positionInPage,
                    label: s.label,
                    playerName: Value(s.playerName),
                  ));
                }
              }
            }
          }
          if (from < 7) {
            // Update CC stickers with real player names and correct labels.
            const ccPlayers = <String?>[
              null, 'Lamine Yamal', 'Joshua Kimmich', 'Virgil van Dijk',
              'Antonee Robinson', 'Alphonso Davies', 'Lautaro Martínez',
              'Harry Kane', 'Edson Álvarez', 'Weston McKennie',
              'Jefferson Lerma', 'Santiago Giménez', 'Gabriel Magalhães', null,
            ];
            const ccLabels = <String>[
              'Coca-Cola × FIFA WC 2026', '', '', '', '', '', '', '', '', '', '', '', '',
              'Copa do Mundo FIFA 2026',
            ];
            for (var i = 0; i < ccPlayers.length; i++) {
              final num = 'CC${i + 1}';
              final player = ccPlayers[i];
              final label = ccLabels[i];
              await customUpdate(
                'UPDATE stickers SET player_name = ?, label = ? WHERE number = ?',
                variables: [
                  player != null ? Variable.withString(player) : const Variable(null),
                  Variable.withString(label),
                  Variable.withString(num),
                ],
                updates: {stickers},
              );
            }
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
