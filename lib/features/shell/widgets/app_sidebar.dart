import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../../auth/auth_provider.dart';
import '../../auth/presentation/user_avatar.dart';

class _NavItem {
  const _NavItem(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

const _items = [
  _NavItem('Dashboard', Icons.dashboard_rounded, Routes.dashboard),
  _NavItem('Habits', Icons.checklist_rounded, Routes.habits),
  _NavItem('Calendar', Icons.calendar_month_rounded, Routes.calendar),
  _NavItem('Analytics', Icons.insights_rounded, Routes.analytics),
  _NavItem('Goals', Icons.flag_rounded, Routes.goals),
  _NavItem('Journal', Icons.menu_book_rounded, Routes.journal),
  _NavItem('Achievements', Icons.emoji_events_rounded, Routes.achievements),
  _NavItem('Focus', Icons.timer_rounded, Routes.focus),
  _NavItem('AI Coach', Icons.auto_awesome_rounded, Routes.ai),
];

/// The vertical navigation rail with branding, routes and user card.
class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key, required this.location});
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppShadows.glow(AppColors.primary, strength: 0.2),
                  ),
                  child: Icon(Icons.bolt_rounded, color: AppColors.onPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GradientText('Aura',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
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
                for (var i = 0; i < _items.length; i++)
                  _SidebarTile(
                    item: _items[i],
                    active: location == _items[i].route,
                    onTap: () => context.go(_items[i].route),
                  ).animate().fadeIn(delay: (40 * i).ms, duration: 300.ms).slideX(begin: -0.1),
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
                  item: const _NavItem('Settings', Icons.settings_rounded, Routes.settings),
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
  const _SidebarTile({required this.item, required this.active, required this.onTap});
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            gradient: active
                ? LinearGradient(colors: [
                    AppColors.alpha(AppColors.primary, 0.18),
                    AppColors.alpha(AppColors.secondary, 0.06),
                  ])
                : null,
            color: !active && _hover ? AppColors.alpha(Colors.white, 0.05) : null,
            border: Border.all(
              color: active ? AppColors.alpha(AppColors.primary, 0.4) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(widget.item.icon,
                  size: 19,
                  color: active ? AppColors.primary : (_hover ? AppColors.text : AppColors.muted)),
              const SizedBox(width: 13),
              Text(
                widget.item.label,
                style: TextStyle(
                  color: active ? AppColors.text : (_hover ? AppColors.text : AppColors.muted),
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (active)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.glow(AppColors.primary, strength: 0.25),
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
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  (u?.isPremium ?? false) ? 'Premium' : 'Free plan',
                  style: TextStyle(
                    fontSize: 11,
                    color: (u?.isPremium ?? false) ? AppColors.primary : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (u?.isPremium ?? false)
            Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 18),
        ],
      ),
    );
  }
}
