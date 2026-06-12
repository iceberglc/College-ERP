import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

class StaffVocabularyDetailScreen extends StatefulWidget {
  final String vocabId;
  const StaffVocabularyDetailScreen({super.key, required this.vocabId});

  @override
  State<StaffVocabularyDetailScreen> createState() => _State();
}

class _State extends State<StaffVocabularyDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  List<dynamic> _words = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.dio.get(
        '/staff/vocabulary/${widget.vocabId}/',
      );
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _data = data;
        _words = (data['words'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteWord(dynamic wordId) async {
    try {
      await ApiClient.instance.dio.delete(
        '/staff/vocabulary/${widget.vocabId}/words/$wordId/',
      );
      await _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Word deleted.'),
            backgroundColor: IceColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addWord(
    String english,
    String translation,
    String example,
  ) async {
    try {
      await ApiClient.instance.dio.post(
        '/staff/vocabulary/${widget.vocabId}/words/',
        data: {
          'word': english,
          'meaning': translation,
          'example_sentence': example,
        },
      );
      await _fetch();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Word added!'),
            backgroundColor: IceColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_data == null) return;
    try {
      await ApiClient.instance.dio.patch(
        '/staff/vocabulary/${widget.vocabId}/',
        data: {'title': _data!['title'], 'description': _data!['description']},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Changes saved!'),
            backgroundColor: IceColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAddWordDialog() {
    showDialog(
      context: context,
      builder: (_) => _AddWordDialog(
        onAdd: (english, translation, example) {
          Navigator.of(context).pop();
          _addWord(english, translation, example);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IceColors.bg,
      appBar: AppBar(
        backgroundColor: IceColors.bg,
        elevation: 0,
        leading: const BackButton(color: IceColors.text),
        title: Text(
          _data?['title']?.toString() ?? 'Vocabulary Day',
          style: const TextStyle(
            color: IceColors.text,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _saveChanges,
            child: const Text(
              'Save',
              style: TextStyle(
                color: IceColors.navyDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: IceColors.navyDeep),
            )
          : _error != null
          ? _ErrorState(error: _error!, onRetry: _fetch)
          : _Body(
              data: _data!,
              words: _words,
              onDeleteWord: _deleteWord,
              onAddWord: _showAddWordDialog,
            ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<dynamic> words;
  final Future<void> Function(dynamic) onDeleteWord;
  final VoidCallback onAddWord;

  const _Body({
    required this.data,
    required this.words,
    required this.onDeleteWord,
    required this.onAddWord,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? '';
    final description = data['description']?.toString() ?? '';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Info card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(18),
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
                      const Icon(
                        Icons.edit_note_rounded,
                        size: 16,
                        color: IceColors.navyDeep,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Lesson Info',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: IceColors.navyDeep,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: IceColors.text,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: IceColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(duration: 250.ms),
        ),

        // Words header + Add button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Words (${words.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: IceColors.text,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onAddWord,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Word'),
                  style: FilledButton.styleFrom(
                    backgroundColor: IceColors.navyDeep,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Word list
        if (words.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.style_outlined,
                      size: 48,
                      color: IceColors.muted,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No words yet',
                      style: TextStyle(fontSize: 14, color: IceColors.muted),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap "Add Word" to add the first word.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: IceColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _WordRow(
                word: words[i] as Map,
                index: i,
                onDelete: () => onDeleteWord(words[i]['id']),
              ),
              childCount: words.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ─── Word Row ─────────────────────────────────────────────────────────────────

class _WordRow extends StatelessWidget {
  final Map word;
  final int index;
  final VoidCallback onDelete;
  const _WordRow({
    required this.word,
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final english = word['word']?.toString() ?? '';
    final translation = word['meaning']?.toString() ?? '';
    final example = word['example_sentence']?.toString() ?? '';

    return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: IceColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: IceColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: IceColors.navyDeep.withAlpha(12),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: IceColors.navyDeep,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      english,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: IceColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      translation,
                      style: const TextStyle(
                        fontSize: 13,
                        color: IceColors.muted,
                      ),
                    ),
                    if (example.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '"$example"',
                        style: const TextStyle(
                          fontSize: 12,
                          color: IceColors.muted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: IceColors.danger,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 30 * index))
        .fadeIn(duration: 200.ms);
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Word?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Remove "${word['word']}" from this lesson?',
          style: const TextStyle(color: IceColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: FilledButton.styleFrom(backgroundColor: IceColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Add Word Dialog ──────────────────────────────────────────────────────────

class _AddWordDialog extends StatefulWidget {
  final void Function(String english, String translation, String example) onAdd;
  const _AddWordDialog({required this.onAdd});

  @override
  State<_AddWordDialog> createState() => _AddWordDialogState();
}

class _AddWordDialogState extends State<_AddWordDialog> {
  final _englishCtrl = TextEditingController();
  final _translationCtrl = TextEditingController();
  final _exampleCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _englishCtrl.dispose();
    _translationCtrl.dispose();
    _exampleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Add Word',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _englishCtrl,
              decoration: const InputDecoration(
                labelText: 'English word *',
                prefixIcon: Icon(
                  Icons.translate_rounded,
                  size: 18,
                  color: IceColors.navyDeep,
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _translationCtrl,
              decoration: const InputDecoration(
                labelText: 'Translation *',
                prefixIcon: Icon(
                  Icons.language_rounded,
                  size: 18,
                  color: IceColors.navyDeep,
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _exampleCtrl,
              decoration: const InputDecoration(
                labelText: 'Example sentence',
                prefixIcon: Icon(
                  Icons.format_quote_rounded,
                  size: 18,
                  color: IceColors.muted,
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onAdd(
                _englishCtrl.text.trim(),
                _translationCtrl.text.trim(),
                _exampleCtrl.text.trim(),
              );
            }
          },
          style: FilledButton.styleFrom(backgroundColor: IceColors.navyDeep),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: IceColors.muted,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: IceColors.muted),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: IceColors.navyDeep),
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
