import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:guardian_angel/l10n/app_localizations.dart';
import '../core/app_theme.dart';
import '../services/database_service.dart';
import '../services/protocol_loader.dart';
import '../services/quiz_generator.dart';
import '../services/tts_service.dart';
import '../widgets/gradient_button.dart';

enum _LessonPhase { steps, quiz, result }

/// Practice walkthrough of an emergency protocol.
///
/// Reuses the same localized protocol JSON and step images as the emergency
/// flow, but never logs to Incident_Log and never auto-plays TTS — this is a
/// calm study mode, not an active emergency.
class LearningLessonScreen extends StatefulWidget {
  final String emergencyId;
  final String emergencyTitle;
  final Color emergencyColor;

  const LearningLessonScreen({
    super.key,
    required this.emergencyId,
    required this.emergencyTitle,
    required this.emergencyColor,
  });

  @override
  State<LearningLessonScreen> createState() => _LearningLessonScreenState();
}

class _LearningLessonScreenState extends State<LearningLessonScreen> {
  List<dynamic> _steps = [];
  List<QuizQuestion> _questions = [];
  bool _loading = true;
  String? _errorMessage;
  String? _loadedLocale;

  _LessonPhase _phase = _LessonPhase.steps;
  int _currentStep = 0;

  // Quiz state: one slot per question holding the picked option index (null =
  // not answered yet). Answers always form a prefix — the user can revisit
  // answered questions via the dots but can only answer at the frontier.
  int _currentQuestion = 0;
  List<int?> _selections = [];
  int? _attempts;

  bool get _answered =>
      _selections.isNotEmpty && _selections[_currentQuestion] != null;

  /// Index of the first unanswered question (== answered count).
  int get _answeredCount => _selections.where((s) => s != null).length;

