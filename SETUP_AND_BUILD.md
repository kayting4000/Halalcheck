# How to Build the Halal Scanner APK Yourself

An APK is a compiled Android app. The `Halalcheck/` folder is **source code**,
so it must be compiled on a machine that has the Android/Flutter build tools.
This guide walks you through installing those and producing the APK.

> The background auto-builder was stopped so you can download the tools
> yourself. Partial files it left behind are in `..\_toolchain\` — safe to
> delete once you're set up.

---

## Option 1 (EASIEST): Android Studio — installs everything at once

Android Studio bundles the **Flutter plugin, Android SDK, and a JDK 17**, so you
don't have to wire up pieces manually.

1. **Install Android Studio** → https://developer.android.com/studio
2. Open Android Studio → **More Actions → SDK Manager**
   - SDK Platforms tab → check **Android 14 (API 34)** and **Android 15 (API 35)**
   - SDK Tools tab → check **Android SDK Build-Tools 34/35**, **Android SDK
     Command-line Tools**, **Android Emulator** (optional)
3. Install the **Flutter plugin**: Settings/Preferences → Plugins → search
   "Flutter" → Install → restart. (This also installs Dart.)
4. Install the **Flutter SDK**: Settings → Languages & Frameworks → Flutter →
   point to a folder (e.g. `C:\src\flutter`). If empty, Android Studio offers to
   download the SDK for you. Or download manually (Option 2, step 1).
5. Open the `Halalcheck` folder as a project.
6. In the terminal (bottom panel) run:

   ```bash
   flutter pub get
   flutter build apk --release --no-tree-shake-icons
   ```

7. Your APK appears at:
   `Halalcheck\build\app\outputs\flutter-apk\app-release.apk`

---

## Option 2 (Manual): install each tool yourself

### 1) Flutter SDK
- Download (Windows, ~1.8 GB): the latest stable zip from
  https://docs.flutter.dev/get-started/install/windows
  (or directly: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.47.7-stable.zip)
- Extract to e.g. `C:\src\flutter`
- Add `C:\src\flutter\bin` to your **PATH** environment variable.

### 2) Android SDK (command-line tools)
- Download: https://developer.android.com/studio#command-tools
  (Windows zip, ~150 MB)
- Extract, then run `sdkmanager` to install the required packages:
  ```bash
  sdkmanager "platform-tools" "platforms;android-34" "platforms;android-35" "build-tools;34.0.0" "build-tools;35.0.0"
  sdkmanager --licenses     # accept all
  ```
- Set environment variable `ANDROID_HOME` (or `ANDROID_SDK_ROOT`) to the SDK path.
- Tell Flutter about it: `flutter config --android-sdk <path>`

### 3) JDK 17
- The project's Gradle needs **JDK 17** (JDK 8 is too old).
- Easiest: the JDK bundled with Android Studio (`...\Android Studio\jbr`).
- Or download Microsoft OpenJDK 17: https://aka.ms/download-jdk/microsoft-jdk-17-windows-x64.zip
- Set `JAVA_HOME` to that folder.

### 4) Verify + build
```bash
flutter doctor          # should show no critical errors
flutter pub get
flutter build apk --release --no-tree-shake-icons
```
APK output: `Halalcheck\build\app\outputs\flutter-apk\app-release.apk`

---

## Install the APK on your phone
- Copy `app-release.apk` to your phone and tap it (enable "Install unknown apps"), **or**
- With the phone plugged in (USB debugging on):
  ```bash
  flutter install
  # or: adb install build\app\outputs\flutter-apk\app-release.apk
  ```

## Notes
- `--no-tree-shake-icons` is required — the app's icon tree-shaking crashes
  Gradle on some setups (documented in CHANGELOG.md).
- Firebase config (`google-services.json`) is already included in
  `android/app/`, so the app will build and connect to the existing Firebase
  project `halalscanner-c7667`.
