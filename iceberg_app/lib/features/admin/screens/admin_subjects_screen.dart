import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class AdminSubjectsScreen extends ConsumerStatefulWidget {
  const AdminSubjectsScreen({super.key});

  @override
  ConsumerState<AdminSubjectsScreen> createState() =>
      _AdminSubjectsScreenState();
}

class _AdminSubjectsScreenState extends ConsumerState<AdminSubjectsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _courses = [];
  int? _filterCourseId;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadSubjects(), _loadCourses()]);
  }

  Future<void> _loadSubjects() async {
    try {
      final res = await ApiClient.instance.dio.get('/admin/subjects/');
      setState(() {
        _subjects = List<Map<String, dynamic>>.from(
          res.data is List ? res.data : (res.data['results'] ?? res.data),
        );
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadCourses() async {
    try {
      final res = await ApiClient.instance.dio.get('/admin/courses/');
      setState(() {
        _courses = List<Map<String, dynamic>>.from(
          res.data is List ? res.data : (res.data['results'] ?? res.data),
        );
      });
    } catch (_) {}
  }

  void _showForm({Map<String, dynamic>? subject}) {
    final nameCtrl = TextEditingController(
      text: subject?['name']?.toString() ?? '',
    );
    int? selectedCourseId = subject?['course'] is Map
        ? subject!['course']['id'] as int?
        : (subject?['course'] as int?);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSheetState) => _SubjectFormSheet(
          title: subject == null ? 'Add Subject' : 'Edit Subject',
          nameCtrl: nameCtrl,
          courses: _courses,
          selectedCourseId: selectedCourseId,
          showDelete: subject != null,
          onCourseChanged: (id) => setSheetState(() => selectedCourseId = id),
          onSave: () async {
            if (nameCtrl.text.trim().isEmpty || selectedCourseId == null) {
              return;
            }
            final data = {
              'name': nameCtrl.text.trim(),
              'course': selectedCourseId,
            };
            try {
              if (subject == null) {
                await ApiClient.instance.dio.post(
                  '/admin/subjects/',
                  data: data,
                );
              } else {
                await ApiClient.instance.dio.patch(
                  '/admin/subjects/${subject['id']}/',
                  data: data,
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _loadSubjects();
            } catch (_) {}
          },
          onDelete: subject == null
              ? null
              : () async {
                  try {
                    await ApiClient.instance.dio.delete(
                      '/admin/subjects/${subject['id']}/',
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadSubjects();
                  } catch (_) {}
                },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterCourseId == null) return _subjects;
    return _subjects.where((s) {
      final courseId = s['course'] is Map ? s['course']['id'] : s['course'];
      return courseId == _filterCourseId;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: _loadAll,
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Subjects',
                subtitle: 'Manage course subjects',
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
                    Icons.menu_book_rounded,
                    color: IceColors.navyDeep,
                    size: 22,
                  ),
                ),
                actions: [
                  ElevatedButton.icon(
                    onPressed: () => _showForm(),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      'Add Subject',
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
            if (_courses.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _filterCourseId == null,
                          onTap: () => setState(() => _filterCourseId = null),
                        ),
                        const SizedBox(width: 8),
                        ..._courses.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: c['name']?.toString() ?? '',
                              selected: _filterCourseId == c['id'],
                              onTap: () => setState(
                                () => _filterCourseId = c['id'] as int?,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
            else if (_filtered.isEmpty)
              SliverToBoxAdapter(child: _buildEmpty())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((_, i) {
                  final filtered = _filtered;
                  if (i == filtered.length) return const SizedBox(height: 80);
                  return _SubjectCard(
                    subject: filtered[i],
                    index: i,
                    onTap: () => _showForm(subject: filtered[i]),
                  );
                }, childCount: _filtered.length + 1),
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
            Icon(Icons.menu_book_outlined, size: 48, color: IceColors.muted),
            SizedBox(height: 12),
            Text(
              'No subjects yet',
              style: TextStyle(color: IceColors.muted, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? IceColors.navyDeep : IceColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? IceColors.navyDeep : IceColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : IceColors.muted,
        ),
      ),
    ),
  );
}

class _SubjectCard extends StatelessWidget {
  final Map<String, dynamic> subject;
  final int index;
  final VoidCallback onTap;
  const _SubjectCard({
    required this.subject,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = subject['name']?.toString() ?? 'Untitled';
    final course = subject['course'] is Map
        ? subject['course']['name']?.toString() ?? ''
        : subject['course_name']?.toString() ?? '';

    return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: IceColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: IceColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: IceColors.navyDeep.withAlpha(12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.subject_rounded,
                    color: IceColors.navyDeep,
                    size: 18,
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
                      if (course.isNotEmpty)
                        Text(
                          course,
                          style: const TextStyle(
                            fontSize: 12,
                            color: IceColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (course.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: IceColors.navyDeep.withAlpha(10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      course,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: IceColors.navyDeep,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: IceColors.muted,
                ),
              ],
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: 60 + index * 30))
        .slideX(begin: 0.05, duration: 300.ms, curve: Curves.easeOut)
        .fadeIn(duration: 250.ms);
  }
}

class _SubjectFormSheet extends StatelessWidget {
  final String title;
  final TextEditingController nameCtrl;
  final List<Map<String, dynamic>> courses;
  final int? selectedCourseId;
  final bool showDelete;
  final ValueChanged<int?> onCourseChanged;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  const _SubjectFormSheet({
    required this.title,
    required this.nameCtrl,
    required this.courses,
    required this.selectedCourseId,
    required this.onCourseChanged,
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
            decoration: _inputDeco('Subject Name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: selectedCourseId,
            decoration: _inputDeco('Course'),
            borderRadius: BorderRadius.circular(12),
            items: courses
                .map(
                  (c) => DropdownMenuItem<int>(
                    value: c['id'] as int?,
                    child: Text(c['name']?.toString() ?? ''),
                  ),
                )
                .toList(),
            onChanged: onCourseChanged,
          ),
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
