# AGENTS.md: working on mobile-app

Rules for anyone (human or AI) changing code here. Read [`ARCHITECTURE.md`](ARCHITECTURE.md) for the
design and [`docs/PRD.md`](docs/PRD.md) for the requirements. When the code and these docs disagree,
fix one of them in the same change.

## Architecture: the dependency rule

```
presentation ─┐
              ├─> application ─> domain
infrastructure┘        (ports)     (pure Dart)
app/ (composition root) wires everything
```

| Layer | May import | Never imports |
|---|---|---|
| `features/*/domain` | `dart:core` libraries, `package:meta`, `lib/core` | Flutter, any other package, other layers |
| `features/*/application` | its domain, other features' domain types, `lib/core` | Flutter, infrastructure, presentation |
| `features/*/infrastructure` | domain, application, packages (dio, hive_ce, flutter_litert, …) | presentation |
| `features/*/presentation` | application, domain types, Flutter, Riverpod, `lib/ui/theme` | infrastructure, dio, hive, tflite |
| `lib/app` | everything | – |

`test/architecture_test.dart` enforces this table. Never weaken it to make a change pass.

## Where code goes

| You are adding… | Put it in |
|---|---|
| A rule or invariant ("confidence in 0–1", status rule) | `domain` (entity or value object) |
| A step the user triggers ("diagnose", "sync", "download model") | `application` use case returning `Result<T>` |
| Anything doing I/O (HTTP, Hive, files, LiteRT, secure storage) | `infrastructure` adapter implementing a port |
| A screen, widget or notifier | `presentation` |
| Provider wiring, routes, theme | `lib/app` |
| Shared types (`Result`, `Failure`, `Clock`) | `lib/core` |

## Adding a feature end to end (checklist)
1. Requirement ID in `docs/PRD.md`, and its screen state in `design/STITCH_PROMPTS.md` if it has UI.
2. Domain types plus unit tests.
3. Port(s) and a use case plus unit tests with fakes.
4. Adapter plus an infrastructure test (temp dir, mock HTTP adapter).
5. Provider in `lib/app/providers.dart`; notifier and widget plus widget tests (each state, contrast, reduce motion).
6. Update `docs/PROGRESS.md` with the evidence. Commit as `feat(mobile-app): <ID> …`.

## Conventions
- **Errors:** use cases return `Result<T>`. They never throw across layers. Every `Failure` subtype is
  handled with an exhaustive `switch` in the UI, using the copy from PRD §5.
- **No code generation:** no freezed, json_serializable, riverpod_generator or Hive adapters. Use Dart 3
  sealed classes, records and hand-written `toMap`/`fromMap`.
- **Providers** are declared only in `lib/app/providers.dart`. Notifiers depend on use cases, never
  on adapters. Tests use `ProviderScope(overrides: …)`.
- **Theme:** colours, text styles, spacing, radius and motion come only from `lib/ui/theme/`, whose
  tokens are copied from `designs/field_diagnostic_tool/DESIGN.md`. No raw `Color(0x…)` or durations in widgets.
- **Diagnosis status** is always icon + label + colour (`DiagnosisColors` extension).
- **Motion:** use the tokens in `motion.dart`. Every animation checks `MediaQuery.disableAnimationsOf(context)`
  and the reduce-motion setting.
- **Strings:** user copy comes from the Stitch prompts and PRD §5; keep it plain. Put strings in one place
  per feature (ready for l10n in F6).
- **IDs and time:** `uuid` v4 made on the phone; timestamps in UTC (ISO 8601 with `Z`) on the wire.
- **HTTP:** one Dio from `shared/http/api_client.dart`. Never create Dio elsewhere. Every request
  gets `X-Request-ID`.
- **Secrets:** the access key lives only in `flutter_secure_storage`. Never log it, put it in Hive or
  commit it.

## Model and preprocessing rules
- **Bundled model:** `assets/models/crop_disease_v1.{tflite,json}` is copied from
  `python-ml-service/models/` and never edited. A new model means a new version and new file names.
- **No hardcoded model facts:** class names, threshold and input shape are read from the json, never
  hardcoded.
- **Preprocessing parity:** preprocessing must match Python exactly (resize shorter side to 256 bilinear →
  centre crop 224 → RGB float32 / 255, NHWC). Any change to `preprocess.dart` must keep
  `test/infrastructure/preprocess_golden_test.dart` passing (max abs diff ≤ 1e-4 against the Python fixture).
- **Inference** runs off the UI thread. Reuse one interpreter per active model, and close it on swap or dispose.
- **Swapping models:** verify sha256 **before** activation. Keep the previous model. The bundled v1 is the last fallback.

## Platform rules
- **Android:**
  - minSdk 26, targetSdk 36
  - cleartext HTTP only in `src/debug` network security config
  - native libraries must be **16 KB page-size aligned** ([Android docs](https://developer.android.com/guide/practices/page-sizes)): check with `tool/check_16kb.dart` and run once on a 16 KB emulator before a release
- **iOS:**
  - deployment target 15.0
  - `Info.plist` has `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` and (debug) `NSAllowsLocalNetworking`
  - run `pod install` after adding plugins

## Tests

| Kind | Where | Command | Needs |
|---|---|---|---|
| Unit (domain, application) | `test/features/**` | `flutter test` | nothing |
| Infrastructure (Hive temp dir, HTTP mock, preprocessing golden) | `test/features/**/infrastructure` | `flutter test` | fixtures |
| Widget (states, contrast, reduce motion) | `test/features/**/presentation` | `flutter test` | nothing |
| Architecture | `test/architecture_test.dart` | `flutter test` | nothing |
| End to end | `integration_test/` | `flutter test integration_test -d <emulator>` | `docker compose up` at the repo root |

Run the relevant test first, then the full suite once before committing.

## Do / don't
- **Do:**
  - write locally before showing a result
  - make sync and model updates safe to repeat
  - keep diffs small
  - follow the existing pattern in a neighbouring feature
- **Don't:**
  - call the Python services directly (only go-backend)
  - block the UI on the network
  - add a package without updating ARCHITECTURE §12 and the decision log
  - disable a lint or test to get green
  - invent UI that isn't in the Stitch prompts

## Definition of done
- [ ] The requirement's acceptance criterion (ROADMAP) passes
- [ ] `flutter analyze` clean; `flutter test` green; integration test green if the change touches backend flows
- [ ] Works in airplane mode where the PRD says so
- [ ] Reduce motion, contrast and 48 dp targets respected
- [ ] `docs/PROGRESS.md` updated with evidence
