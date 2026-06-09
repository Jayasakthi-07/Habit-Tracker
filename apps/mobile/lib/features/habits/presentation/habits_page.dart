import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_x.dart';
import 'providers/habit_providers.dart';
import 'widgets/habit_card.dart';
import 'widgets/habit_editor_sheet.dart';

/// Full habit list with today's completion state. Tap a card to edit, tap the
/// tick to complete, long-press for the status picker.
class HabitsPage extends ConsumerWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitsControllerProvider);
    final habits = state.habits.where((h) => !h.archived).toList();
    final today = DateTime.now().dateOnly;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text('Your habits',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const Spacer(),
                  Text('${habits.length}',
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 15)),
                ],
              ),
            ),
          ),
          if (habits.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _empty(context),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              sliver: SliverList.builder(
                itemCount: habits.length,
                itemBuilder: (_, i) =>
                    HabitCard(habit: habits[i], date: today),
              ),
            ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.alpha(AppColors.primary, 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: AppColors.primary, size: 44),
            ),
            const SizedBox(height: 20),
            Text('No habits yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Create your first habit and start a streak.\nIt syncs to all your devices automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => HabitEditorSheet.show(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF002417),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create habit',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
