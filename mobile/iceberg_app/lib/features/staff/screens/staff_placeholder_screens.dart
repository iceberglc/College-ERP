import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// Back control for the staff Payments / Notifications headers. Works whether
/// the screen was pushed (pops) or reached via `go` (falls back to home).
class _HeaderBack extends StatelessWidget {
  const _HeaderBack();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () {
          final nav = Navigator.of(context);
          if (nav.canPop()) {
            nav.maybePop();
          } else {
            context.go('/staff/home');
          }
        },
        child: const Row(children: [
          Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
          SizedBox(width: 6),
          Text('Back',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ─── Staff Payments Screen ────────────────────────────────────────────────────
class StaffPaymentsScreen extends ConsumerWidget {
  const StaffPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(staffPaymentsProvider);
    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(staffPaymentsProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _PaymentsHeader()),
            invoices.when(
              loading: () => const SliverToBoxAdapter(child: _Skeleton()),
              error: (e, _) => SliverToBoxAdapter(child: _ErrCard('$e')),
              data: (list) {
                if (list.isEmpty) return _empty('No payment records', Icons.payment_outlined);
                final paid = list.where((i) => i['status'] == 'paid').length;
                return SliverList(
                  delegate: SliverChildListDelegate([
                    _SummaryRow(total: list.length, paid: paid, pending: list.length - paid),
                    const SizedBox(height: 8),
                    ...list.asMap().entries.map((e) => _InvoiceCard(inv: e.value, idx: e.key)),
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

  SliverFillRemaining _empty(String msg, IconData icon) => SliverFillRemaining(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: IceColors.muted),
            const SizedBox(height: 12),
            Text(msg,
                style: const TextStyle(
                    color: IceColors.muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

class _PaymentsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: kHeroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _HeaderBack(),
        const Text('Payments',
            style: TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900))
            .animate().slideX(begin: -0.1, duration: 400.ms).fadeIn(duration: 300.ms),
        const SizedBox(height: 4),
        Text('Student invoices for your groups',
            style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 13))
            .animate(delay: 80.ms).fadeIn(),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int total, paid, pending;
  const _SummaryRow({required this.total, required this.paid, required this.pending});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        _Chip('Total', '$total', IceColors.navyDeep),
        const SizedBox(width: 8),
        _Chip('Paid', '$paid', IceColors.success),
        const SizedBox(width: 8),
        _Chip('Pending', '$pending', IceColors.warning),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Chip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: IceColors.muted)),
          ]),
        ),
      );
}

class _InvoiceCard extends StatelessWidget {
  final dynamic inv;
  final int idx;
  const _InvoiceCard({required this.inv, required this.idx});

  @override
  Widget build(BuildContext context) {
    final isPaid = inv['status']?.toString() == 'paid';
    final statusColor = isPaid ? IceColors.success : IceColors.warning;
    final student = inv['student_name'] ?? inv['student'] ?? '—';
    final group = inv['group_name'] ?? inv['group'] ?? '—';
    final due = inv['due_date']?.toString() ?? '';
    final amount = inv['amount'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IceColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: statusColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(
              isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,
              color: statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(student.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text(group.toString(),
                  style: const TextStyle(fontSize: 12, color: IceColors.muted)),
              if (due.isNotEmpty)
                Text('Due $due',
                    style: const TextStyle(fontSize: 11, color: IceColors.muted)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              amount != null ? fmtCurrency(amount) : '—',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                isPaid ? 'Paid' : 'Pending',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
              ),
            ),
          ]),
        ]),
      ),
    )
        .animate(delay: Duration(milliseconds: 300 + idx * 60))
        .slideY(begin: 0.1, duration: 350.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }
}

// ─── Staff Notifications Screen ───────────────────────────────────────────────
class StaffNotificationsScreen extends ConsumerWidget {
  const StaffNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(notificationsProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _NotifHeader()),
            notifs.when(
              loading: () => const SliverToBoxAdapter(child: _Skeleton()),
              error: (e, _) => SliverToBoxAdapter(child: _ErrCard('$e')),
              data: (list) {
                if (list.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.notifications_none_rounded, size: 56, color: IceColors.muted),
                        SizedBox(height: 12),
                        Text('No notifications',
                            style: TextStyle(
                                color: IceColors.muted,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 12),
                    ...list.asMap().entries.map((e) => _NotifCard(n: e.value, idx: e.key)),
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

class _NotifHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 20, 20, 28),
      decoration: const BoxDecoration(
        gradient: kHeroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _HeaderBack(),
        const Text('Notifications',
            style: TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900))
            .animate().slideX(begin: -0.1, duration: 400.ms).fadeIn(duration: 300.ms),
        const SizedBox(height: 4),
        Text('Admin broadcasts and system alerts',
            style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 13))
            .animate(delay: 80.ms).fadeIn(),
      ]),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final dynamic n;
  final int idx;
  const _NotifCard({required this.n, required this.idx});

  @override
  Widget build(BuildContext context) {
    final isRead = n['is_read'] == true;
    final title = n['title']?.toString() ?? n['message']?.toString() ?? '—';
    final message = n['message']?.toString() ?? '';
    final date = n['created_at']?.toString() ?? '';
    final dotColor = isRead ? IceColors.muted : IceColors.navyDeep;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : IceColors.navyDeep.withAlpha(8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRead ? IceColors.border : IceColors.navyDeep.withAlpha(40),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: dotColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(
              isRead
                  ? Icons.notifications_none_rounded
                  : Icons.notifications_active_rounded,
              color: dotColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                          fontSize: 14,
                          color: IceColors.text)),
                ),
                if (!isRead)
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: IceColors.navyDeep, shape: BoxShape.circle)),
              ]),
              if (message.isNotEmpty && message != title) ...[
                const SizedBox(height: 4),
                Text(message,
                    style: const TextStyle(fontSize: 13, color: IceColors.muted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
              if (date.length >= 10) ...[
                const SizedBox(height: 6),
                Text(date.substring(0, 10),
                    style: const TextStyle(fontSize: 11, color: IceColors.muted)),
              ],
            ]),
          ),
        ]),
      ),
    )
        .animate(delay: Duration(milliseconds: 200 + idx * 60))
        .slideX(begin: 0.06, duration: 350.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────
class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const SizedBox(height: 16),
            ...List.generate(
              5,
              (_) => Container(
                height: 80,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ]),
        ),
      );
}

class _ErrCard extends StatelessWidget {
  final String msg;
  const _ErrCard(this.msg);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Error: $msg', style: const TextStyle(color: IceColors.danger)),
      );
}

// Legacy, not used
class StaffMoreScreen2 extends StatelessWidget {
  const StaffMoreScreen2({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
