import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/role_nav.dart';
import '../../../shared/widgets/adaptive_layout.dart';

class AdminShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AdminShell({super.key, required this.navigationShell});

  static const _items = [
    IceNavItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      path: '/admin/home',
    ),
    IceNavItem(
      icon: Icons.people_rounded,
      label: 'People',
      path: '/admin/students',
    ),
    IceNavItem(
      icon: Icons.manage_accounts_rounded,
      label: 'Manage',
      path: '/admin/manage',
    ),
    IceNavItem(
      icon: Icons.grid_view_rounded,
      label: 'More',
      path: '/admin/more',
    ),
  ];

  @override
  Widget build(BuildContext context) => AdaptiveLayout(
    navigationShell: navigationShell,
    items: _items,
    sections: adminSidebarSections,
  );
}
