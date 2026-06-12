import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class SuperadminAnalyticsScreen extends ConsumerWidget {
  const SuperadminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);
    final branches = ref.watch(adminBranchesProvider);

    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(adminStatsProvider.future),
            ref.refresh(adminBranchesProvider.future),
          ]);
        },
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Analytics',
                subtitle: 'Global counts and branch distribution',
              ),
            ),
            stats.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
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
              data: (data) {
                final cards = [
                  _Metric(
                    Icons.people_rounded,
                    'Students',
                    data['student_count'] ?? data['total_students'] ?? 0,
                    IceColors.navyDeep,
                  ),
                  _Metric(
                    Icons.person_pin_rounded,
                    'Active Students',
                    data['active_students'] ?? 0,
                    IceColors.success,
                  ),
                  _Metric(
                    Icons.badge_rounded,
                    'Staff',
                    data['staff_count'] ?? data['total_staff'] ?? 0,
                    IceColors.info,
                  ),
                  _Metric(
                    Icons.group_work_rounded,
                    'Groups',
                    data['group_count'] ?? data['total_groups'] ?? 0,
                    IceColors.warning,
                  ),
                  _Metric(
                    Icons.archive_rounded,
                    'Archived',
                    data['archived_groups'] ?? 0,
                    IceColors.muted,
                  ),
                  _Metric(
                    Icons.menu_book_rounded,
                    'Courses',
                    data['course_count'] ?? data['total_courses'] ?? 0,
                    IceColors.navy,
                  ),
                ];

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final cols = c.maxWidth >= 900 ? 3 : 2;
                        final width = (c.maxWidth - (cols - 1) * 10) / cols;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final card in cards)
                              SizedBox(
                                width: width,
                                child: _MetricCard(metric: card),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            branches.when(
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (list) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Branch Coverage',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: IceColors.text,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (list.isEmpty)
                        const _SuperadminEmpty(
                          icon: Icons.account_tree_outlined,
                          title: 'No branches',
                          text: 'Branches created by admins appear here.',
                        )
                      else
                        ...list.map(
                          (branch) => _BranchRow(branch: branch as Map),
                        ),
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

class SuperadminMoreScreen extends StatelessWidget {
  const SuperadminMoreScreen({super.key});

  static const _items = [
    _SuperadminAction(Icons.dashboard_rounded, 'Dashboard', '/superadmin/home'),
    _SuperadminAction(
      Icons.account_tree_rounded,
      'Branches',
      '/superadmin/branches',
    ),
    _SuperadminAction(
      Icons.analytics_rounded,
      'Analytics',
      '/superadmin/analytics',
    ),
    _SuperadminAction(Icons.people_rounded, 'Students', '/superadmin/students'),
    _SuperadminAction(Icons.badge_rounded, 'Teachers', '/superadmin/staff'),
    _SuperadminAction(Icons.contacts_rounded, 'Leads', '/superadmin/leads'),
    _SuperadminAction(
      Icons.notifications_rounded,
      'Notifications',
      '/superadmin/notifications',
    ),
    _SuperadminAction(Icons.person_rounded, 'Profile', '/superadmin/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 900
        ? 4
        : width >= 600
        ? 3
        : 2;
    return Scaffold(
      backgroundColor: IceColors.bg,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: IcePageHeader(
              title: 'More',
              subtitle: 'Global administration tools',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: _items.length,
              itemBuilder: (context, index) =>
                  _SuperadminActionCard(item: _items[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _Metric metric;
  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: IceColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: IceColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: metric.color.withAlpha(18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(metric.icon, color: metric.color, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${metric.value}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: IceColors.text,
                ),
              ),
              Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: IceColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BranchRow extends StatelessWidget {
  final Map branch;
  const _BranchRow({required this.branch});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: IceColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: IceColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: IceColors.navyDeep.withAlpha(14),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.account_tree_rounded,
            color: IceColors.navyDeep,
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                branch['name']?.toString() ?? 'Branch',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: IceColors.text,
                ),
              ),
              if ((branch['address'] ?? '').toString().isNotEmpty)
                Text(
                  branch['address'].toString(),
                  style: const TextStyle(fontSize: 12, color: IceColors.muted),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SuperadminActionCard extends StatelessWidget {
  final _SuperadminAction item;
  const _SuperadminActionCard({required this.item});

  @override
  Widget build(BuildContext context) => Material(
    color: IceColors.surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.go(item.path),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: IceColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: IceColors.navyDeep.withAlpha(14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, color: IceColors.navyDeep, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: IceColors.text,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SuperadminEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _SuperadminEmpty({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: IceColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: IceColors.border),
    ),
    child: Column(
      children: [
        Icon(icon, size: 44, color: IceColors.muted),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: IceColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: IceColors.muted),
        ),
      ],
    ),
  );
}

class _Metric {
  final IconData icon;
  final String label;
  final Object value;
  final Color color;
  const _Metric(this.icon, this.label, this.value, this.color);
}

class _SuperadminAction {
  final IconData icon;
  final String label;
  final String path;
  const _SuperadminAction(this.icon, this.label, this.path);
}
