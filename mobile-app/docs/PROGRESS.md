# Progress: mobile-app

Update this file whenever a milestone item changes state. Evidence = a command's output, a test name or a commit.

| Milestone | Status | Date |
|---|---|---|
| D0 Design | ✅ Docs + Stitch screens in `designs/`; UI spec in `UI_IMPLEMENTATION.md` | 2026-10-30 |
| F0 Scaffold + UI on mock data | ✅ Talk MVP screens S1–S7 done (UI_TASKS U0–U13) | 2026-10-30 |
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
| Stitch screens exported | ✅ `designs/` (45 folders) |

## Decision log

| Date | Decision | Why |
|---|---|---|
| 2026-10-30 | Riverpod 3, no code generation | DI + state in one package; plain Dart 3 sealed classes |
| 2026-10-30 | Talk MVP first (S1–S7); onboarding, library and splash in F6 | Time to the talk |
| 2026-10-30 | Android first, 412 × 915 designs; iOS must build | The demo runs on Android |
| 2026-10-30 | `tflite_flutter` (official) with `flutter_litert` as the fallback behind the `Classifier` port | tflite_flutter's last release was 2025-10 |
| 2026-11-03 | Switch to `flutter_litert` as primary, `tflite_flutter` as fallback (replaces the row above) | The talk names flutter_litert; it is actively released (3.9.4, 2026-10-12) |
| 2026-10-30 | Hive CE for data, `flutter_secure_storage` for the access key | Hive isn't encrypted storage for secrets |
| 2026-10-30 | Stay on Flutter 3.41.6; pin compatible packages (go_router 17.5, riverpod 3.3.2, animations 2.2, very_good_analysis 10.2) | Avoid changing the machine's shared SDK |
| 2026-10-30 | Build the UI first with mock adapters behind the real ports | See `UI_IMPLEMENTATION.md` |
| 2026-10-30 | Bundle the Inter font, no google_fonts | google_fonts downloads at runtime, which breaks offline |

## F0: UI on mock data ✅ (UI_TASKS.md U0–U14, 105/105)

| Item | Evidence |
|---|---|
| Flutter 3.41.6 project, DDD layers, architecture test | `test/architecture_test.dart` |
| Theme from Stitch DESIGN.md, drift guard | `test/ui/theme/design_tokens_test.dart` |
| 19 shared widgets + catalogue | `test/ui/widgets/widgets_test.dart`, golden `c0_component_reference.png` |
| Domain, use cases, mock adapters, 8 scenarios | `test/features/**`, `test/app/providers_test.dart` |
| Screens S1–S7, all states, light + dark | page suites + 30 goldens in `test/goldens/` |
| Accessibility | tap target / label / contrast guidelines in every page suite |
| Runs on Android emulator (API 37, 16 KB page image) | `flutter run` with mock data |
| Onboarding, offline disease library (real notes), native splash | `test/features/onboarding`, `test/features/library` |
| Totals | 91 tests green; `flutter analyze` clean |

Design corrections (Stitch output was inconsistent): see `UI_IMPLEMENTATION.md` §1.

## Next: D0 → F0
- [x] Generate and export the Stitch screens (`designs/`)
- [x] F0 scaffold + UI on mock data
- [x] U14 onboarding, library, splash
- [ ] F1: replace MockClassifier/MockDiagnosisRepository with LiteRT + Hive
