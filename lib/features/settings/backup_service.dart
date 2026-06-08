import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/storage/hive_service.dart';

/// Backs up and restores all user data to/from a single JSON file.
///
/// Covers habits, logs, goals and journal entries — enough to fully migrate a
/// user's data to another machine.
class BackupService {
  BackupService._();
  static final instance = BackupService._();

  static const _dataBoxes = [Boxes.habits, Boxes.logs, Boxes.goals, Boxes.journal];

  Future<String> backup() async {
    final payload = <String, dynamic>{
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
    };
    for (final name in _dataBoxes) {
      final box = HiveService.box(name);
      payload[name] = {
        for (final key in box.keys) key.toString(): HiveService.cast(box.get(key)!),
      };
    }

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/AuraHabits Backups');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/aura_backup_$stamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file.path;
  }

  /// Restores from [path]. Returns the number of records imported.
  Future<int> restore(String path) async {
    final file = File(path);
    if (!file.existsSync()) throw 'Backup file not found';
    final payload = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

    var count = 0;
    for (final name in _dataBoxes) {
      final data = payload[name];
      if (data is! Map) continue;
      final box = HiveService.box(name);
      await box.clear();
      for (final entry in data.entries) {
        await box.put(entry.key, Map<String, dynamic>.from(entry.value as Map));
        count++;
      }
    }
    return count;
  }

  /// Most recent backup file, if any (for quick restore).
  Future<File?> latestBackup() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/AuraHabits Backups');
    if (!dir.existsSync()) return null;
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files.isEmpty ? null : files.first;
  }
}
