import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/role_nav.dart';
import '../../../shared/widgets/adaptive_layout.dart';

class StudentShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const StudentShell({super.key, required this.navigationShell});

  static const _items = [
    IceNavItem(
      icon: Icons.home_rounded,
      label: 'Home',
      path: '/student/home',
    ),
    IceNavItem(
      icon: Icons.menu_book_rounded,
      label: 'Learn',
      path: '/student/vocabulary',
    ),
    IceNavItem(
      icon: Icons.insights_rounded,
      label: 'Progress',
      path: '/student/progress',
    ),
    IceNavItem(
      icon: Icons.grid_view_rounded,
      label: 'More',
      path: '/student/more',
    ),
  ];

  @override
  Widget build(BuildContext context) => AdaptiveLayout(
        navigationShell: navigationShell,
        items: _items,
        sections: studentSidebarSections,
      );
}
