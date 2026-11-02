# UI tasks (mock data phase)

A checklist for building the UI described in [`UI_IMPLEMENTATION.md`](UI_IMPLEMENTATION.md) (referred to
as **§n** below). Designs are in [`../designs/`](../designs/).

**How to use:**
- **Order:** work through phases in order. U0–U5 come first; after that, U6–U12 can be done in any order.
- **Ticking:** tick `[x]` a task only after its **Done when** check has passed, and add a short evidence note
  after it, e.g. `✓ scan_page_test` or `✓ matches PNG`.
- **Closing a phase:** a phase is closed when its gate passes. Then add a line to [`PROGRESS.md`](PROGRESS.md).
- **Spec changes:** if a task changes the spec, update `UI_IMPLEMENTATION.md` in the same step.

**Phase gate (every phase):**
- `flutter analyze` clean
- `flutter test` green
- for UI phases, each state checked on the emulator next to its `designs/<id>/screen.png`

## Progress

| Phase | Done / total |
|---|---|
| U0 Project setup | 7 / 7 ✅ |
| U1 Core | 7 / 7 ✅ |
| U2 Theme | 6 / 6 ✅ |
| U3 Shared widgets | 21 / 21 ✅ |
| U4 Domain + mocks | 8 / 8 ✅ |
| U5 App shell + router | 4 / 4 ✅ |
| U6 Scan | 7 / 7 ✅ |
| U7 Analyzing | 4 / 4 ✅ |
| U8 Result | 10 / 10 ✅ |
| U9 History | 5 / 5 ✅ |
| U10 Advice | 7 / 7 ✅ |
| U11 Model | 6 / 6 ✅ |
| U12 Settings, Diagnostics, Speed | 5 / 5 ✅ |
| U13 Dark mode + review | 4 / 4 ✅ |
| U14 Onboarding, Library, Splash (F6) | 4 / 4 ✅ |
| **Total** | **105 / 105** ✅ |

---

## U0 Project setup
- [x] **U0.1** Run `flutter create --org com.paulmburu --platforms android,ios --project-name leafcheck .` inside `mobile-app/` (keep the existing docs and designs). · ref §2 · **Done when:** `flutter run` shows the counter app on the emulator. ✓ project created; `flutter build apk --debug` OK (emulator run comes in U5.4)
- [x] **U0.2** In `pubspec.yaml`, add `flutter_riverpod ^3.3.2`, `go_router ^17.5.0`, `animations ^2.2.0`, `flutter_animate ^4.5.2`, and dev `very_good_analysis ^10.2.0`. · ref §2 · **Done when:** `flutter pub get` resolves on Flutter 3.41.6. ✓ pub get on 3.41.6
- [x] **U0.3** Create `analysis_options.yaml` that includes very_good_analysis; remove the counter app. · ref §2 · **Done when:** `flutter analyze` is clean. ✓ analyze: no issues
- [x] **U0.4** Add the Inter font (`assets/fonts/`) and the 5 photos from `designs/close_up_*` and `designs/authentic_*` copied to `assets/images/{leaf_late_blight,leaf_early_blight,leaf_healthy,leaf_blurry,field_rows}.jpg`; declare them in pubspec. · ref §2 · **Done when:** a test loads each asset. ✓ assets_test; photos converted to 800 px JPEG (8 MB → 0.9 MB), Inter v4.1 static TTFs + OFL
- [x] **U0.5** Create the folder skeleton from §3 (`app/`, `core/`, `ui/`, `features/{diagnosis,advice,model_update,settings}/{domain,application,infrastructure/mock,presentation}`). · ref §3 · **Done when:** the tree matches §3. ✓ tree created
- [x] **U0.6** Add `test/flutter_test_config.dart`, which loads Inter for widget and golden tests. · ref §9 · **Done when:** a golden smoke test renders Inter, not Ahem. ✓ flutter_test_config.dart loads Inter
- [x] **U0.7** Add `test/architecture_test.dart` enforcing the layer import rules from AGENTS.md. · ref §3, §9 · **Done when:** it passes, and fails on a deliberate bad import. ✓ architecture_test (2 tests, incl. a deliberate violation)

