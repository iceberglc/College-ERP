import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class AdminGroupsScreen extends ConsumerStatefulWidget {
  const AdminGroupsScreen({super.key});
  @override
  ConsumerState<AdminGroupsScreen> createState() => _State();
}

class _State extends ConsumerState<AdminGroupsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminGroupsManageProvider);
    return Scaffold(
      backgroundColor: IceColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/groups/add'),
        backgroundColor: IceColors.navyDeep,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('Add Group'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminGroupsManageProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Groups',
                subtitle: 'All active study groups',
              ),
            ),
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search groups...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: IceColors.muted, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            async.when(
              loading: () => const SliverToBoxAdapter(child: _Skeleton()),
              error: (e, _) =>
                  SliverToBoxAdapter(child: _ErrorCard('$e')),
              data: (list) {
                final filtered = _query.isEmpty
                    ? list
                    : list.where((g) {
                        final m = g as Map<String, dynamic>;
                        return (m['name']?.toString().toLowerCase() ?? '')
                                .contains(_query) ||
                            (m['course_name']?.toString().toLowerCase() ?? '')
                                .contains(_query);
                      }).toList();
                if (filtered.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(searching: _query.isNotEmpty),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _GroupCard(
                        item: filtered[i] as Map<String, dynamic>,
                        index: i),
                    childCount: filtered.length,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  const _GroupCard({required this.item, required this.index});

  @override
  ConsumerState<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends ConsumerState<_GroupCard> {
  bool _deleting = false;

  Future<void> _delete(BuildContext context) async {
    final id = widget.item['id']?.toString() ?? '';
    final name = widget.item['name']?.toString() ?? 'this group';
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Group?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: IceColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ApiClient.instance.dio.delete('/admin/groups-manage/$id/');
      ref.invalidate(adminGroupsManageProvider);
    } catch (e) {
      if (mounted) setState(() => _deleting = false);
      messenger.showSnackBar(SnackBar(
        content: Text('Failed: $e'),
        backgroundColor: IceColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final name = item['name']?.toString() ?? '—';
    final course = item['course_name']?.toString() ?? '';
    final teacher = item['teacher_name']?.toString() ?? '';
    final branch = item['branch_name']?.toString() ?? '';
    final schedule = item['schedule']?.toString() ?? '';
    final room = item['room']?.toString() ?? '';
    final id = item['id']?.toString() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IceColors.border),
        boxShadow: [
          BoxShadow(
            color: IceColors.navyDeep.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        IceColors.navyDeep.withAlpha(180),
                        IceColors.navyDeep,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(initial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: IceColors.text)),
                      const SizedBox(height: 4),
                      if (course.isNotEmpty)
                        _Meta(icon: Icons.book_outlined, text: course),
                      if (teacher.isNotEmpty)
                        _Meta(icon: Icons.person_outlined, text: teacher),
                      if (branch.isNotEmpty)
                        _Meta(icon: Icons.business_outlined, text: branch),
                      if (schedule.isNotEmpty)
                        _Meta(icon: Icons.schedule_rounded, text: schedule),
                      if (room.isNotEmpty)
                        _Meta(icon: Icons.room_outlined, text: room),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (id.isNotEmpty) ...[
            const Divider(height: 1, color: IceColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => context.go('/admin/groups/$id'),
                    icon: const Icon(Icons.people_rounded, size: 15),
                    label: const Text('Students'),
                    style: TextButton.styleFrom(
                        foregroundColor: IceColors.navyDeep,
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () => context.go('/admin/groups/$id/edit'),
                    icon: const Icon(Icons.edit_rounded, size: 15),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                        foregroundColor: IceColors.navyDeep,
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  if (_deleting)
                    const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: IceColors.danger))
                  else
                    IconButton(
                      onPressed: () => _delete(context),
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18, color: IceColors.danger),
                      tooltip: 'Delete group',
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 60 + widget.index * 50))
        .slideY(begin: 0.15, duration: 350.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Icon(icon, size: 12, color: IceColors.muted),
            const SizedBox(width: 5),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12,
                      color: IceColors.muted,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
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
            for (int i = 0; i < 5; i++) ...[
              Container(
                  height: 100,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20))),
              const SizedBox(height: 12),
            ],
          ]),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final bool searching;
  const _EmptyState({required this.searching});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          Icon(Icons.group_outlined,
              size: 56, color: IceColors.muted.withAlpha(100)),
          const SizedBox(height: 16),
          Text(searching ? 'No groups match' : 'No groups yet',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: IceColors.muted)),
        ]),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard(this.message);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Error: $message',
            style: const TextStyle(color: IceColors.danger)),
      );
}
