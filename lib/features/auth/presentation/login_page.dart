import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../../../shared/widgets/window_buttons.dart';
import '../auth_provider.dart';

/// Premium split-panel authentication screen.
///
/// Sign-in is handled exclusively through Google (desktop OAuth loopback flow).
/// A discreet offline-guest option remains so the app is still usable without
/// an internet connection.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err; // null on success; router redirects automatically.
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

  Widget _card(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: GlassCard(
          padding: const EdgeInsets.all(34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Welcome to Aura Habits', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Sign in with your Google account to get started and keep your '
                'identity across sessions.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 30),
              _GoogleButton(loading: _loading, onPressed: _loading ? null : _signInWithGoogle),
              if (_loading) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.muted),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Complete sign-in in the browser window that just opened…',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.alpha(AppColors.danger, 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: AppColors.alpha(AppColors.danger, 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(fontSize: 12, color: AppColors.danger)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
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
              Center(
                child: TextButton.icon(
                  onPressed: _loading ? null : () => ref.read(authProvider.notifier).continueAsGuest(),
                  icon: const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.muted),
                  label: const Text('Continue offline as guest',
                      style: TextStyle(color: AppColors.muted, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your habit data always stays local on this device. Google sign-in is '
                'only used for your name, email and avatar.',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(color: AppColors.faint),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.06, curve: Curves.easeOutCubic),
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
                    'gamification and beautiful insights — designed to keep you consistent.',
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
                    _FeatureChip(Icons.timer_rounded, 'Focus mode'),
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