## U1 Core (`lib/core`, `lib/ui/assets`, `lib/ui/strings`)
- [x] **U1.1** `core/result/result.dart` (sealed `Result<T>`: `Ok`/`Err`) and `failure.dart` (the PRD §5 failures). · ref §3 · **Done when:** a unit test does an exhaustive switch over both. ✓ core_test "switch is exhaustive"
- [x] **U1.2** `core/enums/sync_state.dart`, `connectivity_status.dart`. · ref §4 · **Done when:** compiles; values match §4. ✓
- [x] **U1.3** `core/constants/app_constants.dart` (min analyzing hold 600 ms, history page size, question 3–500 characters, threshold display). · ref §3 · **Done when:** it is referenced instead of literals. ✓ (also maxSyncBatch, speedTestRuns, readyTimeout, recentCount)
- [x] **U1.4** `core/utils/formatters.dart`: percent "76.5%", relative day/time ("Today, 09:12", "Yesterday, 16:40", "27 Oct, 11:05"), bytes "9.0 MB", "3.8 of 9.1 MB", ms "1.9 ms"; plus `clock.dart`. · ref §4 · **Done when:** `formatters_test` covers every format in §4. ✓ core_test Formatters (all §4 formats); Clock is a typedef (lint: one-member interface)
- [x] **U1.5** `core/mock/mock_scenario.dart` (enum + read from `--dart-define=SCENARIO`). · ref §4 · **Done when:** the default is `online`, and a test checks the parsing. ✓ core_test MockScenario
- [x] **U1.6** `ui/assets/app_assets.dart` (image and font path constants). · ref §3 · **Done when:** U0.4's test uses these constants. ✓ assets_test uses AppAssets.all
- [x] **U1.7** `ui/strings/common_strings.dart` (Retry, Online, Offline, Synced, Pending, Syncing, Rejected, Active, Cancel, Undo, …). · ref §3 · **Done when:** no shared literal is duplicated across features (grep). ✓ CommonStrings

## U2 Theme (`lib/ui/theme`)
- [x] **U2.1** `tokens.dart`: light and dark colours, `AppSpace`, `AppRadius` (§7), with the §1 overrides (primary `#2E7D32`). · ref §7 · **Done when:** values equal DESIGN.md. ✓ tokens.dart (+ AppSize); dark tokens from STITCH_PROMPTS §1 (the export has none)
- [x] **U2.2** `typography.dart`: the YAML type scale → `TextTheme`, display-small, and a tabular-figures `numeric` helper. · ref §7 · **Done when:** a test checks the sizes, weights and line heights. ✓ design_tokens_test "type scale"
- [x] **U2.3** `diagnosis_colors.dart`: `ThemeExtension` per condition plus uncertain (main, bar, container, onContainer, icon). · ref §7 · **Done when:** light and dark values are present and `lerp` works. ✓ design_tokens_test "interpolate"; dark diag colours lightened for AA
- [x] **U2.4** `motion.dart`: `AppMotion` durations and curves, plus `ReduceMotion.of(context)`. · ref §7, §8 · **Done when:** a test shows the reduce-motion flag disables animations. ✓ motion_test (OS or app setting)
- [x] **U2.5** `app_theme.dart`: light and dark `ThemeData` with component themes (filled button 56 dp / r16, card, chip, navigation bar 80 dp, bottom sheet r28, snackbar, input). · ref §7 · **Done when:** a widget test reads every component theme. ✓ design_tokens_test "component themes"
- [x] **U2.6** `test/ui/theme/design_tokens_test.dart`: parse the DESIGN.md YAML and compare with the tokens (overrides excepted). · ref §7 · **Done when:** it passes, and fails when a token is changed. ✓ fails when surface changed by 1 bit (checked), passes otherwise

