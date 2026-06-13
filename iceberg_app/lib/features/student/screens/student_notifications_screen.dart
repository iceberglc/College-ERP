import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/theme/ice_tokens.dart';
import '../../../shared/widgets/ice_kit.dart';
import '../../../shared/widgets/ice_shell.dart';

/// Notifications — All / Unread / Announcements with mark-read actions and
/// deep links into the related screen.
class StudentNotificationsScreen extends ConsumerStatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  ConsumerState<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends ConsumerState<StudentNotificationsScreen> {
  int _tab = 0;
  bool _markingAll = false;

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);

    return notifications.when(
      loading: () => const PageSkeleton(),
      error: (e, _) => ErrorState(
        error: e,
        onRetry: () => ref.invalidate(notificationsProvider),
      ),
      data: (list) => _buildBody(context, list),
    );
  }

  Widget _buildBody(BuildContext context, List list) {
    final visible = switch (_tab) {
      1 => list.where((n) => n['is_read'] != true).toList(),
      2 => list.where((n) => n['category'] == 'announcement').toList(),
      _ => list,
    };
    final hasUnread = list.any((n) => n['is_read'] != true);

    return IcePage(
      title: 'Notifications',
      onRefresh: () async => ref.refresh(notificationsProvider.future),
      action: hasUnread
          ? GestureDetector(
              onTap: _markingAll ? null : _markAllRead,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.ice.inset,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: _markingAll
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.ice.accent,
                        ),
                      )
                    : Text(
                        'Read all',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: context.ice.accent,
                        ),
                      ),
              ),
            )
          : null,
      children: [
        IceChipTabs(
          tabs: const ['All', 'Unread', 'Announcements'],
          index: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: 16),
        if (list.isEmpty)
          const IceCard(
            child: EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'You\'re all caught up',
              message: 'New notifications will show up here.',
            ),
          )
        else if (visible.isEmpty)
          IceCard(
            child: EmptyState(
              icon: Icons.done_all_rounded,
              title: _tab == 1 ? 'No unread notifications' : 'Nothing here',
            ),
          )
        else
          ...visible.map(
            (n) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NotificationCard(
                n: n as Map<String, dynamic>,
                onTap: () => _onTap(n),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    try {
      await ApiClient.instance.dio.post('/notifications/mark-all-read/');
      ref.invalidate(notificationsProvider);
      ref.invalidate(studentDashProvider);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _onTap(Map n) async {
    if (n['is_read'] != true) {
      try {
        await ApiClient.instance.dio.post('/notifications/${n['id']}/read/');
        ref.invalidate(notificationsProvider);
        ref.invalidate(studentDashProvider);
      } catch (_) {}
    }
    if (!mounted) return;
    // Deep link by category.
    final route = switch (n['category']) {
      'attendance' => '/student/attendance',
      'result' => '/student/results',
      'homework' => '/student/assignments',
      'vocabulary' => '/student/vocabulary',
      'payment' => '/student/payments',
      _ => null,
    };
    if (route != null) context.go(route);
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> n;
  final VoidCallback onTap;
  const _NotificationCard({required this.n, required this.onTap});

  (IconData, Color) _visual(BuildContext context) {
    final t = context.ice;
    return switch (n['category']) {
      'attendance' => (Icons.event_available_rounded, t.coral),
      'result' => (Icons.workspace_premium_rounded, t.sky),
      'announcement' => (Icons.campaign_rounded, t.mint),
      'homework' => (Icons.assignment_rounded, t.amber),
      'vocabulary' => (Icons.translate_rounded, t.accent),
      'payment' => (Icons.payments_rounded, t.coral),
      _ => (Icons.notifications_rounded, t.textMid),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ice;
    final (icon, color) = _visual(context);
    final unread = n['is_read'] != true;
    final created = DateTime.tryParse(n['created_at'] ?? '');

    return IceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      color: unread ? null : t.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _title(n['category']),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: t.textHi,
                        ),
                      ),
                    ),
                    if (created != null)
                      Text(
                        _relative(created),
                        style: TextStyle(fontSize: 11, color: t.textLow),
                      ),
                    if (unread) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: t.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  n['message'] ?? '',
                  style: TextStyle(fontSize: 13, color: t.textMid, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _title(dynamic c) => switch (c) {
    'attendance' => 'Attendance update',
    'result' => 'Result published',
    'announcement' => 'Announcement',
    'homework' => 'Assignment',
    'vocabulary' => 'Vocabulary released',
    'payment' => 'Payment',
    _ => 'Notification',
  };

  String _relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}
