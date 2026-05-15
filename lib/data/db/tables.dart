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