## U3 Shared widgets
> Files are grouped: `buttons/buttons.dart` (Primary, Tonal, AppText), `feedback/banners.dart` (Offline, Error), `layout/layout.dart` (SectionCard, InfoRow, SectionHeader, IconTextRow, AppBottomSheet). Also added `ui/theme/app_icons.dart` (one icon set) and `ui/theme/diagnosis_tone.dart`.

### Tasks (`lib/ui/widgets`, one test each in `test/ui/widgets/`) · ref §5 · reference: `designs/c0_component_reference`
- [x] **U3.1** `buttons/primary_button.dart` (56 dp, r16, optional icon, loading) ✓ widgets_test "buttons"
- [x] **U3.2** `buttons/tonal_button.dart` (48 dp) ✓
- [x] **U3.3** `buttons/app_text_button.dart` ✓
- [x] **U3.4** `chips/status_chip.dart` (neutral / positive / warning / error / progress) ✓ "status chip"
- [x] **U3.5** `diagnosis/diagnosis_icon.dart` + `diagnosis_chip.dart` (icon + label + colour always together) ✓ "diagnosis chip"; ui uses DiagnosisTone, not feature enums
- [x] **U3.6** `diagnosis/confidence_bar.dart` (threshold tick, count-up, reduce motion) ✓ "confidence bar" (+ CountUpText)
- [x] **U3.7** `diagnosis/leaf_photo.dart` (r16, Hero tag) ✓
- [x] **U3.8** `feedback/offline_banner.dart` (slide in/out) ✓
- [x] **U3.9** `feedback/error_banner.dart` ✓
- [x] **U3.10** `feedback/empty_state.dart` ✓
- [x] **U3.11** `feedback/skeleton_lines.dart` (opacity pulse) ✓
- [x] **U3.12** `feedback/app_snackbar.dart` ✓ "snackbar and bottom sheet"
- [x] **U3.13** `layout/section_card.dart` ✓ "layout widgets"
- [x] **U3.14** `layout/info_row.dart` (tabular value) ✓ fixed: value right-aligned like C0
- [x] **U3.15** `layout/section_header.dart` ✓
- [x] **U3.16** `layout/icon_text_row.dart` ✓
- [x] **U3.17** `layout/app_bottom_sheet.dart` (handle, r28, scrim) ✓
- [x] **U3.18** `progress/progress_ring.dart` ProgressRing (ring → check; renamed from DownloadProgress to avoid clashing with the domain type) ✓ ring → check
- [x] **U3.19** `navigation/app_shell.dart` (NavigationBar: Scan / History / Settings) ✓ "app shell"
- [x] **U3.20** Each U3.1–U3.19 test checks 48 dp targets and semantics labels ✓ expectAccessible (tap target, labels, contrast) found primary-text contrast 4.18 → fixed with primaryText #1B5E20
- [x] **U3.21** Debug page `/dev/components` showing every widget. **Done when:** it matches `designs/c0_component_reference/screen.png` ✓ golden test/goldens/c0_component_reference.png reviewed against C0 (icons, chips, headers, bar, banner, card, empty state match)

