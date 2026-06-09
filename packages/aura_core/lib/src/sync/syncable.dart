/// Contract for any local entity that can be mirrored to the cloud.
///
/// The existing domain models (Habit, HabitLog, Goal, …) already expose
/// `id` and `toJson()`, so they can adopt this with a tiny addition. The sync
/// engine stores [toJson] into the Supabase `data` column and uses [id] as the
/// row key.
abstract interface class Syncable {
  /// Stable unique key (uuid, or a composite like "habitId|date" for logs).
  String get id;

  /// Full serialized payload stored in the `data` jsonb column.
  Map<String, dynamic> toJson();
}

/// A row as represented in a synced Supabase table.
class SyncRecord {
  const SyncRecord({
    required this.id,
    required this.data,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final Map<String, dynamic> data;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  factory SyncRecord.fromRow(Map<String, dynamic> row) => SyncRecord(
        id: row['id'] as String,
        data: (row['data'] as Map?)?.cast<String, dynamic>() ?? const {},
        updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
        deletedAt: row['deleted_at'] != null
            ? DateTime.parse(row['deleted_at'] as String).toUtc()
            : null,
      );
}
