import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/auth_provider.dart';
import '../../license/license_service.dart';

/// Profile / account tab: identity, premium license, and sign-out.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider);
    final license = ref.watch(licenseProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          GlassCard(
            child: Row(
              children: [
                _avatar(profile),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile?.name ?? 'User',
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text)),
                      const SizedBox(height: 3),
                      Text(profile?.email ?? '',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.muted)),
                    ],
                  ),
                ),
                if (license.activated)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: const Text('PRO',
                        style: TextStyle(
                            color: Color(0xFF002417),
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _licenseCard(context, ref, license),
          const SizedBox(height: 16),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _tile(
                  icon: Icons.cloud_done_rounded,
                  title: 'Cloud sync',
                  subtitle: 'Your habits sync across all your devices',
                  color: AppColors.primary,
                ),
                const Divider(height: 1, color: AppColors.border),
                _tile(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  subtitle: 'You can sign back in any time',
                  color: AppColors.danger,
                  onTap: () => _confirmSignOut(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text('Aura Habits · v1.0.0',
                style: TextStyle(color: AppColors.faint, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _avatar(UserProfile? profile) {
    final hasPhoto = (profile?.photoUrl ?? '').isNotEmpty;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasPhoto ? null : AppColors.primaryGradient,
        image: hasPhoto
            ? DecorationImage(
                image: NetworkImage(profile!.photoUrl), fit: BoxFit.cover)
            : null,
      ),
      child: hasPhoto
          ? null
          : Center(
              child: Text(profile?.initials ?? 'U',
                  style: const TextStyle(
                      color: Color(0xFF002417),
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ),
    );
  }

  Widget _licenseCard(
      BuildContext context, WidgetRef ref, LicenseState license) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  license.activated
                      ? Icons.workspace_premium_rounded
                      : Icons.lock_outline_rounded,
                  color: AppColors.primary,
                  size: 20),
              const SizedBox(width: 10),
              Text(license.activated ? 'Premium active' : 'Unlock Premium',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            license.activated
                ? 'Thank you for supporting Aura Habits.'
                : 'Enter a license key to unlock all premium features.',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          if (license.activated)
            OutlinedButton(
              onPressed: () {
                ref.read(licenseProvider.notifier).deactivate();
                ref.read(authProvider.notifier).setPremium(false);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.muted,
                side: const BorderSide(color: AppColors.border),
              ),
              child: const Text('Deactivate'),
            )
          else
            FilledButton(
              onPressed: () => _enterKey(context, ref),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF002417),
              ),
              child: const Text('Enter license key',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Future<void> _enterKey(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        String? error;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text('Activate Premium',
                style: TextStyle(color: AppColors.text)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(
                      hintText: 'AURA-XXXX-XXXX-XXXX'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 12)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.muted)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: const Color(0xFF002417),
                ),
                onPressed: () {
                  final err = ref
                      .read(licenseProvider.notifier)
                      .activate(controller.text);
                  if (err == null) {
                    ref.read(authProvider.notifier).setPremium(true);
                    Navigator.of(dialogContext).pop();
                  } else {
                    setState(() => error = err);
                  }
                },
                child: const Text('Activate'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Sign out?', style: TextStyle(color: AppColors.text)),
        content: const Text(
          'Your data stays safely in the cloud and on this device.',
          style: TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child:
                const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(authProvider.notifier).signOut();
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.alpha(color, 0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: color, size: 19),
      ),
      title: Text(title,
          style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right_rounded, color: AppColors.faint)
          : null,
    );
  }
}
