# aura_core

Shared backbone for the **Aura Habit Tracker** desktop (Windows) and mobile
(Android) apps. Consumed by both via a `path:` dependency so behavior stays
identical across platforms.

## Responsibilities (grown incrementally, phase by phase)
- **Supabase** client init + access (`AuraSupabase`, `SupabaseConfig`).
- **Cloud sync** engine: offline-first, Realtime, last-write-wins, tombstones
  (`SyncEntity`, `Syncable`, `SyncRecord`, … more added in Phase 2).
- **Auth** (Phase 1), **AI providers** (Phase 7), and shared domain logic.

## Configuration
Credentials are injected with `--dart-define` (never committed):

```
--dart-define=SUPABASE_URL=https://<project>.supabase.co
--dart-define=SUPABASE_ANON_KEY=<anon public key>
```

If unset, the app runs fully offline (existing single-device experience).
