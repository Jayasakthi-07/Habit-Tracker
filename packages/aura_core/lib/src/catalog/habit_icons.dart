import 'package:flutter/material.dart';

/// The single shared set of habit icons used by **both** the Windows and Android
/// habit editors, so the same habit shows the same glyph everywhere.
///
/// Icons are stored on a habit as their `codePoint` (an int) and rendered at
/// runtime via `IconData(codePoint, fontFamily: 'MaterialIcons')`, so the apps
/// must be built with `--no-tree-shake-icons` (already the project default).
const List<IconData> kHabitIconChoices = <IconData>[
  Icons.favorite_rounded,
  Icons.fitness_center_rounded,
  Icons.directions_run_rounded,
  Icons.directions_walk_rounded,
  Icons.pedal_bike_rounded,
  Icons.sports_basketball_rounded,
  Icons.sports_soccer_rounded,
  Icons.pool_rounded,
  Icons.self_improvement_rounded,
  Icons.spa_rounded,
  Icons.menu_book_rounded,
  Icons.school_rounded,
  Icons.code_rounded,
  Icons.work_rounded,
  Icons.edit_note_rounded,
  Icons.lightbulb_rounded,
  Icons.psychology_rounded,
  Icons.water_drop_rounded,
  Icons.local_drink_rounded,
  Icons.restaurant_rounded,
  Icons.local_cafe_rounded,
  Icons.bedtime_rounded,
  Icons.nightlight_rounded,
  Icons.sunny,
  Icons.alarm_rounded,
  Icons.brush_rounded,
  Icons.music_note_rounded,
  Icons.camera_alt_rounded,
  Icons.savings_rounded,
  Icons.attach_money_rounded,
  Icons.translate_rounded,
  Icons.eco_rounded,
  Icons.cleaning_services_rounded,
  Icons.pets_rounded,
  Icons.smoke_free_rounded,
  Icons.medication_rounded,
  Icons.phone_iphone_rounded,
  Icons.volunteer_activism_rounded,
];

/// Resolves a stored habit icon code into a renderable [IconData].
IconData habitIconFor(int codePoint) =>
    // ignore: non_const_argument_for_const_parameter
    IconData(codePoint, fontFamily: 'MaterialIcons');
