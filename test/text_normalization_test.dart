import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_angel/core/text_normalization.dart';

void main() {
  group('normalizeForMatch', () {
    test('lowercases and trims so search is case-insensitive', () {
      expect(normalizeForMatch('  ChOcKiNg  '), 'chocking');
    });
  });

  group('fuzzyContains — home search (fuzzyAscii: true)', () {
    test('tolerates an English typo within one edit', () {
      // The reported case: "chocking" should resolve to "choking" locally.
      expect(fuzzyContains('chocking', 'choking', fuzzyAscii: true), isTrue);
    });

    test('matches a typo inside a phrase', () {
      expect(
        fuzzyContains('someone is chocking', 'choking', fuzzyAscii: true),
        isTrue,
      );
    });

    test('still matches the exact word', () {
      expect(fuzzyContains('choking', 'choking', fuzzyAscii: true), isTrue);
    });

    test('does not match clearly different words', () {
      expect(fuzzyContains('burns', 'choking', fuzzyAscii: true), isFalse);
      expect(fuzzyContains('breathe', 'choking', fuzzyAscii: true), isFalse);
    });

    test('short keywords (< 5 chars) are not fuzzy-matched', () {
      // "cpr" is too short to fuzzy-match safely.
      expect(fuzzyContains('cor', 'cpr', fuzzyAscii: true), isFalse);
    });
  });

  group('fuzzyContains — voice commands (default, fuzzyAscii: false)', () {
    test('English stays exact-only so commands are not misfired', () {
      // Must remain false: a fuzzy "next" in a protocol flow is dangerous.
      expect(fuzzyContains('chocking', 'choking'), isFalse);
      expect(fuzzyContains('text', 'next'), isFalse);
    });

    test('non-ASCII keywords keep their built-in fuzziness', () {
      // Arabic near-miss (one substituted letter, ر→ز) still matches without
      // the flag — recognition of Arabic/Hebrew is noisier on-device.
      expect(fuzzyContains('اختباز', 'اختبار'), isTrue);
    });
  });
}
