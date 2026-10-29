# HalalCheck — Halal Food Scanner

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](https://flutter.dev)

A cross-platform mobile application that helps Muslims identify halal food products and discover halal-certified venues using on-device AI, barcode scanning, and community-driven mapping.

---

## Features

| Feature | Description |
|---|---|
| **Ingredient Scanner** | Camera captures ingredient labels; on-device ML Kit OCR reads text; offline halal rules engine returns verdict |
| **Barcode Scanner** | Scans product barcodes → fetches ingredients from Open Food Facts (free, no key) → offline verdict |
| **Halal Venue Map** | Interactive OpenStreetMap showing verified halal restaurants, markets, and stores |
| **Community Submissions** | Users suggest new venues; admins approve or deny with reasons |
| **Guest Mode** | Browse and scan without an account; restricted from submitting venues |
| **Admin Panel** | Manage pending, verified, and denied venue submissions in real time |
| **Blockchain Registry** *(Phase 2)* | Read-only on-chain halal certificate verification via Polygon Amoy testnet |

---

## Tech Stack

- **Frontend**: Flutter / Dart
- **Backend**: Firebase Authentication + Cloud Firestore
- **On-device OCR**: Google ML Kit (`google_mlkit_text_recognition`)
- **Barcode**: `mobile_scanner` (ML Kit)
- **Halal Engine**: Offline rules-based ingredient classifier (`lib/services/halal_engine.dart`)
- **Product Data**: Open Food Facts API (free, no key required)
- **Maps**: OpenStreetMap via `flutter_map`
- **State Management**: Provider
- **Blockchain** *(optional)*: `web3dart` — read-only Polygon Amoy testnet

---

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart        # Firebase config (not committed — see Setup)
├── models/
│   └── halal_location.dart      # Venue data model
├── providers/
│   └── auth_provider.dart       # Authentication state
├── screens/
│   ├── scanner_screen.dart      # Ingredient & barcode scanner
│   ├── map_screen.dart          # Halal venue map
│   ├── admin_screen.dart        # Admin panel
│   ├── dashboard_screen.dart
│   ├── login_screen.dart / signin_screen.dart / signup_screen.dart
│   ├── suggest_location_screen.dart
│   ├── guidelines_screen.dart
│   └── about_screen.dart
├── services/
│   ├── halal_engine.dart        # Offline halal rules engine
│   ├── ocr_service.dart         # On-device OCR (ML Kit)
│   ├── barcode_service.dart     # Open Food Facts lookup
│   ├── location_service.dart    # Firestore venue operations
│   ├── blockchain_config.dart   # Blockchain feature flag & config
│   └── blockchain_service.dart  # Web3 read-only client
└── widgets/
    ├── app_theme.dart
    └── glass_container.dart

contracts/
└── HalalRegistry.sol            # Solidity smart contract (Phase 2)

test/
├── halal_engine_test.dart
├── blockchain_test.dart
└── widget_test.dart
```

---

## Setup

### Prerequisites

- Flutter SDK ≥ 3.0
- Android Studio / Xcode
- Firebase project (see below)

### 1. Clone the repository

```bash
git clone https://github.com/kayting4000/Halalcheck.git
cd Halalcheck
```

### 2. Configure Firebase

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** (Google, Email/Password, Anonymous)
3. Enable **Cloud Firestore** (Production mode)
4. Run `flutterfire configure` to generate `lib/firebase_options.dart`
5. Place `google-services.json` in `android/app/`

### 3. Environment variables

Copy the template and fill in your values:

```bash
cp assets/.env.example assets/.env
```

> `assets/.env` is git-ignored and must never be committed.

### 4. Firestore security rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /locations/{locationId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.token.email == '<your-admin-email>';
      match /reviews/{reviewId} {
        allow read: if true;
        allow create: if request.auth != null;
      }
    }
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

### 5. Install dependencies & run

```bash
flutter pub get
flutter run
```

### 6. Build release APK

```bash
flutter build apk --release --no-tree-shake-icons
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Halal Analysis — How It Works

```
Camera / Barcode
      │
      ▼
ML Kit OCR / Open Food Facts
      │  (ingredient text)
      ▼
HalalEngine (offline)
      │  matches against haram / doubtful / halal marker database
      ▼
Verdict: Halal ✅ | Haram ❌ | Doubtful ⚠️
```

No cloud AI API key is required for scanning. The app works fully offline for ingredient analysis.

---

## Blockchain Integration (Phase 2 — Optional)

- Smart contract: `contracts/HalalRegistry.sol` (Solidity, Polygon Amoy testnet)
- The app is **read-only** — it verifies certificates but never holds private keys
- Enable via `BlockchainConfig.enabled = true` in `lib/services/blockchain_config.dart`
- Certificate writes are performed by authorized certifiers through a backend relay

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "feat: description"`
4. Push and open a Pull Request

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## Citation

If you use this software in academic work, please cite it via the Zenodo DOI badge on this repository.
