import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/ice_page_header.dart';

final _staffFeedbackProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiClient.instance.dio.get('/feedback/');
  final d = res.data;
  if (d is List) return d;
  if (d is Map && d.containsKey('results')) return d['results'] as List;
  return [];
});

class StaffFeedbackScreen extends ConsumerWidget {
  const StaffFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_staffFeedbackProvider);

    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(_staffFeedbackProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Feedback Inbox',
                subtitle: 'Messages from your students',
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
                            color: IceColors.info.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.inbox_outlined,
                              size: 32, color: IceColors.info),
                        ),
                        const SizedBox(height: 16),
                        const Text('No feedback received.',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: IceColors.text)),
                        const SizedBox(height: 6),
                        const Text('Feedback from students will appear here.',
                            style: TextStyle(color: IceColors.muted, fontSize: 13),
                            textAlign: TextAlign.center),
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
                      return _FeedbackCard(
                          item: item, index: i - 1, ref: ref);
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
}

class _FeedbackCard extends StatelessWidget {
  final dynamic item;
  final int index;
  final WidgetRef ref;
  const _FeedbackCard({required this.item, required this.index, required this.ref});

  @override
  Widget build(BuildContext context) {
    final hasReply    = item['reply'] != null;
    final studentName = item['student_name']?.toString() ?? '?';
    final initial     = studentName[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: hasReply ? IceColors.border : IceColors.info.withAlpha(60)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: IceColors.navyDeep.withAlpha(15),
            child: Text(initial,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: IceColors.navyDeep)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(studentName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
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
              child: const Text('Replied',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: IceColors.success)),
            )
          else
            GestureDetector(
              onTap: () => _replySheet(context, ref, item),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: IceColors.info.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.reply_rounded, size: 13, color: IceColors.info),
                  SizedBox(width: 4),
                  Text('Reply',
                      style: TextStyle(
                          fontSize: 11,
                          color: IceColors.info,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: IceColors.surface2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            item['feedback']?.toString() ?? '—',
            style: const TextStyle(fontSize: 13, color: IceColors.text),
          ),
        ),
        if (hasReply) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: IceColors.success.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: IceColors.success.withAlpha(40)),
            ),
            child: Row(children: [
              const Icon(Icons.reply_rounded, size: 14, color: IceColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(item['reply'].toString(),
                    style: const TextStyle(
                        fontSize: 12, color: IceColors.text)),
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

  void _replySheet(BuildContext context, WidgetRef ref, dynamic item) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
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
            const Text('Reply to Feedback',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: IceColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: IceColors.border),
              ),
              child: Text('"${item['feedback']}"',
                  style: const TextStyle(
                      fontSize: 13,
                      color: IceColors.muted,
                      fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: ctrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Your reply', alignLabelWithHint: true),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (ctrl.text.trim().isEmpty) return;
                await ApiClient.instance.dio.patch(
                    '/feedback/${item['id']}/',
                    data: {'reply': ctrl.text.trim()});
                ref.invalidate(_staffFeedbackProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Send Reply'),
            ),
          ],
        ),
      ),
    );
  }
}
