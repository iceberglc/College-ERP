import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class SuperadminHomeScreen extends ConsumerWidget {
  const SuperadminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
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
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Global Overview',
                subtitle: 'Welcome, ${user?.firstName ?? "Superadmin"}',
              ),
            ),
            stats.when(
              loading: () => const SliverToBoxAdapter(child: _Skeleton()),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $e', style: const TextStyle(color: IceColors.danger)),
                ),
              ),
              data: (d) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(children: [
                    _globalBanner(d, branches.valueOrNull?.length),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _StatTile(
                        label: 'Students',
                        value: '${d['student_count'] ?? d['total_students'] ?? 0}',
                        icon: Icons.people_rounded,
                        color: IceColors.navyDeep,
                        delay: 0,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _StatTile(
                        label: 'Staff',
                        value: '${d['staff_count'] ?? d['total_staff'] ?? 0}',
                        icon: Icons.badge_rounded,
                        color: IceColors.info,
                        delay: 60,
                      )),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _StatTile(
                        label: 'Groups',
                        value: '${d['group_count'] ?? d['total_groups'] ?? 0}',
                        icon: Icons.group_work_rounded,
                        color: IceColors.warning,
                        delay: 120,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _StatTile(
                        label: 'Courses',
                        value: '${d['course_count'] ?? d['total_courses'] ?? 0}',
                        icon: Icons.menu_book_rounded,
                        color: IceColors.success,
                        delay: 180,
                      )),
                    ]),
                  ]),
                ),
              ),
            ),
            branches.when(
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (list) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Branches',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: IceColors.muted)),
                      const SizedBox(height: 8),
                      ...list.asMap().entries.map((e) {
                        final b = e.value as Map;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: IceColors.border),
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: IceColors.navyDeep.withAlpha(18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.account_tree_rounded,
                                  color: IceColors.navyDeep, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(b['name']?.toString() ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: IceColors.text)),
                                  if ((b['address'] ?? '').toString().isNotEmpty)
                                    Text(b['address'].toString(),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: IceColors.muted)),
                                ],
                              ),
                            ),
                          ]),
                        )
                            .animate(delay: Duration(milliseconds: 50 * e.key))
                            .fadeIn(duration: 280.ms)
                            .slideX(begin: 0.08, duration: 300.ms);
                      }),
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

  Widget _globalBanner(Map d, int? branchCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [IceColors.navy, IceColors.navyMid, IceColors.navyDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Superadmin Dashboard',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('ICEBERG',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2)),
              const SizedBox(height: 2),
              Text(
                '${branchCount ?? d['total_branches'] ?? 0} branches active',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.public_rounded, color: Colors.white, size: 28),
        ),
      ]),
    )
        .animate()
        .slideY(begin: 0.15, duration: 400.ms, curve: Curves.easeOut)
        .fadeIn(duration: 350.ms);
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;

  const _StatTile({
    required this.label,
    required this.value,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IceColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: IceColors.text)),
          Text(label,
              style: const TextStyle(fontSize: 12, color: IceColors.muted)),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 280.ms)
        .scale(begin: const Offset(0.96, 0.96), duration: 280.ms);
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
            Container(
                height: 100,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: Container(
                      height: 96,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)))),
              const SizedBox(width: 10),
              Expanded(
                  child: Container(
                      height: 96,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)))),
            ]),
          ]),
        ),
      );
}
