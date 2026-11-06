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

## 2. Time plan (40 min, 34 talk slides + 14 for Q&A, two speakers)

| Act | Slides | Time | Speaker | Focus |
|---|---|---|---|---|
| 1 Why on-device | 1–4 | 3:45 | Paul | Field problem, network cost, the system in one picture |
| 2 Where the model comes from | 5–9 | 5:15 | Paul | Flashcards + 3 piles, MobileNetV2, export, the wrapper, how a model reaches the phone |
| 3a On-device AI in Flutter ★ | 10–18 | 10:00 | Titus | Layers (wall sockets), `flutter_litert`, preprocessing, silent bug, abstain, result meanings |
| 3b Offline-first Flutter ★ | 19–21 | 3:15 | Titus | No internet vs needs backend, sync states, tests |
| 4 Coming back online | 22–29 | 7:15 | Titus (Go, 22–24) · Paul (RAG, 25–29) | go-backend, updates, extras, why RAG, Ollama, the librarian, advice |
| 5 Demo and honesty | 30–33 | 5:30 | Titus drives, Paul narrates | Demo, one leaf end to end, limitations, takeaways |
| Q&A | 34 | 5:00 | Both | Feedback QR on screen |
| Deep dives (Q&A only) | 35–46 | – | – | One section per `docs/learn` part |
| Backup | 47–48 | – | – | Built vs next, glossary |

Skip if late: 18, 23, 24, 29 (and the map on 27). Handovers: 9 → 10 and 24 → 25. Per-slide script: [`PRESENTATION_SPEAKER_GUIDE.md`](PRESENTATION_SPEAKER_GUIDE.md).

## 3. Slides

★ = Flutter-focused · NEW = added from `docs/learn/`. Slides show no repo paths (sources are in the speaker notes).

| # | Title | Visual / code | From |
|---|---|---|---|
| 1 | Beyond the API Call | Field photo, both speakers, feedback QR | – |
| 2 | A leaf and no signal | Field photo | rag-service notes |
| 3 | The cost of the API call | 4 number boxes | `benchmarks/results.md` |
| 4 | The system in one picture | Laptop → phone → backend with roles | `HOW_IT_WORKS.md` |
| 5 | Flashcards → model | Plots + **3 piles** (study / quiz / exam) + imbalance line | `learn/01` |
| 6 | MobileNetV2: it already knows how to see | Frozen-features diagram + PyTorch snippet | `learn/01` |
| 7 | One model, two runtimes | Clinic / translator diagram + export snippet | `learn/02` |
| 8 | NEW · Make the phone's job easy | "Moved inside → so the phone…" table + `MobileWrapper.forward` | `learn/02` |
| 9 | How a model reaches the phone | Two paths + "Never" box | `learn/05` |
| 10 ★ | The app at a glance | 4 screenshots | goldens |
| 11 ★ | Clean layers in Flutter | Layers + providers snippet + **wall sockets** line | `learn/05` |
| 12 ★ | Loading the model with flutter_litert | Dart snippet + label card | `litert_classifier.dart` |
| 13 ★ | Photo → tensor → scores | 7-step flow + Dart snippet | `preprocess.dart` |
| 14 ★ | Capture → analyze | 3 screenshots | goldens |
| 15 ★ | The silent bug | 95.8 / 9.3 / 55.6 | `mismatch.json` |
| 16 ★ | Show the answer honestly | 3 screenshots | goldens |
| 17 ★ | Don't guess: abstain | Decision diagram, % bars, Python rule | `eval_summary.json`, live run |
| 18 ★ | What each result means | 4-row table | `HOW_IT_WORKS.md` |
| 19 ★ | Offline is the default | **No internet needed vs needs the backend** + 10.0.2.2 story | `learn/05` |
| 20 ★ | Write first, sync later | State diagram + 3 screenshots | `learn/05` |
| 21 ★ | Testing the UI | 97 tests, 4 a11y bugs, 3 goldens | `UI_TASKS.md` |
| 22 | One door: go-backend | Gateway diagram + why-line + SQL | `learn/04` |
| 23 | Safe model updates | 3 screenshots | `learn/04` |
| 24 | Extras when online | Second opinion / advice / update table (live 87.8 vs 84.3) | `learn/05` |
| 25 | NEW · Why not just ask a chatbot? | Chatbot vs RAG cards | `learn/03` |
| 26 | What is Ollama? | Does / doesn't + 3 numbers | `learn/03` |
| 27 | NEW · How the librarian finds paragraphs | Notes → 17 chunks → numbers → ChromaDB, **map of meaning**, the label bridge | `learn/03` |
| 28 | "What do I do about this?" | Flow + real answer | live run |
| 29 | Same knowledge, offline | 2 screenshots | goldens |
| 30 | Live demo | Airplane-mode steps | demo runbook |
| 31 | NEW · One leaf, end to end | 5 cards: learn → convert → advise → front desk → phone | `learn/` 01–05 |
| 32 | Limitations, honestly | 95.8% vs 54.8% | `field_eval.json` |
| 33 | Five takeaways | Text | – |
| 34 | Any questions? | Feedback QR card | organisers |

### Deep dives (for Q&A, slides 35–46)
| # | Slide | From |
|---|---|---|
| 35 | Deep dives (index) | – |
| 36 | How the model learned (training loop, early stopping, augmentation) | `learn/01` |
| 37 | One file carries everything (checkpoint contents) | `learn/01` |
| 38 | A photo at the clinic (8 checks + status codes) | `learn/02` |
| 39 | One error shape everywhere | `learn/02` + `04` |
| 40 | The librarian's two cases, the writer's rules | `learn/03` |
| 41 | What moved the answer quality (RAGAS table + lessons) | `learn/03` |
| 42 | Every request at the door (4 checks + layers) | `learn/04` |
| 43 | Sync, safely (outcomes, rules, idempotency) | `learn/04` |
| 44 | Updates, forwarding, storage | `learn/04` |
| 45 | What happens at start-up | `learn/05` |
| 46 | When things go wrong (failure → message) | `learn/05` |
| 47 | Backup · Built vs next | – |
| 48 | Backup · Glossary (14 terms) | `learn/` glossaries |

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
