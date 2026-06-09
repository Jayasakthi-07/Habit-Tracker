import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/glow_button.dart';
import '../../domain/habit.dart';
import '../../domain/habit_enums.dart';
import '../providers/habit_providers.dart';

/// Bottom-sheet editor to create or edit a habit. Returns nothing; mutations go
/// through [habitsControllerProvider] which the lists watch.
class HabitEditorSheet {
  static Future<void> show(BuildContext context, {Habit? habit}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _Editor(habit: habit),
    );
  }
}

/// A small curated set of habit icons (runtime IconData → needs
/// --no-tree-shake-icons, which the build flag already sets).
const _icons = <int>[
  0xe87d, // favorite
  0xe1a3, // fitness_center
  0xe566, // self_improvement
  0xe80c, // local_drink-ish
  0xe0c9, // book / menu_book
  0xe3ab, // brush
  0xe57f, // music_note
  0xe88a, // home
  0xe332, // code
  0xeb49, // bedtime
  0xe567, // directions_run
  0xe540, // restaurant
];

class _Editor extends ConsumerStatefulWidget {
  const _Editor({this.habit});
  final Habit? habit;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late int _iconCode;
  late int _colorValue;
  late HabitFrequency _frequency;
  late HabitDifficulty _difficulty;
  late int _target;
  String? _error;

  bool get _isEdit => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _name = TextEditingController(text: h?.name ?? '');
    _description = TextEditingController(text: h?.description ?? '');
    _iconCode = h?.iconCode ?? _icons.first;
    _colorValue = h?.colorValue ?? AppColors.habitPalette.first.toARGB32();
    _frequency = h?.frequency ?? HabitFrequency.daily;
    _difficulty = h?.difficulty ?? HabitDifficulty.medium;
    _target = h?.targetPerDay ?? 1;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give your habit a name.');
      return;
    }
    final ctrl = ref.read(habitsControllerProvider.notifier);
    final repo = ref.read(habitRepositoryProvider);
    if (_isEdit) {
      await ctrl.save(widget.habit!.copyWith(
        name: name,
        description: _description.text.trim(),
        iconCode: _iconCode,
        colorValue: _colorValue,
        frequency: _frequency,
        difficulty: _difficulty,
        targetPerDay: _target,
      ));
    } else {
      await ctrl.create(Habit(
        id: repo.newId(),
        name: name,
        description: _description.text.trim(),
        iconCode: _iconCode,
        colorValue: _colorValue,
        frequency: _frequency,
        difficulty: _difficulty,
        targetPerDay: _target,
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
      ));
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref.read(habitsControllerProvider.notifier).delete(widget.habit!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.all(10),
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.86),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(_isEdit ? 'Edit habit' : 'New habit',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 18),
              TextField(
                controller: _name,
                style: const TextStyle(color: AppColors.text),
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                style: const TextStyle(color: AppColors.text),
                decoration: const InputDecoration(
                    labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 20),
              _label('Icon'),
              const SizedBox(height: 10),
              _iconPicker(),
              const SizedBox(height: 20),
              _label('Color'),
              const SizedBox(height: 10),
              _colorPicker(),
              const SizedBox(height: 20),
              _label('Frequency'),
              const SizedBox(height: 10),
              _chips<HabitFrequency>(
                values: HabitFrequency.values,
                selected: _frequency,
                label: (f) => f.label,
                onTap: (f) => setState(() => _frequency = f),
              ),
              const SizedBox(height: 20),
              _label('Difficulty'),
              const SizedBox(height: 10),
              _chips<HabitDifficulty>(
                values: HabitDifficulty.values,
                selected: _difficulty,
                label: (d) => '${d.label} · ${d.xp} XP',
                onTap: (d) => setState(() => _difficulty = d),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              GlowButton(
                label: _isEdit ? 'Save changes' : 'Create habit',
                icon: Icons.check_rounded,
                expand: true,
                onPressed: _save,
              ),
              if (_isEdit) ...[
                const SizedBox(height: 10),
                GlowButton(
                  label: 'Delete habit',
                  icon: Icons.delete_outline_rounded,
                  variant: GlowButtonVariant.ghost,
                  color: AppColors.danger,
                  expand: true,
                  onPressed: _delete,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600));

  Widget _iconPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _icons.map((code) {
        final selected = code == _iconCode;
        final color = Color(_colorValue);
        return GestureDetector(
          onTap: () => setState(() => _iconCode = code),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.alpha(color, 0.18)
                  : AppColors.alpha(Colors.white, 0.03),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                  color: selected ? color : AppColors.border,
                  width: selected ? 1.5 : 1),
            ),
            child: Icon(
              // ignore: non_const_argument_for_const_parameter
              IconData(code, fontFamily: 'MaterialIcons'),
              color: selected ? color : AppColors.muted,
              size: 22,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _colorPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppColors.habitPalette.map((c) {
        final v = c.toARGB32();
        final selected = v == _colorValue;
        return GestureDetector(
          onTap: () => setState(() => _colorValue = v),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                  color: selected ? Colors.white : Colors.transparent,
                  width: 2),
            ),
            child: selected
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _chips<T>({
    required List<T> values,
    required T selected,
    required String Function(T) label,
    required ValueChanged<T> onTap,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) {
        final isSel = v == selected;
        return GestureDetector(
          onTap: () => onTap(v),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSel
                  ? AppColors.alpha(AppColors.primary, 0.14)
                  : AppColors.alpha(Colors.white, 0.03),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                  color: isSel ? AppColors.primary : AppColors.border),
            ),
            child: Text(
              label(v),
              style: TextStyle(
                fontSize: 13,
                color: isSel ? AppColors.primary : AppColors.muted,
                fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
