import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/figus_colors.dart';
import '../../data/providers.dart';
import 'qr_codec.dart';

/// Two-mode page for in-person trades: show your inventory as a QR code, or
/// scan someone else's. Skips JSON paste entirely.
class TradeQrPage extends ConsumerStatefulWidget {
  /// `mode: 'show'` opens straight on the show tab; `mode: 'scan'` on the
  /// scan tab. Anything else defaults to a toggle the user can flip.
  final String mode;
  const TradeQrPage({super.key, this.mode = 'show'});

  @override
  ConsumerState<TradeQrPage> createState() => _TradeQrPageState();
}

class _TradeQrPageState extends ConsumerState<TradeQrPage> {
  late bool _showing;
  String? _payload;
  String? _error;

  @override
  void initState() {
    super.initState();
    _showing = widget.mode != 'scan';
    if (_showing) _buildPayload();
  }

  Future<void> _buildPayload() async {
    setState(() {
      _payload = null;
      _error = null;
    });
    try {
      final db = ref.read(databaseProvider);
      final encoded = await TradeQrCodec.encodeFromDb(db);
      if (!mounted) return;
      setState(() => _payload = encoded);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Erro ao gerar QR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trocar por QR'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Expanded(child: _ModeButton(
                  label: 'Mostrar meu QR',
                  icon: Icons.qr_code_rounded,
                  active: _showing,
                  onTap: () {
                    setState(() => _showing = true);
                    _buildPayload();
                  },
                )),
                const SizedBox(width: 8),
                Expanded(child: _ModeButton(
                  label: 'Escanear amigo',
                  icon: Icons.qr_code_scanner_rounded,
                  active: !_showing,
                  onTap: () => setState(() => _showing = false),
                )),
              ],
            ),
          ),
        ),
      ),
      body: _showing ? _buildShow(c) : _buildScan(c),
    );
  }

  Widget _buildShow(FigusColors c) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textMuted)),
        ),
      );
    }
    if (_payload == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mostre este QR para um amigo escanear.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.border),
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: QrImageView(
                data: _payload!,
                // Low error correction stretches QR capacity to ~2953 bytes
                // at v40 — important for the long inventory payload.
                version: QrVersions.auto,
                gapless: true,
                errorCorrectionLevel: QrErrorCorrectLevel.L,
                backgroundColor: Colors.white,
                // If the data is somehow STILL too big, the builder runs and
                // shows a useful error inline instead of just a grey box.
                errorStateBuilder: (ctx, err) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Não consegui montar o QR — inventário muito grande.\n'
                      'Use "Comparar" e cole o inventário por texto.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.textMuted, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${_payload!.length} caracteres no QR',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.textMuted,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScan(FigusColors c) {
    return _Scanner(onDetected: (raw) async {
      try {
        final db = ref.read(databaseProvider);
        final friend = await TradeQrCodec.decodeFromQr(raw, db);
        // Navigate to compare page with the decoded inventory. Route param
        // pattern keeps it simple — no Riverpod state to thread.
        if (!mounted) return;
        context.go('/compare', extra: friend);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR não é do Figus: $e')),
        );
      }
    });
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? c.accent.withValues(alpha: 0.15) : c.cardAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? c.accent : c.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: active ? c.accent : c.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? c.accent : c.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Scanner extends StatefulWidget {
  final void Function(String) onDetected;
  const _Scanner({required this.onDetected});

  @override
  State<_Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<_Scanner> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_handled) return;
              for (final code in capture.barcodes) {
                final raw = code.rawValue;
                if (raw == null || raw.isEmpty) continue;
                _handled = true;
                widget.onDetected(raw);
                break;
              }
            },
          ),
        ),
        // Translucent overlay framing the central scan area.
        IgnorePointer(
          child: Container(
            color: Colors.black.withValues(alpha: 0.35),
            alignment: Alignment.center,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Aponte a câmera pro QR do amigo',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
