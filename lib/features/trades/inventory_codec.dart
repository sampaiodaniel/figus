import 'dart:convert';

import '../../data/db/database.dart';
import '../../data/repos/profile_repo.dart';
import 'trade_matcher.dart';

/// Serializes / deserializes an inventory between two devices.
///
/// Format (JSON):
///   {
///     "v": 1,
///     "profile": "Daniel",
///     "favorites": ["BRA","ARG"],
///     "dupes": {"BRA10": 2, "ARG3": 1, ...},
///     "missing": ["BRA1","BRA2",...],
///     "foils": ["BRA1","FWC9",...]   // codes that are foil/shiny
///   }
class InventoryCodec {
  /// Pulls the active profile's inventory from the database.
  static Future<Map<String, dynamic>> exportMine(AppDatabase db) async {
    final repo = ProfileRepo(db);
    final profile = await repo.active();
    final favorites = await repo.favoriteNations();

    final stickers = await db.select(db.stickers).get();
    final nationsRows = await db.select(db.nations).get();
    final nationCodeById = {for (final n in nationsRows) n.id: n.code};
    final collections = await (db.select(db.collections)
          ..where((c) => c.profileId.equals(profile.id)))
        .get();
    final byStickerId = {for (final c in collections) c.stickerId: c};

    final dupes = <String, int>{};
    final missing = <String>[];
    final foils = <String>[];
    for (final s in stickers) {
      if (s.isFoil) foils.add(s.number);
      final c = byStickerId[s.id];
      if (c == null || c.status == 'missing') {
        missing.add(s.number);
      } else if (c.status == 'duplicate') {
        dupes[s.number] = c.duplicateCount;
      }
    }

    return {
      'v': 1,
      'profile': profile.name,
      'favorites': favorites.toList(),
      'dupes': dupes,
      'missing': missing,
      'foils': foils,
      // Optional: nation code per sticker so the other side can rank.
      'nations': {
        for (final s in stickers)
          if (s.nationId != null) s.number: nationCodeById[s.nationId!],
      },
    };
  }

  static String encodeJson(Map<String, dynamic> map) => jsonEncode(map);

  /// Builds a [TradeInventory] from a JSON payload sent by another device.
  static TradeInventory decodeAsFriend(String json) {
    final obj = jsonDecode(json) as Map<String, dynamic>;
    final dupes = (obj['dupes'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toInt()));
    final missing = ((obj['missing'] as List?) ?? []).map((e) => e as String).toSet();
    final foils = ((obj['foils'] as List?) ?? []).map((e) => e as String).toSet();
    final nations = (obj['nations'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v as String));
    final favs = ((obj['favorites'] as List?) ?? []).map((e) => e as String).toSet();

    final stickers = <String, TradeSticker>{};
    final allCodes = <String>{...dupes.keys, ...missing, ...foils, ...nations.keys};
    for (final code in allCodes) {
      stickers[code] = TradeSticker(
        code: code,
        nationCode: nations[code],
        isFoil: foils.contains(code),
      );
    }

    return TradeInventory(
      dupesByCode: dupes,
      missingCodes: missing,
      stickersByCode: stickers,
      favoriteNations: favs,
    );
  }

  /// Builds a [TradeInventory] from the local database for the active profile.
  static Future<TradeInventory> myInventory(AppDatabase db) async {
    final exported = await exportMine(db);
    return decodeAsFriend(encodeJson(exported));
  }

  static String? profileNameOf(String json) {
    try {
      final obj = jsonDecode(json) as Map<String, dynamic>;
      return obj['profile'] as String?;
    } catch (_) {
      return null;
    }
  }
}