## U4 Domain + mocks · ref §4
- [x] **U4.1** diagnosis domain: enums (`DiagnosisCondition.fromLabel`, `DiagnosisStatus`, `PredictionSource`), `Confidence`, `Diagnosis`, `Prediction`, ports `DiagnosisRepository` and `Classifier`, with unit tests (status rule, label parsing). ✓ diagnosis_domain_test "domain" (labels, status rule, validation); ports in `domain/repositories/ports.dart` (+ SyncService)
- [x] **U4.2** diagnosis application: `DiagnoseLeaf`, `GetHistory`, `GetDiagnosis`, `DeleteDiagnosis`, with tests using fakes. ✓ use_cases.dart (+ SecondOpinion, SyncDiagnoses); "use cases on mocks"
- [x] **U4.3** diagnosis mocks: `diagnosis_mock_data.dart` (all §4 rows), `MockDiagnosisRepository`, `MockClassifier` (900 ms; asset → result). ✓ exact design data; history dates relative to the clock (Today/Yesterday/27 Oct)
- [x] **U4.4** advice: `AdviceAnswer`, `Citation`, port, `AskAdvice`; `MockAdviceRepository` (3 s, canned answer, scenario errors). ✓ other_features_test "advice" (incl. local 3–500 validation)
- [x] **U4.5** model_update: `ModelRelease`, `DownloadProgress`, `ModelUpdatePhase`, port, use cases; `MockModelUpdateRepository` (progress stream over 6 s, checksumFail). ✓ "model update" (download → activate → rollback; checksum keeps v1)
- [x] **U4.6** settings, connectivity and sync: `AppSettings`, `BenchmarkResult`, `ServiceHealth`, `BackendStatus`, ports; mocks driven by `MockScenario`; `MockSyncService` (1.5 s flip). ✓ "settings and status"; BackendStatus lives in settings/domain
- [x] **U4.7** `app/di/providers.dart` (one provider per port) + `mock_overrides.dart` (scenario → overrides). ✓ providers_test: all use cases resolve in all 8 scenarios; unbound port fails loudly
- [x] **U4.8** **Done when:** every use case test passes, and the architecture test passes (no presentation → infrastructure import). ✓ 45 tests green; architecture test green

## U5 App shell + router · ref §8
- [x] **U5.1** `app/router/routes.dart` (path and name constants for every route in §8). ✓
- [x] **U5.2** `app/router/app_router.dart`: `StatefulShellRoute.indexedStack`, pushed routes, transitions (fade-through, shared axis), reduce-motion fallback. ✓ StatefulShellRoute + FadeThroughBranches (tabs keep state); shared axis for settings sub-pages; fade for analyzing
- [x] **U5.3** `app/app.dart` + `main.dart` (`ProviderScope` with mock overrides, theme mode from settings). ✓ App (theme mode + ReduceMotionScope from AppSettingsController); main binds mocks via --dart-define=SCENARIO
- [x] **U5.4** **Done when:** the app launches with 3 placeholder tabs that switch with fade-through; back navigation works. ✓ app_test (tabs, push, back, no nav bar on pushed pages); runs on emulator (Android 17, 16 KB image)

## U6 Scan (S1-A/B/C, S1a) · ref §6 · designs `s1_a_scan_online`, `s1_b_scan_offline`, `s1_c_scan_first_run`, `s1a_a_photo_source`
- [x] **U6.1** `diagnosis/presentation/strings/diagnosis_strings.dart` (all diagnosis copy, per-condition texts). ✓
- [x] **U6.2** `scan/scan_state.dart` + `scan_controller.dart` (connectivity, model version, recent). ✓ scanStateProvider (derived from history, /ready status, active model)
- [x] **U6.3** `scan/widgets/status_row.dart` + `scan_hero_card.dart` (pulse with reduce motion). ✓ pulse stops under reduce motion
- [x] **U6.4** `presentation/widgets/diagnosis_tile.dart` + `scan/widgets/recent_section.dart` (stagger). ✓ + diagnosis_presenter (domain → tone/title), sync_chip; tile 72 dp (fixed from 88)
- [x] **U6.5** `scan/widgets/photo_tips_card.dart` (S1-C) + offline banner wiring (S1-B). ✓ OfflineBanner fix: no AnimatedSize at zero duration (crashed under reduce motion)
- [x] **U6.6** `scan/widgets/photo_source_sheet.dart` (S1a; debug picker of the 4 leaf assets) → starts analyzing. ✓ two-step sheet (source → sample picker); fixed: sheets open on the root navigator to cover the nav bar like the design; picker scrolls
- [x] **U6.7** `scan_page.dart`; page tests for online/offline/firstRun + goldens. **Done when:** all 4 states match their PNGs. ✓ scan_page_test (5 tests, accessibility); goldens vs PNGs via tool/compare_design.py; differences recorded in UI_IMPLEMENTATION §1

