import 'package:flutter/material.dart';
import '../../shared/widgets/ice_sidebar.dart';

/// Desktop sidebar menus per role. Grouping mirrors the deployed Django
/// sidebar (`erpnext_sidebar.html`): Overview → People → Academic →
/// Finance → Communication.

const adminSidebarSections = [
  SidebarSection(title: 'Overview', items: [
    SidebarItem(
        icon: Icons.dashboard_rounded, label: 'Dashboard', path: '/admin/home'),
    SidebarItem(
        icon: Icons.account_circle_rounded,
        label: 'Profile & Settings',
        path: '/admin/profile'),
  ]),
  SidebarSection(title: 'People', items: [
    SidebarItem(
        icon: Icons.school_rounded, label: 'Students', path: '/admin/students'),
    SidebarItem(
        icon: Icons.co_present_rounded, label: 'Teachers', path: '/admin/staff'),
    SidebarItem(
        icon: Icons.admin_panel_settings_rounded,
        label: 'Admins',
        path: '/admin/admins'),
    SidebarItem(
        icon: Icons.person_add_alt_rounded,
        label: 'Registration Leads',
        path: '/admin/leads'),
  ]),
  SidebarSection(title: 'Academic', items: [
    SidebarItem(
        icon: Icons.groups_rounded, label: 'Groups', path: '/admin/groups'),
    SidebarItem(
        icon: Icons.how_to_reg_rounded,
        label: 'Enroll Student',
        path: '/admin/enroll'),
    SidebarItem(
        icon: Icons.menu_book_rounded, label: 'Courses', path: '/admin/courses'),
    SidebarItem(
        icon: Icons.category_rounded, label: 'Subjects', path: '/admin/subjects'),
    SidebarItem(
        icon: Icons.calendar_month_rounded,
        label: 'Sessions',
        path: '/admin/sessions'),
    SidebarItem(
        icon: Icons.business_rounded, label: 'Branches', path: '/admin/branches'),
    SidebarItem(
        icon: Icons.fact_check_rounded,
        label: 'Attendance',
        path: '/admin/attendance'),
  ]),
  SidebarSection(title: 'Finance', items: [
    SidebarItem(
        icon: Icons.payments_rounded, label: 'Payments', path: '/admin/payments'),
  ]),
  SidebarSection(title: 'Communication', items: [
    SidebarItem(
        icon: Icons.chat_rounded, label: 'Messages', path: '/admin/messages'),
    SidebarItem(
        icon: Icons.auto_stories_rounded, label: 'Stories', path: '/admin/stories'),
    SidebarItem(
        icon: Icons.notifications_active_rounded,
        label: 'Send Notification',
        path: '/admin/notify'),
    SidebarItem(
        icon: Icons.event_busy_rounded,
        label: 'Leave Requests',
        path: '/admin/leave'),
  ]),
];

const staffSidebarSections = [
  SidebarSection(title: 'Overview', items: [
    SidebarItem(
        icon: Icons.dashboard_rounded, label: 'Dashboard', path: '/staff/home'),
    SidebarItem(
        icon: Icons.account_circle_rounded,
        label: 'Profile & Settings',
        path: '/staff/profile'),
  ]),
  SidebarSection(title: 'Teaching', items: [
    SidebarItem(
        icon: Icons.groups_rounded, label: 'My Classes', path: '/staff/classes'),
    SidebarItem(
        icon: Icons.fact_check_rounded,
        label: 'Take Attendance',
        path: '/staff/attendance'),
    SidebarItem(
        icon: Icons.grading_rounded, label: 'Results', path: '/staff/results'),
    SidebarItem(
        icon: Icons.assignment_rounded,
        label: 'Assignments',
        path: '/staff/assignments'),
    SidebarItem(
        icon: Icons.translate_rounded,
        label: 'Vocabulary',
        path: '/staff/vocabulary'),
  ]),
  SidebarSection(title: 'Personal', items: [
    SidebarItem(
        icon: Icons.chat_rounded, label: 'Messages', path: '/staff/messages'),
    SidebarItem(
        icon: Icons.event_busy_rounded, label: 'Apply Leave', path: '/staff/leave'),
    SidebarItem(
        icon: Icons.feedback_rounded, label: 'Feedback', path: '/staff/feedback'),
    SidebarItem(
        icon: Icons.notifications_rounded,
        label: 'Notifications',
        path: '/staff/notifications'),
  ]),
];

