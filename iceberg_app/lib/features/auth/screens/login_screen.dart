import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _idCtrl   = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading   = false;
  bool _obscure   = true;
  String? _error;

  @override
  void dispose() {
    _idCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() { _loading = true; _error = null; });
    final err = await ref.read(authProvider.notifier)
        .login(_idCtrl.text.trim(), _passCtrl.text);
    if (mounted) setState(() { _loading = false; _error = err; });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 768 ? _buildDesktop(context) : _buildMobile(context);
  }

  // ── Desktop: navy backdrop + centered card (mirrors Django login page) ────
  Widget _buildDesktop(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [IceColors.navy, IceColors.navyMid, IceColors.navyDeep],
          ),
        ),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.fromLTRB(36, 40, 36, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: IceColors.navy,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'ICE',
                        style: TextStyle(
                          color: IceColors.lime,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    )
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.easeOutBack)
                        .fadeIn(duration: 300.ms),
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'Xush kelibsiz',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: IceColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Iltimos, akkauntingizga kiring',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: IceColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _form(),
                ],
              ),
            ),
          )
              .animate()
              .slideY(begin: 0.06, duration: 450.ms, curve: Curves.easeOutCubic)
              .fadeIn(duration: 350.ms),
        ),
      ),
    );
  }

  // ── Mobile: lime hero + bottom sheet card (unchanged design) ──────────────
  Widget _buildMobile(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Top lime-to-white gradient section (45% of screen) ──────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: size.height * 0.45,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF0FFA0), Color(0xFFF8FFE0)],
                ),
              ),
              alignment: Alignment.center,
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: IceColors.navy,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'ICE',
                            style: TextStyle(
                              color: IceColors.lime,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.elasticOut)
                        .fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),

          // ── White card from bottom ───────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: size.height * 0.38,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 32, 24, bottom + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 28),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    const Text(
                      'Xush kelibsiz',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: IceColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Iltimos, akkauntingizga kiring',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: IceColors.muted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _form(),
                  ],
                ),
              ),
            )
                .animate(delay: 200.ms)
                .slideY(begin: 0.15, duration: 500.ms, curve: Curves.easeOutCubic)
                .fadeIn(duration: 400.ms),
          ),
        ],
      ),
    );
  }

  // ── Shared login form ──────────────────────────────────────────────────────
  InputDecoration _dec({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder b(Color color, [double w = 1.5]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: w),
        );
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: b(const Color(0xFFEEEEEE)),
      enabledBorder: b(const Color(0xFFEEEEEE)),
      focusedBorder: b(IceColors.navy, 2),
      errorBorder: b(IceColors.danger),
      focusedErrorBorder: b(IceColors.danger, 2),
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: IceColors.navy),
      ),
      suffixIcon: suffixIcon,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ID / email field ─────────────────────────────────────────────
          TextFormField(
            controller: _idCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _dec(
              label: 'ID raqam yoki email',
              icon: Icons.person_outline_rounded,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Majburiy' : null,
          )
              .animate(delay: 200.ms)
              .slideX(begin: -0.05, duration: 400.ms, curve: Curves.easeOut)
              .fadeIn(duration: 350.ms),

          const SizedBox(height: 14),

          // ── Parol field ──────────────────────────────────────────────────
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: _dec(
              label: 'Parol',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: IceColors.muted,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Majburiy' : null,
          )
              .animate(delay: 280.ms)
              .slideX(begin: -0.05, duration: 400.ms, curve: Curves.easeOut)
              .fadeIn(duration: 350.ms),

          // ── Error message ────────────────────────────────────────────────
          AnimatedSize(
            duration: 300.ms,
            child: _error == null
                ? const SizedBox(height: 20)
                : Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: IceColors.danger.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: IceColors.danger.withAlpha(60)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          color: IceColors.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: IceColors.danger, fontSize: 13)),
                      ),
                    ]),
                  ).animate().shake(duration: 400.ms, hz: 3).fadeIn(
                        duration: 200.ms),
          ),

          // ── KIRISH button ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: IceColors.navy,
                foregroundColor: Colors.white,
                disabledBackgroundColor: IceColors.navy.withAlpha(120),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text(
                      'KIRISH',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          )
              .animate(delay: 350.ms)
              .slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut)
              .fadeIn(duration: 350.ms),

          const SizedBox(height: 16),
          Center(
            child: Text(
              'Parolni tiklash uchun adminstratorga murojaat qiling.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: IceColors.muted.withAlpha(160),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
