# Presentation slides: "Beyond the API Call: On-Device AI in Flutter with LiteRT and Offline-First Architecture"

The slide-by-slide outline for the talk, the PowerPoint template to build it in, and where every
screenshot and number comes from. Background and progress: [`PRESENTATION_PLAN.md`](PRESENTATION_PLAN.md).
How to present each slide, with links to share: [`PRESENTATION_SPEAKER_GUIDE.md`](PRESENTATION_SPEAKER_GUIDE.md).

**Session:** FlutterconKE, Flutter AI / Mobile track, Advanced, **40 min** (≈35 min talk + 5 min Q&A).
**Speakers:** Paul Mburu (Mobile Engineer, Pezesha · @paulnm) and Titus Kariuki (Mobile Developer, Volane International).

**Focus:** the Flutter app (`mobile-app/`), with about 60% of the time. The ML, RAG and Go services each
appear at the moment the app needs them, so the story never leaves the phone.

---

## 1. PowerPoint template

**Use: SlidesCarnival "Minimal Scientific Conference Slides"**
https://www.slidescarnival.com/template/scientific-conference-slides/331609

| | |
|---|---|
| Cost / licence | Free, no sign-up, no limits (per SlidesCarnival, checked 2026-11-02) |
| Format | Opens in Canva → **Share → Download → Microsoft PowerPoint (.pptx)**; also Google Slides |
| Why this one | Minimal and data-friendly: room for code, diagrams and benchmark tables; no stock-photo clutter; recolours cleanly to the app's palette, so app screenshots look native on the slides |
| Not chosen | Slidesgo "Tech Business Conference" / "Agriculture Tech Pitch Deck" (credit slide required, decorative); SlidesMania "Mr. G" (Google colours clash with leaf green); `flutter_deck` (slides as a Flutter app, no .pptx) |

### Keep the template's palette (no recolour)
Its sage greens already sit well next to the app's leaf green, so the screenshots stay the only saturated colour.

| Element | Value |
|---|---|
| Backgrounds | White `#FFFFFF` · mint `#EAF5F1` · dark green `#466546` (section dividers, Q&A) |
| Accent / rules | Sage `#ADCCAD`; titles in `#466546` on light slides, white on dark |
| Number colours (results slides only) | Healthy `#2E7D32` · Early blight `#B26A00` · Late blight `#B23B1E` (from `mobile-app/lib/ui/theme/tokens.dart`) |
| Fonts | Template's **Gothic A1** (titles Light 300 under a thin rule; body 300/400) · **JetBrains Mono** for code |

Use the light goldens on every slide; the screenshots sit on the mint panel on dark slides.

Layout rules:
- Screenshots go on rounded cards (radius ≈ 16 px), all at the same height.
- At most 3 phone screenshots per slide.
- One idea per slide; numbers big.

---

## 2. Time plan (40 min, 24 slides, two speakers)

| Act | Slides | Time | Speaker | Service in focus |
|---|---|---|---|---|
| 1 Why on-device | 1–3 | 4 min | Paul | – |
| 2 Where the model comes from | 4–5 | 4 min | Paul | ML training + `python-ml-service` |
| 3a On-device AI in Flutter ★ | 6–11 | 10 min | Titus | **Flutter** (`flutter_litert`, preprocessing, abstain) |
| 3b Offline-first Flutter ★ | 12–15 | 6 min | Titus | **Flutter** (Hive, `connectivity_plus`, outbox, design system, tests) |
| 4 Coming back online | 16–18 | 4 min | Titus | `go-backend` (shown through the app) |
| 4 What to do about it | 19–20 | 2 min | Paul | `rag-service` |
| 5 Demo and honesty | 21–23 | 5 min | Titus drives the demo, Paul narrates and takes limitations | Flutter |
| Q&A | 24 | 5 min | Both | – |

Paul covers the ML service and RAG; Titus covers the Flutter app and the Go service. Two handovers: 5 → 6 and 18 → 19.

On service slides the **left half is the Flutter screen** and the right half is the service behind it.

---

## 3. Slides

Screenshot paths are relative to `mobile-app/test/goldens/` unless noted. ★ = Flutter-focused.

### Act 1: Why on-device
| # | Title | Say / show | Visual | Source |
|---|---|---|---|---|
| 1 | Beyond the API Call | Talk title, both speakers | `mobile-app/assets/splash/splash_icon.png` | – |
| 2 | A leaf and no signal | Late blight can destroy a field within days; farms often have no signal | `s8_a_onboarding_1.png` (field photo) | `rag-service/knowledge/potato_late_blight.md` |
| 3 | The cost of the API call | 3 MB photo: ≈1.3 s Wi-Fi · ≈34 s 3G · ≈4 min 2G vs **1.9 ms on the phone** | Bar chart (log scale) | `benchmarks/results.md` D2, D3 (network modelled) |

