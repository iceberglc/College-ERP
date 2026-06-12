import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class StaffClassesScreen extends ConsumerWidget {
  const StaffClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffGroupsProvider);

    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(staffGroupsProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'My Classes',
                subtitle: 'Your assigned groups',
              ),
            ),
            async.when(
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
              data: (list) {
                if (list.isEmpty) {
                  return const SliverToBoxAdapter(child: _EmptyState());
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _GroupCard(group: list[i] as Map, index: i),
                    childCount: list.length,
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

// ─── Group Card ───────────────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final Map group;
  final int index;
  const _GroupCard({required this.group, required this.index});

  @override
  Widget build(BuildContext context) {
    final name = group['name']?.toString() ?? 'Group';
    final courseName =
        group['course_name']?.toString() ?? group['course']?.toString() ?? '';
    final studentCount = group['student_count'] ?? group['students_count'] ?? 0;

    return GestureDetector(
          onTap: () => _showStudentsSheet(context, group),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: IceColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: IceColors.border),
            ),
            child: Row(
              children: [
                // Color circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: IceColors.navyDeep.withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'G',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: IceColors.navyDeep,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: IceColors.text,
                        ),
                      ),
                      if (courseName.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          courseName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: IceColors.muted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_rounded,
                            size: 14,
                            color: IceColors.navyDeep,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$studentCount students',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: IceColors.navyDeep,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: IceColors.muted,
                  size: 20,
                ),
              ],
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: 40 * index))
        .fadeIn(duration: 250.ms)
        .slideX(begin: 0.05, duration: 250.ms);
  }

  void _showStudentsSheet(BuildContext context, Map group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StudentsBottomSheet(group: group),
    );
  }
}

// ─── Students Bottom Sheet ────────────────────────────────────────────────────

class _StudentsBottomSheet extends StatefulWidget {
  final Map group;
  const _StudentsBottomSheet({required this.group});

  @override
  State<_StudentsBottomSheet> createState() => _StudentsBottomSheetState();
}

class _StudentsBottomSheetState extends State<_StudentsBottomSheet> {
  bool _loading = true;
  String? _error;
  List<dynamic> _students = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = widget.group['id'];
      final res = await ApiClient.instance.dio.get('/groups/$id/');
      final data = res.data;
      List<dynamic> list = [];
      if (data is Map) {
        list =
            (data['enrolled_students'] as List?) ??
            (data['students'] as List?) ??
            [];
      } else if (data is List) {
        list = data;
      }
      setState(() {
        _students = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupName = widget.group['name']?.toString() ?? 'Group';
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: IceColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: IceColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: IceColors.text,
                          ),
                        ),
                        Text(
                          _loading
                              ? 'Loading...'
                              : '${_students.length} students',
                          style: const TextStyle(
                            fontSize: 12,
                            color: IceColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: IceColors.muted,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: IceColors.border),

            // Content
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: IceColors.navyDeep,
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: Text(
                        'Error: $_error',
                        style: const TextStyle(color: IceColors.danger),
                      ),
                    )
                  : _students.isEmpty
                  ? const Center(
                      child: Text(
                        'No students in this group.',
                        style: TextStyle(color: IceColors.muted),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomPad),
                      itemCount: _students.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final s = _students[i] as Map;
                        final firstName = s['first_name']?.toString() ?? '';
                        final lastName = s['last_name']?.toString() ?? '';
                        final name = '$firstName $lastName'.trim();
                        final subtitle =
                            s['email']?.toString() ??
                            s['phone']?.toString() ??
                            s['login_id']?.toString() ??
                            '';

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: IceColors.surface2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: IceColors.border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: IceColors.navyDeep.withAlpha(
                                  12,
                                ),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: IceColors.navyDeep,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isNotEmpty ? name : 'Student',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: IceColors.text,
                                      ),
                                    ),
                                    if (subtitle.isNotEmpty)
                                      Text(
                                        subtitle,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: IceColors.muted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(40),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.class_outlined, size: 48, color: IceColors.muted),
        SizedBox(height: 16),
        Text(
          'No classes assigned',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: IceColors.muted,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'You have not been assigned to any groups yet.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: IceColors.muted),
        ),
      ],
    ),
  );
}
