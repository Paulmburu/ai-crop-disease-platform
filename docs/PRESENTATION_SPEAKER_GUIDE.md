# Speaker guide: "Beyond the API Call"

How to present each of the 24 slides in [`presentation/LeafCheck_FlutterconKE.pptx`](presentation/LeafCheck_FlutterconKE.pptx),
with links you can share with the audience. Outline and sources for every number:
[`PRESENTATION_SLIDES.md`](PRESENTATION_SLIDES.md).

## How to use this guide

- **Speakers:**
  - **Paul:** ML service and RAG. Slides 1–5, 19–20 and 22, plus narrating the demo; about 11:15.
  - **Titus:** the Flutter app and the Go service. Slides 6–18, plus driving the demo; about 20:15.
  - **Shared:** slides 21, 23 and 24.
- **Time:** 40 min = **35 min talk + 5 min Q&A**; the times below add up to 35:00.
- **Two handovers:**
  - **Slide 5 → 6.** Paul says: *"That's how the model is made. Titus will show how the Flutter app runs it."*
  - **Slide 18 → 19.** Titus says: *"The app can diagnose. Paul will show how it explains what to do."*
- **Rules:**
  - One idea per slide.
  - Never read the slide out loud; the slide shows the number, you say why it matters.
  - Point at the screenshot (laser or cursor) every time you name something on it.
- **Numbers** come only from the files cited in `PRESENTATION_SLIDES.md`. Say "modelled" for network times, and "mock" for the second opinion.
- **"Go deeper"** links are for the audience. Share them after the talk (e.g. in the event chat); the deck has no links.

## What is real today (say it before anyone asks)

| Real, measured | Mock (behind the real portsGi) |
|---|---|
| Trained model, eval and field numbers (`ml-training/outputs/`) | In-app inference: LiteRT arrives in **F1** |
| `.tflite` export + laptop benchmark 1.9 ms (`benchmarks/results.md` D2) | Local storage (Hive) and sync: **F1/F2** |
| go-backend: sync, model releases, predictions + advice proxies | Online/offline in the app = the `SCENARIO` flag, not the real network |
| rag-service with cited answers and RAGAS scores | Second-opinion numbers on slide 18 |
| The whole Flutter UI, 91 tests, goldens | – |

Say this on slide 6: *"The UI you'll see runs on mock adapters behind the same ports the real ones plug into. The model,
the backend and the RAG service are real."* If F1/F2 land before the talk, update this box and use demo path B.

---

## Act 1: Why on-device · Paul · 4:00

### 1. Beyond the API Call · 0:45
- **Open with:** "Most AI features in mobile apps are an HTTP call. Today we'll show what happens when you take the API call away."
- **Key points:**
  - Introduce both speakers in one line each.
  - The app is LeafCheck: it diagnoses potato leaves with no internet.
- **Transition:** "Let's start where the app is used: in the field."

### 2. A leaf and no signal · 1:15
- **Open with:** "In cool, wet weather, late blight can destroy a potato field within days."
- **Key points:**
  - Late blight caused the Irish potato famine.
  - The person who needs the answer is standing in the field, where the signal is weakest.
