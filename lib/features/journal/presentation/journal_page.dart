import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_x.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glow_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../journal_provider.dart';

class JournalPage extends ConsumerStatefulWidget {
  const JournalPage({super.key});

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage> {
  final _text = TextEditingController();
  Mood _mood = Mood.okay;
  bool _loaded = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _hydrate() {
    if (_loaded) return;
    final today = ref.read(journalProvider.notifier).entryFor(DateTime.now());
    if (today != null) {
      _text.text = today.text;
      _mood = today.mood;
    }
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    _hydrate();
    final entries = ref.watch(journalProvider);

    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Journal & Mood',
            subtitle: 'Reflect on your day and track how you feel',
            icon: Icons.menu_book_rounded,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _todayEditor()),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: _MoodInsights(entries: entries)),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Past Entries', icon: Icons.history_rounded),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('No journal entries yet.', style: TextStyle(color: AppColors.muted))),
            )
          else
            for (var i = 0; i < entries.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EntryCard(entry: entries[i])
                    .animate()
                    .fadeIn(delay: (30 * i).ms)
                    .slideX(begin: 0.04),
              ),
        ],
      ),
    );
  }

  Widget _todayEditor() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How are you feeling today?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final m in Mood.values)
                GestureDetector(
                  onTap: () => setState(() => _mood = m),
                  child: AnimatedContainer(
                    duration: AppSpacing.fast,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _mood == m ? AppColors.alpha(m.color, 0.18) : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _mood == m ? m.color : AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Text(m.emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Text(m.label, style: TextStyle(fontSize: 10, color: _mood == m ? m.color : AppColors.muted)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _text,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Write a reflection about your day, wins, and challenges…',
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: GlowButton(
              label: 'Save entry',
              icon: Icons.check_rounded,
              onPressed: () {
                ref.read(journalProvider.notifier).save(DateTime.now(), _mood, _text.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Color(0xFF1C1C1C),
                    content: Text('Journal saved', style: TextStyle(color: Colors.white)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodInsights extends StatelessWidget {
  const _MoodInsights({required this.entries});
  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    final avg = entries.isEmpty
        ? 0.0
        : entries.map((e) => e.mood.score).reduce((a, b) => a + b) / entries.length;
    final avgMood = Mood.fromScore(avg.round().clamp(1, 5));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Mood Insights', icon: Icons.insights_rounded),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(entries.isEmpty ? '—' : avgMood.emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entries.isEmpty ? 'No data' : 'Average: ${avgMood.label}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('${entries.length} entries logged', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Recent mood strip.
          Row(
            children: [
              for (final e in entries.take(14).toList().reversed)
                Expanded(
                  child: Tooltip(
                    message: '${e.date.pretty}: ${e.mood.label}',
                    child: Container(
                      height: 8 + e.mood.score * 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: e.mood.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends ConsumerWidget {
  const _EntryCard({required this.entry});
  final JournalEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.mood.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(entry.date.pretty, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 10),
                    Text(entry.mood.label, style: TextStyle(color: entry.mood.color, fontSize: 12)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => ref.read(journalProvider.notifier).delete(entry.date),
                      child: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.muted),
                    ),
                  ],
                ),
                if (entry.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(entry.text, style: const TextStyle(color: AppColors.muted, height: 1.5)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