## U7 Analyzing (S2-A/B) · designs `s2_a_analyzing_start`, `s2_b_analyzing_end`
- [x] **U7.1** `analyzing/analyzing_controller.dart` (DiagnoseLeaf + min hold, then navigate to `/diagnosis/:id`). ✓ analyzeProvider (FutureProvider.family; DiagnoseLeaf + min hold); pushReplacement to Result
- [x] **U7.2** `analyzing/widgets/scan_line_overlay.dart` (900 ms sweep; static under reduce motion). ✓ fixed position for key frames, rests mid-photo under reduce motion
- [x] **U7.3** `analyzing/widgets/analyzing_caption.dart` + `analyzing_page.dart` (Hero source). ✓ + failure state with retry; Hero tag LeafPhoto.scanHeroTag
- [x] **U7.4** **Done when:** start and end frames match S2-A/S2-B, and Hero flies into Result. ✓ analyzing_page_test: S2-A/S2-B goldens + full scan→analyze→result flow. Design fixes: Stitch omitted the line in S2-A and broke the S2-B photo

## U8 Result (S3-A…E, S5-D) · designs `s3_a_result_late_blight`, `s3_b_result_healthy`, `s3_c_result_early_blight`, `s3_d_result_not_sure_1`, `s3_e_result_second_opinion`, `s5_d_result_sync_rejected_1`
- [x] **U8.1** `result/result_state.dart` + `result_controller.dart` (diagnosis, second-opinion state, advice availability). ✓ resultProvider (live from history) + SecondOpinionController (family notifier)
- [x] **U8.2** `result/widgets/diagnosis_header.dart` (including the "Not sure" variant). ✓ result_header.dart (chip + title + italic pathogen / not-sure text)
- [x] **U8.3** `result/widgets/confidence_card.dart` + `top_k_rows.dart` (count-up). ✓ uncertain lists all three classes (fixes Stitch S3-D wrong %)
- [x] **U8.4** `result/widgets/meta_row.dart` + `meaning_card.dart`. ✓ in result_cards.dart
- [x] **U8.5** `result/widgets/retake_tips_card.dart` (S3-D). ✓
- [x] **U8.6** `result/widgets/second_opinion_card.dart` (S3-E, container transform). ✓ values stacked so names never wrap mid-word (fixes Stitch S3-E)
- [x] **U8.7** `result/widgets/sync_rejected_banner.dart` (S5-D). ✓ ErrorBanner once (Stitch S5-D repeated it 3×); error-card actions use onErrorContainer
- [x] **U8.8** `result/widgets/result_actions.dart` (Get advice / Retake photo + second opinion) + delete confirmation. ✓ Retake → Scan; delete asks first; second opinion offline → snackbar
- [x] **U8.9** `result_page.dart` assembling the states. ✓
- [x] **U8.10** Page tests + goldens. **Done when:** all 6 states match their PNGs. ✓ result_page_test 7 tests (all 6 states + delete), goldens compared side by side

