import 'package:flutter/material.dart';

/// Metric keys an app must supply to evaluate achievements. Keeping them as
/// string constants means the **catalog lives once in aura_core** and both the
/// Windows and Android apps evaluate the exact same 70+ achievements — they only
/// differ in how they compute these numbers from local data.
abstract class AchMetric {
  static const habits = 'habits'; // habits created (incl. archived)
  static const bestStreak = 'bestStreak'; // best streak across all habits
  static const currentStreak = 'currentStreak'; // best *current* streak
  static const completed = 'completed'; // total completed logs
  static const level = 'level'; // gamification level
  static const xp = 'xp'; // total XP
  static const activeDays = 'activeDays'; // days with any completion
  static const perfectDays = 'perfectDays'; // days all scheduled habits done
  static const categories = 'categories'; // distinct categories used
  static const goals = 'goals'; // goals created
  static const goalsDone = 'goalsDone'; // goals completed
  static const journal = 'journal'; // journal entries written
  static const successPct = 'successPct'; // overall success rate, 0..100
}

/// A static achievement definition (one source of truth, shared by both apps).
class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.metric,
    required this.threshold,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String metric;
  final num threshold;
}

/// An evaluated achievement: a [def] plus the user's unlock state and progress.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.unlocked,
    required this.progress,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool unlocked;
  final double progress; // 0..1
}

const _green = Color(0xFF00FF88);
const _cyan = Color(0xFF00D4FF);
const _gold = Color(0xFFFFC857);
const _pink = Color(0xFFFF5A6E);
const _violet = Color(0xFFB388FF);
const _orange = Color(0xFFFF8A65);
const _teal = Color(0xFF4DD0E1);
const _lime = Color(0xFFAED581);

