import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob serves no real ads in debug mode for the app's own ID, so we swap
/// in Google's adaptive-banner test units when running under flutter run.
/// The adaptive test IDs serve creatives that fill the requested AdSize —
/// the standard banner test IDs always return 320x50, masking the real
/// adaptive sizing on tablets.
const _prodBannerAdUnitId = 'ca-app-pub-7319987062749834/4232418305';
const _testAdaptiveBannerUnitIdAndroid = 'ca-app-pub-3940256099942544/9214589741';
const _testAdaptiveBannerUnitIdIos = 'ca-app-pub-3940256099942544/2435281174';

String _bannerAdUnitId() {
  if (kDebugMode) {
    return Platform.isIOS ? _testAdaptiveBannerUnitIdIos : _testAdaptiveBannerUnitIdAndroid;
  }
  return _prodBannerAdUnitId;
}

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _loadStarted = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // Defer to post-frame so MediaQuery is available for the
      // adaptive-banner size calculation.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAd();
      });
    }
  }

  Future<void> _loadAd() async {
    if (_loadStarted) return;
    _loadStarted = true;
    // Full banner (468x60) — Daniel's preferred slot. Cabe bem em tablet
    // e em telas de celular acima de ~480dp; pra device mais estreito o
    // wrapping container já clampa via FittedBox fora.
    final AdSize size = AdSize.fullBanner;
    final ad = BannerAd(
      adUnitId: _bannerAdUnitId(),
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          // Log so we can tell NO_FILL apart from misconfigured unit IDs.
          debugPrint('[BannerAd] failed: code=${err.code} domain=${err.domain} msg=${err.message}');
          ad.dispose();
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
