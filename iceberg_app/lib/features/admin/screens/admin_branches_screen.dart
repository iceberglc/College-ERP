import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class AdminBranchesScreen extends ConsumerStatefulWidget {
  const AdminBranchesScreen({super.key});

  @override
  ConsumerState<AdminBranchesScreen> createState() =>
      _AdminBranchesScreenState();
}

class _AdminBranchesScreenState extends ConsumerState<AdminBranchesScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _branches = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.dio.get('/admin/branches-manage/');
      setState(() {
        _branches = List<Map<String, dynamic>>.from(
          res.data is List ? res.data : (res.data['results'] ?? res.data),
        );
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showForm({Map<String, dynamic>? branch}) {
    final nameCtrl = TextEditingController(
      text: branch?['name']?.toString() ?? '',
    );
    final addrCtrl = TextEditingController(
      text: branch?['address']?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BranchFormSheet(
        title: branch == null ? 'Add Branch' : 'Edit Branch',
        nameCtrl: nameCtrl,
        addrCtrl: addrCtrl,
        showDelete: branch != null,
        onSave: () async {
          if (nameCtrl.text.trim().isEmpty) return;
          final data = {
            'name': nameCtrl.text.trim(),
            'address': addrCtrl.text.trim(),
          };
          try {
            if (branch == null) {
              await ApiClient.instance.dio.post(
                '/admin/branches-manage/',
                data: data,
              );
            } else {
              await ApiClient.instance.dio.patch(
                '/admin/branches-manage/${branch['id']}/',
                data: data,
              );
            }
            if (ctx.mounted) Navigator.pop(ctx);
            _load();
          } catch (_) {}
        },
        onDelete: branch == null
            ? null
            : () async {
                try {
                  await ApiClient.instance.dio.delete(
                    '/admin/branches-manage/${branch['id']}/',
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (_) {}
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Branches',
                subtitle: 'Manage school branches',
                avatar: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: IceColors.navyDeep.withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: IceColors.border),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.location_city_rounded,
                    color: IceColors.navyDeep,
                    size: 22,
                  ),
                ),
                actions: [
                  ElevatedButton.icon(
                    onPressed: () => _showForm(),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      'Add Branch',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: IceColors.lime,
                      foregroundColor: IceColors.navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: IceColors.navyDeep),
                  ),
                ),
              )
            else if (_branches.isEmpty)
              SliverToBoxAdapter(child: _buildEmpty())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((_, i) {
                  if (i == _branches.length) return const SizedBox(height: 80);
                  return _BranchCard(
                    branch: _branches[i],
                    index: i,
                    onEdit: () => _showForm(branch: _branches[i]),
                  );
                }, childCount: _branches.length + 1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.all(60),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.location_city_outlined,
              size: 48,
              color: IceColors.muted,
            ),
            SizedBox(height: 12),
            Text(
              'No branches yet',
              style: TextStyle(color: IceColors.muted, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final Map<String, dynamic> branch;
  final int index;
  final VoidCallback onEdit;
  const _BranchCard({
    required this.branch,
    required this.index,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final name = branch['name']?.toString() ?? 'Unnamed';
    final address = branch['address']?.toString() ?? '';
    final students = branch['student_count'] ?? branch['students'] ?? 0;
    final staff = branch['staff_count'] ?? branch['staff'] ?? 0;

    return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: IceColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: IceColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: IceColors.navyDeep.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.store_rounded,
                      color: IceColors.navyDeep,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: IceColors.text,
                          ),
                        ),
                        if (address.isNotEmpty)
                          Text(
                            address,
                            style: const TextStyle(
                              fontSize: 12,
                              color: IceColors.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: IceColors.muted,
                    ),
                    tooltip: 'Edit',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatPill(
                    icon: Icons.people_rounded,
                    label: '$students students',
                    color: IceColors.navyDeep,
                  ),
                  const SizedBox(width: 8),
                  _StatPill(
                    icon: Icons.badge_rounded,
                    label: '$staff staff',
                    color: IceColors.navyDeep,
                  ),
                ],
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 80 + index * 40))
        .slideX(begin: 0.05, duration: 300.ms, curve: Curves.easeOut)
        .fadeIn(duration: 250.ms);
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withAlpha(12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _BranchFormSheet extends StatelessWidget {
  final String title;
  final TextEditingController nameCtrl;
  final TextEditingController addrCtrl;
  final bool showDelete;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  const _BranchFormSheet({
    required this.title,
    required this.nameCtrl,
    required this.addrCtrl,
    required this.onSave,
    this.showDelete = false,
    this.onDelete,
  });

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: IceColors.surface2,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: IceColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: IceColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: IceColors.navyDeep, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        left: 16,
        right: 16,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: IceColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: IceColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: IceColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: IceColors.text,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameCtrl,
            decoration: _inputDeco('Branch Name'),
          ),
          const SizedBox(height: 12),
          TextField(controller: addrCtrl, decoration: _inputDeco('Address')),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: IceColors.lime,
                    foregroundColor: IceColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (showDelete && onDelete != null) ...[
                const SizedBox(width: 12),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: IceColors.danger,
                  ),
                  tooltip: 'Delete',
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
