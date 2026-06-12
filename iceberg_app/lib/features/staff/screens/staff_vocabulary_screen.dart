import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class StaffVocabularyScreen extends ConsumerWidget {
  const StaffVocabularyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffVocabularyProvider);
    return Scaffold(
      backgroundColor: IceColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDay(context, ref),
        backgroundColor: IceColors.navyDeep,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Day', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(staffVocabularyProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Vocabulary',
                subtitle: 'Manage vocabulary day sets',
              ),
            ),
            async.when(
              loading: () =>
                  const SliverToBoxAdapter(child: _VocabSkeleton()),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $e',
                      style: const TextStyle(color: IceColors.danger)),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return SliverToBoxAdapter(child: _Empty());
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      if (i == list.length) return const SizedBox(height: 100);
                      final item = list[i] as Map;
                      return _VocabDayCard(
                        item: item,
                        index: i,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StaffVocabularyDayDetailScreen(
                              dayId: item['id'] as int,
                              dayTitle: item['title']?.toString() ?? 'Day ${item['day_number']}',
                            ),
                          ),
                        ).then((_) => ref.invalidate(staffVocabularyProvider)),
                        onDelete: () => _deleteDay(context, ref, item['id'] as int),
                      );
                    },
                    childCount: list.length + 1,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateDay(BuildContext context, WidgetRef ref) async {
    final groups = ref.read(staffGroupsProvider).value ?? [];
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateDaySheet(groups: groups, ref: ref),
    );
  }

  Future<void> _deleteDay(BuildContext context, WidgetRef ref, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Day'),
        content: const Text('Are you sure you want to delete this vocabulary day?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: IceColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiClient.instance.dio.delete('/staff/vocabulary/$id/');
        ref.invalidate(staffVocabularyProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

class _VocabDayCard extends StatelessWidget {
  final Map item;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _VocabDayCard({
    required this.item,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isReleased = item['is_released'] == true;
    final wordCount = item['word_count'] ?? 0;
    final dayNumber = item['day_number'] ?? 0;
    final title = item['title']?.toString() ?? '';
    final groupName = item['group_name']?.toString() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isReleased ? IceColors.success.withAlpha(80) : IceColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isReleased
                    ? IceColors.success.withAlpha(20)
                    : IceColors.navyDeep.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: isReleased
                    ? const Icon(Icons.check_circle_rounded,
                        color: IceColors.success, size: 22)
                    : Text('D$dayNumber',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: IceColors.navyDeep)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.isNotEmpty ? title : 'Day $dayNumber',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: IceColors.text)),
                  Text(
                    '$groupName · $wordCount word${wordCount != 1 ? 's' : ''} · ${isReleased ? 'Released' : 'Draft'}',
                    style: const TextStyle(fontSize: 11, color: IceColors.muted),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_right_rounded,
                    color: IceColors.muted, size: 20),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: IceColors.danger, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 40 * index))
        .fadeIn(duration: 280.ms)
        .slideY(begin: 0.06, duration: 280.ms);
  }
}

class _CreateDaySheet extends ConsumerStatefulWidget {
  final List<dynamic> groups;
  final WidgetRef ref;
  const _CreateDaySheet({required this.groups, required this.ref});

  @override
  ConsumerState<_CreateDaySheet> createState() => _CreateDaySheetState();
}

