// Round-trip tests for the QR payload codec. These don't need a DB —
// they exercise the JSON+gzip+base64 layer in isolation by replaying
// what would have come out of encodeFromDb / what comes back in
// decodeFromQr.

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

/// Replica do encoder de QR sem dependência de banco — usa o mesmo
/// formato v2 ({v,p,o,d,f}) compactado com gzip + base64Url.
String _encode(Map<String, dynamic> slim) {
  final json = jsonEncode(slim);
  final gz = GZipEncoder().encode(utf8.encode(json));
  return 'FIGUS2:${base64Url.encode(gz!)}';
}

Map<String, dynamic> _decode(String s) {
  expect(s.startsWith('FIGUS2:'), true);
  final b64 = s.substring('FIGUS2:'.length);
  final gz = base64Url.decode(b64);
  final raw = GZipDecoder().decodeBytes(gz);
  final json = utf8.decode(raw);
  return jsonDecode(json) as Map<String, dynamic>;
}

void main() {
  group('QR codec roundtrip', () {
    test('encodes minimal payload (empty inventory)', () {
      final slim = {
        'v': 2,
        'p': 'Daniel',
        'o': <String>[],
        'd': <String, int>{},
        'f': <String>[],
      };
      final encoded = _encode(slim);
      final decoded = _decode(encoded);
      expect(decoded['p'], 'Daniel');
      expect(decoded['o'], isEmpty);
    });

    test('encodes typical 400-card inventory and stays under QR cap', () {
      final owned = [
        for (var i = 1; i <= 400; i++)
          'BRA${i % 20 + 1}', // ~20 variants × 20 picks
      ];
      final slim = {
        'v': 2,
        'p': 'Daniel',
        'o': owned,
        'd': {'BRA5': 3, 'ARG10': 2},
        'f': ['BRA', 'ARG'],
      };
      final encoded = _encode(slim);
      // QR v40 binary mode (low EC) caps at 2953 bytes.
      expect(encoded.length, lessThan(2953),
          reason: '400-card inventory must fit in a QR code');
    });

    test('roundtrip preserves all top-level fields', () {
      final slim = {
        'v': 2,
        'p': 'Maria',
        'o': ['BRA1', 'BRA2', 'FWC1'],
        'd': {'BRA1': 2},
        'f': ['BRA'],
      };
      final encoded = _encode(slim);
      final decoded = _decode(encoded);
      expect(decoded['v'], 2);
      expect(decoded['p'], 'Maria');
      expect((decoded['o'] as List).cast<String>(), ['BRA1', 'BRA2', 'FWC1']);
      expect((decoded['d'] as Map)['BRA1'], 2);
      expect((decoded['f'] as List).cast<String>(), ['BRA']);
    });

    test('roundtrip preserves utf-8 in profile name', () {
      final slim = {
        'v': 2,
        'p': 'João da Silva — colecionador 🌟',
        'o': <String>[],
        'd': <String, int>{},
        'f': <String>[],
      };
      final decoded = _decode(_encode(slim));
      expect(decoded['p'], 'João da Silva — colecionador 🌟');
    });

    test('decoder rejects non-Figus prefix', () {
      expect(() => _decode('garbage'), throwsA(isA<TestFailure>()));
    });

    test('gzip reduces typical payload by at least 50%', () {
      // Sanity check: confirms our space-saving claim. JSON with 400
      // owned codes is ~3200 bytes raw, gzipped should be ~1.5KB.
      final owned = [
        for (var i = 1; i <= 400; i++)
          ['BRA', 'ARG', 'GER', 'FRA', 'ESP'][i % 5] + (i % 20 + 1).toString(),
      ];
      final slim = {
        'v': 2,
        'p': 'D',
        'o': owned,
        'd': <String, int>{},
        'f': <String>[],
      };
      final raw = jsonEncode(slim).length;
      final gzLen = GZipEncoder().encode(utf8.encode(jsonEncode(slim)))!.length;
      expect(gzLen, lessThan(raw ~/ 2),
          reason: 'gzip should shrink the JSON to under half its raw size');
    });

    test('large inventory (1058 stickers) still fits with low ECC', () {
      final owned = [
        for (var i = 0; i < 1058; i++) 'S${i.toString().padLeft(4, '0')}',
      ];
      final slim = {
        'v': 2,
        'p': 'Big',
        'o': owned,
        'd': <String, int>{},
        'f': <String>[],
      };
      final encoded = _encode(slim);
      // Even a worst-case full inventory should fit within a v40 QR code
      // at error correction L (2953 bytes binary mode).
      expect(encoded.length, lessThan(2953),
          reason: 'A complete album must fit in a single QR');
    });

    test('empty profile name does not break encoding', () {
      final slim = {
        'v': 2,
        'p': '',
        'o': ['BRA1'],
        'd': <String, int>{},
        'f': <String>[],
      };
      final decoded = _decode(_encode(slim));
      expect(decoded['p'], '');
    });
  });
}
