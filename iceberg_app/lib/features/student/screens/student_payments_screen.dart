import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

class StudentPaymentsScreen extends ConsumerWidget {
  const StudentPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(invoicesProvider);
    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(invoicesProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Payments',
                subtitle: 'Your tuition invoices and payment history',
              ),
            ),
            async.when(
              loading: () => const SliverToBoxAdapter(child: _Skeleton()),
              error: (e, _) => SliverToBoxAdapter(child: _ErrorCard('$e')),
              data: (list) {
                if (list.isEmpty) return SliverToBoxAdapter(child: _Empty());
                final unpaid = list
                    .where((x) => (x as Map)['is_paid'] != true)
                    .toList();
                final paid = list
                    .where((x) => (x as Map)['is_paid'] == true)
                    .toList();
                final totalDue = unpaid.fold<double>(
                  0,
                  (s, x) =>
                      s + (((x as Map)['amount'] as num?)?.toDouble() ?? 0),
                );
                return SliverList(
                  delegate: SliverChildListDelegate([
                    // Summary banner
                    if (unpaid.isNotEmpty)
                      _SummaryBanner(
                        unpaidCount: unpaid.length,
                        totalDue: totalDue,
                      ),
                    if (unpaid.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          'Outstanding',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: IceColors.muted,
                          ),
                        ),
                      ),
                      ...unpaid.asMap().entries.map(
                        (e) => _InvoiceCard(
                          item: e.value as Map<String, dynamic>,
                          index: e.key,
                        ),
                      ),
                    ],
                    if (paid.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Paid',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: IceColors.muted,
                          ),
                        ),
                      ),
                      ...paid.asMap().entries.map(
                        (e) => _InvoiceCard(
                          item: e.value as Map<String, dynamic>,
                          index: e.key + unpaid.length,
                        ),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final int unpaidCount;
  final double totalDue;
  const _SummaryBanner({required this.unpaidCount, required this.totalDue});

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [IceColors.navy, IceColors.navyMid, IceColors.navyDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount Due',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${totalDue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$unpaidCount invoice${unpaidCount != 1 ? 's' : ''} outstanding',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        )
        .animate()
        .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut)
        .fadeIn(duration: 350.ms);
  }
}

class _InvoiceCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  const _InvoiceCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final isPaid = item['is_paid'] == true;
    final amount = (item['amount'] as num?)?.toDouble() ?? 0;
    final desc = item['description']?.toString() ?? 'Invoice';
    final due = item['due_date']?.toString() ?? '';
    final isOverdue =
        !isPaid &&
        due.isNotEmpty &&
        DateTime.tryParse(due) != null &&
        DateTime.parse(due).isBefore(DateTime.now());

    final statusColor = isPaid
        ? IceColors.success
        : isOverdue
        ? IceColors.danger
        : IceColors.warning;
    final statusLabel = isPaid
        ? 'Paid'
        : isOverdue
        ? 'Overdue'
        : 'Pending';

    return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: IceColors.border),
            boxShadow: [
              BoxShadow(
                color: IceColors.navyDeep.withAlpha(6),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPaid
                      ? Icons.check_circle_outline_rounded
                      : Icons.receipt_outlined,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      desc,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: IceColors.text,
                      ),
                    ),
                    if (due.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          '${isOverdue ? "Was due" : "Due"} $due',
                          style: TextStyle(
                            fontSize: 11,
                            color: isOverdue
                                ? IceColors.danger
                                : IceColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isPaid ? IceColors.success : IceColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 60 + index * 50))
        .slideX(begin: 0.1, duration: 320.ms, curve: Curves.easeOut)
        .fadeIn(duration: 280.ms);
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: Colors.grey[200]!,
    highlightColor: Colors.grey[50]!,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < 4; i++) ...[
            Container(
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 56,
          color: IceColors.muted.withAlpha(100),
        ),
        const SizedBox(height: 16),
        const Text(
          'No invoices',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: IceColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your payment records will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: IceColors.muted),
        ),
      ],
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard(this.message);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Text(
      'Error: $message',
      style: const TextStyle(color: IceColors.danger),
    ),
  );
}
