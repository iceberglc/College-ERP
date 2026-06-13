import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/ice_tokens.dart';
import '../../../shared/widgets/ice_kit.dart';
import '../../../shared/widgets/ice_shell.dart';

class StaffNotificationsScreen extends ConsumerWidget {
  const StaffNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final async = ref.watch(notificationsProvider);

    return async.when(
      loading: () => IcePage(
        title: s('Notifications'),
        backButton: true,
        children: const [PageSkeleton()],
      ),
      error: (e, _) => IcePage(
        title: s('Notifications'),
        backButton: true,
        children: [
          ErrorState(
            error: e,
            onRetry: () => ref.invalidate(notificationsProvider),
          ),
        ],
      ),
      data: (list) => IcePage(
        title: s('Notifications'),
        backButton: true,
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          await ApiClient.instance.dio.post('/notifications/mark-all-read/');
        },
        children: list.isEmpty
            ? [
                EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: s('No notifications'),
                ),
              ]
            : [
                for (final n in list) _NotifCard(item: n),
              ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final dynamic item;
  const _NotifCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = context.ice;
    final read = item['is_read'] as bool? ?? false;
    return IceCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5, right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: read ? Colors.transparent : t.accent,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['message'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        read ? FontWeight.w500 : FontWeight.w700,
                    color: t.textHi,
                  ),
                ),
                if (item['created_at'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item['created_at'].toString().substring(0, 10),
                      style: TextStyle(fontSize: 12, color: t.textMid),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
