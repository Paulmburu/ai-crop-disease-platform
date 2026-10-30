# PRD: mobile-app (LeafCheck, working name)

| | |
|---|---|
| Status | Draft, design phase |
| Owner | Paul Mburu |
| Related | [`../ARCHITECTURE.md`](../ARCHITECTURE.md) · [`ROADMAP.md`](ROADMAP.md) · [`../../docs/API_CONTRACT.md`](../../docs/API_CONTRACT.md) · [`../../docs/PRESENTATION_PLAN.md`](../../docs/PRESENTATION_PLAN.md) |

## 1. Problem

Smallholder potato farmers lose crops to late blight, which can destroy a field within days in cool,
wet weather. Expert help is far away, and mobile internet in the field is slow, expensive or missing.
A diagnosis app that needs the cloud fails exactly where it's needed:
- **Upload time:** a 3 MB photo over 3G takes about 34 s to reach a server.
- **No network at all:** in the field, often nothing gets through.

The same model running on the phone answers in about 1.9 ms with no data cost (from
[`benchmarks/results.md`](../../benchmarks/results.md)).

## 2. Users

| Persona | Context | Needs |
|---|---|---|
| **Farmer** | In the field, bright sun, one hand, mid-range Android, often offline | A fast, clear answer; what to do next; no account |
| **Extension officer** | Visits many farms, scans many leaves, syncs at the office | History, sync, reliable model version |
| **Presenter** (the talk) | Live demo on an emulator or phone, airplane mode on stage | Predictable flows, visible latency, a recoverable demo |

## 3. Goals and non-goals

**Goals (v1, for the talk):**
1. Diagnose potato early blight, late blight or healthy on the phone, **in airplane mode**.
2. Be honest about uncertainty: below the model's threshold, ask for a better photo.
3. Keep history locally and sync it safely (idempotent) when online.
4. Update the model over the air, safely (checksum, rollback).
5. Give cited advice and a server second opinion when online.

**Non-goals (v1):**
- accounts or login
- crops other than potato
- uploading photos for training
- push notifications
- background sync while the app is closed
- languages other than English
- tablets and web
- Play Store release

Several of these are F6 or later.

## 4. Functional requirements

IDs are used in [`ROADMAP.md`](ROADMAP.md), the tests and the commits. Screen IDs (S1…S10) match
[`../design/STITCH_PROMPTS.md`](../design/STITCH_PROMPTS.md).

### Diagnosis (D)
| ID | Requirement | Screen | Milestone |
|---|---|---|---|
| D1 | Take a photo with the camera or pick one from the gallery | S1, S1a | F1 |
| D2 | Run the bundled or active LiteRT model on the phone with no network; preprocessing matches Python (§8) | S2 | F1 |
| D3 | Show condition, plant, confidence vs threshold, top-3, latency and model version | S3-A/B/C | F1 |
| D4 | If top-1 < threshold, show "Not sure" with retake tips and no disease name as the answer | S3-D | F1 |
| D5 | Save every diagnosis locally (UUID, device id, label, confidence, threshold, model version, captured time, photo path) before showing the result | S3 | F1 |
| D6 | Show recent diagnoses on Scan and a full History grouped by day; open any item as a Result | S1, S5-A | F1 |
| D7 | Delete a diagnosis (photo + record); if already synced, it stays on the server (stated in the dialog) | S3 | F1 |
| D8 | Second opinion: send the photo to `POST /api/v1/predictions` only when the user taps it; show both results | S3-E | F3 |

### Sync (S)
| ID | Requirement | Screen | Milestone |
|---|---|---|---|
| S1 | Each saved diagnosis is queued (`pending`) | S5 | F2 |
| S2 | Sync runs on reconnect (after `/ready` passes), on app resume and on pull-to-refresh; batches ≤ 500 to `POST /api/v1/diagnoses:sync` | S5-B | F2 |
| S3 | `created` and `duplicate` → `synced`; `invalid` → `rejected` with the server's reason shown | S5-A, S5-D | F2 |
| S4 | A crash or timeout mid-sync is safe: the same items are resent and come back as `duplicate` | – | F2 |
| S5 | Show the waiting count and the last sync time | S5-A, S7-B | F2 |

