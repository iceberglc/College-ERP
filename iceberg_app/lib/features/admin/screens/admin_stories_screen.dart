import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class AdminStoriesScreen extends ConsumerStatefulWidget {
  const AdminStoriesScreen({super.key});

  @override
  ConsumerState<AdminStoriesScreen> createState() => _AdminStoriesScreenState();
}

class _AdminStoriesScreenState extends ConsumerState<AdminStoriesScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _stories = [];
  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([_loadStories(), _loadGroups()]);
  }

  Future<void> _loadStories() async {
    try {
      dynamic data;
      try {
        final res = await ApiClient.instance.dio.get('/admin/stories/');
        data = res.data;
      } catch (_) {
        final res = await ApiClient.instance.dio.get('/stories/');
        data = res.data;
      }
      setState(() {
        _stories = List<Map<String, dynamic>>.from(
            data is List ? data : (data['results'] ?? data));
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadGroups() async {
    try {
      final res = await ApiClient.instance.dio.get('/admin/groups/');
      final raw = res.data;
      setState(() {
        _groups = List<Map<String, dynamic>>.from(
            raw is List ? raw : (raw['results'] ?? []));
      });
    } catch (_) {}
  }

  Future<void> _deleteStory(Map<String, dynamic> story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: IceColors.surface,
        title: const Text('Delete Story',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('This story will be permanently removed.',
            style: TextStyle(color: IceColors.muted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: IceColors.muted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: IceColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        dynamic endpoint;
        try {
          endpoint = '/admin/stories/${story['id']}/';
          await ApiClient.instance.dio.delete(endpoint);
        } catch (_) {
          await ApiClient.instance.dio.delete('/stories/${story['id']}/');
        }
        _loadStories();
      } catch (_) {}
    }
  }

  void _showAddForm() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    int? selectedGroupId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSheetState) => Container(
          margin: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
              left: 16,
              right: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: IceColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: IceColors.border),
          ),
          child: SingleChildScrollView(
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
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Add Story',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: IceColors.text)),
                const SizedBox(height: 16),
                _inputDeco(titleCtrl, 'Title'),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 4,
                  decoration: _fieldDecoration('Content'),
                ),
                if (_groups.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: selectedGroupId,
                    decoration: _fieldDecoration('Target Group (optional)'),
                    borderRadius: BorderRadius.circular(12),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('All')),
                      ..._groups.map((g) => DropdownMenuItem<int?>(
                            value: g['id'] as int?,
                            child: Text(g['name']?.toString() ?? ''),
                          )),
                    ],
                    onChanged: (v) =>
                        setSheetState(() => selectedGroupId = v),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final data = {
                      'title': titleCtrl.text.trim(),
                      'content': contentCtrl.text.trim(),
                      if (selectedGroupId != null) 'group': selectedGroupId,
                    };
                    try {
                      try {
                        await ApiClient.instance.dio
                            .post('/admin/stories/', data: data);
                      } catch (_) {
                        await ApiClient.instance.dio
                            .post('/stories/', data: data);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadStories();
                    } catch (_) {}
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: IceColors.lime,
                    foregroundColor: IceColors.navy,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Publish Story',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: IceColors.surface2,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: IceColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: IceColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: IceColors.navyDeep, width: 1.5)),
      );

  Widget _inputDeco(TextEditingController ctrl, String label) => TextField(
        controller: ctrl,
        decoration: _fieldDecoration(label),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IceColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddForm,
        backgroundColor: IceColors.navyDeep,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Story'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Stories',
                subtitle: 'Dashboard announcements',
                avatar: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: IceColors.navyDeep.withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: IceColors.border),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.auto_stories_rounded,
                      color: IceColors.navyDeep, size: 22),
                ),
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(
                  child: Center(
                      child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                              color: IceColors.navyDeep))))
            else if (_stories.isEmpty)
              SliverToBoxAdapter(child: _buildEmpty())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (i == _stories.length) return const SizedBox(height: 100);
                    return _StoryCard(
                      story: _stories[i],
                      index: i,
                      onDelete: () => _deleteStory(_stories[i]),
                    );
                  },
                  childCount: _stories.length + 1,
                ),
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
            Icon(Icons.auto_stories_outlined, size: 48, color: IceColors.muted),
            SizedBox(height: 12),
            Text('No stories yet',
                style: TextStyle(color: IceColors.muted, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final Map<String, dynamic> story;
  final int index;
  final VoidCallback onDelete;
  const _StoryCard(
      {required this.story, required this.index, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final title = story['title']?.toString() ?? 'Untitled';
    final content = story['content']?.toString() ?? '';
    final date = story['created_at']?.toString().split('T').first ??
        story['date']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IceColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IceColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: IceColors.navyDeep.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.article_rounded,
                color: IceColors.navyDeep, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: IceColors.text)),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: IceColors.muted)),
                ],
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(date,
                      style: const TextStyle(
                          fontSize: 11, color: IceColors.muted)),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline,
                color: IceColors.danger, size: 20),
            tooltip: 'Delete',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 60 + index * 30))
        .slideX(begin: 0.05, duration: 300.ms, curve: Curves.easeOut)
        .fadeIn(duration: 250.ms);
  }
}
