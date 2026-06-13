import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/role_nav.dart';
import '../../../shared/widgets/adaptive_layout.dart';

class AdminShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AdminShell({super.key, required this.navigationShell});

  static const _items = [
    IceNavItem(icon: Icons.dashboard_rounded,  label: 'Dashboard', path: '/admin/home'),
    IceNavItem(icon: Icons.people_rounded,      label: 'Students',  path: '/admin/students'),
    IceNavItem(icon: Icons.group_work_rounded,  label: 'Groups',    path: '/admin/groups'),
    IceNavItem(icon: Icons.payment_rounded,     label: 'Payments',  path: '/admin/payments'),
    IceNavItem(icon: Icons.contacts_rounded,    label: 'Leads',     path: '/admin/leads'),
    IceNavItem(icon: Icons.grid_view_rounded,   label: 'More',      path: '/admin/more'),
  ];

  @override
  Widget build(BuildContext context) => AdaptiveLayout(
        navigationShell: navigationShell,
        items: _items,
        sections: adminSidebarSections,
      );
}
