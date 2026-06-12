import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class StaffResultsScreen extends ConsumerStatefulWidget {
  const StaffResultsScreen({super.key});

  @override
  ConsumerState<StaffResultsScreen> createState() => _State();
}

class _State extends ConsumerState<StaffResultsScreen> {
  dynamic _selectedGroup;
  List<dynamic> _students = [];
  Map<int, Map<String, TextEditingController>> _controllers = {};
  bool _loadingStudents = false;
  bool _saving = false;
  String? _error;

  static const _examTypes = ['Midterm', 'Final', 'Quiz'];

  Future<void> _loadStudents(dynamic group) async {
    setState(() { _selectedGroup = group; _loadingStudents = true; _error = null; });
    for (final m in _controllers.values) {
      for (final c in m.values) { c.dispose(); }
    }
    _controllers = {};
    try {
      final res = await ApiClient.instance.dio.get('/groups/${group['id']}/students/');
      final list = (res.data is List) ? res.data as List : (res.data['students'] as List? ?? []);
      setState(() {
        _students = list;
        _controllers = {
          for (final s in list)
            (s['id'] as int): {
              for (final e in _examTypes) e: TextEditingController()
            }
        };
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
      final results = <Map<String, dynamic>>[];
      for (final entry in _controllers.entries) {
        for (final exam in entry.value.entries) {
          final v = exam.value.text.trim();
          if (v.isNotEmpty) {
            results.add({
              'student': entry.key,
              'exam_type': exam.key,
              'score': double.tryParse(v) ?? 0,
            });
          }
        }
      }
      await ApiClient.instance.dio.post('/results/', data: {
        'group': _selectedGroup['id'],
        'results': results,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Results saved!'),
          backgroundColor: IceColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _saving = false; });
    }
  }

  @override
  void dispose() {
    for (final m in _controllers.values) {
      for (final c in m.values) { c.dispose(); }
    }
    super.dispose();
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
              title: 'Add Results',
              subtitle: _selectedGroup == null
                  ? 'Select a group below'
                  : _selectedGroup['name']?.toString() ?? '',
            ),
          ),

          groups.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox(height: 8)),
            error:   (_, __) => const SliverToBoxAdapter(child: SizedBox()),
            data: (list) => SliverToBoxAdapter(
              child: SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final g        = list[i];
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
                              color: selected ? IceColors.navyDeep : IceColors.border),
                          boxShadow: selected
                              ? [BoxShadow(
                                  color: IceColors.navyDeep.withAlpha(40),
                                  blurRadius: 8, offset: const Offset(0, 2))]
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
                child: Center(child: Padding(
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
                child: Center(child: Text('No students.',
                    style: TextStyle(color: IceColors.muted))),
              ),
            )
          else if (_students.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 40, 16, 16),
                child: Center(
                  child: Column(children: [
                    Icon(Icons.touch_app_rounded, size: 40, color: IceColors.muted),
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
                  final s     = _students[i];
                  final id    = s['id'] as int;
                  final ctrls = _controllers[id];
                  if (ctrls == null) return const SizedBox();
                  final name  = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: IceColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: IceColors.navyDeep.withAlpha(15),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: IceColors.navyDeep),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(name.isEmpty ? s['login_id']?.toString() ?? '—' : name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                        ]),
                        const SizedBox(height: 12),
                        Row(
                          children: _examTypes.map((exam) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: TextFormField(
                                  controller: ctrls[exam],
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: exam,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
                childCount: _students.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                child: ElevatedButton(
                  onPressed: _saving || _students.isEmpty ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text('Save Results'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
