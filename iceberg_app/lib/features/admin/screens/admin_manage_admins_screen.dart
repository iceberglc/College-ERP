import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class AdminManageAdminsScreen extends ConsumerStatefulWidget {
  const AdminManageAdminsScreen({super.key});

  @override
  ConsumerState<AdminManageAdminsScreen> createState() =>
      _AdminManageAdminsScreenState();
}

class _AdminManageAdminsScreenState
    extends ConsumerState<AdminManageAdminsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminAdminsProvider);
    return Scaffold(
      backgroundColor: IceColors.bg,
      // Creating admins is superadmin-only; hide the button when the list
      // itself was refused (403 for branch admins).
      floatingActionButton: async.hasValue
          ? FloatingActionButton.extended(
              onPressed: () => _openAddSheet(context),
              backgroundColor: IceColors.navyDeep,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Add Admin'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminAdminsProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Admins',
                subtitle: 'Branch admin accounts',
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Search by name or email…',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: IceColors.muted,
                      size: 20,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            async.when(
              loading: () => const SliverToBoxAdapter(child: _Skeleton()),
              error: (e, _) => SliverToBoxAdapter(
                child: e.toString().contains('403')
                    ? const _ForbiddenState()
                    : const _ErrorCard(
                        'Could not load admin accounts. '
                        'Pull down to retry.',
                      ),
              ),
              data: (list) {
                final all = list.cast<Map<String, dynamic>>();
                final filtered = _query.isEmpty
                    ? all
                    : all.where((a) {
                        final name = (a['full_name'] ?? '')
                            .toString()
                            .toLowerCase();
                        final email = (a['email'] ?? '')
                            .toString()
                            .toLowerCase();
                        return name.contains(_query) || email.contains(_query);
                      }).toList();

                if (filtered.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(searching: _query.isNotEmpty),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _AdminTile(
                      item: filtered[i],
                      index: i,
                      onUpdated: () => ref.invalidate(adminAdminsProvider),
                    ),
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

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdminFormSheet(
        onSaved: () {
          ref.invalidate(adminAdminsProvider);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _AdminTile extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  final VoidCallback onUpdated;
  const _AdminTile({
    required this.item,
    required this.index,
    required this.onUpdated,
  });

  @override
  ConsumerState<_AdminTile> createState() => _AdminTileState();
}

class _AdminTileState extends ConsumerState<_AdminTile> {
  bool _deleting = false;

  Future<void> _delete(BuildContext context) async {
    final id = widget.item['id']?.toString() ?? '';
    final name = widget.item['full_name']?.toString() ?? 'this admin';
    final isSuperAdmin = widget.item['is_super_admin'] == true;

    if (isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Super-admin accounts cannot be deleted.'),
          backgroundColor: IceColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Delete Admin?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text('Delete "$name"? This cannot be undone.'),
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
      await ApiClient.instance.dio.delete('/admin/admins/$id/');
      widget.onUpdated();
    } catch (e) {
      if (mounted) setState(() => _deleting = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: IceColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final name =
        item['full_name']?.toString() ?? item['email']?.toString() ?? '—';
    final email = item['email']?.toString() ?? '';
    final isSuperAdmin = item['is_super_admin'] == true;
    final isActive = item['is_active'] != false;
    final branches = (item['branch_names'] as List?)?.cast<String>() ?? [];
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final id = item['id']?.toString() ?? '';

    return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: IceColors.border),
            boxShadow: [
              BoxShadow(
                color: IceColors.navyDeep.withAlpha(6),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: isSuperAdmin
                          ? IceColors.lime.withAlpha(220)
                          : IceColors.navyDeep.withAlpha(20),
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isSuperAdmin
                              ? IceColors.navyDeep
                              : IceColors.navyDeep,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: IceColors.text,
                                  ),
                                ),
                              ),
                              if (isSuperAdmin)
                                _Tag('Super Admin', IceColors.navyDeep)
                              else if (!isActive)
                                _Tag('Inactive', IceColors.muted),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: IceColors.muted,
                            ),
                          ),
                          if (branches.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              branches.join(', '),
                              style: const TextStyle(
                                fontSize: 11,
                                color: IceColors.muted,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isSuperAdmin && id.isNotEmpty) ...[
                const Divider(height: 1, color: IceColors.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _openEditSheet(context, item),
                        icon: const Icon(Icons.edit_rounded, size: 14),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: IceColors.navyDeep,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_deleting)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: IceColors.danger,
                          ),
                        )
                      else
                        IconButton(
                          onPressed: () => _delete(context),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: IceColors.danger,
                          ),
                          tooltip: 'Delete admin',
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 50 + widget.index * 40))
        .slideY(begin: 0.1, duration: 300.ms, curve: Curves.easeOut)
        .fadeIn(duration: 250.ms);
  }

  void _openEditSheet(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdminFormSheet(
        existing: item,
        onSaved: () {
          widget.onUpdated();
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withAlpha(18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

// ---------------------------------------------------------------------------
// Add / Edit sheet
// ---------------------------------------------------------------------------

class _AdminFormSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  const _AdminFormSheet({this.existing, required this.onSaved});

  @override
  ConsumerState<_AdminFormSheet> createState() => _AdminFormSheetState();
}

class _AdminFormSheetState extends ConsumerState<_AdminFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _password;
  bool _isActive = true;
  List<int> _selectedBranchIds = [];
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _email = TextEditingController(text: e?['email'] ?? '');
    _firstName = TextEditingController(text: e?['first_name'] ?? '');
    _lastName = TextEditingController(text: e?['last_name'] ?? '');
    _phone = TextEditingController(text: e?['phone'] ?? '');
    _password = TextEditingController();
    _isActive = e?['is_active'] != false;
    _selectedBranchIds = (e?['branch_ids'] as List?)?.cast<int>() ?? [];
  }

  @override
  void dispose() {
    _email.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final id = widget.existing?['id'];
      final body = {
        'email': _email.text.trim(),
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'phone': _phone.text.trim(),
        'is_active': _isActive,
        'branch_ids': _selectedBranchIds,
        if (!_isEdit || _password.text.isNotEmpty) 'password': _password.text,
      };

      if (_isEdit) {
        await ApiClient.instance.dio.patch('/admin/admins/$id/', data: body);
      } else {
        await ApiClient.instance.dio.post('/admin/admins/', data: body);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(adminBranchesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  Text(
                    _isEdit ? 'Edit Admin' : 'Add Admin',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: IceColors.danger.withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: IceColors.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),

                      _Field(label: 'First Name', controller: _firstName),
                      const SizedBox(height: 12),
                      _Field(label: 'Last Name', controller: _lastName),
                      const SizedBox(height: 12),
                      _Field(
                        label: 'Email',
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        label: 'Phone',
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        label: _isEdit
                            ? 'New Password (leave blank to keep)'
                            : 'Password',
                        controller: _password,
                        obscureText: true,
                        validator: _isEdit
                            ? null
                            : (v) {
                                if (v == null || v.trim().length < 6) {
                                  return 'Min 6 characters';
                                }
                                return null;
                              },
                      ),
                      const SizedBox(height: 16),

                      // Active toggle
                      SwitchListTile(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        title: const Text(
                          'Active',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Inactive admins cannot log in',
                          style: TextStyle(fontSize: 12),
                        ),
                        activeThumbColor: IceColors.navyDeep,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),

                      // Branch picker
                      const Text(
                        'Branches',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Leave empty for super-admin (all branches)',
                        style: TextStyle(fontSize: 11, color: IceColors.muted),
                      ),
                      const SizedBox(height: 8),
                      branchesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text(
                          '$e',
                          style: const TextStyle(
                            color: IceColors.danger,
                            fontSize: 12,
                          ),
                        ),
                        data: (branches) {
                          final bList = branches.cast<Map<String, dynamic>>();
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: bList.map((b) {
                              final bid = b['id'] as int;
                              final selected = _selectedBranchIds.contains(bid);
                              return FilterChip(
                                label: Text(b['name']?.toString() ?? ''),
                                selected: selected,
                                onSelected: (v) {
                                  setState(() {
                                    if (v) {
                                      _selectedBranchIds.add(bid);
                                    } else {
                                      _selectedBranchIds.remove(bid);
                                    }
                                  });
                                },
                                selectedColor: IceColors.navyDeep.withAlpha(25),
                                checkmarkColor: IceColors.navyDeep,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: selected
                                      ? IceColors.navyDeep
                                      : IceColors.muted,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                side: BorderSide(
                                  color: selected
                                      ? IceColors.navyDeep.withAlpha(80)
                                      : IceColors.border,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: IceColors.navyDeep,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isEdit ? 'Save Changes' : 'Create Admin',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscureText,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: IceColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
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
      child: Column(
        children: [
          for (int i = 0; i < 4; i++) ...[
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final bool searching;
  const _EmptyState({required this.searching});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        Icon(
          Icons.admin_panel_settings_outlined,
          size: 56,
          color: IceColors.muted.withAlpha(100),
        ),
        const SizedBox(height: 16),
        Text(
          searching ? 'No admins match' : 'No admins yet',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: IceColors.muted,
          ),
        ),
      ],
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard(this.message);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Text(message, style: const TextStyle(color: IceColors.danger)),
  );
}

class _ForbiddenState extends StatelessWidget {
  const _ForbiddenState();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(48),
    child: Column(
      children: [
        Icon(Icons.lock_outline_rounded, size: 48, color: IceColors.muted),
        SizedBox(height: 14),
        Text(
          'Super-admin only',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: IceColors.text,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Admin accounts can only be managed\nby the super-admin.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: IceColors.muted),
        ),
      ],
    ),
  );
}
