import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase for last-write-wins collection sync.
/// All public methods are fire-and-forget safe — they catch their own errors.
class SyncRepo {
  static const _table = 'collection_entries';

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isSignedIn => _client?.auth.currentUser != null;
  String? get userId => _client?.auth.currentUser?.id;
  String? get userEmail => _client?.auth.currentUser?.email;

  /// Push a single sticker state change to Supabase.
  /// No-op when signed out or on web (CORS) or on error.
  Future<void> pushEntry(String stickerNumber, String status, int dupCount) async {
    if (!isSignedIn) return;
    final uid = userId!;
    try {
      await _client!.from(_table).upsert({
        'user_id': uid,
        'sticker_number': stickerNumber,
        'status': status,
        'duplicate_count': dupCount,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,sticker_number');
    } catch (e) {
      debugPrint('[SyncRepo] pushEntry error: $e');
    }
  }

  /// Bulk-push many entries in a single HTTP round-trip. Returns true on
  /// success. Used by the initial-sync flow so we don't fire 400+ network
  /// requests sequentially.
  Future<bool> pushEntriesBulk(
      List<({String stickerNumber, String status, int dupCount})> entries) async {
    if (!isSignedIn || entries.isEmpty) return false;
    final uid = userId!;
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await _client!.from(_table).upsert(
        entries
            .map((e) => {
                  'user_id': uid,
                  'sticker_number': e.stickerNumber,
                  'status': e.status,
                  'duplicate_count': e.dupCount,
                  'updated_at': now,
                })
            .toList(),
        onConflict: 'user_id,sticker_number',
      );
      return true;
    } catch (e) {
      debugPrint('[SyncRepo] pushEntriesBulk error: $e');
      return false;
    }
  }

  /// Pull all entries for the current user.
  /// Returns map of stickerNumber → (status, dupCount).
  ///
  /// Paginates internally to bypass Supabase's default 1000-row cap, so
  /// users with 1000+ collection entries get everything back instead of
  /// silently losing the tail.
  Future<Map<String, ({String status, int dupCount})>> pullAll() async {
    if (!isSignedIn) return {};
    const pageSize = 1000;
    final result = <String, ({String status, int dupCount})>{};
    try {
      // Force-refresh the session before querying. A stale token still
      // counts as "signed in" client-side (currentUser != null), but RLS
      // rejects the query server-side because auth.uid() comes back null —
      // and Supabase returns 0 rows instead of an error, which is why the
      // user sees a "successful" sync that brought nothing. Refreshing
      // sets a valid Bearer for the upcoming select.
      try {
        await _client!.auth.refreshSession().timeout(const Duration(seconds: 15));
      } catch (e) {
        debugPrint('[SyncRepo] pullAll refreshSession failed (continuing): $e');
      }
      var offset = 0;
      while (true) {
        // Hard timeout per page — without this, the spinner can spin
        // forever if Supabase happens to be flaky on a given device. 30s
        // is plenty for 1k rows in any country.
        final rows = await _client!
            .from(_table)
            .select('sticker_number,status,duplicate_count')
            .eq('user_id', userId!)
            // Deterministic order is REQUIRED for pagination — without it
            // Postgres can return overlapping/missing rows across pages and
            // the user has to sync twice to converge.
            .order('sticker_number')
            .range(offset, offset + pageSize - 1)
            .timeout(const Duration(seconds: 30));
        if (rows.isEmpty) break;
        for (final r in rows) {
          result[r['sticker_number'] as String] = (
            status: r['status'] as String,
            dupCount: (r['duplicate_count'] as num).toInt(),
          );
        }
        if (rows.length < pageSize) break;
        offset += pageSize;
      }
      return result;
    } catch (e) {
      debugPrint('[SyncRepo] pullAll error: $e');
      // Re-throw so the caller can show a meaningful error instead of an
      // empty map masquerading as "no data on server". The few callers that
      // truly want silent failure (auto-sync observer, the cloud icon in
      // the progress card) already wrap this in their own try/catch.
      rethrow;
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// Send OTP to email. Returns error message or null on success.
  Future<String?> sendOtp(String email) async {
    try {
      await _client!.auth.signInWithOtp(email: email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Verify OTP code. Returns error message or null on success.
  ///
  /// Tries OtpType.email first (standard OTP flow). If that fails with a
  /// "token expired" error, retries with OtpType.signup — this is the path
  /// for first-time users whose account was created in unconfirmed state.
  /// The dual attempt makes the auth flow resilient to whichever email
  /// template Supabase happens to send.
  Future<String?> verifyOtp(String email, String token) async {
    Object? lastError;
    String? lastErrorCode;
    for (final type in const [OtpType.email, OtpType.signup, OtpType.magiclink]) {
      try {
        await _client!.auth.verifyOTP(
          email: email,
          token: token,
          type: type,
        );
        return null;
      } on AuthException catch (e) {
        lastError = e;
        lastErrorCode = e.code;
        debugPrint('[SyncRepo] verifyOtp type=$type failed: ${e.code} / ${e.message}');
        // If error isn't related to the OTP type, no point trying others
        if (e.code == 'invalid_credentials' ||
            e.code == 'user_not_found') {
          break;
        }
      } catch (e) {
        lastError = e;
        debugPrint('[SyncRepo] verifyOtp type=$type unknown error: $e');
      }
    }
    if (lastError is AuthException) {
      final msg = (lastError as AuthException).message;
      return lastErrorCode != null ? '$msg [$lastErrorCode]' : msg;
    }
    return lastError?.toString();
  }

  Future<void> signOut() async {
    try {
      await _client?.auth.signOut();
    } catch (e) {
      debugPrint('[SyncRepo] signOut error: $e');
    }
  }

  // ── User settings (theme, favorites, profile name) ───────────────────────
  //
  // We piggyback on Supabase Auth's `user_metadata` JSON column instead of
  // creating a dedicated table. Zero migration cost and the data follows the
  // user automatically across devices via the session token.

  /// Merge-push user settings to Supabase. Only the fields you pass are
  /// updated; the rest of user_metadata is preserved.
  Future<bool> pushUserSettings({
    String? theme,
    List<String>? favoriteNations,
    String? profileName,
    String? avatar,
  }) async {
    if (!isSignedIn) return false;
    try {
      final current = _client!.auth.currentUser?.userMetadata ?? const {};
      final merged = <String, dynamic>{...current};
      if (theme != null) merged['theme'] = theme;
      if (favoriteNations != null) merged['favorite_nations'] = favoriteNations;
      if (profileName != null) merged['profile_name'] = profileName;
      if (avatar != null) merged['avatar'] = avatar;
      merged['settings_updated_at'] =
          DateTime.now().toUtc().toIso8601String();
      await _client!.auth.updateUser(UserAttributes(data: merged));
      return true;
    } catch (e) {
      debugPrint('[SyncRepo] pushUserSettings error: $e');
      return false;
    }
  }

  /// Fetch fresh user settings from the server. Issues a network call to
  /// /auth/v1/user so we get up-to-date metadata (cached version may be
  /// stale if another device updated it after this session started).
  Future<
      ({
        String? theme,
        List<String>? favoriteNations,
        String? profileName,
        String? avatar,
      })> pullUserSettings() async {
    const empty = (
      theme: null,
      favoriteNations: null,
      profileName: null,
      avatar: null,
    );
    if (!isSignedIn) return empty;
    try {
      final res = await _client!.auth.getUser();
      final meta = res.user?.userMetadata;
      if (meta == null) return empty;
      final favRaw = meta['favorite_nations'];
      final favs = favRaw is List
          ? favRaw.map((e) => e.toString()).toList()
          : null;
      return (
        theme: meta['theme'] as String?,
        favoriteNations: favs,
        profileName: meta['profile_name'] as String?,
        avatar: meta['avatar'] as String?,
      );
    } catch (e) {
      debugPrint('[SyncRepo] pullUserSettings error: $e');
      return empty;
    }
  }

  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();
}

final syncRepoProvider = Provider<SyncRepo>((_) => SyncRepo());
