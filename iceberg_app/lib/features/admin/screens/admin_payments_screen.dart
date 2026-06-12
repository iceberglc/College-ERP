import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() =>
      _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _invoices = [];
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.dio.get('/admin/invoices-manage/');
      setState(() {
        _invoices = List<Map<String, dynamic>>.from(
          res.data is List ? res.data : (res.data['results'] ?? res.data),
        );
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'All') return _invoices;
    return _invoices.where((inv) {
      final status = (inv['status'] ?? inv['payment_status'] ?? '')
          .toString()
          .toLowerCase();
      return status == _filter.toLowerCase();
    }).toList();
  }

  Future<void> _recordPayment(Map<String, dynamic> invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: IceColors.surface,
        title: const Text(
          'Record Payment',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Mark this invoice as paid?',
          style: TextStyle(color: IceColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: IceColors.muted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: IceColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiClient.instance.dio.patch(
          '/admin/invoices-manage/${invoice['id']}/',
          data: {'status': 'paid'},
        );
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment recorded'),
              backgroundColor: IceColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to record payment')),
          );
        }
      }
    }
  }

  Future<void> _addInvoice() async {
    final studentCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final dueDateCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
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
            const Text(
              'Add Invoice',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: IceColors.text,
              ),
            ),
            const SizedBox(height: 16),
            _inputField(studentCtrl, 'Student (ID or name)'),
            const SizedBox(height: 12),
            _inputField(
              amountCtrl,
              'Amount',
              type: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            _inputField(dueDateCtrl, 'Due Date (YYYY-MM-DD)'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (amountCtrl.text.trim().isEmpty) return;
                try {
                  await ApiClient.instance.dio.post(
                    '/admin/invoices-manage/',
                    data: {
                      'student': studentCtrl.text.trim(),
                      'amount': amountCtrl.text.trim(),
                      'due_date': dueDateCtrl.text.trim(),
                    },
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } catch (_) {}
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: IceColors.lime,
                foregroundColor: IceColors.navy,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String label, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Payments',
                subtitle: 'Invoice management',
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
                    Icons.receipt_long_rounded,
                    color: IceColors.navyDeep,
                    size: 22,
                  ),
                ),
                actions: [
                  ElevatedButton.icon(
                    onPressed: _addInvoice,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      'Add Invoice',
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: ['All', 'Paid', 'Unpaid']
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: f,
                            selected: _filter == f,
                            onTap: () => setState(() => _filter = f),
                          ),
                        ),
                      )
                      .toList(),
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
                  final list = _filtered;
                  if (i == list.length) return const SizedBox(height: 80);
                  return _InvoiceCard(
                    invoice: list[i],
                    index: i,
                    onRecordPayment: () => _recordPayment(list[i]),
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
            Icon(Icons.receipt_outlined, size: 48, color: IceColors.muted),
            SizedBox(height: 12),
            Text(
              'No invoices yet',
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

class _InvoiceCard extends StatelessWidget {
  final Map<String, dynamic> invoice;
  final int index;
  final VoidCallback onRecordPayment;
  const _InvoiceCard({
    required this.invoice,
    required this.index,
    required this.onRecordPayment,
  });

  Color get _statusColor {
    final s = (invoice['status'] ?? invoice['payment_status'] ?? '')
        .toString()
        .toLowerCase();
    if (s == 'paid') return IceColors.success;
    if (s == 'overdue') return IceColors.danger;
    return const Color(0xFFF59E0B);
  }

  String get _statusLabel {
    final s = (invoice['status'] ?? invoice['payment_status'] ?? '')
        .toString()
        .toLowerCase();
    if (s == 'paid') return 'Paid';
    if (s == 'overdue') return 'Overdue';
    return 'Unpaid';
  }

  bool get _isUnpaid {
    final s = (invoice['status'] ?? invoice['payment_status'] ?? '')
        .toString()
        .toLowerCase();
    return s == 'unpaid' || s == '';
  }

  @override
  Widget build(BuildContext context) {
    final studentName =
        invoice['student_name'] ??
        invoice['student']?['name'] ??
        invoice['student']?.toString() ??
        'Unknown';
    final amount = invoice['amount']?.toString() ?? '—';
    final dueDate = invoice['due_date']?.toString() ?? '';

    return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(16),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: IceColors.text,
                          ),
                        ),
                        if (dueDate.isNotEmpty)
                          Text(
                            'Due $dueDate',
                            style: const TextStyle(
                              fontSize: 12,
                              color: IceColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '\$$amount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: IceColors.text,
                    ),
                  ),
                  const Spacer(),
                  if (_isUnpaid)
                    ElevatedButton(
                      onPressed: onRecordPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: IceColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Record Payment'),
                    ),
                ],
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 60 + index * 30))
        .slideX(begin: 0.05, duration: 300.ms, curve: Curves.easeOut)
        .fadeIn(duration: 250.ms);
  }
}
