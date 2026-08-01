# AttendanceFlow

Flutter app for tracking daily attendance on a simple monthly calendar.

<p align="center">
  <img src="screenshots/01_calendar.png" alt="Monthly calendar with weekday attendance" width="260" />
  <img src="screenshots/02_marked_days.png" alt="Marked attendance days across the month" width="260" />
  <img src="screenshots/03_monthly_stats.png" alt="Monthly present days and progress" width="260" />
</p>

## Features

- Monthly calendar with tap-to-mark attendance days
- Edit mode for bulk corrections
- Local persistence via SharedPreferences
- Clean light UI tuned for phones (consistent spacing, clear hierarchy)
- Android and iOS targets

## Run

```bash
flutter pub get
flutter run
```

## Stack

- Flutter / Dart
- Material Design
- `shared_preferences` for offline storage
