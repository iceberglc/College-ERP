import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/theme/ice_tokens.dart';
import '../../../shared/widgets/ice_kit.dart';
import '../../../shared/widgets/ice_shell.dart';

/// Vocabulary Days — summary stats + filterable day list.
class StudentVocabularyScreen extends ConsumerStatefulWidget {
  const StudentVocabularyScreen({super.key});

  @override
  ConsumerState<StudentVocabularyScreen> createState() =>
      _StudentVocabularyScreenState();
}

class _StudentVocabularyScreenState
    extends ConsumerState<StudentVocabularyScreen> {
  int _tab = 0; // 0 all · 1 completed · 2 pending

  @override
  Widget build(BuildContext context) {
    final vocab = ref.watch(vocabularyProvider);

    return vocab.when(
      loading: () => const PageSkeleton(),
      error: (e, _) => ErrorState(
        error: e,
        onRetry: () => ref.invalidate(vocabularyProvider),
      ),
      data: (days) => _buildBody(context, days),
    );
  }

  Widget _buildBody(BuildContext context, List days) {
    final t = context.ice;
    final completed = days.where((d) => d['is_completed'] == true).length;
    final totalWords = days.fold<int>(
      0,
      (sum, d) => sum + ((d['word_count'] as num?)?.toInt() ?? 0),
    );
    final pct = days.isEmpty ? 0 : (completed / days.length * 100).round();

    final visible = switch (_tab) {
      1 => days.where((d) => d['is_completed'] == true).toList(),
      2 => days.where((d) => d['is_completed'] != true).toList(),
      _ => days,
    };

    return IcePage(
      title: 'Vocabulary Days',
      subtitle: 'Track and practice new words',
      onRefresh: () async => ref.refresh(vocabularyProvider.future),
      children: [
        // ── Summary tiles ────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _MiniStat(label: 'Total Days', value: '${days.length}'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(label: 'Completed', value: '$completed'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                label: 'Completion',
                value: '$pct%',
                accent: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(label: 'Total Words', value: '$totalWords'),
            ),
          ],
        ),
        const SizedBox(height: 18),

        IceChipTabs(
          tabs: const ['All Days', 'Completed', 'Pending'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 16),

        if (days.isEmpty)
          const IceCard(
            child: EmptyState(
              icon: Icons.menu_book_rounded,
              title: 'No vocabulary yet',
              message:
                  'Your teacher hasn\'t released any vocabulary days. Check back soon!',
            ),
          )
        else if (visible.isEmpty)
          IceCard(
            child: EmptyState(
              icon: Icons.filter_alt_off_rounded,
              title: _tab == 1 ? 'Nothing completed yet' : 'Nothing pending',
              message: _tab == 1
                  ? 'Finish a day with a 60%+ quiz score to complete it.'
                  : 'Great job — every released day is done!',
            ),
          )
        else
          ...visible.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DayCard(day: d as Map<String, dynamic>),
            ),
          ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Days unlock when your teacher releases them.',
            style: TextStyle(fontSize: 12, color: t.textLow),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  const _MiniStat({
    required this.label,
    required this.value,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.ice;
    return IceCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      radius: 16,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: accent ? t.accent : t.textHi,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: t.textMid,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final Map<String, dynamic> day;
  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final t = context.ice;
    final done = day['is_completed'] == true;
    final release = DateTime.tryParse(day['release_at'] ?? '');

    return IceCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.go('/student/vocabulary/${day['id']}'),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: done ? t.accentSoft : t.inset,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '${day['day_number']}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: done ? t.accent : t.textHi,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day ${day['day_number']}'
                  '${(day['title'] as String?)?.isNotEmpty == true ? ' — ${day['title']}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: t.textHi,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (release != null)
                      DateFormat('MMM dd, yyyy').format(release),
                    '${day['word_count'] ?? 0} words',
                  ].join('  ·  '),
                  style: TextStyle(fontSize: 12, color: t.textMid),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(
            done ? 'Completed' : 'Pending',
            tone: done ? BadgeTone.accent : BadgeTone.amber,
          ),
        ],
      ),
    );
  }
}
