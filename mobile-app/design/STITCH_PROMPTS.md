# Google Stitch prompts: LeafCheck mobile app

Prompts for designing every screen of the mobile app in [Google Stitch](https://stitch.withgoogle.com)
before any Flutter code exists. They follow [`../ARCHITECTURE.md`](../ARCHITECTURE.md) (§10 screens,
§11 theme and motion), and every number in them comes from this repo.

> **LeafCheck** is a working name. Rename it in prompt 1 only; every other prompt says "the app".

**Why the prompts look like this.** The sources below describe how Stitch works best:
- Stitch reads the project's **DESIGN.md** on every generation, so the theme is defined once there and then locked.
- A prompt works best when it names the screen, lists the content **top to bottom**, gives **real placeholder data** and ends with a **"Do not include"** list.
- A follow-up should change **one thing at a time** and say what must stay the same.
- **Prototype** mode links screens with transitions.

Sources: [Stitch Prompt Guide (Google AI Developers Forum)](https://discuss.ai.google.dev/t/stitch-prompt-guide/83844/149) ·
[DESIGN.md with Stitch (DEV)](https://dev.to/shanmukhavenkatasai/stop-letting-ai-ruin-your-ui-how-to-master-google-stitch-designmd-14p9) ·
[Stitch 2.0 guide (MindStudio)](https://www.mindstudio.ai/blog/google-stitch-2-0-ai-design-tool) ·
[Prototypes and canvas (nxcode)](https://www.nxcode.io/resources/news/google-stitch-complete-guide-vibe-design-2026)

**About animation.** Stitch produces static screens and prototype transitions between them. It does
not make timed micro-animations. So motion is covered in three ways:
1. **Key frames:** the important moments are drawn as separate screens, e.g. Analyzing at the start and at the end, or downloading at 42%.
2. **Prototype transitions:** these screens are linked with transitions (section 5).
3. **Motion spec:** every prompt ends with a block that records the exact animation, which the Flutter build implements from `motion.dart`.

---

## Contents
0. [How to use](#0-how-to-use)
1. [Theme and typography (DESIGN.md)](#1-theme-and-typography-designmd)
2. [Consistency preamble](#2-consistency-preamble)
3. [Component reference screen](#3-component-reference-screen-optional)
4. [Screen prompts](#4-screen-prompts)
   - [S1 Scan (Home)](#s1-scan-home)
   - [S1a Photo source sheet](#s1a-photo-source-sheet)
   - [S2 Analyzing](#s2-analyzing)
   - [S3 Result](#s3-result)
   - [S4 Advice sheet](#s4-advice-sheet)
   - [S5 History](#s5-history)
   - [S6 Model](#s6-model)
   - [S7 Settings and Diagnostics](#s7-settings-and-diagnostics)
   - [S8 Onboarding](#s8-onboarding-later)
   - [S9 Disease library](#s9-disease-library-later)
   - [S10 Splash](#s10-splash-later)
   - [Dark mode variants](#dark-mode-variants)
5. [Prototype and transitions](#5-prototype-and-transitions)
6. [Iteration prompts](#6-iteration-prompts)
7. [Review checklist](#7-review-checklist)

---

## 0. How to use

1. Create a **new Stitch project** and choose **App (mobile)**.
2. Open **DESIGN.md** (Edit Theme) and paste the whole of [prompt 1](#1-theme-and-typography-designmd).
   Check that the colours and font it shows match, then **lock the theme**.
3. Optional: generate the [component reference screen](#3-component-reference-screen-optional) so later screens copy its parts.
4. Generate the screens **in the order of section 4, one prompt per generation**. Every prompt already
   starts with the [consistency preamble](#2-consistency-preamble); paste the fenced block as it is.
5. **States of the same screen** (e.g. Result: healthy vs late blight): duplicate the first state
   screen, then run the state prompt on the duplicate. The layout stays the same and only the content
   changes. If you generate from scratch instead, the full prompt still describes the identical layout.
6. Fix problems with the [iteration prompts](#6-iteration-prompts): **one change per prompt**.
7. When every screen exists, wire the prototype with [section 5](#5-prototype-and-transitions), run it,
   and go through the [review checklist](#7-review-checklist).
8. Export DESIGN.md, the HTML and the PNGs into `mobile-app/design/export/` for the Flutter build.

Screen IDs (`S3-B` etc.) are used as screen names in Stitch, so the prototype table matches them.

---

## 1. Theme and typography (DESIGN.md)

Paste into Stitch's DESIGN.md. This is the single source of truth for every screen.

````markdown
# DESIGN.md: LeafCheck

## Product
LeafCheck is an Android app that diagnoses potato leaf diseases from a photo, directly on the phone,
without internet. It recognises three conditions: Early blight, Late blight and Healthy. When the
phone is online it can also sync past diagnoses, update its model, get a second opinion from a
server, and show treatment advice with cited sources.

Users: smallholder potato farmers and agricultural extension officers. They use the app outdoors, in
bright sun, often with one hand and dirty fingers, on mid-range Android phones with slow or no
internet. Copy is plain and short, at about a 6th-grade reading level. The tone is calm, practical
and honest about uncertainty.

## Canvas rules (apply to every screen)
- Output exactly ONE mobile screen per generation, 412 x 915 px (Android, Material Design 3).
- The screen stands alone: NO device frame, NO phone mockup, NO bezel, NO drop shadow around the
  screen, NO artboard, NO grouping with other screens, NO background canvas colour around it.
- Draw a flat Android status bar (time "10:24", Wi-Fi, signal, battery 76%) and the thin gesture
  navigation handle at the bottom. Nothing else outside the app UI.
- Design only the elements the prompt lists. Do not add sections, cards, banners, badges, avatars,
  promos, ratings or features that are not asked for.

## Visual style
Material Design 3, light theme by default. Calm, clean, utilitarian, like a well-made government or
NGO field tool. Flat tonal surfaces. Generous spacing. Real content, not marketing.

## Colour tokens: light
| Token | Hex | Use |
|---|---|---|
| primary | #2E7D32 | main buttons, active nav, links, focus |
| on-primary | #FFFFFF | text/icons on primary |
| primary-container | #B8F0B0 | selected chips, active nav pill, light emphasis |
| on-primary-container | #002204 | text on primary-container |
| secondary-container | #D5E8CF | tonal buttons, neutral chips |
| on-secondary-container | #101F0F | text on secondary-container |
| surface | #F7FBF2 | screen background |
| surface-container-low | #F1F5EC | cards |
| surface-container | #EBEFE6 | bottom nav bar, sheets |
| surface-container-high | #E6E9E1 | text fields, pressed states |
| on-surface | #181D17 | main text |
| on-surface-variant | #424940 | secondary text, icons |
| outline | #72796F | borders of outlined elements |
| outline-variant | #C2C8BD | dividers, card borders |
| error | #BA1A1A | errors only |
| error-container | #FFDAD6 | error banners |

## Colour tokens: dark
| Token | Hex |
|---|---|
| primary | #9DD49A |
| on-primary | #003909 |
| primary-container | #1B5E20 |
| on-primary-container | #B8F0B0 |
| secondary-container | #3B4B39 |
| surface | #101510 |
| surface-container-low | #181D17 |
| surface-container | #1C211B |
| surface-container-high | #262B25 |
| on-surface | #DFE4DA |
| on-surface-variant | #C2C8BD |
| outline | #8C9388 |
| outline-variant | #424940 |
| error | #FFB4AB |

## Diagnosis colours (semantic, used ONLY for diagnosis status)
Each status ALWAYS appears as icon + label + colour together, never colour alone.
| Status | Main | Container (light) | Text on container | Icon (Material Symbols Rounded) |
|---|---|---|---|---|
| Healthy | #2E7D32 | #DCEFD9 | #0B3D0F | check_circle |
| Early blight | #B26A00 (icon/text) / #F9A825 (bar fill) | #FFF0C7 | #4A3200 | warning |
| Late blight | #B23B1E | #FCE3DC | #5E1607 | coronavirus |
| Uncertain | #5F6B73 | #E6EBEE | #263238 | help |

## Colour rules
- 60% surface, 30% surface containers, 10% primary. One accent colour per screen.
- Diagnosis colours appear only on diagnosis elements (header, confidence bar, history status chip).
- Text contrast meets WCAG AA (4.5:1 body, 3:1 large text). Never put grey text on green.

## Typography
Font: Inter (all text). Numbers that change (percentages, milliseconds, MB, counts) use tabular
figures.
| Role | Size / line height | Weight |
|---|---|---|
| display-small (result title) | 36 / 44 | 600 |
| headline-small (screen titles in content) | 24 / 32 | 600 |
| title-large (top app bar) | 22 / 28 | 500 |
| title-medium (card titles, list primary) | 16 / 24 | 600 |
| body-large (main text) | 16 / 24 | 400 |
| body-medium (secondary text) | 14 / 20 | 400 |
| label-large (buttons) | 14 / 20 | 600, sentence case |
| label-medium (chips, badges) | 12 / 16 | 500 |
Sentence case everywhere. No ALL CAPS except the 2-letter unit labels "MB" and "ms".

## Spacing, shape, elevation
- 4 dp grid: 4, 8, 12, 16, 24, 32. Screen side padding 16. Gap between cards 12. Section gap 24.
- Corner radius: chips 8, text fields 12 (top corners only for filled), cards 16, bottom sheets 28 (top corners), FAB/large button 16, pills/full 999.
- Elevation: tonal surfaces only. Cards are flat with surface-container-low fill, no shadow, or a
  1 px outline-variant border. Bottom sheet and snackbar may use level-2 shadow; nothing else.
- Minimum touch target 48 x 48 dp. Primary buttons 56 dp tall, full width inside 16 dp padding.

## Icons and imagery
- Material Symbols Rounded, weight 400, 24 dp (20 dp inside chips). No other icon style.
- Leaf photos: realistic close-up photographs of real potato leaves (green leaf, or leaf with dark
  brown target-ring spots for early blight, or dark water-soaked lesions with pale borders for late
  blight), natural daylight, slightly imperfect framing like a phone photo taken in a field.
- No illustrations of people, no stock photos of people, no abstract shapes.

## Components (reuse exactly on every screen)
- **Top app bar (small):** surface colour, left-aligned title in title-large, optional back arrow
  (arrow_back) on the left and up to 2 icon buttons on the right. No shadow; 1 px outline-variant
  divider only when content scrolls under it.
- **Bottom navigation bar:** surface-container, 80 dp tall, exactly 3 destinations: "Scan"
  (photo_camera), "History" (history), "Settings" (settings). Active item: primary-container pill
  64 x 32 behind a filled icon, label in on-surface 12/16 weight 600. Inactive: outlined icon,
  on-surface-variant label.
- **Filled button:** primary fill, on-primary label, 56 dp tall, radius 16, optional leading icon.
- **Tonal button:** secondary-container fill, on-secondary-container label, 48 dp tall, radius 16.
- **Text button:** primary label, no fill.
- **Status chip:** 32 dp tall, radius 8, 20 dp leading icon, label-medium. Variants: neutral (outline
  border, surface fill), positive (primary-container), warning (#FFF0C7), error (error-container).
- **Card:** surface-container-low, radius 16, 16 dp padding, optional 1 px outline-variant border.
- **List tile:** 72 dp tall, 56 x 56 thumbnail with radius 12 on the left, title-medium + body-medium,
  trailing element (chip, icon or time).
- **Confidence bar:** 8 dp tall, radius 999, track surface-container-high, fill in the diagnosis
  colour, a 2 dp tall vertical tick in on-surface-variant marking the threshold, value right-aligned
  above the bar in title-medium tabular figures.
- **Banner (offline):** full-width strip under the app bar, 40 dp tall, surface-container-high, icon
  cloud_off + one line of body-medium text + text button "Retry" on the right.
- **Bottom sheet:** surface-container, top corners 28, 32 x 4 drag handle centred 16 dp from the top.
- **Snackbar:** inverse surface (#2D322C) with #EEF2E9 text, radius 8, optional text action.
- **Progress:** linear 4 dp in primary; circular 48 dp, 4 dp stroke.
- **Skeleton:** rounded rectangles in surface-container-high, no shimmer colours other than that.
- **Empty state:** 64 dp outlined icon in on-surface-variant, one headline-small line, one body-medium
  line, one tonal button. Centred, no illustration.

## Motion tokens (for annotations and prototype transitions)
- Durations: short 150 ms, medium 300 ms, long 500 ms.
- Easing: emphasized-decelerate (entering), emphasized-accelerate (leaving), standard (on-screen changes).
- Patterns: fade-through between bottom-nav tabs; container transform from a list tile or card to its
  detail; shared axis X for step-by-step flows; bottom sheets slide up 300 ms; Hero for the leaf photo.
- With "reduce motion" on, all motion is replaced by an instant change or a 150 ms fade.
- Nothing animates while idle except the soft pulse on the Scan button (described on S1).

## Hard rules (to keep it realistic and not "AI-looking")
- NO gradients, glassmorphism, blur panels, neon, glow, lens flares or noise textures.
- NO 3D shapes, blobs, orbs, particles, abstract waves or decorative illustrations.
- NO sparkle, magic wand, robot, brain, circuit or "stars" icons, and no words like "AI-powered",
  "smart", "magic", "intelligent" or "revolutionary" in the UI.
- NO emojis. NO avatars or profile pictures. NO user names or greetings ("Hi John").
- NO cards inside cards. NO more than one filled button per screen.
- NO lorem ipsum. Use the exact text given in each prompt.
- Data must look like real app data: specific numbers, real dates (October 2026), real file sizes.
````

---

## 2. Consistency preamble

This block is already included at the top of every screen prompt below. It's repeated here for
reference.

```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.
```

---

## 3. Component reference screen (optional)

Generate this once, before the app screens, if you want Stitch to see every component together. It is
a reference sheet, not an app screen. Don't link it in the prototype.

```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone tall screen, 412 px wide (height as needed), with no device frame, no mockup and no grouping with other screens.
Make it look like a real design-system reference page: plain, labelled, no decoration.

Screen name: "C0 Component reference". A vertical list of labelled component samples on the surface colour, each sample under a small label-medium caption in on-surface-variant:
1. "Top app bar": title "History", back arrow, one trailing icon button (sync).
2. "Bottom navigation": Scan (active), History, Settings.
3. "Buttons": filled "Scan a leaf" with photo_camera icon; tonal "Get advice"; text button "Retry".
4. "Status chips": neutral "Model v1" (memory icon); positive "Online" (cloud_done); warning "Pending sync" (schedule); error "Rejected" (error).
5. "Diagnosis headers": four rows, each icon + label in its diagnosis colour on its container: "Healthy", "Early blight", "Late blight", "Not sure".
6. "Confidence bar": label "Confidence", value "76.5%", Late blight fill, threshold tick at 50% with caption "Threshold 50%".
7. "List tile": leaf photo thumbnail, title "Late blight", subtitle "Today, 09:12 · On-device", trailing chip "Synced" (cloud_done).
8. "Offline banner": cloud_off icon, "You're offline. Diagnosis still works.", text button "Retry".
9. "Card": title "Model v1", body "9.0 MB · Installed 29 Oct 2026".
10. "Linear progress" at 42% with caption "3.8 of 9.0 MB".
11. "Circular progress" 48 dp.
12. "Skeleton": three text lines of 100%, 92%, 60% width.
13. "Snackbar": "Synced 12 diagnoses" with action "View".
14. "Empty state": history icon, "No diagnoses yet", "Scan a leaf to see it here.", tonal button "Scan a leaf".

Do not include: device frame, phone mockup, gradients, illustrations, avatars, extra components not listed.
```

---

## 4. Screen prompts

Each screen has its states as separate prompts. Generate state **A** first, then the others (ideally on
a duplicate of A, see [How to use](#0-how-to-use) step 5).

### S1 Scan (Home)

The first tab. It gives one obvious action, a quiet status line, and the last three diagnoses.

#### S1-A Scan: online, with history
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S1-A Scan – online". Home screen of a potato leaf diagnosis app. The user wants to photograph a leaf and get a diagnosis in seconds.

Top to bottom:
1. Flat Android status bar.
2. Top app bar: title "LeafCheck" (title-large), no back arrow, one trailing icon button "help" (outlined).
3. Status row (16 dp below app bar), two status chips side by side, left-aligned:
   - neutral chip, icon "memory", text "Model v1"
   - positive chip, icon "cloud_done", text "Online"
4. Main action area, a card (surface-container-low, radius 16) about 300 dp tall, centred content:
   - 72 dp circle in primary-container with a 36 dp "photo_camera" icon in on-primary-container
   - headline-small "Check a potato leaf"
   - body-medium in on-surface-variant: "Works without internet. Fill the frame with one leaf, in daylight."
   - filled button, full width of the card content: icon "photo_camera", label "Scan a leaf"
5. Section header row, 24 dp below: title-medium "Recent" on the left, text button "See all" on the right.
6. Three list tiles (72 dp each, 1 px outline-variant dividers between them):
   - Late-blight leaf photo thumbnail · "Late blight" · "Today, 09:12 · 76.5%" · trailing status chip warning style with icon "schedule" "Pending"
   - Healthy leaf photo · "Healthy" · "Yesterday, 16:40 · 98.1%" · trailing chip positive "cloud_done" "Synced"
   - Early-blight leaf photo · "Early blight" · "27 Oct, 11:05 · 88.4%" · trailing chip positive "Synced"
   Each title is preceded by a 20 dp diagnosis icon in its diagnosis colour (coronavirus / check_circle / warning).
7. Bottom navigation bar: Scan (active), History, Settings.

Motion spec (annotate, do not render as effects):
- The "Scan a leaf" button has a soft pulse: the 72 dp circle scales 1.00 → 1.04 → 1.00 over 2400 ms, standard easing, repeating. Off when reduce motion is on.
- Recent tiles enter with a 40 ms stagger, fade + 8 dp upward slide, 300 ms emphasized-decelerate, only on first load.
- Tapping a tile: container transform into S3 Result, 500 ms.

Do not include: greeting, user name, avatar, weather widget, tips carousel, promotional banner, floating action button, search bar, gradients, illustrations, more than 3 recent items.
```

#### S1-B Scan: offline
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S1-B Scan – offline". Identical layout to "S1-A Scan – online" with exactly these differences:
1. Status bar shows no Wi-Fi icon and an "airplane mode" icon.
2. Directly under the top app bar, the offline banner: icon "cloud_off", text "You're offline. Diagnosis still works.", text button "Retry".
3. The second status chip is neutral style with icon "cloud_off" and text "Offline".
4. In the Recent list, the first two items show the warning chip "schedule" "Pending" and the third shows "Synced".
Everything else (texts, card, button, list, bottom nav) is unchanged.

Motion spec: the banner slides down from under the app bar, 300 ms emphasized-decelerate, and the content below moves down with it; it slides back up 150 ms emphasized-accelerate when back online.

Do not include: error colours, warning dialogs, disabled scan button (scanning works offline), anything not in S1-A.
```

#### S1-C Scan: first run (no history)
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S1-C Scan – first run". Identical to "S1-A Scan – online" except the "Recent" section (header + list) is replaced by a short "How to take a good photo" card (surface-container-low, radius 16, 16 dp padding):
- title-medium "For a good result"
- three rows, each a 24 dp outlined icon in on-surface-variant + body-medium text:
  - "wb_sunny": "Use daylight, avoid strong shadows"
  - "eco": "One leaf, filling most of the frame"
  - "center_focus_strong": "Hold still until the photo is sharp"
Bottom navigation bar unchanged (Scan active).

Motion spec: none beyond the S1-A button pulse.

Do not include: example photos, carousel, illustrations, empty-state art, anything not listed.
```

### S1a Photo source sheet

#### S1a-A Choose photo source
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S1a-A Photo source". The "S1-A Scan – online" screen dimmed with a 32% black scrim, and a modal bottom sheet on top.
Bottom sheet (surface-container, top corners 28, drag handle):
1. title-medium "Add a leaf photo", 24 dp from the top.
2. Two list rows, 56 dp each, leading 24 dp icon in on-surface-variant:
   - "photo_camera" "Take photo"
   - "photo_library" "Choose from gallery"
3. 24 dp bottom padding above the gesture handle.

Motion spec: scrim fades in 150 ms; sheet slides up 300 ms emphasized-decelerate; dismiss slides down 150 ms emphasized-accelerate.

Do not include: cancel button, extra options, file browser, illustrations.
```

### S2 Analyzing

These are two key frames of one animation: a scan line sweeping over the photo while the model runs
(held for at least 600 ms so it's visible on stage).

#### S2-A Analyzing: start
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S2-A Analyzing – start". Full-screen focus moment, no bottom navigation bar.
Top to bottom:
1. Flat status bar.
2. Top app bar: back arrow "close" icon on the left, no title.
3. The leaf photo: a realistic phone photo of a potato leaf with dark, water-soaked brown lesions with pale yellow borders (late blight), in a 380 x 380 square with radius 16, centred, 24 dp below the app bar.
4. Over the photo, near the TOP edge: a horizontal scan line 2 dp tall in primary (#2E7D32) spanning the full photo width, with a 24 dp tall band above it filled with primary at 12% opacity (flat, not a gradient).
5. 32 dp below the photo, centred: body-large "Checking the leaf…" in on-surface.
6. Below it, body-medium in on-surface-variant: "On this phone · no internet needed".
7. A linear progress bar (indeterminate), 4 dp, 200 dp wide, centred, 16 dp below.

Motion spec:
- The scan line moves from the top edge to the bottom edge of the photo in 900 ms, standard easing, and repeats until the result is ready (minimum one full pass, 600 ms hold).
- On completion the photo flies (Hero, 500 ms emphasized-decelerate) to its position in S3 Result.

Do not include: percentages, fake "AI thinking" text, neural network imagery, sparkles, bounding boxes, heat maps, cancel button text, bottom navigation.
```

#### S2-B Analyzing: end
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S2-B Analyzing – end". Identical to "S2-A Analyzing – start" with one difference: the scan line and its 24 dp tinted band are near the BOTTOM edge of the photo instead of the top. Everything else is unchanged.

Motion spec: this is the last key frame of the sweep in S2-A (900 ms top → bottom).

Do not include: anything not in S2-A.
```

### S3 Result

A pushed screen, with no bottom nav. The header colour and icon follow the diagnosis.

#### S3-A Result: late blight (confident)
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S3-A Result – late blight". The diagnosis result. The user wants to know what is wrong and what to do next.
Top to bottom:
1. Flat status bar.
2. Top app bar: back arrow, title "Result", trailing icon button "delete" (outlined).
3. The same late-blight leaf photo as S2, 380 wide x 240 tall, radius 16, centred.
4. Diagnosis header, 16 dp below, left-aligned:
   - a status chip in the Late blight container (#FCE3DC) with 20 dp "coronavirus" icon and text "Late blight" in #5E1607
   - display-small "Late blight" in on-surface
   - body-large in on-surface-variant: "Potato · Phytophthora infestans"
5. Confidence block (card, surface-container-low, radius 16):
   - row: title-medium "Confidence" left, "76.5%" right (title-medium, tabular figures)
   - confidence bar, Late blight fill (#B23B1E) to 76.5%, threshold tick at 50%
   - body-medium in on-surface-variant under the bar: "Above the 50% threshold"
   - divider (outline-variant)
   - two smaller rows (body-medium): "Early blight" "18.9%" and "Healthy" "4.6%", each with a thin 4 dp bar in outline-variant fill
6. Meta row, body-medium in on-surface-variant, single line with 16 dp icons: "memory" "On-device · 1.9 ms · Model v1".
7. Short explanation card (surface-container-low, radius 16):
   - title-medium "What this means"
   - body-medium: "Late blight spreads fast in cool, wet weather and can destroy a field within days. Act today."
8. Buttons pinned to the bottom with 16 dp padding:
   - filled button, full width, icon "chat", label "Get advice"
   - below it, text button centred, icon "cloud_upload", label "Ask the server for a second opinion"

Motion spec:
- Photo arrives by Hero from S2 (500 ms).
- The confidence bar fills from 0 to 76.5% and the number counts up from 0.0% in 500 ms emphasized-decelerate, starting 100 ms after the screen settles.
- The diagnosis chip and title fade in + 8 dp slide up, 300 ms, 60 ms stagger.

Do not include: bottom navigation, share button, rating, chat bubbles, treatment product ads, maps, sparkles, any second filled button.
```

#### S3-B Result: healthy
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S3-B Result – healthy". Identical layout to "S3-A Result – late blight" with these contents:
- Photo: an evenly green, healthy potato leaf.
- Chip: Healthy container (#DCEFD9), icon "check_circle", text "Healthy" in #0B3D0F.
- Title "Healthy"; subtitle "Potato · no disease found".
- Confidence "98.1%", bar fill #2E7D32, caption "Above the 50% threshold"; smaller rows "Early blight" "1.2%", "Late blight" "0.7%".
- Meta: "On-device · 1.9 ms · Model v1".
- Card title "What this means", body: "No signs of early or late blight on this leaf. Keep checking your plants every week."
- Buttons: filled "Get advice" (icon "chat"), text button "Ask the server for a second opinion".

Motion spec: same as S3-A (bar fills to 98.1%).

Do not include: celebration graphics, confetti, badges, anything not in S3-A.
```

#### S3-C Result: early blight
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S3-C Result – early blight". Identical layout to "S3-A Result – late blight" with these contents:
- Photo: a potato leaf with several dark brown spots with concentric target-like rings.
- Chip: Early blight container (#FFF0C7), icon "warning" in #B26A00, text "Early blight" in #4A3200.
- Title "Early blight"; subtitle "Potato · Alternaria solani".
- Confidence "88.4%", bar fill #F9A825, caption "Above the 50% threshold"; smaller rows "Late blight" "9.3%", "Healthy" "2.3%".
- Meta: "On-device · 1.9 ms · Model v1".
- Card body: "A common fungal disease that starts on older, lower leaves. Remove badly affected leaves and keep foliage dry."
- Buttons: filled "Get advice", text button "Ask the server for a second opinion".

Motion spec: same as S3-A (bar fills to 88.4%).

Do not include: anything not in S3-A.
```

#### S3-D Result: uncertain
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S3-D Result – not sure". The model is below its confidence threshold, so the app is honest and asks for a better photo. Same skeleton as S3-A:
1. Status bar; top app bar: back arrow, title "Result", trailing "delete".
2. Photo: a blurry, shadowed field photo of potato foliage with several overlapping leaves.
3. Header: chip in Uncertain container (#E6EBEE), icon "help", text "Not sure" in #263238; display-small "Not sure"; body-large in on-surface-variant: "The photo isn't clear enough for a reliable answer."
4. Confidence card: "Best guess" left, "38.9%" right; bar fill #5F6B73 to 38.9% with threshold tick at 50%; caption "Below the 50% threshold"; smaller rows "Early blight" "38.9%", "Late blight" "31.4%", "Healthy" "29.7%".
5. Tips card (surface-container-low), title-medium "Try again with", three rows with 24 dp outlined icons:
   - "wb_sunny" "Daylight, no harsh shadow"
   - "eco" "One leaf filling the frame"
   - "center_focus_strong" "A sharp, steady photo"
6. Meta row: "On-device · 1.9 ms · Model v1".
7. Bottom: filled button, icon "photo_camera", label "Retake photo"; text button "Ask the server for a second opinion".

Motion spec: bar fills to 38.9% (500 ms); tips card fades in 300 ms after the bar finishes.

Do not include: a disease name as the title, red or error colours, "Get advice" button, alarming wording.
```

#### S3-E Result: second opinion shown
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S3-E Result – second opinion". Identical to "S3-A Result – late blight", scrolled so the photo is 120 dp tall (cropped), with one added card directly below the confidence card:
Card (surface-container-low, radius 16), title-medium "Second opinion", then a two-column comparison, each column with a label-medium caption and a value:
- left column caption "This phone", value "Late blight 76.5%" with 20 dp coronavirus icon, body-medium "1.9 ms"
- right column caption "Server", value "Late blight 81.2%" with 20 dp coronavirus icon, body-medium "312 ms over Wi-Fi"
- footer row: positive status chip "check_circle" "Both agree"
The text button "Ask the server for a second opinion" is removed; the filled "Get advice" button stays.

Motion spec: the card expands from the text button's position (container transform, 300 ms), values count up 300 ms.

Do not include: charts, graphs, server logos, anything not listed.
```

### S4 Advice sheet

A modal bottom sheet opened from Result. Answers come from the server (3–20 s) and come with
citations.

#### S4-A Advice: suggested questions
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S4-A Advice – questions". The "S3-A Result – late blight" screen behind a 32% black scrim; a bottom sheet covering the lower 70% of the screen.
Sheet (surface-container, top radius 28, drag handle):
1. Row: chip in Late blight style "coronavirus" "Late blight" on the left; icon button "close" on the right.
2. headline-small "Ask about late blight".
3. body-medium in on-surface-variant: "Answers come from extension guides and list their sources."
4. Three suggested question rows, each a full-width outlined button-like row (radius 12, 1 px outline-variant, 56 dp, body-large left-aligned, trailing "arrow_forward" icon):
   - "What should I do today?"
   - "How does it spread?"
   - "How do I prevent it next season?"
5. A filled text field pinned to the bottom of the sheet (surface-container-high, radius 12 top corners), placeholder "Type your question", trailing icon button "send" in primary.

Motion spec: sheet slides up 300 ms emphasized-decelerate; question rows stagger in 40 ms apart.

Do not include: chat bubbles yet, avatars, bot icon, typing indicator, sparkles, the word "AI".
```

#### S4-B Advice: loading
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S4-B Advice – loading". Same sheet as "S4-A Advice – questions", now showing the asked question and a loading state:
1. Header row (chip "Late blight" + close) unchanged.
2. The question as a right-aligned block: surface-container-high, radius 16, 12 dp padding, body-large "What should I do today?".
3. Below, left-aligned, a skeleton answer: four lines in surface-container-high, radius 4, widths 100%, 94%, 88%, 52%, 12 dp tall, 8 dp gaps.
4. Under the skeleton, body-medium in on-surface-variant with a 16 dp circular progress: "Looking through the guides… this can take up to 20 seconds".
5. The text field at the bottom, disabled (38% opacity).

Motion spec: skeleton bars pulse opacity 1.0 → 0.5 → 1.0 every 1200 ms, standard easing (no coloured shimmer). Off with reduce motion.

Do not include: typing dots, robot or bot avatar, percentages, anything not listed.
```

#### S4-C Advice: answer with citations
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S4-C Advice – answer". Same sheet as S4-B, expanded to 90% height, with the answer:
1. Header row unchanged; question block unchanged.
2. Answer, left-aligned, plain body-large text (no bubble), with small superscript-style citation markers as 20 x 20 primary-container rounded squares containing "1" or "2" in label-medium:
   "Remove and destroy infected plants and leaves today [1]. Do not leave cull piles near the field [2]. In cool, wet weather, apply a protectant fungicide every 7–10 days and follow the label [1]. Check the rest of the field daily for new spots [1]."
3. title-medium "Sources", then two source rows (56 dp, leading 24 dp "description" icon, title-medium + body-medium, trailing "open_in_new"):
   - "1  Potato late blight" · "UC IPM · ipm.ucanr.edu"
   - "2  Potato late blight: Management" · "UC IPM · ipm.ucanr.edu"
4. A small note row, body-medium on-surface-variant with "info" icon: "Learning notes, not professional advice. Follow local guidance and pesticide labels."
5. Text field at the bottom enabled, placeholder "Ask a follow-up".

Motion spec: answer text fades in by sentence, 60 ms apart, 300 ms each; sources slide up 8 dp + fade 300 ms after the text. Tapping a citation marker scrolls to and briefly highlights (primary-container fill, 600 ms) the matching source row.

Do not include: chat bubbles for the answer, avatar, thumbs up/down, copy/share buttons, sparkles, "AI" wording.
```

#### S4-D Advice: offline
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S4-D Advice – offline". Same sheet as "S4-A Advice – questions" (header row and close button unchanged), content replaced by a centred empty state:
- 64 dp outlined "cloud_off" icon in on-surface-variant
- headline-small "Advice needs internet"
- body-medium on-surface-variant: "Your diagnosis is saved. We'll ask as soon as you're back online."
- tonal button "Ask when online" with leading "schedule" icon
- text button "Read offline notes" (opens the disease library)
No text field.

Motion spec: empty state fades in 300 ms.

Do not include: error red, retry spinners, illustrations, anything not listed.
```

#### S4-E Advice: service unavailable
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S4-E Advice – unavailable". Same as "S4-D Advice – offline" with:
- icon "cloud_off" replaced by "build" (outlined)
- headline-small "Advice is unavailable right now"
- body-medium: "The advice service isn't responding. Try again in a few minutes."
- tonal button "Try again" with "refresh" icon
- caption under it in label-medium on-surface-variant: "Reference: d6720fce"
- text button "Read offline notes"

Motion spec: empty state fades in 300 ms; "Try again" swaps its icon for a 20 dp circular progress while retrying.

Do not include: stack traces, error codes other than the short reference, red full-screen errors.
```

### S5 History

The second tab: the local diagnoses, each with its sync state.

#### S5-A History: list
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S5-A History". The list of diagnoses saved on this phone.
Top to bottom:
1. Status bar; top app bar: title "History", trailing icon button "sync".
2. Sync summary row (16 dp padding): body-medium on-surface-variant with 16 dp "schedule" icon: "2 waiting to sync · Last sync today 08:55".
3. Day header "Today" (label-large, on-surface-variant), then tiles (72 dp, thumbnails 56 x 56 radius 12, dividers):
   - late-blight photo · title with 20 dp coronavirus icon "Late blight" · "09:12 · 76.5% · On-device" · warning chip "schedule" "Pending"
   - blurry photo · "help" icon "Not sure" · "09:10 · 38.9% · On-device" · warning chip "Pending"
4. Day header "Yesterday":
   - healthy photo · "Healthy" · "16:40 · 98.1% · On-device" · positive chip "cloud_done" "Synced"
5. Day header "27 Oct 2026":
   - early-blight photo · "Early blight" · "11:05 · 88.4% · On-device" · positive chip "Synced"
   - late-blight photo · "Late blight" · "10:58 · 91.7% · Server" · positive chip "Synced"
   - healthy photo · "Healthy" · "10:51 · 95.0% · On-device" · error chip "error" "Rejected"
6. Bottom navigation bar: Scan, History (active), Settings.

Motion spec: tiles enter with a 30 ms stagger (fade + 8 dp up, 300 ms) on first open; switching tabs uses fade-through 300 ms; tapping a tile is a container transform into the S3 Result screen (500 ms).

Do not include: search bar, filters, charts, statistics, map, export button, more tiles than listed.
```

#### S5-B History: syncing
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S5-B History – syncing". Identical to "S5-A History" with these differences:
- A Material pull-to-refresh indicator (40 dp circle, surface-container-high, primary arc) 16 dp below the app bar, content pushed down 56 dp.
- Sync summary text: "Syncing 2 diagnoses…".
- The two "Pending" chips show a 16 dp circular progress instead of the schedule icon, text "Syncing".
Everything else unchanged.

Motion spec: when sync finishes each chip morphs (cross-fade 300 ms, standard) from "Syncing" to positive "Synced"; then a snackbar "Synced 2 diagnoses" slides up for 4 s.

Do not include: full-screen loaders, dialogs, anything not in S5-A.
```

#### S5-C History: empty
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S5-C History – empty". Top app bar "History" (no trailing icon) and bottom navigation (History active) exactly as S5-A. Body: centred empty state:
- 64 dp outlined "history" icon in on-surface-variant
- headline-small "No diagnoses yet"
- body-medium on-surface-variant: "Scan a leaf and it will appear here, even without internet."
- tonal button with "photo_camera" icon: "Scan a leaf"

Motion spec: empty state fades in 300 ms; tab switch fade-through 300 ms.

Do not include: illustrations, sample data, tips, anything not listed.
```

#### S5-D History: rejected item detail
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S5-D Result – sync rejected". Identical layout to "S3-B Result – healthy" (healthy leaf, 95.0%, date "27 Oct 2026, 10:51") with one added element directly under the top app bar: a banner (error-container, 16 dp padding, radius 12, inset 16 dp) with "error" icon, title-medium "Couldn't sync this diagnosis", body-medium "The phone's clock was ahead by more than a day. Check the date and time settings.", and a text button "Try again".
The buttons at the bottom stay as in S3-B.

Motion spec: the banner slides down 300 ms emphasized-decelerate; on successful retry it collapses 150 ms and a "Synced" snackbar appears.

Do not include: technical error codes, red full-screen states, anything else new.
```

### S6 Model

Opened from Settings. It shows the on-device model and handles updates safely.

#### S6-A Model: up to date
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S6-A Model – up to date". Pushed from Settings, no bottom navigation.
Top to bottom:
1. Status bar; top app bar: back arrow, title "Diagnosis model".
2. Card (surface-container-low, radius 16):
   - row: 40 dp circle primary-container with "memory" icon; title-medium "Model v1"; positive chip "check_circle" "Active" on the right
   - info rows (body-medium label on-surface-variant left, value on-surface right, tabular figures), 40 dp each with dividers:
     - "Recognises" · "Early blight, Late blight, Healthy"
     - "Size" · "9.0 MB"
     - "Confidence threshold" · "50%"
     - "Installed" · "29 Oct 2026"
     - "Checksum" · "83bb8785…c969b7b" (monospace-looking numerals still in Inter)
3. Status line, body-medium with "cloud_done" icon in primary: "Up to date · checked today 10:20".
4. Tonal button, full width, "refresh" icon: "Check for updates".
5. Text button centred: "Restore built-in model".

Motion spec: tapping "Check for updates" replaces the icon with a 20 dp circular progress for the request; the status line cross-fades 300 ms to the new text.

Do not include: bottom navigation, changelog, ratings, technical graphs, anything not listed.
```

#### S6-B Model: update available
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S6-B Model – update available". Identical to "S6-A Model – up to date" plus one card inserted between the model card and the status line:
Card (primary-container fill, radius 16): title-medium "Model v2 is available" in on-primary-container; body-medium "9.1 MB · Same three conditions · Published 30 Oct 2026"; body-medium "Download on Wi-Fi to save data."; filled button "Download v2" with "download" icon.
The status line reads "Update available · checked today 10:24". The tonal "Check for updates" button is removed (only one action).

Motion spec: the new card expands in from the status line, 300 ms emphasized-decelerate.

Do not include: second filled button, release notes list, anything else.
```

#### S6-C Model: downloading
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S6-C Model – downloading". Identical to "S6-B Model – update available" except the v2 card content becomes:
- title-medium "Downloading model v2"
- 48 dp circular progress at 42% (determinate, primary on surface-container-high track) on the left, and to its right: title-medium "42%" (tabular) and body-medium "3.8 of 9.1 MB · about 20 s left"
- text button "Cancel"
Status line: "Model v1 stays active until v2 is checked."

Motion spec: progress ring and numbers update continuously; the download resumes where it stopped if the connection drops.

Do not include: anything not listed.
```

#### S6-D Model: installed
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S6-D Model – installed". Identical to "S6-A Model – up to date" but showing v2: title "Model v2", "Size" "9.1 MB", "Installed" "30 Oct 2026", checksum "5f0c2a91…8e14d2a0". Status line: "Checked and installed · v1 kept as backup". Text button "Go back to v1" replaces "Restore built-in model".
A snackbar at the bottom: "Model v2 is ready" with action "Undo".

Motion spec: in the downloading card the progress ring completes and morphs into a 48 dp "check_circle" icon (300 ms), then the card collapses into this layout (300 ms).

Do not include: confetti, celebratory graphics.
```

#### S6-E Model: checksum failed
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S6-E Model – check failed". Identical to "S6-A Model – up to date" (v1 active) with a card inserted under the model card: error-container fill, radius 16, "gpp_bad" icon, title-medium "Download didn't pass the safety check", body-medium "The file was damaged or changed, so it was deleted. Model v1 is still active.", tonal button "Try again".

Motion spec: the downloading card cross-fades (300 ms) into this error card; no shake or flashing.

Do not include: technical hashes in the message, red full-screen error.
```

### S7 Settings and Diagnostics

#### S7-A Settings
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S7-A Settings". Third tab.
Top to bottom:
1. Status bar; top app bar: title "Settings".
2. Section label "Diagnosis" (label-large, primary), then list rows (56–72 dp, leading 24 dp outlined icon, trailing "chevron_right"):
   - "memory" · "Diagnosis model" · "v1 · up to date"
3. Section label "Server":
   - "dns" · "Server address" · "http://10.0.2.2:8080 · Android emulator"
   - "key" · "Access key" · "•••••••• set"
   - "monitor_heart" · "Diagnostics" · "All services working"
4. Section label "Display":
   - "dark_mode" · "Theme" · trailing segmented button with 3 segments "Light" (selected) "Dark" "System"
   - "motion_photos_off" · "Reduce motion" · trailing switch (off)
5. Section label "About":
   - "smartphone" · "Device ID" · "a3f1c2d4-…-9b7e"
   - "info" · "Version" · "1.0.0 (1)"
6. Bottom navigation bar: Scan, History, Settings (active).

Motion spec: tab switch fade-through 300 ms; tapping a row opens its page with shared axis X (300 ms).

Do not include: account, login, profile picture, notifications settings, language picker, premium/upgrade rows.
```

#### S7-B Diagnostics
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S7-B Diagnostics". Pushed from Settings, no bottom navigation.
1. Status bar; top app bar: back arrow, title "Diagnostics", trailing icon button "refresh".
2. Card "Services" (title-medium), rows 48 dp each: 10 dp status dot (primary for OK, #BA1A1A for down) + body-large name + trailing body-medium value on-surface-variant (tabular):
   - "Server" · "OK · 24 ms"
   - "Database" · "OK"
   - "Diagnosis service" · "OK"
   - "Advice service" · "Down" (dot in error colour, value in error colour)
   - caption: "Checked 10:24 · http://10.0.2.2:8080"
3. Card "Sync": rows "Waiting to sync" "2", "Last sync" "Today 08:55", "Synced in total" "148".
4. Card "This phone": rows "Model" "v1 · 9.0 MB", "Inference (last)" "1.9 ms", "Phone" "Pixel 7a · Android 16".
5. Tonal button full width "speed" icon "Run speed test" (opens S7-C).

Motion spec: refresh rotates the icon 360° in 500 ms while rows cross-fade to new values (150 ms).

Do not include: logs, charts, raw JSON, anything not listed.
```

#### S7-C Speed test results
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S7-C Speed test". Pushed from Diagnostics, no bottom navigation.
1. Status bar; top app bar: back arrow, title "Speed test".
2. body-medium on-surface-variant: "100 diagnoses of the same photo on this phone, no internet."
3. Two large stat blocks side by side (cards, surface-container-low, radius 16), each: label-medium caption + display-small value (tabular) + body-medium unit:
   - "Typical (p50)" · "1.9" · "ms"
   - "Slow (p95)" · "1.9" · "ms"
4. Card "Compared with the server" (title-medium), rows body-medium with values right-aligned (tabular):
   - "This phone" · "1.9 ms"
   - "Server over Wi-Fi" · "≈ 1.3 s"
   - "Server over 3G" · "≈ 34 s"
   - caption: "Server times include uploading a 3 MB photo (estimated)."
5. Filled button "Run again" with "replay" icon.

Motion spec: while running, a linear progress shows "Run 37 of 100"; values count up 500 ms when done.

Do not include: charts, leaderboards, share button, anything not listed.
```

### S8 Onboarding (later)

Three pages using shared axis X, shown on first launch.

#### S8-A Onboarding: works offline
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S8-A Onboarding 1". No app bar, no bottom navigation.
1. Status bar; text button "Skip" top-right.
2. A real photograph of a potato field row in daylight, full width, 420 dp tall, no people, bottom corners square.
3. 32 dp below: headline-small "Works in the field, without internet".
4. body-large on-surface-variant: "Diagnosis happens on your phone. Results are saved and synced later."
5. Page indicator: 3 dots, first active (primary, 24 x 8 pill), others 8 dp outline-variant.
6. Filled button "Next" pinned 16 dp above the gesture bar.

Motion spec: pages move with shared axis X, 300 ms; the indicator pill slides between dots.

Do not include: illustrations, people, phone mockups, icons over the photo.
```

#### S8-B Onboarding: how to photograph
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S8-B Onboarding 2". Same layout as "S8-A Onboarding 1" with:
- Photo area replaced by two real leaf photos side by side (each 180 x 240, radius 16): left a sharp, well-lit single potato leaf with a small primary-container chip "check" "Good"; right a blurry, shadowed bunch of leaves with an error-container chip "close" "Hard to read".
- headline-small "One leaf, daylight, steady"
- body-large: "Fill the frame with one leaf. Avoid shadows and blur."
- dots: second active. Button "Next".

Motion spec: same shared axis X (300 ms) as S8-A; indicator pill slides to the second dot.

Do not include: illustrations, arrows, extra tips.
```

#### S8-C Onboarding: privacy
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S8-C Onboarding 3". Same layout as "S8-A Onboarding 1" with:
- Photo area replaced by a surface-container-low card 420 dp tall containing three rows with 32 dp outlined icons in primary and body-large text:
  - "photo_camera": "Photos stay on your phone"
  - "cloud_upload": "Only the result is synced, never the photo"
  - "person_off": "No account needed"
- headline-small "Your photos stay with you"
- body-large: "You can change the server in Settings at any time."
- dots: third active. Filled button "Start scanning" (no "Skip").

Motion spec: same shared axis X as S8-A; "Start scanning" leads to S1-C with fade-through 300 ms.

Do not include: legal text blocks, checkboxes, illustrations.
```

### S9 Disease library (later)

#### S9-A Disease library: list
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S9-A Disease library". Pushed from the help icon or "Read offline notes", no bottom navigation.
1. Status bar; top app bar: back arrow, title "Potato diseases".
2. body-medium on-surface-variant: "Available offline. Summaries of public extension guides."
3. Three cards (radius 16, surface-container-low), each: 120 dp tall real leaf photo across the top (top corners 16), then 16 dp padding with the diagnosis chip, title-medium name, body-medium one-line summary, trailing "chevron_right":
   - Late blight chip · "Late blight" · "Spreads fast in cool, wet weather. Act the same day."
   - Early blight chip · "Early blight" · "Target-like brown spots on older leaves."
   - Healthy chip · "Healthy leaf" · "What a healthy potato leaf looks like."

Motion spec: tapping a card is a container transform into S9-B, 500 ms.

Do not include: search, other crops, bookmarks, ratings.
```

#### S9-B Disease library: late blight detail
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Keep the top app bar, bottom navigation bar, side padding (16 dp) and card style identical to the other screens in this project.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S9-B Late blight". Article-style detail, no bottom navigation.
1. Status bar; top app bar over the photo: back arrow on a 40 dp surface circle.
2. Real photo of a late-blight potato leaf, full width, 260 dp tall.
3. Late blight chip; display-small "Late blight"; body-large on-surface-variant "Phytophthora infestans · a water mould".
4. Sections, each title-medium heading + body-large text, 24 dp apart:
   - "Signs": "Pale to dark green, water-soaked spots that quickly turn brown to purple-black, often with a yellow border. White growth under leaves in humid weather."
   - "When it spreads": "Cool, wet weather. It can destroy a field within days."
   - "What to do": three bullet rows: "Remove and destroy infected plants", "Don't leave cull piles near the field", "Use a protectant fungicide in risky weather and follow the label"
5. Source row: "description" icon · "UC IPM · Potato late blight" · "open_in_new".

Motion spec: photo collapses under the app bar on scroll (parallax 0.5); app bar gets a surface fill after 200 dp.

Do not include: ads, product recommendations, comments, share.
```

### S10 Splash (later)

#### S10-A Splash
```text
Use the project's DESIGN.md exactly: same colours, Inter type scale, spacing, radius, icons and components.
Design ONLY the elements listed below, in the order listed, with the exact text given. Do not add anything else.
Output ONE standalone Android screen, 412 x 915, with no device frame, no mockup, no shadow around it and no grouping with other screens.
Make it look like a real, shipped, utilitarian app: no gradients, no glow, no decorative illustrations, no AI or sparkle imagery.

Screen name: "S10-A Splash". Android 12+ style splash: surface (#F7FBF2) background; centred 96 dp app icon = a primary-container (#B8F0B0) rounded square (radius 28) with a single simple leaf mark in #2E7D32 (Material Symbols "eco", filled); nothing else except the flat status bar. Bottom: body-medium on-surface-variant "LeafCheck", 48 dp above the gesture bar.

Motion spec: the icon fades + scales 0.9 → 1.0 in 300 ms; the splash leaves with a 150 ms fade when the model is loaded.

Do not include: taglines, loading bars, illustrations, gradients.
```

### Dark mode variants

Run on a **duplicate** of each key screen: S1-A, S3-A, S3-D, S4-C, S5-A, S6-C, S7-A.

```text
Convert this screen to the DARK colour tokens from DESIGN.md. Keep the layout, text, photos, spacing, components and diagnosis meaning exactly the same.
Use surface #101510 for the background, surface-container tokens for cards, sheets and the bottom bar, and the dark primary #9DD49A.
Diagnosis containers become darker versions of the same hue with light text (Late blight container #5E1607 with #FCE3DC text; Early blight #4A3200 with #FFF0C7; Healthy #0B3D0F with #DCEFD9; Uncertain #263238 with #E6EBEE). Keep WCAG AA contrast.
Rename the screen with the suffix " – dark". One standalone screen, no device frame, no grouping.
Do not include: glow, neon, gradients, pure black #000000 backgrounds, any new element.
```

---

## 5. Prototype and transitions

Wire these in Stitch's **Prototype** mode after all screens exist. The "Flutter" column is how the app
implements them (`ARCHITECTURE.md` §11).

| From (hotspot) | To | Stitch transition | Flutter motion |
|---|---|---|---|
| S1-A "Scan a leaf" | S1a-A | Slide up (bottom sheet) | Modal bottom sheet, 300 ms emphasized-decelerate |
| S1a-A "Take photo" | S2-A | Fade | Fade 150 ms |
| S2-A | S2-B | Smart animate / dissolve (auto, 900 ms) | Scan-line sweep loop |
| S2-B | S3-A | Smart animate (photo Hero) | Hero 500 ms |
| S3-A "Get advice" | S4-A | Slide up | Bottom sheet 300 ms |
| S4-A question row | S4-B | Dissolve | Cross-fade 150 ms |
| S4-B | S4-C | Dissolve (auto, 3 s) | Staggered text reveal |
| S3-A "Ask the server…" | S3-E | Smart animate | Container transform 300 ms |
| S1-A recent tile / S5-A tile | S3-x | Smart animate (expand) | Container transform 500 ms |
| Bottom nav items | S1-A / S5-A / S7-A | Dissolve | Fade-through 300 ms |
| S5-A sync icon | S5-B | Dissolve | Pull-to-refresh + chip morph |
| S7-A "Diagnosis model" | S6-A | Push left | Shared axis X 300 ms |
| S6-A "Check for updates" | S6-B | Dissolve | Cross-fade 300 ms |
| S6-B "Download v2" | S6-C | Dissolve | Progress ring |
| S6-C | S6-D | Dissolve (auto) | Ring → check morph 300 ms |
| S7-A "Diagnostics" | S7-B | Push left | Shared axis X 300 ms |
| S7-B "Run speed test" | S7-C | Push left | Shared axis X 300 ms |
| S8-A "Next" → S8-B → S8-C | next page | Push left | Shared axis X 300 ms |
| S8-C "Start scanning" | S1-C | Dissolve | Fade-through 300 ms |
| S4-C "Read offline notes" (S4-D) | S9-A | Push left | Shared axis X 300 ms |
| S9-A card | S9-B | Smart animate (expand) | Container transform 500 ms |

---

## 6. Iteration prompts

Select the screen(s) first. One change per prompt.

| Problem | Prompt |
|---|---|
| Inconsistent nav | `Make the bottom navigation bar on this screen identical to the one on "S1-A Scan – online" (height, colours, icons, labels, active pill). Change nothing else.` |
| Too much decoration | `Remove every element that is not in the original prompt for this screen (extra cards, badges, illustrations, banners). Keep the remaining layout, colours and text unchanged.` |
| AI look | `Remove all gradients, glows, blur and sparkle or AI imagery. Use flat DESIGN.md surface colours instead. Change nothing else.` |
| Small targets | `Make every tappable element at least 48 x 48 dp and primary buttons 56 dp tall. Keep the visual style and layout otherwise unchanged.` |
| Fake imagery | `Replace the image with a realistic close-up phone photograph of a real potato leaf in daylight, slightly imperfect framing. Keep its size and position.` |
| Contrast | `Increase text contrast to meet WCAG AA (4.5:1 for body text) using only DESIGN.md tokens. Keep layout unchanged.` |
| Numbers jump | `Use tabular (fixed-width) figures for every percentage, time and size on this screen. Change nothing else.` |
| Wrong font | `Set every text element to Inter using the DESIGN.md type scale. Change nothing else.` |
| Framed output | `Remove the device frame, mockup, shadow and background canvas. Output only the 412 x 915 app screen itself.` |
| Grouped screens | `Split this into separate standalone screens, one per state, each 412 x 915 with no frame and no grouping.` |
| Lorem ipsum | `Replace placeholder text with the exact text from the prompt. No lorem ipsum.` |
| Colour as only signal | `Make sure every diagnosis status shows its icon and its label next to the colour.` |

---

## 7. Review checklist

Go through every screen before exporting:

- [ ] Colours, font, radius and spacing match DESIGN.md. No off-palette colours.
- [ ] Top app bar and bottom navigation are pixel-identical across tabs. Pushed screens have no bottom nav.
- [ ] Only listed elements exist; the text matches the prompt exactly; no lorem ipsum.
- [ ] No gradients, glow, blobs, sparkles, robots, emojis, avatars or "AI" wording.
- [ ] Every diagnosis shows icon + label + colour; numbers use tabular figures.
- [ ] Touch targets ≥ 48 dp; primary buttons 56 dp; at most one filled button per screen.
- [ ] Each screen is standalone, 412 × 915, unframed and ungrouped.
- [ ] All states exist: S1 A–C, S1a, S2 A–B, S3 A–E, S4 A–E, S5 A–D, S6 A–E, S7 A–C, S8 A–C, S9 A–B, S10, plus 7 dark variants.
- [ ] The prototype plays: Scan → Analyzing → Result → Advice, History → Result, Settings → Model → update.
- [ ] Export DESIGN.md + HTML + PNGs to `mobile-app/design/export/`.

When this is done, the Flutter build (F0+) uses `export/DESIGN.md` for its theme tokens and the PNGs as
widget-test references.
