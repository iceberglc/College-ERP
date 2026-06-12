import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class StudentProgressScreen extends ConsumerWidget {
  const StudentProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentProgressProvider);
    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(studentProgressProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'My Progress',
                subtitle: 'Charts & learning analytics',
              ),
            ),
            async.when(
              loading: () =>
                  const SliverToBoxAdapter(child: _ProgressSkeleton()),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $e',
                      style: const TextStyle(color: IceColors.danger)),
                ),
              ),
              data: (d) => SliverToBoxAdapter(child: _ProgressContent(data: d)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProgressContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final activity = (data['activity_30d'] as List?)?.cast<num>() ?? [];
    final quizScores = (data['quiz_scores'] as List?)?.cast<num>() ?? [];
    final examResults = (data['exam_results'] as List?) ?? [];
    final attPct = data['attendance_pct'];
    final completedDays = data['completed_days'] ?? 0;
    final avgQuiz = data['avg_quiz_score'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary KPI row
          Row(children: [
            Expanded(
                child: _KpiTile(
                    label: 'Attendance',
                    value: attPct != null
                        ? '${(attPct as num).round()}%'
                        : '—',
                    color: IceColors.navyDeep,
                    icon: Icons.bar_chart_rounded,
                    delay: 0)),
            const SizedBox(width: 10),
            Expanded(
                child: _KpiTile(
                    label: 'Vocab Days',
                    value: '$completedDays',
                    color: IceColors.success,
                    icon: Icons.menu_book_rounded,
                    delay: 60)),
            const SizedBox(width: 10),
            Expanded(
                child: _KpiTile(
                    label: 'Avg Quiz',
                    value: avgQuiz != null
                        ? '${(avgQuiz as num).round()}%'
                        : '—',
                    color: IceColors.warning,
                    icon: Icons.quiz_rounded,
                    delay: 120)),
          ]),
          const SizedBox(height: 24),

          // 30-day activity chart
          if (activity.isNotEmpty) ...[
            _sectionLabel('30-Day Activity'),
            const SizedBox(height: 12),
            _ActivityBarChart(data: activity),
            const SizedBox(height: 24),
          ],

          // Quiz score trend
          if (quizScores.isNotEmpty) ...[
            _sectionLabel('Quiz Score Trend'),
            const SizedBox(height: 12),
            _LineChartCard(
              spots: quizScores.asMap().entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                  .toList(),
              color: IceColors.warning,
              maxY: 100,
              label: 'Score %',
            ),
            const SizedBox(height: 24),
          ],

          // Exam results per group
          if (examResults.isNotEmpty) ...[
            _sectionLabel('Exam Results'),
            const SizedBox(height: 12),
            ...examResults.asMap().entries.map((e) {
              final group = e.value as Map;
              final scores = (group['scores'] as List?)?.cast<num>() ?? [];
              return _ExamGroupCard(
                groupName: group['group_name']?.toString() ?? 'Group',
                scores: scores,
                index: e.key,
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final int delay;
  const _KpiTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IceColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: IceColors.muted)),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 280.ms)
        .scale(begin: const Offset(0.94, 0.94), duration: 280.ms);
  }
}

Widget _sectionLabel(String text) => Text(
      text,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: IceColors.text),
    );

class _ActivityBarChart extends StatelessWidget {
  final List<num> data;
  const _ActivityBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<double>(1, (m, v) => v.toDouble() > m ? v.toDouble() : m);
    return Container(
      height: 120,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IceColors.border),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxVal + 1,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i == 0 || i == data.length - 1 || i == data.length ~/ 2) {
                    return Text(
                      i == 0 ? '30d' : i == data.length - 1 ? 'Today' : '',
                      style: const TextStyle(fontSize: 9, color: IceColors.muted),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 16,
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
                color: IceColors.border.withAlpha(80), strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) {
            final val = e.value.toDouble();
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: val,
                color: val > 0
                    ? IceColors.navyDeep.withAlpha(180)
                    : IceColors.border,
                width: 6,
                borderRadius: BorderRadius.circular(2),
              ),
            ]);
          }).toList(),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, duration: 400.ms);
  }
}

class _LineChartCard extends StatelessWidget {
  final List<FlSpot> spots;
  final Color color;
  final double maxY;
  final String label;
  const _LineChartCard({
    required this.spots,
    required this.color,
    required this.maxY,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IceColors.border),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          clipData: const FlClipData.all(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${s.y.round()}%',
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ))
                  .toList(),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text('${v.round()}',
                    style:
                        const TextStyle(fontSize: 9, color: IceColors.muted)),
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
                color: IceColors.border.withAlpha(80), strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: color,
              barWidth: 2.5,
              dotData: FlDotData(
                show: spots.length <= 10,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3,
                    color: color,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [color.withAlpha(40), color.withAlpha(5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, duration: 400.ms);
  }
}

class _ExamGroupCard extends StatelessWidget {
  final String groupName;
  final List<num> scores;
  final int index;
  const _ExamGroupCard({
    required this.groupName,
    required this.scores,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final avg = scores.isEmpty
        ? 0.0
        : scores.fold<double>(0, (s, v) => s + v.toDouble()) / scores.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IceColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(groupName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: IceColors.text)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: IceColors.info.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Avg ${avg.round()}%',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: IceColors.info)),
              ),
            ],
          ),
          if (scores.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: _LineChartCard(
                spots: scores
                    .asMap()
                    .entries
                    .map((e) =>
                        FlSpot(e.key.toDouble(), e.value.toDouble()))
                    .toList(),
                color: IceColors.navyDeep,
                maxY: 100,
                label: '',
              ),
            ),
          ],
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.08, duration: 300.ms);
  }
}

class _ProgressSkeleton extends StatelessWidget {
  const _ProgressSkeleton();
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              Expanded(child: _box(80)),
              const SizedBox(width: 10),
              Expanded(child: _box(80)),
              const SizedBox(width: 10),
              Expanded(child: _box(80)),
            ]),
            const SizedBox(height: 20),
            _box(120),
            const SizedBox(height: 16),
            _box(160),
          ]),
        ),
      );
  Widget _box(double h) => Container(
      height: h,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)));
}
