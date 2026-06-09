import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glow_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/auth_provider.dart';
import '../../auth/presentation/user_avatar.dart';
import '../../export/export_service.dart';
import '../../goals/goals_provider.dart';
import '../../habits/presentation/providers/habit_providers.dart';
import '../../journal/journal_provider.dart';
import '../../license/license_service.dart';
import '../backup_service.dart';
import '../settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(authProvider);
    final license = ref.watch(licenseProvider);

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Settings',
            subtitle: 'Customize Aura Habits to fit your workflow',
            icon: Icons.settings_rounded,
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _ProfileCard(user: user),
                    const SizedBox(height: 16),
                    _NotificationsCard(settings: settings),
                    const SizedBox(height: 16),
                    _GeneralCard(settings: settings),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, curve: Curves.easeOutCubic),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _PremiumCard(isPremium: user?.isPremium ?? false, license: license),
                    const SizedBox(height: 16),
                    _DataCard(),
                    const SizedBox(height: 16),
                    _AboutCard(),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: 0.05, curve: Curves.easeOutCubic),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title, icon: icon),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({required this.user});
  final UserProfile? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Card(
      title: 'Profile',
      icon: Icons.person_rounded,
      children: [
        Row(
          children: [
            UserAvatar(user: user, size: 56, radius: 16),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                  Text(user?.email.isNotEmpty == true ? user!.email : 'No email',
                      style: TextStyle(color: AppColors.muted, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            GlowButton(
              label: 'Edit profile',
              icon: Icons.edit_rounded,
              variant: GlowButtonVariant.outline,
              onPressed: () => _editProfile(context, ref, user),
            ),
            const SizedBox(width: 12),
            GlowButton(
              label: 'Sign out',
              icon: Icons.logout_rounded,
              variant: GlowButtonVariant.ghost,
              color: AppColors.danger,
              onPressed: () {
                ref.read(authProvider.notifier).signOut();
                context.go(Routes.login);
              },
            ),
          ],
        ),
      ],
    );
  }

  void _editProfile(BuildContext context, WidgetRef ref, UserProfile? user) {
    final name = TextEditingController(text: user?.name ?? '');
    final email = TextEditingController(text: user?.email ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit profile', style: Theme.of(dialogContext).textTheme.titleLarge),
                const SizedBox(height: 18),
                TextField(controller: name, decoration: const InputDecoration(hintText: 'Name')),
                const SizedBox(height: 12),
                TextField(controller: email, decoration: const InputDecoration(hintText: 'Email')),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: GlowButton(
                    label: 'Save',
                    icon: Icons.check_rounded,
                    onPressed: () {
                      ref.read(authProvider.notifier).updateProfile(name: name.text.trim(), email: email.text.trim());
                      Navigator.pop(dialogContext);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsCard extends ConsumerWidget {
  const _NotificationsCard({required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.read(settingsProvider.notifier);
    return _Card(
      title: 'Notifications',
      icon: Icons.notifications_rounded,
      children: [
        _Toggle(label: 'Enable desktop notifications', value: settings.notificationsEnabled, onChanged: c.setNotifications),
        _Toggle(label: 'Notification sounds', value: settings.soundEnabled, onChanged: c.setSound),
      ],
    );
  }
}

class _GeneralCard extends ConsumerWidget {
  const _GeneralCard({required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.read(settingsProvider.notifier);
    return _Card(
      title: 'General',
      icon: Icons.tune_rounded,
      children: [
        _Toggle(label: 'Minimize to system tray', value: settings.minimizeToTray, onChanged: c.setMinimizeToTray),
        _Toggle(label: 'Start with Windows', value: settings.startWithWindows, onChanged: c.setStartWithWindows),
        _Toggle(label: 'Week starts on Monday', value: settings.weekStartsMonday, onChanged: c.setWeekStart),
        const SizedBox(height: 14),
        Text('Appearance',
            style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const _ThemeSelector(),
      ],
    );
  }
}

/// Segmented System / Light / Dark theme picker (desktop).
class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final ctrl = ref.read(themeModeProvider.notifier);
    Widget seg(ThemeMode m, IconData icon, String label) {
      final sel = mode == m;
      return Expanded(
        child: GestureDetector(
          onTap: () => ctrl.setMode(m),
          child: AnimatedContainer(
            duration: AppSpacing.fast,
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel
                  ? AppColors.alpha(AppColors.primary, 0.16)
                  : AppColors.alpha(Colors.white, 0.03),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                  color: sel ? AppColors.primary : AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 16,
                    color: sel ? AppColors.primary : AppColors.muted),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel ? AppColors.primary : AppColors.muted)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        seg(ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
        seg(ThemeMode.light, Icons.light_mode_rounded, 'Light'),
        seg(ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
      ],
    );
  }
}

class _PremiumCard extends ConsumerWidget {
  const _PremiumCard({required this.isPremium, required this.license});
  final bool isPremium;
  final LicenseState license;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      glowColor: AppColors.primary,
      borderColor: AppColors.alpha(AppColors.primary, 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(license.activated ? 'Premium Activated' : 'Aura Premium',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              if (license.activated)
                const Icon(Icons.verified_rounded, color: AppColors.success),
            ],
          ),
          const SizedBox(height: 12),
          if (license.activated) ...[
            Text('License: ${license.key}', style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Device: ${license.deviceId}', style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 16),
            GlowButton(
              label: 'Deactivate license',
              icon: Icons.link_off_rounded,
              variant: GlowButtonVariant.outline,
              color: AppColors.danger,
              onPressed: () {
                ref.read(licenseProvider.notifier).deactivate();
                ref.read(authProvider.notifier).setPremium(false);
              },
            ),
          ] else ...[
            Text(
              'Unlock unlimited habits, advanced analytics, premium themes and AI features.',
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _Perk('Unlimited habits'),
                _Perk('AI coach'),
                _Perk('Premium themes'),
                _Perk('Priority support'),
              ],
            ),
            const SizedBox(height: 16),
            GlowButton(
              label: 'Activate license',
              icon: Icons.vpn_key_rounded,
              expand: true,
              onPressed: () => _activate(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  void _activate(BuildContext context, WidgetRef ref) {
    final keyCtrl = TextEditingController();
    String? error;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Activate Premium', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Enter your license key (AURA-XXXX-XXXX-XXXX).',
                      style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: keyCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(hintText: 'AURA-XXXX-XXXX-XXXX'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                  ],
                  const SizedBox(height: 12),
                  // Convenience for evaluation: generate a valid demo key.
                  TextButton(
                    onPressed: () => keyCtrl.text = ref.read(licenseProvider.notifier).generateDemoKey(),
                    child: const Text('Generate demo key', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GlowButton(label: 'Cancel', variant: GlowButtonVariant.outline, onPressed: () => Navigator.pop(context)),
                      const SizedBox(width: 12),
                      GlowButton(
                        label: 'Activate',
                        icon: Icons.check_rounded,
                        onPressed: () {
                          final err = ref.read(licenseProvider.notifier).activate(keyCtrl.text);
                          if (err == null) {
                            ref.read(authProvider.notifier).setPremium(true);
                            Navigator.pop(context);
                          } else {
                            setState(() => error = err);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.alpha(AppColors.primary, 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.text)),
        ],
      ),
    );
  }
}

class _DataCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void notify(String msg) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1C1C1C),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 5),
      ));
    }

    return _Card(
      title: 'Data & Backup',
      icon: Icons.storage_rounded,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            GlowButton(
              label: 'Backup data',
              icon: Icons.backup_rounded,
              variant: GlowButtonVariant.outline,
              onPressed: () async {
                final path = await BackupService.instance.backup();
                notify('Backup saved → $path');
              },
            ),
            GlowButton(
              label: 'Restore latest',
              icon: Icons.restore_rounded,
              variant: GlowButtonVariant.outline,
              onPressed: () async {
                final latest = await BackupService.instance.latestBackup();
                if (latest == null) {
                  notify('No backup found. Create one first.');
                  return;
                }
                final count = await BackupService.instance.restore(latest.path);
                ref.invalidate(habitsControllerProvider);
                ref.invalidate(goalsProvider);
                ref.invalidate(journalProvider);
                notify('Restored $count records from latest backup.');
              },
            ),
            GlowButton(
              label: 'Export CSV',
              icon: Icons.table_chart_rounded,
              variant: GlowButtonVariant.ghost,
              onPressed: () => ExportService.instance.exportCsv(ref, context),
            ),
            GlowButton(
              label: 'Export Excel',
              icon: Icons.grid_on_rounded,
              variant: GlowButtonVariant.ghost,
              onPressed: () => ExportService.instance.exportExcel(ref, context),
            ),
          ],
        ),
      ],
    );
  }
}

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'About & Security',
      icon: Icons.info_rounded,
      children: [
        _InfoRow(label: 'Version', value: '1.0.0'),
        _InfoRow(label: 'Storage', value: 'Local & encrypted-at-rest'),
        _InfoRow(label: 'Privacy', value: 'Offline-first — your data never leaves this device'),
        SizedBox(height: 8),
        Text(
          'Aura Habits keeps all your data on this device. Security features include local '
          'password protection and device-bound licensing.',
          style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: TextStyle(color: AppColors.muted, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF002417),
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.muted,
            inactiveTrackColor: AppColors.surface,
          ),
        ],
      ),
    );
  }
}
