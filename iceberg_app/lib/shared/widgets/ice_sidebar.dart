import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_state.dart';
import '../../core/theme/app_theme.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class SidebarItem {
  final IconData icon;
  final String label;
  final String path;
  const SidebarItem({
    required this.icon,
    required this.label,
    required this.path,
  });
}

class SidebarSection {
  final String title;
  final List<SidebarItem> items;
  const SidebarSection({required this.title, required this.items});
}

// ─── IceSidebar ──────────────────────────────────────────────────────────────
/// Desktop sidebar that mirrors the deployed Django web version
/// (`erpnext_sidebar.html` + `erpnext-style.css`):
///   white 256px surface, user header with round avatar, uppercase section
///   titles, nav links with a 3px left accent + tinted background when
///   active — but with smoother Flutter-native hover/selection animations.
class IceSidebar extends ConsumerWidget {
  final List<SidebarSection> sections;
  const IceSidebar({super.key, required this.sections});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final currentPath = GoRouterState.of(context).uri.path;

    final name = user == null
        ? ''
        : (user.fullName.isEmpty ? user.loginId : user.fullName);
    final role = user == null
        ? ''
        : user.isSuperAdmin
        ? 'Super Admin'
        : user.isAdmin
        ? 'Admin'
        : user.isStaff
        ? 'Teacher'
        : 'Student';
    final initials = _initials(name);

    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: IceColors.surface,
        border: Border(right: BorderSide(color: IceColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── User header (mirrors .sidebar-header) ─────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: IceColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [IceColors.navy, IceColors.navyDeep],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: IceColors.navyDeep.withAlpha(120),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: IceColors.text,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        role,
                        style: const TextStyle(
                          color: IceColors.muted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Nav sections ───────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              children: [
                for (final section in sections) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Text(
                      section.title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.3,
                        color: IceColors.muted,
                      ),
                    ),
                  ),
                  for (final item in section.items)
                    _SidebarLink(
                      item: item,
                      active: _isActive(currentPath, item.path),
                    ),
                ],
              ],
            ),
          ),

          // ── Logout footer ──────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: IceColors.border)),
            ),
            child: _SidebarLink(
              item: const SidebarItem(
                icon: Icons.logout_rounded,
                label: 'Sign out',
                path: '__logout__',
              ),
              active: false,
              onTap: () => _confirmLogout(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  // Exact match wins; otherwise longest-prefix match so `/admin/groups/add`
  // highlights "Groups" but `/admin/home` doesn't highlight everything.
  bool _isActive(String currentPath, String itemPath) {
    if (currentPath == itemPath) return true;
    return currentPath.startsWith('$itemPath/');
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Sign out?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('You will need to log in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: IceColors.navyDeep),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}

// ─── Nav link (mirrors .nav-link / .nav-link.active) ────────────────────────
class _SidebarLink extends StatefulWidget {
  final SidebarItem item;
  final bool active;
  final VoidCallback? onTap;
  const _SidebarLink({required this.item, required this.active, this.onTap});

  @override
  State<_SidebarLink> createState() => _SidebarLinkState();
}

class _SidebarLinkState extends State<_SidebarLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final accent = IceColors.navyDeep;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap ?? () => context.go(widget.item.path),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: active
                ? accent.withAlpha(26)
                : _hover
                ? IceColors.surface2
                : Colors.transparent,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: Border(
              left: BorderSide(
                color: active ? accent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: Icon(
                  widget.item.icon,
                  size: 16,
                  color: active
                      ? accent
                      : IceColors.muted.withAlpha(_hover ? 255 : 190),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: IceColors.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── DesktopPageShell ────────────────────────────────────────────────────────
/// Wraps standalone (non-tab) routes so the sidebar persists on desktop.
/// On mobile (<768px) the child renders alone, exactly as before.
class DesktopPageShell extends StatelessWidget {
  final List<SidebarSection> sections;
  final Widget child;
  const DesktopPageShell({
    super.key,
    required this.sections,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 768) return child;
    return Scaffold(
      backgroundColor: IceColors.bg,
      body: Row(
        children: [
          IceSidebar(sections: sections),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
