/// Plain DTOs the UI consumes — decoupled from drift-generated classes
/// so the widget tree never imports the database.
library;

enum StickerOwnership { missing, owned, duplicate }

class StickerView {
  final int id;
  final String number;
  final String label;
  final String type; // crest|team_photo|player|intro|legend|logo
  final bool isFoil;
  final int pageNumber;
  final int positionInPage;
  final String? nationCode;
  final StickerOwnership status;
  final int duplicateCount;
  final String? playerName;

  const StickerView({
    required this.id,
    required this.number,
    required this.label,
    required this.type,
    required this.isFoil,
    required this.pageNumber,
    required this.positionInPage,
    required this.nationCode,
    required this.status,
    required this.duplicateCount,
    this.playerName,
  });

  /// Display name shown under the sticker number, falling back to label.
  String? get displayName {
    if (playerName != null && playerName!.isNotEmpty) return playerName;
    if (label.isNotEmpty) return label;
    return null;
  }
}

class NationView {
  final int id;
  final String code;
  final String name;
  final String flag;
  final String? group;
  final int orderInAlbum;
  final int ownedCount;
  final int totalCount;

  const NationView({
    required this.id,
    required this.code,
    required this.name,
    required this.flag,
    required this.group,
    required this.orderInAlbum,
    required this.ownedCount,
    required this.totalCount,
  });
}

/// Section for the Album page: a header (Nation or "Especiais") + its stickers.
class AlbumSection {
  final String key; // nation code or "FWC"
  final String title; // "BRA - Brasil"
  final String? flag;
  final int ownedCount;
  final int totalCount;
  final List<StickerView> stickers;

  const AlbumSection({
    required this.key,
    required this.title,
    required this.flag,
    required this.ownedCount,
    required this.totalCount,
    required this.stickers,
  });
}

class AlbumStats {
  final int total;
  final int owned;
  final int missing;
  final int duplicates;
  final int foilOwned;
  final int foilTotal;

  const AlbumStats({
    required this.total,
    required this.owned,
    required this.missing,
    required this.duplicates,
    required this.foilOwned,
    required this.foilTotal,
  });

  double get percentComplete => total == 0 ? 0 : owned / total;
}
