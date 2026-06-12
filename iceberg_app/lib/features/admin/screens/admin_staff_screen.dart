import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class AdminStaffScreen extends ConsumerStatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  ConsumerState<AdminStaffScreen> createState() => _State();
}

class _State extends ConsumerState<AdminStaffScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(adminStaffProvider);

    return Scaffold(
      backgroundColor: IceColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/staff/add'),
        backgroundColor: IceColors.navyDeep,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.badge_rounded),
        label: const Text('Add Staff'),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: IcePageHeader(
              title: 'Staff',
              subtitle: 'Teachers and administrators',
              avatar: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withAlpha(30)),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.badge_rounded,
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
                      borderSide: const BorderSide(color: IceColors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: IceColors.border)),
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
                    child: Center(child: Text('No staff found.',
                        style: TextStyle(color: IceColors.muted))),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (i == filtered.length) return const SizedBox(height: 80);
                    return _StaffTile(staff: filtered[i], index: i);
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

class _StaffTile extends ConsumerStatefulWidget {
  final dynamic staff;
  final int index;
  const _StaffTile({required this.staff, required this.index});

  @override
  ConsumerState<_StaffTile> createState() => _StaffTileState();
}

class _StaffTileState extends ConsumerState<_StaffTile> {
  bool _deleting = false;

  Future<void> _delete() async {
    final pk   = widget.staff['id']?.toString() ?? '';
    final name = '${widget.staff['first_name'] ?? ''} ${widget.staff['last_name'] ?? ''}'.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Staff?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Remove $name permanently. This cannot be undone.'),
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
      await ApiClient.instance.dio.delete('/admin/staff/$pk/');
      ref.invalidate(adminStaffProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$name removed'),
          backgroundColor: IceColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: IceColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s      = widget.staff;
    final name   = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
    final id     = s['login_id']?.toString() ?? '';
    final spec   = s['specialization']?.toString() ?? '';
    final active = s['is_active'] != false;
    final pk     = s['id']?.toString() ?? '';

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
              backgroundColor: IceColors.info.withAlpha(20),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: IceColors.navyDeep),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name.isEmpty ? id : name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(spec.isNotEmpty ? '$id · $spec' : id,
                    style: const TextStyle(
                        fontSize: 12, color: IceColors.muted)),
              ]),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (active ? IceColors.success : IceColors.muted)
                    .withAlpha(15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                active ? 'Active' : 'Inactive',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? IceColors.success : IceColors.muted),
              ),
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
                onPressed: pk.isEmpty
                    ? null
                    : () => context.go('/admin/staff/$pk/edit'),
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
