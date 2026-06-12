import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class AdminEnrollmentScreen extends ConsumerStatefulWidget {
  const AdminEnrollmentScreen({super.key});

  @override
  ConsumerState<AdminEnrollmentScreen> createState() =>
      _AdminEnrollmentScreenState();
}

class _AdminEnrollmentScreenState extends ConsumerState<AdminEnrollmentScreen> {
  String _studentSearch = '';
  String _groupSearch = '';

  Map<String, dynamic>? _selectedStudent;
  Map<String, dynamic>? _selectedGroup;

  bool _loading = false;
  String? _successMsg;
  String? _errorMsg;

  Future<void> _enroll() async {
    if (_selectedStudent == null || _selectedGroup == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _loading = true;
      _successMsg = null;
      _errorMsg = null;
    });
    try {
      final res = await ApiClient.instance.dio.post(
        '/admin/enrollments/',
        data: {
          'student_id': _selectedStudent!['id'],
          'group_id': _selectedGroup!['id'],
        },
      );
      final created = res.statusCode == 201;
      if (mounted) {
        setState(() {
          _loading = false;
          _successMsg = created
              ? '${_selectedStudent!['first_name']} ${_selectedStudent!['last_name']} enrolled in ${_selectedGroup!['name']}.'
              : 'Already enrolled — re-activated.';
          _selectedStudent = null;
          _selectedGroup = null;
          _studentSearch = '';
          _groupSearch = '';
        });
        ref.invalidate(adminGroupsManageProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = '$e';
        });
      }
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
    final studentsAsync = ref.watch(adminStudentsProvider);
    final groupsAsync = ref.watch(adminGroupsManageProvider);

