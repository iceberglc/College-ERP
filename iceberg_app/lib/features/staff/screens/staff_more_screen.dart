import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class StaffMoreScreen extends StatelessWidget {
  const StaffMoreScreen({super.key});

  static const _tiles = [
    _MoreTile(icon: Icons.grade_rounded,           label: 'Results',      path: '/staff/results'),
    _MoreTile(icon: Icons.assignment_rounded,       label: 'Assignments',  path: '/staff/assignments'),
    _MoreTile(icon: Icons.menu_book_rounded,        label: 'Vocabulary',   path: '/staff/vocabulary'),
    _MoreTile(icon: Icons.beach_access_rounded,     label: 'Leave',        path: '/staff/leave'),
    _MoreTile(icon: Icons.rate_review_rounded,      label: 'Feedback',     path: '/staff/feedback'),
    _MoreTile(icon: Icons.payment_rounded,          label: 'Payments',     path: '/staff/payments'),
    _MoreTile(icon: Icons.notifications_rounded,    label: 'Notifications',path: '/staff/notifications'),
    _MoreTile(icon: Icons.person_rounded,           label: 'Profile',      path: '/staff/profile'),
    _MoreTile(icon: Icons.logout_rounded,           label: 'Logout',       path: '/login', isLogout: true),
  ];

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final cols = MediaQuery.of(context).size.width >= 600 ? 3 : 2;

    return Scaffold(
      backgroundColor: IceColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, top + 20, 20, 28),
            decoration: const BoxDecoration(
              gradient: kHeroGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('More',
                  style: TextStyle(
                      color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900))
                  .animate().slideX(begin: -0.1, duration: 400.ms).fadeIn(duration: 300.ms),
              const SizedBox(height: 4),
              Text('All teacher tools and settings',
                  style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 13))
                  .animate(delay: 80.ms).fadeIn(),
            ]),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemCount: _tiles.length,
              itemBuilder: (context, i) => _MoreTileWidget(_tiles[i], i),
            ),
          ),
        ],
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
  final int index;
  const _MoreTileWidget(this.tile, this.index);

  @override
  Widget build(BuildContext context) {
    final iconColor = tile.isLogout ? IceColors.danger : IceColors.navyDeep;
    final bgColor = tile.isLogout ? IceColors.danger.withAlpha(20) : IceColors.surface2;

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
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
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
    )
        .animate(delay: Duration(milliseconds: 40 * index))
        .fadeIn(duration: 220.ms)
        .scale(begin: const Offset(0.92, 0.92), duration: 220.ms, curve: Curves.easeOut);
  }
}
