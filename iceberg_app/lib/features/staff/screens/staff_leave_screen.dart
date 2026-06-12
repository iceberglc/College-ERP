import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/ice_list_tile.dart';
import '../../../shared/widgets/ice_page_header.dart';

class StaffLeaveScreen extends ConsumerWidget {
  const StaffLeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(leaveProvider);

    return Scaffold(
      backgroundColor: IceColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showApplySheet(context, ref);
        },
        backgroundColor: IceColors.navyDeep,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Apply Leave',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(leaveProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Leave Requests',
                subtitle: 'Apply and track your leaves',
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
                            color: IceColors.navyDeep.withAlpha(12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.event_note_outlined,
                              size: 32, color: IceColors.navyDeep),
                        ),
                        const SizedBox(height: 16),
                        const Text('No leave requests yet.',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: IceColors.text)),
                        const SizedBox(height: 6),
                        const Text('Tap the button below to apply.',
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
                      final item   = list[i - 1];
                      final status = item['status']?.toString() ?? 'pending';
                      final badge  = status == 'approved'
                          ? IceBadge.approved
                          : status == 'rejected'
                              ? IceBadge.rejected
                              : IceBadge.pending;
                      return _LeaveCard(
                        date: item['date']?.toString() ?? fmtDate(item['created_at']),
                        message: item['message']?.toString() ?? '',
                        badge: badge,
                        index: i - 1,
                      );
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

  void _showApplySheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ApplySheet(onSubmit: () {
        ref.invalidate(leaveProvider);
        Navigator.pop(ctx);
      }),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final String date;
  final String message;
  final IceBadge badge;
  final int index;
  const _LeaveCard({
    required this.date,
    required this.message,
    required this.badge,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IceColors.border),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: IceColors.navyDeep.withAlpha(12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.calendar_today_rounded,
              size: 18, color: IceColors.navyDeep),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(date,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(message,
                  style: const TextStyle(fontSize: 12, color: IceColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
        badge,
      ]),
    )
        .animate(delay: Duration(milliseconds: 300 + index * 60))
        .slideX(begin: 0.08, duration: 350.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }
}

class _ApplySheet extends StatefulWidget {
  final VoidCallback onSubmit;
  const _ApplySheet({required this.onSubmit});
  @override
  State<_ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends State<_ApplySheet> {
  final _msgCtrl = TextEditingController();
  DateTime? _date;
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _msgCtrl.dispose(); super.dispose(); }

  Future<void> _pick() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _submit() async {
    if (_date == null) { setState(() => _error = 'Pick a date'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient.instance.dio.post('/leave/', data: {
        'date': _date!.toIso8601String().substring(0, 10),
        'message': _msgCtrl.text.trim(),
      });
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
          const Text('Apply for Leave',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pick,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: IceColors.surface2,
                border: Border.all(
                    color: _date != null ? IceColors.navyDeep : IceColors.border,
                    width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.calendar_today_outlined,
                    size: 18,
                    color: _date != null ? IceColors.navyDeep : IceColors.muted),
                const SizedBox(width: 10),
                Text(
                  _date == null ? 'Select date' : fmtDate(_date!.toIso8601String()),
                  style: TextStyle(
                      color: _date == null ? IceColors.muted : IceColors.text,
                      fontWeight: FontWeight.w500),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _msgCtrl,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
                labelText: 'Reason', alignLabelWithHint: true),
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
                : const Text('Submit Request'),
          ),
        ],
      ),
    );
  }
}
