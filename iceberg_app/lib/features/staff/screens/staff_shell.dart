import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/role_nav.dart';
import '../../../shared/widgets/adaptive_layout.dart';

class StaffShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const StaffShell({super.key, required this.navigationShell});

  static const _items = [
    IceNavItem(
      icon: Icons.home_rounded,
      label: 'Dashboard',
      path: '/staff/home',
    ),
    IceNavItem(
      icon: Icons.class_rounded,
      label: 'Classes',
      path: '/staff/classes',
    ),
    IceNavItem(
      icon: Icons.fact_check_rounded,
      label: 'Attendance',
      path: '/staff/attendance',
    ),
    IceNavItem(
      icon: Icons.grid_view_rounded,
      label: 'More',
      path: '/staff/more',
    ),
  ];

  @override
  Widget build(BuildContext context) => AdaptiveLayout(
    navigationShell: navigationShell,
    items: _items,
    sections: staffSidebarSections,
  );
}
