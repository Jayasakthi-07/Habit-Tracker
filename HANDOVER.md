# 🤝 AURA HABIT TRACKER — Project Handover (read me first)

> **You are the new Claude taking over this project mid-build.** Read this whole
> file before doing anything. It contains the complete vision, every decision the
> user has locked in, the full roadmap with status, the exact next steps, and the
> non-obvious gotchas learned the hard way. The previous session built Phases 0–2;
> your job is to continue **without losing any context, changing any decision, or
> dropping any requirement.**
>
> After reading, briefly confirm to the user that you understand the project and
> state what you'll do next (Phase 3). Keep the same tone: warm, concrete, and
> guide the (non-technical) user step-by-step whenever they must do manual setup.

---

## 1. What this project is (vision)

**Aura Habits** is a **premium, production-grade habit tracker** being built to the
quality bar of "what a $100M company would ship." Two clients share one backend:

- **Windows desktop app** (Flutter) — already built and polished; now cloud-backed.
- **Android app** (Flutter) — **not built yet; this is the next major phase.**
- **Supabase backend** — accounts, Postgres database, **real-time cloud sync**.

The headline promise: **complete a habit on your phone and it appears instantly on
Windows, and vice-versa** — offline-first, with everything (habits, streaks,
completion, goals, journal) synced and restored per account.

It must be visually stunning, smooth, clean (minimal glow — see §6), offline-first,
and reliable. Build patiently, **phase by phase, over weeks** — quality over speed.

---

## 2. Locked decisions — DO NOT change these

| Decision | Value |
|---|---|
| Platforms | **Android + Windows only. NO iOS.** (User is on Windows; iOS needs a Mac.) |
| Backend | **Supabase** (Auth + Postgres + Realtime + Storage + Edge Functions) |
| AI engine | Support **BOTH Google Gemini AND OpenAI** behind one provider interface, user-selectable (Phase 7) |
| Monetization | **Offline license keys only** — NO subscriptions / RevenueCat. Premium gated by license. A valid demo key is `AURA-LIFE-TIME-68C8`. |
| Auth methods | **Email + password with an email verification CODE**, **Google sign-in**. **NO GUEST MODE** (explicitly removed). |
| App name | "Aura Habits" / `AuraHabits.exe` (keep) |
| UI style | Dark, premium, glassmorphism, **minimal/subtle glow** (user disliked heavy glow), smooth animations |
| Repo | Single GitHub repo, branch `feature/cloud-platform`, commit + push every phase |
| Build flag | Always `--no-tree-shake-icons` (habits use runtime-selected `IconData`) |
| Secrets | Live in gitignored `env.json`, injected via `--dart-define-from-file=env.json`. **Never commit secrets.** |

**User's working style (important):** the user is **not very technical**. Whenever
they must do manual setup (Supabase, Google Cloud, SMTP, Play Console), give a
**clear, numbered, click-by-click guide** explaining *what*, *why*, and *how*.
After code changes, **build the release and launch it** so they can test. Always
commit + push. Don't skip features. Ask for credentials/keys when needed (with a
guide). Be patient and encouraging.

---

## 3. Current status at a glance

