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

class StudentAssignmentsScreen extends ConsumerStatefulWidget {
  const StudentAssignmentsScreen({super.key});
  @override
  ConsumerState<StudentAssignmentsScreen> createState() => _State();
}

class _State extends ConsumerState<StudentAssignmentsScreen> {
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
                subtitle: 'Your class tasks and homework',
              ),
            ),
            async.when(
              loading: () => const SliverToBoxAdapter(child: _Skeleton()),
              error: (e, _) =>
                  SliverToBoxAdapter(child: _ErrorCard('$e')),
              data: (list) => list.isEmpty
                  ? SliverToBoxAdapter(child: _Empty())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _AssignmentCard(
                          item: list[i] as Map<String, dynamic>,
                          index: i,
                          onSubmit: () => ref.invalidate(assignmentsProvider),
                        ),
                        childCount: list.length,
                      ),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// ── Assignment card ──────────────────────────────────────────────────────────
class _AssignmentCard extends ConsumerWidget {
  final Map<String, dynamic> item;
  final int index;
  final VoidCallback onSubmit;
  const _AssignmentCard(
      {required this.item, required this.index, required this.onSubmit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueStr = item['due_date']?.toString() ?? '';
    final groupName = item['group_name']?.toString() ?? '—';
    final isOverdue = dueStr.isNotEmpty &&
        DateTime.tryParse(dueStr) != null &&
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isOverdue
                      ? IceColors.danger.withAlpha(18)
                      : IceColors.navyDeep.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.assignment_outlined,
                  color: isOverdue ? IceColors.danger : IceColors.navyDeep,
                  size: 22,
                ),
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
                    const SizedBox(height: 3),
                    Text(groupName,
                        style: const TextStyle(
                            fontSize: 12,
                            color: IceColors.muted,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: IceColors.danger.withAlpha(18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Overdue',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: IceColors.danger)),
                ),
            ],
          ),
          if (item['description'] != null &&
              item['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item['description'].toString(),
              style: const TextStyle(
                  fontSize: 13, color: IceColors.muted, height: 1.45),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (dueStr.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.schedule_rounded,
                  size: 13,
                  color:
                      isOverdue ? IceColors.danger : IceColors.muted),
              const SizedBox(width: 5),
              Text('Due $dueStr',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isOverdue
                          ? IceColors.danger
                          : IceColors.muted)),
            ]),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.upload_outlined, size: 16),
              label: const Text('Submit Assignment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: IceColors.navyDeep,
                side: const BorderSide(color: IceColors.navyDeep, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _showSubmit(context, item['id'] as int),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 100 + index * 60))
        .slideY(begin: 0.15, duration: 350.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }

  void _showSubmit(BuildContext context, int assignmentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmitSheet(
        assignmentId: assignmentId,
        title: item['title']?.toString() ?? '',
        onDone: onSubmit,
      ),
    );
  }
}

// ── Submit sheet ─────────────────────────────────────────────────────────────
class _SubmitSheet extends StatefulWidget {
  final int assignmentId;
  final String title;
  final VoidCallback onDone;
  const _SubmitSheet(
      {required this.assignmentId, required this.title, required this.onDone});
  @override
  State<_SubmitSheet> createState() => _SubmitSheetState();
}

class _SubmitSheetState extends State<_SubmitSheet> {
  final _notes = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    HapticFeedback.lightImpact();
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient.instance.dio
          .post('/assignments/${widget.assignmentId}/submit/', data: {
        'notes': _notes.text.trim(),
      });
      setState(() { _loading = false; _done = true; });
      widget.onDone();
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      setState(() {
        _error = (e.response?.data is Map)
            ? e.response!.data.values.first.toString()
            : 'Submission failed.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: IceColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          if (_done)
            Column(children: [
              const SizedBox(height: 16),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: IceColors.success.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: IceColors.success, size: 36),
              ),
              const SizedBox(height: 12),
              const Text('Submitted!',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: IceColors.success)),
              const SizedBox(height: 24),
            ])
          else ...[
            Row(children: [
              const Expanded(
                child: Text('Submit Assignment',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: IceColors.text)),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.title,
                  style: const TextStyle(
                      fontSize: 13, color: IceColors.muted)),
            ),
            const SizedBox(height: 16),
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
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Notes or comments (optional)...'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 18),
                label: const Text('Submit'),
                onPressed: _loading ? null : _submit,
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────
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
                  height: 120,
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
          Icon(Icons.assignment_outlined,
              size: 56, color: IceColors.muted.withAlpha(100)),
          const SizedBox(height: 16),
          const Text('No assignments',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: IceColors.muted)),
          const SizedBox(height: 8),
          const Text('Your teachers haven\'t posted any assignments yet.',
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
