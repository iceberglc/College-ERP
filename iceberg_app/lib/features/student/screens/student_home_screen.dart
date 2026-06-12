import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final dash = ref.watch(studentDashProvider);

    final initials = _initials(user);

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(studentDashProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ───────────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(context, user, initials)),

            // ── Content ──────────────────────────────────────────────────
            dash.when(
              loading: () => const SliverToBoxAdapter(child: _Skeleton()),
              error: (e, _) => SliverToBoxAdapter(child: _ErrorCard('$e')),
              data: (data) => _buildContent(context, data),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(IceUser? user) {
    if (user == null) return '?';
    final f = user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '';
    final l = user.lastName.isNotEmpty ? user.lastName[0].toUpperCase() : '';
    return '$f$l'.isNotEmpty ? '$f$l' : '?';
  }

  Widget _buildHeader(BuildContext context, IceUser? user, String initials) {
    final top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top + 20, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Xayrli kun',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: IceColors.muted,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 4),
                Text(
                      user?.firstName.isNotEmpty == true
                          ? user!.firstName
                          : 'Talaba',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: IceColors.navy,
                      ),
                    )
                    .animate(delay: 80.ms)
                    .slideX(
                      begin: -0.1,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    )
                    .fadeIn(duration: 300.ms),
              ],
            ),
          ),
          // Lime avatar circle
          Container(
                width: 48,
                height: 48,
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
              .animate(delay: 200.ms)
              .scale(duration: 400.ms, curve: Curves.elasticOut),
        ],
      ),
    );
  }

  SliverList _buildContent(BuildContext context, Map<String, dynamic> data) {
    final att = data['attendance_percentage'];
    final total = data['total_subjects'] ?? 0;
    final avg = data['average_score'];
    final groups = data['enrolled_groups'] ?? '—';
    final notices = (data['notices'] as List?) ?? [];
    final stories = (data['stories'] as List?) ?? [];

    return SliverList(
      delegate: SliverChildListDelegate([
        // ── Stories ──────────────────────────────────────────────────────
        if (stories.isNotEmpty) _StoriesRow(stories: stories),

        // ── Statistika section header ─────────────────────────────────────
        const _SectionHeader(title: 'Statistika', actionLabel: ''),

        const SizedBox(height: 8),

        // ── 2x2 stat tiles ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: fmtPercent(att),
                  label: 'Davomat',
                  icon: Icons.bar_chart_rounded,
                  color: _attColor(att),
                  delay: 0,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value: avg != null ? fmtPercent(avg) : '—',
                  label: "O'rtacha ball",
                  icon: Icons.grade_rounded,
                  color: IceColors.warning,
                  delay: 80,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: fmtNum(total),
                  label: 'Fanlar',
                  icon: Icons.book_outlined,
                  color: IceColors.info,
                  delay: 160,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value: groups.toString(),
                  label: 'Guruhlar',
                  icon: Icons.group_outlined,
                  color: IceColors.navyDeep,
                  delay: 240,
                ),
              ),
            ],
          ),
        ),

        // ── Bildirishnomalar ─────────────────────────────────────────────
        if (notices.isNotEmpty) ...[
          const SizedBox(height: 8),
          const _SectionHeader(title: 'Bildirishnomalar', actionLabel: ''),
          const SizedBox(height: 8),
          ...notices.asMap().entries.map(
            (e) => _NoticeCard(notice: e.value, index: e.key),
          ),
        ],

        const SizedBox(height: 100),
      ]),
    );
  }

  Color _attColor(dynamic att) {
    if (att == null) return IceColors.muted;
    final d = (att is num) ? att.toDouble() : double.tryParse('$att') ?? 0;
    return d >= 75
        ? IceColors.success
        : d >= 60
        ? IceColors.warning
        : IceColors.danger;
  }
}

// ── Section header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  const _SectionHeader({required this.title, required this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: IceColors.navy,
            ),
          ),
          if (actionLabel.isNotEmpty)
            Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: IceColors.navyDeep,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Stat tile ──────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final int delay;
  const _StatTile({
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
            border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withAlpha(22),
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
        .animate(delay: Duration(milliseconds: 300 + delay))
        .slideY(begin: 0.15, duration: 400.ms, curve: Curves.easeOut)
        .fadeIn(duration: 350.ms);
  }
}

// ── Notice card ────────────────────────────────────────────────────────────────
class _NoticeCard extends StatelessWidget {
  final dynamic notice;
  final int index;
  const _NoticeCard({required this.notice, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: IceColors.info.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.campaign_outlined,
                  color: IceColors.info,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice['title']?.toString() ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: IceColors.navy,
                      ),
                    ),
                    if (notice['message'] != null)
                      Text(
                        notice['message'].toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: IceColors.muted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 400 + index * 80))
        .slideX(begin: 0.08, duration: 350.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }
}

// ── Stories row ────────────────────────────────────────────────────────────────
class _StoriesRow extends StatelessWidget {
  final List<dynamic> stories;
  const _StoriesRow({required this.stories});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Yangiliklar', actionLabel: ''),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stories.length,
            itemBuilder: (context, i) {
              final s = stories[i] as Map;
              return GestureDetector(
                onTap: () => _showStory(context, s),
                child:
                    Container(
                          width: 68,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                  color: IceColors.lime,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.campaign_rounded,
                                  color: IceColors.navy,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                s['title']?.toString() ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: IceColors.navy,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate(delay: Duration(milliseconds: 50 * i))
                        .fadeIn(duration: 250.ms)
                        .scale(begin: const Offset(0.9, 0.9), duration: 250.ms),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  void _showStory(BuildContext context, Map story) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: IceColors.lime,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: IceColors.navy,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      story['title']?.toString() ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: IceColors.navy,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: IceColors.muted,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                story['content']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: IceColors.navy,
                  height: 1.5,
                ),
              ),
              if ((story['author_name'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '— ${story['author_name']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: IceColors.muted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Skeleton ───────────────────────────────────────────────────────────────────
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _box(110)),
              const SizedBox(width: 10),
              Expanded(child: _box(110)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _box(110)),
              const SizedBox(width: 10),
              Expanded(child: _box(110)),
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

// ── Error card ─────────────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard(this.message);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Text(
      'Xatolik: $message',
      style: const TextStyle(color: IceColors.danger),
    ),
  );
}
