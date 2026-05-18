import 'package:drift/drift.dart';

class Albums extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  IntColumn get year => integer()();
  IntColumn get totalStickers => integer()();
}

class Nations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get albumId => integer().references(Albums, #id)();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get flag => text()();
  TextColumn get group => text().nullable()();
  IntColumn get orderInAlbum => integer()();
}

class Stickers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get albumId => integer().references(Albums, #id)();
  IntColumn get nationId => integer().nullable().references(Nations, #id)();
  TextColumn get number => text()(); // BRA1, FWC9, ...
  TextColumn get type => text()(); // crest|team_photo|player|intro|legend|logo
  BoolColumn get isFoil => boolean().withDefault(const Constant(false))();
  IntColumn get pageNumber => integer()();
  IntColumn get positionInPage => integer()();
  TextColumn get label => text()();
  // Player name (or label) shown under the sticker number, like in the
  // physical album. User-editable; nullable until populated.
  TextColumn get playerName => text().nullable()();
}

class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get name => text()();
  IntColumn get avatarColor => integer().withDefault(const Constant(0xFF1F66FF))();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  BoolColumn get isShared => boolean().withDefault(const Constant(false))();
  // Comma-separated list of nation codes the user favorites — used to bias
  // trade suggestions.
  TextColumn get favoriteNations => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  // Avatar identifier — `avatar_01`..`avatar_11` map to SVG assets shipped
  // in assets/avatars/. Legacy emoji strings ('⚽', '🏆', …) still render
  // via AvatarImage's text fallback, so v8 profiles keep working.
  TextColumn get avatarEmoji => text().withDefault(const Constant('avatar_01'))();
}

/// Streak state per profile. One row per profile; updated on each app open.
class Streaks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastOpenAt => dateTime().nullable()();
  IntColumn get freezesUsedThisMonth =>
      integer().withDefault(const Constant(0))();
  // 'YYYY-MM' — used to reset freezesUsedThisMonth at month boundary.
  TextColumn get freezesMonthKey =>
      text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {profileId},
      ];
}

/// Earned badges per profile. badgeId is a stable string like
/// 'streak_7', 'completed_BRA', 'first_scan', so listing/migrations are
/// safe even as definitions evolve.
class Badges extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  TextColumn get badgeId => text()();
  DateTimeColumn get earnedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {profileId, badgeId},
      ];
}

class Collections extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  IntColumn get stickerId => integer().references(Stickers, #id)();
  TextColumn get status => text().withDefault(const Constant('missing'))(); // missing|owned|duplicate
  IntColumn get duplicateCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {profileId, stickerId},
      ];
}

class Wishlist extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId => integer().references(Profiles, #id)();
  IntColumn get stickerId => integer().references(Stickers, #id)();
  IntColumn get priority => integer().withDefault(const Constant(1))(); // 1-3
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {profileId, stickerId},
      ];
}
