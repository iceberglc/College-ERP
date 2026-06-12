import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class StudentResultsScreen extends ConsumerWidget {
  const StudentResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(studentResultsProvider);

    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(studentResultsProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'My Results',
                subtitle: 'Exam scores and grades',
                avatar: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withAlpha(30)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.grade_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
            data.when(
              loading: () => const SliverToBoxAdapter(child: _Skeleton()),
              error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error: $e',
                          style: const TextStyle(color: IceColors.danger)))),
              data: (d) {
                final List<dynamic> results =
                    (d['results'] as List<dynamic>?) ?? <dynamic>[];
                if (results.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                          child: Text('No results yet.',
                              style: TextStyle(color: IceColors.muted))),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      if (i == 0) return const SizedBox(height: 20);
                      if (i == results.length + 1) return const SizedBox(height: 100);
                      return _ResultCard(result: results[i - 1], index: i - 1);
                    },
                    childCount: results.length + 2,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final dynamic result;
  final int index;
  const _ResultCard({required this.result, required this.index});

  @override
  Widget build(BuildContext context) {
    final subject = result['subject']?.toString() ?? '—';
    final exam    = result['exam_type']?.toString() ?? result['type']?.toString() ?? '';
    final score   = result['score'] ?? result['marks'];
    final total   = result['total_marks'] ?? result['max_marks'] ?? 100;
    final pct     = (score != null && total != null)
        ? (double.tryParse(score.toString()) ?? 0) /
              (double.tryParse(total.toString()) ?? 100) * 100
        : null;
    final color = pct == null
        ? IceColors.muted
        : pct >= 70 ? IceColors.success : pct >= 50 ? IceColors.warning : IceColors.danger;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: color.withAlpha(15), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                score?.toString() ?? '—',
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 15, color: color),
              ),
              if (pct != null)
                Text(
                  '${pct.round()}%',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 9, color: color.withAlpha(180)),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(subject,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            if (exam.isNotEmpty) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: IceColors.navyDeep.withAlpha(12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(exam,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: IceColors.navyDeep)),
              ),
            ],
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('/ $total',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: IceColors.muted)),
          if (pct != null) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: 50,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 4,
                  backgroundColor: color.withAlpha(20),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ],
        ]),
      ]),
    )
        .animate(delay: Duration(milliseconds: 350 + index * 70))
        .slideX(begin: 0.08, duration: 350.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(children: List.generate(
            5,
            (_) => Container(
              height: 72,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(18)),
            ),
          )),
        ),
      );
}
