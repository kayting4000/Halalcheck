# Halal Scanner App - Complete Documentation

## 📱 App Overview
**Halal Scanner** is a Flutter mobile application that helps Muslims identify halal food products and find halal-certified venues. It uses AI-powered image analysis and community-driven location mapping.

---

## 🏗️ Architecture Overview

### Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Authentication, Firestore Database)
- **AI Service**: Groq API (Llama 4 Scout model)
- **Maps**: OpenStreetMap with flutter_map
- **State Management**: Provider pattern

---

## 🔑 Key Features

### 1. **Ingredient Scanner** 
- Scan product ingredient labels with camera
- AI analyzes ingredients for halal compliance
- Real-time status: Halal ✅ / Haram ❌ / Doubtful ⚠️

### 2. **Halal Venue Map**
- Interactive map showing verified halal restaurants, markets, and stores
- User location tracking
- Get directions to venues via Google Maps
- Filter by venue type

### 3. **Community Contributions**
- Users can suggest new halal venues
- Admin verification system
- Reviews and ratings for venues

### 4. **User Authentication**
- Google Sign-In
- Email/Password authentication
- Guest mode (limited features)
- Admin role for venue verification

---

## 🔌 Scanner Architecture (API-Free)

### 1. **Halal Analysis — Fully Offline, No API Key**

The previous cloud vision-LLM (Groq/Gemini) integration has been **removed**.
Scanning now works with **no API keys**, **no free-tier limits**, and even
**offline** for the ingredient + verdict path.

**Service Files**:
- `lib/services/ocr_service.dart` — on-device OCR (Google ML Kit)
- `lib/services/halal_engine.dart` — offline halal rules engine
- `lib/services/barcode_service.dart` — Open Food Facts barcode lookup

**Ingredient mode (offline):**
1. Camera photo → **ML Kit OCR** (`google_mlkit_text_recognition`) reads the
   ingredient label **on-device** (no network, no key).
2. **HalalEngine** matches ingredients against a curated haram / doubtful /
   halal marker database and returns a deterministic verdict.

**Barcode mode (free API):**
1. `mobile_scanner` (ML Kit) reads the barcode.
2. **Open Food Facts** (`world.openfoodfacts.org`) returns the product's
   ingredient text — **free, no API key**.
3. **HalalEngine** produces the verdict.

**Response Format** (unchanged, reused by the existing UI):
```json
{
  "status": "halal|haram|doubtful",
  "reason": "Overall summary",
  "ingredients": [ { "name": "Sugar", "status": "halal" } ],
  "purityReport": "Detailed explanation..."
}
```

> ⚠️ **Security:** The old hardcoded Groq API key has been removed from the
> codebase and this document. If it was ever pushed to a public repo, **revoke
> it in the Groq console** immediately.

---

### 2. **Firebase Services**

**Configuration File**: `lib/firebase_options.dart`

#### Firebase Authentication
- **Service**: Firebase Auth
- **Methods**:
  - Google Sign-In
  - Email/Password
  - Anonymous (Guest mode)
- **Admin Email**: `habibunnajalkaytin@gmail.com`

#### Cloud Firestore Database

**Collections Structure**:

**`locations` Collection**:
```
locations/
├── {locationId}/
│   ├── name: string
│   ├── lat: number
│   ├── lng: number
│   ├── type: "restaurant" | "market" | "store"
│   ├── isVerified: boolean
│   ├── status: "pending" | "verified" | "denied"
│   ├── address: string
│   ├── description: string (optional)
│   ├── submittedBy: userId
│   ├── createdAt: timestamp
│   ├── denyReason: string (optional)
│   └── reviews/
│       └── {reviewId}/
│           ├── userId: string
│           ├── userName: string
│           ├── rating: number (1-5)
│           ├── comment: string
│           └── createdAt: timestamp
```

**`users` Collection**:
```
users/
└── {userId}/
    ├── email: string
    └── role: "user" | "admin"
```

**Service File**: `lib/services/location_service.dart`

**Key Methods**:
- `getVerifiedLocations()` - Stream of verified venues
- `getPendingLocations()` - Stream of pending submissions
- `getDeniedLocations()` - Stream of denied submissions
- `submitLocation(location)` - Submit new venue
- `verifyLocation(id)` - Admin approves venue
- `denyLocation(id, reason)` - Admin rejects venue
- `deleteLocation(id)` - Remove venue
- `getReviews(locationId)` - Get venue reviews
- `addReview(locationId, rating, comment)` - Add review