| Phase | Title | Status |
|---|---|---|
| 0 | Monorepo + Supabase foundation | ✅ DONE |
| 1 | Accounts & auth (email+code, Google) | ✅ DONE & verified |
| 2 | Cloud sync engine (offline-first + realtime) | ✅ DONE & verified end-to-end |
| — | Post-fixes: remove guest, per-account isolation, glow reduction, completion-UI redesign + crash fix | ✅ DONE |
| **3** | **Android app MVP** | ✅ DONE & verified — app at `apps/mobile/` on shared `aura_core`; auth + sync + MVP screens; cross-device sync verified live (signed in, completed a habit phone→cloud). Google sign-in still needs the user to do `apps/mobile/ANDROID_GOOGLE_AUTH_SETUP.md` (debug SHA-1 `E4:EC:3A:E4:3A:5F:C8:B7:85:93:EE:22:37:95:51:32:64:AB:3E:D4`) + hand back the Web client ID → `GOOGLE_WEB_CLIENT_ID` in env.json. |
| **4** | **Android feature parity** | ✅ DONE & verified — ported goals/journal/gamification/analytics/categories (byte-identical models). New tabs: **Insights** (level/XP, stats, 30-day fl_chart trend, success bars, achievements) + **Journal** (mood + note). **Goals** page (pushed) + **Calendar** (pushed, `standalone:true`) reachable from dashboard header + Profile. SyncController refreshes goals/journal on remote change. Verified on emulator. Remaining for full parity later: focus timer, categories management UI, export, AI (Phase 7). |
| **5** | **Advanced analytics & insights** | ✅ DONE (mobile) & verified — per-habit **detail page** (streak/best/total/success stats, 26-week contribution **heatmap**, **weekday performance** bars, recent activity); habit-card tap now opens detail (edit moved to detail app-bar). Insights tab gained a **7/30/90-day range selector**, overall **weekday performance**, and an all-habits heatmap. New repo methods (`habitHeatmap`, `weekdayPerformance`, `recentLogs`, `periodSuccess`, `overallWeekdayPerformance`) are derived-only (sync-safe). Desktop already had an analytics page; these enrich the mobile client. |
| **6** | **Social & sharing cards** | ✅ DONE (mobile) & verified — branded portrait **share cards** (Aura brand, focal stat, accent glow, stat row, footer) captured from a `RepaintBoundary` to high-res PNG and sent via the Android share sheet (`share_plus`). Entry points: habit detail (streak card), tap an unlocked **achievement**, and Insights **Share progress**. Verified: share sheet opens with the image + message. Files: `lib/features/share/share_service.dart`, `share_card_page.dart`. |
| 7 | AI coaching (Gemini + OpenAI) | ⬜ pending |
| 8 | UI/UX production polish | ⬜ pending (glow already reduced) |
| 9 | Gamification expansion (badges/challenges/leaderboards) | ⬜ pending |
| 10 | Notifications & smart scheduling (FCM) | ⬜ pending |
| 11 | Branding & Play Store readiness | ⬜ pending |
| 12 | Hardening & release | ⬜ pending |

The full approved roadmap also lives at
`C:\Users\jayas\.claude\plans\foamy-hatching-meadow.md` (same machine). The phase
list above is authoritative and unchanged.

---

## 4. Architecture (as actually built)

> ⚠️ Deviation from the original plan worth knowing: the plan described a full pub
> **workspace** with the desktop app moved to `apps/desktop`. To avoid breaking the
> working app, we did a **lighter** approach: the desktop app stays at the **repo
> root** (`lib/`), and shared code lives in a local package **`packages/aura_core`**
> consumed via a `path:` dependency. The **Android app should be a new Flutter
> project** (suggest `apps/mobile/`) that **also** path-depends on `aura_core`.

```
habittracker_windows/                 (repo root = the Windows app)
├── lib/                              # Windows desktop app (Flutter)
│   ├── main.dart                     # bootstrap: Hive, AuraSupabase.init(), window, tray
│   ├── app.dart                      # MaterialApp.router; keeps SyncController alive
│   ├── core/ (theme, router, storage/hive, window, config/google_auth_config)
│   ├── shared/widgets/               # GlassCard, GlowButton, ProgressRing, etc.
│   └── features/
│       ├── auth/                     # Supabase auth + login UI (no guest)
│       ├── sync/sync_controller.dart # starts/stops sync on auth + per-account isolation
│       ├── habits/ goals/ journal/ calendar/ analytics/ dashboard/
│       ├── gamification/ focus/ categories/ notifications/ export/ license/ settings/ shell/
├── packages/aura_core/              # SHARED package (desktop + future mobile)
│   └── lib/src/
│       ├── config/supabase_config.dart      # reads SUPABASE_URL/ANON_KEY from dart-define
│       ├── supabase/aura_supabase.dart      # AuraSupabase.init()/client/currentUser
│       ├── auth/auth_service.dart           # email/OTP/Google(idToken)/reset/signOut
│       └── sync/ sync_engine.dart, sync_manager.dart, sync_entity.dart, syncable.dart
├── supabase/
│   ├── migrations/0001_init.sql      # schema + RLS + realtime (idempotent)
│   ├── SETUP.md, GOOGLE_AUTH_SETUP.md, EMAIL_VERIFICATION.md, SMTP_SETUP.md
├── env.json                          # GITIGNORED — real Supabase + Google creds (persists on disk)
├── installer/AuraHabits.iss          # Inno Setup script (per-user install, signtool-ready)
└── HANDOVER.md                       # this file
```

**Patterns:** Clean architecture, feature-first, **MVVM with Riverpod**, GoRouter
(with a `ShellRoute` — see the navigator gotcha in §8), Hive for local storage
(plain JSON maps), offline-first.

---

## 5. Environment, build & git (how to run things)

