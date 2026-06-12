import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  static const _tiles = [
    _MoreTile(
      icon: Icons.people_rounded,
      label: 'Students',
      path: '/admin/students',
    ),
    _MoreTile(icon: Icons.badge_rounded, label: 'Staff', path: '/admin/staff'),
    _MoreTile(
      icon: Icons.group_work_rounded,
      label: 'Groups',
      path: '/admin/groups',
    ),
    _MoreTile(
      icon: Icons.menu_book_rounded,
      label: 'Courses',
      path: '/admin/courses',
    ),
    _MoreTile(
      icon: Icons.account_tree_rounded,
      label: 'Branches',
      path: '/admin/branches',
    ),
    _MoreTile(
      icon: Icons.calendar_month_rounded,
      label: 'Sessions',
      path: '/admin/sessions',
    ),
    _MoreTile(
      icon: Icons.subject_rounded,
      label: 'Subjects',
      path: '/admin/subjects',
    ),
    _MoreTile(
      icon: Icons.payment_rounded,
      label: 'Payments',
      path: '/admin/payments',
    ),
    _MoreTile(
      icon: Icons.contacts_rounded,
      label: 'Leads',
      path: '/admin/leads',
    ),
    _MoreTile(
      icon: Icons.fact_check_rounded,
      label: 'Attendance',
      path: '/admin/attendance',
    ),
    _MoreTile(
      icon: Icons.beach_access_rounded,
      label: 'Leave',
      path: '/admin/leave',
    ),
    _MoreTile(
      icon: Icons.notifications_rounded,
      label: 'Notifications',
      path: '/admin/notify',
    ),
    _MoreTile(
      icon: Icons.auto_stories_rounded,
      label: 'Stories',
      path: '/admin/stories',
    ),
    _MoreTile(
      icon: Icons.person_rounded,
      label: 'Profile',
      path: '/admin/profile',
    ),
    _MoreTile(
      icon: Icons.logout_rounded,
      label: 'Logout',
      path: '/login',
      isLogout: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 600 ? 3 : 2;

    return Scaffold(
      backgroundColor: IceColors.bg,
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: IceColors.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemCount: _tiles.length,
          itemBuilder: (context, i) => _MoreTileWidget(_tiles[i]),
        ),
      ),
    );
  }
}

class _MoreTile {
  final IconData icon;
  final String label;
  final String path;
  final bool isLogout;
  const _MoreTile({
    required this.icon,
    required this.label,
    required this.path,
    this.isLogout = false,
  });
}

class _MoreTileWidget extends StatelessWidget {
  final _MoreTile tile;
  const _MoreTileWidget(this.tile);

  @override
  Widget build(BuildContext context) {
    final iconColor = tile.isLogout ? IceColors.danger : IceColors.navyDeep;
    final bgColor = tile.isLogout
        ? IceColors.danger.withAlpha(20)
        : IceColors.surface2;

    return Material(
      color: IceColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go(tile.path),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: IceColors.border, width: 1.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(tile.icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  tile.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tile.isLogout ? IceColors.danger : IceColors.text,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
