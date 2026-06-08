import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glow_button.dart';
import '../../../shared/widgets/progress_ring.dart';
import '../../../shared/widgets/section_header.dart';
import '../../notifications/notification_service.dart';

enum PomodoroMode {
  focus(25, 'Focus', AppColors.primary),
  shortBreak(5, 'Short Break', AppColors.secondary),
  longBreak(15, 'Long Break', AppColors.info);

  const PomodoroMode(this.minutes, this.label, this.color);
  final int minutes;
  final String label;
  final Color color;
}

class FocusPage extends ConsumerStatefulWidget {
  const FocusPage({super.key});

  @override
  ConsumerState<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends ConsumerState<FocusPage> {
  PomodoroMode _mode = PomodoroMode.focus;
  Timer? _timer;
  int _remaining = PomodoroMode.focus.minutes * 60;
  bool _running = false;
  int _completedSessions = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _total => _mode.minutes * 60;
  double get _progress => 1 - (_remaining / _total);

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 1) {
        _finish();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = _total;
    });
  }

  void _finish() {
    _timer?.cancel();
    NotificationService.instance.show(
      '${_mode.label} complete!',
      _mode == PomodoroMode.focus ? 'Great work — time for a break.' : 'Break over — back to focus!',
    );
    setState(() {
      _running = false;
      if (_mode == PomodoroMode.focus) _completedSessions++;
      _remaining = _total;
    });
  }

  void _setMode(PomodoroMode mode) {
    _timer?.cancel();
    setState(() {
      _mode = mode;
      _remaining = mode.minutes * 60;
      _running = false;
    });
  }

  String get _formatted {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Focus Mode',
            subtitle: 'Deep-work Pomodoro sessions',
            icon: Icons.timer_rounded,
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Center(
              child: GlassCard(
                width: 460,
                glowColor: _mode.color,
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mode switcher.
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final m in PomodoroMode.values)
                            GestureDetector(
                              onTap: () => _setMode(m),
                              child: AnimatedContainer(
                                duration: AppSpacing.fast,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                decoration: BoxDecoration(
                                  color: _mode == m ? AppColors.alpha(m.color, 0.18) : null,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: Text(m.label,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _mode == m ? m.color : AppColors.muted)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    ProgressRing(
                      progress: _progress.clamp(0, 1),
                      size: 240,
                      strokeWidth: 18,
                      gradient: LinearGradient(colors: [_mode.color, AppColors.secondary]),
                      duration: const Duration(milliseconds: 400),
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_formatted, style: AppTypography.numeric(56)),
                          Text(_running ? 'In progress' : 'Ready',
                              style: const TextStyle(color: AppColors.muted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_running)
                          GlowButton(
                            label: _remaining == _total ? 'Start' : 'Resume',
                            icon: Icons.play_arrow_rounded,
                            color: _mode.color,
                            onPressed: _start,
                          )
                        else
                          GlowButton(
                            label: 'Pause',
                            icon: Icons.pause_rounded,
                            variant: GlowButtonVariant.outline,
                            color: _mode.color,
                            onPressed: _pause,
                          ),
                        const SizedBox(width: 14),
                        GlowButton(
                          label: 'Stop',
                          icon: Icons.stop_rounded,
                          variant: GlowButtonVariant.ghost,
                          color: AppColors.danger,
                          onPressed: _stop,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Completed focus sessions today: $_completedSessions',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms).scale(
                    begin: const Offset(0.96, 0.96),
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
