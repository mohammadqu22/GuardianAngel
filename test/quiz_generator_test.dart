import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_angel/services/quiz_generator.dart';

void main() {
  const steps = <QuizStep>[
    (title: 'Check if they can cough', instruction: 'Watch their condition.'),
    (title: 'Call for help', instruction: 'Call emergency services (101).'),
    (title: 'Give 5 back blows', instruction: 'Strike between the blades.'),
    (title: 'Give 5 abdominal thrusts', instruction: 'Press inward and up.'),
    (title: 'Alternate and repeat', instruction: 'Keep alternating.'),
    (title: 'If they become unconscious', instruction: 'Begin CPR.'),
    (title: 'Special cases', instruction: 'Use chest thrusts instead.'),
  ];
  final titles = [for (final s in steps) s.title];

  test('quiz generation is deterministic for the same protocol', () {
    final first = QuizGenerator.generate('choking', steps);
    final second = QuizGenerator.generate('choking', steps);

    expect(first.length, second.length);
    for (var i = 0; i < first.length; i++) {
      expect(first[i].type, second[i].type);
      expect(first[i].stepNumber, second[i].stepNumber);
      expect(first[i].options, second[i].options);
      expect(first[i].correctIndex, second[i].correctIndex);
    }
  });

  test('asks one question per step up to the cap', () {
    expect(QuizGenerator.generate('cpr', steps).length, steps.length);

    final tenSteps = [
      for (var i = 0; i < 10; i++) (title: 'Step $i', instruction: 'Do $i'),
    ];
    expect(
      QuizGenerator.generate('cpr', tenSteps).length,
      QuizGenerator.maxQuestions,
    );
  });

  test('questions use only existing step titles and mark the right answer', () {
    final questions = QuizGenerator.generate('cpr', steps);

    for (final q in questions) {
      expect(q.options.length, lessThanOrEqualTo(QuizGenerator.maxOptions));
      expect(q.options.toSet().length, q.options.length,
          reason: 'options must not repeat');
      for (final option in q.options) {
        expect(titles, contains(option),
            reason: 'every option must be an existing step title');
      }
      expect(q.correctTitle, titles[q.stepNumber - 1],
          reason: 'correct option must be the asked-about step title');
    }
  });

  test('question types are consistent with their source step', () {
    final questions = QuizGenerator.generate('bleeding', steps);

    expect(
      questions.map((q) => q.type).toSet().length,
      greaterThan(1),
      reason: 'a 7-step protocol should mix question types',
    );

    for (final q in questions) {
      switch (q.type) {
        case QuizQuestionType.whichStep:
          expect(q.anchorTitle, isNull);
          expect(q.instruction, isNull);
        case QuizQuestionType.comesAfter:
          expect(q.anchorTitle, titles[q.stepNumber - 2],
              reason: 'anchor must be the step right before the answer');
        case QuizQuestionType.instructionMatch:
          expect(q.instruction, steps[q.stepNumber - 1].instruction,
              reason: 'prompt instruction must belong to the answer step');
      }
      expect(q.reinforcement, steps[q.stepNumber - 1].instruction,
          reason: 'reinforcement must quote the answer step instruction');
    }
  });

  test('comesAfter questions never offer the anchor as an option', () {
    for (final id in ['choking', 'cpr', 'bleeding', 'burns', 'seizures']) {
      final questions = QuizGenerator.generate(id, steps);
      for (final q in questions) {
        if (q.type == QuizQuestionType.comesAfter) {
          expect(q.options, isNot(contains(q.anchorTitle)),
              reason: 'the step quoted in the question is not a useful option');
        }
      }
    }
  });

  test('distractors come from steps near the asked-about one', () {
    final questions = QuizGenerator.generate('cpr', steps);
    for (final q in questions) {
      final correctIdx = q.stepNumber - 1;
      for (final option in q.options) {
        if (option == q.correctTitle) continue;
        final optionIdx = titles.indexOf(option);
        expect((optionIdx - correctIdx).abs(), lessThanOrEqualTo(3),
            reason: 'plausible distractors sit near the correct step');
      }
    }
  });

  test('instructionMatch is skipped when the instruction names its step', () {
    final giveawaySteps = [
      for (final title in titles)
        (title: title, instruction: 'Now you must $title without delay.'),
    ];
    final questions = QuizGenerator.generate('choking', giveawaySteps);
    expect(questions, isNotEmpty);
    for (final q in questions) {
      expect(q.type, isNot(QuizQuestionType.instructionMatch),
          reason: 'an instruction containing its own title gives the answer away');
    }
  });

  test('different protocols get different question order', () {
    final a = QuizGenerator.generate('choking', steps);
    final b = QuizGenerator.generate('bleeding', steps);
    final aShape =
        [for (final q in a) '${q.stepNumber}:${q.options.join('|')}'].join();
    final bShape =
        [for (final q in b) '${q.stepNumber}:${q.options.join('|')}'].join();
    expect(aShape, isNot(bShape));
  });

  test('protocols with fewer than two steps produce no quiz', () {
    expect(
      QuizGenerator.generate('x', const [(title: 'Only', instruction: 'i')]),
      isEmpty,
    );
    expect(QuizGenerator.generate('x', const []), isEmpty);
  });

  test('two-step protocol still produces valid questions', () {
    final questions = QuizGenerator.generate('x', const [
      (title: 'First', instruction: 'a'),
      (title: 'Second', instruction: 'b'),
    ]);
    expect(questions, isNotEmpty);
    for (final q in questions) {
      expect(q.options.length, 2);
      expect(q.options, contains(q.correctTitle));
    }
  });

  test('medal tiers follow score thresholds', () {
    expect(QuizMedal.of(8, 8), QuizMedal.gold);
    expect(QuizMedal.of(6, 8), QuizMedal.silver);
    expect(QuizMedal.of(5, 8), QuizMedal.bronze);
    expect(QuizMedal.of(0, 8), QuizMedal.bronze);
    expect(QuizMedal.of(0, 0), QuizMedal.bronze);
  });
}
