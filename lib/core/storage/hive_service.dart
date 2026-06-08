import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Names of the Hive boxes used across the app.
abstract class Boxes {
  static const habits = 'habits';
  static const logs = 'habit_logs';
  static const categories = 'categories';
  static const goals = 'goals';
  static const journal = 'journal';
  static const settings = 'settings';
  static const profile = 'profile';
  static const gamification = 'gamification';
}

/// Initialises Hive in a dedicated app-data directory and opens all boxes.
///
/// Boxes store plain JSON-compatible maps, so no generated type adapters are
/// required — this keeps the data layer simple and migration-friendly.
class HiveService {
  static Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    await Hive.initFlutter('${dir.path}/AuraHabits');

    await Future.wait([
      Hive.openBox<Map>(Boxes.habits),
      Hive.openBox<Map>(Boxes.logs),
      Hive.openBox<Map>(Boxes.categories),
      Hive.openBox<Map>(Boxes.goals),
      Hive.openBox<Map>(Boxes.journal),
      Hive.openBox(Boxes.settings),
      Hive.openBox(Boxes.profile),
      Hive.openBox(Boxes.gamification),
    ]);
  }

  static Box<Map> box(String name) => Hive.box<Map>(name);
  static Box dynBox(String name) => Hive.box(name);

  /// Casts a raw Hive map (which decodes as `Map<dynamic, dynamic>`) into the
  /// `Map<String, dynamic>` shape our `fromJson` factories expect.
  static Map<String, dynamic> cast(Map raw) => Map<String, dynamic>.from(raw);

  static Future<void> closeAll() => Hive.close();
}