- **Toolchain:** Flutter 3.44 stable, Dart 3.12, Windows 10/11, VS 2022 Desktop C++.
- **`env.json`** (repo root, **gitignored, already on disk** in this folder) holds:
  `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_DESKTOP_CLIENT_ID`,
  `GOOGLE_DESKTOP_CLIENT_SECRET`. Because you reopened the **same folder**, this
  file is already present — you don't need the user to re-send secrets. If it's ever
  missing, ask the user to paste the four values and recreate it.
- **Analyze:** `flutter analyze lib packages` (expect ~10 harmless info-level lints).
- **Build (release, with creds):**
  `flutter build windows --release --no-tree-shake-icons --dart-define-from-file=env.json`
  → output `build\windows\x64\runner\Release\AuraHabits.exe`.
- **Run it** so the user can test (PowerShell: launch the exe; confirm the process
  is alive). Close a running instance first: `Stop-Process -Name AuraHabits -Force`.
- **Installer:** `"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\AuraHabits.iss`
  → `installer\Output\AuraHabits-Setup.exe` (per-user, no UAC; unsigned until a cert exists).
- **Git:** remote `github.com/Jayasakthi-07/Habit-Tracker`, work on branch
  **`feature/cloud-platform`**. Commit with the user's co-author trailer and push
  after each logical change. (LF→CRLF warnings on commit are harmless.)

---

## 6. UI / glow guidance (user is specific about this)

The user found the original UI **too glowy/blurry**. We already reduced it; **keep
it minimal going forward**:
- `AppShadows.glow` default strength is now **0.16** (was 0.45), tight radius.
- `GlassCard` backdrop blur **8** (was 18), surface opacity **0.82** (was 0.55) → crisp.
- Ambient auras dimmed (~0.07–0.09 alpha); progress-ring glow blur 2.5.
- Use subtle, tight halos only. Prefer clarity over neon bloom.
Design tokens: primary `#00FF88`, secondary `#00D4FF`, bg `#0A0A0A`, surface
`#141414`, card `#1C1C1C`. See `lib/core/theme/`.

---

## 7. Backend (Supabase) — what is already configured

- **Project ref:** `qvjixjniytgwfrjlygtb` · URL `https://qvjixjniytgwfrjlygtb.supabase.co`.
  Anon key is in `env.json` (safe to ship; RLS protects data).
- **Schema** (`supabase/migrations/0001_init.sql`, already run): a `profiles` table
  (auto-created on signup) + **generic synced tables**: `habits`, `habit_logs`,
  `categories`, `goals`, `journal_entries`, `achievements`, `settings`,
  `gamification`. **Every synced table has the same shape:**
  `id text PK, user_id uuid, data jsonb, updated_at timestamptz, deleted_at timestamptz`.
  **RLS** = owner-only on all tables. **Realtime** publication includes them all.
  The Hive **box key = row `id`**, the box value (JSON map) = the `data` column.
