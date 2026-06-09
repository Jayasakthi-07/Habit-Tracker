import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../../../shared/widgets/window_buttons.dart';
import '../auth_provider.dart';

enum _Mode { signIn, signUp, verify, forgot }

/// Premium split-panel authentication screen.
///
/// Supports email + password sign-up with a 6-digit email verification code,
/// sign-in, password reset, Google sign-in, and an offline guest fallback —
/// all backed by Supabase (except guest, which stays local).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  _Mode _mode = _Mode.signIn;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  void _switch(_Mode mode) => setState(() {
        _mode = mode;
        _error = null;
        _info = null;
      });

  bool _validEmail(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    final pass = _password.text;
    final name = _name.text.trim();
    final code = _code.text.trim();

    String? v;
    switch (_mode) {
      case _Mode.signIn:
        if (!_validEmail(email)) {
          v = 'Enter a valid email address.';
        } else if (pass.isEmpty) {
          v = 'Enter your password.';
        }
      case _Mode.signUp:
        if (name.isEmpty) {
          v = 'Enter your name.';
        } else if (!_validEmail(email)) {
          v = 'Enter a valid email address.';
        } else if (pass.length < 6) {
          v = 'Password must be at least 6 characters.';
        }
      case _Mode.verify:
        if (code.length < 6) v = 'Enter the 6-digit code from your email.';
      case _Mode.forgot:
        if (!_validEmail(email)) v = 'Enter a valid email address.';
    }
    if (v != null) {
      setState(() => _error = v);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    final ctrl = ref.read(authProvider.notifier);
    String? err;
    switch (_mode) {
      case _Mode.signIn:
        err = await ctrl.signInWithEmail(email: email, password: pass);
      case _Mode.signUp:
        err = await ctrl.signUpWithEmail(name: name, email: email, password: pass);
        if (err == null && mounted) {
          setState(() {
            _loading = false;
            _mode = _Mode.verify;
            _info = 'We emailed a 6-digit verification code to $email.';
          });
          return;
        }
      case _Mode.verify:
        err = await ctrl.verifyEmailCode(email: email, code: code);
      case _Mode.forgot:
        err = await ctrl.sendPasswordReset(email);
        if (err == null && mounted) {
          setState(() {
            _loading = false;
            _mode = _Mode.signIn;
            _info = 'Password reset link sent to $email.';
          });
          return;
        }
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err; // null on success → router redirects automatically.
    });
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    final err = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err;
    });
  }

  Future<void> _resendCode() async {
    final err = await ref.read(authProvider.notifier).resendCode(_email.text.trim());
    if (!mounted) return;
    setState(() {
      _error = err;
      _info = err == null ? 'A new code is on its way.' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 44,
              child: Row(
                children: const [
                  Expanded(child: TitleDragArea(child: SizedBox.expand())),
                  WindowButtons(),
                ],
              ),
            ),
          ),
          Row(
            children: [
              const Expanded(flex: 5, child: _BrandPanel()),
              Expanded(flex: 4, child: Center(child: _card(context))),
            ],
          ),
        ],
      ),
    );
  }

  String get _title => switch (_mode) {
        _Mode.signIn => 'Welcome back',
        _Mode.signUp => 'Create your account',
        _Mode.verify => 'Check your email',
        _Mode.forgot => 'Reset your password',
      };

  String get _subtitle => switch (_mode) {
        _Mode.signIn => 'Sign in to sync your habits across all your devices.',
        _Mode.signUp => 'Start building better habits — your data syncs everywhere.',
        _Mode.verify => 'Enter the 6-digit code we emailed to confirm your account.',
        _Mode.forgot => 'We\'ll email you a link to set a new password.',
      };

  String get _primaryLabel => switch (_mode) {
        _Mode.signIn => 'Sign in',
        _Mode.signUp => 'Create account',
        _Mode.verify => 'Verify & continue',
        _Mode.forgot => 'Send reset link',
      };

  Widget _card(BuildContext context) {
    final theme = Theme.of(context);
    final isVerify = _mode == _Mode.verify;
    final isForgot = _mode == _Mode.forgot;
    final showSocial = !isVerify && !isForgot;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: GlassCard(
          padding: const EdgeInsets.all(34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(_subtitle, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 24),

              if (_mode == _Mode.signUp) ...[
                _field(controller: _name, label: 'Full name', icon: Icons.person_outline_rounded),
                const SizedBox(height: 14),
              ],
              if (!isVerify) ...[
                _field(
                  controller: _email,
                  label: 'Email',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
              ],
              if (_mode == _Mode.signIn || _mode == _Mode.signUp) ...[
                _field(
                  controller: _password,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18, color: AppColors.muted),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ],
              if (isVerify) _codeField(),

              if (_mode == _Mode.signIn)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loading ? null : () => _switch(_Mode.forgot),
                    child: const Text('Forgot password?',
                        style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ),
                ),

              if (_info != null) _banner(_info!, isError: false),
              if (_error != null) _banner(_error!, isError: true),

              const SizedBox(height: 18),
              _PrimaryButton(
                label: _primaryLabel,
                loading: _loading,
                onPressed: _loading ? null : _submit,
              ),

              if (isVerify) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _loading ? null : _resendCode,
                      child: const Text('Resend code',
                          style: TextStyle(color: AppColors.secondary, fontSize: 13)),
                    ),
                    const Text('·', style: TextStyle(color: AppColors.faint)),
                    TextButton(
                      onPressed: _loading ? null : () => _switch(_Mode.signUp),
                      child: const Text('Change email',
                          style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    ),
                  ],
                ),
              ],

              if (isForgot) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : () => _switch(_Mode.signIn),
                    child: const Text('Back to sign in',
                        style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  ),
                ),
              ],

              if (showSocial) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: theme.textTheme.bodySmall),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: 16),
                _GoogleButton(loading: _loading, onPressed: _loading ? null : _googleSignIn),
                const SizedBox(height: 14),
                Center(
                  child: TextButton.icon(
                    onPressed: _loading ? null : () => ref.read(authProvider.notifier).continueAsGuest(),
                    icon: const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.muted),
                    label: const Text('Continue offline as guest',
                        style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 6),
                _toggleRow(),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic),
      ),
    );
  }

  Widget _toggleRow() {
    final isSignUp = _mode == _Mode.signUp;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(isSignUp ? 'Already have an account?' : 'New to Aura Habits?',
            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        TextButton(
          onPressed: _loading ? null : () => _switch(isSignUp ? _Mode.signIn : _Mode.signUp),
          child: Text(isSignUp ? 'Sign in' : 'Create one',
              style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: c),
        );
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.text),
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.muted),
        prefixIcon: Icon(icon, size: 18, color: AppColors.muted),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.alpha(Colors.white, 0.03),
        border: border(AppColors.border),
        enabledBorder: border(AppColors.border),
        focusedBorder: border(AppColors.primary),
      ),
    );
  }

  Widget _codeField() {
    return TextField(
      controller: _code,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onSubmitted: (_) => _submit(),
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 14,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: '••••••',
        hintStyle: const TextStyle(color: AppColors.faint, letterSpacing: 14, fontSize: 28),
        filled: true,
        fillColor: AppColors.alpha(Colors.white, 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _banner(String msg, {required bool isError}) {
    final color = isError ? AppColors.danger : AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.alpha(color, 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.alpha(color, 0.3)),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: TextStyle(fontSize: 12, color: color))),
        ],
      ),
    );
  }
}