### Act 2: Where the model comes from (ML service)
| # | Title | Say / show | Visual | Source |
|---|---|---|---|---|
| 4 | Data → model | 2,152 potato images; healthy only 152 (6.6× fewer); MobileNetV2 with frozen base, ~40 s to train; **95.8%**, macro F1 0.945 | `ml-training/outputs/plots/class_distribution.png` + `confusion_matrix.png` | `ml-training/outputs/eval_summary.json` |
| 5 | One model, two runtimes | `python-ml-service`: PyTorch `/api/v1/predict` and export to `.tflite` (9.0 MB, `[1,224,224,3]` → `[1,3]`, matches PyTorch to 8e-7) + `crop_disease_v1.json` = **the contract the app reads** (labels, threshold, input shape) | Diagram: `.pt` → `.tflite` + `.json` → phone | `python-ml-service/scripts/export_tflite.py`, `docs/API_CONTRACT.md` |

### Act 3: Inside the Flutter app ★
| # | Title | Say / show | Visual | Source |
|---|---|---|---|---|
| 6 | ★ The app at a glance | Diagnose offline, history, settings | `s1_a_scan_online` · `s3_a_result_late_blight` · `s5_a_history_1` · `s7_a_settings` | – |
| 7 | ★ Clean layers in Flutter | `flutter_litert` behind the `Classifier` port (ARCHITECTURE §12); domain → application (use cases, ports) ← infrastructure (LiteRT, Hive, Dio; mocks today); presentation reads use cases only; `app/di/providers.dart` is the single wiring point; an architecture test enforces it | Layer diagram + 6-line `providers.dart` snippet | `mobile-app/ARCHITECTURE.md` §3, `test/architecture_test.dart` |
| 8 | ★ Capture → analyze | Photo picker → inference in an isolate; result saved **before** it is shown; scan line held ≥ 600 ms so it reads | `s1a_a_photo_source` → `s2_a_analyzing_start` → `s2_b_analyzing_end` | `lib/features/diagnosis/presentation/analyzing/` |
| 9 | ★ The silent bug | Same model, one preprocessing slip: forgot ÷255 → **9.3%** (210 of 216 leaves called "healthy"); red/blue swapped → 55.6%; **no error is raised**. Fix: a golden test that compares the Dart tensor with Python's | Table: correct 95.8 · no ÷255 9.3 · BGR 55.6 | `ml-training/outputs/mismatch.json` |
| 10 | ★ Show the answer honestly | Confidence bar with threshold tick; top-3; on-device latency + model version; status = icon + label + colour | `s3_a_result_late_blight` · `s3_c_result_early_blight` · `s3_b_result_healthy` | `lib/features/diagnosis/presentation/result/` |
| 11 | ★ Don't guess: abstain | Threshold 0.50 → answers **96.3%** of photos, **97.1%** of those correct; below it: "Not sure, retake" | `s3_d_result_not_sure_1` | `ml-training/outputs/mismatch.json` (`correct`), PRESENTATION_PLAN A6 |
| 12 | ★ Offline is the default | Scanning never disabled; online = `GET /ready` answered within 2 s, not `connectivity_plus` alone | `s1_b_scan_offline` · `s4_d_advice_offline` | `lib/features/settings/presentation/shared/backend_status_provider.dart` |
| 13 | ★ Write first, sync later | Outbox; UUID made on the phone; re-sending a batch returns `duplicate`, never a second row; rejected items explain why | `s5_a_history_1` → `s5_b_history_syncing` · `s5_d_result_sync_rejected_1` | `go-backend` sync tests (100 created → 100 duplicate) |
| 14 | ★ Design system → code | Stitch DESIGN.md → `ui/theme` tokens; a drift test fails if they diverge; 19 shared widgets; Stitch errors corrected, not copied | `c0_component_reference.png` | `test/ui/theme/design_tokens_test.dart`, `docs/UI_IMPLEMENTATION.md` §1 |
| 15 | ★ Testing the UI | 91 tests; a golden per screen state, light + dark; accessibility checks found 4 real bugs (text contrast 4.18:1, crash under reduce motion, 40 dp tap target, unlabelled switch) | Grid of 6 goldens + `dark/s3_a_result_late_blight.png` | `mobile-app/docs/UI_TASKS.md` |

