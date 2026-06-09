import 'package:aura_core/aura_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_x.dart';
import '../../../../shared/widgets/glow_button.dart';
import '../../../categories/domain/habit_category.dart';
import '../../domain/habit.dart';
import '../../domain/habit_enums.dart';
import '../providers/habit_providers.dart';

/// Shared habit-icon set — identical to the Android app (`aura_core`).
const _iconChoices = kHabitIconChoices;

/// Opens the create/edit habit dialog.
Future<void> showHabitEditor(BuildContext context, WidgetRef ref, {Habit? existing}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => _HabitEditorDialog(existing: existing),
  );
}

class _HabitEditorDialog extends ConsumerStatefulWidget {
  const _HabitEditorDialog({this.existing});
  final Habit? existing;

  @override
  ConsumerState<_HabitEditorDialog> createState() => _HabitEditorDialogState();
}

class _HabitEditorDialogState extends ConsumerState<_HabitEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _notes;

  late String _categoryId;
  late HabitPriority _priority;
  late HabitDifficulty _difficulty;
  late int _iconCode;
  late int _colorValue;
  late HabitFrequency _frequency;
  late List<int> _weekdays;
  late int _target;
  late DateTime _start;
  DateTime? _end;
  late List<String> _reminders;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final h = widget.existing;
    _name = TextEditingController(text: h?.name ?? '');
    _desc = TextEditingController(text: h?.description ?? '');
    _notes = TextEditingController(text: h?.notes ?? '');
    _categoryId = h?.categoryId ?? BuiltInCategories.all.first.id;
    _priority = h?.priority ?? HabitPriority.medium;
    _difficulty = h?.difficulty ?? HabitDifficulty.medium;
    _iconCode = h?.iconCode ?? _iconChoices.first.codePoint;
    _colorValue = h?.colorValue ?? AppColors.habitPalette.first.toARGB32();
    _frequency = h?.frequency ?? HabitFrequency.daily;
    _weekdays = List.of(h?.weekdays ?? [1, 2, 3, 4, 5, 6, 7]);
    _target = h?.targetPerDay ?? 1;
    _start = h?.startDate ?? DateTime.now();
    _end = h?.endDate;
    _reminders = List.of(h?.reminderTimes ?? const []);
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;
    final controller = ref.read(habitsControllerProvider.notifier);
    final base = widget.existing;
    final habit = (base ??
            Habit(id: ref.read(habitRepositoryProvider).newId(), name: '', startDate: _start))
        .copyWith(
      name: _name.text.trim(),
      description: _desc.text.trim(),
      notes: _notes.text.trim(),
      categoryId: _categoryId,
      priority: _priority,
      difficulty: _difficulty,
      iconCode: _iconCode,
      colorValue: _colorValue,
      frequency: _frequency,
      weekdays: _weekdays..sort(),
      targetPerDay: _target,
      startDate: _start,
      endDate: _end,
      clearEndDate: _end == null,
      reminderTimes: _reminders,
    );
    if (_editing) {
      controller.save(habit);
    } else {
      controller.create(habit);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(_colorValue);
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header.
            Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 22),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.alpha(accent, 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.alpha(accent, 0.3)),
                    ),
                    // ignore: non_const_argument_for_const_parameter
                    child: Icon(IconData(_iconCode, fontFamily: 'MaterialIcons'), color: accent),
                  ),
                  const SizedBox(width: 14),
                  Text(_editing ? 'Edit habit' : 'New habit',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.muted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Body.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Name'),
                    TextField(
                      controller: _name,
                      autofocus: !_editing,
                      decoration: const InputDecoration(hintText: 'e.g. Drink 8 glasses of water'),
                    ),
                    const SizedBox(height: 16),
                    _label('Description'),
                    TextField(
                      controller: _desc,
                      decoration: const InputDecoration(hintText: 'Optional short description'),
                    ),
                    const SizedBox(height: 20),
                    _label('Category'),
                    _CategoryPicker(
                      selected: _categoryId,
                      onChanged: (id) => setState(() => _categoryId = id),
                    ),
                    const SizedBox(height: 20),
                    _label('Color'),
                    _ColorPicker(
                      selected: _colorValue,
                      onChanged: (c) => setState(() => _colorValue = c),
                    ),
                    const SizedBox(height: 20),
                    _label('Icon'),
                    _IconPicker(
                      selected: _iconCode,
                      accent: accent,
                      onChanged: (c) => setState(() => _iconCode = c),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Priority'),
                              _Segmented<HabitPriority>(
                                values: HabitPriority.values,
                                selected: _priority,
                                labelOf: (p) => p.label,
                                onChanged: (p) => setState(() => _priority = p),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Difficulty'),
                              _Segmented<HabitDifficulty>(
                                values: HabitDifficulty.values,
                                selected: _difficulty,
                                labelOf: (d) => d.label,
                                onChanged: (d) => setState(() => _difficulty = d),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _label('Frequency'),
                    _Segmented<HabitFrequency>(
                      values: HabitFrequency.values,
                      selected: _frequency,
                      labelOf: (f) => f.label,
                      onChanged: (f) => setState(() => _frequency = f),
                    ),
                    if (_frequency == HabitFrequency.weekly || _frequency == HabitFrequency.custom) ...[
                      const SizedBox(height: 14),
                      _WeekdayPicker(
                        selected: _weekdays,
                        onChanged: (days) => setState(() => _weekdays = days),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Start date'),
                              _DateField(
                                value: _start,
                                onTap: () async {
                                  final picked = await _pickDate(_start);
                                  if (picked != null) setState(() => _start = picked);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('End date (optional)'),
                              _DateField(
                                value: _end,
                                hint: 'No end',
                                onClear: _end == null ? null : () => setState(() => _end = null),
                                onTap: () async {
                                  final picked = await _pickDate(_end ?? _start);
                                  if (picked != null) setState(() => _end = picked);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _label('Daily target (times per day)'),
                    _Stepper(
                      value: _target,
                      onChanged: (v) => setState(() => _target = v),
                    ),
                    const SizedBox(height: 20),
                    _label('Reminders'),
                    _ReminderEditor(
                      reminders: _reminders,
                      onAdd: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (t != null) {
                          setState(() => _reminders.add(
                              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'));
                        }
                      },
                      onRemove: (r) => setState(() => _reminders.remove(r)),
                    ),
                    const SizedBox(height: 20),
                    _label('Notes'),
                    TextField(
                      controller: _notes,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Any extra notes…'),
                    ),
                  ],
                ),
              ),
            ),
            // Footer.
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
              child: Row(
                children: [
                  if (_editing)
                    GlowButton(
                      label: 'Delete',
                      icon: Icons.delete_outline_rounded,
                      variant: GlowButtonVariant.ghost,
                      color: AppColors.danger,
                      onPressed: () {
                        ref.read(habitsControllerProvider.notifier).delete(widget.existing!.id);
                        Navigator.pop(context);
                      },
                    ),
                  const Spacer(),
                  GlowButton(
                    label: 'Cancel',
                    variant: GlowButtonVariant.outline,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  GlowButton(
                    label: _editing ? 'Save changes' : 'Create habit',
                    icon: Icons.check_rounded,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(DateTime initial) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Color(0xFF002417),
            surface: AppColors.card,
          ),
        ),
        child: child!,
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
      );
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in BuiltInCategories.all)
          _Chip(
            label: c.name,
            icon: c.icon,
            color: c.color,
            selected: c.id == selected,
            onTap: () => onChanged(c.id),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon, required this.color, required this.selected, required this.onTap});
  final String label;
  final IconData? icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppSpacing.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.alpha(color, 0.18) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? color : AppColors.muted),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: selected ? AppColors.text : AppColors.muted,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in AppColors.habitPalette)
          GestureDetector(
            onTap: () => onChanged(c.toARGB32()),
            child: AnimatedContainer(
              duration: AppSpacing.fast,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: c.toARGB32() == selected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
                boxShadow: c.toARGB32() == selected ? AppShadows.glow(c, strength: 0.25) : null,
              ),
              child: c.toARGB32() == selected
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.black)
                  : null,
            ),
          ),
      ],
    );
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.selected, required this.accent, required this.onChanged});
  final int selected;
  final Color accent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final ic in _iconChoices)
          GestureDetector(
            onTap: () => onChanged(ic.codePoint),
            child: AnimatedContainer(
              duration: AppSpacing.fast,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ic.codePoint == selected ? AppColors.alpha(accent, 0.18) : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ic.codePoint == selected ? accent : AppColors.border),
              ),
              child: Icon(ic, size: 19, color: ic.codePoint == selected ? accent : AppColors.muted),
            ),
          ),
      ],
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final v in values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: AppSpacing.fast,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: v == selected ? AppColors.primaryGradient : null,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    labelOf(v),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: v == selected ? const Color(0xFF002417) : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({required this.selected, required this.onChanged});
  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 7; i++)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                final next = List.of(selected);
                if (next.contains(i)) {
                  next.remove(i);
                } else {
                  next.add(i);
                }
                onChanged(next);
              },
              child: AnimatedContainer(
                duration: AppSpacing.fast,
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: selected.contains(i) ? AppColors.primaryGradient : null,
                  color: selected.contains(i) ? null : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: selected.contains(i) ? Colors.transparent : AppColors.border),
                ),
                child: Text(
                  _labels[i - 1],
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected.contains(i) ? const Color(0xFF002417) : AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onTap, this.hint = '', this.onClear});
  final DateTime? value;
  final VoidCallback onTap;
  final String hint;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value != null ? value!.pretty : hint,
                style: TextStyle(color: value != null ? AppColors.text : AppColors.faint, fontSize: 13),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded, size: 15, color: AppColors.muted),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _btn(Icons.remove_rounded, () => onChanged((value - 1).clamp(1, 99))),
        Container(
          width: 56,
          alignment: Alignment.center,
          child: Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        _btn(Icons.add_rounded, () => onChanged((value + 1).clamp(1, 99))),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 18, color: AppColors.text),
        ),
      );
}

class _ReminderEditor extends StatelessWidget {
  const _ReminderEditor({required this.reminders, required this.onAdd, required this.onRemove});
  final List<String> reminders;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final r in reminders)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: BoxDecoration(
              color: AppColors.alpha(AppColors.secondary, 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(color: AppColors.alpha(AppColors.secondary, 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_active_rounded, size: 14, color: AppColors.secondary),
                const SizedBox(width: 6),
                Text(r, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => onRemove(r),
                  child: Icon(Icons.close_rounded, size: 14, color: AppColors.muted),
                ),
              ],
            ),
          ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 15, color: AppColors.primary),
                SizedBox(width: 6),
                Text('Add reminder', style: TextStyle(fontSize: 12, color: AppColors.primary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
