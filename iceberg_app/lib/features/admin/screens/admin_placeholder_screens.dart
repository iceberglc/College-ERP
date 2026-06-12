import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/ice_page_header.dart';

// Re-export fully-implemented screens so the router's single import still
// resolves all class names without modification.
export 'admin_courses_screen.dart';
export 'admin_branches_screen.dart';
export 'admin_sessions_screen.dart';
export 'admin_subjects_screen.dart';
export 'admin_payments_screen.dart';
export 'admin_attendance_screen.dart';
export 'admin_stories_screen.dart';
export 'admin_notify_screen.dart';
export 'admin_leave_screen.dart';

class AdminManageHubScreen extends StatelessWidget {
  const AdminManageHubScreen({super.key});

  static const _sections = [
    _AdminManageSection(
      title: 'Academic Setup',
      items: [
        _AdminManageItem(Icons.group_work_rounded, 'Groups', '/admin/groups'),
        _AdminManageItem(
          Icons.person_add_alt_1_rounded,
          'Enroll Student',
          '/admin/enroll',
        ),
        _AdminManageItem(Icons.menu_book_rounded, 'Courses', '/admin/courses'),
        _AdminManageItem(Icons.subject_rounded, 'Subjects', '/admin/subjects'),
        _AdminManageItem(
          Icons.calendar_month_rounded,
          'Sessions',
          '/admin/sessions',
        ),
        _AdminManageItem(
          Icons.account_tree_rounded,
          'Branches',
          '/admin/branches',
        ),
      ],
    ),
    _AdminManageSection(
      title: 'People',
      items: [
        _AdminManageItem(Icons.people_rounded, 'Students', '/admin/students'),
        _AdminManageItem(Icons.badge_rounded, 'Staff', '/admin/staff'),
        _AdminManageItem(
          Icons.admin_panel_settings_rounded,
          'Admins',
          '/admin/admins',
        ),
        _AdminManageItem(
          Icons.contacts_rounded,
          'Registration Leads',
          '/admin/leads',
        ),
      ],
    ),
    _AdminManageSection(
      title: 'Operations',
      items: [
        _AdminManageItem(Icons.payment_rounded, 'Payments', '/admin/payments'),
        _AdminManageItem(
          Icons.fact_check_rounded,
          'Attendance',
          '/admin/attendance',
        ),
        _AdminManageItem(
          Icons.beach_access_rounded,
          'Leave Requests',
          '/admin/leave',
        ),
        _AdminManageItem(
          Icons.auto_stories_rounded,
          'Stories',
          '/admin/stories',
        ),
        _AdminManageItem(
          Icons.notifications_active_rounded,
          'Send Notification',
          '/admin/notify',
        ),
        _AdminManageItem(Icons.chat_rounded, 'Messages', '/admin/messages'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: IceColors.bg,
    body: CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: IcePageHeader(
            title: 'Manage',
            subtitle: 'Academic setup, users, payments, and communication',
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _AdminManageSectionCard(section: _sections[index]),
              childCount: _sections.length,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AdminManageSectionCard extends StatelessWidget {
  final _AdminManageSection section;
  const _AdminManageSectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IceColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: IceColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: IceColors.text,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final columns = c.maxWidth >= 780
                  ? 3
                  : c.maxWidth >= 520
                  ? 2
                  : 1;
              final width = (c.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final item in section.items)
                    SizedBox(
                      width: width,
                      child: _AdminManageTile(item: item),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminManageTile extends StatelessWidget {
  final _AdminManageItem item;
  const _AdminManageTile({required this.item});

  @override
  Widget build(BuildContext context) => Material(
    color: IceColors.surface2,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.go(item.path),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: IceColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: IceColors.navyDeep.withAlpha(14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(item.icon, size: 19, color: IceColors.navyDeep),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                item.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: IceColors.text,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: IceColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}

class _AdminManageSection {
  final String title;
  final List<_AdminManageItem> items;
  const _AdminManageSection({required this.title, required this.items});
}

class _AdminManageItem {
  final IconData icon;
  final String label;
  final String path;
  const _AdminManageItem(this.icon, this.label, this.path);
}
