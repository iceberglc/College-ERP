import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/ice_tokens.dart';
import '../../../shared/widgets/ice_kit.dart';
import '../../../shared/widgets/ice_shell.dart';

/// Feedback — Send (typed) + My Feedback with admin replies.
///
/// The backend `FeedbackStudent` stores `feedback` + `reply`. The feedback
/// type is encoded as a "[Type] " prefix on the message.
class StudentFeedbackScreen extends ConsumerStatefulWidget {
  const StudentFeedbackScreen({super.key});

  @override
  ConsumerState<StudentFeedbackScreen> createState() =>
      _StudentFeedbackScreenState();
}

class _StudentFeedbackScreenState extends ConsumerState<StudentFeedbackScreen> {
  int _tab = 0;
  static const _types = [
    'General feedback',
    'Teacher feedback',
    'Class feedback',
    'System problem',
    'Payment issue',
    'Other',
  ];
  String _type = _types.first;
  final _message = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_message.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ApiClient.instance.dio.post(
        '/feedback/',
        data: {'feedback': '[$_type] ${_message.text.trim()}'},
      );
      ref.invalidate(feedbackProvider);
      if (mounted) {
        setState(() {
          _message.clear();
          _tab = 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback sent. Thank you!')),
        );
      }
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send feedback. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ice;

    return IcePage(
      title: 'Feedback',
      backButton: true,
      children: [
        IceChipTabs(
          tabs: const ['New Feedback', 'My Feedback'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 18),
        if (_tab == 0) ...[
          MicroLabel('Feedback Type'),
          const SizedBox(height: 8),
          IceCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _type,
                isExpanded: true,
                dropdownColor: t.card,
                icon: Icon(Icons.expand_more_rounded, color: t.textMid),
                style: TextStyle(
                  color: t.textHi,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
                items: _types
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
            ),
          ),
          const SizedBox(height: 14),
          MicroLabel('Your Message'),
          const SizedBox(height: 8),
          TextField(
            controller: _message,
            maxLines: 5,
            maxLength: 500,
            style: TextStyle(color: t.textHi, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              hintText: 'Share feedback or ask a question…',
            ),
          ),
          const SizedBox(height: 8),
          IceButton('Send Feedback', busy: _busy, onPressed: _send),
        ] else
          _MyFeedback(),
      ],
    );
  }
}

class _MyFeedback extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedback = ref.watch(feedbackProvider);
    return feedback.when(
      loading: () => const Column(
        children: [
          SkeletonBox(height: 100),
          SizedBox(height: 10),
          SkeletonBox(height: 100),
        ],
      ),
      error: (e, _) =>
          ErrorState(error: e, onRetry: () => ref.invalidate(feedbackProvider)),
      data: (list) {
        if (list.isEmpty) {
          return const IceCard(
            child: EmptyState(
              icon: Icons.forum_outlined,
              title: 'No feedback yet',
              message: 'Your feedback and any replies will show up here.',
            ),
          );
        }
        return Column(
          children: list
              .map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FeedbackCard(f: f as Map<String, dynamic>),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final Map<String, dynamic> f;
  const _FeedbackCard({required this.f});

  @override
  Widget build(BuildContext context) {
    final t = context.ice;
    final replied = f['has_reply'] == true;
    final created = DateTime.tryParse(f['created_at'] ?? '');

    return IceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              StatusBadge(
                replied ? 'Replied' : 'Open',
                tone: replied ? BadgeTone.accent : BadgeTone.amber,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            f['feedback'] ?? '',
            style: TextStyle(fontSize: 14, color: t.textHi, height: 1.45),
          ),
          if (created != null) ...[
            const SizedBox(height: 6),
            Text(
              DateFormat('MMM d, yyyy').format(created),
              style: TextStyle(fontSize: 11.5, color: t.textLow),
            ),
          ],
          if (replied) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.inset,
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: t.accent, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.reply_rounded, size: 14, color: t.accent),
                      const SizedBox(width: 6),
                      MicroLabel('Reply', color: t.accent),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    f['reply'] ?? '',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: t.textMid,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