/// Gradient primary action button with hover + loading states.
class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({required this.label, required this.loading, required this.onPressed});
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppSpacing.fast,
          height: 50,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: enabled && _hover ? AppShadows.glow(AppColors.primary) : null,
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF002417)),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      color: Color(0xFF002417),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// A white, Material-styled "Continue with Google" button with a multicolor G.
class _GoogleButton extends StatefulWidget {
  const _GoogleButton({required this.onPressed, required this.loading});
  final VoidCallback? onPressed;
  final bool loading;

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppSpacing.fast,
          height: 50,
          decoration: BoxDecoration(
            color: enabled ? (_hover ? Colors.white : const Color(0xFFF5F5F5)) : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: enabled && _hover
                ? [const BoxShadow(color: Color(0x33FFFFFF), blurRadius: 18, spreadRadius: -6)]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4285F4)),
                )
              else
                const _GoogleGLogo(size: 20),
              const SizedBox(width: 12),
              Text(
                widget.loading ? 'Waiting for Google…' : 'Continue with Google',
                style: TextStyle(
                  color: enabled ? const Color(0xFF1A1A1A) : AppColors.faint,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A lightweight multicolor Google "G" mark (sweep-gradient over a glyph).
class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo({this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const SweepGradient(
        startAngle: 0.6,
        colors: [
          Color(0xFF4285F4), // blue
          Color(0xFF34A853), // green
          Color(0xFFFBBC05), // yellow
          Color(0xFFEA4335), // red
          Color(0xFF4285F4),
        ],
        stops: [0.0, 0.3, 0.55, 0.8, 1.0],
      ).createShader(bounds),
      child: Icon(Icons.g_mobiledata_rounded, size: size * 1.7, color: Colors.white),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF12121F), Color(0xFF0A0A0A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -60, left: -40, child: _glow(AppColors.ambientA, 280)),
          Positioned(bottom: -80, right: -40, child: _glow(AppColors.ambientB, 320)),
          Padding(
            padding: const EdgeInsets.all(56),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.glow(AppColors.primary),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Color(0xFF002417), size: 30),
                    ),
                    const SizedBox(width: 16),
                    GradientText('Aura Habits',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
                const SizedBox(height: 36),
                Text(
                  'Build habits that\nactually stick.',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(height: 1.15),
                ).animate().fadeIn(delay: 150.ms, duration: 700.ms).slideY(begin: 0.1),
                const SizedBox(height: 18),
                SizedBox(
                  width: 420,
                  child: Text(
                    'A premium, offline-first habit tracker with streaks, analytics, '
                    'gamification and beautiful insights — now syncing across all your devices.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 700.ms),
                const SizedBox(height: 40),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    _FeatureChip(Icons.local_fire_department_rounded, 'Streaks'),
                    _FeatureChip(Icons.insights_rounded, 'Analytics'),
                    _FeatureChip(Icons.emoji_events_rounded, 'Achievements'),
                    _FeatureChip(Icons.cloud_done_rounded, 'Cloud sync'),
                  ],
                ).animate().fadeIn(delay: 450.ms, duration: 700.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [AppColors.alpha(color, 0.22), Colors.transparent]),
        ),
      );
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.alpha(Colors.white, 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.text)),
        ],
      ),
    );
  }
}
