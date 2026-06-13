import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/theme/app_theme.dart';

// ─── Superadmin Analytics ────────────────────────────────────────────────────
class SuperadminAnalyticsScreen extends ConsumerWidget {
  const SuperadminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats    = ref.watch(adminStatsProvider);
    final branches = ref.watch(adminBranchesProvider);
    final groups   = ref.watch(adminGroupsManageProvider);

    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(adminStatsProvider.future),
            ref.refresh(adminBranchesProvider.future),
            ref.refresh(adminGroupsManageProvider.future),
          ]);
        },
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _AnalyticsHeader()),
            stats.when(
              loading: () => const SliverToBoxAdapter(child: _Skeleton()),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: $e',
                        style: const TextStyle(color: IceColors.danger))),
              ),
              data: (d) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(children: [
                    // KPI grid
                    LayoutBuilder(builder: (ctx, c) {
                      final kpis = [
                        _Kpi('Students', '${d['student_count'] ?? d['total_students'] ?? 0}',
                            Icons.people_rounded, IceColors.navyDeep),
                        _Kpi('Active', '${d['active_students'] ?? 0}',
                            Icons.how_to_reg_rounded, IceColors.success),
                        _Kpi('Staff', '${d['staff_count'] ?? d['total_staff'] ?? 0}',
                            Icons.badge_rounded, IceColors.info),
                        _Kpi('Groups', '${d['group_count'] ?? d['total_groups'] ?? 0}',
                            Icons.group_work_rounded, IceColors.warning),
                        _Kpi('Archived', '${d['archived_groups'] ?? 0}',
                            Icons.archive_rounded, IceColors.muted),
                        _Kpi('Courses', '${d['course_count'] ?? 0}',
                            Icons.menu_book_rounded, IceColors.cyan),
                      ];
                      final cols = c.maxWidth >= 600 ? 3 : 2;
                      final w = (c.maxWidth - (cols - 1) * 10) / cols;
                      return Wrap(spacing: 10, runSpacing: 10, children: [
                        for (final k in kpis) SizedBox(width: w, child: _KpiCard(kpi: k)),
                      ]);
                    }),
                    const SizedBox(height: 16),
                    // Groups pie chart by course
                    groups.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (list) => _GroupsChart(groups: list),
                    ),
                  ]),
                ),
              ),
            ),
            // Branch breakdown
            branches.when(
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (list) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Branch Performance',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: IceColors.text)),
                      const SizedBox(height: 10),
                      ...list.asMap().entries.map((e) => _BranchRow(b: e.value, idx: e.key)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: kHeroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Analytics',
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900))
            .animate().slideX(begin: -0.1, duration: 400.ms).fadeIn(duration: 300.ms),
        const SizedBox(height: 4),
        Text('System-wide performance overview',
            style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 13))
            .animate(delay: 80.ms).fadeIn(),
      ]),
    );
  }
}

class _Kpi {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Kpi(this.label, this.value, this.icon, this.color);
}

class _KpiCard extends StatelessWidget {
  final _Kpi kpi;
  const _KpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: IceColors.border),
          boxShadow: [
            BoxShadow(
                color: kpi.color.withAlpha(16), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: kpi.color.withAlpha(20),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(kpi.icon, color: kpi.color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(kpi.value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kpi.color)),
          Text(kpi.label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: IceColors.muted)),
        ]),
      );
}

class _GroupsChart extends StatelessWidget {
  final List<dynamic> groups;
  const _GroupsChart({required this.groups});

