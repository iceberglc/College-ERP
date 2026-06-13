# Mobile — Flutter App

This directory contains the Flutter mobile application (`iceberg_app`) for students and staff.

## Structure

```
mobile/
└── iceberg_app/    Flutter project (Android + iOS)
    ├── lib/
    │   ├── core/         Shared utilities, theme, HTTP client
    │   ├── features/     Feature modules (auth, attendance, assignments, …)
    │   └── shared/       Reusable widgets
    ├── android/
    ├── ios/
    └── pubspec.yaml
```

## Setup

1. Install Flutter SDK: https://flutter.dev/docs/get-started/install
2. Install dependencies:

```bash
cd mobile/iceberg_app
flutter pub get
```

## Running on a device or emulator

```bash
cd mobile/iceberg_app

# List available devices
flutter devices

# Run on a connected device / emulator
flutter run
```

## Configuring the API base URL

The API base URL is defined in `lib/core/config/app_config.dart` (or similar).
For local development, point it at your machine's LAN IP (not `localhost`) so a
physical device can reach the Django dev server.

## Building a release APK

```bash
cd mobile/iceberg_app
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Building for iOS

```bash
cd mobile/iceberg_app
flutter build ios --release
# Then open ios/Runner.xcworkspace in Xcode and archive.
```

> **Note:** Release APKs are distributed via GitHub Releases, not committed to the
> repository. The file `iceberg-student.apk` at the repo root is excluded by `.gitignore`.
