import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Provisioned interstitial unit from Daniel's AdMob account. Debug
// builds still use the Google test ID so we don't burn impressions
// during development.
const _adUnitId = kDebugMode
    ? 'ca-app-pub-3940256099942544/1033173712'
    : 'ca-app-pub-7319987062749834/9304321163';

class InterstitialHelper {
  static InterstitialAd? _ad;
  static int _sessionTaps = 0;
  // Phase 1 (lançamento): conservative — interstitial 1 a cada 30 taps.
  // Bumps to 15 in phase 2 (>1k MAU) and 10 in phase 3 (>10k MAU).
  static const _tapsPerAd = 30;

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
