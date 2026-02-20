# TXQR

[![GoDoc](https://godoc.org/github.com/divan/txqr?status.svg)](https://godoc.org/github.com/divan/txqr)

TXQR (Transfer via QR) is a protocol and set of tools and libs to transfer data via animated QR codes. It uses [fountain codes](https://en.wikipedia.org/wiki/Fountain_code) for error correction.

See related blog posts for more details:
- [Animated QR data transfer with Gomobile and Gopherjs](https://divan.github.io/posts/animatedqr/)
- [Fountain codes and animated QR](https://divan.github.io/posts/fountaincodes/)

## Demo

![Demo](./docs/demo.gif)

Reader iOS app in the demo (uses this lib via Gomobile): [https://github.com/divan/txqr-reader](https://github.com/divan/txqr-reader)

## Flutter Android Scanner App

A modern Flutter-based Android application that scans and decodes TXQR-encoded animated QR codes. The app reuses the existing Go core library via `gomobile bind`, bridged to Flutter through Kotlin MethodChannels.

### Features

- Real-time QR frame scanning with `mobile_scanner`
- Live progress indicator with animated overlay
- Transfer speed and time tracking
- Data copy-to-clipboard and share actions
- Material 3 UI with dark mode support

### Building the Android App

#### Prerequisites

- Flutter SDK
- Android SDK / Android Studio
- Go 1.16+ (for `gomobile`)
- `gomobile` tool installed: `go install github.com/google/mobile/cmd/gomobile@latest`
- Android NDK installed via Android Studio

#### Steps

1. **Build the Go AAR** (compiles `mobile/decode.go` to Android archive):
   ```bash
   make aar
   ```
   This creates `flutter_app/android/app/libs/txqr.aar` using `gomobile bind -target=android`.

2. **Install Flutter dependencies**:
   ```bash
   cd flutter_app
   flutter pub get
   ```

3. **Run the app on an Android device or emulator**:
   ```bash
   flutter run
   ```

4. **(Optional) Build APK for distribution**:
   ```bash
   flutter build apk --release
   ```

### Project Structure

```
flutter_app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── services/
│   │   └── txqr_service.dart    # MethodChannel client for Go decoder
│   ├── screens/
│   │   ├── scanner_screen.dart  # Camera + QR scanning UI
│   │   └── result_screen.dart   # Results & data display
│   └── widgets/
│       └── qr_scanner_overlay.dart  # Scan overlay with progress arc
├── android/
│   └── app/
│       ├── libs/
│       │   └── txqr.aar         # Go library (built by `make aar`)
│       └── src/main/kotlin/...
│           └── MainActivity.kt  # MethodChannel bridge to Go API
├── pubspec.yaml                 # Flutter dependencies
└── ...
```

### Go Integration

The Flutter app integrates the Go TXQR core library (`mobile/decode.go`) via:

1. **Android AAR** — `gomobile bind -target=android` produces a compiled `.aar` library
2. **MethodChannel** — Kotlin code in `MainActivity.kt` exposes Go methods as platform-level APIs
3. **Dart wrapper** — `TxqrService` in `txqr_service.dart` provides a clean Dart interface

**Exported Go methods:**
- `Decode(data string) error` — Feed a QR frame string
- `IsCompleted() bool` — Check if decoding is finished
- `Data() string` — Get the decoded payload
- `Progress() int` — Decoding progress percentage
- `Speed() string` — Average read speed (human-readable)
- `TotalTime() string` — Total scan duration (human-readable)
- `Reset()` — Reset decoder for new session

### Dependencies

Key Flutter packages:
- `mobile_scanner` — QR code scanning via device camera
- `share_plus` — Share decoded data
- `permission_handler` — Request camera permission

## Automated Tester App

Also see `cmd/txqr-tester` app for automated testing of different encoder parameters.

## License

MIT
