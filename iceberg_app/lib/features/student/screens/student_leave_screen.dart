import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/ice_tokens.dart';
import '../../../shared/widgets/ice_kit.dart';
import '../../../shared/widgets/ice_shell.dart';

/// Leave Requests — New Request form + History.
///
/// The backend `LeaveReportStudent` stores a single `date` + `message`, so the
/// richer fields (type + date range) are encoded into the message and the
/// from-date is sent as `date`. Status: 0 pending · 1 approved · -1 rejected.
class StudentLeaveScreen extends ConsumerStatefulWidget {
  const StudentLeaveScreen({super.key});

  @override
  ConsumerState<StudentLeaveScreen> createState() => _StudentLeaveScreenState();
}

class _StudentLeaveScreenState extends ConsumerState<StudentLeaveScreen> {
  int _tab = 0;

  static const _types = ['Medical leave', 'Family reason', 'Travel', 'Other'];
  String _type = _types.first;
  DateTime? _from;
  DateTime? _to;
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_from == null || _reason.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a start date and add a reason.')),
      );
      return;
    }
    setState(() => _busy = true);
    final df = DateFormat('yyyy-MM-dd');
    final range = _to != null
        ? '${df.format(_from!)} → ${df.format(_to!)}'
        : df.format(_from!);
    final message = '[$_type] $range\n${_reason.text.trim()}';
    try {
      await ApiClient.instance.dio.post(
        '/leave/',
        data: {'date': df.format(_from!), 'message': message},
      );
      ref.invalidate(leaveProvider);
      if (mounted) {
        setState(() {
          _reason.clear();
          _from = null;
          _to = null;
          _tab = 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave request submitted.')),
        );
      }
    } on DioException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit. Try again.')),
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
      title: 'Leave Requests',
      backButton: true,
      children: [
        IceChipTabs(
          tabs: const ['New Request', 'History'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 18),
        if (_tab == 0) ...[
          MicroLabel('Leave Type'),
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
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'From Date',
                  value: _from,
                  onPick: (d) => setState(() => _from = d),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  label: 'To Date',
                  value: _to,
                  firstDate: _from,
                  onPick: (d) => setState(() => _to = d),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          MicroLabel('Reason'),
          const SizedBox(height: 8),
          TextField(
            controller: _reason,
            maxLines: 4,
            maxLength: 300,
            style: TextStyle(color: t.textHi, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              hintText: 'Briefly explain your reason…',
            ),
          ),
          const SizedBox(height: 8),
          IceButton('Submit Request', busy: _busy, onPressed: _submit),
        ] else
          _History(),
      ],
    );
  }
}

class _History extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaves = ref.watch(leaveProvider);
    return leaves.when(
      loading: () => const Column(
        children: [
          SkeletonBox(height: 90),
          SizedBox(height: 10),
          SkeletonBox(height: 90),
        ],
      ),
      error: (e, _) =>
          ErrorState(error: e, onRetry: () => ref.invalidate(leaveProvider)),
      data: (list) {
        if (list.isEmpty) {
          return const IceCard(
            child: EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No requests yet',
              message: 'Your leave history will appear here.',
            ),
          );
        }
        return Column(
          children: list
              .map(
                (l) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LeaveCard(leave: l as Map<String, dynamic>),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final Map<String, dynamic> leave;
  const _LeaveCard({required this.leave});

  (String, BadgeTone) get _badge => switch (leave['status']) {
    1 => ('Approved', BadgeTone.accent),
    -1 => ('Rejected', BadgeTone.coral),
    _ => ('Pending', BadgeTone.amber),
  };

  @override
  Widget build(BuildContext context) {
    final t = context.ice;
    final (badge, tone) = _badge;
    final created = DateTime.tryParse(leave['created_at'] ?? '');
    final message = (leave['message'] ?? '').toString();
    // First line carries [type] + range, the rest is the reason.
    final lines = message.split('\n');
    final header = lines.first;
    final body = lines.length > 1 ? lines.sublist(1).join('\n') : '';

    return IceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  header,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: t.textHi,
                  ),
                ),
              ),
              StatusBadge(badge, tone: tone),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              body,
              style: TextStyle(fontSize: 13, color: t.textMid, height: 1.4),
            ),
          ],
          if (created != null) ...[
            const SizedBox(height: 8),
            Text(
              'Requested ${DateFormat('MMM d, yyyy').format(created)}',
              style: TextStyle(fontSize: 11.5, color: t.textLow),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateTime? firstDate;
  final ValueChanged<DateTime> onPick;

  const _DateField({
    required this.label,
    required this.value,
    this.firstDate,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.ice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MicroLabel(label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? firstDate ?? now,
              firstDate: firstDate ?? now.subtract(const Duration(days: 30)),
              lastDate: now.add(const Duration(days: 365)),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: t.accent,
                    onPrimary: t.onAccent,
                    surface: t.card,
                    onSurface: t.textHi,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: t.inset,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.stroke),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: t.textMid),
                const SizedBox(width: 8),
                Text(
                  value != null
                      ? DateFormat('MMM d, yyyy').format(value!)
                      : 'Select',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: value != null ? t.textHi : t.textLow,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
