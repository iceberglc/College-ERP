import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_state.dart';
import '../../core/theme/app_theme.dart';

class ProfileHubScreen extends ConsumerStatefulWidget {
  const ProfileHubScreen({super.key});

  @override
  ConsumerState<ProfileHubScreen> createState() => _State();
}

class _State extends ConsumerState<ProfileHubScreen> {
  // Personal info editing
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  bool _savingProfile = false;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    try {
      final res = await ApiClient.instance.dio.patch(
        '/me/',
        data: {
          'first_name': _firstNameCtrl.text.trim(),
          'last_name': _lastNameCtrl.text.trim(),
        },
      );
      ref
          .read(authProvider.notifier)
          .updateUser(
            IceUser.fromJson(Map<String, dynamic>.from(res.data as Map)),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated!'),
            backgroundColor: IceColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _pickProfileImage() async {
    if (_uploadingAvatar) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked == null) return;

      setState(() => _uploadingAvatar = true);
      final bytes = await picked.readAsBytes();
      final form = FormData.fromMap({
        'profile_pic': MultipartFile.fromBytes(bytes, filename: picked.name),
      });
      final res = await ApiClient.instance.dio.patch(
        '/me/',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      ref
          .read(authProvider.notifier)
          .updateUser(
            IceUser.fromJson(Map<String, dynamic>.from(res.data as Map)),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile image updated!'),
            backgroundColor: IceColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _showChangePasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log out?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'You will be signed out of your account.',
          style: TextStyle(color: IceColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: IceColors.danger),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: IceColors.navyDeep),
        ),
      );
    }

    final initials = _getInitials(user.fullName);
    final roleLabel = user.isAdmin
        ? 'Administrator'
        : user.isStaff
        ? 'Staff'
        : 'Student';
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: IceColors.bg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Hero avatar section ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, topPad + 32, 24, 32),
              decoration: const BoxDecoration(
                gradient: kHeroGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        final nav = Navigator.of(context);
                        if (nav.canPop()) {
                          nav.maybePop();
                        } else {
                          context.go('/staff/home');
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 22),
                          SizedBox(width: 6),
                          Text('Back',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ),
                  // Avatar
                  GestureDetector(
                    onTap: _pickProfileImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: IceColors.lime,
                            border: Border.all(
                              color: Colors.white.withAlpha(60),
                              width: 3,
                            ),
                          ),
                          child:
                              user.profilePicUrl != null &&
                                  user.profilePicUrl!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    user.profilePicUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(
                                        initials,
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: IceColors.navy,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: IceColors.navy,
                                    ),
                                  ),
                                ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: IceColors.lime,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: IceColors.navy,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 12,
                              color: IceColors.navy,
                            ),
                          ),
                        ),
                        if (_uploadingAvatar)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(80),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 14),
                  Text(
                    user.fullName.isEmpty ? user.loginId : user.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: IceColors.lime,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      roleLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: IceColors.navy,
                      ),
                    ),
                  ).animate().fadeIn(delay: 150.ms),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Personal Info ────────────────────────────────────────────
            _SectionCard(
              title: 'Personal Info',
              icon: Icons.person_outline_rounded,
              child: Column(
                children: [
                  _EditField(label: 'First Name', controller: _firstNameCtrl),
                  const SizedBox(height: 10),
                  _EditField(label: 'Last Name', controller: _lastNameCtrl),
                  const SizedBox(height: 10),
                  _ReadOnlyField(label: 'Email', value: user.email),
                  const SizedBox(height: 10),
                  _ReadOnlyField(label: 'Login ID', value: user.loginId),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _savingProfile ? null : _saveProfile,
                      style: FilledButton.styleFrom(
                        backgroundColor: IceColors.navyDeep,
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _savingProfile
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.06),

            const SizedBox(height: 12),

            // ── Security ─────────────────────────────────────────────────
            _SectionCard(
              title: 'Security',
              icon: Icons.lock_outline_rounded,
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showChangePasswordSheet,
                  icon: const Icon(Icons.key_rounded, size: 18),
                  label: const Text('Change Password'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: IceColors.navyDeep,
                    side: const BorderSide(color: IceColors.navyDeep),
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.06),

            const SizedBox(height: 12),

            // ── Appearance ───────────────────────────────────────────────
            _SectionCard(
              title: 'Appearance',
              icon: Icons.palette_outlined,
              child: _ThemeSelector(),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.06),

            const SizedBox(height: 12),

            // ── About ────────────────────────────────────────────────────
            _SectionCard(
              title: 'About',
              icon: Icons.info_outline_rounded,
              child: Column(
                children: [
                  _InfoRow(label: 'Version', value: '1.0.0'),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Contact', value: 'support@iceberglc.com'),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Website', value: 'iceberglc.com'),
                ],
              ),
            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.06),

            const SizedBox(height: 20),

            // ── Logout ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Log out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: IceColors.danger,
                    side: const BorderSide(color: IceColors.danger),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IceColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IceColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: IceColors.navyDeep),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: IceColors.navyDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}

// ─── Edit Field ───────────────────────────────────────────────────────────────

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _EditField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
  );
}

// ─── Read Only Field ──────────────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: IceColors.surface2,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: IceColors.border, width: 1.5),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: IceColors.muted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: IceColors.text,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.lock_rounded, size: 14, color: IceColors.border),
      ],
    ),
  );
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: const TextStyle(fontSize: 13, color: IceColors.muted)),
      const Spacer(),
      Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: IceColors.text,
        ),
      ),
    ],
  );
}

// ─── Theme Selector ───────────────────────────────────────────────────────────

class _ThemeSelector extends StatefulWidget {
  @override
  State<_ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<_ThemeSelector> {
  // 0 = System, 1 = Light, 2 = Dark
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    const options = ['System', 'Light', 'Dark'];
    const icons = [
      Icons.brightness_auto_rounded,
      Icons.wb_sunny_outlined,
      Icons.nightlight_round_outlined,
    ];

    return Row(
      children: List.generate(3, (i) {
        final isSelected = _selected == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? IceColors.navyDeep : IceColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? IceColors.navyDeep : IceColors.border,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    icons[i],
                    size: 20,
                    color: isSelected ? Colors.white : IceColors.muted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    options[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : IceColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Change Password Sheet ────────────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _showOld = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiClient.instance.dio.post(
        '/me/change-password/',
        data: {
          'old_password': _oldCtrl.text,
          'new_password': _newCtrl.text,
          'confirm_password': _confirmCtrl.text,
        },
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password changed successfully!'),
            backgroundColor: IceColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad =
        MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      decoration: const BoxDecoration(
        color: IceColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: IceColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Change Password',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: IceColors.text,
            ),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _PasswordField(
                  controller: _oldCtrl,
                  label: 'Current Password',
                  show: _showOld,
                  onToggle: () => setState(() => _showOld = !_showOld),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _PasswordField(
                  controller: _newCtrl,
                  label: 'New Password',
                  show: _showNew,
                  onToggle: () => setState(() => _showNew = !_showNew),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _PasswordField(
                  controller: _confirmCtrl,
                  label: 'Confirm New Password',
                  show: _showConfirm,
                  onToggle: () => setState(() => _showConfirm = !_showConfirm),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v != _newCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: IceColors.navyDeep,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Update Password',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool show;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.show,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: !show,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          size: 18,
          color: IceColors.muted,
        ),
      ),
    ),
  );
}
