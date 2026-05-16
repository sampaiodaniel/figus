import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

import '../domain/models/album_view_models.dart';
import 'db/database.dart';
import 'repos/album_repo.dart';
import 'repos/collection_repo.dart';
import 'repos/profile_repo.dart';
import 'repos/sync_repo.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final albumRepoProvider = Provider<AlbumRepo>((ref) => AlbumRepo(ref.watch(databaseProvider)));
final collectionRepoProvider = Provider<CollectionRepo>((ref) => CollectionRepo(
  ref.watch(databaseProvider),
  sync: ref.watch(syncRepoProvider),
));
final profileRepoProvider = Provider<ProfileRepo>((ref) => ProfileRepo(ref.watch(databaseProvider)));

/// Bumped manually after every mutation to invalidate album/stats queries.
final collectionVersionProvider = StateProvider<int>((_) => 0);

final albumFilterProvider = StateProvider<AlbumFilter>((_) => AlbumFilter.all);
final albumSearchProvider = StateProvider<String>((_) => '');

final albumSectionsProvider = FutureProvider.autoDispose<List<AlbumSection>>((ref) async {
  ref.watch(collectionVersionProvider);
  final repo = ref.watch(albumRepoProvider);
  final filter = ref.watch(albumFilterProvider);
  final search = ref.watch(albumSearchProvider);
  return repo.loadSections(filter: filter, search: search.isEmpty ? null : search);
});

final albumStatsProvider = FutureProvider.autoDispose<AlbumStats>((ref) async {
  ref.watch(collectionVersionProvider);
  final repo = ref.watch(albumRepoProvider);
  return repo.loadStats();
});

final profilesListProvider = FutureProvider.autoDispose((ref) async {
  ref.watch(collectionVersionProvider);
  return ref.watch(profileRepoProvider).all();
});

/// Emits Supabase auth state changes; used to reactively rebuild sync UI.
final syncAuthStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(syncRepoProvider).authStateChanges;
});
