import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import 'student_flashcard_screen.dart';
import 'student_vocabulary_quiz_screen.dart';

class StudentVocabularyDetailScreen extends StatefulWidget {
  final String vocabId;
  const StudentVocabularyDetailScreen({super.key, required this.vocabId});

  @override
  State<StudentVocabularyDetailScreen> createState() => _State();
}

class _State extends State<StudentVocabularyDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient.instance.dio.get('/vocabulary/${widget.vocabId}/');
      setState(() { _data = res.data as Map<String, dynamic>; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _markComplete() async {
    try {
      await ApiClient.instance.dio.post('/vocabulary/${widget.vocabId}/complete/');
      await _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Marked as complete!'),
          backgroundColor: IceColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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
          _data?['title']?.toString() ?? 'Vocabulary',
          style: const TextStyle(
            color: IceColors.text,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: IceColors.navyDeep))
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _fetch)
              : _Body(data: _data!, onMarkComplete: _markComplete, vocabId: widget.vocabId),
    );
  }
}

class _Body extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onMarkComplete;
  final String vocabId;
  const _Body({required this.data, required this.onMarkComplete, required this.vocabId});

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? '';
    final description = data['description']?.toString() ?? '';
    final words = (data['words'] as List?) ?? [];
    final isCompleted = data['is_completed'] == true;
    final dayId = data['id'] is int ? data['id'] as int : int.tryParse(data['id']?.toString() ?? '') ?? 0;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header info card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
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
                        if (title.isNotEmpty)
                          Text(title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              )),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(description,
                              style: TextStyle(
                                color: Colors.white.withAlpha(180),
                                fontSize: 13,
                              )),
                        ],
                        const SizedBox(height: 12),
                        Row(children: [
                          _StatChip(icon: Icons.style_rounded, label: '${words.length} words'),
                          const SizedBox(width: 8),
                          if (isCompleted)
                            _StatChip(
                                icon: Icons.check_circle_rounded,
                                label: 'Completed',
                                color: IceColors.lime),
                        ]),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06),
              ),

              // Words header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Word List',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: IceColors.text,
                      )),
                ),
              ),

              // Word cards
              if (words.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('No words in this lesson.',
                          style: TextStyle(color: IceColors.muted, fontSize: 14)),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final word = words[i] as Map;
                      return _WordCard(word: word, index: i);
                    },
                    childCount: words.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),

        // Bottom action buttons
        SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: IceColors.surface,
              border: Border(top: BorderSide(color: IceColors.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: words.isEmpty
                          ? null
                          : () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => StudentFlashcardScreen(vocabId: vocabId),
                              )),
                      icon: const Text('📚', style: TextStyle(fontSize: 16)),
                      label: const Text('Flashcards'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: IceColors.navyDeep,
                        side: const BorderSide(color: IceColors.navyDeep),
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: words.isEmpty
                          ? null
                          : () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => StudentVocabularyQuizScreen(
                                  dayId: dayId,
                                  dayTitle: title,
                                ),
                              )),
                      icon: const Text('✏️', style: TextStyle(fontSize: 16)),
                      label: const Text('Take Quiz'),
                      style: FilledButton.styleFrom(
                        backgroundColor: IceColors.navyDeep,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ]),
                if (!isCompleted) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onMarkComplete,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Mark Complete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: IceColors.success,
                        side: const BorderSide(color: IceColors.success),
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WordCard extends StatelessWidget {
  final Map word;
  final int index;
  const _WordCard({required this.word, required this.index});

  @override
  Widget build(BuildContext context) {
    final english = word['word']?.toString() ?? '';
    final translation = word['meaning']?.toString() ?? '';
    final example = word['example_sentence']?.toString() ?? '';
    final pronunciation = word['pronunciation_note']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IceColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IceColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: IceColors.navyDeep.withAlpha(12),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text('${index + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: IceColors.navyDeep,
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(english,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: IceColors.text,
                            )),
                        if (pronunciation.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(pronunciation,
                              style: const TextStyle(
                                fontSize: 12,
                                color: IceColors.muted,
                                fontStyle: FontStyle.italic,
                              )),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(translation,
                        style: const TextStyle(
                          fontSize: 14,
                          color: IceColors.muted,
                          fontWeight: FontWeight.w500,
                        )),
                  ],
                ),
              ),
            ],
          ),
          if (example.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: IceColors.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '"$example"',
                style: const TextStyle(
                  fontSize: 12,
                  color: IceColors.muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 40 * index))
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.06, duration: 250.ms);
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                )),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: IceColors.muted),
              const SizedBox(height: 16),
              const Text('Failed to load',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: IceColors.muted)),
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