class _CreateDaySheetState extends ConsumerState<_CreateDaySheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  int? _selectedGroupId;
  bool _isReleased = false;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a group')));
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiClient.instance.dio.post('/staff/vocabulary/create/', data: {
        'title': _titleCtrl.text.trim(),
        'group_id': _selectedGroupId,
        'is_released': _isReleased,
      });
      widget.ref.invalidate(staffVocabularyProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Vocabulary Day',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: IceColors.text)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                  hintText: 'e.g. Business Vocabulary #1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedGroupId,
                decoration: const InputDecoration(
                  labelText: 'Group *',
                  border: OutlineInputBorder(),
                ),
                items: widget.groups.map((g) {
                  final m = g as Map;
                  return DropdownMenuItem<int>(
                    value: m['id'] as int?,
                    child: Text(m['name']?.toString() ?? ''),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedGroupId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isReleased,
                onChanged: (v) => setState(() => _isReleased = v),
                title: const Text('Release to students',
                    style: TextStyle(fontSize: 14)),
                subtitle: const Text('Students can see this day immediately',
                    style: TextStyle(fontSize: 12, color: IceColors.muted)),
                activeColor: IceColors.navyDeep,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: IceColors.navyDeep,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Create',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StaffVocabularyDayDetailScreen extends ConsumerStatefulWidget {
  final int dayId;
  final String dayTitle;
  const StaffVocabularyDayDetailScreen({
    super.key,
    required this.dayId,
    required this.dayTitle,
  });

  @override
  ConsumerState<StaffVocabularyDayDetailScreen> createState() =>
      _StaffVocabularyDayDetailScreenState();
}

class _StaffVocabularyDayDetailScreenState
    extends ConsumerState<StaffVocabularyDayDetailScreen> {
  void _showAddWordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddWordSheet(
        dayId: widget.dayId,
        onAdded: () => ref.invalidate(staffVocabDetailProvider(widget.dayId)),
      ),
    );
  }

  Future<void> _deleteWord(int wordId) async {
    try {
      await ApiClient.instance.dio
          .delete('/staff/vocabulary/${widget.dayId}/words/$wordId/');
      ref.invalidate(staffVocabDetailProvider(widget.dayId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _toggleRelease(bool current) async {
    try {
      await ApiClient.instance.dio.patch(
        '/staff/vocabulary/${widget.dayId}/',
        data: {'is_released': !current},
      );
      ref.invalidate(staffVocabDetailProvider(widget.dayId));
      ref.invalidate(staffVocabularyProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(staffVocabDetailProvider(widget.dayId));

    return Scaffold(
      backgroundColor: IceColors.bg,
      appBar: AppBar(
        backgroundColor: IceColors.navyDeep,
        foregroundColor: Colors.white,
        title: Text(widget.dayTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        elevation: 0,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWordSheet,
        backgroundColor: IceColors.navyDeep,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Word',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: IceColors.danger))),
        data: (day) {
          final isReleased = day['is_released'] == true;
          final words = (day['words'] as List?) ?? [];
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Release toggle card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isReleased
                                ? IceColors.success.withAlpha(80)
                                : IceColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isReleased
                                    ? IceColors.success.withAlpha(20)
                                    : IceColors.border,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isReleased
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                color: isReleased
                                    ? IceColors.success
                                    : IceColors.muted,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isReleased
                                        ? 'Released to students'
                                        : 'Draft — not visible',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14),
                                  ),
                                  Text(
                                    '${words.length} word${words.length != 1 ? 's' : ''}',
                                    style: const TextStyle(
                                        fontSize: 12, color: IceColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isReleased,
                              onChanged: (_) => _toggleRelease(isReleased),
                              activeColor: IceColors.navyDeep,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (words.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: IceColors.border),
                          ),
                          child: const Center(
                            child: Text('No words yet. Tap + to add.',
                                style: TextStyle(
                                    color: IceColors.muted, fontSize: 13)),
                          ),
                        )
                      else
                        ...words.asMap().entries.map((e) {
                          final w = e.value as Map;
                          return _WordCard(
                            word: w,
                            index: e.key,
                            onDelete: () => _deleteWord(w['id'] as int),
                          );
                        }),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final Map word;
  final int index;
  final VoidCallback onDelete;
  const _WordCard({
    required this.word,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: IceColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: IceColors.navyDeep.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text('${index + 1}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: IceColors.navyDeep)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(word['word']?.toString() ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: IceColors.navyDeep)),
                    if ((word['pronunciation_note'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        word['pronunciation_note'].toString(),
                        style: const TextStyle(
                            fontSize: 11,
                            color: IceColors.muted,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(word['meaning']?.toString() ?? '',
                    style: const TextStyle(
                        fontSize: 13, color: IceColors.text)),
                if ((word['example_sentence'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '"${word['example_sentence']}"',
                      style: const TextStyle(
                          fontSize: 12,
                          color: IceColors.muted,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: const Icon(Icons.delete_outline_rounded,
                  color: IceColors.danger, size: 18),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 40 * index))
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.05, duration: 250.ms);
  }
}

class _AddWordSheet extends StatefulWidget {
  final int dayId;
  final VoidCallback onAdded;
  const _AddWordSheet({required this.dayId, required this.onAdded});

  @override
  State<_AddWordSheet> createState() => _AddWordSheetState();
}

class _AddWordSheetState extends State<_AddWordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _wordCtrl = TextEditingController();
  final _meaningCtrl = TextEditingController();
  final _pronCtrl = TextEditingController();
  final _exampleCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _wordCtrl.dispose();
    _meaningCtrl.dispose();
    _pronCtrl.dispose();
    _exampleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiClient.instance.dio.post(
        '/staff/vocabulary/${widget.dayId}/words/',
        data: {
          'word': _wordCtrl.text.trim(),
          'meaning': _meaningCtrl.text.trim(),
          if (_pronCtrl.text.trim().isNotEmpty)
            'pronunciation_note': _pronCtrl.text.trim(),
          if (_exampleCtrl.text.trim().isNotEmpty)
            'example_sentence': _exampleCtrl.text.trim(),
        },
      );
      widget.onAdded();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          0, 0, 0, MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Word',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: IceColors.text)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _wordCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Word *', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _meaningCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Meaning *', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pronCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Pronunciation note (optional)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _exampleCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Example sentence (optional)',
                      border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: IceColors.navyDeep,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Add Word',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VocabSkeleton extends StatelessWidget {
  const _VocabSkeleton();
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            for (int i = 0; i < 5; i++) ...[
              Container(
                  height: 68,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16))),
              const SizedBox(height: 10),
            ],
          ]),
        ),
      );
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(40),
        child: Column(children: [
          Icon(Icons.menu_book_outlined, size: 56, color: IceColors.muted),
          SizedBox(height: 16),
          Text('No vocabulary days yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: IceColors.muted)),
          SizedBox(height: 8),
          Text(
            'Tap the + button to create a new vocabulary day.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: IceColors.muted),
          ),
        ]),
      );
}
