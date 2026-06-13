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
import '../../../shared/widgets/ice_page_header.dart';

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
                final recentLeads = (d['recent_leads'] as List?) ?? [];
                final recentEnrollments = (d['recent_enrollments'] as List?) ?? [];
                final cards = <_StatCard>[
                  _StatCard(
                    value: fmtNum(stats['total_students']),
                    label: 'Students',
                    icon: Icons.people_rounded,
                    color: IceColors.navyDeep,
                    delay: 0,
                    onTap: () => context.go('/admin/students'),
                  ),
                  _StatCard(
                    value: fmtNum(stats['total_staff']),
                    label: 'Staff',
                    icon: Icons.badge_rounded,
                    color: IceColors.info,
                    delay: 80,
                    onTap: () => context.go('/admin/staff'),
                  ),
                  _StatCard(
                    value: fmtNum(stats['total_groups']),
                    label: 'Groups',
                    icon: Icons.group_rounded,
                    color: IceColors.cyan,
                    delay: 160,
                    onTap: () => context.go('/admin/groups'),
                  ),
                  _StatCard(
                    value: fmtPercent(stats['avg_attendance']),
                    label: 'Avg Attendance',
                    icon: Icons.bar_chart_rounded,
                    color: IceColors.success,
                    delay: 240,
                    onTap: () => context.go('/admin/attendance'),
                  ),
                  _StatCard(
                    value: fmtNum(stats['new_leads'] ?? stats['total_leads']),
                    label: 'New Leads',
                    icon: Icons.contacts_rounded,
                    color: IceColors.warning,
                    delay: 320,
                    onTap: () => context.go('/admin/leads'),
                  ),
                  _StatCard(
                    value: fmtNum(stats['total_branches']),
                    label: 'Branches',
                    icon: Icons.location_city_rounded,
                    color: IceColors.muted,
                    delay: 400,
                    onTap: () => context.go('/admin/branches'),
                  ),
                ];
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    child: Column(children: [
                      // 2 columns on phones, 3 on tablets/desktop.
                      LayoutBuilder(builder: (context, c) {
                        final cols = c.maxWidth >= 600 ? 3 : 2;
                        final w = (c.maxWidth - (cols - 1) * 10) / cols;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final card in cards)
                              SizedBox(width: w, child: card),
                          ],
                        );
                      }),
                      const SizedBox(height: 16),
                      _AttendanceTrendChart(stats: stats),
                      const SizedBox(height: 16),
                      _QuickActionsGrid(),
                      if (recentLeads.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _ActivityFeed(
                          title: 'Recent Leads',
                          icon: Icons.contacts_rounded,
                          color: IceColors.warning,
                          items: recentLeads.map((l) => _ActivityItem(
                            title: l['name']?.toString() ?? '—',
                            subtitle: l['course']?.toString() ?? l['phone']?.toString() ?? '',
                            trailing: l['date']?.toString() ?? '',
                            icon: Icons.person_add_rounded,
                            color: IceColors.warning,
                          )).toList(),
                          onTapAll: () => context.go('/admin/leads'),
                        ),
                      ],
                      if (recentEnrollments.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _ActivityFeed(
                          title: 'Recent Enrollments',
                          icon: Icons.how_to_reg_rounded,
                          color: IceColors.success,
                          items: recentEnrollments.map((e) => _ActivityItem(
                            title: e['student']?.toString() ?? '—',
                            subtitle: e['group']?.toString() ?? '',
                            trailing: '',
                            icon: Icons.school_rounded,
                            color: IceColors.success,
                          )).toList(),
                          onTapAll: () => context.go('/admin/students'),
                        ),
                      ],
                      const SizedBox(height: 100),
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
    // Phones: hero bleeds to the screen edges (mobile pattern).
    // Tablets/desktop: floating rounded card with margins.
    final wide = MediaQuery.sizeOf(context).width >= 768;
    return Container(
      margin: wide ? const EdgeInsets.fromLTRB(16, 16, 16, 0) : EdgeInsets.zero,
      padding: EdgeInsets.fromLTRB(
          20, wide ? 24 : MediaQuery.paddingOf(context).top + 20, 20, 28),
      decoration: BoxDecoration(
        gradient: kHeroGradient,
        borderRadius: wide
            ? BorderRadius.circular(28)
            : const BorderRadius.vertical(bottom: Radius.circular(32)),
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


// ─── Quick Actions Grid ───────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action(Icons.person_add_rounded,     'Add Student',   '/admin/students/add', IceColors.navyDeep),
      _Action(Icons.badge_rounded,           'Add Staff',     '/admin/staff/add',    IceColors.info),
      _Action(Icons.group_add_rounded,       'Add Group',     '/admin/groups/add',   IceColors.cyan),
      _Action(Icons.receipt_long_rounded,    'Payments',      '/admin/payments',     IceColors.success),
      _Action(Icons.fact_check_rounded,      'Attendance',    '/admin/attendance',   IceColors.warning),
      _Action(Icons.notifications_rounded,   'Notify',        '/admin/notify',       IceColors.danger),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IceColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quick Actions',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: IceColors.text)),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (ctx, c) {
          final cols = c.maxWidth >= 480 ? 6 : 3;
          final w = (c.maxWidth - (cols - 1) * 8) / cols;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions
                .asMap()
                .entries
                .map((e) => SizedBox(
                      width: w,
                      child: _ActionBtn(a: e.value, delay: e.key * 50),
                    ))
                .toList(),
          );
        }),
      ]),
    ).animate(delay: 500.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, duration: 400.ms);
  }
}

