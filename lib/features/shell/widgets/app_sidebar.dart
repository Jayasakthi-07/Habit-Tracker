import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../../auth/auth_provider.dart';
import '../../auth/presentation/user_avatar.dart';

class _NavItem {
  const _NavItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

const _primary = [
  _NavItem('Dashboard', Icons.dashboard_rounded, Routes.dashboard),
  _NavItem('Habits', Icons.checklist_rounded, Routes.habits),
  _NavItem('Calendar', Icons.calendar_month_rounded, Routes.calendar),
  _NavItem('Analytics', Icons.insights_rounded, Routes.analytics),
];

const _secondary = [
  _NavItem('Goals', Icons.flag_rounded, Routes.goals),
  _NavItem('Journal', Icons.menu_book_rounded, Routes.journal),
  _NavItem('Achievements', Icons.emoji_events_rounded, Routes.achievements),
  _NavItem('Focus', Icons.timer_rounded, Routes.focus),
  _NavItem('AI Coach', Icons.auto_awesome_rounded, Routes.ai),
];

/// The vertical navigation rail with branding, grouped routes and user card.
class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key, required this.location});
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: AppColors.alpha(AppColors.surface, AppColors.isLight ? 0.85 : 0.55),
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppShadows.accent,
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GradientText('Aura',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text('HABITS',
                        style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 4,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          // Nav.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
                  child: Text('OVERVIEW', style: AppTypography.overline()),
                ),
                for (final item in _primary)
                  _SidebarTile(
                    item: item,
                    active: location == item.route,
                    onTap: () => context.go(item.route),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
                  child: Text('GROW', style: AppTypography.overline()),
                ),
                for (final item in _secondary)
                  _SidebarTile(
                    item: item,
                    active: location == item.route,
                    onTap: () => context.go(item.route),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Settings + user card.
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _SidebarTile(
                  item: const _NavItem(
                      'Settings', Icons.settings_rounded, Routes.settings),
                  active: location == Routes.settings,
                  onTap: () => context.go(Routes.settings),
                ),
                const SizedBox(height: 8),
                _UserCard(user: user),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatefulWidget {
  const _SidebarTile(
      {required this.item, required this.active, required this.onTap});
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppSpacing.fast,
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            color: active
                ? AppColors.alpha(
                    AppColors.primary, AppColors.isLight ? 0.10 : 0.14)
                : (_hover ? AppColors.alpha(AppColors.text, 0.05) : null),
          ),
          child: Row(
            children: [
              // Accent bar marks the active route.
              AnimatedContainer(
                duration: AppSpacing.fast,
                width: 3,
                height: 18,
                margin: const EdgeInsets.only(right: 11),
                decoration: BoxDecoration(
                  gradient: active ? AppColors.accentGlow : null,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(widget.item.icon,
                  size: 19,
                  color: active
                      ? AppColors.primary
                      : (_hover ? AppColors.text : AppColors.muted)),
              const SizedBox(width: 12),
              Text(
                widget.item.label,
                style: TextStyle(
                  color: active
                      ? AppColors.text
                      : (_hover ? AppColors.text : AppColors.muted),
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});
  final UserProfile? user;

  @override
  Widget build(BuildContext context) {
    final u = user;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          UserAvatar(user: u, size: 36, radius: 10),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u?.name ?? 'User',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  (u?.isPremium ?? false) ? 'Premium' : 'Free plan',
                  style: TextStyle(
                    fontSize: 11,
                    color: (u?.isPremium ?? false)
                        ? AppColors.primary
                        : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (u?.isPremium ?? false)
            Icon(Icons.workspace_premium_rounded,
                color: AppColors.primary, size: 18),
        ],
      ),
    );
  }
}
