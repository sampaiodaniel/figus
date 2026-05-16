import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:share_plus/share_plus.dart';

import '../../domain/models/album_view_models.dart';
import 'share_card.dart';

class ShareService {
  /// Renders [ShareCard] off-screen, captures it as PNG and opens the
  /// platform share sheet (WhatsApp shows up automatically).
  static Future<void> shareProgressCard(
    BuildContext context, {
    required AlbumStats stats,
    required String albumName,
    required String profileName,
  }) async {
    try {
      // Pre-load icon bytes so Image.memory works inside the off-screen tree.
      Uint8List? iconBytes;
      try {
        final data = await rootBundle.load('assets/figus-icon-512.png');
        iconBytes = data.buffer.asUint8List();
      } catch (_) {
        // asset unavailable — card falls back to the 'F' letter
      }

      final pngBytes = await _captureWidget(
        ShareCard(
            stats: stats,
            albumName: albumName,
            profileName: profileName,
            iconBytes: iconBytes),
        const Size(1080, 1080),
      );

      final caption = 'Acompanhe minha coleção do $albumName no Figus 📚⚽\n'
          '${(stats.percentComplete * 100).toStringAsFixed(0)}% completo · '
          'me faltam ${stats.missing} · tenho ${stats.duplicates} repetidas pra trocar.';

      await Share.shareXFiles(
        [XFile.fromData(pngBytes, name: 'figus.png', mimeType: 'image/png')],
        text: caption,
      );
    } catch (e, st) {
      debugPrint('Share failed: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar: $e')),
        );
      }
    }
  }

  /// Share a plain text list (missing or duplicates) — friendlier for WhatsApp text.
  static Future<void> shareTextList({
    required String title,
    required List<StickerView> stickers,
  }) async {
    final lines = StringBuffer()..writeln(title)..writeln();
    final byNation = <String, List<StickerView>>{};
    for (final s in stickers) {
      final key = s.nationCode ?? 'FWC';
      byNation.putIfAbsent(key, () => []).add(s);
    }
    for (final entry in byNation.entries) {
      final nums = entry.value.map((s) => s.number.replaceAll(RegExp(r'^[A-Z]+'), '')).join(', ');
      lines.writeln('${entry.key}: $nums');
    }
    lines..writeln()..writeln('— gerado pelo Figus 📚');
    await Share.share(lines.toString());
  }

  static Future<Uint8List> _captureWidget(Widget widget, Size logicalSize) async {
    final repaintBoundary = RenderRepaintBoundary();
    const pixelRatio = 1.0;
    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    final renderView = RenderView(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
      child: RenderPositionedBox(alignment: Alignment.center, child: repaintBoundary),
      configuration: ViewConfiguration(
        physicalConstraints: BoxConstraints.tight(logicalSize) * pixelRatio,
        logicalConstraints: BoxConstraints.tight(logicalSize),
        devicePixelRatio: pixelRatio,
      ),
    );

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(textDirection: TextDirection.ltr, child: widget),
    ).attachToRenderTree(buildOwner);

    buildOwner
      ..buildScope(rootElement)
      ..finalizeTree();
    pipelineOwner
      ..flushLayout()
      ..flushCompositingBits()
      ..flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
