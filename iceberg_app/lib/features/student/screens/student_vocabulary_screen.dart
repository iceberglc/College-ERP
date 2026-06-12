import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';
import 'student_vocabulary_quiz_screen.dart';

class StudentVocabularyScreen extends ConsumerWidget {
  const StudentVocabularyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vocabularyProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(vocabularyProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Vocabulary',
                subtitle: 'Daily word sets from your groups',
              ),
            ),
            async.when(
              loading: () => const SliverToBoxAdapter(child: _Skeleton()),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: IceColors.danger),
                  ),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return SliverToBoxAdapter(child: _Empty());
                }

                // Find first incomplete day for "Continue" section
                final Map? continueItem = () {
                  for (final item in list) {
                    final m = item as Map;
                    if (m['is_completed'] != true) return m;
                  }
                  return null;
                }();

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    // Index 0: Continue card (if applicable)
                    // Index 1: "Barcha kunlar" header
                    // Index 2+: day cards
                    // Last: bottom padding

                    if (continueItem != null) {
                      if (index == 0) {
                        return _ContinueCard(item: continueItem, ref: ref);
                      }
                      if (index == 1) {
                        return const _SectionHeader(title: 'Barcha kunlar');
                      }
                      final dayIndex = index - 2;
                      if (dayIndex == list.length) {
                        return const SizedBox(height: 100);
                      }
                      return _VocabDayCard(
                        item: list[dayIndex] as Map,
                        index: dayIndex,
                        ref: ref,
                      );
                    } else {
                      if (index == 0) {
                        return const _SectionHeader(title: 'Barcha kunlar');
                      }
                      final dayIndex = index - 1;
                      if (dayIndex == list.length) {
                        return const SizedBox(height: 100);
                      }
                      return _VocabDayCard(
                        item: list[dayIndex] as Map,
                        index: dayIndex,
                        ref: ref,
                      );
                    }
                  }, childCount: list.length + (continueItem != null ? 3 : 2)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Continue Card ────────────────────────────────────────────────────────────

class _ContinueCard extends StatelessWidget {
  final Map item;
  final WidgetRef ref;
  const _ContinueCard({required this.item, required this.ref});

  @override
  Widget build(BuildContext context) {
    final dayNumber = item['day_number'] ?? 0;
    final title = item['title']?.toString() ?? '';
    final groupName = item['group_name']?.toString() ?? '';
    final wordCount = item['word_count'] ?? 0;
    final viewedCount = item['viewed_count'] ?? 0;
    final progress = wordCount > 0
        ? (viewedCount as num).toDouble() / (wordCount as num).toDouble()
        : 0.0;
    final displayTitle = title.isNotEmpty ? title : 'Day $dayNumber';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: _SectionHeader(title: 'Davom ettiring', noPadding: true),
          ),
          Container(
            decoration: BoxDecoration(
              color: IceColors.navy,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$groupName · $wordCount so\'z',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withAlpha(160),
                  ),
                ),
                const SizedBox(height: 14),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white.withAlpha(40),
                    valueColor: const AlwaysStoppedAnimation(IceColors.lime),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$viewedCount / $wordCount so\'z ko\'rildi',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withAlpha(140),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => StudentVocabularyQuizScreen(
                              dayId: item['id'] as int,
                              dayTitle: displayTitle,
                            ),
                          ),
                        )
                        .then((_) => ref.invalidate(vocabularyProvider)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IceColors.lime,
                      foregroundColor: IceColors.navy,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Boshlash'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, duration: 300.ms);
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool noPadding;
  const _SectionHeader({required this.title, this.noPadding = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: noPadding
        ? EdgeInsets.zero
        : const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: IceColors.text,
      ),
    ),
  );
}

// ─── Vocab Day Card ───────────────────────────────────────────────────────────