### Model update (M)
| ID | Requirement | Screen | Milestone |
|---|---|---|---|
| M1 | Show the active model: version, labels, size, threshold, installed date, sha256 | S6-A | F4 |
| M2 | Check `GET /model-releases/latest` with `If-None-Match`; 304 = up to date | S6-A/B | F4 |
| M3 | Download with progress and resume (Range); the old model stays active during download | S6-C | F4 |
| M4 | Verify sha256 before activating; on mismatch delete the file and keep the current model | S6-E | F4 |
| M5 | Activate atomically, keep the previous model, allow going back, and keep the bundled v1 as a last resort | S6-D | F4 |
| M6 | The new model's `.json` (labels, threshold, input shape) is used together with the new `.tflite`, never mixed | – | F4 |

### Advice (A)
| ID | Requirement | Screen | Milestone |
|---|---|---|---|
| A1 | Suggested questions per diagnosis plus free text (3–500 characters) | S4-A | F3 |
| A2 | `POST /api/v1/advice` with `class_name`; show a loading state for up to 60 s | S4-B | F3 |
| A3 | Show the answer with `[n]` citations linked to sources (open in browser) and the disclaimer | S4-C | F3 |
| A4 | Offline: say advice needs internet and offer "Ask when online" (queued question) | S4-D | F3 |
| A5 | 503 `advice_unavailable`: say it's unavailable and offer retry; show the short request id | S4-E | F3 |

### Connectivity (C)
| ID | Requirement | Screen | Milestone |
|---|---|---|---|
| C1 | Online means `GET /ready` returned 200 within 2 s, not just that an interface is up | S1-B | F2 |
| C2 | Show online/offline status and an offline banner; scanning is never disabled | S1-A/B | F2 |
| C3 | Per-service status (`ml_service`, `rag_service`) turns second opinion or advice off or on | S3, S7-B | F2 |

### Settings (ST)
| ID | Requirement | Screen | Milestone |
|---|---|---|---|
| ST1 | Server address with presets (emulator, simulator, custom) and the access key, stored securely | S7-A | F2 |
| ST2 | Device id: a UUID generated on first run, shown, never changes | S7-A | F1 |
| ST3 | Theme (light/dark/system) and reduce motion (also follows the OS setting) | S7-A | F5 |
| ST4 | Diagnostics: service status, sync stats, phone/model info | S7-B | F5 |
| ST5 | Speed test: N = 100 on-device runs → p50/p95 | S7-C | F5 |

### Later (F6)
Onboarding (S8), disease library (S9), splash (S10), background sync, field-photo collection with
consent, Swahili.

## 5. Error catalogue (server/device → what the user sees)

| Source | Code / condition | Failure | User sees | Action |
|---|---|---|---|---|
| Device | no network / `/ready` fails | `Offline` | "You're offline. Diagnosis still works." | Retry; queue |
| Server | 401 | `Unauthorized` | "The access key isn't accepted. Check Settings." | Open Settings |
| Server | 422 `validation_error`, `invalid_*` | `Invalid` | The specific detail in plain words (e.g. "The phone's clock was ahead by more than a day…") | Fix / retry |
| Server | 503 `advice_unavailable` / `prediction_unavailable` | `ServerUnavailable` | "… is unavailable right now. Try again in a few minutes." + `Reference: <first 8 chars of request_id>` | Retry |
| Server | 404 `no_release` / `release_withdrawn` | `Invalid` | "No newer model is available." | – |
| Server | 409 `artifact_checksum_mismatch`, or a local sha mismatch | `ChecksumMismatch` | "Download didn't pass the safety check… current model still active." | Try again |
| Device | model fails to load | `ModelLoadFailed` | "Couldn't load model vX. Using the built-in model." (automatic fallback) | – |
| Any | anything else | `Unexpected` | "Something went wrong." + reference | Retry |