## U9 History (S5-A/B/C) · designs `s5_a_history_1`, `s5_c_history_empty` (S5-B from prompt)
- [x] **U9.1** `history/history_state.dart` + `history_controller.dart` (day grouping, pending count, last sync, syncing). ✓ day grouping, pending/syncing counts, last sync label
- [x] **U9.2** `history/widgets/sync_summary_row.dart` + `day_section.dart`. ✓
- [x] **U9.3** Pull-to-sync: chips switch to syncing, then synced (cross-fade), snackbar "Synced 2 diagnoses" (S5-B). ✓ app-bar sync + pull to refresh; chips cross-fade; snackbar; offline explains via snackbar
- [x] **U9.4** `history_page.dart`, empty state (S5-C), tile → Result container transform. ✓ empty → Scan; tile → Result (no nav bar)
- [x] **U9.5** Page tests + goldens. **Done when:** S5-A/C match their PNGs and S5-B matches the prompt. ✓ history_page_test 5 tests; S5-B golden created (no Stitch design); Stitch S5 exports had black margins and a different status-bar time

## U10 Advice (S4-A…E) · designs `s4_a_advice_questions`, `s4_b_advice_loading`, `s4_c_advice_answer`, `s4_d_advice_offline`, `s4_e_advice_unavailable`
- [x] **U10.1** `advice/presentation/strings/advice_strings.dart` (suggested questions per condition, disclaimer, states). ✓
- [x] **U10.2** `advice_sheet/advice_state.dart` + controller (phases from §4). ✓ AdviceController (family by class label); opens in offline phase when /ready says offline
- [x] **U10.3** `advice_sheet/widgets/sheet_header.dart`, `suggested_questions.dart`, `advice_input.dart` (S4-A). ✓ advice_parts.dart (header, suggestions, input)
- [x] **U10.4** `question_bubble.dart` + loading with **SkeletonLines** (S4-B). ✓ QuestionBubble + AdviceLoading
- [x] **U10.5** `answer_text.dart` (citation markers → scroll and highlight), `source_list.dart`, `advice_disclaimer.dart` (S4-C). ✓ advice_answer.dart (markers → scroll + 600 ms highlight; url_launcher ^6.3.3 added, copies link if it cannot open)
- [x] **U10.6** Offline and unavailable states with **EmptyState** + reference caption (S4-D/E). ✓ EmptyState + reference. "Read offline notes" deferred to U14 (library) so it never leads nowhere
- [x] **U10.7** Sheet opened from Result; page tests + goldens. **Done when:** all 5 states match their PNGs. ✓ advice_sheet_test 5 tests; S4-A/B built from the prompt (Stitch exports overlap the Result layer)

## U11 Model (S6-A…E) · designs `s6_a_model_up_to_date`, `s6_b_model_update_available`, `s6_c_model_downloading`, `s6_d_model_installed`, `s6_e_model_check_failed`
- [x] **U11.1** `model/model_state.dart` + controller (check, download stream, activate, undo/rollback). ✓ ModelController (check, download stream, activate, cancel, rollback/undo); refreshes activeModelProvider
- [x] **U11.2** `model/widgets/model_info_card.dart` + `model_status_line.dart` (S6-A). ✓ model_cards.dart (info card, status line)
- [x] **U11.3** `model/widgets/update_available_card.dart` (S6-B). ✓ secondaryContainer (design tone)
- [x] **U11.4** `model/widgets/downloading_card.dart` (S6-C) → installed with ring → check + snackbar Undo (S6-D). ✓ ring → check; snackbar "Model v2 is ready" / Undo
- [x] **U11.5** `model/widgets/check_failed_card.dart` (S6-E). ✓ status line says "Update available" (Stitch S6-E said "Up to date" after a failed install)
- [x] **U11.6** `model_page.dart`; page tests + goldens. **Done when:** all 5 states match their PNGs. ✓ model_page_test (A, B→C→D→undo, E); S6-D built from S6-A (Stitch export unstyled); "Restore built-in" hidden when already built-in (no dead button)