class _VocabDayCard extends StatelessWidget {
  final Map item;
  final int index;
  final WidgetRef ref;
  const _VocabDayCard({
    required this.item,
    required this.index,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = item['is_completed'] == true;
    final wordCount = item['word_count'] ?? 0;
    final dayNumber = item['day_number'] ?? 0;
    final title = item['title']?.toString() ?? '';
    final groupName = item['group_name']?.toString() ?? '';
    final words = (item['words'] as List?) ?? [];
    final displayTitle = title.isNotEmpty ? title : 'Day $dayNumber';

    return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCompleted
                  ? IceColors.success.withAlpha(60)
                  : const Color(0xFFEEEEEE),
              width: 1.5,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              leading: _DayCircle(
                dayNumber: dayNumber,
                isCompleted: isCompleted,
              ),
              title: Text(
                displayTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: IceColors.text,
                ),
              ),
              subtitle: Text(
                '$groupName · $wordCount so\'z',
                style: const TextStyle(fontSize: 11, color: IceColors.muted),
              ),
              trailing: isCompleted
                  ? _DoneChip()
                  : _StartMiniButton(
                      onPressed: () => Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => StudentVocabularyQuizScreen(
                                dayId: item['id'] as int,
                                dayTitle: displayTitle,
                              ),
                            ),
                          )
                          .then((_) => ref.invalidate(vocabularyProvider)),
                    ),
              children: [
                if (words.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No words yet.',
                      style: TextStyle(color: IceColors.muted, fontSize: 13),
                    ),
                  )
                else ...[
                  ...words.map((w) {
                    final word = w as Map;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                word['word']?.toString() ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: IceColors.navyDeep,
                                ),
                              ),
                              if ((word['pronunciation_note'] ?? '')
                                  .toString()
                                  .isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  word['pronunciation_note'].toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: IceColors.muted,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            word['meaning']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: IceColors.text,
                            ),
                          ),
                          if ((word['example_sentence'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '"${word['example_sentence']}"',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: IceColors.muted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  // Bottom action buttons
                  Row(
                    children: [
                      if (!isCompleted)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _markComplete(context, item['id'], ref),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Mark Done'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: IceColors.navyDeep,
                              side: const BorderSide(color: IceColors.navyDeep),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      if (!isCompleted) const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => StudentVocabularyQuizScreen(
                                    dayId: item['id'] as int,
                                    dayTitle: displayTitle,
                                  ),
                                ),
                              )
                              .then((_) => ref.invalidate(vocabularyProvider)),
                          icon: const Icon(Icons.quiz_rounded, size: 16),
                          label: const Text('Take Quiz'),
                          style: FilledButton.styleFrom(
                            backgroundColor: IceColors.navy,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: 40 * index))
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.06, duration: 280.ms);
  }

  Future<void> _markComplete(
    BuildContext context,
    dynamic id,
    WidgetRef ref,
  ) async {
    try {
      await ApiClient.instance.dio.post('/vocabulary/$id/complete/');
      ref.invalidate(vocabularyProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

// ─── Day Circle ───────────────────────────────────────────────────────────────

class _DayCircle extends StatelessWidget {
  final int dayNumber;
  final bool isCompleted;
  const _DayCircle({required this.dayNumber, required this.isCompleted});

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: isCompleted ? IceColors.lime : const Color(0xFFEEEEEE),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: isCompleted
          ? Icon(Icons.check_rounded, size: 20, color: IceColors.navy)
          : Text(
              '$dayNumber',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: IceColors.muted,
              ),
            ),
    ),
  );
}

// ─── Done Chip ────────────────────────────────────────────────────────────────

class _DoneChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: IceColors.success.withAlpha(20),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Text(
      'Done',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: IceColors.success,
      ),
    ),
  );
}

// ─── Start Mini Button ────────────────────────────────────────────────────────

class _StartMiniButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _StartMiniButton({required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 32,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: IceColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        minimumSize: Size.zero,
      ),
      child: const Text('Boshlash'),
    ),
  );
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: Colors.grey[200]!,
    highlightColor: Colors.grey[50]!,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (int i = 0; i < 5; i++) ...[
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    ),
  );
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(40),
    child: Column(
      children: [
        Icon(Icons.menu_book_outlined, size: 56, color: IceColors.muted),
        SizedBox(height: 16),
        Text(
          'No vocabulary yet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: IceColors.muted,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Your teacher will add vocabulary sets here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: IceColors.muted),
        ),
      ],
    ),
  );
}
