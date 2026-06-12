import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class StaffHomeScreen extends ConsumerWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final stats = ref.watch(staffStatsProvider);
    final groups = ref.watch(staffGroupsProvider);

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(staffStatsProvider.future),
            ref.refresh(staffGroupsProvider.future),
          ]);
        },
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildCleanHeader(context, user, greeting),
            ),

            stats.when(
              loading: () => const SliverToBoxAdapter(child: _Skeleton()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
              data: (d) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    children: [
                      // 2 columns on phones, 4 across on tablets/desktop.
                      LayoutBuilder(
                        builder: (context, c) {
                          final cards = <Widget>[
                            _StatCard(
                              value: fmtNum(d['total_students']),
                              label: 'Students',
                              icon: Icons.people_rounded,
                              color: IceColors.navyDeep,
                              delay: 0,
                            ),
                            _StatCard(
                              value: fmtNum(d['total_groups']),
                              label: 'My Groups',
                              icon: Icons.group_rounded,
                              color: IceColors.info,
                              delay: 80,
                            ),
                            _StatCard(
                              value: fmtNum(d['sessions_today']),
                              label: 'Sessions Today',
                              icon: Icons.today_rounded,
                              color: IceColors.cyan,
                              delay: 160,
                            ),
                            _StatCard(
                              value: fmtPercent(d['avg_attendance']),
                              label: 'Avg Attendance',
                              icon: Icons.bar_chart_rounded,
                              color: IceColors.success,
                              delay: 240,
                            ),
                          ];
                          final cols = c.maxWidth >= 600 ? 4 : 2;
                          final w = (c.maxWidth - (cols - 1) * 10) / cols;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final card in cards)
                                SizedBox(width: w, child: card),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _StaffAttendanceChart(data: d),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                child: const Text(
                  'My Groups',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: IceColors.text,
                  ),
                ).animate(delay: 400.ms).fadeIn(),
              ),
            ),

            groups.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: IceColors.navyDeep),
                  ),
                ),
              ),
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
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No groups assigned.',
                          style: TextStyle(color: IceColors.muted),
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((_, i) {
                    if (i == list.length) return const SizedBox(height: 100);
                    return _GroupCard(group: list[i], index: i);
                  }, childCount: list.length + 1),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanHeader(
    BuildContext context,
    IceUser? user,
    String greeting,
  ) {
    final name = user?.firstName.isNotEmpty == true
        ? user!.firstName
        : 'Teacher';
    final full = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    final initials = full.isNotEmpty
        ? full
              .split(' ')
              .where((p) => p.isNotEmpty)
              .take(2)
              .map((p) => p[0])
              .join()
              .toUpperCase()
        : 'T';
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: IceColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 2),
                Text(
                      name,
                      style: const TextStyle(
                        color: IceColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                    .animate(delay: 60.ms)
                    .slideX(
                      begin: -0.08,
                      duration: 350.ms,
                      curve: Curves.easeOut,
                    )
                    .fadeIn(duration: 300.ms),
              ],
            ),
          ),
          Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: IceColors.lime,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: IceColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
              .animate(delay: 150.ms)
              .scale(duration: 350.ms, curve: Curves.elasticOut),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final int delay;
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(20),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: IceColors.muted,
                ),
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 400 + delay))
        .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut)
        .fadeIn(duration: 350.ms);
  }
}

class _GroupCard extends StatelessWidget {
  final dynamic group;
  final int index;
  const _GroupCard({required this.group, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: IceColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: IceColors.navyDeep.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.group_rounded,
                  size: 20,
                  color: IceColors.navyDeep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group['name']?.toString() ?? '—',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (group['subject'] != null || group['course'] != null)
                      Text(
                        (group['subject'] ?? group['course'])?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: IceColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: IceColors.navyDeep.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${group['student_count'] ?? '—'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: IceColors.navyDeep,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 500 + index * 80))
        .slideX(begin: 0.1, duration: 350.ms, curve: Curves.easeOut)
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
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _box(90)),
              const SizedBox(width: 10),
              Expanded(child: _box(90)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _box(90)),
              const SizedBox(width: 10),
              Expanded(child: _box(90)),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _box(double h) => Container(
    height: h,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
  );
}

class _StaffAttendanceChart extends StatelessWidget {
  final Map data;
  const _StaffAttendanceChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final spark = (data['attendance_spark'] as List?)?.cast<num>() ?? [];
    if (spark.isEmpty) return const SizedBox.shrink();

    final spots = spark
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();
    final maxY =
        spark.map((v) => v.toDouble()).reduce((a, b) => a > b ? a : b) + 10;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IceColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Trend',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: IceColors.text,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: BarChart(
              BarChartData(
                maxY: maxY.clamp(0, 110),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                barGroups: spots
                    .map(
                      (s) => BarChartGroupData(
                        x: s.x.toInt(),
                        barRods: [
                          BarChartRodData(
                            toY: s.y,
                            width: 18,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            color: IceColors.navyDeep.withAlpha(
                              s.y > 70
                                  ? 220
                                  : s.y > 50
                                  ? 150
                                  : 80,
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 350.ms).fadeIn(duration: 400.ms);
  }
}
