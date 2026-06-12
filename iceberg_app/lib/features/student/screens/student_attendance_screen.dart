import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/ice_page_header.dart';

class StudentAttendanceScreen extends ConsumerWidget {
  const StudentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(studentAttendanceProvider);

    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(studentAttendanceProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Attendance',
                subtitle: 'Subject-wise breakdown',
                avatar: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withAlpha(30)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.bar_chart_rounded,
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
                final overall  = d['overall_percentage'];
                final subjects = (d['subjects'] as List?) ?? [];
                return SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    if (overall != null)
                      _OverallBanner(percent: overall),
                    if (subjects.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text('By Subject',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: IceColors.text)),
                      ),
                      ...subjects.asMap().entries.map(
                          (e) => _SubjectCard(subject: e.value, index: e.key)),
                    ] else
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: Text('No subjects found.',
                            style: TextStyle(color: IceColors.muted))),
                      ),
                    const SizedBox(height: 100),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallBanner extends StatelessWidget {
  final dynamic percent;
  const _OverallBanner({required this.percent});

  @override
  Widget build(BuildContext context) {
    final pct   = (percent is num) ? percent.toDouble() : double.tryParse(percent.toString()) ?? 0.0;
    final color = pct >= 75 ? IceColors.success : pct >= 60 ? IceColors.warning : IceColors.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: color.withAlpha(30), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Overall Attendance',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: IceColors.muted)),
              const SizedBox(height: 6),
              Text(fmtPercent(pct),
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: color)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 8,
                  backgroundColor: color.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              pct >= 75 ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: color,
              size: 28,
            ),
          ),
        ]),
      ),
    )
        .animate(delay: 300.ms)
        .slideY(begin: 0.2, duration: 450.ms, curve: Curves.easeOut)
        .fadeIn(duration: 350.ms);
  }
}

class _SubjectCard extends StatelessWidget {
  final dynamic subject;
  final int index;
  const _SubjectCard({required this.subject, required this.index});

  @override
  Widget build(BuildContext context) {
    final name    = subject['subject']?.toString() ?? subject['name']?.toString() ?? '—';
    final present = subject['present'] ?? 0;
    final total   = subject['total'] ?? 0;
    final pct     = total > 0 ? (present / total * 100) : 0.0;
    final color   = pct >= 75 ? IceColors.success : pct >= 60 ? IceColors.warning : IceColors.danger;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: IceColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(fmtPercent(pct),
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13, color: color)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 7,
            backgroundColor: color.withAlpha(20),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 6),
        Text('$present of $total classes attended',
            style: const TextStyle(fontSize: 11, color: IceColors.muted)),
      ]),
    )
        .animate(delay: Duration(milliseconds: 450 + index * 70))
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
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const SizedBox(height: 20),
            _box(100),
            const SizedBox(height: 10),
            _box(72),
            const SizedBox(height: 8),
            _box(72),
            const SizedBox(height: 8),
            _box(72),
          ]),
        ),
      );

  Widget _box(double h) => Container(
        height: h,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(18)),
      );
}
