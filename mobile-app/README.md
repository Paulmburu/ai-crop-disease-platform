# mobile-app

The Flutter app of the crop disease platform. It diagnoses a potato leaf **on the phone** with a
LiteRT model and works fully offline. When online it syncs diagnoses, updates its model, asks the
server for a second opinion and shows cited treatment advice, all through
[`go-backend`](../go-backend/README.md).

**Status: design phase, no code yet.** Work starts at milestone F0 ([`docs/ROADMAP.md`](docs/ROADMAP.md)).

## Documents

| Document | Read it for |
|---|---|
| [`docs/PRD.md`](docs/PRD.md) | What the app must do: users, numbered requirements, error catalogue, budgets |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | How it is built: DDD layers, features, flows, theme, dependencies |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Milestones D0, F0–F6 with acceptance criteria |
| [`docs/PROGRESS.md`](docs/PROGRESS.md) | What is done, with evidence, plus the decision log |
| [`AGENTS.md`](AGENTS.md) | Rules for anyone (human or AI) writing code here |
| [`design/STITCH_PROMPTS.md`](design/STITCH_PROMPTS.md) | Google Stitch prompts for every screen and state |
| [`../docs/API_CONTRACT.md`](../docs/API_CONTRACT.md) | The backend endpoints the app calls |

## Prerequisites

| Tool | Version | Install / check |
|---|---|---|
| Flutter | **3.47.9** stable (Dart 3.13) | Installed with Homebrew here: `brew upgrade --cask flutter`, then `flutter --version` |
| Android Studio | current, with SDK Platform 36, Build-Tools, NDK **r28+**, CMake | `flutter doctor --android-licenses` |
| Android emulator | Pixel 7-class, API 35/36, **plus one 16 KB page-size image** (to check the LiteRT native library) | Device Manager in Android Studio |
| Xcode | 26.x with an iOS 18+ simulator (iOS is secondary for the talk) | `xcode-select -p`, `pod --version` |
| Backend | the repo's Docker stack | from the repo root: `docker compose up -d --build --wait` |

Check everything with `flutter doctor -v`.

**Target platforms:**
- **Android:** minSdk 26, targetSdk 36.
- **iOS:** 15.0 or later.

## Quick start (available from F0)

```bash
cd mobile-app
flutter pub get
cp ../python-ml-service/models/crop_disease_v1.{tflite,json} assets/models/   # bundled model
flutter run                         # pick the emulator
```

The model files are produced by `python-ml-service/scripts/export_tflite.py` (see the
[root README](../README.md#step-by-step-from-a-fresh-clone)). Never edit them by hand. A new model
gets a new version and new file names.

## Connecting to the backend

| Where the app runs | Base URL (Settings → Server address) |
|---|---|
| Android emulator | `http://10.0.2.2:8080` |
| iOS simulator | `http://localhost:8080` |
| Real phone on the same Wi-Fi | `http://<laptop IP>:8080` (`ipconfig getifaddr en0`); allow it in the macOS firewall |

The access key for local development is `dev-key`.

Plain HTTP is allowed **only in debug builds**:
- **Android:** `android/app/src/debug/res/xml/network_security_config.xml`.
- **iOS:** `NSAllowsLocalNetworking` in `Info.plist`.

Release builds use HTTPS only.

To test model updates, publish a v2 on the backend. Export it as `crop_disease_v2.*` into
`python-ml-service/models/`, then run `docker compose restart go-backend` (it publishes new files on
start). Or call the admin API with `dev-admin-key`:
```bash
curl -X POST localhost:8080/api/v1/model-releases -H 'X-API-Key: dev-admin-key' \
  -H 'Content-Type: application/json' \
  -d '{"version":"v2","class_labels":["Potato___Early_blight","Potato___Late_blight","Potato___healthy"],"confidence_threshold":0.5,"input_shape":[1,224,224,3]}'
```

## Commands (from F0)

| Command | What |
|---|---|
| `flutter analyze` | Lints (very_good_analysis), must be clean |
| `flutter test` | Unit, widget, golden and architecture tests; no device needed |
| `flutter test integration_test -d emulator-5554` | End-to-end on the emulator against the Docker backend |
| `dart run tool/check_16kb.dart build/app/outputs/flutter-apk/app-release.apk` | Native-library alignment check (added in F1) |
| `flutter build apk --release --split-per-abi` | Release APKs (debug-signed for the talk) |

## Design workflow

1. Generate the screens in Google Stitch with [`design/STITCH_PROMPTS.md`](design/STITCH_PROMPTS.md).
2. Export DESIGN.md, the HTML and the PNGs into `design/export/`.
3. The Flutter theme (`lib/app/theme/`) takes its tokens from `design/export/DESIGN.md`. The PNGs are
   visual references for widget tests.
