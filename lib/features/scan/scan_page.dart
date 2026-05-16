import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../pro/paywall_sheet.dart';
import '../pro/pro_service.dart';
import 'ocr_service.dart';
import 'review_detections_sheet.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});
  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  CameraController? _controller;
  bool _initializing = false;
  String? _error;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    if (!OcrService.isSupported) {
      setState(() => _error = 'O scan funciona só no celular (iOS/Android).');
      return;
    }
    // Check daily limit before opening camera
    final pro = ref.read(proProvider);
    if (!pro.canScanOcr) {
      if (mounted) await showPaywall(context, trigger: PaywallContext.ocrLimit);
      return;
    }
    setState(() => _initializing = true);
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(back, ResolutionPreset.high, enableAudio: false);
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() {
        _controller = ctrl;
        _initializing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao abrir câmera: $e';
        _initializing = false;
      });
    }
  }

  Future<void> _capture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    try {
      final shot = await ctrl.takePicture();
      if (!mounted) return;
      await _runOcr(shot.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _runOcr(String imagePath) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final detections = await OcrService.recognize(imagePath);
      if (!mounted) return;
      Navigator.pop(context); // close loading
      if (detections.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhuma figurinha reconhecida. Tente alinhar melhor a página.'),
          ),
        );
        return;
      }
      await showReviewDetectionsSheet(context, ref, detections);
      // Count this scan against the daily quota (no-op for Pro)
      await ref.read(proProvider.notifier).incrementOcrScan();
      // Cleanup temp file
      try {
        await File(imagePath).delete();
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OCR falhou: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trocar / Scan')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (kIsWeb || !OcrService.isSupported) {
      return _OcrUnsupportedView();
    }
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    }
    if (_controller == null) {
      final pro = ref.watch(proProvider);
      return _ScanIntro(
        onStart: _initCamera,
        loading: _initializing,
        scansRemaining: pro.ocrScansRemaining,
        isPro: pro.isActive,
      );
    }
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: CameraPreview(_controller!)),
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Text(
                  'Alinhe a página inteira dentro do quadro',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: FloatingActionButton.large(
            onPressed: _capture,
            child: const Icon(Icons.camera_alt_rounded, size: 36),
          ),
        ),
      ],
    );
  }
}

class _ScanIntro extends StatelessWidget {
  final VoidCallback onStart;
  final bool loading;
  final int scansRemaining;
  final bool isPro;
  const _ScanIntro({
    required this.onStart,
    required this.loading,
    required this.scansRemaining,
    required this.isPro,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_rounded, size: 80, color: AppTheme.seed),
          const SizedBox(height: 24),
          const Text(
            'Scan da página inteira',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tire uma foto da página do álbum físico — o app reconhece os números '
            'das figurinhas e marca automaticamente as que estão coladas.\n\n'
            'Sempre pede confirmação antes de salvar (nada é marcado em silêncio).',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.inkSoft),
          ),
          const SizedBox(height: 24),
          // OCR scan quota indicator
          if (!isPro)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: scansRemaining == 0
                    ? const Color(0xFFFFEBEB)
                    : AppTheme.slotSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    scansRemaining == 0 ? Icons.warning_rounded : Icons.document_scanner_rounded,
                    size: 16,
                    color: scansRemaining == 0 ? Colors.red : AppTheme.inkSoft,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    scansRemaining == 0
                        ? 'Limite diário atingido (3/3) — renova amanhã'
                        : 'Scans hoje: ${3 - scansRemaining}/3 • $scansRemaining restante${scansRemaining == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scansRemaining == 0 ? Colors.red : AppTheme.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          if (!isPro) const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: loading ? null : onStart,
            icon: loading
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.camera_alt_outlined),
            label: Text(loading ? 'Abrindo...' : 'Abrir câmera'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openImport(context),
            icon: const Icon(Icons.file_upload_outlined),
            label: const Text('Importar do Figuritas'),
          ),
        ],
      ),
    );
  }

  void _openImport(BuildContext context) {
    context.push('/import');
  }
}

class _OcrUnsupportedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline_rounded, size: 64, color: AppTheme.inkSoft),
          const SizedBox(height: 16),
          const Text(
            'Scan por câmera só funciona no celular',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Você está rodando a versão web. Instale o APK no Android pra usar OCR.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.inkSoft),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => context.push('/import'),
            child: const Text('Importar do Figuritas (manual)'),
          ),
        ],
      ),
    );
  }
}