---

### 3. **Google Maps Integration**

**URL Launcher for Directions**:
- **URL Format**: `https://www.google.com/maps/dir/?api=1&destination={lat},{lng}&travelmode=driving`
- **Method**: Opens external Google Maps app
- **Trigger**: "Get Directions" button on venue details

**Map Display**:
- **Provider**: OpenStreetMap (free, no API key needed)
- **Tile Server**: `https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png`
- **Library**: flutter_map package

---

## 📂 App Flow

### 1. **App Startup** (`main.dart`)
```
1. Initialize Flutter bindings
2. Initialize Firebase
3. Load AppAuthProvider (state management)
4. Check authentication state:
   - Not logged in → SignInScreen
   - Logged in as admin → AdminScreen
   - Logged in as user → MainScreen
```

### 2. **Authentication Flow** (`auth_provider.dart`)
```
User opens app
    ↓
Check Firebase Auth state
    ↓
If authenticated:
    - Load user profile from Firestore
    - Check if admin (email match)
    - Set user role
    ↓
If not authenticated:
    - Show SignInScreen
    - Options: Google / Email / Guest
    ↓
After sign-in:
    - Create/update user in Firestore
    - Navigate to appropriate screen
```

### 3. **Scanner Flow** (`scanner_screen.dart`)
```
User opens Scanner tab
    ↓
Request camera permission
    ↓
Initialize camera (prefer back camera)
    ↓
Show viewfinder with alignment guide
    ↓
User taps capture button
    ↓
1. Pause camera preview
2. Capture image
3. Show "Analyzing..." overlay
4. Send to Groq API
5. Parse JSON response
6. Display results in bottom sheet
    ↓
Results show:
    - Status badge (Halal/Haram/Doubtful)
    - Purity report
    - Ingredient breakdown
    ↓
User can scan again or close
```

### 4. **Map Flow** (`map_screen.dart`)
```
User opens Map tab
    ↓
Request location permission
    ↓
Get user's current location
    ↓
Load verified venues from Firestore (real-time stream)
    ↓
Display markers on map:
    - Blue dot = User location
    - Pink markers = Verified venues
    - Gray markers = Unverified
    ↓
User interactions:
    - Tap marker → Show venue details
    - Long press map → Suggest new venue (if not guest)
    - Search bar → Filter venues
    - Category chips → Filter by type
    ↓
Venue details sheet:
    - Name, address, description
    - Reviews and ratings
    - "Get Directions" button → Opens Google Maps
```

### 5. **Admin Flow** (`admin_screen.dart`)
```
Admin logs in
    ↓
View three tabs:
    1. Pending - Venues awaiting approval
    2. Verified - Approved venues
    3. Denied - Rejected venues
    ↓
For each pending venue:
    - View details (name, location, type)
    - Options:
        ✓ Verify → Moves to verified, visible to all users
        ✗ Deny → Requires reason, moves to denied
        🗑️ Delete → Permanently removes
    ↓
Changes sync to Firestore immediately
All users see updates in real-time
```

---

## 🔐 Security & Permissions

### Android Permissions (AndroidManifest.xml)
```xml
- INTERNET - API calls, Firebase
- CAMERA - Ingredient scanning
- ACCESS_FINE_LOCATION - User location on map
- ACCESS_COARSE_LOCATION - Approximate location
```

### Firebase Security Rules (Recommended)
```javascript
// Firestore Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Locations collection
    match /locations/{locationId} {
      allow read: if true; // Public read
      allow create: if request.auth != null; // Authenticated users can suggest
      allow update, delete: if request.auth.token.email == 'habibunnajalkaytin@gmail.com'; // Admin only
      
      // Reviews subcollection
      match /reviews/{reviewId} {
        allow read: if true;
        allow create: if request.auth != null;
      }
    }
  }
}
```

---

## 💾 Data Models

### HalalLocation
```dart
{
  id: String (Firestore doc ID)
  name: String
  lat: double
  lng: double
  type: "restaurant" | "market" | "store"
  isVerified: boolean
  status: "pending" | "verified" | "denied"
  address: String
  description: String? (optional)
  submittedBy: String (user ID)
  createdAt: Timestamp
  denyReason: String? (optional)
}
```

