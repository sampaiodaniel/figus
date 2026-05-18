import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/theme/figus_colors.dart';

const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
const _testMrecAndroid = 'ca-app-pub-3940256099942544/2247696110';
const _testAdaptiveAndroid = 'ca-app-pub-3940256099942544/9214589741';

const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
const _testMrecIos = 'ca-app-pub-3940256099942544/2435281174';
const _testAdaptiveIos = 'ca-app-pub-3940256099942544/2435281174';

String _bannerId() =>
    Platform.isIOS ? _testBannerIos : _testBannerAndroid;
String _mrecId() => Platform.isIOS ? _testMrecIos : _testMrecAndroid;
String _adaptiveId() =>
    Platform.isIOS ? _testAdaptiveIos : _testAdaptiveAndroid;

class BannerGalleryPage extends StatelessWidget {
  const BannerGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Galeria de banners (debug)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GalleryHeader(),
          _BannerSample(
            title: 'Banner 320×50',
            note: 'Padrão · paga 1x · cabe em qualquer aparelho',
            unitId: _bannerId(),
            size: AdSize.banner,
          ),
          _BannerSample(
            title: 'Large Banner 320×100',
            note: 'Dobra a altura · paga ~1.5x · ainda discreto',
            unitId: _bannerId(),
            size: AdSize.largeBanner,
          ),
          _BannerSample(
            title: 'Medium Rectangle 300×250',
            note: 'Bem maior · paga 3-5x · pode soar agressivo',
            unitId: _mrecId(),
            size: AdSize.mediumRectangle,
          ),
          _BannerSample(
            title: 'Full Banner 468×60',
            note: 'Otimizado tablet · meio estreito em celular',
            unitId: _bannerId(),
            size: AdSize.fullBanner,
          ),
          _BannerSample(
            title: 'Leaderboard 728×90',
            note: 'Tablet/desktop · transborda em celular (largura > 720)',
            unitId: _bannerId(),
            size: AdSize.leaderboard,
          ),
          const _AdaptiveAnchoredSample(),
        ],
      ),
    );
  }
}

class _GalleryHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        'Renderizando com Google test ad units. O tamanho exibido é o real '
        '(em dp) — escala conforme densidade da tela do aparelho. Os de '
        'tablet podem cortar se a largura disponível for menor que o banner.',
        style: TextStyle(fontSize: 12, color: context.fc.textMuted, height: 1.4),
      ),
    );
  }
}

class _BannerSample extends StatefulWidget {
  final String title;
  final String note;
  final String unitId;
  final AdSize size;
  const _BannerSample({
    required this.title,
    required this.note,
    required this.unitId,
    required this.size,
  });

  @override
  State<_BannerSample> createState() => _BannerSampleState();
}

class _BannerSampleState extends State<_BannerSample> {
  BannerAd? _ad;
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _ad = BannerAd(
        adUnitId: widget.unitId,
        request: const AdRequest(),
        size: widget.size,
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, err) {
            debugPrint('[Gallery] ${widget.title} failed: ${err.message}');
            if (mounted) setState(() => _error = err.message);
            ad.dispose();
          },
        ),
      )..load();
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          Text(widget.note,
              style: TextStyle(fontSize: 12, color: c.textMuted)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(4),
              color: c.cardAlt,
            ),
            alignment: Alignment.center,
            width: widget.size.width.toDouble(),
            height: widget.size.height.toDouble(),
            child: _error != null
                ? Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('Falhou: $_error',
                        style: const TextStyle(fontSize: 11, color: Colors.red)),
                  )
                : !_loaded || _ad == null
                    ? Text('Carregando…',
                        style: TextStyle(color: c.textMuted, fontSize: 12))
                    : AdWidget(ad: _ad!),
          ),
        ],
      ),
    );
  }
}

class _AdaptiveAnchoredSample extends StatefulWidget {
  const _AdaptiveAnchoredSample();
  @override
  State<_AdaptiveAnchoredSample> createState() => _AdaptiveAnchoredSampleState();
}

class _AdaptiveAnchoredSampleState extends State<_AdaptiveAnchoredSample> {
  BannerAd? _ad;
  bool _loaded = false;
  AdSize? _size;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    final width = MediaQuery.of(context).size.width.truncate();
    final size = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      width,
    );
    if (size == null || !mounted) return;
    _size = size;
    _ad = BannerAd(
      adUnitId: _adaptiveId(),
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('[Gallery] adaptive failed: ${err.message}');
          ad.dispose();
        },
      ),
    )..load();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final s = _size;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Adaptive Anchored ⭐',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          Text(
            'Largura cheia · altura calculada (~50-90) · '
            'paga ~1.2x · recomendado Google'
            '${s != null ? " · agora: ${s.width}×${s.height}" : ""}',
            style: TextStyle(fontSize: 12, color: c.textMuted),
          ),
          const SizedBox(height: 6),
          if (s != null)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(4),
                color: c.cardAlt,
              ),
              alignment: Alignment.center,
              width: s.width.toDouble(),
              height: s.height.toDouble(),
              child: !_loaded || _ad == null
                  ? Text('Carregando…',
                      style: TextStyle(color: c.textMuted, fontSize: 12))
                  : AdWidget(ad: _ad!),
            )
          else
            Text('Calculando tamanho…',
                style: TextStyle(color: c.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
