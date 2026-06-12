import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class AdminGroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;
  const AdminGroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<AdminGroupDetailScreen> createState() =>
      _AdminGroupDetailScreenState();
}

class _AdminGroupDetailScreenState
    extends ConsumerState<AdminGroupDetailScreen> {
  Map<String, dynamic>? _group;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.dio.get(
        '/admin/groups-manage/${widget.groupId}/',
      );
      setState(() {
        _group = Map<String, dynamic>.from(res.data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _removeStudent(int enrollmentId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Remove Student?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text('Remove $name from this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: IceColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiClient.instance.dio.delete(
        '/admin/enrollments/',
        data: {'enrollment_id': enrollmentId},
      );
      ref.invalidate(adminGroupsManageProvider);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: IceColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: IceColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: IceColors.navyDeep),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: IceColors.bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: IceColors.danger,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: IceColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: IceColors.navyDeep,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final g = _group!;
    final name = g['name']?.toString() ?? '—';
    final course = g['course_name']?.toString() ?? '';
    final teacher = g['teacher_name']?.toString() ?? 'Unassigned';
    final branch = g['branch_name']?.toString() ?? '';
    final schedule = g['schedule']?.toString() ?? '';
    final room = g['room']?.toString() ?? '';
    final capacity = g['capacity'] ?? 0;
    final fee = g['monthly_fee']?.toString() ?? '';
    final students = (g['students'] as List?) ?? [];
    final enrolled = students.length;

    return Scaffold(
      backgroundColor: IceColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: IcePageHeader(
              title: name,
              subtitle: course.isNotEmpty ? course : 'Group detail',
            ),
          ),
          // Group info card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: IceColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(Icons.person_rounded, 'Teacher', teacher),
                    if (branch.isNotEmpty)
                      _InfoRow(Icons.business_rounded, 'Branch', branch),
                    if (schedule.isNotEmpty)
                      _InfoRow(Icons.schedule_rounded, 'Schedule', schedule),
                    if (room.isNotEmpty)
                      _InfoRow(Icons.room_rounded, 'Room', room),
                    _InfoRow(
                      Icons.people_rounded,
                      'Capacity',
                      '$enrolled / $capacity enrolled',
                    ),
                    if (fee.isNotEmpty)
                      _InfoRow(
                        Icons.payments_rounded,
                        'Monthly fee',
                        "$fee so'm",
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Students header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Enrolled Students ($enrolled)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  IconButton(
                    onPressed: _load,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: IceColors.muted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (students.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No students enrolled yet.',
                    style: TextStyle(color: IceColors.muted),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((_, i) {
                if (i == students.length) return const SizedBox(height: 80);
                final s = students[i] as Map;
                final sName = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'
                    .trim();
                final lid = s['login_id']?.toString() ?? '';
                final status = s['status']?.toString() ?? '';
                final eid = s['enrollment_id'] as int?;
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: IceColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: IceColors.navyDeep.withAlpha(15),
                        child: Text(
                          sName.isNotEmpty ? sName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: IceColors.navyDeep,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sName.isEmpty ? lid : sName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              lid,
                              style: const TextStyle(
                                fontSize: 11,
                                color: IceColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (status.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (status == 'active'
                                        ? IceColors.success
                                        : IceColors.muted)
                                    .withAlpha(15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: status == 'active'
                                  ? IceColors.success
                                  : IceColors.muted,
                            ),
                          ),
                        ),
                      if (eid != null)
                        IconButton(
                          onPressed: () => _removeStudent(eid, sName),
                          icon: const Icon(
                            Icons.person_remove_rounded,
                            size: 18,
                            color: IceColors.danger,
                          ),
                          tooltip: 'Remove from group',
                        ),
                    ],
                  ),
                );
              }, childCount: students.length + 1),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 15, color: IceColors.navyDeep),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: IceColors.text,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: IceColors.muted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
