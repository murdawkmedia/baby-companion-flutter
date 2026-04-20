# Baby Companion — Pebble to Flutter Port Spec

## Context

The existing app is a Pebble Watch app (`src/c/baby-companion.c`, 2565 lines, Pebble SDK 3) targeting the `emery` and `gabbro` platforms. The app needs to be rebuilt from scratch as a **Flutter (Dart)** app targeting **Android min SDK 31 (Android 12)**, with a future option to reuse the same codebase for iOS.

The new repo lives at: `murdawkmedia/baby-companion-flutter`

> **Note:** `murdawkmedia/baby-companion-android` is a separate Kotlin bridge app that connects the Pebble watch to Android (Health Connect, Baby Buddy, webhooks). Do NOT overwrite it. This Flutter app is a standalone phone companion that works independently of the watch.

---

## 1. Feature Inventory

Eight tracked event types (from the `FeedRecord.type` field):

| type | Event        | Fields used                                        |
|------|--------------|----------------------------------------------------|
| 0    | Nursing      | `side` (0=Left, 1=Right), `duration_mins`          |
| 1    | Formula      | `oz_halves` (dose in 0.5 oz units, range 1-20)     |
| 2    | Milestone    | `side` = milestone index (0-14)                    |
| 3    | Diaper       | `side` (0=wet, 1=dirty)                            |
| 4    | Sleep        | `duration_mins`                                    |
| 5    | Medication   | `side` (0=Tylenol, 1=Motrin), `oz_halves` (0.5 mL)|
| 6    | Colic        | `duration_mins` stores **seconds**                 |
| 7    | Contraction  | `duration_mins` = seconds, `oz_halves` = interval minutes |

---

## 2. Screen Map

Every screen in the Pebble app, in navigation order:

- **Main menu** — 3 sections: header (baby name or "Baby Companion"), FEEDING section, TRACK section.
  - FEEDING: Start/Resume Nursing, Log Formula, Log Diaper, Log Medication, Reminder (tap to cycle interval).
  - TRACK: History, Sleep, Colic Timer, Contractions, Milestones, Settings.
- **Nursing** — Live stopwatch. Left/Right side toggle. Auto-resumes if a session was active when the app closed.
- **Formula** — UP/DOWN adjusts ounces in 0.5 increments (min 0.5 oz, max 10 oz). SELECT logs the entry.
- **Diaper** — Wet/Dirty toggle. Shows running diaper counts from recent history.
- **Medication** — Tylenol/Motrin toggle. Dose adjustable in 0.5 mL increments.
- **Sleep** — Stopwatch start/stop. Session persists across app close (saved to storage).
- **Colic timer** — Stopwatch for crying episodes.
- **Contractions** — Stopwatch with running average duration + interval. Evaluates 5-1-1 or 4-1-1 rule ("go to hospital" threshold). Shows session summary on exit.
- **Milestones** — 15-item checklist. Asterisk marks logged milestones. Tapping toggles and records timestamp.
- **History** — Scrollable list of the last 10 recorded events (ring buffer), showing type, time, and details.
- **Name picker** — Character-by-character baby name entry, up to 12 characters.
- **Date picker** — Month/Day/Year selector for baby's birth date.
- **Settings** — 6 rows: Theme (cycle), Reminder interval (cycle), Baby Name (opens picker), Birth Date (opens picker), Contraction Rule (toggle 5-1-1 / 4-1-1), version info.
- **Reminder alert** — Full-screen alert shown when a feeding reminder fires.

---

## 3. Data Model (Flutter Replacement)

### Pebble storage (for reference)

Pebble uses `persist_*` key-value storage with a 10-slot ring buffer (`SK_FEEDS_BASE` keys 10-19). This was a storage-size workaround. On a phone there is no reason to cap history.

### Flutter data model

Use **`sqflite`** for the events table:

```dart
class BabyEvent {
  final int? id;
  final DateTime startTime;
  final EventType type;       // enum: nursing, formula, milestone, diaper, sleep, medication, colic, contraction
  final int? durationSeconds; // unified to seconds (Pebble used mixed units)
  final int? side;            // 0/1 depending on type
  final int? ozHalves;        // 0.5-unit doses for formula/medication
}

enum EventType { nursing, formula, milestone, diaper, sleep, medication, colic, contraction }
```

Additional storage:

- **`baby_profile`** table: name (String, max 12 chars), birth_month, birth_day, birth_year.
- **`settings`** table/key-value: theme_id (0=Neutral, 1=Boy, 2=Girl), reminder_mode (0-6), contraction_rule (0=5-1-1, 1=4-1-1).
- **`milestones_logged`**: 15 boolean flags + timestamps. Maps to the Pebble `SK_MILESTONES` bitmask + `SK_MILESTONE_TIMES_BASE` keys.
- **Active session state**: Use `shared_preferences` for nursing/sleep/colic/contraction session resumability (start timestamps).

---

## 4. Behavior to Preserve Exactly

### Reminder intervals

Options: Off, 1h, 2h, 2h 30m, 3h, 3h 30m, 4h. Timed from the **start** of the feed, not the end. Use `flutter_local_notifications` + `android_alarm_manager_plus`.

### Vibration patterns

