import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final dash = ref.watch(adminDashProvider);

    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminDashProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, user)),
            dash.when(
              loading: () => const SliverToBoxAdapter(child: _Skeleton()),
              error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error: $e',
                          style: const TextStyle(color: IceColors.danger)))),
              data: (d) {
                final stats = d['stats'] ?? d;
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    child: Column(children: [
                      Row(children: [
                        Expanded(child: _StatCard(
                          value: fmtNum(stats['total_students']),
                          label: 'Students',
                          icon: Icons.people_rounded,
                          color: IceColors.navyDeep,
                          delay: 0,
                          onTap: () => context.go('/admin/students'),
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCard(
                          value: fmtNum(stats['total_staff']),
                          label: 'Staff',
                          icon: Icons.badge_rounded,
                          color: IceColors.info,
                          delay: 80,
                          onTap: () => context.go('/admin/staff'),
                        )),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _StatCard(
                          value: fmtNum(stats['total_groups']),
                          label: 'Groups',
                          icon: Icons.group_rounded,
                          color: IceColors.cyan,
                          delay: 160,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCard(
                          value: fmtPercent(stats['avg_attendance']),
                          label: 'Avg Attendance',
                          icon: Icons.bar_chart_rounded,
                          color: IceColors.success,
                          delay: 240,
                        )),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _StatCard(
                          value: fmtNum(stats['new_leads'] ?? stats['total_leads']),
                          label: 'New Leads',
                          icon: Icons.contacts_rounded,
                          color: IceColors.warning,
                          delay: 320,
                          onTap: () => context.go('/admin/leads'),
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCard(
                          value: fmtNum(stats['total_branches']),
                          label: 'Branches',
                          icon: Icons.location_city_rounded,
                          color: IceColors.muted,
                          delay: 400,
                        )),
                      ]),
                      const SizedBox(height: 16),
                      _AttendanceTrendChart(stats: stats),
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, IceUser? user) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.paddingOf(context).top + 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: kHeroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Admin Panel',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900))
                    .animate()
                    .slideX(begin: -0.1, duration: 400.ms, curve: Curves.easeOut)
                    .fadeIn(duration: 300.ms),
                const SizedBox(height: 4),
                Text(
                  user?.fullName.isNotEmpty == true ? user!.fullName : 'Welcome back',
                  style: TextStyle(
                      color: Colors.white.withAlpha(160),
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ).animate(delay: 80.ms).fadeIn(),
              ]),
            ),
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withAlpha(30)),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 22),
            ).animate(delay: 200.ms).scale(duration: 400.ms, curve: Curves.elasticOut),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            _QuickChip(
                icon: Icons.people_rounded,
                label: 'Students',
                onTap: () => context.go('/admin/students')),
            const SizedBox(width: 10),
            _QuickChip(
                icon: Icons.badge_rounded,
                label: 'Staff',
                onTap: () => context.go('/admin/staff')),
            const SizedBox(width: 10),
            _QuickChip(
                icon: Icons.contacts_rounded,
                label: 'Leads',
                onTap: () => context.go('/admin/leads')),
          ])
              .animate(delay: 300.ms)
              .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut)
              .fadeIn(duration: 300.ms),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(18),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withAlpha(30)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: IceColors.cyan),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final int delay;
  final VoidCallback? onTap;
  const _StatCard({
    required this.value, required this.label,
    required this.icon,  required this.color, required this.delay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withAlpha(20), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Row(children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500, color: IceColors.muted)),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 10, color: color.withAlpha(120)),
          ]),
        ]),
      ),
    )
        .animate(delay: Duration(milliseconds: 400 + delay))
        .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut)
        .fadeIn(duration: 350.ms);
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
            Row(children: [
              Expanded(child: _box(90)),
              const SizedBox(width: 10),
              Expanded(child: _box(90)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _box(90)),
              const SizedBox(width: 10),
              Expanded(child: _box(90)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _box(90)),
              const SizedBox(width: 10),
              Expanded(child: _box(90)),
            ]),
          ]),
        ),
      );

  Widget _box(double h) => Container(
        height: h,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)),
      );
}


class _AttendanceTrendChart extends StatelessWidget {
  final Map stats;
  const _AttendanceTrendChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final sparkData = (stats['attendance_spark'] as List?)?.cast<num>() ?? [];
    if (sparkData.isEmpty) return const SizedBox.shrink();

    final spots = sparkData.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
    final maxY = sparkData.map((v) => v.toDouble()).reduce((a, b) => a > b ? a : b) + 10;

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
          const Text('Attendance Trend (7 days)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: IceColors.text)),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY.clamp(0, 110),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: IceColors.navyDeep,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: IceColors.navyDeep.withAlpha(30),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 450.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms);
  }
}
