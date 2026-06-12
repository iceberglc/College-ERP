import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/ice_page_header.dart';

class AdminLeadsScreen extends ConsumerWidget {
  const AdminLeadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(adminLeadsProvider);

    return Scaffold(
      backgroundColor: IceColors.bg,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminLeadsProvider.future),
        color: IceColors.navyDeep,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: IcePageHeader(
                title: 'Leads',
                subtitle: 'Prospective students and inquiries',
                avatar: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withAlpha(30)),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.contacts_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
            data.when(
              loading: () => const SliverToBoxAdapter(child: _Skeleton()),
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
                            color: IceColors.warning.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.contacts_outlined,
                              size: 32, color: IceColors.warning),
                        ),
                        const SizedBox(height: 16),
                        const Text('No leads yet.',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: IceColors.text)),
                      ]),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      if (i == 0) return const SizedBox(height: 16);
                      if (i == list.length + 1) return const SizedBox(height: 80);
                      return _LeadCard(lead: list[i - 1], index: i - 1);
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

class _LeadCard extends StatelessWidget {
  final dynamic lead;
  final int index;
  const _LeadCard({required this.lead, required this.index});

  @override
  Widget build(BuildContext context) {
    final name   = lead['name']?.toString() ?? lead['full_name']?.toString() ?? '—';
    final phone  = lead['phone']?.toString();
    final date   = lead['created_at']?.toString();
    final status = lead['status']?.toString() ?? 'new';
    final statusColor = status == 'enrolled'
        ? IceColors.success
        : status == 'contacted'
            ? IceColors.info
            : IceColors.warning;
    final statusLabel =
        status[0].toUpperCase() + status.substring(1);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IceColors.border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: statusColor.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: statusColor),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            if (phone != null) ...[
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.phone_outlined, size: 12, color: IceColors.muted),
                const SizedBox(width: 4),
                Text(phone,
                    style: const TextStyle(
                        fontSize: 12, color: IceColors.muted)),
              ]),
            ],
            if (date != null) ...[
              const SizedBox(height: 2),
              Text(fmtDate(date),
                  style: const TextStyle(
                      fontSize: 11, color: IceColors.muted)),
            ],
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(statusLabel,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor)),
        ),
      ]),
    )
        .animate(delay: Duration(milliseconds: 200 + index * 50))
        .slideX(begin: 0.08, duration: 350.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(children: List.generate(
            5,
            (_) => Container(
              height: 80,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
            ),
          )),
        ),
      );
}
