/// The set of cloud-synced entity types.
///
/// Each value maps to a Supabase table created by `supabase/migrations`. Every
/// such table shares the same shape (`id, user_id, data, updated_at, deleted_at`)
/// so the [SyncEngine] can treat them uniformly.
enum SyncEntity {
  habits('habits'),
  habitLogs('habit_logs'),
  categories('categories'),
  goals('goals'),
  journalEntries('journal_entries'),
  achievements('achievements'),
  settings('settings'),
  gamification('gamification');

  const SyncEntity(this.table);

  /// The Postgres/Supabase table name.
  final String table;

  /// Whether this entity is a per-user singleton (one row keyed by the user id),
  /// as opposed to a collection of independently-keyed records.
  bool get isSingleton =>
      this == SyncEntity.settings || this == SyncEntity.gamification;
}
