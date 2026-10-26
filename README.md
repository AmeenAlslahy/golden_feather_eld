# Golden Feather ELD

Golden Feather ELD is a Flutter-based Electronic Logging Device (ELD) designed for field compliance tracking, activity logging, and operational recordkeeping.

The project is built to support mobile workflows in environments where location, time, documentation, and reporting matter — with a strong focus on secure local data handling, offline readiness, and exportable compliance records.

## Overview

Golden Feather ELD helps teams track field activities with a modern mobile experience. It combines:

- location-aware logging
- secure local persistence
- digital sign-off and document capture
- PDF/report export workflows
- offline and local-first data handling
- Firebase-based reliability and messaging support

## Key Features

- Field compliance tracking
- GPS and geolocation-aware activity records
- Local persistence using Hive and SharedPreferences
- Secure storage for sensitive data
- Signature capture support
- Image and document uploads
- PDF export and sharing
- Offline-capable app flow
- Firebase integration for crash reporting and push messaging
- State management with Riverpod and route handling with GoRouter

## Tech Stack

- Flutter
- Dart SDK >= 3.8.0
- Riverpod + Riverpod Annotation
- GoRouter
- Hive + SharedPreferences + Flutter Secure Storage
- Dio + Connectivity Plus
- Geolocator + Geocoding
- Firebase Core / Crashlytics / Messaging
- PDF + Share Plus
- Image Picker + Signature
- ScreenUtil + Google Fonts

## Project Requirements

Before running the app, make sure you have:

- Flutter 3.32.0 or newer
- Dart SDK compatible with the project
- Android Studio / VS Code with Flutter support
- An Android emulator or a connected Android/iOS device
- Optional: Firebase project configuration for messaging / crash reporting

## Installation

1. Clone the repository:

```bash
git clone https://github.com/AmeenAlslahy/golden_feather_eld.git
cd golden_feather_eld
```

2. Install dependencies:

```bash
flutter pub get
```

3. If code generation is required by the project (for Riverpod / Freezed / JSON serialization), run:

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## Environment Configuration

This project includes `.env` support and may require environment values depending on your deployment setup.

Create your local environment file if required:

```bash
cp .env.example .env
```

Then update it with your project-specific values.

## Run the App

### Android / iOS

```bash
flutter run
```

### Specific device

```bash
flutter devices
flutter run -d <device-id>
```

## Project Structure

```text
.
├── android/
├── ios/
├── lib/
├── test/
├── assets/
├── .env
├── README.md
├── pubspec.yaml
├── analysis_options.yaml
├── test_driver/
└── ...
```

## Development Notes

The application follows a structured mobile app architecture with:

- state-driven UI composition
- dependency injection via providers
- local secure persistence for compliance-related data
- offline-friendly processing for field operations
- exportable records for compliance workflows

## Contributing

Contributions are welcome. To contribute:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run formatting and validation
5. Submit a pull request

Example:

```bash
git checkout -b feature/my-change
flutter format .
flutter test
```

## License

This project does not currently declare a license in the repository. If this app is intended for public or commercial use, it is recommended to add an appropriate license such as MIT or Apache 2.0.

## Contact

For questions or collaboration inquiries, use the repository contact information or open an issue in the GitHub project.

---

This README was updated for the current Flutter project configuration and reflects the application’s compliance-tracking and field-operations focus.
