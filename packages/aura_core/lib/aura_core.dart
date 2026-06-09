/// Aura Core — shared backbone for the Aura Habit Tracker desktop & mobile apps.
///
/// Holds the Supabase client, cloud-sync engine, AI providers, and any business
/// logic that must behave identically across platforms. Grown incrementally so
/// the working Windows app is never broken.
library;

export 'src/config/supabase_config.dart';
export 'src/supabase/aura_supabase.dart';
export 'src/sync/sync_entity.dart';
export 'src/sync/syncable.dart';
