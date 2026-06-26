/// Locale-tolerant text helpers shared by search and voice-command matching.
///
/// Speech recognition — especially Arabic and Hebrew — adds vowel diacritics,
/// tatweel, and bidirectional control characters and uses different letter
/// forms, so a raw dictated string rarely equals the stored keyword literally.
/// Normalizing both sides (and allowing a small edit distance) lets matches
/// succeed despite those variations.
library;

/// Strips diacritics / control marks and unifies common letter variants, then
/// lowercases and collapses whitespace.
String normalizeForMatch(String input) {
  final buffer = StringBuffer();
  for (var ch in input.runes) {
    // Arabic diacritics (tashkeel) and Hebrew niqqud / cantillation marks.
    if ((ch >= 0x0610 && ch <= 0x061A) ||
        (ch >= 0x064B && ch <= 0x065F) ||
        ch == 0x0670 ||
        (ch >= 0x06D6 && ch <= 0x06ED) ||
        ch == 0x0640 || // Arabic tatweel
        (ch >= 0x0591 && ch <= 0x05BD) ||
        ch == 0x05BF ||
        ch == 0x05C1 ||
        ch == 0x05C2 ||
        ch == 0x05C4 ||
        ch == 0x05C5 ||
        ch == 0x05C7) {
      continue;
    }
    // Bidirectional control characters.
    if (ch == 0x200E ||
        ch == 0x200F ||
        ch == 0x061C ||
        (ch >= 0x202A && ch <= 0x202E) ||
        (ch >= 0x2066 && ch <= 0x2069)) {
      continue;
    }
    // Unify Arabic alef variants (آ أ إ → ا) and alef-maqsura (ى → ي).
    if (ch == 0x0622 || ch == 0x0623 || ch == 0x0625) ch = 0x0627;
    if (ch == 0x0649) ch = 0x064A;
    // Unify taa-marbuta (ة → ه), a frequent recognizer/spelling variance.
    if (ch == 0x0629) ch = 0x0647;
    buffer.writeCharCode(ch);
  }
  return buffer.toString().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// True when a speech_to_text error message represents a benign silence /
/// no-match timeout (the user simply hasn't spoken) rather than a real engine
/// failure. iOS reports these as "permanent", so both the home dictation and
/// the protocol Free Mode treat them as transient and re-arm instead of
/// surfacing an "unavailable" error.
bool isTransientSpeechError(String errorMsg) {
  final msg = errorMsg.toLowerCase();
  return msg.contains('no_match') ||
      msg.contains('speech_timeout') ||
      msg.contains('no_speech') ||
      msg.contains('retry') ||
      msg.contains('busy');
}

/// Levenshtein edit distance between two strings (insertions, deletions,
/// substitutions). Used to tolerate near-miss recognitions like ق↔ك.
int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  var prev = List<int>.generate(b.length + 1, (i) => i);
  var curr = List<int>.filled(b.length + 1, 0);

  for (var i = 0; i < a.length; i++) {
    curr[0] = i + 1;
    for (var j = 0; j < b.length; j++) {
      final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
      curr[j + 1] = [
        curr[j] + 1, // insertion
        prev[j + 1] + 1, // deletion
        prev[j] + cost, // substitution
      ].reduce((m, e) => e < m ? e : m);
    }
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[b.length];
}

/// Returns true if [keyword] matches [text] as a WHOLE word (or, for a
/// multi-word keyword, as a contiguous phrase) — never as a substring inside a
/// larger word. Substring matching caused false commands like "I broke my arm"
/// triggering "ok"→Next, which is dangerous in an emergency flow.
///
/// For non-ASCII keywords (Arabic/Hebrew), where on-device recognition is
/// noisier, a near-miss token within [maxEdits] edit distance also matches
/// (e.g. ق↔ك). ASCII (English) keywords require an exact token by default to
/// avoid pairs like "fast"~"last" colliding — which matters for voice commands
/// where a false "next" is dangerous.
///
/// Set [fuzzyAscii] to also tolerate near-miss ASCII tokens (typos like
/// "chocking"→"choking"). This is safe for the home search box — a wrong tile
/// is harmless — but must stay off for command matching. It only applies to
/// keywords of length >= 5, since short English words collide too easily.
bool fuzzyContains(
  String text,
  String keyword, {
  int maxEdits = 1,
  bool fuzzyAscii = false,
}) {
  if (keyword.isEmpty) return false;
  // Multi-word keyword (e.g. "go back"): match as a contiguous phrase.
  if (keyword.contains(' ')) return text.contains(keyword);

  final isAscii = keyword.codeUnits.every((c) => c < 128);
  final fuzzyEligible = isAscii
      ? (fuzzyAscii && keyword.length >= 5)
      : keyword.length >= 4;
  for (final token in text.split(' ')) {
    if (token == keyword) return true;
    if (fuzzyEligible &&
        token.length >= 3 &&
        levenshtein(token, keyword) <= maxEdits) {
      return true;
    }
  }
  return false;
}
