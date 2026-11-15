# StudentOS app

A personal, local-only Flutter app: Calendar, Finance and Notes, plus an Android
home-screen widget. No account, no server, no internet permission. All data is in
an on-device SQLite database (Drift).

## Run

```
flutter pub get
flutter run
```

## Check

```
flutter analyze
flutter test
```

## Build

```
flutter build apk --release --split-per-abi
```

APKs land in `build/app/outputs/flutter-apk/`. Use `app-arm64-v8a-release.apk` for
a modern phone and `app-x86_64-release.apk` for the emulator.

## After changing database tables

Tables are in `lib/core/db/app_database.dart`. Regenerate the code with:

```
dart run build_runner build --delete-conflicting-outputs
```

Raise `schemaVersion` and add a migration when changing tables that already hold data.

## Layout

- `lib/core/` - database, router, theme, shell with bottom bar and drawer
- `lib/features/calendar|finance|notes/` - model, repository (database access), controller (Riverpod), screen
- `android/app/src/main/kotlin/.../CalendarWidgetProvider.kt` - home-screen widget
