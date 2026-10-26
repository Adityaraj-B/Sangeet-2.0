# Sangeet 2.0 (Atelier Acoustique)

A bespoke, high-fidelity music streaming and offline player built with Flutter, featuring the handcrafted **Atelier Acoustique** design language, seamless multi-platform support, background audio streaming, offline vault caching, and Firebase cloud sync.

---

## ✨ Features

- **Atelier Acoustique Aesthetics**: Deep onyx canvas, champagne gold accents, subtle acoustic glows, and typography designed for audiophiles.
- **Dynamic Playback Engine**: Powered by `just_audio` and `audio_service` with notification controls, lock-screen artwork, and lockless background buffering.
- **Smart Queue & Autoplay**: Content-aware queue generation with cosine/overlap similarity matching.
- **Offline Vault**: Encrypted-grade local persistence for favorite songs and downloads via `sqflite` and sanitized local disk storage.
- **Cloud Synchronization**: Optional Firebase Authentication (Email + Modern Google Sign-In Credential Manager) and Firestore playlist backups.
- **Global Search & Curated Soundscapes**: Rapid search across songs, albums, and artists, plus mood-driven curated collections.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.6.0)
- [Android Studio](https://developer.android.com/studio) / Xcode (for iOS/macOS)
- [Dart](https://dart.dev/get-dart) (>= 3.6.0)

### 1. Clone the repository

```bash
git clone https://github.com/Adityaraj-B/Sangeet-2.0.git
cd Sangeet-2.0
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Firebase & Signing Configuration

Sensitive credentials and Firebase configurations are excluded from version control to preserve security. To configure Firebase for your own setup:

1. **FlutterFire CLI (Recommended)**:
   ```bash
   flutterfire configure
   ```
2. **Or Manual Setup via Template Files**:
   - **Android**: Copy `android/app/google-services.json.example` to `android/app/google-services.json` and insert your Firebase app credentials.
   - **iOS**: Copy `ios/Runner/GoogleService-Info.plist.example` to `ios/Runner/GoogleService-Info.plist`.
   - **Dart**: Copy `lib/firebase_options.dart.example` to `lib/firebase_options.dart` and populate your API keys.
   - **Release Signing**: Copy `android/key.properties.example` to `android/key.properties` if you wish to sign release bundles.

### 4. Run the app

```bash
# Debug mode
flutter run

# Build release Android App Bundle (AAB)
flutter build appbundle --release

# Build release Android APK
flutter build apk --release
```

---

## 📐 Project Structure

```
lib/
├── artist/          # Artist detail screen and discography
├── auth/            # Firebase Auth & Google Sign-In with Atelier UI
├── components/      # Reusable widgets (buttons, cards, chips, skeletons)
├── constants/       # API endpoints and configuration
├── exceptions/      # Custom domain exceptions
├── home/            # Discovery screen, trending albums, soundscapes
├── insights/        # Listening statistics and habits
├── library/         # Liked tracks, playlists, and offline downloads
├── main_layout/     # Aura bottom nav and mini player shell
├── models/          # Immutable domain models (Song, Album, Artist, Playlist)
├── player/          # Fullscreen player, queue sheet, waveform scrubber
├── playlist/        # Playlist details, import tools
├── profile/         # User profile, cloud backup, and storage metrics
├── repositories/    # Data persistence and download cache handlers
├── search/          # Global search and Sonic Spectra explorer
├── services/        # Audio background handler, connectivity, Firebase
├── theme/           # Atelier Acoustique design tokens (colors, radii, typography)
└── utils/           # Responsive layout helpers
```

---

## 🔒 Security & Privacy

This repository enforces strict `.gitignore` rules:
- No signing keystores (`*.jks`, `*.keystore`, `key.properties`).
- No machine-specific paths (`local.properties`).
- No raw Firebase private keys or client service files (`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`).
- Sanitized `.example` templates are provided for contributors.
