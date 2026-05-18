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
  /// Number of foil stickers that the user has marked as `duplicate`
  /// (i.e. they have spares). Important for trades — foils are usually
  /// worth 2 commons.
  final int foilDuplicateStickers;
  /// Sum of `duplicateCount` across foil duplicate entries — the *extra*
  /// copies, not the base owned one. Used to label "X repetidas brilhantes".
  final int foilExtraCopies;
  final int collectedThisWeek;
  final int activeDays;
  final int daysCollecting;
  final int streak;
  /// Count of stickers acquired per week for the last 4 weeks, oldest first.
  /// Index 0 = 4 weeks ago, index 3 = current week.
  final List<int> weeklyHistory;
  /// DateTime.weekday (1=Mon … 7=Sun) of the day-of-week the user marks
  /// the most stickers. Null when no activity yet.
  final int? bestDayOfWeek;
  /// How many stickers were marked on the best day of week (total, all-time).
  final int bestDayOfWeekCount;

  const AlbumStats({
    required this.total,
    required this.owned,
    required this.missing,
    required this.duplicates,
    required this.foilOwned,
    required this.foilTotal,
    this.foilDuplicateStickers = 0,
    this.foilExtraCopies = 0,
    this.collectedThisWeek = 0,
    this.activeDays = 0,
    this.daysCollecting = 0,
    this.streak = 0,
    this.weeklyHistory = const [0, 0, 0, 0],
    this.bestDayOfWeek,
    this.bestDayOfWeekCount = 0,
  });

  double get percentComplete => total == 0 ? 0 : owned / total;
}