## U12 Settings, Diagnostics, Speed (S7-A/B/C) · designs `s7_a_settings`, `s7_b_diagnostics_2`, `s7_c_speed_test`
- [x] **U12.1** `settings/presentation/strings/settings_strings.dart` + settings state/controller (theme, reduce motion, server, device id). ✓ SettingsStrings; AppSettingsController (from U5) drives theme + reduce motion app-wide
- [x] **U12.2** `settings/widgets/settings_section.dart`, `settings_row.dart`, `theme_segmented.dart`, debug "Mock scenario" row; `settings_page.dart` (S7-A). ✓ settings_widgets.dart + theme_segmented.dart; debug row shows the mock scenario. Fixed: segmented button 40 → 48 dp, switch got a semantic label (both found by the a11y checks)
- [x] **U12.3** `diagnostics/widgets/services_card.dart`, `sync_stats_card.dart`, `phone_info_card.dart`; `diagnostics_page.dart` with refresh (S7-B). ✓ service_row.dart; counts come from real history (design said 148)
- [x] **U12.4** `speed_test/widgets/stat_block.dart`, `comparison_card.dart`; `speed_test_page.dart` with the running state (S7-C). ✓ speed_test_state.dart (auto-runs, progress "Run n of 100"); Stitch avatar removed (DESIGN.md forbids avatars)
- [x] **U12.5** Page tests + goldens. **Done when:** S7-A/B/C match their PNGs, and theme switching works app-wide. ✓ settings_pages_test 4 tests incl. dark theme golden; PlaceholderPage deleted (all routes real)

## U13 Dark mode + review · ref §1, §9
- [x] **U13.1** Dark goldens for S1-A, S3-A, S3-D, S4-C, S5-A, S6-C, S7-A (no glow, AA contrast). ✓ test/goldens/dark_mode_test.dart: 7 screens, each passes textContrastGuideline; goldens in test/goldens/dark/
- [x] **U13.2** Accessibility sweep: contrast, tap targets, labels and reduce motion on every page test. ✓ expectAccessible (tap targets, labels, contrast) runs in every page suite (scan, result, history, advice, model, settings, widgets); reduce motion is the default in page tests; found and fixed 4 issues: primary text contrast, OfflineBanner crash under reduce motion, 40 dp segmented button, unlabelled switch
- [x] **U13.3** Side-by-side review of every golden against its `designs/<id>/screen.png`; fix any differences. ✓ every implemented state compared side by side (tool/compare_design.py) during its phase; fixes recorded per task
- [x] **U13.4** Record the remaining intended differences in UI_IMPLEMENTATION §1; mark F0 UI done in PROGRESS.md. ✓ UI_IMPLEMENTATION §1 lists every intended difference; PROGRESS.md updated

## U14 Onboarding, Library, Splash (F6) · designs `s8_a_onboarding_1`, `s8_b_onboarding_2`, `s8_c_onboarding_3`, `s9_a_disease_library`, `s9_b_late_blight`, `s10_a_splash`, `s10_a_splash_dark`
- [x] **U14.1** `onboarding/` page (PageView, shared axis, `page_dots.dart`, `photo_compare.dart`, `privacy_points.dart`) + first-run flag (S8-A/B/C). ✓ onboarding_page.dart + onboarding_parts.dart; AppSettings.onboarded; MockScenario.onboarding; fixed zero-duration page animation under reduce motion
- [x] **U14.2** (also add "Read offline notes" to S4-D/E) Bundle `rag-service/knowledge/potato_*.md` as assets; `library/` list + detail pages (S9-A/B). ✓ notes bundled to assets/knowledge/ and parsed by AssetDiseaseLibrary (real content, no mock); Scan help icon + advice "Read offline notes" open it; Stitch S9-A chips got their icons
- [x] **U14.3** `flutter_native_splash` config, light and dark (S10) (version checked against 3.41.6 first). ✓ flutter_native_splash ^2.4.7 (2.4.8 needs a newer meta than Flutter 3.41 pins); icon rendered from theme tokens by tool/render_splash_icon_test.dart
- [x] **U14.4** Page tests + goldens. **Done when:** all match their PNGs. ✓ library_test (parser + pages + links), onboarding_test; 91 tests green