- **Auth providers enabled:** Email (Confirm email ON, OTP) + Google.
  - **Email verification is an 8-DIGIT code** (Supabase default here). The email
    template was edited to include `{{ .Token }}` (see `supabase/EMAIL_VERIFICATION.md`).
  - **SMTP:** custom SMTP via **Gmail** (`smtp.gmail.com:587`, sender
    `aurahabittracker@gmail.com`, Gmail **App Password** stored in the Supabase
    dashboard — NOT in the repo). This works. (Resend/Brevo failed because sending
    *from* a `@gmail.com` address is blocked by DMARC; Gmail SMTP is DMARC-aligned.)
  - **Google:** desktop sign-in uses our loopback OAuth to get a Google **id_token**,
    then `AuthService.signInWithGoogleIdToken` → Supabase. The desktop OAuth **client
    IDs are in Supabase → Auth → Google → "Authorized Client IDs"**
    (`...7bl2jihc...` and `...nv9e56k5...`). For **Android**, you'll create a NEW
    Android OAuth client (needs the app's SHA-1) + a Web client — guide the user.
- A real account already exists & has synced data (e.g. user `jayasakthi.msi@gmail.com`
  with a `GYM` habit). Don't be surprised to see existing rows.

---

## 8. What's been completed — details & gotchas

### Phase 0 — Foundation ✅
- `packages/aura_core` created; `supabase_flutter`, `connectivity_plus`, `hive` deps.
- `AuraSupabase.init()` called in `main.dart` (safe no-op if unconfigured).
- SQL schema + RLS + realtime applied to the live project.

### Phase 1 — Auth ✅ (verified: user signs in via email-code and Google)
- `aura_core/.../auth/auth_service.dart`: `signUpWithEmail` (returns `AuthResponse`
  so we detect confirm-on vs off), `verifyEmailOtp`, `resendSignupCode`,
  `signInWithEmail`, `sendPasswordReset`, `signInWithGoogleIdToken`, `signOut`,
  `onAuthStateChange`.
- Desktop `features/auth/auth_provider.dart`: `AuthController` is Supabase-backed.
  `UserProfile` (no `isGuest`), Supabase session is the single source of truth;
  premium is a local flag (license). Google bridges via the existing loopback flow
  in `features/auth/google_auth_service.dart` (now also returns the `idToken`).
- `features/auth/presentation/login_page.dart`: multi-mode card
  (signIn / signUp / **verify-code (accepts up to 8 digits)** / forgot) + Google
  button. **Guest button removed.**

### Phase 2 — Cloud sync ✅ (verified end-to-end against real data)
- `aura_core/.../sync/sync_engine.dart` — per-box bidirectional sync:
  pull/reconcile on start, push on local Hive `box.watch()` change, **soft-delete
  tombstones**, Supabase **Realtime** cloud→local, and an **echo guard** via a
  per-id content "shadow" (last-synced JSON) so our own writes don't loop.
- `sync_manager.dart` — orchestrates one engine per box, connectivity-aware
  `flush()` on reconnect, `SyncStatus` + a `remoteChanges` stream.
- Desktop `features/sync/sync_controller.dart` — starts/stops sync on auth; maps
  the 5 collection boxes (habits, habit_logs, categories, goals, journal); routes
  remote changes back into Riverpod providers (`habitsController.refreshFromStore()`,
  invalidate goals/journal) for live UI updates. Kept alive from `app.dart`.

### Post-Phase fixes ✅
1. **No Guest Mode** — removed `continueAsGuest`, `isGuest`, the guest button.
2. **Per-account data isolation** — in `SyncController`: when a **different**
   account signs in (`last_sync_user` ≠ current uid), it **wipes the synced Hive
   boxes BEFORE any sync engine starts**, then reconcile pulls the new account's
   cloud data. Switching back restores the original account from the cloud. XP/
   streaks are **derived from logs**, so they restore automatically.
   - 🔑 **Why clear-before-start matters:** if you clear boxes while a sync engine's
     `box.watch()` is active, the deletions get pushed as **tombstones** and would
     wipe the cloud. Clearing happens only while sync is stopped. Never break this.
3. **Glow reduced** across theme + components (see §6).
4. **Completion UI redesigned + crash fixed** (`features/habits/.../habit_card.dart`):
   premium status picker dialog + animated tick (tap = complete, long-press /
   right-click = picker; completed shows a clean bold white check).
   - 🔑 **CRITICAL GOTCHA (caused a black-screen crash):** under GoRouter
     `ShellRoute`, `showDialog` pushes on the **root** navigator. If you call
     `Navigator.pop(context)` with a **page** context (inside the shell's nested
     navigator), you pop the **current page** → black screen. **Always pop the
     dialog's OWN context** (name the `builder: (dialogContext) => ...` param and
     pop that), or use `Navigator.of(context, rootNavigator: true)`. We fixed this
     here and in Settings "Edit profile". **Audit every new dialog for this.**

---

## 9. ⬅️ NEXT: Phase 3 — Android app MVP (start here)

**Goal:** an installable **Android** app on the same `aura_core`, signed in with the
same accounts, that **syncs live** with Windows (complete on phone → shows on
desktop instantly, and vice-versa).

**Suggested approach (keep the user informed, build incrementally, verify):**
1. **Create the mobile app** as a new Flutter project (e.g. `apps/mobile/`,
   Android-only enabled). Add `aura_core` via `path:` dependency. Add Riverpod,
   go_router, flutter_animate, google_fonts, etc. Recreate `env.json` consumption
   (same `--dart-define-from-file`).
2. **Port the design system** — extract/reuse theme tokens + key widgets. Consider a
   shared `packages/aura_ui` later, but to start, copy the theme into the mobile app
   and keep parity with the (now low-glow) desktop look. Mobile-first navigation
   (bottom nav), gestures, smooth transitions.
3. **Auth on mobile** — reuse `aura_core/AuthService`. Email + code works as-is.
   For **Google on Android**, use the `google_sign_in` package (works on Android,
   unlike desktop) to get an id_token → `signInWithGoogleIdToken`. **You'll need to
   guide the user** to create an **Android OAuth client** in Google Cloud (needs the
   app's **SHA-1** fingerprint — generate the debug/release keystore and give them
   the SHA-1 to paste) plus a **Web client ID**, and add the Android client to
   Supabase. Provide a step-by-step `.md` guide like the existing ones.