## 6. Data and privacy

| Store | Content | Retention |
|---|---|---|
| Hive `diagnoses` | Records (§4 D5), `syncState`, server error if rejected | Until the user deletes |
| Hive `outbox` | Pending ids | Until synced |
| Hive `settings` | Server URL, device id, theme, reduce motion, `schemaVersion` | App lifetime |
| Hive `model` | Active and previous version, path, sha | App lifetime |
| Secure storage | Access key (`flutter_secure_storage`: Keychain / Android Keystore) | Until changed |
| Files | Photos `appDocuments/photos/<id>.jpg`; models `appSupport/models/` | Photos deleted with their diagnosis |

**Privacy rules:**
- **Photos never leave the phone,** except when the user taps "second opinion", and then only that one photo.
- **No personal data:** sync sends no names and no location.
- **Device id** is a random UUID, not a hardware id.

**Migrations:** each box has a `schemaVersion`. Upgrades run at start-up, before the UI, and are tested.

## 7. Non-functional requirements

| Area | Requirement |
|---|---|
| Offline | Every D requirement works in airplane mode |
| Performance | On-device inference p50 < 50 ms on a mid-range phone (laptop CPU: 1.9 ms); preprocessing < 150 ms; tap → result < 1 s (Analyzing is held ≥ 600 ms on purpose) |
| Start-up | Cold start to an interactive Scan screen < 3 s; the model loads in the background |
| Size | Release APK per ABI ≤ 30 MB (model 9.0 MB) |
| Compatibility | Android 8.0+ (minSdk 26), **16 KB page-size compatible** native libraries ([Android requirement](https://developer.android.com/guide/practices/page-sizes)); iOS 15+ |
| Accessibility | WCAG AA contrast; 48 dp targets; TalkBack/VoiceOver labels; status never shown by colour alone; reduce motion respected; text scaling to 200% without clipping |
| Reliability | No data loss on crash (write before showing); sync and model update are safe to repeat |
| Security | Access key in secure storage; HTTPS in release; debug-only cleartext; no secrets in logs |
| Observability | Local ring-buffer log (last 500 lines, no secrets); `X-Request-ID` on every call, shown in errors and Diagnostics |
| Battery/data | No polling; `/ready` only on connectivity change, resume or user action; model download suggests Wi-Fi |

## 8. Model contract (must match the server)

- **Files:** `crop_disease_<v>.tflite` + `crop_disease_<v>.json`, with `model_version`, `input_shape`, `class_names` and `confidence_threshold`.
- **Input:** `float32 [1, 224, 224, 3]`, NHWC, RGB.
  1. Resize the shorter side to 256 (bilinear).
  2. Centre crop to 224.
  3. Divide by 255. Normalisation is inside the model.
- **Output:** `float32 [1, 3]` probabilities in `class_names` order. The status rule is the same as the server's.
- **Accuracy context:** 95.8% on lab photos, 54.8% on PlantDoc field photos. This is why D4 exists, and why the limitations are stated in the talk.

## 9. Success metrics

| Metric | Target |
|---|---|
| Airplane-mode diagnosis of a PlantVillage late-blight leaf | Correct, on stage, every run |
| Phone p50 inference | Measured and on the benchmarks slide |
| Sync | 100 queued → 100 synced; resend → 100 duplicate |
| Crash-free demo runs | 5 rehearsals in a row |

## 10. Open questions

| Question | Default until decided |
|---|---|
| Final app name | "LeafCheck" |
| iOS on stage? | Android only for the talk; iOS must build and run |
| Keep queued advice questions after the app is closed? | Yes, stored in Hive |
| Collect field photos for retraining (consent flow)? | F6 |