/// The master list — 70+ achievements across streaks, completions, levels,
/// variety, consistency, goals and journaling.
const List<AchievementDef> kAchievementDefs = <AchievementDef>[
  // ---- Getting started ----
  AchievementDef(
      id: 'first_habit',
      title: 'First Step',
      description: 'Create your first habit',
      icon: Icons.flag_rounded,
      color: _green,
      metric: AchMetric.habits,
      threshold: 1),
  AchievementDef(
      id: 'first_done',
      title: 'Day One',
      description: 'Complete a habit for the first time',
      icon: Icons.check_circle_rounded,
      color: _green,
      metric: AchMetric.completed,
      threshold: 1),
  AchievementDef(
      id: 'first_journal',
      title: 'Dear Diary',
      description: 'Write your first journal entry',
      icon: Icons.menu_book_rounded,
      color: _violet,
      metric: AchMetric.journal,
      threshold: 1),
  AchievementDef(
      id: 'first_goal',
      title: 'Dream Big',
      description: 'Set your first goal',
      icon: Icons.outlined_flag_rounded,
      color: _cyan,
      metric: AchMetric.goals,
      threshold: 1),

  // ---- Best streak ----
  AchievementDef(id: 'streak_3', title: 'Getting Going', description: 'Reach a 3-day streak', icon: Icons.local_fire_department_rounded, color: _gold, metric: AchMetric.bestStreak, threshold: 3),
  AchievementDef(id: 'streak_7', title: 'Week Warrior', description: 'Reach a 7-day streak', icon: Icons.local_fire_department_rounded, color: _gold, metric: AchMetric.bestStreak, threshold: 7),
  AchievementDef(id: 'streak_14', title: 'Fortnight', description: 'Reach a 14-day streak', icon: Icons.local_fire_department_rounded, color: _gold, metric: AchMetric.bestStreak, threshold: 14),
  AchievementDef(id: 'streak_21', title: 'Habit Formed', description: 'Reach a 21-day streak', icon: Icons.local_fire_department_rounded, color: _orange, metric: AchMetric.bestStreak, threshold: 21),
  AchievementDef(id: 'streak_30', title: 'Monthly Master', description: 'Reach a 30-day streak', icon: Icons.local_fire_department_rounded, color: _orange, metric: AchMetric.bestStreak, threshold: 30),
  AchievementDef(id: 'streak_60', title: 'Two Months Strong', description: 'Reach a 60-day streak', icon: Icons.whatshot_rounded, color: _orange, metric: AchMetric.bestStreak, threshold: 60),
  AchievementDef(id: 'streak_100', title: 'Centurion', description: 'Reach a 100-day streak', icon: Icons.whatshot_rounded, color: _pink, metric: AchMetric.bestStreak, threshold: 100),
  AchievementDef(id: 'streak_150', title: 'Unbreakable', description: 'Reach a 150-day streak', icon: Icons.bolt_rounded, color: _pink, metric: AchMetric.bestStreak, threshold: 150),
  AchievementDef(id: 'streak_180', title: 'Half-Year Hero', description: 'Reach a 180-day streak', icon: Icons.bolt_rounded, color: _pink, metric: AchMetric.bestStreak, threshold: 180),
  AchievementDef(id: 'streak_270', title: 'Relentless', description: 'Reach a 270-day streak', icon: Icons.flash_on_rounded, color: _violet, metric: AchMetric.bestStreak, threshold: 270),
  AchievementDef(id: 'streak_365', title: 'Year of You', description: 'Reach a 365-day streak', icon: Icons.military_tech_rounded, color: _violet, metric: AchMetric.bestStreak, threshold: 365),

  // ---- Current streak (live) ----
  AchievementDef(id: 'cur_3', title: 'On a Roll', description: 'Hold a 3-day active streak', icon: Icons.trending_up_rounded, color: _green, metric: AchMetric.currentStreak, threshold: 3),
  AchievementDef(id: 'cur_7', title: 'In the Zone', description: 'Hold a 7-day active streak', icon: Icons.trending_up_rounded, color: _green, metric: AchMetric.currentStreak, threshold: 7),
  AchievementDef(id: 'cur_30', title: 'Locked In', description: 'Hold a 30-day active streak', icon: Icons.lock_clock_rounded, color: _teal, metric: AchMetric.currentStreak, threshold: 30),
  AchievementDef(id: 'cur_100', title: 'Momentum Machine', description: 'Hold a 100-day active streak', icon: Icons.rocket_launch_rounded, color: _teal, metric: AchMetric.currentStreak, threshold: 100),

  // ---- Total completions ----
  AchievementDef(id: 'done_10', title: 'Perfect Ten', description: 'Complete 10 habits total', icon: Icons.done_all_rounded, color: _green, metric: AchMetric.completed, threshold: 10),
  AchievementDef(id: 'done_25', title: 'Quarter Century', description: 'Complete 25 habits total', icon: Icons.done_all_rounded, color: _green, metric: AchMetric.completed, threshold: 25),
  AchievementDef(id: 'done_50', title: 'Half Ton', description: 'Complete 50 habits total', icon: Icons.done_all_rounded, color: _cyan, metric: AchMetric.completed, threshold: 50),
  AchievementDef(id: 'done_100', title: 'Hundred Club', description: 'Complete 100 habits total', icon: Icons.workspace_premium_rounded, color: _cyan, metric: AchMetric.completed, threshold: 100),
  AchievementDef(id: 'done_250', title: 'Dedicated', description: 'Complete 250 habits total', icon: Icons.workspace_premium_rounded, color: _gold, metric: AchMetric.completed, threshold: 250),
  AchievementDef(id: 'done_500', title: 'Habit Veteran', description: 'Complete 500 habits total', icon: Icons.shield_rounded, color: _gold, metric: AchMetric.completed, threshold: 500),
  AchievementDef(id: 'done_1000', title: 'Legend', description: 'Complete 1,000 habits total', icon: Icons.emoji_events_rounded, color: _pink, metric: AchMetric.completed, threshold: 1000),
  AchievementDef(id: 'done_2000', title: 'Mythic', description: 'Complete 2,000 habits total', icon: Icons.diamond_rounded, color: _violet, metric: AchMetric.completed, threshold: 2000),

  // ---- Level ----
  AchievementDef(id: 'lvl_2', title: 'Level Up', description: 'Reach level 2', icon: Icons.arrow_circle_up_rounded, color: _green, metric: AchMetric.level, threshold: 2),
  AchievementDef(id: 'lvl_3', title: 'Climbing', description: 'Reach level 3', icon: Icons.arrow_circle_up_rounded, color: _green, metric: AchMetric.level, threshold: 3),
  AchievementDef(id: 'lvl_5', title: 'Rising Star', description: 'Reach level 5', icon: Icons.star_rounded, color: _gold, metric: AchMetric.level, threshold: 5),
  AchievementDef(id: 'lvl_10', title: 'Seasoned', description: 'Reach level 10', icon: Icons.star_rounded, color: _gold, metric: AchMetric.level, threshold: 10),
  AchievementDef(id: 'lvl_15', title: 'Expert', description: 'Reach level 15', icon: Icons.stars_rounded, color: _cyan, metric: AchMetric.level, threshold: 15),
  AchievementDef(id: 'lvl_20', title: 'Master', description: 'Reach level 20', icon: Icons.stars_rounded, color: _cyan, metric: AchMetric.level, threshold: 20),
  AchievementDef(id: 'lvl_30', title: 'Grandmaster', description: 'Reach level 30', icon: Icons.auto_awesome_rounded, color: _pink, metric: AchMetric.level, threshold: 30),
  AchievementDef(id: 'lvl_50', title: 'Ascended', description: 'Reach level 50', icon: Icons.auto_awesome_rounded, color: _violet, metric: AchMetric.level, threshold: 50),

  // ---- XP ----
  AchievementDef(id: 'xp_100', title: 'First 100 XP', description: 'Earn 100 XP', icon: Icons.bolt_rounded, color: _green, metric: AchMetric.xp, threshold: 100),
  AchievementDef(id: 'xp_500', title: 'XP Hunter', description: 'Earn 500 XP', icon: Icons.bolt_rounded, color: _cyan, metric: AchMetric.xp, threshold: 500),
  AchievementDef(id: 'xp_1000', title: 'XP Machine', description: 'Earn 1,000 XP', icon: Icons.electric_bolt_rounded, color: _gold, metric: AchMetric.xp, threshold: 1000),
  AchievementDef(id: 'xp_5000', title: 'XP Overlord', description: 'Earn 5,000 XP', icon: Icons.electric_bolt_rounded, color: _violet, metric: AchMetric.xp, threshold: 5000),

  // ---- Habits created / variety ----
  AchievementDef(id: 'habits_3', title: 'Triple Threat', description: 'Track 3 habits', icon: Icons.dashboard_customize_rounded, color: _green, metric: AchMetric.habits, threshold: 3),
  AchievementDef(id: 'habits_5', title: 'Collector', description: 'Track 5 habits', icon: Icons.dashboard_customize_rounded, color: _cyan, metric: AchMetric.habits, threshold: 5),
  AchievementDef(id: 'habits_10', title: 'Juggler', description: 'Track 10 habits', icon: Icons.apps_rounded, color: _gold, metric: AchMetric.habits, threshold: 10),
  AchievementDef(id: 'habits_15', title: 'Habit Architect', description: 'Track 15 habits', icon: Icons.account_tree_rounded, color: _orange, metric: AchMetric.habits, threshold: 15),
  AchievementDef(id: 'habits_25', title: 'Life Designer', description: 'Track 25 habits', icon: Icons.account_tree_rounded, color: _pink, metric: AchMetric.habits, threshold: 25),
  AchievementDef(id: 'cat_3', title: 'Well Rounded', description: 'Use 3 categories', icon: Icons.category_rounded, color: _teal, metric: AchMetric.categories, threshold: 3),
  AchievementDef(id: 'cat_5', title: 'Balanced Life', description: 'Use 5 categories', icon: Icons.category_rounded, color: _teal, metric: AchMetric.categories, threshold: 5),
  AchievementDef(id: 'cat_8', title: 'Renaissance', description: 'Use 8 categories', icon: Icons.diversity_3_rounded, color: _lime, metric: AchMetric.categories, threshold: 8),
  AchievementDef(id: 'cat_12', title: 'Polymath', description: 'Use 12 categories', icon: Icons.diversity_3_rounded, color: _lime, metric: AchMetric.categories, threshold: 12),

  // ---- Active days ----
  AchievementDef(id: 'active_7', title: 'Showing Up', description: 'Be active on 7 days', icon: Icons.calendar_today_rounded, color: _green, metric: AchMetric.activeDays, threshold: 7),
  AchievementDef(id: 'active_14', title: 'Regular', description: 'Be active on 14 days', icon: Icons.calendar_today_rounded, color: _green, metric: AchMetric.activeDays, threshold: 14),
  AchievementDef(id: 'active_30', title: 'Committed', description: 'Be active on 30 days', icon: Icons.event_available_rounded, color: _cyan, metric: AchMetric.activeDays, threshold: 30),
  AchievementDef(id: 'active_60', title: 'Devoted', description: 'Be active on 60 days', icon: Icons.event_available_rounded, color: _cyan, metric: AchMetric.activeDays, threshold: 60),
  AchievementDef(id: 'active_90', title: 'Quarter Strong', description: 'Be active on 90 days', icon: Icons.event_available_rounded, color: _gold, metric: AchMetric.activeDays, threshold: 90),
  AchievementDef(id: 'active_180', title: 'Half-Year Habit', description: 'Be active on 180 days', icon: Icons.calendar_month_rounded, color: _pink, metric: AchMetric.activeDays, threshold: 180),
  AchievementDef(id: 'active_365', title: 'All Year Round', description: 'Be active on 365 days', icon: Icons.calendar_month_rounded, color: _violet, metric: AchMetric.activeDays, threshold: 365),

  // ---- Perfect days ----
  AchievementDef(id: 'perfect_1', title: 'Flawless', description: 'Complete every habit in a day', icon: Icons.verified_rounded, color: _green, metric: AchMetric.perfectDays, threshold: 1),
  AchievementDef(id: 'perfect_5', title: 'Spotless Five', description: '5 perfect days', icon: Icons.verified_rounded, color: _cyan, metric: AchMetric.perfectDays, threshold: 5),
  AchievementDef(id: 'perfect_10', title: 'Perfectionist', description: '10 perfect days', icon: Icons.verified_rounded, color: _gold, metric: AchMetric.perfectDays, threshold: 10),
  AchievementDef(id: 'perfect_25', title: 'Immaculate', description: '25 perfect days', icon: Icons.auto_awesome_rounded, color: _orange, metric: AchMetric.perfectDays, threshold: 25),
  AchievementDef(id: 'perfect_50', title: 'Untouchable', description: '50 perfect days', icon: Icons.auto_awesome_rounded, color: _pink, metric: AchMetric.perfectDays, threshold: 50),
  AchievementDef(id: 'perfect_100', title: 'Centified', description: '100 perfect days', icon: Icons.workspace_premium_rounded, color: _violet, metric: AchMetric.perfectDays, threshold: 100),

  // ---- Success rate ----
  AchievementDef(id: 'rate_50', title: 'Halfway There', description: 'Reach 50% overall success', icon: Icons.percent_rounded, color: _green, metric: AchMetric.successPct, threshold: 50),
  AchievementDef(id: 'rate_75', title: 'Consistent', description: 'Reach 75% overall success', icon: Icons.percent_rounded, color: _cyan, metric: AchMetric.successPct, threshold: 75),
  AchievementDef(id: 'rate_90', title: 'Elite', description: 'Reach 90% overall success', icon: Icons.trending_up_rounded, color: _gold, metric: AchMetric.successPct, threshold: 90),
  AchievementDef(id: 'rate_100', title: 'Perfection', description: 'Reach 100% overall success', icon: Icons.emoji_events_rounded, color: _violet, metric: AchMetric.successPct, threshold: 100),

  // ---- Goals ----
  AchievementDef(id: 'goals_3', title: 'Ambitious', description: 'Set 3 goals', icon: Icons.outlined_flag_rounded, color: _cyan, metric: AchMetric.goals, threshold: 3),
  AchievementDef(id: 'goals_5', title: 'Visionary', description: 'Set 5 goals', icon: Icons.outlined_flag_rounded, color: _teal, metric: AchMetric.goals, threshold: 5),
  AchievementDef(id: 'goals_10', title: 'Mastermind', description: 'Set 10 goals', icon: Icons.flag_circle_rounded, color: _lime, metric: AchMetric.goals, threshold: 10),
  AchievementDef(id: 'goaldone_1', title: 'Goal Getter', description: 'Complete a goal', icon: Icons.task_alt_rounded, color: _green, metric: AchMetric.goalsDone, threshold: 1),
  AchievementDef(id: 'goaldone_3', title: 'Closer', description: 'Complete 3 goals', icon: Icons.task_alt_rounded, color: _gold, metric: AchMetric.goalsDone, threshold: 3),
  AchievementDef(id: 'goaldone_10', title: 'Finisher', description: 'Complete 10 goals', icon: Icons.emoji_events_rounded, color: _pink, metric: AchMetric.goalsDone, threshold: 10),

  // ---- Journal ----
  AchievementDef(id: 'journal_7', title: 'Reflective', description: 'Write 7 journal entries', icon: Icons.edit_note_rounded, color: _violet, metric: AchMetric.journal, threshold: 7),
  AchievementDef(id: 'journal_30', title: 'Storyteller', description: 'Write 30 journal entries', icon: Icons.edit_note_rounded, color: _violet, metric: AchMetric.journal, threshold: 30),
  AchievementDef(id: 'journal_60', title: 'Chronicler', description: 'Write 60 journal entries', icon: Icons.history_edu_rounded, color: _orange, metric: AchMetric.journal, threshold: 60),
  AchievementDef(id: 'journal_100', title: 'Memoirist', description: 'Write 100 journal entries', icon: Icons.history_edu_rounded, color: _pink, metric: AchMetric.journal, threshold: 100),
];

/// Evaluates the whole catalog against a [metrics] snapshot. Unlocked when the
/// metric meets the threshold; progress is the ratio toward it (0..1).
List<Achievement> evaluateAchievements(Map<String, num> metrics) {
  return kAchievementDefs.map((def) {
    final value = metrics[def.metric] ?? 0;
    final ratio = def.threshold == 0
        ? 1.0
        : (value / def.threshold).clamp(0, 1).toDouble();
    return Achievement(
      id: def.id,
      title: def.title,
      description: def.description,
      icon: def.icon,
      color: def.color,
      unlocked: value >= def.threshold,
      progress: ratio,
    );
  }).toList();
}

/// Count of unlocked achievements for a [metrics] snapshot.
int unlockedAchievementCount(Map<String, num> metrics) =>
    evaluateAchievements(metrics).where((a) => a.unlocked).length;
