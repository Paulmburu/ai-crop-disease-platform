# Speaker guide: "Beyond the API Call"

How to present each of the 32 slides in [`presentation/LeafCheck_FlutterconKE.pptx`](presentation/LeafCheck_FlutterconKE.pptx)
(30 in the talk, plus 2 backup slides), with links you can share with the audience. Outline and sources for every number:
[`PRESENTATION_SLIDES.md`](PRESENTATION_SLIDES.md). Plain-language background: [`HOW_IT_WORKS.md`](HOW_IT_WORKS.md).

## How to use this guide

- **Session:** FlutterconKE, **Fri 6 Nov, 14:20** (per the organisers' feedback sheet), 40 min.
- **Speakers:**
  - **Paul:** ML service and RAG. Slides 1–9, 25–29 and 32, plus narrating the demo.
  - **Titus:** the Flutter app and the Go service. Slides 10–24, plus driving the demo.
  - **Shared:** slides 30, 31, 33 and 34.
- **Time:** 40 min = **35 min talk + 5 min Q&A**; the times below add up to 35:00.
- **Two handovers:**
  - **Slide 9 → 10.** Paul says: *"That's how the model is made and shipped. Titus will show how the Flutter app runs it."*
  - **Slide 24 → 25.** Titus says: *"The app can diagnose. Paul will show how it explains what to do."*
- **Skip if late:** slides 18, 23, 24 and 29, plus the map on 27 (≈3:00 saved).
- **Rules:**
  - One idea per slide.
  - Never read the slide out loud; the slide shows the number, you say why it matters.
  - Point at the screenshot or diagram every time you name something on it.
- **Numbers:** say "modelled" for network times. The phone screenshots come from the design build, so some numbers on them differ from the live run; the slide text gives the real ones.
- **"Go deeper"** links are for the audience. Share them after the talk (e.g. in the event chat); the deck has no links.
- **Feedback QR** (events.droidcon.co.ke/f/bzvavqjc) is on slides 1 and 34. Mention it at the start and at Q&A.

## What is built (say it if anyone asks "is it real?")

Everything you see runs end to end, checked on an Android emulator on 2026-11-04: on-device LiteRT diagnosis,
local storage, automatic sync to go-backend, second opinion, cited advice from the local LLM, and model updates.

| Built | Next |
|---|---|
| On-device LiteRT (`flutter_litert`), 11 ms p50 on the emulator | Python-vs-Dart preprocessing parity test |
| Hive outbox, sync, second opinion, advice, model updates | Resumable model downloads |
| 97 tests, goldens light + dark | Access key in secure storage; real-phone benchmarks |

Sources for slide numbers: `benchmarks/results.md`, `ml-training/outputs/eval_summary.json`, `field_eval.json`,
`mismatch.json`, and the live emulator run (87.8%, 67.2%, 84.3%, 11 ms).

---

## Act 1: Why on-device · Paul · 3:45

### 1. Beyond the API Call · 0:45
- **Open with:** "Most AI features in mobile apps are an HTTP call. Today we'll show what happens when you take the API call away."
- **Key points:**
  - Introduce both speakers in one line each.
  - The app is LeafCheck: it diagnoses potato leaves with no internet.
  - Point at the QR: "Rate the session any time."
- **Transition:** "Let's start where the app is used: in the field."

### 2. A leaf and no signal · 0:45
- **Open with:** "In cool, wet weather, late blight can destroy a potato field within days."
- **Key points:**
  - Late blight caused the Irish potato famine.
  - The person who needs the answer is standing in the field, where the signal is weakest.
- **Show:** the photo; let it sit for a second.
- **Transition:** "So what does an API call actually cost out there?"
- **Go deeper:** [PlantVillage paper (Hughes & Salathé)](https://arxiv.org/abs/1511.08060), the open dataset behind most leaf-disease models.

### 3. The cost of the API call · 1:15
- **Open with:** "Same 3 MB photo. Same model. Two places to run it."
- **Key points:**
  - On the device: **1.9 ms** on a laptop CPU, **11 ms** on an Android emulator.
  - Through a backend: about 1.3 s on Wi-Fi, 34 s on 3G, 4 min on 2G.
  - Say clearly that the network times are **modelled**, not measured on a phone.
- **Show:** go left to right; stop on "4 min".
- **Likely question:** "Real phone speed?" → "Not measured yet; the emulator gives 11 ms. A mid-range phone will be slower, but still milliseconds, not seconds."
- **Transition:** "Before the details, here's the whole system on one slide."

### 4. The system in one picture · 1:00
- **Open with:** "Three places: the laptop teaches, the phone diagnoses, the backend helps when it can."
- **Key points:**
  - Laptop, once: ml-training is the school; python-ml-service is the translator that makes the model phone-sized.
  - Phone, every scan: the app is the pocket doctor. It diagnoses and saves with no internet.
  - Backend, only when online: go-backend is the front desk. Behind it, the ML service (second opinion), the librarian (rag-service), the writer (Ollama) and Postgres.
- **Say:** "The phone is the doctor; the internet is only for extras."
- **Transition:** "Let's start at the school."

## Act 2: Where the model comes from (ML service) · Paul · 5:15

### 5. Flashcards → model · 1:15
- **Open with:** "2,152 potato leaf photos, and only 152 of them healthy."
- **Key points:**
  - The dataset is imbalanced: 6.6× fewer healthy leaves.
  - **95.8%** accuracy, macro F1 **0.945** on 216 test photos the model never saw.
- **Show:** the confusion matrix diagonal.
- **Transition:** "Why can a small model learn this in 40 seconds?"

### 6. MobileNetV2: it already knows how to see · 1:30
- **Open with:** "We didn't teach a model to see. We taught a model that already sees, three new words."
- **Key points:**
  - MobileNetV2 is a small image model built for phones: about 3.4 million parameters.
  - Its feature layers already learned edges, spots and textures from ImageNet. We **froze** them.
  - We trained only the last layer, for 3 classes. That's transfer learning, and it takes about 40 s.
  - The code: freeze `features`, replace `classifier[1]` with a 3-output layer.
- **Show:** the diagram left to right, then the two `requires_grad` / `Linear` lines.
- **Go deeper:** [MobileNetV2 paper](https://arxiv.org/abs/1801.04381).

### 7. One model, two runtimes · 0:45
- **Open with:** "One model, exported twice: PyTorch for the server, LiteRT for the phone."
- **Key points:**
  - The export is two lines: `litert_torch.convert`, then `export`.
  - We verify it: the LiteRT output matches PyTorch to 8e-7.
  - It ships with a label card (`.json`): labels, threshold and input shape.
- **Show:** the snippet, then the Model screen.
- **Go deeper:**
  - [LiteRT: convert PyTorch models](https://ai.google.dev/edge/litert/models/convert_pytorch)
  - [LiteRT overview](https://ai.google.dev/edge/litert)

### 8. Make the phone's job easy · 0:45
- **Open with:** "Before converting, we made the phone's job as small as possible."
- **Key points:**
  - We wrap the model so three things happen **inside** it: pixel order, normalisation, softmax.
  - So the phone only resizes, crops and **divides by 255**. Fewer steps, fewer ways to get it wrong.
  - Point at the 4-line `forward`: that's the whole wrapper.
- **Transition:** "Now the model exists as a phone file. How does it reach a phone?"

### 9. How a model reaches the phone · 1:00
- **Open with:** "The model learns in school, the laptop, never on the job, the phone."
- **Key points:**
  - Path A: copy it into the app at build time. That's how v1 ships.
  - Path B: go-backend publishes v2; the app's "Check for updates" downloads it, checks the sha256 fingerprint, switches, and keeps v1 as a backup.
  - Never: the phone learning from scans, or sync uploading photos.
- **Handover:** "That's how the model is made and shipped. Titus will show how the Flutter app runs it."

## Act 3a: On-device AI in Flutter · Titus · 10:00

### 10. The app at a glance · 0:45
- **Open with:** "Four tabs' worth of app, and none of it needs the internet."
- **Show:** Scan → Result → History → Settings.
- **Transition:** "How is it built so the model can be swapped and tested?"

### 11. Clean layers in Flutter · 1:00
- **Open with:** "`flutter_litert` is an implementation detail. The app depends on a `Classifier` port."
- **Key points:**
  - Domain is pure Dart, and use cases return `Result`.
  - Infrastructure holds LiteRT, Hive and Dio; mocks plug into the same ports for tests and design states.
  - `providers.dart` is the only place where things are wired together.
  - An architecture test fails the build if a layer imports the wrong thing.
- **Likely question:** "Why not call the interpreter from the widget?" → "Then you can't test the UI without a model, or swap the runtime."
- **Go deeper:**
  - [Flutter app architecture guide](https://docs.flutter.dev/app-architecture)
  - [Riverpod](https://riverpod.dev)

### 12. Loading the model with flutter_litert · 1:15
- **Open with:** "Loading the model is ten lines."
- **Key points:**
  - `Interpreter.fromBuffer` with the active model's bytes: the bundled v1, or a downloaded update.
  - One interpreter, reused; it reloads only when the model's sha256 changes.
  - The app reads the label card: labels, threshold and shape are never hardcoded.
- **Go deeper:** [`flutter_litert` on pub.dev](https://pub.dev/packages/flutter_litert)

### 13. Photo → tensor → scores · 1:30
- **Open with:** "Here's what happens between the photo and the answer."
- **Key points:**
  - Resize the short side to 256, crop the centre 224 × 224, scale RGB to 0–1: a `[1,224,224,3]` tensor.
  - `compute()` keeps the preprocessing off the UI thread.
  - `interpreter.run(input, out)` fills three scores that add up to 100%.
  - 11 ms on the emulator, 1.9 ms on a laptop CPU.
- **Transition:** "Get one of those steps wrong, and here's what happens."

### 14. Capture → analyze · 0:45
- **Open with:** "Camera, gallery, or a sample photo; then the scan."
- **Key points:**
  - The result is **saved before it's shown**.
  - The scan line is held at least 600 ms. Users don't trust an instant answer they can't see happen.

### 15. The silent bug · 1:45 ★ (the moment to slow down)
- **Open with:** "Same model, same photos. One line of preprocessing wrong, and **no error**."
- **Key points:**
  - Forget ÷255: **9.3%**, with 210 of 216 leaves called "healthy".
  - Red and blue swapped: 55.6%.
  - The guard: compare the Dart tensor with Python's for the same photo.
- **Show:** pause on 9.3%. Ask the room: "Who would have caught this in code review?"
- **Go deeper:** [On-device image classification in Flutter (DEV Community, 2026)](https://dev.to/techwithsam/on-device-ai-in-flutter-2026-tensorflow-lite-tutorial-image-classifier-app-4o53)

### 16. Show the answer honestly · 0:45
- **Open with:** "A percentage alone isn't an answer."
- **Key points:**
  - The confidence bar has a threshold tick, with the top 3 underneath.
  - Status is always icon + label + colour, never colour alone.
- **Go deeper:** [Flutter accessibility](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility)

### 17. Don't guess: abstain · 1:30
- **Open with:** "The most useful thing the model can say is 'I'm not sure'."
- **Key points:**
  - One rule: the top score ≥ 50% shows a diagnosis; below it, "Not sure, retake".
  - Real results: late blight 87.8%, early blight 67.2%; a blurry photo gives 38.9%, so "Not sure".
  - It answers 96.3% of test photos and is right 97.1% of the time when it does.
  - The server applies the same rule (the Python line), so phone and server never disagree on what "sure" means.
- **Show:** the bars crossing the 50% line.

### 18. What each result means · 0:45 (skip if late)
- **Open with:** "What should a farmer do with each answer?"
- **Key points:** read one row: "Not sure: retake, one leaf, daylight, fill the frame."
- **Transition:** "A diagnosis has to survive the network. That's the offline-first part."

## Act 3b: Offline-first Flutter · Titus · 3:15

### 19. Offline is the default · 1:00
- **Open with:** "Offline isn't an error state in this app. It's the normal state."
- **Key points:**
  - Scanning is never disabled.
  - "Online" means `GET /ready` answered within 2 s. Wi-Fi alone doesn't mean the server is reachable.
  - The real story: the app said "offline" on a phone with working Wi-Fi, because it was looking for 10.0.2.2, the emulator-only address.
- **Go deeper:**
  - [Flutter offline-first design pattern](https://docs.flutter.dev/app-architecture/design-patterns/offline-first)
  - [`connectivity_plus`](https://pub.dev/packages/connectivity_plus) (read its note on what it can't detect)

### 20. Write first, sync later · 1:45
- **Open with:** "Every result is written to the phone first. Sync is a background detail."
- **Key points:**
  - Pending → Syncing → Synced, or Rejected with a reason. A lost connection goes back to Pending.
  - Sync runs by itself whenever `/ready` answers.
  - The UUIDs are made on the phone, so the same result sent twice is a "duplicate", never a second row.
- **Likely question:** "Why not Firebase or PowerSync?" → "They work too. We wanted the sync contract visible and testable against our own Go API."
- **Go deeper:**
  - [Create offline-first apps (Android Developers, YouTube)](https://www.youtube.com/watch?v=jaZ2gLMGUsM)
  - [How to make an offline-first app in Flutter (Arthur Giani, YouTube)](https://www.youtube.com/watch?v=lixgKQeLg_U)
  - [Hive CE](https://pub.dev/packages/hive_ce)

### 21. Testing the UI · 0:30
- **Open with:** "97 tests, and a golden image for every screen state in light and dark."
- **Key points:** accessibility checks found 4 real bugs: text contrast of 4.18:1, a crash under reduce motion, a 40 dp tap target, an unlabelled switch.
- **Go deeper:** [`matchesGoldenFile`](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html)

## Act 4: Coming back online · Titus (Go, 22–24) · Paul (RAG, 25–29) · 7:15

### 22. One door: go-backend · 1:15
- **Open with:** "When the network comes back, the app talks to exactly one service."
- **Key points:**
  - Go owns sync, history and model releases, and proxies predictions and advice.
  - Why sending twice is safe: one SQL line, `ON CONFLICT (id) DO NOTHING`. The same id inserts nothing, and the phone gets "duplicate".
- **Go deeper:** [Designing robust APIs with idempotency (Stripe)](https://stripe.com/blog/idempotency)

### 23. Safe model updates · 0:45 (skip if late)
- **Open with:** "Shipping a new model is a download. Downloads fail."
- **Key points:** ETag/304 keeps checks cheap; the sha256 is checked **before** switching; the previous model is kept.
- **Go deeper:** [Android 16 KB page sizes](https://developer.android.com/guide/practices/page-sizes)

### 24. Extras when online · 0:45 (skip if late)
- **Open with:** "When the network is there, the app gets three extras, all through go-backend."
- **Key points:**
  - Second opinion: the photo is uploaded only when the user taps. Live run: phone 87.8%, server 84.3%, both late blight.
  - Advice: question + disease label → cited answer (Paul explains next).
  - Model update: 304 if unchanged, else download → sha256 check → switch, keep the old model.

### 25. Why not just ask a chatbot? · 0:45 · Paul
- **Handover (Titus, end of 24):** "The app can diagnose. Paul will show how it explains what to do."
- **Open with:** "Why not just send the question to a chatbot?"
- **Key points:**
  - A plain chatbot answers from memory: no sources, and it may invent advice.
  - RAG first finds trusted text (our notes), then lets the AI answer only from it, citing [n], or say "not enough information".
- **Transition:** "The AI part is Ollama."

### 26. What is Ollama? · 1:00
- **Open with:** "Ollama is a free app that runs a text AI on our own laptop."
- **Key points:**
  - It runs llama3.1:8b locally: no cloud, no per-call fee, and questions stay private.
  - It writes the advice, and it graded our answers' quality.
  - It does NOT diagnose leaves; that's MobileNetV2 on the phone.
  - About 3.5 s warm and 20 s cold, so advice is an extra and never blocks.
- **Go deeper:** [Ollama](https://ollama.com)

### 27. How the librarian finds paragraphs · 1:00
- **Open with:** "Here's how the librarian finds the right paragraph."
- **Key points:**
  - Our 3 notes are split into 17 small chunks; each chunk becomes a list of numbers that captures its meaning.
  - Think of a **map of meaning**: "remove infected leaves" and "destroy cull piles" sit close; the question lands near them.
  - The bridge: each note carries the model's label, so the app's question searches only that disease's note.
- **Skip if late:** say the bridge line, skip the map.
- **Go deeper:** deep dive "The librarian's two cases, the writer's rules".

### 28. "What do I do about this?" · 1:15
- **Open with:** "A diagnosis without advice is half an answer."
- **Key points:**
  - RAG in two steps: the librarian finds the right paragraph in our notes; the writer (Ollama) explains it, citing `[n]`.
  - Read the real answer and its [3] source.
  - Faithfulness went from **0.51 → 0.88** after two fixes: no "padding" rule in the prompt, and self-contained "Cause" sentences in the notes.
  - Off-topic questions are refused before Ollama is even called.
- **Go deeper:**
  - [What is RAG? (IBM Technology, YouTube)](https://www.youtube.com/watch?v=T-D1OfcDW1M)
  - [Original RAG paper](https://arxiv.org/abs/2005.11401)
  - [Ragas docs](https://docs.ragas.io)

### 29. Same knowledge, offline · 0:30 (skip if late)
- **Open with:** "And the same notes are bundled in the app, so the library works in airplane mode."
- **Transition:** "Enough slides. Let's show it."

## Act 5: Demo and honesty · both · 5:30

### 30. Live demo · 3:00
See the [demo runbook](#demo-runbook) below. Titus drives the phone and Paul narrates.

### 31. One leaf, end to end · 0:30
- **Open with (Paul):** "One leaf, end to end, in five steps."
- **Key points:** read the five cards left to right, one line each: learn → convert → advise → front desk → phone.
- **Transition:** "Now the honest part."

### 32. Limitations, honestly · 1:30
- **Open with (Paul):** "95.8% is on lab photos. Here's the number that matters."
- **Key points:**
  - **54.8%** on 221 field photos (PlantDoc).
  - The model knows "diseased": only 0.9% of diseased leaves were called healthy. But it confuses the two blights, and the threshold doesn't catch it: it still answers 86% of field photos, at 55%.
  - Next: field data collected with consent, calibration, and real-phone benchmarks.
- **Go deeper:** [PlantDoc paper](https://arxiv.org/abs/1911.10317)

### 33. Five takeaways · 0:30
Paul reads takeaways 1–3 and Titus reads 4–5, one line each, then stops.

### 34. Any questions? · 5:00 (Q&A)
- Point at the QR: "How was this session? Scan, tap the stars, anonymous."
- Use the [Q&A bank](#qa-bank). After this: the **Deep dives** index (35) and slides 36–46, then Built vs next (47) and Glossary (48).

---

---

## Demo runbook

**Roles:** Titus drives one emulator (or a mirrored phone) and Paul narrates and watches the clock. **Slot: 3:30.**

### How the app behaves (real build, checked 2026-11-04)
| Thing | Behaviour |
|---|---|
| Diagnosis | On the device with LiteRT. Sample photos: late blight 87.8%, early blight 67.2%; the blurry sample → "Not sure" |
| New diagnosis | Saved on the phone as **Pending** |
| Online / offline | Online = go-backend answered `/ready` in 2 s; re-checked every 10 s |
| Sync | Automatic when online: Pending → Synced within ~10 s; History's refresh icon forces it |
| Advice | Real call through go-backend to rag-service and Ollama; ~3.5 s warm, ~20 s cold |
| Data | Kept across restarts (Hive). For a clean demo, uninstall/reinstall the app the day before |

### The day before
- [ ] Rehearse twice with a timer, once with a deliberate failure (stop Docker) to practise the fallback.
- [ ] Record the **backup video** of the full path (macOS **Cmd + Shift + 5**). Save it to the desktop **and** a USB stick.
- [ ] `ollama list` shows `llama3.1:8b` (~4.9 GB; never pull it on venue Wi-Fi).
- [ ] Laptop: notifications off, battery at 100%, charger packed, emulator readable from the back row.

### 60 minutes before
```bash
ollama serve &                                    # or open the Ollama app
cd ai-crop-disease-platform && docker compose up -d --build --wait
curl -s localhost:8080/ready                      # all true
curl -s -X POST localhost:8080/api/v1/advice -H 'X-API-Key: dev-key' \
  -H 'Content-Type: application/json' \
  -d '{"question":"What should I do today?","class_name":"Potato___Late_blight"}' | jq .answer   # warms Ollama
flutter emulators --launch Medium_Phone
cd mobile-app && flutter run -d emulator-5554     # or VS Code: "LeafCheck: real backend (emulator)"
```
On a **real phone**, use the laptop's IP: `flutter run --dart-define=SERVER_URL=http://<ipconfig getifaddr en0>:8080`,
on the same network (your hotspot, not the venue Wi-Fi).

### 5 minutes before
- [ ] App on the **Scan** tab; Diagnostics shows all services working.
- [ ] Re-run the warm-up `curl` (Ollama unloads idle models after a few minutes).
- [ ] Backup video open and paused on frame 1.

### Script (3:30)
| Time | Titus does | Paul says |
|---|---|---|
| 0:00 | Turn on airplane mode; point at the offline banner | "No connection. Watch what still works." |
| 0:15 | Scan a leaf → Use a sample photo → late blight | "Everything you're about to see runs on the phone." |
| 0:35 | Result appears; point at confidence and "On-device · ms" | "Late blight, about 88%, above the threshold. Saved before it was shown." |
| 0:55 | History → point at **Pending** | "It's in the outbox, waiting for a connection." |
| 1:05 | Scan the **blurry** sample → "Not sure" | "And when the photo is bad, it says so instead of guessing." |
| 1:25 | Turn airplane mode off; History | "Back online… and it syncs by itself: Synced." |
| 1:50 | Open the late-blight result → **Ask the server for a second opinion** | "The server's model agrees, about 84%." |
| 2:15 | **Get advice** → "What should I do today?" | "Now the librarian and the writer: a real answer from our notes, with sources." |
| 3:00 | Point at the `[n]` source | "That's offline-first: the network is an upgrade, not a requirement." |

### Failure handling (decide in ≤ 10 seconds)
| Symptom | Do this |
|---|---|
| App frozen or crashed | Play the backup video from the matching timestamp |
| Still "Pending" after 20 s online | Tap History's refresh icon once; if still pending → "the backend is our weak point today" → video |
| Advice spinner > 20 s | "Cold model; this is exactly why advice never blocks the diagnosis." Move on; show slide 28 |
| Advice "unavailable" | Show it: graceful failure is a feature |
| Docker not running at all | Do steps 0:00–1:05 (no backend needed), then the video |
| Laptop / projector dies | Paul continues from the PDF on the USB stick |
| Running late | Cut the blurry photo and the second opinion (≈45 s) |

### After the demo
- Leave the app running for Q&A ("can you show the model screen?" → Settings → Diagnosis model).
- Don't stop Docker until the session ends.

### Fallback: mock build (no backend at all)
`flutter run --dart-define=SCENARIO=offline` (or `online`, `adviceDown`, …) runs the same screens on built-in data,
with no network. Use it only if the backend can't start; say "this is the design build".

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
| Running late (>2 min behind at slide 13) | Skip 18, 23, 24 and 29 (≈3:00 saved) |
| Running early | Expand 15 (ask the room) and 32 (field-error examples) |
| 5 minutes left in the talk | The off-stage speaker raises a hand; jump to 32 |
| A question during the talk | Park it: "great, let's take it at the end" |
| HDMI/adapter fails | Bring USB-C→HDMI and USB-C→VGA adapters; keep a **PDF** of the deck on a USB stick |
| Fonts missing on the venue laptop | Present from the PDF (fonts embedded) |
| No venue Wi-Fi | Fine: the backend runs locally in Docker, and demo path A needs no internet |
| One speaker unavailable | The other presents everything: these notes are complete for both |

## Q&A bank

Slides 35–46 are **deep dives** made for Q&A: jump to the one in bold.

Who answers: **P** = Paul (model, ML service, RAG), **T** = Titus (Flutter app, offline sync, Go). Every answer is either backed by a repo file or says "not measured".

### ML and on-device
| Question | Short answer | Who · evidence |
|---|---|---|
| How accurate is it in a real field? | 54.8% on 221 PlantDoc photos. It's good at "diseased vs healthy" (0.9% of diseased leaves called healthy) but weak at telling the two blights apart. | P · `field_eval.json` |
| Isn't 54.8% useless? | For blight-vs-blight, yes, today. That's why we show it and why the next step is field data, not a bigger model. | P · `field_eval.json` |
| Why is lab accuracy so high? | PlantVillage has near-duplicate photos of the same leaf, so test scores are optimistic. | P · `ml-training/README.md` |
| Did you handle the class imbalance? | A weighted sampler in training and a stratified split, so healthy appears in every split. | P · `ml-training/src/crop_ml/data.py` · **show slide 36** |
| Is the model quantized? | No, it's float32 (9.0 MB). Int8 or float16 quantization is the obvious next step for size and speed; we haven't measured its accuracy cost yet. | P · `python-ml-service/scripts/export_tflite.py` |
| GPU / NNAPI delegate? | CPU today. Delegates are a config change in the LiteRT adapter; not benchmarked. | T |
| What about low-end phones and battery? | Not measured yet. Inference is one call per photo, not a video stream, so the battery cost should be small, but we won't claim a number. | P |
| What if I photograph my face, or a maize leaf? | It's a 3-class potato model, so it will still pick one of the three classes. The threshold catches some of these as "Not sure", not all. Out-of-distribution detection is future work. | P |
| Is the confidence calibrated? | Not yet. The threshold is 0.50 from the validation set; calibration is on the next-steps list. | P · `eval_summary.json` |
| Why not ML Kit or Gemini Nano? | We needed our own classifier with a known preprocessing contract. LiteRT runs any `.tflite`. Gemini Nano is generative and only available on some devices. | P |
| Why MobileNetV2 and not a newer model? | Small, fast, well understood on mobile, and trains in seconds with a frozen base. Good enough to tell the on-device story. | P |
| How do you keep Dart preprocessing equal to Python? | A golden test: the Dart tensor vs a Python fixture, max diff ≤ 1e-4. | T · AGENTS.md · **show slide 8, 15** |

### Flutter
| Question | Short answer | Who · evidence |
|---|---|---|
| Is the app real or mocked? | Real, end to end: on-device LiteRT, local storage, sync, advice and model updates. Mock adapters exist only for tests and design states. | T · `lib/app/di/real_overrides.dart` |
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
| What about conflicts? | Diagnoses are append-only facts with phone-made UUIDs, so there's nothing to merge: the same ID is a duplicate, a new ID is a new row. | T · go-backend sync tests · **show slide 43** |
| A batch half fails? | Each item gets its own result (`created` / `duplicate` / `invalid`), so a retry only matters for the failed ones and can't double-insert. | T · go-backend README · **show slide 43** |
| The phone's clock is wrong? | The server refuses times more than 24 h in the future (small skew is accepted so no data is lost), and the app explains why (that's the "rejected" screen). | T · `go-backend/internal/domain/diagnosis/diagnosis.go` |
| Doesn't the outbox grow forever? | Synced items leave the outbox; history stays local. Size limits are a later concern for one farmer's photos. | T |
| Two phones, one farmer? | History is per device today. Account sync is out of scope. | T |
| Why not Firebase, PowerSync or Drift? | They're fine choices. We wanted the sync contract visible and testable against our own API. | T |
| How do you know you're "online"? | `GET /ready` answered within 2 s. `connectivity_plus` alone says there's a network, not that the server is reachable. | T · **show slide 45, 46** |

### Backend and RAG
| Question | Short answer | Who · evidence |
|---|---|---|
| Does the LLM hallucinate? | It answers only from retrieved notes with `[n]` citations; faithfulness is 0.88 on our eval. It's 5 questions with an 8B judge, so directional, not proof. | P · PRESENTATION_PLAN · **show slide 40, 41** |
| What if I ask something unrelated? | Off-topic questions are refused before any LLM call ("How do I fix my car engine?" → refused). | P · `rag-service/README.md` · **show slide 40** |
| Prompt injection? | The notes are curated by us, not user-supplied, so injection through retrieval is limited; user questions are still untrusted input. Not formally tested. | P · **show slide 40** |
| Cost and latency at scale? | A local model via Ollama: no per-call fee, ≈3.5 s warm. Scaling means a GPU server; we haven't load-tested. | P · `benchmarks/results.md` D4 |
| How is the API secured? | An `X-API-Key` per request plus a separate admin key; HTTPS in release builds. Per-user auth is future work. | T · go-backend README · **show slide 42, 39** |
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

