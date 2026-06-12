import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class StaffAttendanceScreen extends ConsumerStatefulWidget {
  const StaffAttendanceScreen({super.key});

  @override
  ConsumerState<StaffAttendanceScreen> createState() => _State();
}

class _State extends ConsumerState<StaffAttendanceScreen> {
  dynamic _selectedGroup;
  Map<int, bool> _attendance = {};
  List<dynamic> _students = [];
  bool _saving = false;
  bool _loadingStudents = false;
  String? _error;

  Future<void> _loadStudents(dynamic group) async {
    setState(() {
      _selectedGroup = group;
      _loadingStudents = true;
      _error = null;
      _attendance = {};
    });
    try {
      final res = await ApiClient.instance.dio.get('/groups/${group['id']}/students/');
      final list = (res.data is List) ? res.data as List : (res.data['students'] as List? ?? []);
      setState(() {
        _students = list;
        _attendance = {for (final s in list) (s['id'] as int): false};
        _loadingStudents = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loadingStudents = false; });
    }
  }

  Future<void> _save() async {
    if (_selectedGroup == null) return;
    setState(() { _saving = true; _error = null; });
    try {
      await ApiClient.instance.dio.post('/attendance/', data: {
        'group': _selectedGroup['id'],
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'attendance': _attendance.entries
            .map((e) => {'student': e.key, 'present': e.value})
            .toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Attendance saved!'),
            backgroundColor: IceColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() {
          _attendance = {for (final s in _students) (s['id'] as int): false};
        });
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _saving = false; });
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
              title: 'Take Attendance',
              subtitle: _selectedGroup == null
                  ? 'Select a group below'
                  : _selectedGroup['name']?.toString() ?? '',
            ),
          ),

          // Group selector
          groups.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox(height: 8)),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
            data: (list) => SliverToBoxAdapter(
              child: SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final g = list[i];
                    final selected = _selectedGroup?['id'] == g['id'];
                    return GestureDetector(
                      onTap: () => _loadStudents(g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? IceColors.navyDeep : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: selected ? IceColors.navyDeep : IceColors.border,
                          ),
                          boxShadow: selected
                              ? [BoxShadow(
                                  color: IceColors.navyDeep.withAlpha(40),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))]
                              : null,
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

          if (_loadingStudents)
            const SliverToBoxAdapter(
                child: Center(
                    child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: IceColors.navyDeep))))
          else if (_error != null)
            SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!,
                        style: const TextStyle(color: IceColors.danger))))
          else if (_students.isEmpty && _selectedGroup != null)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                    child: Text('No students in this group.',
                        style: TextStyle(color: IceColors.muted))),
              ),
            )
          else if (_students.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 40, 16, 16),
                child: Center(
                  child: Column(children: [
                    Icon(Icons.touch_app_rounded,
                        size: 40, color: IceColors.muted),
                    SizedBox(height: 8),
                    Text('Select a group to start',
                        style: TextStyle(color: IceColors.muted, fontSize: 14)),
                  ]),
                ),
              ),
            )
          else ...[
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final s       = _students[i];
                  final id      = s['id'] as int;
                  final present = _attendance[id] ?? false;
                  final name    = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    decoration: BoxDecoration(
                      color: present ? IceColors.success.withAlpha(8) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: present
                            ? IceColors.success.withAlpha(80)
                            : IceColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: present,
                      onChanged: (v) =>
                          setState(() => _attendance[id] = v ?? false),
                      title: Text(
                        name.isEmpty ? s['login_id']?.toString() ?? '—' : name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(s['login_id']?.toString() ?? ''),
                      activeColor: IceColors.success,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      secondary: CircleAvatar(
                        radius: 18,
                        backgroundColor: present
                            ? IceColors.success.withAlpha(20)
                            : IceColors.navyDeep.withAlpha(12),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: present ? IceColors.success : IceColors.navyDeep),
                        ),
                      ),
                    ),
                  )
                      .animate(delay: Duration(milliseconds: 200 + i * 30))
                      .slideX(begin: 0.05, duration: 250.ms)
                      .fadeIn(duration: 200.ms);
                },
                childCount: _students.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                child: ElevatedButton(
                  onPressed: _saving || _students.isEmpty ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(
                          'Save Attendance (${_attendance.values.where((v) => v).length}/${_students.length})',
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
