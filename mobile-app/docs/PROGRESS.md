# Progress: mobile-app

Update this file whenever a milestone item changes state. Evidence = a command's output, a test name or a commit.

| Milestone | Status | Date |
|---|---|---|
| D0 Design | 🟡 Docs done; Stitch screens pending | 2026-10-30 |
| F0 Scaffold | ⏳ Not started | |
| F1 On-device diagnosis | ⏳ Not started | |
| F2 Offline-first sync | ⏳ Not started | |
| F3 Advice + second opinion | ⏳ Not started | |
| F4 Model update | ⏳ Not started | |
| F5 Talk polish + demo | ⏳ Not started | |
| F6 After the talk | ⏳ Not started | |

## D0: Design 🟡

| Item | Evidence |
|---|---|
| Architecture | `ARCHITECTURE.md` (commit 4507171) |
| Stitch prompts (35 screens/states) | `design/STITCH_PROMPTS.md` (commit 4507171) |
| README, PRD, ROADMAP, PROGRESS, AGENTS | this commit |
| Stitch screens exported | ⏳ `design/export/` |

## Decision log

| Date | Decision | Why |
|---|---|---|
| 2026-10-30 | Riverpod 3, no code generation | DI + state in one package; plain Dart 3 sealed classes |
| 2026-10-30 | Talk MVP first (S1–S7); onboarding, library and splash in F6 | Time to the talk |
| 2026-10-30 | Android first, 412 × 915 designs; iOS must build | The demo runs on Android |
| 2026-10-30 | `tflite_flutter` (official) with `flutter_litert` as the fallback behind the `Classifier` port | tflite_flutter's last release was 2025-10 |
| 2026-10-30 | Hive CE for data, `flutter_secure_storage` for the access key | Hive isn't encrypted storage for secrets |
| 2026-10-30 | Flutter upgrade needed (3.41.6 → 3.47.9) | Package minimums (go_router 18, riverpod 3.4, very_good_analysis 11) |
| 2026-10-30 | Bundle the Inter font, no google_fonts | google_fonts downloads at runtime, which breaks offline |

## Next: D0 → F0
- [ ] Generate and export the Stitch screens
- [ ] Upgrade Flutter (move the stray `bugreport-*.zip` out of the SDK folder first)
- [ ] F0 scaffold
