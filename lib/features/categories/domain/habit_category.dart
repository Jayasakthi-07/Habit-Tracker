import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A habit category. Built-in categories are predefined; users may add custom
/// ones (persisted via the same model with [isCustom] = true).
class HabitCategory {
  const HabitCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isCustom;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCode': icon.codePoint,
        'color': color.toARGB32(),
        'isCustom': isCustom,
      };

  factory HabitCategory.fromJson(Map<String, dynamic> json) => HabitCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        // ignore: non_const_argument_for_const_parameter
        icon: IconData(json['iconCode'] as int, fontFamily: 'MaterialIcons'),
        color: Color(json['color'] as int),
        isCustom: json['isCustom'] as bool? ?? true,
      );
}

/// The 14 built-in categories required by the product spec.
abstract class BuiltInCategories {
  static const List<HabitCategory> all = [
    HabitCategory(id: 'health', name: 'Health', icon: Icons.favorite_rounded, color: Color(0xFFFF5A6E)),
    HabitCategory(id: 'fitness', name: 'Fitness', icon: Icons.fitness_center_rounded, color: Color(0xFF00FF88)),
    HabitCategory(id: 'reading', name: 'Reading', icon: Icons.menu_book_rounded, color: Color(0xFFFFC857)),
    HabitCategory(id: 'productivity', name: 'Productivity', icon: Icons.bolt_rounded, color: Color(0xFF00D4FF)),
    HabitCategory(id: 'work', name: 'Work', icon: Icons.work_rounded, color: Color(0xFF9575CD)),
    HabitCategory(id: 'study', name: 'Study', icon: Icons.school_rounded, color: Color(0xFF4DD0E1)),
    HabitCategory(id: 'sleep', name: 'Sleep', icon: Icons.bedtime_rounded, color: Color(0xFFB388FF)),
    HabitCategory(id: 'meditation', name: 'Meditation', icon: Icons.self_improvement_rounded, color: Color(0xFFAED581)),
    HabitCategory(id: 'diet', name: 'Diet', icon: Icons.restaurant_rounded, color: Color(0xFFFF8A65)),
    HabitCategory(id: 'finance', name: 'Finance', icon: Icons.savings_rounded, color: Color(0xFF00FF88)),
    HabitCategory(id: 'language', name: 'Language', icon: Icons.translate_rounded, color: Color(0xFF00D4FF)),
    HabitCategory(id: 'creativity', name: 'Creativity', icon: Icons.palette_rounded, color: Color(0xFFF06292)),
    HabitCategory(id: 'spiritual', name: 'Spiritual', icon: Icons.spa_rounded, color: Color(0xFFAED581)),
    HabitCategory(id: 'personal_care', name: 'Personal Care', icon: Icons.spa_outlined, color: Color(0xFFFFC857)),
  ];

  static HabitCategory byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => fallback);

  static const HabitCategory fallback = HabitCategory(
    id: 'other',
    name: 'Other',
    icon: Icons.category_rounded,
    color: AppColors.muted,
  );
}
