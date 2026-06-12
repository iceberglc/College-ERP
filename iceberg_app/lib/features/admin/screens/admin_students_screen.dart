import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class AdminStudentsScreen extends ConsumerStatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  ConsumerState<AdminStudentsScreen> createState() => _State();
}

class _State extends ConsumerState<AdminStudentsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(adminStudentsProvider);

    return Scaffold(
      backgroundColor: IceColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/students/add'),
        backgroundColor: IceColors.navyDeep,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Student'),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: IcePageHeader(
              title: 'Students',
              subtitle: 'Manage enrolled students',
              avatar: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withAlpha(30)),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.people_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name or ID…',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: IceColors.muted, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: IceColors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: IceColors.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: IceColors.navyDeep, width: 1.5)),
                ),
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ),
          ),
          data.when(
            loading: () => const SliverToBoxAdapter(child: _Skeleton()),
            error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: $e',
                        style: const TextStyle(color: IceColors.danger)))),
            data: (list) {
              final filtered = _query.isEmpty
                  ? list
                  : list.where((s) {
                      final name =
                          '${s['first_name']} ${s['last_name']}'.toLowerCase();
                      final id =
                          (s['login_id'] ?? '').toString().toLowerCase();
                      return name.contains(_query) || id.contains(_query);
                    }).toList();

              if (filtered.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: Text('No students found.',
                        style: TextStyle(color: IceColors.muted))),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (i == filtered.length) return const SizedBox(height: 80);
                    final s = filtered[i];
                    return _StudentTile(student: s, index: i);
                  },
                  childCount: filtered.length + 1,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StudentTile extends ConsumerStatefulWidget {
  final dynamic student;
  final int index;
  const _StudentTile({required this.student, required this.index});

  @override
  ConsumerState<_StudentTile> createState() => _StudentTileState();
}

class _StudentTileState extends ConsumerState<_StudentTile> {
  bool _deleting = false;

  Future<void> _delete() async {
    final id = widget.student['id']?.toString() ?? '';
    final name = '${widget.student['first_name'] ?? ''} ${widget.student['last_name'] ?? ''}'.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Student?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Remove $name permanently. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
      await ApiClient.instance.dio.delete('/admin/students/$id/');
      ref.invalidate(adminStudentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name removed'),
            backgroundColor: IceColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: IceColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final name   = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim();
    final id     = student['login_id']?.toString() ?? '';
    final branch = student['branch']?.toString() ?? '';
    final studentPk = student['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IceColors.border),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: IceColors.navyDeep.withAlpha(15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: IceColors.navyDeep),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name.isEmpty ? id : name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(id,
                    style: const TextStyle(
                        fontSize: 12, color: IceColors.muted)),
              ]),
            ),
            if (branch.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: IceColors.navyDeep.withAlpha(12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(branch,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: IceColors.navyDeep)),
              ),
          ]),
        ),
        const Divider(height: 1, indent: 14, endIndent: 14,
            color: IceColors.border),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: studentPk.isEmpty
                    ? null
                    : () => context.go('/admin/students/$studentPk/edit'),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: IceColors.navyDeep,
                  side: const BorderSide(color: IceColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _deleting ? null : _delete,
                icon: _deleting
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: IceColors.danger))
                    : const Icon(Icons.delete_outline_rounded, size: 16),
                label: Text(_deleting ? 'Deleting…' : 'Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: IceColors.danger,
                  side: const BorderSide(color: IceColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    )
        .animate(delay: Duration(milliseconds: 100 + widget.index * 30))
        .slideX(begin: 0.05, duration: 300.ms, curve: Curves.easeOut)
        .fadeIn(duration: 250.ms);
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(children: List.generate(
            6,
            (_) => Container(
              height: 64,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
            ),
          )),
        ),
      );
}