### AnalysisResult
```dart
{
  status: "halal" | "haram" | "doubtful"
  reason: String
  ingredients: List<IngredientResult>
  purityReport: String
}
```

### Review
```dart
{
  id: String
  locationId: String
  userId: String
  userName: String
  rating: double (1-5)
  comment: String
  createdAt: Timestamp
}
```

---

## 🎨 UI/UX Design

### Theme
- **Primary Color**: Magenta (#8E0A57)
- **Background**: Dark (#13010C, #0A0A0A)
- **Glassmorphism**: Frosted glass effect with blur
- **Fonts**: 
  - Philosopher (headings)
  - Century Gothic (body text)

### Key UI Components
1. **Glass Container** - Translucent panels with blur
2. **Gradient Buttons** - Magenta glow effect
3. **Status Badges** - Color-coded (Green=Halal, Red=Haram, Yellow=Doubtful)
4. **Bottom Sheets** - Draggable result panels

---

## 🚀 Build & Deployment

### Development Build
```bash
flutter run
```

### Release APK
```bash
flutter build apk --release --no-tree-shake-icons
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Why `--no-tree-shake-icons`?
The app experienced Gradle daemon crashes with icon tree-shaking enabled. Disabling it increases APK size but ensures stable builds.

---

## 🔄 Real-time Updates

The app uses Firebase Firestore **streams** for real-time data:

```dart
// Example: Map screen listens to location changes
StreamBuilder<List<HalalLocation>>(
  stream: LocationService.getVerifiedLocations(),
  builder: (context, snapshot) {
    // UI updates automatically when data changes
  }
)
```

**Benefits**:
- Admin verifies venue → Instantly appears on all users' maps
- User adds review → Immediately visible to others
- No manual refresh needed

---

## 🐛 Common Issues & Solutions

### 1. **Directions not working**
- **Cause**: Missing URL launcher queries in AndroidManifest.xml
- **Fix**: Added `<queries>` for https and geo schemes

### 2. **Gradle daemon crash during build**
- **Cause**: Icon tree-shaking with large icon sets
- **Fix**: Use `--no-tree-shake-icons` flag

### 3. **Camera not initializing**
- **Cause**: Permission denied or no camera available
- **Fix**: Check permission status, handle errors gracefully

### 4. **API rate limits**
- **Groq API**: Free tier has rate limits
- **Solution**: Implement retry logic or upgrade plan

---

## 📊 API Cost Considerations

### Groq API (Current)
- **Free Tier**: Limited requests per minute
- **Paid Tier**: Higher rate limits
- **Alternative**: Switch to Google Gemini or OpenAI

### Firebase
- **Free Tier (Spark)**:
  - 50K reads/day
  - 20K writes/day
  - 1GB storage
- **Paid Tier (Blaze)**: Pay-as-you-go

---

## 🔮 Future Enhancements

1. **Offline Mode**: Cache scanned products
2. **Barcode Scanner**: Integrate barcode reading
3. **Product Database**: Build local halal product database
4. **Social Features**: Follow users, share findings
5. **Multi-language**: Support Arabic, Malay, etc.
6. **Notifications**: Alert users of new venues nearby
7. **Analytics**: Track popular products/venues

---

## 👨‍💻 Developer Notes

### Key Files
- `main.dart` - App entry point
- `auth_provider.dart` - Authentication state management
- `gemini_service.dart` → *(removed)* replaced by:
  - `halal_engine.dart` - offline halal rules engine (no API)
  - `ocr_service.dart` - on-device OCR (ML Kit)
  - `barcode_service.dart` - Open Food Facts barcode lookup
- `location_service.dart` - Firestore operations
- `map_screen.dart` - Interactive map
- `scanner_screen.dart` - Camera & AI analysis
- `admin_screen.dart` - Admin panel

### Testing
- Test with various product images
- Verify admin functions work correctly
- Check map markers and directions
- Test guest mode limitations

### Maintenance
- Monitor Groq API usage
- Update Firebase security rules
- Keep dependencies updated
- Review user-submitted venues regularly

---

## 📞 Support

**Admin Email**: habibunnajalkaytin@gmail.com

**Firebase Project**: halalscanner-c7667

---

## 📄 License

This is a private project. All rights reserved.

---

**Last Updated**: 2025
**Version**: 1.0.0
**Platform**: Android (iOS support available)
