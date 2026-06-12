import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class StaffUpdateAttendanceScreen extends ConsumerStatefulWidget {
  const StaffUpdateAttendanceScreen({super.key});

  @override
  ConsumerState<StaffUpdateAttendanceScreen> createState() => _State();
}

class _State extends ConsumerState<StaffUpdateAttendanceScreen> {
  dynamic _selectedGroup;
  DateTime _selectedDate = DateTime.now();

  bool _loading = false;
  bool _saving = false;
  String? _error;

  // Student id -> status: 'present' | 'absent' | 'late'
  Map<int, String> _attendance = {};
  List<dynamic> _students = [];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: IceColors.navyDeep,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      if (_selectedGroup != null) _loadAttendance();
    }
  }

  Future<void> _loadAttendance() async {
    if (_selectedGroup == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dateStr = _formatDate(_selectedDate);
      final groupId = _selectedGroup['id'];

      final groupRes = await ApiClient.instance.dio.get('/groups/$groupId/');
      final students = _extractStudents(groupRes.data);
      final Map<int, String> statusMap = {
        for (final s in students)
          if ((s as Map)['id'] is int) s['id'] as int: 'absent',
      };

      final res = await ApiClient.instance.dio.get(
        '/attendance/',
        queryParameters: {'group_id': groupId, 'date': dateStr},
      );
      final data = res.data;
      final reports = <dynamic>[];
      if (data is List) {
        for (final item in data) {
          reports.addAll(_extractReports(item));
        }
      } else if (data is Map) {
        final resultList = (data['results'] as List?) ?? [];
        if (resultList.isNotEmpty) {
          for (final item in resultList) {
            reports.addAll(_extractReports(item));
          }
        } else {
          reports.addAll(_extractReports(data));
        }
      }

      for (final record in reports) {
        final m = record as Map;
        final studentId = m['student_id'] is int
            ? m['student_id'] as int
            : int.tryParse(m['student_id']?.toString() ?? '');
        if (studentId == null) continue;
        statusMap[studentId] = _statusFromApi(m['status']);
        if (!students.any((s) => (s as Map)['id'] == studentId)) {
          students.add({
            'id': studentId,
            'first_name': m['student_name']?.toString() ?? '',
          });
        }
      }

      setState(() {
        _students = students;
        _attendance = statusMap;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _update() async {
    if (_selectedGroup == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final dateStr = _formatDate(_selectedDate);
      await ApiClient.instance.dio.post(
        '/attendance/',
        data: {
          'group_id': _selectedGroup['id'],
          'date': dateStr,
          'records': _attendance.entries
              .map((e) => {'student_id': e.key, 'status': _statusCode(e.value)})
              .toList(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Attendance updated!'),
            backgroundColor: IceColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  List<dynamic> _extractStudents(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      return (data['enrolled_students'] as List?) ??
          (data['students'] as List?) ??
          [];
    }
    return [];
  }

  List<dynamic> _extractReports(dynamic item) {
    if (item is Map) {
      final reports = item['reports'];
      if (reports is List) return reports;
      if (item.containsKey('student_id')) return [item];
    }
    return [];
  }

  String _statusFromApi(dynamic value) {
    if (value is int) {
      return switch (value) {
        1 => 'present',
        2 => 'late',
        _ => 'absent',
      };
    }
    final label = value?.toString().toLowerCase() ?? '';
    if (label == '1' || label == 'present') return 'present';
    if (label == '2' || label == 'late') return 'late';
    return 'absent';
  }

  int _statusCode(String status) {
    switch (status) {
      case 'present':
        return 1;
      case 'late':
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(staffGroupsProvider);

    return Scaffold(
      backgroundColor: IceColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: IcePageHeader(
              title: 'Update Attendance',
              subtitle: 'Edit past attendance records',
            ),
          ),

          // Date + Group selectors
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  // Date picker row
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: IceColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: IceColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: IceColors.navyDeep,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _displayDate(_selectedDate),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: IceColors.text,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.edit_calendar_rounded,
                            size: 16,
                            color: IceColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // Group selector chips
          groups.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox(height: 8)),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
            data: (list) => SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final g = list[i] as Map;
                    final selected = _selectedGroup?['id'] == g['id'];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedGroup = g);
                        _loadAttendance();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? IceColors.navyDeep : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: selected
                                ? IceColors.navyDeep
                                : IceColors.border,
                          ),
                        ),
                        child: Text(
                          g['name']?.toString() ?? '—',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : IceColors.text,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Attendance list
          if (_loading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: IceColors.navyDeep),
                ),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error: $_error',
                  style: const TextStyle(color: IceColors.danger),
                ),
              ),
            )
          else if (_selectedGroup == null)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 40, 16, 16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 40,
                        color: IceColors.muted,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Select a group to load attendance',
                        style: TextStyle(color: IceColors.muted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_students.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No attendance records found.',
                    style: TextStyle(color: IceColors.muted),
                  ),
                ),
              ),
            )
          else ...[
            SliverList(
              delegate: SliverChildBuilderDelegate((_, i) {
                final s = _students[i] as Map;
                final id = s['id'] as int?;
                if (id == null) return const SizedBox.shrink();
                final status = _attendance[id] ?? 'absent';
                final firstName = s['first_name']?.toString() ?? '';
                final lastName = s['last_name']?.toString() ?? '';
                final name = '$firstName $lastName'.trim();
                final subtitle =
                    s['email']?.toString() ??
                    s['phone']?.toString() ??
                    s['login_id']?.toString() ??
                    '';

                return Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _statusBg(status),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _statusBorder(status),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: _statusBorder(
                              status,
                            ).withAlpha(30),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _statusColor(status),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.isNotEmpty ? name : 'Student',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (subtitle.isNotEmpty)
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: IceColors.muted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Status toggle
                          _StatusToggle(
                            status: status,
                            onChange: (v) =>
                                setState(() => _attendance[id] = v),
                          ),
                        ],
                      ),
                    )
                    .animate(delay: Duration(milliseconds: 200 + i * 30))
                    .slideX(begin: 0.05, duration: 250.ms)
                    .fadeIn(duration: 200.ms);
              }, childCount: _students.length),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                child: ElevatedButton(
                  onPressed: _saving || _students.isEmpty ? null : _update,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Update Attendance'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'present':
        return IceColors.success.withAlpha(8);
      case 'late':
        return IceColors.warning.withAlpha(10);
      default:
        return Colors.white;
    }
  }

  Color _statusBorder(String status) {
    switch (status) {
      case 'present':
        return IceColors.success.withAlpha(80);
      case 'late':
        return IceColors.warning.withAlpha(80);
      default:
        return IceColors.border;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return IceColors.success;
      case 'late':
        return IceColors.warning;
      default:
        return IceColors.navyDeep;
    }
  }
}

// ─── Status Toggle ────────────────────────────────────────────────────────────

class _StatusToggle extends StatelessWidget {
  final String status;
  final void Function(String) onChange;
  const _StatusToggle({required this.status, required this.onChange});

  @override
  Widget build(BuildContext context) {
    const statuses = ['present', 'late', 'absent'];
    const labels = {'present': 'P', 'late': 'L', 'absent': 'A'};
    const colors = {
      'present': IceColors.success,
      'late': IceColors.warning,
      'absent': IceColors.danger,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: statuses.map((s) {
        final isSelected = status == s;
        final color = colors[s]!;
        return GestureDetector(
          onTap: () => onChange(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(left: 4),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? color : color.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              labels[s]!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
