import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/role_nav.dart';
import '../../../shared/widgets/adaptive_layout.dart';

class SuperadminShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const SuperadminShell({super.key, required this.navigationShell});

  static const _items = [
    IceNavItem(
      icon: Icons.bar_chart_rounded,
      label: 'Overview',
      path: '/superadmin/home',
    ),
    IceNavItem(
      icon: Icons.account_tree_rounded,
      label: 'Branches',
      path: '/superadmin/branches',
    ),
    IceNavItem(
      icon: Icons.analytics_rounded,
      label: 'Analytics',
      path: '/superadmin/analytics',
    ),
    IceNavItem(
      icon: Icons.grid_view_rounded,
      label: 'More',
      path: '/superadmin/more',
    ),
  ];

  @override
  Widget build(BuildContext context) => AdaptiveLayout(
    navigationShell: navigationShell,
    items: _items,
    sections: superadminSidebarSections,
  );
}
