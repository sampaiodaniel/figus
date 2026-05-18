/// Parses the plain-text export the Figuritas app produces, e.g.:
///
///     Figurinhas App - Lista
///     Eua Méx Can 26
///
///     Repetidas
///     RSA 🇿🇦: 12
///     BIH 🇧🇦: 6, 10, 15
///
/// Used in two places:
///   1. "Importar coleção" page — bulk-mark owned/duplicate from a friend's
///      export shared via WhatsApp.
///   2. "Comparar com amigo" — treat the same paste as a friend's inventory
///      to fuel trade suggestions, no JSON conversion needed.
library;

/// Cheap sniff. Returns true if the text looks like a Figuritas export.
bool isFiguritasFormat(String text) {
  final lower = text.toLowerCase();
  return lower.contains('faltante') || lower.contains('figurinhas app');
}

/// Parses a Figuritas export into (faltantes, repetidas).
/// - `faltantes` is the set of sticker codes the user is missing.
/// - `repetidas` maps sticker code to the count of extra copies.
(Set<String>, Map<String, int>) parseFiguritasExport(String text) {
  final faltantes = <String>{};
  final repetidas = <String, int>{};

  var inFaltantes = false;
  var inRepetidas = false;

  for (final rawLine in text.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;

    final lower = line.toLowerCase();

    if (lower.contains('faltante')) {
      inFaltantes = true;
      inRepetidas = false;
      continue;
    }
    if (lower.contains('repetida')) {
      inFaltantes = false;
      inRepetidas = true;
      continue;
    }
    // Footer / irrelevant lines
    if (lower.contains('baixe') ||
        lower.contains('http') ||
        lower.contains('figurinhas app')) {
      continue;
    }

    if (!inFaltantes && !inRepetidas) continue;

    // Extract team code: first sequence of ASCII letters (2-4 chars).
    final codeMatch = RegExp(r'^([A-Za-z]{2,4})\b').firstMatch(line);
    if (codeMatch == null) continue;
    final teamCode = codeMatch.group(1)!.toUpperCase();

    // Numbers come after ':'.
    final colonIdx = line.indexOf(':');
    if (colonIdx < 0) continue;
    final numbersPart = line.substring(colonIdx + 1);

    for (final part in numbersPart.split(',')) {
      final trimmed = part.trim();
      // Handle "N", "N x2", "Nx2", "N(x2)", "N×2" — Figuritas sometimes
      // encodes quantity when you have multiple copies of the same sticker.
      final m = RegExp(r'^(\d+)(?:\s*[x×(]\s*(\d+))?').firstMatch(trimmed);
      if (m == null) continue;
      final n = int.tryParse(m.group(1)!);
      final count = int.tryParse(m.group(2) ?? '1') ?? 1;
      if (n == null || n < 0) continue;
      final code = n == 0 ? '${teamCode}00' : '$teamCode$n';
      if (inFaltantes) {
        faltantes.add(code);
      } else {
        repetidas[code] = (repetidas[code] ?? 0) + count;
      }
    }
  }

  return (faltantes, repetidas);
}