  @override
  Widget build(BuildContext context) {
    // Count active vs archived
    final active = groups.where((g) => g['is_archived'] != true).length;
    final archived = groups.length - active;
    if (groups.isEmpty) return const SizedBox.shrink();

    final sections = [
      PieChartSectionData(
        value: active.toDouble(),
        color: IceColors.navyDeep,
        title: '$active',
        titleStyle: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
        radius: 60,
      ),
      if (archived > 0)
        PieChartSectionData(
          value: archived.toDouble(),
          color: IceColors.muted.withAlpha(80),
          title: '$archived',
          titleStyle: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
          radius: 60,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IceColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Groups Overview',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: IceColors.text)),
        const SizedBox(height: 16),
        Row(children: [
          SizedBox(
            height: 140,
            width: 140,
            child: PieChart(PieChartData(
              sections: sections,
              centerSpaceRadius: 35,
              sectionsSpace: 3,
            )),
          ),
          const SizedBox(width: 20),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Legend(color: IceColors.navyDeep, label: 'Active groups', count: active),
            const SizedBox(height: 10),
            _Legend(color: IceColors.muted, label: 'Archived', count: archived),
            const SizedBox(height: 10),
            _Legend(color: IceColors.navyDeep, label: 'Total', count: groups.length),
          ]),
        ]),
      ]),
    ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms);
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  const _Legend({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: IceColors.muted)),
          Text('$count',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w900, color: IceColors.text)),
        ]),
      ]);
}

class _BranchRow extends StatelessWidget {
  final dynamic b;
  final int idx;
  const _BranchRow({required this.b, required this.idx});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IceColors.border),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: IceColors.navyDeep.withAlpha(18),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.account_tree_rounded,
              color: IceColors.navyDeep, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b['name']?.toString() ?? '—',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14, color: IceColors.text)),
            if ((b['address'] ?? '').toString().isNotEmpty)
              Text(b['address'].toString(),
                  style: const TextStyle(fontSize: 12, color: IceColors.muted)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: IceColors.navyDeep.withAlpha(15),
              borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: IceColors.navyDeep),
        ),
      ]),
    )
        .animate(delay: Duration(milliseconds: 100 + idx * 60))
        .slideX(begin: 0.08, duration: 300.ms, curve: Curves.easeOut)
        .fadeIn(duration: 280.ms);
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
            const SizedBox(height: 8),
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
            const SizedBox(height: 16),
            _box(180),
          ]),
        ),
      );

  Widget _box(double h) => Container(
        height: h,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)));
}

// ─── Superadmin More Screen ───────────────────────────────────────────────────
class SuperadminMoreScreen extends StatelessWidget {
  const SuperadminMoreScreen({super.key});

  static const _tiles = [
    _Tile(icon: Icons.people_rounded,         label: 'Students',      path: '/superadmin/students'),
    _Tile(icon: Icons.badge_rounded,           label: 'Staff',         path: '/superadmin/staff'),
    _Tile(icon: Icons.contacts_rounded,        label: 'Leads',         path: '/superadmin/leads'),
    _Tile(icon: Icons.account_tree_rounded,    label: 'Branches',      path: '/superadmin/branches'),
    _Tile(icon: Icons.notifications_rounded,   label: 'Notifications', path: '/superadmin/notifications'),
    _Tile(icon: Icons.person_rounded,          label: 'Profile',       path: '/superadmin/profile'),
    _Tile(icon: Icons.logout_rounded,          label: 'Logout',        path: '/login', isLogout: true),
  ];

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final cols = MediaQuery.of(context).size.width >= 600 ? 3 : 2;

    return Scaffold(
      backgroundColor: IceColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, top > 0 ? 0 : 20, 20, 16),
              child: const Text('More',
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w900, color: IceColors.text)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                itemCount: _tiles.length,
                itemBuilder: (ctx, i) => _TileWidget(tile: _tiles[i], index: i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile {
  final IconData icon;
  final String label, path;
  final bool isLogout;
  const _Tile({
    required this.icon,
    required this.label,
    required this.path,
    this.isLogout = false,
  });
}

class _TileWidget extends StatelessWidget {
  final _Tile tile;
  final int index;
  const _TileWidget({required this.tile, required this.index});

  @override
  Widget build(BuildContext context) {
    final iconColor = tile.isLogout ? IceColors.danger : IceColors.navyDeep;
    final bgColor = tile.isLogout ? IceColors.danger.withAlpha(20) : IceColors.navyDeep.withAlpha(18);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go(tile.path),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: IceColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(tile.icon, color: iconColor, size: 26),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(tile.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tile.isLogout ? IceColors.danger : IceColors.text),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn(duration: 250.ms)
        .scale(begin: const Offset(0.92, 0.92), duration: 250.ms, curve: Curves.easeOut);
  }
}
