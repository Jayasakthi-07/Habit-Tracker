import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../auth_provider.dart';

enum _Mode { signIn, signUp, verify, forgot }

/// Mobile authentication screen — a single scrollable column with the brand
/// mark on top and a glass auth card below. Same multi-mode flow as desktop
/// (sign in / sign up / verify 8-digit code / forgot), backed by Supabase via
/// `aura_core`. An account is required — there is no guest mode.
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

  bool _validEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

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
        if (code.length < 6) v = 'Enter the full code from your email.';
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
        final r =
            await ctrl.signUpWithEmail(name: name, email: email, password: pass);
        if (!mounted) return;
        if (r.error == null) {
          setState(() {
            _loading = false;
            if (r.needsVerification) {
              _mode = _Mode.verify;
              _info = 'We emailed a verification code to $email.';
            }
            // else: confirmation disabled → already signed in; router redirects.
          });
          return;
        }
        err = r.error;
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
    FocusScope.of(context).unfocus();
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
    final err =
        await ref.read(authProvider.notifier).resendCode(_email.text.trim());
    if (!mounted) return;
    setState(() {
      _error = err;
      _info = err == null ? 'A new code is on its way.' : null;
    });
  }

  String get _title => switch (_mode) {
        _Mode.signIn => 'Welcome back',
        _Mode.signUp => 'Create your account',
        _Mode.verify => 'Check your email',
        _Mode.forgot => 'Reset your password',
      };

  String get _subtitle => switch (_mode) {
        _Mode.signIn => 'Sign in to sync your habits across all your devices.',
        _Mode.signUp =>
          'Start building better habits — your data syncs everywhere.',
        _Mode.verify => 'Enter the code we emailed to confirm your account.',
        _Mode.forgot => 'We\'ll email you a link to set a new password.',
      };

  String get _primaryLabel => switch (_mode) {
        _Mode.signIn => 'Sign in',
        _Mode.signUp => 'Create account',
        _Mode.verify => 'Verify & continue',
        _Mode.forgot => 'Send reset link',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVerify = _mode == _Mode.verify;
    final isForgot = _mode == _Mode.forgot;
    final showSocial = !isVerify && !isForgot;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient aura blobs — subtle, per HANDOVER §6.
          Positioned(top: -90, left: -60, child: _glow(AppColors.ambientA, 260)),
          Positioned(
              bottom: -120, right: -70, child: _glow(AppColors.ambientB, 300)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _brand(theme),
                      const SizedBox(height: 32),
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(_title, style: theme.textTheme.headlineSmall),
                            const SizedBox(height: 6),
                            Text(_subtitle, style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 22),
                            if (_mode == _Mode.signUp) ...[
                              _field(
                                  controller: _name,
                                  label: 'Full name',
                                  icon: Icons.person_outline_rounded),
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
                            if (_mode == _Mode.signIn ||
                                _mode == _Mode.signUp) ...[
                              _field(
                                controller: _password,
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscure,
                                suffix: IconButton(
                                  icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 18,
                                      color: AppColors.muted),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ],
                            if (isVerify) _codeField(),
                            if (_mode == _Mode.signIn)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed:
                                      _loading ? null : () => _switch(_Mode.forgot),
                                  child: const Text('Forgot password?',
                                      style: TextStyle(
                                          color: AppColors.muted, fontSize: 12)),
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
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: _loading ? null : _resendCode,
                                    child: const Text('Resend code',
                                        style: TextStyle(
                                            color: AppColors.secondary,
                                            fontSize: 13)),
                                  ),
                                  const Text('·',
                                      style: TextStyle(color: AppColors.faint)),
                                  TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () => _switch(_Mode.signUp),
                                    child: const Text('Change email',
                                        style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 13)),
                                  ),
                                ],
                              ),
                            ],
                            if (isForgot) ...[
                              const SizedBox(height: 8),
                              Center(
                                child: TextButton(
                                  onPressed:
                                      _loading ? null : () => _switch(_Mode.signIn),
                                  child: const Text('Back to sign in',
                                      style: TextStyle(
                                          color: AppColors.muted, fontSize: 13)),
                                ),
                              ),
                            ],
                            if (showSocial) ...[
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  const Expanded(
                                      child: Divider(color: AppColors.border)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text('or',
                                        style: theme.textTheme.bodySmall),
                                  ),
                                  const Expanded(
                                      child: Divider(color: AppColors.border)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _GoogleButton(
                                  loading: _loading,
                                  onPressed: _loading ? null : _googleSignIn),
                              const SizedBox(height: 12),
                              _toggleRow(),
                            ],
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 450.ms)
                          .slideY(begin: 0.05, curve: Curves.easeOutCubic),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brand(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppShadows.glow(AppColors.primary),
          ),
          child: const Icon(Icons.bolt_rounded,
              color: Color(0xFF002417), size: 36),
        ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),
        const SizedBox(height: 16),
        GradientText(
          'Aura Habits',
          style: theme.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Build habits that actually stick.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
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
          onPressed: _loading
              ? null
              : () => _switch(isSignUp ? _Mode.signIn : _Mode.signUp),
          child: Text(isSignUp ? 'Sign in' : 'Create one',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
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
      maxLength: 8,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onSubmitted: (_) => _submit(),
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 8,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Enter code',
        hintStyle: const TextStyle(
            color: AppColors.faint, letterSpacing: 1, fontSize: 16),
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
          Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              size: 16,
              color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(msg, style: TextStyle(fontSize: 12, color: color))),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
                colors: [AppColors.alpha(color, 0.18), Colors.transparent]),
          ),
        ),
      );
}

/// Gradient primary action button with loading state.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton(
      {required this.label, required this.loading, required this.onPressed});
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: AppSpacing.fast,
        height: 52,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: enabled ? AppShadows.glow(AppColors.primary) : null,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF002417)),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF002417),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }
}

/// A white "Continue with Google" button with a multicolor G.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed, required this.loading});
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF5F5F5) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF4285F4)),
              )
            else
              const _GoogleGLogo(size: 20),
            const SizedBox(width: 12),
            Text(
              loading ? 'Waiting for Google…' : 'Continue with Google',
              style: TextStyle(
                color: enabled ? const Color(0xFF1A1A1A) : AppColors.faint,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
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
          Color(0xFF4285F4),
          Color(0xFF34A853),
          Color(0xFFFBBC05),
          Color(0xFFEA4335),
          Color(0xFF4285F4),
        ],
        stops: [0.0, 0.3, 0.55, 0.8, 1.0],
      ).createShader(bounds),
      child: Icon(Icons.g_mobiledata_rounded,
          size: size * 1.7, color: Colors.white),
    );
  }
}
