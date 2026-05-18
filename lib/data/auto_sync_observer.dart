import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/pro/theme_service.dart';
import '../features/streak/streak_service.dart';
import 'providers.dart';
import 'repos/sync_repo.dart';

/// Listens to app lifecycle and triggers a pull-only sync whenever the app
/// resumes — so users don't need to remember to tap "Sincronizar". Throttled
/// to once every 30s to keep traffic sane.
///
/// Wrap the app body with [AutoSyncObserver] once, near the root.
class AutoSyncObserver extends ConsumerStatefulWidget {
  final Widget child;
  const AutoSyncObserver({super.key, required this.child});

  @override
  ConsumerState<AutoSyncObserver> createState() => _AutoSyncObserverState();
}

class _AutoSyncObserverState extends ConsumerState<AutoSyncObserver>
    with WidgetsBindingObserver {
  DateTime? _lastSyncedAt;
  static const _throttle = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial cold-start: register the daily open + trigger a sync pull
    // in parallel. Both are non-blocking.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordStreakOpen();
      _maybeSync();
    });
  }

  Future<void> _recordStreakOpen() async {
    try {
      final pid = (await ref.read(profileRepoProvider).active()).id;
      await ref.read(streakServiceProvider).recordOpen(pid);
      if (mounted) {
        ref.read(streakVersionProvider.notifier).state++;
      }
    } catch (_) {
      // Silent — streak isn't critical to app function.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeSync();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // Flush debounced sticker pushes before the OS may freeze us.
      // ignore: discarded_futures
      ref.read(collectionRepoProvider).flushPendingPushes();
    }
  }

  Future<void> _maybeSync() async {
    final now = DateTime.now();
    if (_lastSyncedAt != null && now.difference(_lastSyncedAt!) < _throttle) {
      return; // Too soon; the user just opened, then re-opened. Skip.
    }
    final sync = ref.read(syncRepoProvider);
    if (!sync.isSignedIn) return;
    _lastSyncedAt = now;
    try {
      final repo = ref.read(collectionRepoProvider);
      // pullAll now rethrows on error; the outer catch silences for the
      // auto-sync UX (the user-triggered "Sincronizar agora" path surfaces
      // errors via SnackBar instead).
      final remote = await sync.pullAll();
      final settings = await sync.pullUserSettings();
      if (remote.isNotEmpty) {
        await repo.applyRemoteEntries(remote);
      }
      // Apply settings silently — don't bounce them back to cloud.
      if (settings.theme != null) {
        final seed = AppThemeSeed.values
            .where((t) => t.name == settings.theme)
            .firstOrNull;
        if (seed != null) {
          await ref.read(themeSeedProvider.notifier)
              .set(seed, pushToCloud: false);
        }
      }
      if (settings.favoriteNations != null) {
        await ref.read(profileRepoProvider).setFavoriteNations(
              settings.favoriteNations!.toSet(),
              pushToCloud: false,
            );
      }
      if (settings.profileName != null &&
          settings.profileName!.trim().isNotEmpty) {
        final active = await ref.read(profileRepoProvider).active();
        if (active.name != settings.profileName) {
          await ref.read(profileRepoProvider).rename(
                active.id,
                settings.profileName!,
                pushToCloud: false,
              );
        }
      }
      if (settings.avatar != null && settings.avatar!.isNotEmpty) {
        await ref.read(profileRepoProvider)
            .setAvatarEmoji(settings.avatar!, pushToCloud: false);
      }
      if (mounted) {
        ref.read(collectionVersionProvider.notifier).state++;
        ref.invalidate(albumStatsProvider);
        ref.invalidate(albumSectionsProvider);
        ref.invalidate(profilesListProvider);
      }
    } catch (_) {
      // Silent — auto-sync should never bother the user with errors.
      // Manual "Sincronizar agora" surfaces them when relevant.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