    return Scaffold(
      backgroundColor: IceColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: IcePageHeader(
              title: 'Enroll Student',
              subtitle: 'Add a student to a group',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Success / error banner
                  if (_successMsg != null)
                    _Banner(message: _successMsg!, isError: false),
                  if (_errorMsg != null)
                    _Banner(message: _errorMsg!, isError: true),

                  // Student picker
                  const _SectionLabel('1. Select Student'),
                  const SizedBox(height: 8),
                  studentsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(
                      '$e',
                      style: const TextStyle(color: IceColors.danger),
                    ),
                    data: (list) {
                      final students = list.cast<Map<String, dynamic>>();
                      final filtered = _studentSearch.isEmpty
                          ? students
                          : students.where((s) {
                              final q = _studentSearch.toLowerCase();
                              final name =
                                  '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'
                                      .toLowerCase();
                              final lid = (s['login_id'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              return name.contains(q) || lid.contains(q);
                            }).toList();
                      return _PickerCard(
                        searchHint: 'Search by name or ID…',
                        searchValue: _studentSearch,
                        onSearchChanged: (v) =>
                            setState(() => _studentSearch = v),
                        selected: _selectedStudent == null
                            ? null
                            : () {
                                final fn =
                                    _selectedStudent!['first_name'] ?? '';
                                final ln = _selectedStudent!['last_name'] ?? '';
                                final lid = _selectedStudent!['login_id'] ?? '';
                                return '${('$fn $ln').trim()} ($lid)';
                              }(),
                        items: filtered,
                        itemLabel: (s) {
                          final fn = s['first_name'] ?? '';
                          final ln = s['last_name'] ?? '';
                          final lid = s['login_id'] ?? '';
                          return '${('$fn $ln').trim()} · $lid';
                        },
                        onSelect: (s) => setState(() {
                          _selectedStudent = s;
                          _studentSearch = '';
                        }),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Group picker
                  const _SectionLabel('2. Select Group'),
                  const SizedBox(height: 8),
                  groupsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(
                      '$e',
                      style: const TextStyle(color: IceColors.danger),
                    ),
                    data: (list) {
                      final groups = list.cast<Map<String, dynamic>>();
                      final filtered = _groupSearch.isEmpty
                          ? groups
                          : groups.where((g) {
                              final q = _groupSearch.toLowerCase();
                              return (g['name'] ?? '')
                                      .toString()
                                      .toLowerCase()
                                      .contains(q) ||
                                  (g['course_name'] ?? '')
                                      .toString()
                                      .toLowerCase()
                                      .contains(q);
                            }).toList();
                      return _PickerCard(
                        searchHint: 'Search by name or course…',
                        searchValue: _groupSearch,
                        onSearchChanged: (v) =>
                            setState(() => _groupSearch = v),
                        selected: _selectedGroup == null
                            ? null
                            : '${_selectedGroup!['name']} · ${_selectedGroup!['course_name'] ?? ''}',
                        items: filtered,
                        itemLabel: (g) =>
                            '${g['name']} · ${g['course_name'] ?? ''}',
                        onSelect: (g) => setState(() {
                          _selectedGroup = g;
                          _groupSearch = '';
                        }),
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Summary card
                  if (_selectedStudent != null || _selectedGroup != null)
                    _SummaryCard(
                      student: _selectedStudent,
                      group: _selectedGroup,
                    ),

                  const SizedBox(height: 20),

                  // Enroll button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          (_selectedStudent != null &&
                              _selectedGroup != null &&
                              !_loading)
                          ? _enroll
                          : null,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add_rounded),
                      label: const Text('Enroll Student'),
                      style: FilledButton.styleFrom(
                        backgroundColor: IceColors.navyDeep,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 14,
      color: IceColors.text,
    ),
  );
}

class _PickerCard extends StatelessWidget {
  final String searchHint;
  final String searchValue;
  final ValueChanged<String> onSearchChanged;
  final String? selected;
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic>) itemLabel;
  final ValueChanged<Map<String, dynamic>> onSelect;

  const _PickerCard({
    required this.searchHint,
    required this.searchValue,
    required this.onSearchChanged,
    required this.selected,
    required this.items,
    required this.itemLabel,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IceColors.border),
      ),
      child: Column(
        children: [
          if (selected != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: IceColors.navyDeep.withAlpha(12),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: IceColors.navyDeep,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selected!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: IceColors.navyDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: IceColors.muted,
                  size: 18,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
          ),
          if (searchValue.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No results',
                        style: TextStyle(color: IceColors.muted, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: IceColors.border),
                      itemBuilder: (_, i) => InkWell(
                        onTap: () => onSelect(items[i]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Text(
                            itemLabel(items[i]),
                            style: const TextStyle(
                              fontSize: 13,
                              color: IceColors.text,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic>? student;
  final Map<String, dynamic>? group;
  const _SummaryCard({this.student, this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IceColors.navyDeep.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IceColors.navyDeep.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enrollment Summary',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: IceColors.navyDeep,
            ),
          ),
          const SizedBox(height: 10),
          _Row(
            icon: Icons.person_rounded,
            label: 'Student',
            value: student == null
                ? 'Not selected'
                : () {
                    final fn = student!['first_name'] ?? '';
                    final ln = student!['last_name'] ?? '';
                    final lid = student!['login_id'] ?? '';
                    return '${('$fn $ln').trim()} ($lid)';
                  }(),
          ),
          const SizedBox(height: 6),
          _Row(
            icon: Icons.group_rounded,
            label: 'Group',
            value: group == null
                ? 'Not selected'
                : '${group!['name']} · ${group!['course_name'] ?? ''}',
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 14, color: IceColors.navyDeep),
      const SizedBox(width: 8),
      Text(
        '$label: ',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: IceColors.text,
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(fontSize: 12, color: IceColors.muted),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class _Banner extends StatelessWidget {
  final String message;
  final bool isError;
  const _Banner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: (isError ? IceColors.danger : IceColors.success).withAlpha(18),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: (isError ? IceColors.danger : IceColors.success).withAlpha(60),
      ),
    ),
    child: Row(
      children: [
        Icon(
          isError
              ? Icons.error_outline_rounded
              : Icons.check_circle_outline_rounded,
          size: 16,
          color: isError ? IceColors.danger : IceColors.success,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: isError ? IceColors.danger : IceColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
