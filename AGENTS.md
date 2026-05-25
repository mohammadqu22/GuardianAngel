# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

**Guardian Angel** is a Flutter mobile app targeting both **iOS and Android** that guides users through first-aid emergency protocols step by step. It covers 8 emergency types: CPR, CPR (infant), bleeding, burns, choking, choking (infant), fractures, and seizures. The app was built as an academic final-year project at Azrieli College of Engineering, Jerusalem.

This is a two-person collaborative project. Both developers contribute across all areas of the codebase as needed.

macOS desktop is **not** a target platform. Ignore the `macos/` directory.

## UI Design Reference

The target UI is designed in Google Stitch (project ID: 18416799649176081778). All screen improvements should align with the Stitch mockups. The design uses deep red (#E53935) as the primary brand color, with per-emergency accent colors: orange for Burns, blue for Choking, dark red for Bleeding, purple for Fractures, and amber for Seizures.

## Known Bugs

**App name spelling:** The app name should be spelled "Guardian Angel" in platform config files. Keep repository and package naming consistent when touching app identity files.

## Common Commands
```bash
# Install dependencies
flutter pub get

# Run on connected device or simulator
flutter run

# Build iOS release
flutter build ios

# Analyze (lint)
flutter analyze

# Run tests
flutter test
```

## Architecture

### App Startup Flow (`lib/main.dart`)
1. `SharedPreferences` loads `disclaimer_accepted`, `theme_mode`, and `language` preferences
2. `DatabaseService.database` initializes SQLite tables (failure is non-fatal)
3. `TtsService.instance.init()` configures the audio session (failure is non-fatal)
4. `PermissionService.requestAppPermissions()` requests phone and location permissions (non-blocking)
5. Routes to `DisclaimerScreen` (first launch) or `HomeScreen` (returning users)

### Navigation Model
All navigation uses `Navigator.push()` — there is no named route system. The files `lib/core/routes.dart` and `lib/core/constants.dart` exist but are **empty placeholders**. Do not assume named routes exist.

### Emergency Protocol Data Flow
- JSON protocol files are organized into three language directories:
  - `assets/data/` — English (8 files: bleeding, burns, choking, choking_infant, cpr, cpr_infant, fractures, seizures)
  - `assets/data/he/` — Hebrew (same 8 files)
  - `assets/data/ar/` — Arabic (same 8 files)
- `StepScreen` tries to load the locale-specific file first, then falls back to English — there is no separate loader service (`protocol_loader.dart` is empty)
- `lib/models/emergency.dart` holds the `Emergency` class; the emergency list is built dynamically in `HomeScreen` using localized strings

### JSON Protocol Format
```json
{
  "id": "cpr",
  "title": "CPR",
  "steps": [{ "step": 1, "title": "...", "instruction": "..." }],
  "warnings": ["..."],
  "sources": ["..."]
}
```

### Persistence
`lib/services/database_service.dart` — singleton SQLite via `sqflite` with three tables:
- `User_Settings` — language preference and TTS toggle
- `Emergency_Contact` — name + phone, supports add/edit/delete/call
- `Incident_Log` — timestamped protocol sessions with progress, completion status, total elapsed time, per-step durations, and single/bulk delete support

`SharedPreferences` is used for lightweight flags: `disclaimer_accepted`, `language`, `tts_enabled`, `theme_mode`.

### Services
| File | Status | Purpose |
|---|---|---|
| `database_service.dart` | Implemented | SQLite CRUD |
| `permission_service.dart` | Implemented | Phone + location permissions |
| `location_service.dart` | Implemented | GPS coords + Google Maps link |
| `phone_service.dart` | Implemented | Initiates phone calls via `tel:` URI; used for SOS (101) and emergency contacts |
| `tts_service.dart` | Implemented | Singleton audio player via `audioplayers`; plays pre-recorded MP3s from `assets/audio/` |
| `protocol_loader.dart` | **Empty** | JSON loading is done inline in `StepScreen` |

### Widgets
| File | Status | Purpose |
|---|---|---|
| `gradient_button.dart` | Implemented | Reusable primary action button with gradient background |
| `source_item.dart` | Implemented | Row widget for displaying a medical source entry |
| `emergency_card.dart` | **Empty** | Candidate for extraction from `HomeScreen` |
| `step_widget.dart` | **Empty** | Candidate for extraction from `StepScreen` |

## Known Incomplete Areas

**Incident Log UI**: Implemented in `lib/screens/incident_log_screen.dart` and reachable from Settings. It logs opened protocols, completed/visited steps, total elapsed time, per-step durations, and supports clearing all logs plus deleting one or multiple selected logs.

**Tests**: `test/widget_test.dart` covers the Guardian Angel home screen smoke path. Expand coverage for the Incident Log and protocol timing flows when those areas stabilize.

## Internationalization

Language selection (English / Hebrew / Arabic) is fully wired end-to-end:
- User picks a language in `SettingsScreen`; it is saved to SharedPreferences key `'language'`
- `GuardianAngelApp` applies it as the `locale` property on `MaterialApp` and updates on change
- `StepScreen` reloads the protocol JSON for the new locale via `didChangeDependencies()`
- TTS uses matching language codes: `en-US`, `he-IL`, `ar-SA`

Audio playback uses pre-recorded MP3 files bundled in `assets/audio/` — no device TTS voice installation required. Playback failures (missing asset, audio focus loss) are caught silently so the app remains fully usable without sound.
