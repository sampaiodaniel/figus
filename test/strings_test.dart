import 'package:flutter_test/flutter_test.dart';
import 'package:figus/core/strings.dart';

void main() {
  group('plural', () {
    test('singular for count == 1', () {
      expect(plural(1, 'figurinha', 'figurinhas'), 'figurinha');
    });
    test('plural for count == 0', () {
      expect(plural(0, 'cópia', 'cópias'), 'cópias');
    });
    test('plural for count > 1', () {
      expect(plural(5, 'repetida', 'repetidas'), 'repetidas');
    });
    test('plural for very large count', () {
      expect(plural(1058, 'figurinha', 'figurinhas'), 'figurinhas');
    });
  });

  group('countLabel', () {
    test('1 returns singular', () {
      expect(countLabel(1, 'figurinha', 'figurinhas'), '1 figurinha');
    });
    test('0 returns plural', () {
      expect(countLabel(0, 'cópia', 'cópias'), '0 cópias');
    });
    test('5 returns plural', () {
      expect(countLabel(5, 'dia seguido', 'dias seguidos'), '5 dias seguidos');
    });
    test('big returns plural', () {
      expect(countLabel(442, 'figurinha', 'figurinhas'), '442 figurinhas');
    });
  });

  group('countLabelFormatted', () {
    test('1 returns "1 figurinha"', () {
      expect(countLabelFormatted(1, 'figurinha', 'figurinhas'), '1 figurinha');
    });
    test('99 has no separator', () {
      expect(countLabelFormatted(99, 'figurinha', 'figurinhas'),
          '99 figurinhas');
    });
    test('1058 uses dot separator', () {
      expect(countLabelFormatted(1058, 'figurinha', 'figurinhas'),
          '1.058 figurinhas');
    });
    test('1234567 uses two dot separators', () {
      expect(countLabelFormatted(1234567, 'a', 'b'), '1.234.567 b');
    });
  });
}