class _Action {
  final IconData icon;
  final String label, path;
  final Color color;
  const _Action(this.icon, this.label, this.path, this.color);
}

class _ActionBtn extends StatelessWidget {
  final _Action a;
  final int delay;
  const _ActionBtn({required this.a, required this.delay});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.go(a.path),
        child: Column(children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: a.color.withAlpha(18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: a.color.withAlpha(40)),
            ),
            child: Center(child: Icon(a.icon, color: a.color, size: 22)),
          ),
          const SizedBox(height: 5),
          Text(a.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: IceColors.muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ]),
      )
          .animate(delay: Duration(milliseconds: delay))
          .scale(begin: const Offset(0.9, 0.9), duration: 250.ms, curve: Curves.easeOut)
          .fadeIn(duration: 200.ms);
}

// ─── Activity Feed ────────────────────────────────────────────────────────────
class _ActivityItem {
  final String title, subtitle, trailing;
  final IconData icon;
  final Color color;
  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.icon,
    required this.color,
  });
}

class _ActivityFeed extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_ActivityItem> items;
  final VoidCallback onTapAll;

  const _ActivityFeed({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.onTapAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IceColors.border),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
                color: color.withAlpha(20), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: IceColors.text)),
          ),
          GestureDetector(
            onTap: onTapAll,
            child: Text('See all',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ),
        ]),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((e) => _ActivityRow(item: e.value, idx: e.key, isLast: e.key == items.length - 1)),
      ]),
    ).animate(delay: 600.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08, duration: 400.ms);
  }
}

class _ActivityRow extends StatelessWidget {
  final _ActivityItem item;
  final int idx;
  final bool isLast;
  const _ActivityRow({required this.item, required this.idx, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: item.color.withAlpha(18),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13, color: IceColors.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              if (item.subtitle.isNotEmpty)
                Text(item.subtitle,
                    style: const TextStyle(fontSize: 11, color: IceColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
            ]),
          ),
          if (item.trailing.isNotEmpty)
            Text(item.trailing,
                style: const TextStyle(fontSize: 11, color: IceColors.muted)),
        ]),
      ),
      if (!isLast)
        const Divider(height: 1, color: IceColors.border),
    ]);
  }
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