### Act 4: Coming back online (Go + RAG, shown through the app)
| # | Title | Say / show | Visual | Source |
|---|---|---|---|---|
| 16 | One door: go-backend | The app talks only to Go: `diagnoses:sync`, device history, model releases, `/predictions` and `/advice` proxies, PostgreSQL; same DDD layering as the app | Left `s7_b_diagnostics_2` · right gateway diagram | `go-backend/README.md`, `docs/API_CONTRACT.md` |
| 17 | Safe model updates | ETag/304 → Range download → **sha256 check before switching** → previous model kept; a bad file is refused | `s6_b_model_update_available` → `s6_c_model_downloading` → `s6_d_model_installed` · `s6_e_model_check_failed` | `go-backend` model releases, `lib/features/model_update/` |
| 18 | Second opinion | Phone 76.5% vs server 81.2% (app → Go → ML service); the photo leaves the phone only when the user asks | `s3_e_result_second_opinion` | mock values; live via `/api/v1/predictions` |
| 19 | "What do I do about this?" | `rag-service`: curated notes → retrieval → local LLM, answer with `[n]` sources; faithfulness **0.51 → 0.88** after two fixes (no padding rule; self-contained "Cause" sentences); warm answer ≈3.5 s, so it's an add-on; graceful when down | `s4_a_advice_questions` → `s4_c_advice_answer` · `s4_e_advice_unavailable` | PRESENTATION_PLAN "What moved the RAG scores", `benchmarks/results.md` D4 |
| 20 | Same knowledge, offline | The RAG notes are bundled in the app as a disease library | `s9_a_disease_library` → `s9_b_late_blight` | `mobile-app/assets/knowledge/` |

### Act 5: Demo and honesty
| # | Title | Say / show | Visual | Source |
|---|---|---|---|---|
| 21 | Live demo | Two emulators (mock UI): offline phone scan → Pending · blurry → Not sure · online phone Sync now → Synced · Get advice · then the real `curl` to go-backend `/advice` | `s1_b_scan_offline` · `s5_b_history_syncing` + code box; **backup screen recording** | `PRESENTATION_SPEAKER_GUIDE.md` demo runbook |
| 22 | Limitations | **95.8%** lab photos vs **54.8%** on 221 PlantDoc field photos; the model knows "diseased" (0.9% of diseased leaves called healthy) but confuses the two blights, and the threshold doesn't catch it (answers 86%, at 55%); phone benchmarks still to measure | Two big numbers + `s7_c_speed_test` ("where phone numbers will appear") | `ml-training/outputs/field_eval.json` |
| 23 | Five takeaways | 1. Measure the network cost. 2. Preprocessing is part of the model. 3. Let the model abstain. 4. Write first, sync idempotently. 5. Verify every update. | Text only | – |
| 24 | Thank you / Q&A | Both names; no repo link | Splash icon | – |
| 25 | Backup · What is real today | Real vs mock, shown only if asked | Two-column table | guide "What is real today" |

---

## 4. Screenshots: preparation

**Built deck:** [`presentation/LeafCheck_FlutterconKE.pptx`](presentation/LeafCheck_FlutterconKE.pptx) (24 slides, speaker notes included),
generated by [`presentation/build_deck.py`](presentation/build_deck.py). Install **Gothic A1** and **JetBrains Mono**
(Google Fonts) on the presenting laptop, or PowerPoint substitutes another font.

- **Clear screenshots:** the deck uses a 3x render of every golden (1236 × 2745), not the 1x test goldens:
  ```bash
  cd mobile-app && flutter test --update-goldens --dart-define=SHOT_DPR=3 \
      --dart-define=SHOT_DIR=$PWD/../docs/presentation/screens/
  /tmp/pptvenv/bin/python ../docs/presentation/build_deck.py   # venv: pip install python-pptx pillow
  ```

- **Where:** `mobile-app/test/goldens/` (light) and `mobile-app/test/goldens/dark/` (dark). Size 412 × 915, no status bar or device frame.
- **Regenerate** after UI changes: `cd mobile-app && flutter test --update-goldens`.
- **Photos:** every golden includes its leaf/field photo (`loadImages` in `test/helpers.dart` decodes them before the snapshot).
- **Which theme:** light goldens throughout (see §1); `dark/` only for a "dark mode works too" aside. Don't mix themes on one slide.

## 5. Before the talk
- Pre-warm Ollama (first RAG call ≈3 s, cold start longer); run `docker compose up -d --build --wait`; check `curl localhost:8080/ready`.
- Emulator snapshot ready on the Scan screen; airplane-mode toggle rehearsed.
- Backup recording of slide 21 on the laptop (no network needed).
- Network times on slide 3 are **modelled**; say so. RAGAS on 5 questions with an 8B judge is directional.
