import 'package:flutter_test/flutter_test.dart';
import 'package:figus/features/import/figuritas_parser.dart';

void main() {
  group('isFiguritasFormat', () {
    test('matches a real share-as-text', () {
      const text = '''
Figurinhas App - Lista
Eua Méx Can 26

Repetidas
RSA 🇿🇦: 12
BIH 🇧🇦: 6, 10, 15

Baixe o app
https://www.figuritas.app/pt/baixar
''';
      expect(isFiguritasFormat(text), true);
    });

    test('matches when only the Faltantes header is present', () {
      const text = 'Faltantes\nBRA: 1, 2, 3';
      expect(isFiguritasFormat(text), true);
    });

    test('rejects an unrelated JSON payload', () {
      expect(isFiguritasFormat('{"v":1,"profile":"x"}'), false);
    });

    test('rejects plain code lists', () {
      expect(isFiguritasFormat('BRA1, BRA2, BRA3'), false);
    });
  });

  group('parseFiguritasExport', () {
    test("parses Daniel's pasted example", () {
      const text = '''
Figurinhas App - Lista
Eua Méx Can 26

Repetidas
RSA 🇿🇦: 12
BIH 🇧🇦: 6, 10, 15
TUN 🇹🇳: 17
NZL 🇳🇿: 5
CPV 🇨🇻: 2, 6, 10, 15
URU 🇺🇾: 6
JOR 🇯🇴: 15
UZB 🇺🇿: 5, 15, 19
ENG 🏴󠁧󠁢󠁥󠁮󠁧󠁿: 2

Baixe o app
https://www.figuritas.app/pt/baixar
''';
      final (faltantes, repetidas) = parseFiguritasExport(text);
      expect(faltantes, isEmpty,
          reason: 'this share only includes Repetidas');
      expect(repetidas['RSA12'], 1);
      expect(repetidas['BIH6'], 1);
      expect(repetidas['BIH10'], 1);
      expect(repetidas['BIH15'], 1);
      expect(repetidas['CPV2'], 1);
      expect(repetidas['ENG2'], 1);
      // 1 + 3 + 1 + 1 + 4 + 1 + 1 + 3 + 1 = 16 distinct sticker codes.
      expect(repetidas.length, 16);
    });

    test('parses multiple copies via "x2" notation', () {
      const text = '''
Figurinhas App
Repetidas
BRA: 5 x2, 10
''';
      final (_, repetidas) = parseFiguritasExport(text);
      expect(repetidas['BRA5'], 2);
      expect(repetidas['BRA10'], 1);
    });

    test('parses sticker 0 as CODE00', () {
      const text = '''
Figurinhas App
Repetidas
FWC: 0, 1
''';
      final (_, repetidas) = parseFiguritasExport(text);
      expect(repetidas.containsKey('FWC00'), true);
      expect(repetidas.containsKey('FWC1'), true);
    });

    test('parses both Faltantes and Repetidas sections', () {
      const text = '''
Faltantes
BRA: 1, 2, 3
Repetidas
ARG: 10
''';
      final (faltantes, repetidas) = parseFiguritasExport(text);
      expect(faltantes, {'BRA1', 'BRA2', 'BRA3'});
      expect(repetidas, {'ARG10': 1});
    });

    test('skips empty lines and footer URLs', () {
      const text = '''
Figurinhas App
Repetidas

BRA: 5

Baixe o app
https://example.com
''';
      final (_, repetidas) = parseFiguritasExport(text);
      expect(repetidas, {'BRA5': 1});
    });

    test('handles lines with no colon gracefully', () {
      const text = '''
Repetidas
This is junk
BRA: 1
Also junk no colon
''';
      final (_, repetidas) = parseFiguritasExport(text);
      expect(repetidas, {'BRA1': 1});
    });

    test('returns empty for unrelated text', () {
      const text = 'O céu é azul e a grama é verde.';
      final (faltantes, repetidas) = parseFiguritasExport(text);
      expect(faltantes, isEmpty);
      expect(repetidas, isEmpty);
    });
  });
}
