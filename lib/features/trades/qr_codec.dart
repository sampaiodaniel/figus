import 'dart:convert';

import 'package:archive/archive.dart';

/// Compact encoder/decoder for an inventory snapshot meant to fit inside a
/// QR code. JSON is gzipped and then base64url-encoded so the resulting
/// string is ASCII-safe for QR's binary mode.
class TradeQrCodec {
  /// Magic prefix so the scanner can tell a Figus QR from any other QR.
  static const _prefix = 'FIGUS1:';

  /// Encodes [inventory] (the same shape produced by `InventoryCodec.exportMine`)
  /// into a QR-friendly string.
  static String encode(Map<String, dynamic> inventory) {
    // Strip the `nations` map — it's deterministically derivable from the
    // sticker code on the receiving device (their seed has the same data),
    // and dropping it saves ~30% of the payload size.
    final slim = Map<String, dynamic>.from(inventory);
    slim.remove('nations');
    final json = jsonEncode(slim);
    final gz = GZipEncoder().encode(utf8.encode(json));
    return _prefix + base64Url.encode(gz!);
  }

  /// Decodes a string produced by [encode] back into the inventory JSON.
  /// Throws [FormatException] if the input isn't a valid Figus QR payload.
  static Map<String, dynamic> decode(String input) {
    if (!input.startsWith(_prefix)) {
      throw const FormatException('Não é um QR de troca do Figus');
    }
    final b64 = input.substring(_prefix.length);
    final gz = base64Url.decode(b64);
    final raw = GZipDecoder().decodeBytes(gz);
    final json = utf8.decode(raw);
    return jsonDecode(json) as Map<String, dynamic>;
  }
}
