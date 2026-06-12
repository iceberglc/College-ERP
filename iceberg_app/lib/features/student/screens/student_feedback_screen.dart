import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/ice_page_header.dart';

final _feedbackProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiClient.instance.dio.get('/feedback/');
  final d = res.data;
  if (d is List) return d;
  if (d is Map && d.containsKey('results')) return d['results'] as List;
  return [];
});

class StudentFeedbackScreen extends ConsumerWidget {
  const StudentFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_feedbackProvider);

    return Scaffold(
      backgroundColor: IceColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showSheet(context, ref);
        },
        backgroundColor: IceColors.navyDeep,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text('New Feedback',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_feedbackProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Feedback',
                subtitle: 'Send feedback to your teacher',
              ),
            ),
            data.when(
              loading: () => const SliverToBoxAdapter(
                  child: Center(
                      child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                              color: IceColors.navyDeep)))),
              error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error: $e',
                          style: const TextStyle(color: IceColors.danger)))),
              data: (list) {
                if (list.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
                      child: Column(children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: IceColors.cyan.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded,
                              size: 32, color: IceColors.cyan),
                        ),
                        const SizedBox(height: 16),
                        const Text('No feedback sent yet.',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: IceColors.text)),
                        const SizedBox(height: 6),
                        const Text('Tap the button below to write feedback.',
                            style: TextStyle(color: IceColors.muted, fontSize: 13)),
                      ]),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      if (i == 0) return const SizedBox(height: 16);
                      if (i == list.length + 1) return const SizedBox(height: 100);
                      final item = list[i - 1];
                      return _FeedbackCard(item: item, index: i - 1);
                    },
                    childCount: list.length + 2,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FeedbackSheet(onSubmit: () {
        ref.invalidate(_feedbackProvider);
        Navigator.pop(ctx);
      }),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final dynamic item;
  final int index;
  const _FeedbackCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final hasReply = item['reply'] != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IceColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: IceColors.cyan.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 16, color: IceColors.cyan),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['feedback']?.toString() ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              Text(fmtDate(item['created_at']),
                  style: const TextStyle(fontSize: 11, color: IceColors.muted)),
            ]),
          ),
          if (hasReply)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: IceColors.success.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_rounded, size: 11, color: IceColors.success),
                SizedBox(width: 3),
                Text('Replied',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: IceColors.success)),
              ]),
            ),
        ]),
        if (hasReply) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: IceColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: IceColors.border),
            ),
            child: Row(children: [
              const Icon(Icons.reply_rounded, size: 14, color: IceColors.navyDeep),
              const SizedBox(width: 8),
              Expanded(
                child: Text(item['reply'].toString(),
                    style: const TextStyle(
                        fontSize: 12, color: IceColors.text),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        ],
      ]),
    )
        .animate(delay: Duration(milliseconds: 300 + index * 60))
        .slideX(begin: 0.08, duration: 350.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }
}

class _FeedbackSheet extends StatefulWidget {
  final VoidCallback onSubmit;
  const _FeedbackSheet({required this.onSubmit});
  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) {
      setState(() => _error = 'Write your feedback');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient.instance.dio.post('/feedback/',
          data: {'feedback': _ctrl.text.trim()});
      widget.onSubmit();
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: IceColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Send Feedback',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Your feedback is sent to your teacher.',
              style: TextStyle(fontSize: 13, color: IceColors.muted)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ctrl,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
                labelText: 'Your feedback',
                alignLabelWithHint: true),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: const TextStyle(color: IceColors.danger, fontSize: 12)),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Send Feedback'),
          ),
        ],
      ),
    );
  }
}
