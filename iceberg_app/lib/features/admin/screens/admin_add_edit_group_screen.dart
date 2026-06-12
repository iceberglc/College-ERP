import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class AdminAddEditGroupScreen extends ConsumerStatefulWidget {
  /// null = add mode, non-null = edit mode
  final String? groupId;
  const AdminAddEditGroupScreen({super.key, this.groupId});

  bool get isEdit => groupId != null;

  @override
  ConsumerState<AdminAddEditGroupScreen> createState() =>
      _AdminAddEditGroupScreenState();
}

class _AdminAddEditGroupScreenState
    extends ConsumerState<AdminAddEditGroupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _room = TextEditingController();
  final _schedule = TextEditingController();
  final _fee = TextEditingController();
  int? _courseId;
  int? _branchId;
  int? _teacherId;
  int _capacity = 20;
  String? _startDate;
  bool _loading = false;
  bool _saving = false;
  String? _error;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadGroup();
  }

  Future<void> _loadGroup() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get(
        '/admin/groups-manage/${widget.groupId}/',
      );
      final d = res.data as Map<String, dynamic>;
      _name.text = d['name']?.toString() ?? '';
      _room.text = d['room']?.toString() ?? '';
      _schedule.text = d['schedule']?.toString() ?? '';
      _fee.text = d['monthly_fee']?.toString() ?? '';
      _capacity = (d['capacity'] as num?)?.toInt() ?? 20;
      _startDate = d['start_date']?.toString();
      final course = d['course'];
      _courseId = course is int
          ? course
          : (course is Map ? course['id'] as int? : null);
      final branch = d['branch'];
      _branchId = branch is int
          ? branch
          : (branch is Map ? branch['id'] as int? : null);
      final teacher = d['teacher'];
      _teacherId = teacher is int
          ? teacher
          : (teacher is Map ? teacher['id'] as int? : null);
      setState(() {
        _loading = false;
        _loaded = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'room': _room.text.trim(),
      'schedule': _schedule.text.trim(),
      'capacity': _capacity,
      if (_courseId != null) 'course': _courseId,
      if (_branchId != null) 'branch': _branchId,
      if (_teacherId != null) 'teacher': _teacherId,
      if (_fee.text.trim().isNotEmpty) 'monthly_fee': _fee.text.trim(),
      if (_startDate != null) 'start_date': _startDate,
    };
    try {
      if (widget.isEdit) {
        await ApiClient.instance.dio.patch(
          '/admin/groups-manage/${widget.groupId}/',
          data: body,
        );
      } else {
        await ApiClient.instance.dio.post('/admin/groups-manage/', data: body);
      }
      ref.invalidate(adminGroupsManageProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEdit
                  ? 'Group updated successfully'
                  : 'Group created successfully',
            ),
            backgroundColor: IceColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/admin/groups');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _room.dispose();
    _schedule.dispose();
    _fee.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(coursesProvider);
    final branches = ref.watch(adminBranchesProvider);
    final staff = ref.watch(adminStaffListProvider);

    if (_loading) {
      return const Scaffold(
        backgroundColor: IceColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: IceColors.navyDeep),
        ),
      );
    }

    if (_error != null && !_loaded) {
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
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: IceColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadGroup,
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

    return Scaffold(
      backgroundColor: IceColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: IcePageHeader(
              title: widget.isEdit ? 'Edit Group' : 'New Group',
              subtitle: widget.isEdit
                  ? 'Update group settings'
                  : 'Create a study group',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Form(
                key: _form,
                child: Column(
                  children: [
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: IceColors.danger.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: IceColors.danger.withAlpha(60),
                          ),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: IceColors.danger),
                        ),
                      ),
                    // Name
                    _field(_name, 'Group Name', required: true),
                    // Course
                    const SizedBox(height: 12),
                    courses.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (list) => DropdownButtonFormField<int>(
                        initialValue: _courseId,
                        decoration: _deco('Course'),
                        hint: const Text('Select course'),
                        validator: (v) =>
                            v == null ? 'Course is required' : null,
                        items: list.map((c) {
                          final m = c as Map;
                          return DropdownMenuItem<int>(
                            value: m['id'] as int,
                            child: Text(m['name']?.toString() ?? ''),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _courseId = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Branch
                    branches.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (list) => DropdownButtonFormField<int>(
                        initialValue: _branchId,
                        decoration: _deco('Branch'),
                        hint: const Text('Select branch'),
                        items: list.map((b) {
                          final m = b as Map;
                          return DropdownMenuItem<int>(
                            value: m['id'] as int,
                            child: Text(m['name']?.toString() ?? ''),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _branchId = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Teacher
                    staff.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (list) => DropdownButtonFormField<int>(
                        initialValue: _teacherId,
                        decoration: _deco('Teacher (optional)'),
                        hint: const Text('Select teacher'),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('— No teacher —'),
                          ),
                          ...list.map((s) {
                            final m = s as Map;
                            final sName =
                                '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'
                                    .trim();
                            return DropdownMenuItem<int>(
                              value: m['id'] as int,
                              child: Text(
                                sName.isNotEmpty
                                    ? sName
                                    : m['login_id']?.toString() ?? '',
                              ),
                            );
                          }),
                        ],
                        onChanged: (v) => setState(() => _teacherId = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _field(_room, 'Room (optional)'),
                    _field(
                      _schedule,
                      'Schedule (optional)',
                      hint: 'e.g. Mon/Wed 10:00–12:00',
                    ),
                    // Capacity
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              'Capacity: $_capacity students',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _capacity > 1
                                ? () => setState(() => _capacity--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: IceColors.navyDeep,
                          ),
                          Text(
                            '$_capacity',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _capacity++),
                            icon: const Icon(Icons.add_circle_outline),
                            color: IceColors.navyDeep,
                          ),
                        ],
                      ),
                    ),
                    _field(
                      _fee,
                      'Monthly Fee (UZS, optional)',
                      keyboard: TextInputType.number,
                    ),
                    // Start date
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        DateTime initial = DateTime.now();
                        if (_startDate != null) {
                          try {
                            initial = DateTime.parse(_startDate!);
                          } catch (_) {}
                        }
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(
                            () => _startDate =
                                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
                          );
                        }
                      },
                      child: InputDecorator(
                        decoration: _deco('Start Date (optional)'),
                        child: Text(
                          _startDate ?? 'Select date',
                          style: TextStyle(
                            color: _startDate != null
                                ? IceColors.text
                                : IceColors.muted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: IceColors.navyDeep,
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
                                widget.isEdit ? 'Save Changes' : 'Create Group',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
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
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    String? hint,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: _deco(label).copyWith(hintText: hint),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
    ),
  );

  InputDecoration _deco(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: IceColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: IceColors.border),
    ),
  );
}
