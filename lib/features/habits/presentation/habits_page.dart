import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/glow_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../categories/domain/habit_category.dart';
import 'providers/habit_providers.dart';
import 'widgets/habit_card.dart';
import 'widgets/habit_editor.dart';

class HabitsPage extends ConsumerStatefulWidget {
  const HabitsPage({super.key});

  @override
  ConsumerState<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends ConsumerState<HabitsPage> {
  String _query = '';
  String? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(habitsControllerProvider);
    var habits = state.habits;
    if (_query.isNotEmpty) {
      habits = habits.where((h) => h.name.toLowerCase().contains(_query.toLowerCase())).toList();
    }
    if (_categoryFilter != null) {
      habits = habits.where((h) => h.categoryId == _categoryFilter).toList();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _Fab(onTap: () => showHabitEditor(context, ref)),
      body: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Your Habits',
              subtitle: '${state.habits.length} habit${state.habits.length == 1 ? '' : 's'} • ${state.showArchived ? 'including archived' : 'active'}',
              icon: Icons.checklist_rounded,
              trailing: Row(
                children: [
                  GlowButton(
                    label: state.showArchived ? 'Hide archived' : 'Show archived',
                    icon: Icons.archive_outlined,
                    variant: GlowButtonVariant.ghost,
                    onPressed: () => ref.read(habitsControllerProvider.notifier).toggleShowArchived(),
                  ),
                  const SizedBox(width: 10),
                  GlowButton(
                    label: 'New habit',
                    icon: Icons.add_rounded,
                    onPressed: () => showHabitEditor(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SearchBar(onChanged: (v) => setState(() => _query = v)),
            const SizedBox(height: 14),
            _CategoryFilter(
              selected: _categoryFilter,
              onChanged: (id) => setState(() => _categoryFilter = id),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: habits.isEmpty
                  ? EmptyState(
                      icon: Icons.add_task_rounded,
                      title: state.habits.isEmpty ? 'No habits yet' : 'No matches',
                      message: state.habits.isEmpty
                          ? 'Create your first habit and start building momentum today.'
                          : 'Try adjusting your search or filters.',
                      actionLabel: state.habits.isEmpty ? 'Create a habit' : null,
                      onAction: state.habits.isEmpty ? () => showHabitEditor(context, ref) : null,
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 460,
                        mainAxisExtent: 84,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: habits.length,
                      itemBuilder: (context, i) {
                        final habit = habits[i];
                        return HabitCard(
                          habit: habit,
                          onEdit: () => showHabitEditor(context, ref, existing: habit),
                        )
                            .animate()
                            .fadeIn(delay: (30 * i).ms, duration: 300.ms)
                            .slideY(begin: 0.08);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search habits…',
        prefixIcon: Icon(Icons.search_rounded, size: 19, color: AppColors.muted),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.selected, required this.onChanged});
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _pill('All', null, selected == null),
          for (final c in BuiltInCategories.all) _pill(c.name, c.id, selected == c.id, color: c.color),
        ],
      ),
    );
  }

  Widget _pill(String label, String? id, bool active, {Color? color}) {
    color ??= AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onChanged(id),
        child: AnimatedContainer(
          duration: AppSpacing.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.alpha(color, 0.18) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: active ? color : AppColors.border),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: active ? AppColors.text : AppColors.muted,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
        ),
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: AppShadows.glow(AppColors.primary, strength: 0.22),
        ),
        child: Icon(Icons.add_rounded, color: AppColors.onPrimary, size: 28),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          duration: 2.seconds,
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
        );
  }
}
