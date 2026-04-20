# Baby Companion (Flutter)

Standalone Flutter baby-tracking app — a phone-only port of the [Baby Companion](https://github.com/murdawkmedia/baby-companion) Pebble watch app.

Target: Android 12+ (min SDK 31). iOS support planned via the same codebase.

## Related repos

- [`murdawkmedia/baby-companion`](https://github.com/murdawkmedia/baby-companion) — original Pebble watch app (C, SDK 3).
- [`murdawkmedia/baby-companion-android`](https://github.com/murdawkmedia/baby-companion-android) — Kotlin Android **bridge** for the Pebble watch (separate project — phone relays events to Health Connect, Baby Buddy, webhooks).

This Flutter app replaces the watch entirely. The bridge is unrelated.

## Structure

```
lib/
├── main.dart
├── app.dart                   # MaterialApp + theme switcher
├── data/                      # event model, sqflite DB, settings, session state
├── domain/                    # reminders, contraction rule, time formatting
├── theme/                     # Neutral / Boy / Girl ColorSchemes
└── ui/                        # home + 10 feature screens
```

See [`MIGRATION.md`](./MIGRATION.md) for the full port spec.

## Build

Requires Flutter 3.41+ and the Android SDK.

```
flutter pub get
flutter run                 # debug
flutter build apk --release
```

## Status

Scaffold only. Screen stubs compile but are not yet implemented — see the build order in `MIGRATION.md` §7.
