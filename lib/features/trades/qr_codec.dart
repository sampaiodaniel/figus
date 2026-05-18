import 'dart:convert';

import 'package:archive/archive.dart';

import '../../data/db/database.dart';
import '../../data/repos/profile_repo.dart';
import 'trade_matcher.dart';

/// Compact encoder/decoder for the inventory snapshot that fits inside a
/// QR code. We strip the payload down to only what the matcher actually
/// needs — owned codes, dupes counts, favorites and profile name. The
/// receiver derives "missing" and "foils" from its own local seed.
class TradeQrCodec {
  // v2 prefix is the new short format; v1 (gzipped full JSON) is kept as a
  // fallback for backward compatibility while users on the older version
  // still have QRs floating around.
  static const _prefix = 'FIGUS2:';
  static const _legacyPrefix = 'FIGUS1:';

  /// Builds the QR payload directly from the database. The result is short
  /// enough to fit in QR error-correction level L through v40.
  static Future<String> encodeFromDb(AppDatabase db) async {
    final profile = await ProfileRepo(db).active();
    final favorites = await ProfileRepo(db).favoriteNations();
    final stickers = await db.select(db.stickers).get();
    final collections = await (db.select(db.collections)
          ..where((c) => c.profileId.equals(profile.id)))
        .get();
    final byStickerId = {for (final c in collections) c.stickerId: c};

    final owned = <String>[];
    final dupes = <String, int>{};
    for (final s in stickers) {
      final c = byStickerId[s.id];
      if (c == null || c.status == 'missing') continue;
      owned.add(s.number);
      if (c.status == 'duplicate' && c.duplicateCount > 0) {
        dupes[s.number] = c.duplicateCount;
      }
    }

    // Short JSON keys cut another ~25% off the gzipped size:
    //   p = profile name
    //   o = owned codes
    //   d = duplicates map
    //   f = favorite nations
    final slim = <String, dynamic>{
      'v': 2,
      'p': profile.name,
      'o': owned,
      'd': dupes,
      'f': favorites.toList(),
    };
    final json = jsonEncode(slim);
    final gz = GZipEncoder().encode(utf8.encode(json));
    return _prefix + base64Url.encode(gz!);
  }

  /// Returns the same JSON shape that [InventoryCodec.decodeAsFriend]
  /// consumes, hydrated against the local seed so that "missing" and
  /// "foils" come from the receiver's own database (those weren't sent
  /// over the wire to keep the QR small).
  static Future<TradeInventory> decodeFromQr(
      String input, AppDatabase localDb) async {
    if (input.startsWith(_legacyPrefix)) {
      return _decodeLegacy(input);
    }
    if (!input.startsWith(_prefix)) {
      throw const FormatException('Não é um QR de troca do Figus');
    }
    final b64 = input.substring(_prefix.length);
    final gz = base64Url.decode(b64);
    final raw = GZipDecoder().decodeBytes(gz);
    final json = utf8.decode(raw);
    final obj = jsonDecode(json) as Map<String, dynamic>;
    final profile = obj['p'] as String? ?? 'amigo';
    final owned = ((obj['o'] as List?) ?? []).map((e) => e as String).toSet();
    final dupes = (obj['d'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toInt()));
    final favs = ((obj['f'] as List?) ?? []).map((e) => e as String).toSet();

    // Hydrate sticker metadata from local seed so the matcher can rank by
    // nation and foil status. Missing = local.all - friend.owned.
    final localStickers = await localDb.select(localDb.stickers).get();
    final localNations = await localDb.select(localDb.nations).get();
    final nationCodeById = {for (final n in localNations) n.id: n.code};

    final stickers = <String, TradeSticker>{};
    final missingByFriend = <String>{};
    for (final s in localStickers) {
      stickers[s.number] = TradeSticker(
        code: s.number,
        nationCode: s.nationId != null ? nationCodeById[s.nationId!] : null,
        isFoil: s.isFoil,
      );
      if (!owned.contains(s.number)) missingByFriend.add(s.number);
    }

    return TradeInventory(
      dupesByCode: dupes,
      missingCodes: missingByFriend,
      stickersByCode: stickers,
      favoriteNations: favs,
      profileName: profile,
    );
  }

  /// Decodes a v1 (legacy) payload that carried the full JSON. Kept for
  /// users who scan an older QR; new QRs always use v2.
  static TradeInventory _decodeLegacy(String input) {
    final b64 = input.substring(_legacyPrefix.length);
    final gz = base64Url.decode(b64);
    final raw = GZipDecoder().decodeBytes(gz);
    final json = utf8.decode(raw);
    final obj = jsonDecode(json) as Map<String, dynamic>;
    final dupes = (obj['dupes'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toInt()));
    final missing =
        ((obj['missing'] as List?) ?? []).map((e) => e as String).toSet();
    final foils =
        ((obj['foils'] as List?) ?? []).map((e) => e as String).toSet();
    final nations = (obj['nations'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v as String));
    final favs =
        ((obj['favorites'] as List?) ?? []).map((e) => e as String).toSet();
    final profile = obj['profile'] as String? ?? 'amigo';

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
      profileName: profile,
    );
  }
}
