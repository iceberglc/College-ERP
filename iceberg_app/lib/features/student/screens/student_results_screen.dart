import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/ice_tokens.dart';
import '../../../shared/widgets/ice_kit.dart';
import '../../../shared/widgets/ice_shell.dart';

/// Results — average score, total marks, passed subjects + per-subject bars.
/// Grading scale: test out of 40, exam out of 60, total out of 100.
class StudentResultsScreen extends ConsumerWidget {
  const StudentResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(studentResultsProvider);

    return results.when(
      loading: () => const PageSkeleton(),
      error: (e, _) => ErrorState(
        error: e,
        onRetry: () => ref.invalidate(studentResultsProvider),
      ),
      data: (data) => _buildBody(context, ref, data),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
  ) {
    final s = ref.watch(stringsProvider);
    final rows = ((data['results'] as List?) ?? [])
        .cast<Map<String, dynamic>>();

    if (rows.isEmpty) {
      return IcePage(
        title: s('Results'),
        onRefresh: () async => ref.refresh(studentResultsProvider.future),
        children: [
          IceCard(
            child: EmptyState(
              icon: Icons.workspace_premium_outlined,
              title: s('No results yet.'),
              message: 'Your subject results will appear here once published.',
            ),
          ),
        ],
      );
    }

    final totals = rows.map((r) {
      final test = (r['test'] as num?)?.toDouble() ?? 0;
      final exam = (r['exam'] as num?)?.toDouble() ?? 0;
      return test + exam; // out of 100
    }).toList();
    final avg = totals.reduce((a, b) => a + b) / totals.length;
    final passed = totals.where((v) => v >= 60).length;
    final totalMarks = totals.reduce((a, b) => a + b);

    return IcePage(
      title: s('Results'),
      onRefresh: () async => ref.refresh(studentResultsProvider.future),
      children: [
        // ── Summary grid ─────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                value: '${avg.toStringAsFixed(1)}%',
                label: 'Average Score',
                accent: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                value: totalMarks.toStringAsFixed(0),
                label: 'Total Marks',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                value: '$passed / ${rows.length}',
                label: 'Passed Subjects',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                value: avg >= 90
                    ? 'A'
                    : avg >= 75
                    ? 'B'
                    : avg >= 60
                    ? 'C'
                    : 'D',
                label: 'Overall Grade',
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        const SectionHeader('Subject Performance'),
        ...rows.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SubjectRow(r: r),
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String value;
  final String label;
  final bool accent;
  const _SummaryTile({
    required this.value,
    required this.label,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.ice;
    return IceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: accent ? t.accent : t.textHi,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: t.textMid,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final Map<String, dynamic> r;
  const _SubjectRow({required this.r});

  @override
  Widget build(BuildContext context) {
    final t = context.ice;
    final test = (r['test'] as num?)?.toDouble() ?? 0;
    final exam = (r['exam'] as num?)?.toDouble() ?? 0;
    final total = test + exam;
    final pass = total >= 60;

    return IceCard(
      padding: const EdgeInsets.all(16),
      onTap: () => _showDetail(context, test, exam, total),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r['group_name'] ?? 'Subject',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: t.textHi,
                  ),
                ),
              ),
              Text(
                '${total.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: pass ? t.accent : t.coral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: total / 100,
              minHeight: 7,
              backgroundColor: t.inset,
              valueColor: AlwaysStoppedAnimation(pass ? t.accent : t.coral),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniMetric(
                label: 'Test',
                value: '${test.toStringAsFixed(0)}/40',
              ),
              const SizedBox(width: 16),
              _MiniMetric(
                label: 'Exam',
                value: '${exam.toStringAsFixed(0)}/60',
              ),
              const Spacer(),
              StatusBadge(
                pass ? 'Passed' : 'Retake',
                tone: pass ? BadgeTone.accent : BadgeTone.coral,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetail(
    BuildContext context,
    double test,
    double exam,
    double total,
  ) {
    final t = context.ice;
    showModalBottomSheet(
      context: context,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r['group_name'] ?? 'Subject',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: t.textHi,
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Test score',
              value: '${test.toStringAsFixed(0)} / 40',
            ),
            _DetailRow(
              label: 'Exam score',
              value: '${exam.toStringAsFixed(0)} / 60',
            ),
            _DetailRow(
              label: 'Total',
              value: '${total.toStringAsFixed(0)} / 100',
            ),
            _DetailRow(
              label: 'Percentage',
              value: '${total.toStringAsFixed(1)}%',
              accent: true,
            ),
            if ((r['comment'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              MicroLabel('Teacher comment'),
              const SizedBox(height: 6),
              Text(
                r['comment'],
                style: TextStyle(fontSize: 14, color: t.textMid, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = context.ice;
    return Row(
      children: [
        Text('$label ', style: TextStyle(fontSize: 12, color: t.textLow)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: t.textMid,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  const _DetailRow({
    required this.label,
    required this.value,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.ice;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: t.textMid)),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: accent ? t.accent : t.textHi,
            ),
          ),
        ],
      ),
    );
  }
}
