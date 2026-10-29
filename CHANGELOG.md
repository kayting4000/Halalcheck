# Changelog

## Latest Update - Major Feature Release

### 🎯 New Features

#### 1. **Enhanced Scanner with Multiple Modes**
- **Barcode Scanner**: Scan product barcodes to get instant halal verification
- **Visual Product Scanner**: Take photos of products/food to analyze by appearance
- **Ingredient Scanner**: Original ingredient list analysis (existing feature)
- Groq AI integration for all scanning modes with vision capabilities
- Frosted glass UI for result sheets with smooth animations

#### 2. **Guest Mode (Anonymous Sign-In)**
- "Continue as Guest" button on sign-in screen
- Browse venues, scan products, and view halal locations without account
- Guest badge displayed in drawer
- Restricted from suggesting venues (prompts to sign in)
- Seamless upgrade to full account from drawer

#### 3. **Admin Panel Enhancements**
- **Accept/Deny System**: Admins can now approve OR deny venue suggestions
- Deny with reason dialog for transparency
- Pending, Verified, and Denied tabs for better organization
- Status tracking: `pending`, `verified`, `denied`
- Improved venue management workflow

#### 4. **Map & Navigation Improvements**
- **Direct Navigation**: Tap "GET DIRECTIONS" to open Google Maps with route
- Long-press map to suggest venue (with guest restriction)
- Frosted glass bottom sheet for venue details
- Improved marker icons by venue type (restaurant/market/store)
- Search and filter by venue type

#### 5. **Venue Submission Fixes**
- Fixed timeout issues with proper error handling (15s timeout)
- Better error messages for Firestore permission issues
- Form validation with clear feedback
- Frosted glass UI throughout submission flow
- Status field added to track venue lifecycle

### 🎨 UI/UX Improvements
- Frosted glass (glassmorphism) design throughout the app
- BackdropFilter blur effects on dialogs and sheets
- Smooth animations and transitions
- Guest mode indicators and badges
- Improved error messaging with actionable suggestions

### 🔧 Technical Changes

#### Modified Files:
- `lib/services/gemini_service.dart` - Added barcode & visual product analysis
- `lib/services/location_service.dart` - Added deny/status management
- `lib/models/halal_location.dart` - Added status & denyReason fields
- `lib/providers/auth_provider.dart` - Added guest mode (anonymous auth)
- `lib/screens/signin_screen.dart` - Added "Continue as Guest" button
- `lib/screens/scanner_screen.dart` - Ready for multi-mode scanning
- `lib/screens/map_screen.dart` - Added navigation & guest restrictions
- `lib/screens/suggest_location_screen.dart` - Fixed submission with timeout
- `lib/screens/admin_screen.dart` - Added deny functionality (ready for UI)
- `lib/screens/main_screen.dart` - Guest badge & sign-in prompt in drawer
- `pubspec.yaml` - Added `mobile_scanner: ^6.0.0` for barcode scanning
- `android/gradle.properties` - Reduced JVM memory to 2GB for stability

### 🔐 Firebase Setup Required
1. Enable Cloud Firestore API in Firebase Console
2. Create Firestore database (Production mode)
3. Update Firestore security rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /locations/{docId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null;
    }
    match /locations/{docId}/reviews/{reviewId} {
      allow read: if true;
      allow create: if request.auth != null;
    }
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 📱 Build Configuration
- Reduced Gradle JVM heap from 8GB to 2GB
- Disabled parallel builds for memory efficiency
- Optimized for systems with limited RAM

### 🐛 Bug Fixes
- Fixed venue submission hanging indefinitely
- Fixed Firestore permission denied errors
- Fixed memory issues during APK build
- Added proper timeout handling (15 seconds)
- Improved error messages for debugging

### 🚀 Next Steps
To build the APK:
```bash
flutter clean
flutter pub get
flutter build apk --release
```

APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

---

## Phase 2 — Blockchain Integration (In Progress)

### 🔗 On-Chain Halal Certificate Registry

#### New Files
- `contracts/HalalRegistry.sol` — Solidity smart contract for immutable halal certificate storage
- `lib/services/blockchain_config.dart` — Configuration (feature flag, RPC URL, contract address)
- `lib/services/blockchain_service.dart` — Read-only Web3 client + pure-Dart keccak256
- `test/blockchain_test.dart` — Unit tests for result logic, config, and keccak256

#### Modified Files
- `pubspec.yaml` — Added `web3dart: ^2.7.3` dependency
- `lib/screens/scanner_screen.dart` — Blockchain verification after barcode lookup; "Blockchain Verified" badge; API info dialog entry
- `lib/screens/admin_screen.dart` — Blockchain registry status card in Tools tab

#### Design Decisions
- **Read-only from app**: No private keys in the mobile app. Certificate writes (issue/revoke) are performed by authorized certifiers through a backend relay (e.g., Cloud Function).
- **Feature flag**: `BlockchainConfig.enabled` — when false, the app falls back to Phase 1 offline analysis only.
- **Network**: Polygon Amoy testnet (chainId 80002). Replace RPC URL with your own Infura/Alchemy/QuickNode endpoint for production.
- **Product ID**: `keccak256("halal:barcode:<barcode>")` — deterministic mapping from barcode to on-chain record.

#### Open Decisions (from BLOCKCHAIN_PLAN.md)
1. Public chain (Polygon mainnet) vs. private/permissioned chain?
2. Who are the "certifier" identities allowed to write? (access control)
3. Wallet/key custody for admin writes (Thirdweb vs. custom backend signer)?
4. Should venue verification also be mirrored, or only product certs?

---

**Project**: Halal Scanner  
**Firebase Project**: halalscanner-c7667  
**Admin Email**: habibunnajalkaytin@gmail.com
