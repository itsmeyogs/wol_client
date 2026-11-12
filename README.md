# WoL Gateway Client

A cross-platform Flutter application (Android, Windows, Web) for managing Wake-on-LAN (WoL) gateways and remotely waking, checking, and managing LAN devices.

This client connects to a companion gateway service. For the official gateway server, see:
- **Gateway Repository**: [WOLGatewayAndroid](https://github.com/itsmeyogs/WOLGatewayAndroid)

---

## 🚀 Download Release & Live Web

- 📱 **Android & 💻 Windows**: Download pre-built installer/APK binaries from 👉 **[GitHub Releases](../../releases)**.
- 🌐 **Web Version**: No download required. The web application is hosted and accessible at 👉 **[wol.yogi-islami.my.id](https://wol.yogi-islami.my.id)**.

The web app connects directly to the configured gateway API. If it shows **“Gateway cannot be reached,”** check the browser console for a CORS error. For example:

```text
Access to XMLHttpRequest at 'https://gateway.example.com/api/v1/health' from origin 'https://wol.yogi-islami.my.id' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

If the console reports a CORS error, add the web app's origin to the gateway's CORS Origins. For production, add `https://wol.yogi-islami.my.id`. See [WOLGatewayAndroid — CORS Allowed Origins](https://github.com/itsmeyogs/WOLGatewayAndroid#cors-allowed-origins).

---

## ✨ Features

- **Guest-First & Offline Ready**: Works completely locally without an account using local SQLite storage.
- **Multi-Gateway Support**: Connect and switch across multiple gateway instances via Base URL and API token.
- **LAN Discovery & Manual Add**: Scan local networks exposed by the gateway or manually input target MAC addresses.
- **Device Control**: Send Wake-on-LAN packets, monitor status, and inspect health diagnostics.
- **Optional Cloud Sync**: Sign in with Google or Email/Password to synchronize gateway profiles across multiple devices using Firebase Firestore.

---

## 🛠️ Build Release

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable channel)
- Dart 3.x+

### 1. Android
Build the APK or App Bundle:

```bash
# APK
flutter build apk --release

# App Bundle (for Google Play)
flutter build appbundle --release
```
**Output**: `build/app/outputs/flutter-apk/app-release.apk`

---

### 2. Windows
Requires Visual Studio with "Desktop development with C++" workload installed.

```bash
flutter build windows --release
```
**Output**: `build/windows/x64/runner/Release/`

#### Packaging Installer (Optional)
An Inno Setup script is available at `windows/installer/installer.iss`. Compile it with [Inno Setup](https://jrsoftware.org/isinfo.php) to produce a standalone installer executable.

---

### 3. Web
Ensure SQLite WASM assets (`web/sqlite3.wasm` and `web/sqflite_sw.js`) are present in `web/`.

```bash
# Standard Web build
flutter build web --release

# Or with WebAssembly support
flutter build web --release --wasm
```
**Output**: `build/web/`

---

## 🔥 Firebase & Google Sign-In Setup

Cloud sync is optional. To enable Firebase Authentication and Firestore synchronization, set up your Firebase project:

### 1. Basic Firebase Setup
1. Create a project in the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Authentication** (Google & Email/Password providers).
3. Enable **Cloud Firestore** and apply the security rules found in `firestore.rules`.
4. Configure FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` (reference template: `lib/firebase_options.dart.example`).

---

### 2. Google Sign-In Configuration

#### Android
1. Generate your SHA-1 and SHA-256 fingerprints:
   ```bash
   cd android
   ./gradlew signingReport
   ```
2. In the Firebase Console, go to **Project Settings > Your Apps > Android app** and add both fingerprints.
3. Download the updated `google-services.json` and place it in `android/app/`.

#### Web
1. Ensure the Google provider is enabled under **Authentication > Sign-in method**.
2. Authorized domains in Firebase Console should include your hosting domain (`wol.yogi-islami.my.id`) or `localhost` for local debugging.

#### Windows (Loopback OAuth)
Windows authentication uses a local loopback server to handle OAuth callbacks:
1. Open [Google Cloud Console](https://console.cloud.google.com/) under the same Firebase project.
2. Go to **APIs & Services > Credentials**.
3. Locate or create an **OAuth 2.0 Client ID** of type **Web Application**.
4. Configure the following URIs:
   - **Authorized JavaScript origins**:
     ```
     http://localhost:49152
     ```
   - **Authorized redirect URIs**:
     ```
     http://localhost:49152
     ```
5. Update `_googleWebClientId` in `lib/core/auth/google_windows_sign_in_io.dart` with your Web Client ID if running your own Firebase project.