const studentSidebarSections = [
  SidebarSection(title: 'Overview', items: [
    SidebarItem(
        icon: Icons.dashboard_rounded, label: 'Home', path: '/student/home'),
    SidebarItem(
        icon: Icons.account_circle_rounded,
        label: 'Profile & Settings',
        path: '/student/profile'),
  ]),
  SidebarSection(title: 'Learning', items: [
    SidebarItem(
        icon: Icons.translate_rounded,
        label: 'Vocabulary',
        path: '/student/vocabulary'),
    SidebarItem(
        icon: Icons.trending_up_rounded,
        label: 'My Progress',
        path: '/student/progress'),
    SidebarItem(
        icon: Icons.fact_check_rounded,
        label: 'Attendance',
        path: '/student/attendance'),
    SidebarItem(
        icon: Icons.grading_rounded, label: 'Results', path: '/student/results'),
    SidebarItem(
        icon: Icons.assignment_rounded,
        label: 'Assignments',
        path: '/student/assignments'),
    SidebarItem(
        icon: Icons.emoji_events_rounded,
        label: 'Leaderboard',
        path: '/student/leaderboard'),
    SidebarItem(
        icon: Icons.menu_book_rounded, label: 'Books', path: '/student/books'),
  ]),
  SidebarSection(title: 'Personal', items: [
    SidebarItem(
        icon: Icons.chat_rounded, label: 'Messages', path: '/student/messages'),
    SidebarItem(
        icon: Icons.payments_rounded,
        label: 'Payments',
        path: '/student/payments'),
    SidebarItem(
        icon: Icons.event_busy_rounded,
        label: 'Apply Leave',
        path: '/student/leave'),
    SidebarItem(
        icon: Icons.feedback_rounded,
        label: 'Feedback',
        path: '/student/feedback'),
    SidebarItem(
        icon: Icons.notifications_rounded,
        label: 'Notifications',
        path: '/student/notifications'),
  ]),
];

const superadminSidebarSections = [
  SidebarSection(title: 'Overview', items: [
    SidebarItem(
        icon: Icons.dashboard_rounded,
        label: 'Dashboard',
        path: '/superadmin/home'),
    SidebarItem(
        icon: Icons.account_circle_rounded,
        label: 'Profile & Settings',
        path: '/superadmin/profile'),
  ]),
  SidebarSection(title: 'Network', items: [
    SidebarItem(
        icon: Icons.business_rounded,
        label: 'Branches',
        path: '/superadmin/branches'),
    SidebarItem(
        icon: Icons.insights_rounded,
        label: 'Analytics',
        path: '/superadmin/analytics'),
  ]),
  SidebarSection(title: 'People', items: [
    SidebarItem(
        icon: Icons.school_rounded,
        label: 'Students',
        path: '/superadmin/students'),
    SidebarItem(
        icon: Icons.co_present_rounded,
        label: 'Teachers',
        path: '/superadmin/staff'),
    SidebarItem(
        icon: Icons.person_add_alt_rounded,
        label: 'Registration Leads',
        path: '/superadmin/leads'),
  ]),
  SidebarSection(title: 'More', items: [
    SidebarItem(
        icon: Icons.notifications_rounded,
        label: 'Notifications',
        path: '/superadmin/notifications'),
    SidebarItem(
        icon: Icons.grid_view_rounded, label: 'More', path: '/superadmin/more'),
  ]),
];
