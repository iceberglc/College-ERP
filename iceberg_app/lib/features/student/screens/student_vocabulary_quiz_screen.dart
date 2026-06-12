import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';

class StudentVocabularyQuizScreen extends ConsumerStatefulWidget {
  final int dayId;
  final String dayTitle;
  const StudentVocabularyQuizScreen({
    super.key,
    required this.dayId,
    required this.dayTitle,
  });

  @override
  ConsumerState<StudentVocabularyQuizScreen> createState() =>
      _StudentVocabularyQuizScreenState();
}

class _StudentVocabularyQuizScreenState
    extends ConsumerState<StudentVocabularyQuizScreen> {
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _answered = false;
  bool _quizDone = false;
  bool _submitting = false;
  List<dynamic> _questions = [];

  void _selectAnswer(String choice) {
    if (_answered) return;
    final correct = _questions[_currentIndex]['correct_answer'] as String;
    setState(() {
      _selectedAnswer = choice;
      _answered = true;
      if (choice == correct) _score++;
    });
  }

  Future<void> _next() async {
    if (_currentIndex + 1 < _questions.length) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      await _submitResult();
    }
  }

  Future<void> _submitResult() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final total = _questions.length;
    final pct = total > 0 ? (_score / total * 100).round() : 0;
    try {
      await ApiClient.instance.dio.post(
        '/vocabulary/${widget.dayId}/quiz-result/',
        data: {'score': pct, 'total_questions': total, 'correct_answers': _score},
      );
    } catch (_) {}
    ref.invalidate(vocabularyProvider);
    if (mounted) {
      setState(() {
        _quizDone = true;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(vocabQuizProvider(widget.dayId));

    return Scaffold(
      backgroundColor: IceColors.bg,
      appBar: AppBar(
        backgroundColor: IceColors.navyDeep,
        foregroundColor: Colors.white,
        title: Text(widget.dayTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        elevation: 0,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: IceColors.danger))),
        data: (questions) {
          if (_questions.isEmpty && questions.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _questions = questions);
            });
          }
          if (questions.isEmpty) {
            return _NoQuestionsView(title: widget.dayTitle);
          }
          if (_questions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_quizDone) {
            return _ResultView(
              score: _score,
              total: _questions.length,
              onRetry: () => setState(() {
                _currentIndex = 0;
                _score = 0;
                _selectedAnswer = null;
                _answered = false;
                _quizDone = false;
              }),
              onBack: () => Navigator.of(context).pop(),
            );
          }
          return _QuizBody(
            questions: _questions,
            currentIndex: _currentIndex,
            selectedAnswer: _selectedAnswer,
            answered: _answered,
            submitting: _submitting,
            onSelect: _selectAnswer,
            onNext: _next,
          );
        },
      ),
    );
  }
}

class _QuizBody extends StatelessWidget {
  final List<dynamic> questions;
  final int currentIndex;
  final String? selectedAnswer;
  final bool answered;
  final bool submitting;
  final void Function(String) onSelect;
  final VoidCallback onNext;

  const _QuizBody({
    required this.questions,
    required this.currentIndex,
    required this.selectedAnswer,
    required this.answered,
    required this.submitting,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final q = questions[currentIndex] as Map;
    final choices = (q['choices'] as List?)?.cast<String>() ?? [];
    final correct = q['correct_answer'] as String? ?? '';
    final meaning = q['meaning']?.toString() ?? '';
    final example = q['example_sentence']?.toString() ?? '';

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Question ${currentIndex + 1} of ${questions.length}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: IceColors.muted)),
                  Text('${((currentIndex / questions.length) * 100).round()}%',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: IceColors.navyDeep)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: currentIndex / questions.length,
                  backgroundColor: IceColors.border,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(IceColors.navyDeep),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [IceColors.navy, IceColors.navyDeep],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('What word means:',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text(meaning,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      if (example.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('"$example"',
                            style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                                fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1, duration: 300.ms),

                const SizedBox(height: 20),

                // Choices
                ...choices.asMap().entries.map((e) {
                  final choice = e.value;
                  final isSelected = selectedAnswer == choice;
                  final isCorrect = choice == correct;
                  Color borderColor = IceColors.border;
                  Color bgColor = Colors.white;
                  Color textColor = IceColors.text;
                  IconData? trailingIcon;

                  if (answered) {
                    if (isCorrect) {
                      borderColor = IceColors.success;
                      bgColor = IceColors.success.withAlpha(15);
                      textColor = IceColors.success;
                      trailingIcon = Icons.check_circle_rounded;
                    } else if (isSelected && !isCorrect) {
                      borderColor = IceColors.danger;
                      bgColor = IceColors.danger.withAlpha(15);
                      textColor = IceColors.danger;
                      trailingIcon = Icons.cancel_rounded;
                    }
                  } else if (isSelected) {
                    borderColor = IceColors.navyDeep;
                    bgColor = IceColors.navyDeep.withAlpha(12);
                  }

                  return GestureDetector(
                    onTap: () => onSelect(choice),
                    child: AnimatedContainer(
                      duration: 250.ms,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: borderColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              ['A', 'B', 'C', 'D'][e.key % 4],
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: borderColor),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(choice,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor)),
                          ),
                          if (trailingIcon != null)
                            Icon(trailingIcon, color: textColor, size: 20),
                        ],
                      ),
                    ),
                  )
                      .animate(delay: Duration(milliseconds: 50 * e.key))
                      .fadeIn(duration: 250.ms)
                      .slideX(begin: 0.05, duration: 250.ms);
                }),
              ],
            ),
          ),
        ),

        // Bottom button
        if (answered)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: submitting ? null : onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: IceColors.navyDeep,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          currentIndex + 1 < questions.length
                              ? 'Next Question'
                              : 'See Results',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              )
                  .animate()
                  .slideY(begin: 0.3, duration: 300.ms, curve: Curves.easeOut)
                  .fadeIn(duration: 250.ms),
            ),
          ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  final int score;
  final int total;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  const _ResultView({
    required this.score,
    required this.total,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (score / total * 100).round() : 0;
    final passed = pct >= 60;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: passed
                    ? IceColors.success.withAlpha(20)
                    : IceColors.warning.withAlpha(20),
                border: Border.all(
                    color: passed ? IceColors.success : IceColors.warning,
                    width: 3),
              ),
              child: Icon(
                passed ? Icons.emoji_events_rounded : Icons.school_rounded,
                size: 48,
                color: passed ? IceColors.success : IceColors.warning,
              ),
            )
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text('$pct%',
                style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: passed ? IceColors.success : IceColors.warning))
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 8),
            Text('$score of $total correct',
                style: const TextStyle(fontSize: 16, color: IceColors.muted)),
            const SizedBox(height: 12),
            Text(
              passed
                  ? 'Excellent! Day marked as completed.'
                  : 'Keep practicing! You need 60% to complete.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: passed ? IceColors.success : IceColors.text),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onBack,
                style: FilledButton.styleFrom(
                  backgroundColor: IceColors.navyDeep,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back to Vocabulary',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            if (!passed)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: IceColors.navyDeep,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: IceColors.navyDeep),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Retry Quiz',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoQuestionsView extends StatelessWidget {
  final String title;
  const _NoQuestionsView({required this.title});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.quiz_outlined, size: 56, color: IceColors.muted),
              const SizedBox(height: 16),
              const Text('No quiz available',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: IceColors.muted)),
              const SizedBox(height: 8),
              Text('This vocabulary day has no quiz questions yet.',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 13, color: IceColors.muted)),
            ],
          ),
        ),
      );
}
