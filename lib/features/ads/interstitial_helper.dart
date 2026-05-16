import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Replace with a dedicated interstitial unit from AdMob console once live.
const _adUnitId = kDebugMode
    ? 'ca-app-pub-3940256099942544/1033173712' // Google test ID
    : 'ca-app-pub-7319987062749834/1033173712'; // TODO: create interstitial unit

class InterstitialHelper {
  static InterstitialAd? _ad;
  static int _sessionTaps = 0;
  static const _tapsPerAd = 12;

  static void preload() {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    _load();
  }

  static void _load() {
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) {
              a.dispose();
              _ad = null;
              _load(); // Preload next immediately after dismiss
            },
            onAdFailedToShowFullScreenContent: (a, _) {
              a.dispose();
              _ad = null;
            },
          );
        },
        onAdFailedToLoad: (_) {}, // Fail silently
      ),
    );
  }

  /// Call on every sticker tap. Pass [isPro] so Pro users are never interrupted.
  static void onStickerTap({required bool isPro}) {
    if (isPro) return;
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    _sessionTaps++;
    if (_sessionTaps >= _tapsPerAd) {
      _sessionTaps = 0;
      _ad?.show();
    }
  }
}
