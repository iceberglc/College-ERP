import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class StaffAssignmentsScreen extends ConsumerStatefulWidget {
  const StaffAssignmentsScreen({super.key});
  @override
  ConsumerState<StaffAssignmentsScreen> createState() => _State();
}

class _State extends ConsumerState<StaffAssignmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(assignmentsProvider);
    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(assignmentsProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Assignments',
                subtitle: 'Create and manage class assignments',
                chips: [
                  IceHeaderChip(
                    icon: Icons.add_rounded,
                    label: 'New',
                    onTap: () => _showCreate(context),
                  ),
                ],
              ),
            ),
            async.when(
              loading: () => const SliverToBoxAdapter(child: _Skeleton()),
              error: (e, _) => SliverToBoxAdapter(child: _ErrorCard('$e')),
              data: (list) => list.isEmpty
                  ? SliverToBoxAdapter(child: _Empty())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _AssignmentCard(
                          item: list[i] as Map<String, dynamic>,
                          index: i,
                        ),
                        childCount: list.length,
                      ),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreate(context),
        backgroundColor: IceColors.navyDeep,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Assignment',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showCreate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateSheet(onCreated: () {
        ref.invalidate(assignmentsProvider);
      }),
    );
  }
}

// ── Assignment card ──────────────────────────────────────────────────────────
class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  const _AssignmentCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final dueStr = item['due_date']?.toString() ?? '';
    final groupName = item['group_name']?.toString() ?? '—';
    final isOverdue = dueStr.isNotEmpty && DateTime.tryParse(dueStr) != null &&
        DateTime.parse(dueStr).isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: IceColors.border),
        boxShadow: [
          BoxShadow(
            color: IceColors.navyDeep.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: IceColors.navyDeep.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment_outlined,
                color: IceColors.navyDeep, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title']?.toString() ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: IceColors.text)),
                const SizedBox(height: 4),
                Text(groupName,
                    style: const TextStyle(
                        fontSize: 12,
                        color: IceColors.muted,
                        fontWeight: FontWeight.w500)),
                if (dueStr.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: isOverdue ? IceColors.danger : IceColors.muted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: $dueStr',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOverdue ? IceColors.danger : IceColors.muted,
                      ),
                    ),
                    if (isOverdue) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: IceColors.danger.withAlpha(18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Overdue',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: IceColors.danger)),
                      ),
                    ],
                  ]),
                ],
                if (item['description'] != null &&
                    item['description'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      item['description'].toString(),
                      style: const TextStyle(
                          fontSize: 13, color: IceColors.muted, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 100 + index * 60))
        .slideY(begin: 0.15, duration: 350.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }
}

// ── Create assignment sheet ──────────────────────────────────────────────────
class _CreateSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _CreateSheet({required this.onCreated});
  @override
  ConsumerState<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends ConsumerState<_CreateSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _due = TextEditingController();
  int? _groupId;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _due.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.isEmpty || _groupId == null) {
      setState(() => _error = 'Title and group are required.');
      return;
    }
    HapticFeedback.lightImpact();
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient.instance.dio.post('/assignments/', data: {
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'group_id': _groupId,
        if (_due.text.isNotEmpty) 'due_date': _due.text,
      });
      widget.onCreated();
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      setState(() {
        _error = (e.response?.data is Map)
            ? e.response!.data.values.first.toString()
            : 'Failed to create assignment.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: IceColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Text('New Assignment',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: IceColors.text)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
              children: [
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: IceColors.danger.withAlpha(18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(
                            color: IceColors.danger, fontSize: 13)),
                  ),
                _Field(
                  label: 'Title *',
                  controller: _title,
                  hint: 'e.g. Homework #1',
                ),
                const SizedBox(height: 14),
                // Group picker
                groups.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('$e',
                      style: const TextStyle(color: IceColors.danger)),
                  data: (list) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Group *',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: IceColors.text)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: IceColors.surface2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: IceColors.border, width: 1.5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _groupId,
                            isExpanded: true,
                            hint: const Text('Select group'),
                            items: list.map((g) {
                              final m = g as Map<String, dynamic>;
                              return DropdownMenuItem<int>(
                                value: m['id'] as int,
                                child: Text(m['name']?.toString() ?? ''),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _groupId = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _Field(
                  label: 'Due Date',
                  controller: _due,
                  hint: 'YYYY-MM-DD',
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 14),
                _Field(
                  label: 'Description',
                  controller: _desc,
                  hint: 'Assignment instructions...',
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Create Assignment'),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: IceColors.text)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      );
}

// ── Skeleton ─────────────────────────────────────────────────────────────────
class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            for (int i = 0; i < 4; i++) ...[
              Container(
                  height: 88,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18))),
              const SizedBox(height: 12),
            ],
          ]),
        ),
      );
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          Icon(Icons.assignment_outlined, size: 56, color: IceColors.muted.withAlpha(100)),
          const SizedBox(height: 16),
          const Text('No assignments yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: IceColors.muted)),
          const SizedBox(height: 8),
          const Text('Create the first assignment for your group.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: IceColors.muted)),
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
