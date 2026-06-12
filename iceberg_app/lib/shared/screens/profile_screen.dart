import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_state.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: CircularProgressIndicator(color: IceColors.navyDeep)),
      );
    }

    final initials = _initials(user);
    final roleLabel = user.isAdmin
        ? 'Administrator'
        : user.isStaff
            ? "O'qituvchi / Xodim"
            : 'Talaba';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Profile top section ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.paddingOf(context).top + 28, 20, 24),
              child: Column(
                children: [
                  // Lime avatar circle 72px
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: IceColors.lime,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: IceColors.navy,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 14),

                  Text(
                    user.fullName.isEmpty ? user.loginId : user.fullName,
                    style: const TextStyle(
                      color: IceColors.navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate(delay: 80.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1, duration: 300.ms),

                  const SizedBox(height: 6),

                  Text(
                    '${user.loginId}  ·  $roleLabel',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: IceColors.muted,
                    ),
                  )
                      .animate(delay: 140.ms)
                      .fadeIn(duration: 300.ms),
                ],
              ),
            ),
          ),

          // ── Menu items ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.person_outline_rounded,
                    iconBg: const Color(0xFFE8F4FD),
                    iconColor: IceColors.info,
                    label: "Shaxsiy ma'lumotlar",
                    delay: 180,
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  _MenuItem(
                    icon: Icons.credit_card_outlined,
                    iconBg: const Color(0xFFF0FFF0),
                    iconColor: IceColors.success,
                    label: "To'lov ma'lumoti",
                    delay: 230,
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  _MenuItem(
                    icon: Icons.lock_outline_rounded,
                    iconBg: const Color(0xFFFFF8E7),
                    iconColor: IceColors.warning,
                    label: "Parolni o'zgartirish",
                    delay: 280,
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  _MenuItem(
                    icon: Icons.language_rounded,
                    iconBg: const Color(0xFFF0F4FF),
                    iconColor: IceColors.navyDeep,
                    label: 'Til',
                    value: "O'zbek",
                    delay: 330,
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  _MenuItem(
                    icon: Icons.palette_outlined,
                    iconBg: const Color(0xFFFAF0FF),
                    iconColor: const Color(0xFF9B59B6),
                    label: "Ko'rinish",
                    value: "Tizim bo'yicha",
                    delay: 380,
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),

                  // ── Logout ───────────────────────────────────────────
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    iconBg: IceColors.danger.withAlpha(20),
                    iconColor: IceColors.danger,
                    label: 'Chiqish',
                    labelColor: IceColors.danger,
                    delay: 430,
                    showChevron: false,
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  String _initials(IceUser user) {
    final f =
        user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '';
    final l =
        user.lastName.isNotEmpty ? user.lastName[0].toUpperCase() : '';
    return '$f$l'.isNotEmpty ? '$f$l' : '?';
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Chiqish',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: IceColors.navy),
        ),
        content: const Text(
          'Akkauntingizdan chiqishni xohlaysizmi?',
          style:
              TextStyle(fontSize: 14, color: IceColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Bekor qilish',
              style: TextStyle(
                  color: IceColors.muted,
                  fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: IceColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Chiqish',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Menu item ──────────────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final String? value;
  final bool showChevron;
  final int delay;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.delay,
    required this.onTap,
    this.labelColor,
    this.value,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFFEEEEEE), width: 1.5),
        ),
        child: Row(
          children: [
            // Icon square
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),

            // Label
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: labelColor ?? IceColors.navy,
                ),
              ),
            ),

            // Optional value
            if (value != null) ...[
              Text(
                value!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: IceColors.muted,
                ),
              ),
              const SizedBox(width: 6),
            ],

            // Chevron
            if (showChevron)
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: IceColors.muted),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .slideX(begin: 0.05, duration: 350.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }
}
