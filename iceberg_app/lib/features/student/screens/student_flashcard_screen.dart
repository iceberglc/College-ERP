import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import 'student_vocabulary_quiz_screen.dart';

class StudentFlashcardScreen extends StatefulWidget {
  final String vocabId;
  const StudentFlashcardScreen({super.key, required this.vocabId});

  @override
  State<StudentFlashcardScreen> createState() => _State();
}

class _State extends State<StudentFlashcardScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  List<dynamic> _words = [];
  Map<String, dynamic>? _dayData;
  int _currentIndex = 0;
  bool _allDone = false;

  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnim = Tween<double>(
      begin: 0,
      end: math.pi,
    ).animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));
    _fetch();
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.dio.get(
        '/vocabulary/${widget.vocabId}/',
      );
      final data = res.data as Map<String, dynamic>;
      final words = (data['words'] as List?) ?? [];
      setState(() {
        _dayData = data;
        _words = words;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _flip() {
    if (_flipCtrl.isAnimating) return;
    if (_isFront) {
      _flipCtrl.forward();
    } else {
      _flipCtrl.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  void _next() {
    if (_currentIndex + 1 >= _words.length) {
      setState(() => _allDone = true);
      return;
    }
    // Reset flip to front for next card
    _flipCtrl.reset();
    setState(() {
      _isFront = true;
      _currentIndex++;
    });
  }

  void _prev() {
    if (_currentIndex <= 0) return;
    _flipCtrl.reset();
    setState(() {
      _isFront = true;
      _currentIndex--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IceColors.bg,
      appBar: AppBar(
        backgroundColor: IceColors.bg,
        elevation: 0,
        leading: const BackButton(color: IceColors.text),
        title: Text(
          _dayData?['title']?.toString() ?? 'Flashcards',
          style: const TextStyle(
            color: IceColors.text,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: IceColors.navyDeep),
            )
          : _error != null
          ? _ErrorView(error: _error!, onRetry: _fetch)
          : _words.isEmpty
          ? const _EmptyView()
          : _allDone
          ? _CelebrationView(
              vocabId: widget.vocabId,
              dayData: _dayData,
              onRestart: () => setState(() {
                _allDone = false;
                _currentIndex = 0;
                _isFront = true;
                _flipCtrl.reset();
              }),
            )
          : _FlashcardView(
              words: _words,
              currentIndex: _currentIndex,
              flipAnim: _flipAnim,
              isFront: _isFront,
              onFlip: _flip,
              onPrev: _currentIndex > 0 ? _prev : null,
              onNext: _next,
            ),
    );
  }
}

// ─── Flashcard View ───────────────────────────────────────────────────────────

class _FlashcardView extends StatelessWidget {
  final List<dynamic> words;
  final int currentIndex;
  final Animation<double> flipAnim;
  final bool isFront;
  final VoidCallback onFlip;
  final VoidCallback? onPrev;
  final VoidCallback onNext;

  const _FlashcardView({
    required this.words,
    required this.currentIndex,
    required this.flipAnim,
    required this.isFront,
    required this.onFlip,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final word = words[currentIndex] as Map;
    final total = words.length;
    final progress = (currentIndex + 1) / total;

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${currentIndex + 1} / $total',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: IceColors.navyDeep,
                    ),
                  ),
                  const Text(
                    'Tap card to flip',
                    style: TextStyle(fontSize: 12, color: IceColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: IceColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    IceColors.navyDeep,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),

        // Card
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: onFlip,
                child: AnimatedBuilder(
                  animation: flipAnim,
                  builder: (context, child) {
                    final angle = flipAnim.value;
                    final showFront = angle < math.pi / 2;

                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      alignment: Alignment.center,
                      child: showFront
                          ? _CardFace(word: word, isFront: true)
                          : Transform(
                              transform: Matrix4.identity()..rotateY(math.pi),
                              alignment: Alignment.center,
                              child: _CardFace(word: word, isFront: false),
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // Navigation buttons
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPrev,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Previous'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: IceColors.navyDeep,
                      side: BorderSide(
                        color: onPrev != null
                            ? IceColors.navyDeep
                            : IceColors.border,
                      ),
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onNext,
                    label: Text(
                      currentIndex + 1 >= words.length ? 'Finish' : 'Next',
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    style: FilledButton.styleFrom(
                      backgroundColor: IceColors.navyDeep,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Card Face ────────────────────────────────────────────────────────────────

class _CardFace extends StatelessWidget {
  final Map word;
  final bool isFront;
  const _CardFace({required this.word, required this.isFront});

  @override
  Widget build(BuildContext context) {
    final english = word['word']?.toString() ?? '';
    final translation = word['meaning']?.toString() ?? '';
    final example = word['example_sentence']?.toString() ?? '';
    final pronunciation = word['pronunciation_note']?.toString() ?? '';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isFront ? IceColors.navy : IceColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: isFront
            ? null
            : Border.all(color: IceColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: IceColors.navy.withAlpha(isFront ? 60 : 20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Front / Back indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isFront
                  ? Colors.white.withAlpha(20)
                  : IceColors.navyDeep.withAlpha(15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isFront ? 'English' : 'Translation',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isFront ? Colors.white70 : IceColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (isFront) ...[
            Text(
              english,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            if (pronunciation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                pronunciation,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withAlpha(160),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ] else ...[
            Text(
              translation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: IceColors.text,
              ),
            ),
            if (example.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: IceColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '"$example"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: IceColors.muted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 14,
                color: isFront ? Colors.white38 : IceColors.muted,
              ),
              const SizedBox(width: 4),
              Text(
                'Tap to flip',
                style: TextStyle(
                  fontSize: 11,
                  color: isFront ? Colors.white38 : IceColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Celebration Screen ───────────────────────────────────────────────────────

class _CelebrationView extends StatelessWidget {
  final String vocabId;
  final Map<String, dynamic>? dayData;
  final VoidCallback onRestart;
  const _CelebrationView({
    required this.vocabId,
    required this.dayData,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final dayId = dayData?['id'] is int
        ? dayData!['id'] as int
        : int.tryParse(dayData?['id']?.toString() ?? '') ?? 0;
    final title = dayData?['title']?.toString() ?? 'Vocabulary';

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
                color: IceColors.lime.withAlpha(40),
                border: Border.all(color: IceColors.lime, width: 3),
              ),
              child: const Center(
                child: Text('🎉', style: TextStyle(fontSize: 44)),
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            const Text(
              'All cards reviewed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: IceColors.text,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            const Text(
              'You\'ve gone through all the flashcards.\nReady to test yourself?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: IceColors.muted),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => StudentVocabularyQuizScreen(
                      dayId: dayId,
                      dayTitle: title,
                    ),
                  ),
                ),
                icon: const Icon(Icons.quiz_rounded),
                label: const Text('Take Quiz'),
                style: FilledButton.styleFrom(
                  backgroundColor: IceColors.navyDeep,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Review Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: IceColors.navyDeep,
                  side: const BorderSide(color: IceColors.navyDeep),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style_outlined, size: 48, color: IceColors.muted),
          SizedBox(height: 16),
          Text(
            'No words to review',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: IceColors.muted,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This lesson has no words yet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: IceColors.muted),
          ),
        ],
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: IceColors.muted,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: IceColors.muted),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: IceColors.navyDeep),
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
