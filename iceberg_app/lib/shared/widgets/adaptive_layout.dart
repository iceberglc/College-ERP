import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'ice_sidebar.dart';

// ─── Nav item model ──────────────────────────────────────────────────────────
class IceNavItem {
  final IconData icon;
  final String label;
  final String path;

  const IceNavItem({
    required this.icon,
    required this.label,
    required this.path,
  });
}

// ─── AdaptiveLayout shell ────────────────────────────────────────────────────
/// Renders differently based on screen width:
/// - Mobile  (< 768px): Scaffold + pill-shaped glassmorphic bottom nav
/// - Desktop (>= 768px): persistent 256px Django-style sidebar + content
class AdaptiveLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<IceNavItem> items;
  final List<SidebarSection> sections;

  const AdaptiveLayout({
    super.key,
    required this.navigationShell,
    required this.items,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 768) {
      return _DesktopLayout(
        navigationShell: navigationShell,
        sections: sections,
      );
    }
    return _MobileLayout(
      navigationShell: navigationShell,
      items: items,
    );
  }
}

// ─── Mobile layout ───────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<IceNavItem> items;

  const _MobileLayout({
    required this.navigationShell,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _FloatingBottomNav(
        selectedIndex: navigationShell.currentIndex,
        items: items,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _FloatingBottomNav extends StatelessWidget {
  final int selectedIndex;
  final List<IceNavItem> items;
  final ValueChanged<int> onTap;

  const _FloatingBottomNav({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: IceColors.navy.withAlpha(230),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withAlpha(30),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: IceColors.navy.withAlpha(80),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(items.length, (i) {
                      return _MobileNavItem(
                        item: items[i],
                        selected: i == selectedIndex,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onTap(i);
                        },
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  final IceNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _MobileNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? IceColors.lime.withAlpha(30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with lime glow when active
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: selected
                  ? BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: IceColors.lime.withAlpha(120),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    )
                  : null,
              child: Icon(
                item.icon,
                size: 22,
                color: selected ? IceColors.lime : Colors.white.withAlpha(160),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 9,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                color:
                    selected ? IceColors.lime : Colors.white.withAlpha(120),
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Desktop layout ──────────────────────────────────────────────────────────
/// Mirrors the deployed Django web layout: white 256px sidebar
/// (`IceSidebar`) + centered content column.
class _DesktopLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<SidebarSection> sections;

  const _DesktopLayout({
    required this.navigationShell,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IceColors.bg,
      body: Row(
        children: [
          IceSidebar(sections: sections),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: navigationShell,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
