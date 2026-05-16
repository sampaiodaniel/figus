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
      var offset = 0;
      while (true) {
        final rows = await _client!
            .from(_table)
            .select('sticker_number,status,duplicate_count')
            .eq('user_id', userId!)
            .range(offset, offset + pageSize - 1);
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
      return result;
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

  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();
}

final syncRepoProvider = Provider<SyncRepo>((_) => SyncRepo());
