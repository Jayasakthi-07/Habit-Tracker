# Aura Habits — Premium Windows Habit Tracker

A commercial-grade, offline-first habit tracker for Windows, built with Flutter
Desktop. Aura Habits features a premium futuristic UI (glassmorphism, neon
gradients, soft shadows, smooth micro-interactions), real local persistence,
analytics, gamification, a focus timer, journaling, goals, licensing and more.

> Built with Flutter 3.44 (stable) · Dart 3.12 · Windows Desktop

---

## ✨ Highlights

- **Premium design system** — exact brand palette, glassmorphism, animated
  progress rings, streak flames, heatmaps, glow buttons, page transitions.
- **Custom desktop shell** — frameless window, custom title bar, animated
  sidebar, system tray, minimize-to-tray.
- **Offline-first** — all data stored locally in Hive; no account required.
- **Clean architecture** — feature-based modules, MVVM, repository pattern,
  Riverpod dependency injection.
- **Real analytics** — completion trends, category performance, consistency,
  heatmap, XP/levels, achievements — all computed from your actual data.
- **Exports** — CSV, Excel (xlsx) and PDF reports.
- **Licensing** — offline license-key verification with device binding, ready
  for a future online verification API.

---

## 🎨 Design tokens

| Token            | Value     |
|------------------|-----------|
| Primary accent   | `#00FF88` |
| Secondary        | `#00D4FF` |
| Background       | `#0A0A0A` |
| Surface          | `#141414` |
| Cards            | `#1C1C1C` |
| Text             | `#FFFFFF` |
| Muted            | `#A0A0A0` |

Defined in `lib/core/theme/app_colors.dart`.

---

## 🏗️ Architecture

```
lib/
├── main.dart                  # Bootstrap: Hive, window, notifications
├── app.dart                   # MaterialApp.router + global theme
├── core/                      # Cross-cutting infrastructure
│   ├── theme/                 # Colors, typography, spacing, theme
│   ├── router/                # GoRouter + auth redirect + transitions
│   ├── storage/               # Hive initialisation & box registry
│   ├── window/                # window_manager + tray integration
│   └── utils/                 # Date helpers
├── shared/widgets/            # Reusable premium components
└── features/                  # Feature-first modules (MVVM)
    ├── auth/                  # Google sign-in (desktop OAuth) + guest mode
    ├── shell/                 # App frame: sidebar + title bar
    ├── dashboard/             # Analytics-center home
    ├── habits/                # CRUD, tracking, repository, providers
    │   ├── domain/            # Entities (Habit, HabitLog, enums)
    │   ├── data/              # HabitRepository (+ stats engine)
    │   └── presentation/      # Pages, widgets, Riverpod controllers
    ├── categories/            # Built-in + custom categories
    ├── calendar/              # Month grid + day detail
    ├── analytics/             # Charts & insights
    ├── goals/                 # Goal tracking with progress
    ├── journal/               # Daily journal + mood tracking
    ├── gamification/          # XP, levels, coins, achievements
    ├── focus/                 # Pomodoro / focus mode
    ├── notifications/         # Desktop notifications
    ├── export/                # CSV / Excel / PDF export
    ├── license/               # Commercial licensing
    ├── ai/                    # AI-ready service layer (local heuristics)
    └── settings/              # Settings, backup/restore, premium
```

**Patterns used**

- **MVVM** — Riverpod `Notifier`/`Provider` view-models drive declarative views.
- **Repository pattern** — `HabitRepository` is the single source of truth for
  habit data and derived statistics (streaks, success rates, heatmap).
- **Dependency injection** — all services exposed via Riverpod providers.
- **Feature-first** — each feature owns its domain/data/presentation layers.

---

## 🧱 Tech stack

| Concern        | Package |
|----------------|---------|
| State / DI     | `flutter_riverpod` |
| Local storage  | `hive`, `hive_flutter` (+ `sqflite_common_ffi` available) |
| Routing        | `go_router` |
| Animations     | `flutter_animate` |
| Desktop window | `window_manager`, `tray_manager` |
| Notifications  | `local_notifier` |
| Charts         | `fl_chart` |
| Export         | `pdf`, `printing`, `excel`, `csv` |
| Typography     | `google_fonts` (Inter / Space Grotesk) |
| Security       | `crypto` (password + license hashing) |

---

## 🚀 Getting started

### Prerequisites
- Flutter 3.44+ (stable channel)
- Windows 10/11
- Visual Studio 2022/2026 with the **Desktop development with C++** workload