  int get _score {
    var correct = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_selections[i] == _questions[i].correctIndex) correct++;
    }
    return correct;
  }

  /// Missed questions paired with the option the user actually picked, for
  /// the review section on the result screen.
  List<({QuizQuestion question, String picked})> get _missedDetails => [
    for (var i = 0; i < _questions.length; i++)
      if (_selections[i] != null &&
          _selections[i] != _questions[i].correctIndex)
        (
          question: _questions[i],
          picked: _questions[i].options[_selections[i]!],
        ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeCode = Localizations.localeOf(context).languageCode;
    if (_loadedLocale != localeCode) {
      _loadedLocale = localeCode;
      _loadProtocol(localeCode);
    }
  }

  Future<void> _loadProtocol(String localeCode) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _phase = _LessonPhase.steps;
      _currentStep = 0;
      _resetQuizState();
    });

    final result = await ProtocolLoader.tryLoad(widget.emergencyId, localeCode);
    final error = result.error;
    if (error != null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = switch (error) {
          ProtocolLoadError.failed => AppLocalizations.of(
            context,
          )!.stepErrorFailed,
          ProtocolLoadError.invalid => AppLocalizations.of(
            context,
          )!.stepErrorInvalid,
        };
        _loading = false;
      });
      return;
    }

    final steps = result.json!['steps'] as List;
    final questions = QuizGenerator.generate(widget.emergencyId, [
      for (final step in steps)
        (
          title: step['title'] as String,
          instruction: (step['instruction'] as String?) ?? '',
        ),
    ]);
    final resume = await _loadResumeState(questions, localeCode);

    if (!mounted) return;
    setState(() {
      _steps = steps;
      _questions = questions;
      _selections =
          resume?.selections ?? List<int?>.filled(questions.length, null);
      _currentQuestion = resume?.frontier ?? 0;
      if (resume != null) _phase = _LessonPhase.quiz;
      _loading = false;
    });
  }

  /// Restores an abandoned quiz run so an "In progress" card reopens straight
  /// into the quiz at the first unanswered question. Returns null when there
  /// is nothing valid to resume (not started, already completed, or the
  /// stored run no longer matches the generated quiz — including a run made
  /// under a different locale, whose option lists may differ).
  Future<({List<int?> selections, int frontier})?> _loadResumeState(
    List<QuizQuestion> questions,
    String localeCode,
  ) async {
    try {
      final progress = await DatabaseService.getAllLearningProgress();
      final row = progress[widget.emergencyId];
      if (row == null || row['is_completed'] == 1) return null;
      if (row['partial_total'] != questions.length) return null;

      final stored = row['partial_selections_json'] as String?;
      if (stored == null) return null;
      final payload = jsonDecode(stored);
      if (payload is! Map<String, dynamic>) return null;
      // Options are built from localized titles; picks made in another
      // language could map onto reordered options without failing the
      // bounds checks below, so a locale mismatch discards the run.
      if (payload['locale'] != localeCode) return null;
      var decoded = (payload['picks'] as List).cast<int>();
      if (decoded.isEmpty || decoded.length > questions.length) return null;
      // If every question was answered but the quiz never finished, reopen on
      // the last question with its answer cleared so there is a next action.
      if (decoded.length == questions.length) {
        decoded = decoded.sublist(0, questions.length - 1);
      }
      final selections = List<int?>.filled(questions.length, null);
      for (var i = 0; i < decoded.length; i++) {
        if (decoded[i] < 0 || decoded[i] >= questions[i].options.length) {
          return null;
        }
        selections[i] = decoded[i];
      }
      return (selections: selections, frontier: decoded.length);
    } catch (_) {
      return null;
    }
  }

  void _resetQuizState() {
    _currentQuestion = 0;
    _selections = List<int?>.filled(_questions.length, null);
  }

  void _nextStep() {
    TtsService.instance.stop();
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else if (_questions.isNotEmpty) {
      setState(() => _phase = _LessonPhase.quiz);
    } else {
      // No quiz possible (degenerate protocol) — still record completion.
      _finishQuiz();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      TtsService.instance.stop();
      setState(() => _currentStep--);
    }
  }

  /// Skips the remaining lesson steps and opens the quiz immediately.
  void _goToQuiz() {
    TtsService.instance.stop();
    setState(() => _phase = _LessonPhase.quiz);
  }

  /// Returns from the quiz to the lesson steps for restudying. Quiz answers
  /// are kept, so coming back resumes the quiz exactly where it was.
  void _reviewLesson() {
    setState(() => _phase = _LessonPhase.steps);
  }

  /// Plays the pre-recorded audio for the current step. Learning mode never
  /// auto-plays — this runs only when the user taps the listen button.
  void _playCurrentStep() {
    final step = _steps[_currentStep];
    TtsService.instance.speak(
      widget.emergencyId,
      step['step'] as int,
      TtsService.langCodeFor(_loadedLocale ?? 'en'),
    );
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  void _selectOption(int index) {
    if (_answered) return;
    setState(() => _selections[_currentQuestion] = index);
    _savePartialProgress();
  }

  /// Best-effort snapshot after every answer, so leaving mid-quiz (or the app
  /// being killed) still leaves an accurate progress trail on the card and a
  /// run that can be resumed.
  Future<void> _savePartialProgress() async {
    try {
      await DatabaseService.recordQuizPartialProgress(
        widget.emergencyId,
        answered: _answeredCount,
        correct: _score,
        total: _questions.length,
        selections: [
          for (final selection in _selections)
            if (selection != null) selection,
        ],
        locale: _loadedLocale ?? 'en',
      );
    } catch (_) {
      // Progress is a nicety — the quiz keeps working without it.
    }
  }

  void _nextQuestion() {
    if (!_answered) return;
    if (_currentQuestion < _questions.length - 1) {
      setState(() => _currentQuestion++);
    } else {
      _finishQuiz();
    }
  }

  /// Jumps to an already-answered question (or back to the frontier). Future
  /// questions stay locked until the ones before them are answered.
  void _goToQuestion(int index) {
    if (index == _currentQuestion || index > _answeredCount) return;
    setState(() => _currentQuestion = index);
  }

  Future<void> _finishQuiz() async {
    setState(() => _phase = _LessonPhase.result);
    try {
      final attempts = await DatabaseService.recordLearningCompletion(
        widget.emergencyId,
        score: _score,
        total: _questions.length,
      );
      if (mounted) setState(() => _attempts = attempts);
    } catch (_) {
      // Saving progress is best-effort; the lesson result is still shown.
    }
  }

  void _retakeQuiz() {
    setState(() {
      _phase = _LessonPhase.quiz;
      _resetQuizState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          _phase == _LessonPhase.steps
              ? widget.emergencyTitle
              : '${widget.emergencyTitle} — ${l10n.quizTitle}',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: false,
        actions: [
          // From the quiz, jump back to the lesson to restudy; answers are
          // kept so the quiz resumes where it was.
          if (_phase == _LessonPhase.quiz)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: TextButton.icon(
                onPressed: _reviewLesson,
                style: TextButton.styleFrom(
                  foregroundColor: widget.emergencyColor,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: Text(
                  l10n.learnReviewLesson,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: widget.emergencyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: widget.emergencyColor),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyLarge?.copyWith(color: cs.error),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : switch (_phase) {
              _LessonPhase.steps => _buildStepsPhase(l10n),
              _LessonPhase.quiz => _buildQuizPhase(l10n),
              _LessonPhase.result => _buildResultPhase(l10n),
            },
    );
  }

  // ── Steps phase ──────────────────────────────────────────

  Widget _buildStepsPhase(AppLocalizations l10n) {
    final step = _steps[_currentStep];
    final totalSteps = _steps.length;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLastStep = _currentStep == totalSteps - 1;

    return Padding(
      // Bottom inset keeps the navigation buttons comfortably above the
      // home-indicator area.
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.stepProgress(_currentStep + 1, totalSteps),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              // Jump straight to the quiz without paging through every step.
              if (_questions.isNotEmpty)
                TextButton.icon(
                  onPressed: _goToQuiz,
                  style: TextButton.styleFrom(
                    foregroundColor: widget.emergencyColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.quiz_outlined, size: 18),
                  label: Text(
                    l10n.learnGoToQuiz,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: widget.emergencyColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Icon(Icons.school_outlined, color: widget.emergencyColor),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / totalSteps,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(widget.emergencyColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Image.asset(
                              step['image'] ??
                                  ProtocolLoader.stepImagePath(
                                    widget.emergencyId,
                                    _currentStep + 1,
                                  ),
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            step['title'],
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: widget.emergencyColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            step['instruction'],
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: cs.onSurface,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Listen button — pinned at the card bottom, never scrolls
                  // away. Plays only on tap; learning mode has no autoplay.
                  IconButton(
                    onPressed: _playCurrentStep,
                    icon: Icon(
                      Icons.volume_up_rounded,
                      color: widget.emergencyColor,
                      size: 28,
                    ),
                    tooltip: l10n.learnListen,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _previousStep,
                      icon: const Icon(Icons.arrow_back, size: 20),
                      label: Text(l10n.stepPrevious),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: widget.emergencyColor,
                          width: 1.5,
                        ),
                        foregroundColor: widget.emergencyColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: GradientButton(
                  height: 52,
                  gradientColors: [
                    widget.emergencyColor,
                    widget.emergencyColor.withValues(alpha: 0.85),
                  ],
                  onTap: _nextStep,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLastStep ? l10n.learnStartQuiz : l10n.stepNext,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isLastStep ? Icons.quiz_outlined : Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quiz phase ───────────────────────────────────────────

  Widget _buildQuizPhase(AppLocalizations l10n) {
    final question = _questions[_currentQuestion];
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLastQuestion = _currentQuestion == _questions.length - 1;
    final wasCorrect =
        _answered && _selections[_currentQuestion] == question.correctIndex;

    return Padding(
      // Bottom inset keeps the navigation buttons comfortably above the
      // home-indicator area.
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.quizQuestionProgress(
                  _currentQuestion + 1,
                  _questions.length,
                ),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              _buildProgressDots(),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _questionPrompt(l10n, question),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          if (question.type == QuizQuestionType.instructionMatch) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 110),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: BorderDirectional(
                  start: BorderSide(color: widget.emergencyColor, width: 3),
                ),
              ),
              child: SingleChildScrollView(
                child: Text(
                  question.instruction!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: question.options.length + (_answered ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == question.options.length) {
                  return _buildFeedbackCard(l10n, question, wasCorrect);
                }
                return _buildOption(question, i);
              },
            ),
          ),
          const SizedBox(height: 14),
          GradientButton(
            width: double.infinity,
            height: 52,
            gradientColors: !_answered
                ? [cs.surfaceContainerHighest, cs.surfaceContainerHighest]
                : [
                    widget.emergencyColor,
                    widget.emergencyColor.withValues(alpha: 0.85),
                  ],
            // _nextQuestion no-ops until an option is chosen; the muted
            // gradient signals the disabled state.
            onTap: _nextQuestion,
            child: Center(
              child: Text(
                isLastQuestion ? l10n.quizFinish : l10n.quizNext,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: !_answered ? cs.outline : Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One dot per question: green/red once answered, accent ring on the one
  /// being shown. Answered dots (and the frontier) are tappable so the user
  /// can revisit earlier questions and their feedback.
  Widget _buildProgressDots() {
    final cs = Theme.of(context).colorScheme;
    final frontier = _answeredCount;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _questions.length; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: i <= frontier ? () => _goToQuestion(i) : null,
            child: Padding(
              // Generous padding keeps the touch target comfortable even
              // though the visible dot is small.
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _selections[i] != null
                      ? (_selections[i] == _questions[i].correctIndex
                            ? AppColors.quizCorrectGreen
                            : cs.error)
                      : i == _currentQuestion
                      ? widget.emergencyColor.withValues(alpha: 0.35)
                      : cs.surfaceContainerHighest,
                  border: i == _currentQuestion
                      ? Border.all(color: widget.emergencyColor, width: 2)
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOption(QuizQuestion question, int index) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selected = _selections[_currentQuestion] == index;
    final isCorrectOption = index == question.correctIndex;

    // Before answering: neutral cards. After: the correct option turns green,
    // a wrong pick turns red, everything else fades back.
    Color borderColor = cs.outlineVariant.withValues(alpha: 0.15);
    Color background = cs.surfaceContainerLow;
    Color textColor = cs.onSurface;
    IconData icon = Icons.radio_button_off;
    Color iconColor = cs.outline;
    var emphasized = false;

    if (_answered) {
      if (isCorrectOption) {
        borderColor = AppColors.quizCorrectGreen;
        background = AppColors.quizCorrectGreen.withValues(alpha: 0.10);
        icon = Icons.check_circle;
        iconColor = AppColors.quizCorrectGreen;
        emphasized = true;
      } else if (selected) {
        borderColor = cs.error;
        background = cs.error.withValues(alpha: 0.08);
        icon = Icons.cancel;
        iconColor = cs.error;
        emphasized = true;
      } else {
        textColor = cs.onSurfaceVariant.withValues(alpha: 0.6);
      }
    }

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => _selectOption(index),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: emphasized ? 1.8 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.options[index],
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontWeight: emphasized
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(
    AppLocalizations l10n,
    QuizQuestion question,
    bool wasCorrect,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = wasCorrect ? AppColors.quizCorrectGreen : cs.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                wasCorrect ? Icons.celebration : Icons.lightbulb_outline,
                color: accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                wasCorrect ? l10n.quizCorrect : l10n.quizWrong,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.quizFromProtocol,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            question.reinforcement,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Result phase ─────────────────────────────────────────

  /// The localized prompt a question was asked with — shared by the quiz
  /// phase and the review section so the review shows the original question.
  static String _questionPrompt(AppLocalizations l10n, QuizQuestion question) =>
      switch (question.type) {
        QuizQuestionType.whichStep => l10n.quizQuestionWhichStep(
          question.stepNumber,
        ),
        QuizQuestionType.comesAfter => l10n.quizQuestionAfter(
          question.anchorTitle!,
        ),
        QuizQuestionType.instructionMatch => l10n.quizQuestionInstruction,
      };

  /// One missed question: the original question, the correct answer (green),
  /// and what was picked (red). Tapping opens the full protocol step.
  Widget _buildMissCard(
    AppLocalizations l10n,
    QuizQuestion question,
    String picked,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    Widget answerRow(IconData icon, Color color, String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              height: 1.35,
            ),
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => _showStepSheet(question.stepNumber),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _questionPrompt(l10n, question),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    Icon(
                      isRtl ? Icons.chevron_left : Icons.chevron_right,
                      color: cs.outline,
                      size: 20,
                    ),
                  ],
                ),
                if (question.type == QuizQuestionType.instructionMatch) ...[
                  const SizedBox(height: 4),
                  Text(
                    '"${question.instruction!}"',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                answerRow(
                  Icons.check_circle,
                  AppColors.quizCorrectGreen,
                  l10n.quizCorrectAnswer(question.correctTitle),
                ),
                const SizedBox(height: 6),
                answerRow(Icons.cancel, cs.error, l10n.quizYourAnswer(picked)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows the full protocol step (image, title, instruction) so a missed
  /// question can be restudied without leaving the result screen.
  void _showStepSheet(int stepNumber) {
    if (stepNumber < 1 || stepNumber > _steps.length) return;
    final step = _steps[stepNumber - 1];
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.asset(
                    step['image'] ??
                        ProtocolLoader.stepImagePath(
                          widget.emergencyId,
                          stepNumber,
                        ),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  step['title'],
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: widget.emergencyColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  step['instruction'],
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: cs.onSurface,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultPhase(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total = _questions.length;
    final medal = QuizMedal.of(_score, total);
    final accent = medal.color;
    final medalLabel = switch (medal) {
      QuizMedal.gold => l10n.quizMedalGold,
      QuizMedal.silver => l10n.quizMedalSilver,
      QuizMedal.bronze => l10n.quizMedalBronze,
    };

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 3),
                ),
                child: Icon(Icons.workspace_premium, color: accent, size: 64),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              medalLabel,
              style: theme.textTheme.titleLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            if (_attempts != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.quizAttempt(_attempts!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              l10n.quizResultTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            if (total > 0)
              Text(
                l10n.quizResultScore(_score, total),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            if (_missedDetails.isNotEmpty) ...[
              const SizedBox(height: 24),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.quizReviewTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.quizReviewHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              for (final miss in _missedDetails)
                _buildMissCard(l10n, miss.question, miss.picked),
            ],
            const SizedBox(height: 24),
            if (total > 0) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _retakeQuiz,
                  icon: const Icon(Icons.replay, size: 20),
                  label: Text(l10n.quizRetake),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: widget.emergencyColor, width: 1.5),
                    foregroundColor: widget.emergencyColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            GradientButton(
              width: double.infinity,
              height: 56,
              onTap: () => Navigator.pop(context, true),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home, color: cs.onPrimary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    l10n.stepCompleteBackBtn,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