- **Show:** the photo; let it sit for a second.
- **Transition:** "So what does an API call actually cost out there?"
- **Go deeper:** [PlantVillage paper (Hughes & Salathé)](https://arxiv.org/abs/1511.08060), the open dataset behind most leaf-disease models.

### 3. The cost of the API call · 2:00
- **Open with:** "Same 3 MB photo. Same model. Two places to run it."
- **Key points:**
  - On the phone: **1.9 ms**.
  - Through a backend: about 1.3 s on Wi-Fi, 34 s on 3G, 4 min on 2G.
  - Say clearly that the network times are **modelled** from the stated profiles, not measured on a phone.
- **Show:** go left to right; stop on "4 min".
- **Transition:** "Running on the phone means the model has to get there. Where does it come from?"
- **Likely question:** "Is 1.9 ms on a real phone?" → "No, that's the laptop CPU (`benchmarks/results.md` D2). A mid-range phone will be slower, but still milliseconds, not seconds. Phone numbers are on our limitations slide."

## Act 2: Where the model comes from (ML service) · Paul · 3:45

### 4. Data → model · 1:45
- **Open with:** "2,152 potato leaf photos, and only 152 of them healthy."
- **Key points:**
  - The dataset is imbalanced: 6.6× fewer healthy leaves.
  - MobileNetV2 with a frozen base trains in about 40 s.
  - **95.8%** accuracy, macro F1 **0.945** on 216 test images.
- **Show:** the confusion matrix diagonal.
- **Transition:** "That's a PyTorch model. Our app is Dart."
- **Go deeper:** [MobileNetV2 paper](https://arxiv.org/abs/1801.04381) (why it is small enough for phones).

### 5. One model, two runtimes · 2:00
- **Open with:** "One model, exported twice: PyTorch for the server, LiteRT for the phone."
- **Key points:**
  - The `.tflite` file is 9.0 MB and matches PyTorch to 8e-7.
  - The `.json` beside it is **the contract**: labels, threshold and input shape. Nothing about the model is hardcoded in Dart.
- **Show:** the JSON snippet, then the Model screen.
- **Handover:** "That's how the model is made. Titus will show how the Flutter app runs it."
- **Go deeper:**
  - [LiteRT: convert PyTorch models](https://ai.google.dev/edge/litert/models/convert_pytorch)
  - [LiteRT overview](https://ai.google.dev/edge/litert)

## Act 3a: On-device AI in Flutter · Titus · 10:15

### 6. The app at a glance · 1:00
- **Open with:** "Four tabs' worth of app, and none of it needs the internet."
- **Show:** Scan → Result → History → Settings.
- **Transition:** "How is it built so the model can be swapped and tested?"

### 7. Clean layers in Flutter · 2:00
- **Open with:** "`flutter_litert` is an implementation detail. The app depends on a `Classifier` port."
- **Key points:**
  - Domain is pure Dart, and use cases return `Result`.
  - Infrastructure holds LiteRT, Hive and Dio; mocks stand in today.
  - `providers.dart` is the only place where things are wired together.
  - An architecture test fails the build if a layer imports the wrong thing.
- **Show:** the arrows, then the snippet.
- **Likely question:** "Why not call the interpreter from the widget?" → "Then you can't test the UI without a model, or swap the model's runtime."
- **Go deeper:**
  - [Flutter app architecture guide](https://docs.flutter.dev/app-architecture)
  - [Riverpod](https://riverpod.dev)
  - [`flutter_litert` on pub.dev](https://pub.dev/packages/flutter_litert)

### 8. Capture → analyze · 1:30
- **Open with:** "Pick a photo; inference runs off the UI thread."
- **Key points:**
  - The result is **saved before it's shown**.
  - The scan line is held at least 600 ms. Users don't trust an instant answer they can't see happen.
- **Show:** the three steps left to right.
- **Transition:** "Here's the bug that cost us the most time."

### 9. The silent bug · 2:30 ★ (the moment to slow down)
- **Open with:** "Same model, same photos. One line of preprocessing wrong, and **no error**."
- **Key points:**
  - Forget ÷255: **9.3%**, with 210 of 216 leaves called "healthy".
  - Red and blue swapped: 55.6%.
  - The fix is a golden test comparing the Dart tensor with Python's (max diff ≤ 1e-4).
- **Show:** pause on 9.3%. Ask the room: "Who would have caught this in code review?"
- **Transition:** "Even with correct preprocessing, the model will sometimes be unsure."
- **Go deeper:** [On-device image classification in Flutter (DEV Community, 2026)](https://dev.to/techwithsam/on-device-ai-in-flutter-2026-tensorflow-lite-tutorial-image-classifier-app-4o53), which walks through the full preprocessing pipeline.

### 10. Show the answer honestly · 1:15
- **Open with:** "A percentage alone isn't an answer."
- **Key points:**
  - The confidence bar has a threshold tick, with the top 3 underneath.
  - It shows on-device latency and the model version.
  - Status is always icon + label + colour, never colour alone.
- **Show:** the threshold tick on the late-blight screen.
- **Go deeper:** [Flutter accessibility](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility)

### 11. Don't guess: abstain · 2:00
- **Open with:** "The most useful thing the model can say is 'I'm not sure'."
- **Key points:**
  - With a 0.50 threshold, it answers 96.3% of photos and is right 97.1% of the time when it answers.
  - Below the threshold, it says "Not sure, retake" and shows its best guess.
- **Show:** left vs right phone.
- **Transition:** "A diagnosis has to survive the network. That's the offline-first part."

## Act 3b: Offline-first Flutter · Titus · 6:00

### 12. Offline is the default · 1:30
- **Open with:** "Offline isn't an error state in this app. It's the normal state."
- **Key points:**
  - Scanning is never disabled.
  - "Online" means `GET /ready` answered within 2 s. `connectivity_plus` only tells you there's a network, not that the server is reachable.
- **Show:** the offline banner, then the advice-offline screen.
- **Go deeper:**
  - [Flutter offline-first design pattern](https://docs.flutter.dev/app-architecture/design-patterns/offline-first)
  - [`connectivity_plus`](https://pub.dev/packages/connectivity_plus) (read its note on what it can't detect)

### 13. Write first, sync later · 2:00
- **Open with:** "Every result is written to the phone first. Sync is a background detail."
- **Key points:**
  - The outbox lives in Hive, and the UUIDs are made on the phone.
  - Re-sending a batch returns `duplicate`, never a second row. The Go test sends 100 diagnoses, then the same 100 again: 100 created, then 100 duplicate.
  - Rejected items say why.
- **Show:** Pending → Syncing → Rejected.
- **Likely question:** "Why not Firebase or PowerSync?" → "They work too. We wanted the sync contract to be visible and testable against our own Go API."
- **Go deeper:**
  - [Create offline-first apps (Android Developers, YouTube)](https://www.youtube.com/watch?v=jaZ2gLMGUsM)
  - [How to make an offline-first app in Flutter (Arthur Giani, YouTube)](https://www.youtube.com/watch?v=lixgKQeLg_U)
  - [Designing robust APIs with idempotency (Stripe)](https://stripe.com/blog/idempotency)
  - [Hive CE](https://pub.dev/packages/hive_ce)

### 14. Design system → code · 1:15
- **Open with:** "We designed in Google Stitch, but we didn't copy it blindly."
- **Key points:**
  - DESIGN.md became the theme tokens, and a drift test fails if they diverge.
  - There are 19 shared widgets.
  - Stitch's mistakes were fixed, not copied.
- **Go deeper:** [Google Stitch](https://stitch.withgoogle.com)

### 15. Testing the UI · 1:15
- **Open with:** "91 tests, and a golden image for every screen state in light and dark."
- **Key points:** accessibility checks found 4 real bugs:
  - text contrast of 4.18:1
  - a crash under reduce motion
  - a 40 dp tap target
  - an unlabelled switch
- **Go deeper:**
  - [`matchesGoldenFile`](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html)
  - [WCAG contrast minimum](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)

## Act 4: Coming back online · Titus (Go, 16–18) · Paul (RAG, 19–20) · 6:00

### 16. One door: go-backend · 1:30
- **Open with:** "When the network comes back, the app talks to exactly one service."
- **Key points:**
  - Go owns sync, history and model releases, and proxies predictions and advice.
  - The app never calls the Python services directly.
- **Show:** the Diagnostics screen (service health), then the diagram.

### 17. Safe model updates · 1:30
- **Open with:** "Shipping a new model is a download. Downloads fail."
- **Key points:**
  - ETag/304 keeps checks cheap.
  - Range requests let a download resume.
  - The sha256 is checked **before** switching, and the previous model is kept.
- **Show:** "Bad file refused".
- **Go deeper:** [Android 16 KB page sizes](https://developer.android.com/guide/practices/page-sizes) (why native ML libraries need checking).

### 18. Second opinion · 1:00
- **Open with:** "The server model is optional, and only on request."
- **Key points:**
  - The phone says 76.5%; the server says 81.2%. Say "mock values today".
  - The photo leaves the phone only when the user taps.

### 19. "What do I do about this?" · 1:30 · Paul
- **Handover (Titus, end of 18):** "The app can diagnose. Paul will show how it explains what to do."
- **Open with:** "A diagnosis without advice is half an answer."
- **Key points:**
  - The RAG service retrieves from curated notes and answers with a local LLM, citing `[n]` sources.
  - Faithfulness went from **0.51 → 0.88** after two fixes:
    - removed the "padding" rule from the prompt
    - rewrote the notes so each "Cause" sentence stands on its own
  - A warm answer takes about 3.5 s, so advice is an add-on and never blocks.
- **Likely question:** "Why a local LLM?" → "There's no per-call cost and the data stays private, and on a laptop it runs on Ollama."
- **Go deeper:**
  - [What is RAG? (IBM Technology, YouTube)](https://www.youtube.com/watch?v=T-D1OfcDW1M)
  - [Original RAG paper](https://arxiv.org/abs/2005.11401)
  - [Ragas docs](https://docs.ragas.io)
  - [Ollama](https://ollama.com)

### 20. Same knowledge, offline · 0:30
- **Open with:** "And the same notes are bundled in the app, so the library works in airplane mode."
- **Transition:** "Enough slides. Let's show it."

## Act 5: Demo and honesty · both · 5:00

### 21. Live demo · 3:00
See the [demo runbook](#demo-runbook) below. Titus drives the phone and Paul narrates. **Use path A unless F2 is done.**

### 22. Limitations, honestly · 1:30
- **Open with (Paul):** "95.8% is on lab photos. Here's the number that matters."
- **Key points:**
  - **54.8%** on 221 field photos (PlantDoc).
  - The model knows "diseased": only 0.9% of diseased leaves were called healthy. But it confuses the two blights, and the threshold doesn't catch it: it still answers 86% of field photos, at 55%.
  - Next: field data collected with consent, calibration, and phone benchmarks.
- **Go deeper:** [PlantDoc paper](https://arxiv.org/abs/1911.10317) (why field photos are harder).

### 23. Five takeaways · 0:30
Paul reads takeaways 1–3 and Titus reads 4–5, one line each, then stops.

### 24. Any questions? · 5:00 (Q&A)
Use the [Q&A bank](#qa-bank). Backup slide 25 ("What is real today") is after this one.

---

## Demo runbook

**Roles:** Titus drives the emulators and terminal; Paul narrates and watches the clock. **Slot: 3:00.**

### How the demo app behaves (mock build, checked in the code)
| Thing | Behaviour | Where |
|---|---|---|
| Online / offline | Fixed per run by `--dart-define=SCENARIO`; **airplane mode changes nothing** | `MockBackendStatusSource` |
| Diagnosis | Result picked by the **sample photo**: late blight, early blight, healthy; the blurry sample → "Not sure". Takes 0.9 s + the ≥ 600 ms scan hold | `MockClassifier`, `DiagnosisMockData.forPhoto` |
| New diagnosis | Saved as **Pending** | `DiagnoseLeaf` |
| Sync | History → **Sync now** (refresh icon): Pending → Syncing → Synced in 1.5 s; offline → error | `MockSyncService` |
| Advice | Cited answer after 3 s; offline → "Advice needs internet"; `adviceDown` → "unavailable" | mock advice adapter |
| Reset | Data is in memory: **hot restart (`R`) restores the seed data** | `MockDiagnosisRepository` |

So never say "result in milliseconds" during the mock demo: say "about a second, and none of it touched the network".

### The day before
- [ ] Create two phone emulators side by side: **`Medium_Phone` = OFFLINE**, **`Pixel_10_Pro_XL` = ONLINE** (both exist on this Mac).
- [ ] Full rehearsal twice with a timer, including one with a deliberate failure (kill Docker) to practise the fallback.
- [ ] Record the **backup video** of the full 3-minute path: macOS **Cmd + Shift + 5** → record selected portion (both emulators + terminal). Save to the desktop **and** a USB stick.
- [ ] Ollama model present: `ollama list` shows `llama3.1:8b` (pulling it on venue Wi-Fi is not an option: ~4.9 GB).
- [ ] Laptop: notifications off (Focus mode), battery at 100%, charger packed, display scaling so the emulators are readable from the back row.

### 60 minutes before
```bash
ollama serve &                                   # if not already running
cd ai-crop-disease-platform && docker compose up -d --build --wait
curl -s localhost:8080/ready && curl -s localhost:8001/ready   # go-backend, rag-service
curl -s -X POST localhost:8080/api/v1/advice -H 'X-API-Key: dev-key' \
  -H 'Content-Type: application/json' \
  -d '{"question":"What should I do today?","class_name":"Potato___Late_blight"}' | jq .answer   # warms Ollama

flutter emulators --launch Medium_Phone
flutter emulators --launch Pixel_10_Pro_XL
cd mobile-app
flutter run -d <Medium_Phone id>  --dart-define=SCENARIO=offline   # terminal tab 1
flutter run -d <Pixel id>         --dart-define=SCENARIO=online    # terminal tab 2
```
(`flutter devices` shows the ids, e.g. `emulator-5554`, `emulator-5556`.)

### 5 minutes before
- [ ] Both apps on the **Scan** tab; press `R` in both terminals for fresh seed data.
- [ ] Terminal tab 3 open with the `curl … /advice` command typed, **not run**, font ≥ 24 pt, `clear`ed.
- [ ] Backup video open and paused on frame 1.
- [ ] Re-run the warm-up `curl` (Ollama unloads idle models after a few minutes).

### Script (3:00)
| Time | Titus does | Paul says |
|---|---|---|
| 0:00 | Points at the OFFLINE emulator's banner | "This phone has no connection. Watch what still works." |
| 0:15 | Scan a leaf → Take photo → late-blight sample | "Everything you're about to see runs on the phone." |
| 0:30 | Result appears; point at confidence + "On-device" line | "Late blight, 76.5%, above the threshold. Saved before it was shown." |
| 0:50 | History tab → point at **Pending** | "It's in the outbox, waiting for a connection." |
| 1:00 | Scan again with the **blurry** sample → "Not sure" | "And when the photo is bad, it says so instead of guessing." |
| 1:20 | Switch to the ONLINE emulator → History → **Sync now** | "Now the same app with a connection: Pending… Syncing… Synced." |
| 1:40 | Open a late-blight result → **Get advice** → "What should I do today?" | "Advice needs the server, so it only appears when online. Note the numbered sources." |
| 2:10 | Switch to terminal tab 3, run the `curl` | "In the app that call is mocked today. This is the real go-backend → rag-service call it switches to." |
| 2:40 | Point at `[1]` and the `sources` in the JSON | "Same citations, from the real local model." |
| 2:50 | Back to slides | "That's offline-first: the network is an upgrade, not a requirement." |

### Failure handling (decide in ≤ 10 seconds)
| Symptom | Do this |
|---|---|
| Emulator frozen or app crashed | Use the other emulator for the rest; if both, play the backup video from the matching timestamp |
| Result doesn't appear within 5 s | Hot restart (`R`) once; if it fails again → video |
| `curl` hangs (> 10 s) | Ctrl-C: "Cold model; this is exactly why advice never blocks the diagnosis." Show slide 19 instead |
| `curl` returns an error JSON | Read the `error` field out loud: "graceful failure, same shape as every service" and move on |
| Docker not running at all | Skip the terminal step; the app part needs no backend |
| Laptop / projector dies | Paul continues from the PDF on the USB stick; describe the demo with slides 12–13 |
| Running late | Cut the blurry-photo step and the terminal step (saves ≈1 min) |

### After the demo
- Leave both emulators running for Q&A ("can you show the model screen?" → Settings → Diagnosis model).
- Don't run `docker compose down` until the session ends.

### Path B: after F1/F2 land (real inference and sync)
Use only if real `LiteRtClassifier`, Hive storage and HTTP sync are merged **and** rehearsed on the demo device:
1. One real phone mirrored (install `scrcpy`, `brew install scrcpy`) or one emulator.
2. Airplane mode on → scan → result (real on-device ms) → History "Pending".
3. Airplane mode off → wait for `/ready` → "Synced" (check the row exists: `curl -H 'X-API-Key: dev-key' localhost:8080/api/v1/devices/<device_id>/diagnoses`).
4. Get advice (real call). Same fallbacks as above; re-record the backup video for this path.

## Handling the room

- **"I don't know":** "Good question. We haven't measured that. Find us after, or open an issue on the repo." Never guess a number.
- **Long or niche question:** answer in one sentence, then "happy to go deeper after the talk". Protect the Q&A time for others.
- **Hostile or "this is useless":** agree with the fact, then bridge to the evidence. Example: "Yes, 54.8% isn't good enough to ship. That's why we show it, and why the model abstains."
- **A pitch disguised as a question:** "Thanks, let's talk after." Move on.
- **Speakers disagree on stage:** the owner of the topic answers (Paul: model, ML service, RAG; Titus: Flutter app, offline sync, Go); the other adds at most one line.
- **Someone asks about something on a slide we skipped:** "It's in the deck on the repo; short version: …"

## Timing and technical contingency

| Situation | Do this |
|---|---|
| Running late (>2 min behind at slide 11) | Skip 14, 18 and 20 (≈2:45 saved); shorten 15 to one sentence |
| Running early | Expand 9 (ask the room) and 22 (field-error examples) |
| 5 minutes left in the talk | The off-stage speaker raises a hand; jump to 22 |
| A question during the talk | Park it: "great, let's take it at the end" |
| HDMI/adapter fails | Bring USB-C→HDMI and USB-C→VGA adapters; keep a **PDF** of the deck on a USB stick |
| Fonts missing on the venue laptop | Present from the PDF (fonts embedded) |
| No venue Wi-Fi | Fine: the backend runs locally in Docker, and demo path A needs no internet |
| One speaker unavailable | The other presents everything: these notes are complete for both |

## Q&A bank

Who answers: **P** = Paul (model, ML service, RAG), **T** = Titus (Flutter app, offline sync, Go). Every answer is either backed by a repo file or says "not measured".

### ML and on-device
| Question | Short answer | Who · evidence |
|---|---|---|
| How accurate is it in a real field? | 54.8% on 221 PlantDoc photos. It's good at "diseased vs healthy" (0.9% of diseased leaves called healthy) but weak at telling the two blights apart. | P · `field_eval.json` |
| Isn't 54.8% useless? | For blight-vs-blight, yes, today. That's why we show it and why the next step is field data, not a bigger model. | P · `field_eval.json` |
| Why is lab accuracy so high? | PlantVillage has near-duplicate photos of the same leaf, so test scores are optimistic. | P · `ml-training/README.md` |
| Did you handle the class imbalance? | A weighted sampler in training and a stratified split, so healthy appears in every split. | P · `ml-training/src/crop_ml/data.py` |
| Is the model quantized? | No, it's float32 (9.0 MB). Int8 or float16 quantization is the obvious next step for size and speed; we haven't measured its accuracy cost yet. | P · `python-ml-service/scripts/export_tflite.py` |
| GPU / NNAPI delegate? | CPU today. Delegates are a config change in the LiteRT adapter; not benchmarked. | T |
| What about low-end phones and battery? | Not measured yet. Inference is one call per photo, not a video stream, so the battery cost should be small, but we won't claim a number. | P |
| What if I photograph my face, or a maize leaf? | It's a 3-class potato model, so it will still pick one of the three classes. The threshold catches some of these as "Not sure", not all. Out-of-distribution detection is future work. | P |
| Is the confidence calibrated? | Not yet. The threshold is 0.50 from the validation set; calibration is on the next-steps list. | P · `eval_summary.json` |
| Why not ML Kit or Gemini Nano? | We needed our own classifier with a known preprocessing contract. LiteRT runs any `.tflite`. Gemini Nano is generative and only available on some devices. | P |
| Why MobileNetV2 and not a newer model? | Small, fast, well understood on mobile, and trains in seconds with a frozen base. Good enough to tell the on-device story. | P |
| How do you keep Dart preprocessing equal to Python? | A golden test: the Dart tensor vs a Python fixture, max diff ≤ 1e-4. | T · AGENTS.md |

### Flutter
| Question | Short answer | Who · evidence |
|---|---|---|
| Is the app real or mocked? | The UI is real; storage, sync and inference are mock adapters behind real ports until F1/F2. | P/T · `lib/app/di/mock_overrides.dart` |
| Why Riverpod and not Bloc? | Dependency injection and state in one package, easy overrides in tests, no code generation. Bloc would work too. | T · `docs/PROGRESS.md` decision log |
| Isolate or `compute`? | Preprocessing runs in a background isolate via `compute`, and one interpreter is reused per active model. Whether inference itself needs a long-lived isolate gets measured in F1. | T · ARCHITECTURE.md, AGENTS.md |
| Don't golden tests break across machines? | They can (fonts, rendering). We bundle Inter, load real fonts in `flutter_test_config.dart`, and generate goldens on one OS. | T |
| Web or desktop? | Not a target. Android first; iOS must build. | T · README |
| How much does the model add to the app size? | About 9 MB for the model, plus the LiteRT native libraries (not measured yet). | T |
| Camera support? | The design has camera and gallery; the UI phase uses sample photos. `image_picker` comes in F1. | T · ROADMAP |
| Accessibility? | WCAG contrast, 48 dp targets, labels and reduce-motion checks run in widget tests; they found 4 real bugs. | T · `docs/UI_TASKS.md` |

### Offline-first and sync
| Question | Short answer | Who · evidence |
|---|---|---|
| What about conflicts? | Diagnoses are append-only facts with phone-made UUIDs, so there's nothing to merge: the same ID is a duplicate, a new ID is a new row. | T · go-backend sync tests |
| A batch half fails? | Each item gets its own result (`created` / `duplicate` / `invalid`), so a retry only matters for the failed ones and can't double-insert. | T · go-backend README |
| The phone's clock is wrong? | The server refuses times more than 24 h in the future (small skew is accepted so no data is lost), and the app explains why (that's the "rejected" screen). | T · `go-backend/internal/domain/diagnosis/diagnosis.go` |
| Doesn't the outbox grow forever? | Synced items leave the outbox; history stays local. Size limits are a later concern for one farmer's photos. | T |
| Two phones, one farmer? | History is per device today. Account sync is out of scope. | T |
| Why not Firebase, PowerSync or Drift? | They're fine choices. We wanted the sync contract visible and testable against our own API. | T |
| How do you know you're "online"? | `GET /ready` answered within 2 s. `connectivity_plus` alone says there's a network, not that the server is reachable. | T |

### Backend and RAG
| Question | Short answer | Who · evidence |
|---|---|---|
| Does the LLM hallucinate? | It answers only from retrieved notes with `[n]` citations; faithfulness is 0.88 on our eval. It's 5 questions with an 8B judge, so directional, not proof. | P · PRESENTATION_PLAN |
| What if I ask something unrelated? | Off-topic questions are refused before any LLM call ("How do I fix my car engine?" → refused). | P · `rag-service/README.md` |
| Prompt injection? | The notes are curated by us, not user-supplied, so injection through retrieval is limited; user questions are still untrusted input. Not formally tested. | P |
| Cost and latency at scale? | A local model via Ollama: no per-call fee, ≈3.5 s warm. Scaling means a GPU server; we haven't load-tested. | P · `benchmarks/results.md` D4 |
| How is the API secured? | An `X-API-Key` per request plus a separate admin key; HTTPS in release builds. Per-user auth is future work. | T · go-backend README |
| Why Go? | One small, typed gateway the app talks to; the Python services stay internal. | T |

### Product and ethics
| Question | Short answer | Who · evidence |
|---|---|---|
| Who is responsible if the advice is wrong? | The app says it's guidance from extension notes, not professional advice, and cites the source. It's a learning project, not a certified tool. | T |
| Farmers without smartphones? | Out of scope; this would reach extension officers first. | P |
| Swahili? | Planned: strings are in one place per feature, ready for l10n; Swahili is listed as later work. | T · ROADMAP |
| Where does training data come from? Consent? | Public datasets (PlantVillage, PlantDoc). Field photos will only be collected with consent. | P · ROADMAP |
| Why only potato? | One crop, done honestly, beats ten done badly. The pipeline is crop-agnostic. | P |
| Will you open-source it? | Not public yet; find us after the talk. | P |
| Can I use this for my farm today? | Not yet: field accuracy isn't good enough. Treat it as a reference architecture. | P |

## Resources

Checked 2026-11-03: every link returned a page, and the YouTube titles and channels were confirmed through YouTube's oEmbed service.

**On-device ML / LiteRT**
- [LiteRT overview (Google AI Edge)](https://ai.google.dev/edge/litert)
- [Convert PyTorch models to LiteRT](https://ai.google.dev/edge/litert/models/convert_pytorch)
- [`flutter_litert` on pub.dev](https://pub.dev/packages/flutter_litert)
- [Deploy Android on-device AI with ML Kit GenAI and LiteRT-LM (Android Developers, YouTube)](https://www.youtube.com/watch?v=Z7zx_sTbFPI)
- [TLMs: Tiny LLMs and Agents on Edge Devices with LiteRT-LM, Cormac Brick, Google (AI Engineer, YouTube)](https://www.youtube.com/watch?v=BKWpYIWvAo4)
- [On-Device AI in Flutter 2026: TensorFlow Lite tutorial (DEV Community)](https://dev.to/techwithsam/on-device-ai-in-flutter-2026-tensorflow-lite-tutorial-image-classifier-app-4o53)
- [Android 16 KB page sizes](https://developer.android.com/guide/practices/page-sizes)

**Offline-first and sync**
- [Flutter offline-first design pattern](https://docs.flutter.dev/app-architecture/design-patterns/offline-first)
- [Create offline-first apps (Android Developers, YouTube)](https://www.youtube.com/watch?v=jaZ2gLMGUsM)
- [How to make an offline-first app in Flutter, Arthur Giani (Fluttering, YouTube)](https://www.youtube.com/watch?v=lixgKQeLg_U)
- [Designing robust and predictable APIs with idempotency (Stripe)](https://stripe.com/blog/idempotency)
- [Hive CE](https://pub.dev/packages/hive_ce) · [`connectivity_plus`](https://pub.dev/packages/connectivity_plus)

**Architecture**
- [Flutter app architecture guide](https://docs.flutter.dev/app-architecture)
- [Riverpod](https://riverpod.dev)

**RAG and evaluation**
- [What is Retrieval-Augmented Generation (RAG)? (IBM Technology, YouTube)](https://www.youtube.com/watch?v=T-D1OfcDW1M)
- [RAG paper, Lewis et al. 2020](https://arxiv.org/abs/2005.11401)
- [Ragas docs](https://docs.ragas.io) · [Ollama](https://ollama.com)

**Datasets and models**
- [MobileNetV2 paper](https://arxiv.org/abs/1801.04381)
- [PlantVillage paper](https://arxiv.org/abs/1511.08060)
- [PlantDoc paper](https://arxiv.org/abs/1911.10317)

**UI quality**
- [Flutter accessibility](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility)
- [`matchesGoldenFile`](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html)
- [WCAG 2.2 contrast minimum](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)
- [Google Stitch](https://stitch.withgoogle.com)

**Session page:** [FlutterconKE: Beyond the API Call](https://fluttercondev.ke/sessions/beyond-the-api-call-on-device-ai-in-flutter-with-litert-and-offline-first-architecture)

