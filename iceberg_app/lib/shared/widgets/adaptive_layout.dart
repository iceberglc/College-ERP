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
/// Three-tier responsive layout:
/// - Phone  (<  600px): floating pill bottom nav (compact, icons-only when 6+)
/// - Tablet (600-1199px): floating pill bottom nav (all items with labels)
/// - Desktop (≥ 1200px): persistent 256px sidebar + content column
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
    if (width >= 1200) {
      return _DesktopLayout(
        navigationShell: navigationShell,
        sections: sections,
      );
    }
    // Both phone and tablet use bottom nav; tablet shows all items.
    return _MobileLayout(
      navigationShell: navigationShell,
      items: items,
      isTablet: width >= 600,
    );
  }
}

// ─── Mobile/Tablet layout ────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<IceNavItem> items;
  final bool isTablet;

  const _MobileLayout({
    required this.navigationShell,
    required this.items,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _FloatingBottomNav(
        selectedIndex: navigationShell.currentIndex,
        items: items,
        isTablet: isTablet,
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
  final bool isTablet;
  final ValueChanged<int> onTap;

  const _FloatingBottomNav({
    required this.selectedIndex,
    required this.items,
    required this.isTablet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // On phones with 6 items, hide labels to keep items compact.
    final hideLabels = !isTablet && items.length >= 6;

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 24 : 16,
            6,
            isTablet ? 24 : 16,
            10,
          ),
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
                  padding: EdgeInsets.symmetric(
                    vertical: hideLabels ? 10 : 10,
                    horizontal: isTablet ? 12 : 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(items.length, (i) {
                      return Expanded(
                        child: _NavItem(
                          item: items[i],
                          selected: i == selectedIndex,
                          hideLabel: hideLabels,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTap(i);
                          },
                        ),
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

class _NavItem extends StatelessWidget {
  final IceNavItem item;
  final bool selected;
  final bool hideLabel;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.selected,
    required this.hideLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: hideLabel ? 6 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? IceColors.lime.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                size: hideLabel ? 22 : 22,
                color: selected
                    ? IceColors.lime
                    : Colors.white.withAlpha(160),
              ),
            ),
            if (!hideLabel) ...[
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? IceColors.lime
                      : Colors.white.withAlpha(120),
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Desktop layout ──────────────────────────────────────────────────────────
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
