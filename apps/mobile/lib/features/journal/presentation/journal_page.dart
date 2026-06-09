import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_x.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glow_button.dart';
import '../journal_provider.dart';

/// The "Journal" tab: log today's mood + a note, and browse past entries.
/// Data lives in the synced `journal` box.
class JournalPage extends ConsumerStatefulWidget {
  const JournalPage({super.key});

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage> {
  final _text = TextEditingController();
  Mood? _mood;
  bool _seeded = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _seedToday() {
    if (_seeded) return;
    final today = ref.read(journalProvider.notifier).entryFor(DateTime.now());
    if (today != null) {
      _mood = today.mood;
      _text.text = today.text;
    }
    _seeded = true;
  }

  Future<void> _save() async {
    final mood = _mood;
    if (mood == null) return;
    await ref
        .read(journalProvider.notifier)
        .save(DateTime.now(), mood, _text.text.trim());
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Journal saved'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _seedToday();
    final entries = ref.watch(journalProvider);
    final avg = ref.read(journalProvider.notifier).averageMood;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Row(
            children: [
              Text('Journal',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              if (avg > 0)
                Row(
                  children: [
                    Text(Mood.fromScore(avg.round()).emoji,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text('avg ${avg.toStringAsFixed(1)}',
                        style: TextStyle(
                            color: AppColors.muted, fontSize: 13)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How are you today?',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: Mood.values.map((m) => _moodButton(m)).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _text,
                  maxLines: 3,
                  style: TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: 'Write a few words about your day…',
                    hintStyle: TextStyle(color: AppColors.faint),
                    filled: true,
                    fillColor: AppColors.alpha(Colors.white, 0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                GlowButton(
                  label: 'Save entry',
                  icon: Icons.check_rounded,
                  expand: true,
                  onPressed: _mood == null ? null : _save,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (entries.isNotEmpty) ...[
            Text('History', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...entries.map((e) => _entryTile(e)),
          ],
        ],
      ),
    );
  }

  Widget _moodButton(Mood m) {
    final sel = _mood == m;
    return GestureDetector(
      onTap: () => setState(() => _mood = m),
      child: AnimatedContainer(
        duration: AppSpacing.fast,
        width: 52,
        height: 60,
        decoration: BoxDecoration(
          color: sel ? AppColors.alpha(m.color, 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: sel ? m.color : AppColors.border, width: sel ? 1.5 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(m.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 2),
            Text(m.label,
                style: TextStyle(
                    color: sel ? m.color : AppColors.faint, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _entryTile(JournalEntry e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.alpha(e.mood.color, 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(e.mood.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(e.date.pretty,
                          style: TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text(e.mood.label,
                          style: TextStyle(color: e.mood.color, fontSize: 12)),
                    ],
                  ),
                  if (e.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(e.text,
                        style: TextStyle(
                            color: AppColors.muted, fontSize: 13, height: 1.4)),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: () => ref.read(journalProvider.notifier).delete(e.date),
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded,
                    size: 16, color: AppColors.faint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
