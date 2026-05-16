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

  /// Pull all entries for the current user.
  /// Returns map of stickerNumber → (status, dupCount).
  Future<Map<String, ({String status, int dupCount})>> pullAll() async {
    if (!isSignedIn) return {};
    try {
      final rows = await _client!
          .from(_table)
          .select('sticker_number,status,duplicate_count')
          .eq('user_id', userId!);
      return {
        for (final r in rows)
          r['sticker_number'] as String: (
            status: r['status'] as String,
            dupCount: (r['duplicate_count'] as num).toInt(),
          ),
      };
    } catch (e) {
      debugPrint('[SyncRepo] pullAll error: $e');
      return {};
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
  Future<String?> verifyOtp(String email, String token) async {
    try {
      await _client!.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
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
