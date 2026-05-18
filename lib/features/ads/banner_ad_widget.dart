import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob serves no real ads in debug mode for the app's own ID, so we swap
/// in Google's adaptive-banner test units when running under flutter run.
/// The adaptive test IDs serve creatives that fill the requested AdSize —
/// the standard banner test IDs always return 320x50, masking the real
/// adaptive sizing on tablets.
// Provisioned banner unit from Daniel's AdMob account (Android only; iOS
// will need a separate unit when the app ships there).
const _prodBannerAdUnitId = 'ca-app-pub-7319987062749834/4243566179';
const _testBannerUnitIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
const _testBannerUnitIdIos = 'ca-app-pub-3940256099942544/2934735716';

String _bannerAdUnitId() {
  if (kDebugMode) {
    return Platform.isIOS ? _testBannerUnitIdIos : _testBannerUnitIdAndroid;
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
    // Anchored adaptive banner: pega largura cheia do device e altura
    // auto (~50-90 px). No tablet vira ~728x90, em celular ~360x50.
    // Substitui o fullBanner 468x60 fixo que dava NO_FILL em devices
    // estreitos e teto baixo em tablet.
    final width = MediaQuery.of(context).size.width.truncate();
    final adaptive = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      width,
    );
    final AdSize size = adaptive ?? AdSize.banner;
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