### Run in development
```bash
flutter pub get
flutter run -d windows
```

### Build a release executable
```bash
flutter build windows --release --no-tree-shake-icons
```

> `--no-tree-shake-icons` is required because habits use **user-selected icons**
> resolved at runtime (dynamic `IconData`), which the icon tree-shaker cannot
> statically analyse.

The build output is at:
```
build/windows/x64/runner/Release/AuraHabits.exe
```
Ship the **entire `Release/` folder** (the exe plus its `data/` folder and DLLs).

---

## 📦 Building an installer

A ready-to-use [Inno Setup](https://jrsoftware.org/isinfo.php) script is provided
at `installer/AuraHabits.iss`. After a release build:

1. Install Inno Setup 6.
2. Open `installer/AuraHabits.iss` in the Inno Setup Compiler.
3. Click **Build → Compile**.

This produces `installer/Output/AuraHabits-Setup.exe`, a single-file installer
with Start-menu/desktop shortcuts and an uninstaller.

---

## 🔐 Authentication (Google Sign-In)

Sign-in uses **Google** via the OAuth 2.0 **Authorization Code + PKCE** flow over
a loopback redirect (`features/auth/google_auth_service.dart`) — the supported
pattern for native desktop apps (the `google_sign_in` plugin does not run on
Windows). The app:

1. Spins up a temporary `http://localhost:<port>` listener.
2. Opens the system browser to Google's consent screen.
3. Validates the returned `state`, exchanges the code (with the PKCE verifier)
   for tokens, and reads the user's name/email/avatar.
4. Renders a **branded, animated success page** in the browser.

Credentials live in `lib/core/config/google_auth_config.dart`. For a **Desktop**
OAuth client, Google treats the client secret as non-confidential, so it ships
embedded. A small **offline guest** option remains so the app works without a
network connection.

> **Google Cloud setup:** if your OAuth consent screen is in *Testing* status,
> add your account as a **Test user**, or sign-in will be blocked.

## ✍️ Code signing (for distribution)

The setup executable is unsigned. To avoid SmartScreen warnings on end-user
machines, sign both `AuraHabits.exe` and `AuraHabits-Setup.exe` with an
Authenticode certificate:

```powershell
signtool sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 `
  /a "build\windows\x64\runner\Release\AuraHabits.exe"
```

You can also wire `SignTool` into the Inno Setup script via `SignTool=` directives.

## 🔑 Licensing (commercial)

Aura Habits ships with an offline license system (`features/license`):

- **Format:** `AURA-XXXX-XXXX-XXXX` where the final block is a checksum of the
  first two blocks.
- **Device binding:** each activation is bound to a per-device id (one license =
  one device).
- **Storage:** activation is stored locally.
- **Future-ready:** swap `_verifyKey` for an online API call without touching the
  UI.

For evaluation, **Settings → Aura Premium → Activate license → Generate demo key**
produces a valid key.

---

## 🧪 Tests

```bash
flutter test
```

Unit tests cover the domain rules behind scheduling, streak credit and
serialization (`test/widget_test.dart`).

---

## 📊 Data model

- **Habit** — name, description, category, priority, difficulty, icon, color,
  frequency (daily/weekly/monthly/custom), weekdays, start/end dates, multiple
  reminders, daily target, notes.
- **HabitLog** — per-day status (completed / partial / skipped / postponed /
  missed), keyed by `habitId|yyyy-MM-dd`.
- **Goal**, **JournalEntry** — persisted in their own Hive boxes.

Data is stored under `%APPDATA%/com.aurahabits/AuraHabits/`.

Backups (Settings → Data & Backup) export/import a single JSON snapshot to
`Documents/AuraHabits Backups/`.

---

## 🗺️ Feature status

**Deeply implemented & wired to real data**

Dashboard · Habit CRUD & tracking · Categories · Streak engine · Calendar ·
Analytics · Goals · Journal & mood · Gamification (XP/levels/achievements) ·
Focus/Pomodoro · CSV/Excel/PDF export · Backup/restore · Google sign-in & guest mode ·
Offline licensing · Settings · Desktop notifications · System tray.

**Scaffolded / architecture-ready (interfaces in place for future expansion)**

AI coach (local heuristics now, online API placeholder) · Social / leaderboards ·
Multi-window widgets · Cloud sync. These have service layers / data structures
ready so they can be completed without re-architecting.

---

## 📄 License

Proprietary / commercial. © 2026 Aura Habits. All rights reserved.