| Event            | Pattern                              |
|------------------|--------------------------------------|
| UI tap/click     | Short pulse                          |
| Entry logged     | Double pulse                         |
| Important action | Long pulse                           |
| Reminder alert   | 200ms-150ms-200ms-150ms-400ms        |
| Medication done  | 100ms-80ms-100ms-80ms-100ms          |
| Contraction start| 80ms-120ms-150ms                     |
| Contraction stop | 300ms-100ms-100ms                    |

Use the `vibration` package.

### Contraction rule evaluation

- **5-1-1 rule**: contractions 5 minutes apart, lasting 1 minute each, for 1 hour.
- **4-1-1 rule**: contractions 4 minutes apart, lasting 1 minute each, for 1 hour.
- The app tracks a running average of contraction duration and interval, then evaluates against the selected rule.

### Time-ago formatting

- `t == 0` -> "No entries yet"
- `< 90s` -> "Just now"
- `< 1h` -> "Xm ago"
- `< 24h` -> "Xh Ym ago"
- `>= 24h` -> "Xd ago"

### Themes

| Theme   | Background    | Highlight        | Title bar        |
|---------|---------------|------------------|------------------|
| Neutral | Black         | Tiffany Blue     | Tiffany Blue/Black text |
| Boy     | Oxford Blue   | Picton Blue      | Picton Blue/Black text  |
| Girl    | Black         | Shocking Pink     | Folly/White text        |

Map these to Material 3 `ColorScheme` instances.

### Milestones (exact names, exact order)

1. Social Smile
2. First Laugh
3. Holds Head Up
4. Tracks Objects
5. Rolls Fwd-Back
6. Rolls Back-Fwd
7. Sits w/ Support
8. Sits Alone
9. First Solid Food
10. Crawling
11. Pulls to Stand
12. First Steps
13. First Word
14. Points at Things
15. Waves Bye-Bye

### Medications

Tylenol and Motrin, dosed in 0.5 mL increments.

---

## 5. Proposed Flutter Project Layout

```
baby-companion-flutter/
├── pubspec.yaml
├── android/
├── lib/
│   ├── main.dart
│   ├── app.dart                      # MaterialApp + theme switcher
│   ├── data/
│   │   ├── event.dart                # BabyEvent model + EventType enum
│   │   ├── database.dart             # sqflite singleton, migrations
│   │   ├── settings_repo.dart        # theme, reminder, contraction rule
│   │   └── active_session.dart       # shared_preferences for live timers
│   ├── domain/
│   │   ├── reminder_scheduler.dart   # feed reminder scheduling
│   │   ├── contraction_rule.dart     # 5-1-1 / 4-1-1 evaluator
│   │   └── time_format.dart          # time-ago + elapsed formatting
│   ├── ui/
│   │   ├── home/home_screen.dart
│   │   ├── nursing/nursing_screen.dart
│   │   ├── formula/formula_screen.dart
│   │   ├── diaper/diaper_screen.dart
│   │   ├── medication/medication_screen.dart
│   │   ├── sleep/sleep_screen.dart
│   │   ├── colic/colic_screen.dart
│   │   ├── contractions/contractions_screen.dart
│   │   ├── milestones/milestones_screen.dart
│   │   ├── history/history_screen.dart
│   │   └── settings/settings_screen.dart
│   └── theme/
│       └── themes.dart               # Neutral / Boy / Girl ColorSchemes
└── test/
```

### Recommended packages

- `sqflite` — local SQLite database
- `shared_preferences` — active session state
- `flutter_local_notifications` — feed reminders
- `android_alarm_manager_plus` — exact alarm scheduling
- `vibration` — haptic feedback patterns
- `intl` — date/time formatting

---

## 6. Assets

The 7 Pebble bitmap PNGs (`img_bottle.png`, `img_colic.png`, `img_contraction.png`, `img_diaper.png`, `img_medication.png`, `img_nursing.png`, `img_sleep.png`) are 1-bit Pebble-format bitmaps and should **not** be reused directly.

For the Flutter app, use Material Symbols or redrawn vector assets. Suggested icons:

| Feature       | Material Symbol suggestion         |
|---------------|------------------------------------|
| Nursing       | `child_care` or custom             |
| Formula       | `baby_changing_station`            |
| Diaper        | `baby_changing_station` variant    |
| Sleep         | `bedtime`                          |
| Medication    | `medication`                       |
| Colic         | `timer`                            |
| Contractions  | `pregnant_woman`                   |
| Milestones    | `emoji_events`                     |

---

## 7. Build Order (recommended)

1. `flutter create . --platforms=android --org=media.murdawk`
2. Scaffold folder structure from section 5.
3. Implement data layer: `BabyEvent` model, `sqflite` database, repos.
4. Implement home screen + one end-to-end flow (e.g. nursing) to validate architecture.
5. Fan out to remaining screens (formula, diaper, medication, sleep, colic, contractions, milestones, history).
6. Implement settings screen (theme, name, birth date, contraction rule, reminder).
7. Wire reminders + vibration patterns last.

---

## Source Reference

All behavior is defined in a single file: `src/c/baby-companion.c` (2565 lines) in the `murdawkmedia/baby-companion` repository.
