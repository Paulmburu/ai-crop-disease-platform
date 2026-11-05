# mobile-app

The Flutter app of the crop disease platform. It diagnoses a potato leaf **on the phone** with a
LiteRT model and works fully offline. When online it syncs diagnoses, updates its model, asks the
server for a second opinion and shows cited treatment advice, all through
[`go-backend`](../go-backend/README.md).

**Status: runs end to end.** On-device LiteRT diagnosis, Hive storage, and go-backend sync, advice,
second opinion and model updates all work on the emulator (checked 2026-11-04). Every screen also
runs on mock data (`SCENARIO`) for design states and golden tests. Next: the Python-fixture
preprocessing parity test, resumable downloads, secure storage for the key.

## Documents

| Document | Read it for |
|---|---|
| [`docs/PRD.md`](docs/PRD.md) | What the app must do: users, numbered requirements, error catalogue, budgets |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | How it is built: DDD layers, features, flows, theme, dependencies |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Milestones D0, F0–F6 with acceptance criteria |
| [`docs/PROGRESS.md`](docs/PROGRESS.md) | What is done, with evidence, plus the decision log |
| [`docs/UI_IMPLEMENTATION.md`](docs/UI_IMPLEMENTATION.md) | How each screen maps to the designs, and the Stitch corrections |
| [`docs/UI_TASKS.md`](docs/UI_TASKS.md) | The UI phases and tasks (all done) |
| [`../docs/PRESENTATION_SLIDES.md`](../docs/PRESENTATION_SLIDES.md) | The FlutterconKE talk built on this app; deck in `../docs/presentation/` |
| [`AGENTS.md`](AGENTS.md) | Rules for anyone (human or AI) writing code here |
| [`design/STITCH_PROMPTS.md`](design/STITCH_PROMPTS.md) | Google Stitch prompts for every screen and state |
| [`../docs/API_CONTRACT.md`](../docs/API_CONTRACT.md) | The backend endpoints the app calls |

## Prerequisites

| Tool | Version | Install / check |
|---|---|---|
| Flutter | **3.41.6** (Dart 3.11.4), the installed version; no upgrade planned | `flutter --version` |
| Android Studio | current, with SDK Platform 36, Build-Tools, NDK **r28+**, CMake | `flutter doctor --android-licenses` |
| Android emulator | Pixel 7-class, API 35/36, **plus one 16 KB page-size image** (to check the LiteRT native library) | Device Manager in Android Studio |
| Xcode | 26.x with an iOS 18+ simulator (iOS is secondary for the talk) | `xcode-select -p`, `pod --version` |
| Backend | the repo's Docker stack | from the repo root: `docker compose up -d --build --wait` |

Check everything with `flutter doctor -v`.

**Target platforms:**
- **Android:** minSdk 26, targetSdk 36.
- **iOS:** 15.0 or later.

## Quick start

**End to end (real model, real backend).** Start the backend from the repo root first
(`docker compose up -d --build --wait`, with Ollama running; see the [root README](../README.md#run-the-app-end-to-end-on-an-emulator)), then:

```bash
cd mobile-app
flutter pub get
flutter run -d emulator-5554                  # real adapters, backend at http://10.0.2.2:8080
flutter run --dart-define=SERVER_URL=http://192.168.1.20:8080   # real phone: your laptop's IP
```

What runs for real: on-device LiteRT (`flutter_litert`, bundled `assets/models/crop_disease_v1.*`),
diagnoses and settings in Hive, photos from camera, gallery or the bundled samples ("Use a sample
photo"), and go-backend over HTTP for `/ready`, sync (automatic when online), second opinion, advice
and model updates. The access key defaults to `dev-key` (`--dart-define=API_KEY=...`).

**Mock data (no backend; design states, golden tests, offline demos):**
```bash
flutter run --dart-define=SCENARIO=online     # or offline, firstRun, uncertainPhoto, adviceDown,
                                              # updateAvailable, checksumFail, syncRejected, onboarding
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

## Commands

| Command | What |
|---|---|
| `flutter analyze` | Lints (very_good_analysis), must be clean |
| `flutter test` | Unit, widget, golden and architecture tests; no device needed |
| `flutter test --update-goldens` | Regenerate `test/goldens/` after an intended UI change |
| `flutter test --update-goldens --dart-define=SHOT_DPR=3 --dart-define=SHOT_DIR=$PWD/../docs/presentation/screens/` | 3x screenshots of every screen for slides (goldens untouched) |
| `flutter test integration_test -d emulator-5554` | End-to-end on the emulator against the Docker backend (from F2) |
| `dart run tool/check_16kb.dart build/app/outputs/flutter-apk/app-release.apk` | Native-library alignment check (added in F1) |
| `flutter build apk --release --split-per-abi` | Release APKs (debug-signed for the talk) |

## Design workflow

1. Generate the screens in Google Stitch with [`design/STITCH_PROMPTS.md`](design/STITCH_PROMPTS.md).
2. Export DESIGN.md, the HTML and the PNGs into `designs/` (done).
3. The Flutter theme (`lib/ui/theme/`) takes its tokens from `designs/field_diagnostic_tool/DESIGN.md`. The PNGs are
   visual references for widget tests.
