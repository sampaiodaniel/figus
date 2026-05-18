/// Tiny helpers for Portuguese pluralization. Centralized so every "X
/// figurinha/figurinhas" string reads the same and we have a single
/// place to fix grammar bugs.

/// Returns the singular or plural form depending on [count]. Uses [one]
/// when count == 1 and [many] otherwise.
String plural(int count, String one, String many) => count == 1 ? one : many;

/// Formats "N <word>" with the right grammatical number.
///   countLabel(1, 'figurinha', 'figurinhas') → '1 figurinha'
///   countLabel(5, 'figurinha', 'figurinhas') → '5 figurinhas'
String countLabel(int count, String singular, String plural) =>
    '$count ${count == 1 ? singular : plural}';

/// Same as [countLabel] but with thousand separators in pt-BR style
/// (dots). Useful for big totals like "1.058 figurinhas" so the number
/// reads naturally instead of "1058".
String countLabelFormatted(int count, String singular, String plural) {
  final formatted = _formatThousands(count);
  return '$formatted ${count == 1 ? singular : plural}';
}

String _formatThousands(int n) {
  final s = n.toString();
  if (s.length <= 3) return s;
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}