4. **Wire sync on mobile** — reuse `SyncManager`/`SyncEngine` from `aura_core` with
   the same box↔entity mapping and the **same per-account isolation rule**
   (clear-before-start). Hive boxes mirror the desktop's.
5. **MVP screens:** onboarding + auth, Dashboard, Habits CRUD + tracking (reuse the
   completion picker UX), Calendar, local notifications. Then Phase 4 ports the rest.
6. **Verify cross-device live sync:** run the Android emulator + the Windows app
   signed into the same account; mutate on one, confirm it appears on the other.

**What you'll need to ask the user for (with guides):** Android Google OAuth client
+ SHA-1 (you generate the keystore, they paste SHA-1 into Google Cloud), later a
Google Play Console account ($25) for release (Phase 11).

---

## 10. Verification playbook

- **Build sanity:** `flutter analyze` clean (0 errors), release build succeeds,
  launched exe stays running (no init crash).
- **Cloud sync (powerful self-check without the UI):** the desktop stores the
  Supabase session in
  `%APPDATA%\Roaming\Aura Habits\Aura Habits\shared_preferences.json` under key
  `flutter.sb-qvjixjniytgwfrjlygtb-auth-token`. Parse it to get `access_token`, then
  call the Supabase REST API (`/rest/v1/<table>?select=...` with headers
  `apikey: <anon>` + `Authorization: Bearer <token>`) to confirm rows are pushed
  (RLS-scoped to that user). This is how Phase 2 was verified (saw the `GYM` habit).
- **Realtime:** insert/patch a row via REST with that token → it should appear in the
  running app within ~1–2s (cloud→local).
- **Isolation:** sign out → sign into a different account → confirm only that
  account's data shows; switch back → original data restored. Confirm no tombstones
  were pushed (the other account's `deleted_at` stays null).

---

## 11. Key files to know

| File | Purpose |
|---|---|
| `packages/aura_core/lib/src/sync/sync_engine.dart` | Core sync algorithm (echo guard, tombstones, realtime) |
| `packages/aura_core/lib/src/sync/sync_manager.dart` | Orchestrates engines + connectivity |
| `packages/aura_core/lib/src/auth/auth_service.dart` | All Supabase auth |
| `lib/features/sync/sync_controller.dart` | Desktop sync wiring + **per-account isolation** |
| `lib/features/auth/auth_provider.dart` | `AuthController` / `UserProfile` (no guest) |
| `lib/features/auth/presentation/login_page.dart` | Multi-mode auth UI (8-digit code) |
| `lib/features/auth/google_auth_service.dart` | Desktop loopback Google → id_token |
| `lib/features/habits/presentation/widgets/habit_card.dart` | Habit row + premium completion picker (dialog-context-safe) |
| `lib/core/theme/app_colors.dart`, `app_spacing.dart` | Tokens + (reduced) shadow/glow |
| `supabase/migrations/0001_init.sql` | Schema + RLS + realtime |
| `supabase/*.md` | User setup guides (Supabase, Google, email template, SMTP) |
| `env.json` (gitignored) | Real Supabase + Google desktop creds |

---

## 12. Known gaps / future TODOs (not blockers)

- **`settings` & `gamification` tables exist but aren't synced yet** — they're
  singleton key-value boxes (primitive values), which the generic Map-based engine
  doesn't handle. Gamification/XP is **derived from logs** so it restores anyway;
  settings (theme prefs) are device-local for now. Add singleton-sync later if wanted.
- **Installer is unsigned** (SmartScreen warning) — needs an Authenticode cert
  (`installer/AuraHabits.iss` is already signtool-ready via `/DSIGN`).
- **AI (Phase 7)** will need a Gemini API key (free) + OpenAI API key (paid) — ask
  the user with a guide when you reach it.

---

## 13. First actions for the new Claude

1. Read this file + skim `supabase/migrations/0001_init.sql` and
   `lib/features/sync/sync_controller.dart` to ground yourself.
2. Confirm `env.json` exists in the repo root (it should). If not, ask the user for
   the four values.
3. Confirm you're on branch `feature/cloud-platform` (`git status`).
4. Tell the user you're picking up at **Phase 3 (Android app)** and outline the
   first concrete steps (create the mobile project on `aura_core`, then auth + sync).
   Then proceed — building incrementally, committing/pushing, and guiding the user
   through any Google-Android setup with a clear `.md`.

**Above all:** keep the exact same vision, roadmap, decisions (§2), and the user's
preferences (§2 working style, §6 glow). Don't restart or re-architect what's done.
Continue as if the session never broke.
