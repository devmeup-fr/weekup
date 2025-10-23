# My Alarms

A lightweight, privacy‑friendly alarm clock built with Flutter. Create one‑shot or recurring alarms, pick a ringtone from bundled sounds, control volume and vibration, and snooze safely with limits. The app supports English and French.


## Highlights
- Create, edit, and delete alarms
- One‑shot alarms (single day) or recurring by weekday
- Repeat every N weeks (1–4), aligned to a chosen reference date
- Snooze with a safe cap (by default up to 4 snoozes per alarm)
- Choose from bundled ringtones and preview them while editing
- Per‑alarm options: loop audio, vibrate, volume
- Next alarm is always computed and scheduled via the `alarm` plugin
- Localized UI (en, fr)


## Requirements
- Flutter SDK compatible with Dart ">=3.2.2 <4.0.0" (see `pubspec.yaml`)
- Android 7.0+ or iOS (Android is primary target in this repo)

Packages used (selection): alarm, permission_handler, shared_preferences, audioplayers, volume_controller, flutter_bloc, flutter_i18n, google_fonts, url_launcher.


## Getting started
1) Install dependencies
```sh
flutter pub get
```

2) Run on a device or emulator
```sh
flutter run
```

3) On first launch, grant the requested permissions (Notifications and Exact Alarms on Android). See “Permissions” below.


## Permissions (Android)
The app requests these at runtime:
- Notifications: to show and fire alarms
- Schedule exact alarm: to ring at the exact time
- Storage (legacy): used by some flows/devices; not required on recent Android, but requested defensively

If an alarm doesn’t fire:
- Ensure Notifications are allowed
- Ensure “Schedule exact alarms” is allowed
- Disable battery optimizations for the app if necessary

The app also uses a full‑screen intent when ringing so you can stop/snooze easily.


## How it works (in short)
- Alarms are persisted in `SharedPreferences` as JSON (`AlarmService`).
- The next occurrence is computed from: hour/minute, weekday selections, “repeat every N weeks”, and a reference date (`createdFor`).
- The soonest upcoming alarm is scheduled with the `alarm` plugin; when it rings, a full‑screen screen offers Snooze and Stop.
- Snooze creates a temporary shadow alarm in 10 minutes; the total snoozes per chain are capped (default 4) to prevent abuse.

Key files you might look at:
- `lib/screens/home_screen.dart` — list of alarms and navigation
- `lib/screens/alarm_edit_screen.dart` — editor with time, weekdays, recurrence, ringtone preview, options
- `lib/screens/alarm_ring_screen.dart` — full‑screen ring UI with Stop/Snooze
- `lib/services/alarm_service.dart` — persistence, next‑alarm computation, scheduling, snooze cap
- `lib/models/alarm_model.dart` — alarm data model and `getNextOccurrence()` logic
- `lib/core/utils/localization_util.dart` + `assets/i18n/` — localization


## Project structure (lib)
- `core/` — blocs, utils, formatting, localization helpers
- `models/` — generic models
- `services/` — alarm and permissions services
- `screens/` — Home, Edit, and Ring screens
- `theme/` — colors, themes, and styles
- `widgets/` — reusable UI widgets

Assets:
- `assets/musics/` — bundled ringtones (mp3)
- `assets/i18n/` — translations (en.json, fr.json)
- `assets/images/` — app icons and artwork


## Development tips
- Orientation is portrait‑only (set in `main.dart`).
- There are two debug flags in `main.dart`:
  - `MODE_MOCK` (unused currently)
  - `WITH_CLEAN_PREF` — when true, clears SharedPreferences and secure storage on start (use carefully)


## Ringtones preview (in the editor)
While editing an alarm you can pick a ringtone and preview it. The preview temporarily sets the media volume using `volume_controller`, and restores your original volume afterward.


## i18n
- English and French are supported
- Add more locales under `assets/i18n/` and wire them via `flutter_i18n`


## App icon and splash
Regenerate launcher icons after updating `assets/images/my_alarm_icon.png`:
```sh
dart run flutter_launcher_icons
```

Regenerate splash screen (if you add a `flutter_native_splash` config to `pubspec.yaml`):
```sh
dart run flutter_native_splash:create
```


## Troubleshooting
- Alarm didn’t ring
  - Open system settings: allow Notifications and “Schedule exact alarms”
  - Disable battery optimization for the app
  - Ensure device time and timezone are correct
- Preview sound is silent
  - Check media volume; the editor uses media stream volume
- Recurrence not matching expectations
  - Verify selected weekdays and the “Repeat every N weeks” slider
  - The reference date (`createdFor`) anchors the recurrence blocks


## License
This repository includes a `LICENSE` file. See it for terms.


## Credits
- Built with Flutter and the awesome open‑source packages listed in `pubspec.yaml`
