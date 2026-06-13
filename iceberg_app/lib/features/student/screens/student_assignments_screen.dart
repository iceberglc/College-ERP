import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/ice_tokens.dart';
import '../../../shared/widgets/ice_kit.dart';
import '../../../shared/widgets/ice_shell.dart';

/// Assignments list — tabs (All / To Do / Submitted / Overdue) + search.
class StudentAssignmentsScreen extends ConsumerStatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  ConsumerState<StudentAssignmentsScreen> createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState
    extends ConsumerState<StudentAssignmentsScreen> {
  int _tab = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final assignments = ref.watch(assignmentsProvider);

    return assignments.when(
      loading: () => const PageSkeleton(),
      error: (e, _) => ErrorState(
        error: e,
        onRetry: () => ref.invalidate(assignmentsProvider),
      ),
      data: (list) => _buildBody(context, list),
    );
  }

  Widget _buildBody(BuildContext context, List list) {
    final t = context.ice;
    final s = ref.watch(stringsProvider);

    bool matchesTab(Map a) => switch (_tab) {
      1 => a['status'] == 'todo' || a['status'] == 'overdue',
      2 => a['status'] == 'submitted' || a['status'] == 'graded',
      3 => a['status'] == 'overdue',
      _ => true,
    };
    bool matchesQuery(Map a) =>
        _query.isEmpty ||
        (a['title'] ?? '').toString().toLowerCase().contains(_query) ||
        (a['group_name'] ?? '').toString().toLowerCase().contains(_query);

    final visible = list
        .where((a) => matchesTab(a) && matchesQuery(a))
        .toList();

    return IcePage(
      title: s('Assignments'),
      onRefresh: () async => ref.refresh(assignmentsProvider.future),
      children: [
        // ── Search ───────────────────────────────────────────────────────
        TextField(
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          style: TextStyle(color: t.textHi, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Search assignments…',
            prefixIcon: Icon(Icons.search_rounded, color: t.textMid, size: 20),
          ),
        ),
        const SizedBox(height: 14),

        IceChipTabs(
          tabs: const ['All', 'To Do', 'Submitted', 'Overdue'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 16),

        if (list.isEmpty)
          const IceCard(
            child: EmptyState(
              icon: Icons.assignment_outlined,
              title: 'No assignments yet',
              message: 'New assignments from your teachers will appear here.',
            ),
          )
        else if (visible.isEmpty)
          const IceCard(
            child: EmptyState(
              icon: Icons.filter_alt_off_rounded,
              title: 'Nothing here',
              message: 'No assignments match this filter.',
            ),
          )
        else
          ...visible.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AssignmentCard(a: a as Map<String, dynamic>),
            ),
          ),
      ],
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic> a;
  const _AssignmentCard({required this.a});

  (String, BadgeTone) get _badge => switch (a['status']) {
    'submitted' => ('Submitted', BadgeTone.accent),
    'graded' => ('Graded', BadgeTone.sky),
    'overdue' => ('Overdue', BadgeTone.coral),
    _ => ('To Do', BadgeTone.amber),
  };

  @override
  Widget build(BuildContext context) {
    final t = context.ice;
    final due = DateTime.tryParse(a['due_date'] ?? '');
    final (badge, tone) = _badge;

    return IceCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.go('/student/assignments/${a['id']}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  a['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: t.textHi,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(badge, tone: tone),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.groups_outlined, size: 14, color: t.textLow),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  [
                    if ((a['subject_name'] as String?)?.isNotEmpty == true)
                      a['subject_name'],
                    if ((a['group_name'] as String?)?.isNotEmpty == true)
                      a['group_name'],
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: t.textMid,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.schedule_rounded, size: 14, color: t.textLow),
              const SizedBox(width: 5),
              Text(
                due != null ? DateFormat('MMM d').format(due) : '',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: due != null && due.isBefore(DateTime.now())
                      ? t.coral
                      : t.textMid,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
