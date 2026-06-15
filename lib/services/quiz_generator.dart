import 'dart:math';

/// Source material for one quiz question: a step's title and instruction,
/// taken verbatim from the localized protocol JSON.
typedef QuizStep = ({String title, String instruction});

enum QuizQuestionType {
  /// "Which of these is step N?"
  whichStep,

  /// "Which step comes right after: [anchorTitle]?"
  comesAfter,

  /// "Which step does this instruction belong to?" (shows [instruction])
  instructionMatch,
}

/// Result medal tiers for a finished quiz.
enum QuizMedal {
  gold,
  silver,
  bronze;

  static QuizMedal of(int score, int total) {
    if (total > 0 && score >= total) return QuizMedal.gold;
    if (total > 0 && score / total >= 0.75) return QuizMedal.silver;
    return QuizMedal.bronze;
  }
}

/// A multiple-choice question whose prompt and options are built exclusively
/// from existing step titles and instructions — the quiz never introduces new
/// medical content.
class QuizQuestion {
  final QuizQuestionType type;

  /// 1-based number of the step the correct answer refers to.
  final int stepNumber;

  /// For [QuizQuestionType.comesAfter]: the preceding step's title.
  final String? anchorTitle;

  /// For [QuizQuestionType.instructionMatch]: the instruction shown as prompt.
  final String? instruction;

  /// The correct step's instruction, quoted after answering as reinforcement.
  final String reinforcement;

  final List<String> options;
  final int correctIndex;

  const QuizQuestion({
    required this.type,
    required this.stepNumber,
    required this.reinforcement,
    required this.options,
    required this.correctIndex,
    this.anchorTitle,
    this.instruction,
  });

  String get correctTitle => options[correctIndex];
}

class QuizGenerator {
  QuizGenerator._();

  static const int maxQuestions = 8;
  static const int maxOptions = 4;

  /// Builds the quiz for a protocol from its steps.
  ///
  /// Deterministic: the same emergency id and steps always produce the same
  /// questions in the same order (the RNG is seeded from the id, not the
  /// clock), so practice results stay comparable across runs.
  static List<QuizQuestion> generate(String emergencyId, List<QuizStep> steps) {
    if (steps.length < 2) return const [];

    final rng = Random(_seedFor(emergencyId));
    final titles = [for (final s in steps) s.title];
    final count = min(maxQuestions, steps.length);

    // Ask about steps spread evenly across the protocol, then shuffle the
    // question order so the quiz doesn't simply walk the steps in sequence.
    final askedIndices = <int>[];
    for (var i = 0; i < count; i++) {
      final index = (i * steps.length) ~/ count;
      if (!askedIndices.contains(index)) askedIndices.add(index);
    }
    askedIndices.shuffle(rng);

    final questions = <QuizQuestion>[];
    for (var q = 0; q < askedIndices.length; q++) {
      final index = askedIndices[q];
      final correct = titles[index];

      // Cycle through the question types, falling back to whichStep when a
      // type doesn't apply: the first step has no predecessor, comesAfter
      // needs at least one distractor besides the anchor, and an instruction
      // that names its own step title would give the answer away.
      var type = QuizQuestionType.values[q % QuizQuestionType.values.length];
      if (type == QuizQuestionType.comesAfter &&
          (index == 0 ||
              titles.length < 3 ||
              _norm(titles[index - 1]) == _norm(correct))) {
        type = QuizQuestionType.whichStep;
      }
      if (type == QuizQuestionType.instructionMatch) {
        final instruction = steps[index].instruction;
        if (instruction.trim().isEmpty ||
            instruction.toLowerCase().contains(correct.toLowerCase())) {
          type = QuizQuestionType.whichStep;
        }
      }
      final anchor = type == QuizQuestionType.comesAfter
          ? titles[index - 1]
          : null;

      // Distractors: other step titles, preferring steps near the asked-about
      // one — actions from the same moment of the protocol read as plausible,
      // so the user has to actually know the order. Never the correct title,
      // and never the anchor a comesAfter question already shows.
      final excluded = {_norm(correct), if (anchor != null) _norm(anchor)};
      final candidates = <int>[
        for (var i = 0; i < titles.length; i++)
          if (i != index && !excluded.contains(_norm(titles[i]))) i,
      ];
      final tieBreak = {for (final i in candidates) i: rng.nextInt(1 << 20)};
      candidates.sort((a, b) {
        final byDistance = (a - index).abs().compareTo((b - index).abs());
        return byDistance != 0
            ? byDistance
            : tieBreak[a]!.compareTo(tieBreak[b]!);
      });

      final distractors = <String>[];
      final seen = <String>{...excluded};
      for (final i in candidates) {
        if (distractors.length >= maxOptions - 1) break;
        final normalized = _norm(titles[i]);
        if (seen.add(normalized)) distractors.add(titles[i]);
      }
      if (distractors.isEmpty) continue;

      final options = [correct, ...distractors]..shuffle(rng);
      questions.add(
        QuizQuestion(
          type: type,
          stepNumber: index + 1,
          anchorTitle: anchor,
          instruction: type == QuizQuestionType.instructionMatch
              ? steps[index].instruction
              : null,
          reinforcement: steps[index].instruction,
          options: options,
          correctIndex: options.indexOf(correct),
        ),
      );
    }
    return questions;
  }

  static String _norm(String title) => title.trim().toLowerCase();

  /// FNV-1a over the emergency id — a stable seed independent of Dart's
  /// platform-specific String.hashCode.
  static int _seedFor(String id) {
    var hash = 0x811C9DC5;
    for (final unit in id.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return hash;
  }
}
