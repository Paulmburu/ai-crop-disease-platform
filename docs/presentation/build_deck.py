"""Builds docs/presentation/LeafCheck_FlutterconKE.pptx from PRESENTATION_SLIDES.md.

Style: SlidesCarnival "Minimal Scientific Conference" (white / mint / dark green, Gothic A1 Light
titles under a thin rule). Screenshots come from the 3x golden render:

    cd mobile-app && flutter test --update-goldens --dart-define=SHOT_DPR=3 \
        --dart-define=SHOT_DIR=$PWD/../docs/presentation/screens/

Run:  python3 -m venv /tmp/pptvenv && /tmp/pptvenv/bin/pip install python-pptx pillow
      /tmp/pptvenv/bin/python docs/presentation/build_deck.py
Fonts: Gothic A1 and JetBrains Mono (Google Fonts, OFL) must be installed on the presenting machine.
"""

from pathlib import Path

from lxml import etree
from PIL import Image
from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import MSO_ANCHOR, PP_ALIGN
from pptx.util import Inches, Pt

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SCREENS = HERE / "screens"
CACHE = Path("/tmp/leafcheck_deck_cache")
OUT = HERE / "LeafCheck_FlutterconKE.pptx"

WHITE, MINT, SAGE, DARK = "FFFFFF", "EAF5F1", "ADCCAD", "466546"
INK, MUTED, ON_DARK, ON_DARK_MUTED = "2F3B2F", "6B7A6B", "FFFFFF", "CFE0CF"
LEAF, EARLY, LATE, PALE_LATE, PALE_LEAF = "2E7D32", "B26A00", "B23B1E", "FCE3DC", "DDEEDD"
TITLE_FONT, BODY_FONT, MONO = "Gothic A1 Light", "Gothic A1", "JetBrains Mono"
PAUL, TITUS, BOTH = "Paul Mburu", "Titus Kariuki", "Paul & Titus"

prs = Presentation()
prs.slide_width, prs.slide_height = Inches(13.333), Inches(7.5)
BLANK = prs.slide_layouts[6]


def rgb(hex_):
    return RGBColor.from_string(hex_)


# ── primitives ────────────────────────────────────────────────────────────
def new_slide(bg=WHITE, speaker=None, notes=""):
    s = prs.slides.add_slide(BLANK)
    s.background.fill.solid()
    s.background.fill.fore_color.rgb = rgb(bg)
    n = len(prs.slides)
    fg = ON_DARK_MUTED if bg == DARK else MUTED
    if n > 1:
        text(s, 12.2, 7.0, 0.8, 0.3, f"{n:02d}", 11, fg, align=PP_ALIGN.RIGHT)
    if speaker:
        text(s, 0.7, 7.0, 4, 0.3, speaker, 11, fg)
    if notes:
        s.notes_slide.notes_text_frame.text = notes
    return s


def rect(s, x, y, w, h, fill, line=None, shape=MSO_SHAPE.RECTANGLE):
    r = s.shapes.add_shape(shape, Inches(x), Inches(y), Inches(w), Inches(h))
    r.fill.solid()
    r.fill.fore_color.rgb = rgb(fill)
    if line:
        r.line.color.rgb = rgb(line)
        r.line.width = Pt(1)
    else:
        r.line.fill.background()
    # Flat like the template: drop the theme style (it adds a shadow in some renderers).
    style = r._element.find("{http://schemas.openxmlformats.org/presentationml/2006/main}style")
    if style is not None:
        r._element.remove(style)
    return r


def rule(s, x, y, w=1.6, color=DARK):
    rect(s, x, y, w, 0.02, color)


def text(s, x, y, w, h, paras, size=18, color=INK, font=BODY_FONT, align=PP_ALIGN.LEFT,
         anchor=MSO_ANCHOR.TOP, spacing=1.15, bold=False):
    """paras: str, or list of paragraphs; a paragraph is str or list of (text, overrides)."""
    tb = s.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = tb.text_frame
    tf.word_wrap = True
    tf.vertical_anchor = anchor
    for side in ("left", "right", "top", "bottom"):
        setattr(tf, f"margin_{side}", 0)
    for i, para in enumerate([paras] if isinstance(paras, str) else paras):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = align
        p.line_spacing = spacing
        for run_text, o in [(para, {})] if isinstance(para, str) else para:
            r = p.add_run()
            r.text = run_text
            f = r.font
            f.name = o.get("font", font)
            f.size = Pt(o.get("size", size))
            f.bold = o.get("bold", bold)
            f.italic = o.get("italic", False)
            f.color.rgb = rgb(o.get("color", color))
    return tb


def title(s, t, x=0.7, y=0.6, w=11.9, size=40, color=DARK, sub=None):
    rule(s, x, y, 1.6, color if color != DARK else DARK)
    text(s, x, y + 0.15, w, 1.0, t, size, color, TITLE_FONT)
    if sub:
        text(s, x, y + 0.95, w, 0.5, sub, 16, ON_DARK_MUTED if color == ON_DARK else MUTED)


def screen(name, crop=None):
    """3x golden, scaled to 1800 px tall (sharp on a 4K projector, small file)."""
    src = SCREENS / f"{name}.png"
    dst = CACHE / f"{name.replace('/', '_')}{'_' + '_'.join(map(str, crop)) if crop else ''}.png"
    if not dst.exists():
        dst.parent.mkdir(parents=True, exist_ok=True)
        im = Image.open(src).convert("RGB")
        if crop:
            im = im.crop(crop)
        if im.height > 1800:
            im = im.resize((round(im.width * 1800 / im.height), 1800), Image.LANCZOS)
        im.save(dst, optimize=True)
    return dst


def round_corners(pic, radius_pct):
    pic.auto_shape_type = MSO_SHAPE.ROUNDED_RECTANGLE
    geom = pic._element.spPr.find("{http://schemas.openxmlformats.org/drawingml/2006/main}prstGeom")
    av = geom.find("{http://schemas.openxmlformats.org/drawingml/2006/main}avLst")
    gd = etree.SubElement(av, "{http://schemas.openxmlformats.org/drawingml/2006/main}gd")
    gd.set("name", "adj")
    gd.set("fmla", f"val {radius_pct * 1000}")


def phone(s, name, x, y, h, caption=None, cap_color=MUTED, crop=None):
    path = screen(name, crop)
    w_px, h_px = Image.open(path).size
    w = h * w_px / h_px
    pic = s.shapes.add_picture(str(path), Inches(x), Inches(y), Inches(w), Inches(h))
    round_corners(pic, 4)
    pic.line.color.rgb = rgb("C9D9C9")
    pic.line.width = Pt(0.75)
    if caption:
        text(s, x - 0.3, y + h + 0.1, w + 0.6, 0.4, caption, 13, cap_color, align=PP_ALIGN.CENTER)
    return w


def phones(s, names, y, h, x0=None, gap=0.45, captions=None, x_end=13.333, cap_color=MUTED):
    """Lays out phones centred between x0 and x_end."""
    w = h * 412 / 915
    total = len(names) * w + (len(names) - 1) * gap
    x0 = 0 if x0 is None else x0
    x = x0 + ((x_end - x0) - total) / 2
    for i, n in enumerate(names):
        phone(s, n, x, y, h, captions[i] if captions else None, cap_color)
        x += w + gap


def image(s, path, x, y, w=None, h=None):
    return s.shapes.add_picture(str(path), Inches(x), Inches(y),
                                Inches(w) if w else None, Inches(h) if h else None)


def cover(s, path, x, y, w, h):
    """Picture filling the box without distortion (centre crop, like CSS cover)."""
    iw, ih = Image.open(path).size
    pic = image(s, path, x, y, w, h)
    excess = 1 - (w / h) / (iw / ih)
    if excess > 0:
        pic.crop_left = pic.crop_right = excess / 2
    else:
        excess = 1 - (iw / ih) / (w / h)
        pic.crop_top = pic.crop_bottom = excess / 2
    return pic


def numbox(s, x, y, w, h, big, label, sub=None, fill=MINT, color=DARK, big_size=48):
    rect(s, x, y, w, h, fill)
    text(s, x, y + 0.2, w, h * 0.55, big, big_size, color, TITLE_FONT, PP_ALIGN.CENTER,
         MSO_ANCHOR.MIDDLE)
    text(s, x + 0.1, y + h * 0.62, w - 0.2, 0.35, label, 16, INK, align=PP_ALIGN.CENTER)
    if sub:
        text(s, x + 0.1, y + h * 0.62 + 0.33, w - 0.2, 0.3, sub, 12, MUTED, align=PP_ALIGN.CENTER)


def code(s, x, y, w, h, src, size=14):
    rect(s, x, y, w, h, "F3F8F5")
    rect(s, x, y, 0.05, h, SAGE)
    text(s, x + 0.3, y + 0.2, w - 0.45, h - 0.3, src.split("\n"), size, "24312A", MONO,
         spacing=1.25)


def node(s, x, y, w, h, label, sub=None, fill=WHITE, line=SAGE, color=DARK, size=16):
    rect(s, x, y, w, h, fill, line, MSO_SHAPE.ROUNDED_RECTANGLE).adjustments[0] = 0.1
    paras = [[(label, {"size": size, "color": color})]]
    if sub:
        paras.append([(sub, {"size": 11, "color": ON_DARK_MUTED if fill == DARK else MUTED})])
    text(s, x + 0.1, y, w - 0.2, h, paras, align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)


def arrow(s, x, y, w=0.5, color=SAGE, down=False):
    shape = MSO_SHAPE.DOWN_ARROW if down else MSO_SHAPE.RIGHT_ARROW
    a = rect(s, x, y, 0.3 if down else w, w if down else 0.3, color, shape=shape)
    return a


def bullets(s, x, y, w, items, size=19, color=INK, gap=0.12):
    paras = []
    for it in items:
        paras.append([(it, {})] if isinstance(it, str) else it)
    tb = text(s, x, y, w, 4.5, paras, size, color, spacing=1.2)
    for p in tb.text_frame.paragraphs:
        p.space_after = Pt(size * gap * 5)
    return tb


B = {"bold": True}

# ══ Act 1: Why on-device (Paul) ══════════════════════════════════════════
s = new_slide(WHITE, notes="Welcome. Two of us: Paul (on-device AI) then Titus (offline-first, backend). "
              "One app, LeafCheck: diagnoses potato leaves with no internet.")
text(s, 0.7, 0.45, 11, 0.3, "FlutterconKE · Flutter AI / Mobile · Advanced · 40 min", 13, MUTED)
text(s, 0.7, 0.8, 12, 1.4, ["Beyond the API Call: On-Device AI in Flutter",
                           "with LiteRT and Offline-First Architecture"], 38, DARK, TITLE_FONT,
     spacing=1.05)
cover(s, ROOT / "mobile-app/assets/images/field_rows.jpg", 0.7, 2.35, 11.93, 3.0)
for i, (who, role) in enumerate([(PAUL, "Mobile Engineer, Pezesha · @paulnm"),
                                 (TITUS, "Mobile Developer, Volane International")]):
    x = 0.7 + i * 4.2
    rule(s, x, 5.75, 1.0)
    text(s, x, 5.9, 4, 0.4, who, 20, INK)
    text(s, x, 6.3, 4, 0.3, role, 13, MUTED)
image(s, ROOT / "mobile-app/assets/splash/splash_icon.png", 11.6, 5.6, h=1.05)

s = new_slide(WHITE, PAUL, "Late blight caused the Irish famine; in cool, wet weather it destroys a "
              "field within days. The farmer is in the field, and the field often has no signal.")
cover(s, ROOT / "mobile-app/assets/images/field_rows.jpg", 6.67, 0, 6.67, 7.5)
title(s, "A leaf and no signal", w=5.6)
text(s, 0.7, 2.2, 5.4, 3, [
    "Late blight can destroy a potato field within days in cool, wet weather.",
    "",
    "The person holding the leaf is in that field, where the signal is weakest.",
], 22, INK, spacing=1.25)
text(s, 0.7, 6.3, 5.4, 0.4, "Source: rag-service/knowledge/potato_late_blight.md", 11, MUTED)

s = new_slide(WHITE, PAUL, "Same 3 MB photo. On the phone: 1.9 ms. Through a backend: upload + round "
              "trip. Network times are modelled from stated profiles, not measured on a phone — say so.")
title(s, "The cost of the API call", sub="One 3 MB leaf photo to a backend vs. the same model on the phone")
for i, (big, lab, sub, fill, col) in enumerate([
        ("1.9 ms", "On the phone", "LiteRT, p50", PALE_LEAF, LEAF),
        ("1.3 s", "Wi-Fi", "upload + RTT", MINT, DARK),
        ("34 s", "3G", "upload + RTT", MINT, DARK),
        ("4 min", "2G (EDGE)", "upload + RTT", MINT, DARK)]):
    numbox(s, 0.7 + i * 3.03, 2.6, 2.8, 2.3, big, lab, sub, fill, col, 54)
text(s, 0.7, 5.4, 11, 0.4, "Network times modelled from stated profiles · benchmarks/results.md D2, D3",
     13, MUTED)

# ══ Act 2: Where the model comes from (Paul) ═════════════════════════════
s = new_slide(MINT, PAUL, "2,152 potato images; healthy is the minority (152, 6.6x fewer). MobileNetV2 "
              "with a frozen base trains in about 40 s. 95.8% accuracy, macro F1 0.945 on 216 test images.")
title(s, "Data → model")
for i, plot in enumerate(["class_distribution", "confusion_matrix"]):
    path = ROOT / f"ml-training/outputs/plots/{plot}.png"
    iw, ih = Image.open(path).size
    w, h = (4.5, 4.5 * ih / iw) if iw / ih > 4.5 / 3.6 else (3.6 * iw / ih, 3.6)
    image(s, path, 0.7 + i * 4.7, 1.9, w, h)
for i, (big, lab) in enumerate([("2,152", "images (healthy: 152)"), ("95.8%", "test accuracy"),
                                ("0.945", "macro F1")]):
    numbox(s, 10.15, 1.9 + i * 1.32, 2.5, 1.22, big, lab, fill=WHITE, big_size=28)
text(s, 0.7, 5.9, 11, 0.4, "MobileNetV2, frozen base, ~40 s to train · ml-training/outputs/eval_summary.json",
     13, MUTED)

s = new_slide(WHITE, PAUL, "python-ml-service serves the PyTorch model on /api/v1/predict and exports "
              ".tflite. The .json beside it is the contract the app reads: labels, threshold, input shape. "
              "Nothing about the model is hardcoded in Dart.")
title(s, "One model, two runtimes")
node(s, 0.7, 2.6, 2.3, 1.1, "PyTorch .pt", "MobileNetV2 v1", MINT)
arrow(s, 3.15, 3.0)
node(s, 3.8, 2.0, 2.6, 1.0, "python-ml-service", "/api/v1/predict", MINT)
node(s, 3.8, 3.3, 2.6, 1.0, "export_tflite.py", "matches PyTorch to 8e-7", MINT)
arrow(s, 6.55, 3.65)
node(s, 7.2, 3.0, 2.4, 0.8, "crop_disease_v1.tflite", "9.0 MB · [1,224,224,3] → [1,3]", WHITE, size=14)
node(s, 7.2, 3.95, 2.4, 0.8, "crop_disease_v1.json", "labels · threshold · shape", WHITE, size=14)
arrow(s, 9.75, 3.65)
phone(s, "s6_a_model_up_to_date", 10.5, 1.6, 4.9)
code(s, 0.7, 4.95, 6.0, 1.75, '{ "input_shape": [1, 224, 224, 3],\n  "input_layout": "NHWC",\n'
     '  "class_names": ["…Early_blight", "…Late_blight", "…healthy"],\n  "confidence_threshold": 0.5 }',
     12)

# ══ Act 3a: On-device AI in Flutter (Paul) ═══════════════════════════════
s = new_slide(WHITE, PAUL, "The app: scan offline, see the result, keep a history, control settings.")
title(s, "The app at a glance")
phones(s, ["s1_a_scan_online", "s3_a_result_late_blight", "s5_a_history_1", "s7_a_settings"], 1.75, 5.0,
       captions=["Scan", "Result", "History", "Settings"])

s = new_slide(MINT, PAUL, "flutter_litert sits behind a Classifier port. Domain is pure Dart; "
              "presentation reads use cases only; providers.dart is the single wiring point; "
              "an architecture test fails the build if a layer imports the wrong thing.")
title(s, "Clean layers in Flutter")
node(s, 0.7, 2.0, 2.6, 0.9, "presentation", "pages · notifiers")
node(s, 0.7, 4.3, 2.6, 0.9, "infrastructure", "flutter_litert · Hive · Dio")
arrow(s, 3.45, 2.3)
arrow(s, 3.45, 4.6)
node(s, 4.1, 3.15, 2.6, 0.9, "application", "use cases · ports", DARK, DARK, ON_DARK)
arrow(s, 6.85, 3.45)
node(s, 7.5, 3.15, 1.9, 0.9, "domain", "pure Dart")
text(s, 0.7, 5.6, 8.7, 0.8, "test/architecture_test.dart enforces the arrows · mocks today, real adapters "
     "in F1 behind the same ports", 13, MUTED)
code(s, 9.6, 1.95, 3.3, 3.4, "// app/di/providers.dart\nfinal classifierProvider =\n"
     "  Provider<Classifier>(…);\n\nfinal diagnoseLeafProvider =\n  Provider((ref) =>\n"
     "    DiagnoseLeaf(\n      classifier: ref.watch(\n        classifierProvider),\n"
     "      …));", 10.5)

s = new_slide(WHITE, PAUL, "Pick a photo, then inference runs in an isolate. The result is saved before "
              "it is shown. The scan line is held at least 600 ms so the user can read it.")
title(s, "Capture → analyze")
phones(s, ["s1a_a_photo_source", "s2_a_analyzing_start", "s2_b_analyzing_end"], 1.75, 5.0, gap=0.9,
       captions=["Photo source", "Inference in an isolate", "Saved, then shown (≥ 600 ms)"])

s = new_slide(MINT, PAUL, "Same model, same photos. Forget the divide by 255 and 210 of 216 leaves "
              "come back 'healthy' — 9.3%. Swap red and blue: 55.6%. No exception anywhere. The fix is a "
              "golden test: Dart tensor vs Python fixture, max diff 1e-4.")
title(s, "The silent bug", w=6)
text(s, 0.7, 1.95, 5.9, 1.0, [[("Same model, same photos. One preprocessing slip in Dart, and ", {}),
                              ("no error is raised.", B)]], 20)
code(s, 0.7, 3.0, 5.9, 1.4, "// must match Python training exactly\nresize(shortSide: 256) → centerCrop(224)\n"
     "rgb → float32 / 255.0   // NHWC [1,224,224,3]", 14)
text(s, 0.7, 4.6, 5.9, 0.6, "Guard: golden test, Dart tensor vs Python fixture (max diff ≤ 1e-4)", 14, MUTED)
for i, (lab, sub, big, col) in enumerate([("Correct preprocessing", None, "95.8%", LEAF),
                                          ("Forgot ÷255", "210 / 216 leaves → “healthy”", "9.3%", LATE),
                                          ("Red/blue swapped", None, "55.6%", EARLY)]):
    y = 1.95 + i * 1.35
    rect(s, 7.2, y, 5.4, 1.15, WHITE)
    text(s, 7.45, y + 0.25, 3, 0.4, lab, 18)
    if sub:
        text(s, 7.45, y + 0.65, 3, 0.3, sub, 12, MUTED)
    text(s, 10.0, y + 0.1, 2.4, 0.95, big, 40, col, TITLE_FONT, PP_ALIGN.RIGHT, MSO_ANCHOR.MIDDLE)
text(s, 7.2, 6.1, 5.4, 0.3, "ml-training/outputs/mismatch.json", 11, MUTED)

s = new_slide(WHITE, PAUL, "Confidence bar with the threshold tick; top-3 underneath; on-device latency "
              "and model version. Status is always icon + label + colour, never colour alone.")
title(s, "Show the answer honestly")
phones(s, ["s3_a_result_late_blight", "s3_c_result_early_blight", "s3_b_result_healthy"], 1.75, 5.0, gap=0.9,
       captions=["Late blight · 76.5%", "Early blight", "Healthy"])

s = new_slide(MINT, PAUL, "Threshold 0.50: the model answers 96.3% of test photos and is right 97.1% of the "
              "time when it answers. Below the threshold it says 'Not sure, retake' and shows its best guess.")
title(s, "Don’t guess: abstain", w=5.5)
numbox(s, 0.7, 2.2, 2.6, 1.6, "96.3%", "photos answered", fill=WHITE, big_size=40)
numbox(s, 3.5, 2.2, 2.6, 1.6, "97.1%", "correct when answered", fill=WHITE, color=LEAF, big_size=40)
text(s, 0.7, 4.1, 5.4, 1.4, ["Threshold 0.50, read from the model’s .json.",
                             "Below it: “Not sure”, best guess, retake."], 18, spacing=1.3)
text(s, 0.7, 5.6, 5.4, 0.3, "ml-training/outputs/eval_summary.json", 11, MUTED)
phones(s, ["s3_a_result_late_blight", "s3_d_result_not_sure_1"], 1.0, 5.6, x0=6.3, gap=0.6,
       captions=["Confident · 76.5%", "Not sure · 38.9%"])

# ══ Act 3b: Offline-first Flutter (Titus) ════════════════════════════════
s = new_slide(DARK, TITUS, "Handover: Paul → Titus. Scanning is never disabled. 'Online' means GET /ready "
              "answered within 2 s, not just connectivity_plus saying there's Wi-Fi.")
title(s, "Offline is the default", color=ON_DARK, w=5.5)
bullets(s, 0.7, 2.1, 5.4, [
    "Scanning is never disabled",
    [("Online = ", {}), ("GET /ready", {"font": MONO, "size": 17}), (" answered in 2 s", {})],
    "connectivity_plus alone isn’t enough: Wi-Fi without internet is common",
    "Advice explains why it’s unavailable",
], 20, ON_DARK)
text(s, 0.7, 6.3, 5.4, 0.3, "backend_status_provider.dart", 11, ON_DARK_MUTED)
rect(s, 6.4, 0, 6.933, 7.5, MINT)
phones(s, ["s1_b_scan_offline", "s4_d_advice_offline"], 0.9, 5.6, x0=6.4, gap=0.6,
       captions=["Scan, offline", "Advice, offline"])

s = new_slide(WHITE, TITUS, "Write locally first, then show. The outbox holds diagnoses with UUIDs made on the "
              "phone. Re-sending a batch returns 'duplicate', never a second row (Go test: 100 created, then "
              "100 duplicate). Rejected items say why.")
title(s, "Write first, sync later")
bullets(s, 0.7, 1.95, 4.0, [
    "① Save locally (Hive), then show the result",
    "② Outbox with UUIDs made on the phone",
    [("③ Re-sent batch → ", {}), ("duplicate", {"italic": True}), (", never a 2nd row", {})],
    "④ Rejected items explain why",
], 19)
text(s, 0.7, 5.6, 4.0, 0.6, "go-backend sync test: 100 created → resend → 100 duplicate", 13, MUTED)
phones(s, ["s5_a_history_1", "s5_b_history_syncing", "s5_d_result_sync_rejected_1"], 1.75, 4.9, x0=4.8,
       gap=0.35, captions=["Pending", "Syncing", "Rejected, with reason"])

s = new_slide(MINT, TITUS, "Stitch's DESIGN.md became ui/theme tokens; a drift test fails if they diverge. "
              "19 shared widgets. Where Stitch was wrong (contrast, duplicated banners), we corrected it rather "
              "than copied it.")
title(s, "Design system → code")
bullets(s, 0.7, 1.95, 3.5, ["Stitch DESIGN.md → lib/ui/theme tokens",
                            "Drift test fails if they diverge",
                            "19 shared widgets",
                            "Stitch mistakes corrected, not copied"], 19)
text(s, 0.7, 5.9, 3.5, 0.6, "design_tokens_test.dart · docs/UI_IMPLEMENTATION.md §1", 11, MUTED)
ref = Image.open(SCREENS / "c0_component_reference.png")
seg = ref.height // 3
for i in range(3):
    phone(s, "c0_component_reference", 4.4 + i * 2.95, 1.75, 4.9,
          crop=(0, i * seg, ref.width, (i + 1) * seg))

s = new_slide(WHITE, TITUS, "91 tests. A golden per screen state, light and dark. Accessibility checks "
              "(contrast, tap targets, labels, reduce motion) found 4 real bugs.")
title(s, "Testing the UI")
for i, (big, lab) in enumerate([("91", "tests"), ("4", "real a11y bugs found")]):
    numbox(s, 0.7, 1.95 + i * 1.5, 3.7, 1.3, big, lab, big_size=40)
text(s, 0.7, 5.0, 3.7, 1.8, ["Text contrast 4.18:1", "Crash under reduce motion", "40 dp tap target",
                             "Unlabelled switch"], 14, MUTED, spacing=1.3)
phones(s, ["s3_c_result_early_blight", "s4_e_advice_unavailable", "dark/s3_a_result_late_blight"], 1.75,
       4.9, x0=4.6, gap=0.4, captions=["Light golden", "Light golden", "Dark golden"])

# ══ Act 4: Coming back online (Titus) ════════════════════════════════════
s = new_slide(MINT, TITUS, "The app talks to one service only: go-backend. It owns sync, history, model "
              "releases, and proxies predictions and advice to the Python services. Same DDD layering as the app.")
phone(s, "s7_b_diagnostics_2", 0.7, 0.9, 5.7)
title(s, "One door: go-backend", x=4.0, w=8.6)
node(s, 4.0, 2.3, 2.0, 1.0, "LeafCheck", "Flutter")
arrow(s, 6.1, 2.65)
node(s, 6.75, 2.0, 2.4, 1.6, "go-backend", "chi · pgx · Postgres", DARK, DARK, ON_DARK, 18)
arrow(s, 9.25, 2.25)
arrow(s, 9.25, 3.05)
node(s, 9.9, 1.9, 2.7, 0.75, "python-ml-service", "/predictions proxy", size=14)
node(s, 9.9, 2.95, 2.7, 0.75, "rag-service", "/advice proxy", size=14)
bullets(s, 4.0, 4.2, 8.6, [[("diagnoses:sync", {"font": MONO, "size": 15}), (" · device history · model "
                                                                              "releases", {})],
                           "The app never calls the Python services directly",
                           "Same DDD layers as the app"], 17)

s = new_slide(WHITE, TITUS, "ETag/304 so checks are cheap; Range download so a dropped connection resumes; "
              "sha256 verified before switching; the previous model is kept. A bad file is refused.")
title(s, "Safe model updates", sub="ETag/304 → Range download → sha256 check before switching → keep the previous model")
phones(s, ["s6_b_model_update_available", "s6_c_model_downloading", "s6_e_model_check_failed"], 1.95, 4.8,
       gap=0.9, captions=["Update offered", "Resumable download", "Bad file refused"])

s = new_slide(MINT, TITUS, "Phone says 76.5%, server says 81.2% (app → Go → ML service). The photo leaves the "
              "phone only when the user asks. Values here are mock; live via /api/v1/predictions.")
title(s, "Second opinion", w=6)
bullets(s, 0.7, 1.95, 6.0, ["Phone 76.5% vs server 81.2%",
                            "App → go-backend → python-ml-service",
                            "The photo leaves the phone only when the user asks"], 20)
text(s, 0.7, 5.6, 6, 0.3, "Mock values today · live via /api/v1/predictions", 11, MUTED)
phone(s, "s3_e_result_second_opinion", 8.3, 0.7, 6.1)

s = new_slide(WHITE, TITUS, "rag-service: curated notes → retrieval → local LLM; answers cite [n] sources. "
              "Faithfulness went 0.51 → 0.88 after two fixes: no padding rule in the prompt, self-contained "
              "'Cause' sentences in the notes. Warm answer ~3.5 s, so it's an add-on, never blocking.")
title(s, "“What do I do about this?”", w=6.4, size=34)
text(s, 0.7, 1.95, 6.0, 0.8, [[("App → ", {}), ("go-backend", B), (" → ", {}), ("rag-service", B),
                              (" → local LLM, with [n] sources", {})]], 18)
numbox(s, 0.7, 3.0, 2.9, 1.6, "0.51 → 0.88", "faithfulness", "two fixes", big_size=30)
numbox(s, 3.8, 3.0, 2.9, 1.6, "≈3.5 s", "warm answer", "an add-on, never blocking", big_size=30)
text(s, 0.7, 4.9, 6.0, 1, "Fixes: no “padding” rule in the prompt · self-contained “Cause” sentences in the "
     "notes", 13, MUTED)
phones(s, ["s4_a_advice_questions", "s4_c_advice_answer"], 1.0, 5.6, x0=6.9, gap=0.4)

s = new_slide(MINT, TITUS, "The same curated notes the RAG service retrieves from are bundled in the app as "
              "a disease library, so the knowledge works offline too.")
title(s, "Same knowledge, offline", w=5.6, size=34)
bullets(s, 0.7, 1.95, 5.2, ["The RAG notes ship inside the app",
                            "Disease library works in airplane mode",
                            "One source of truth: rag-service/knowledge/"], 19)
text(s, 0.7, 5.6, 5.2, 0.3, "mobile-app/assets/knowledge/", 11, MUTED)
phones(s, ["s9_a_disease_library", "s9_b_late_blight"], 1.0, 5.6, x0=6.0, gap=0.6)

# ══ Act 5: Demo and honesty (both) ═══════════════════════════════════════
s = new_slide(DARK, BOTH, "One drives the phone, one narrates. Backup: screen recording on the laptop.")
title(s, "Live demo", color=ON_DARK, w=6)
bullets(s, 0.7, 2.0, 6.0, ["① Airplane mode on", "② Scan a late-blight leaf → result in ms",
                           "③ History shows “Pending”", "④ Wi-Fi on → “Synced”",
                           "⑤ Get advice, with sources"], 22, ON_DARK)
text(s, 0.7, 6.3, 6, 0.3, "Backup: screen recording", 12, ON_DARK_MUTED)
rect(s, 7.0, 0, 6.333, 7.5, MINT)
phones(s, ["s1_b_scan_offline", "s5_b_history_syncing"], 0.9, 5.6, x0=7.0, gap=0.5)

s = new_slide(WHITE, BOTH, "95.8% on lab photos, 54.8% on 221 PlantDoc field photos. The model knows "
              "'diseased' (only 0.9% of diseased leaves called healthy) but confuses the two blights, and the "
              "threshold doesn't catch it: it still answers 86% of field photos, at 55%. Phone benchmarks are "
              "still to be measured; the speed test screen is where they'll appear.")
title(s, "Limitations, honestly", w=8)
numbox(s, 0.7, 2.0, 3.9, 2.0, "95.8%", "Lab photos (PlantVillage)", big_size=60)
numbox(s, 4.85, 2.0, 3.9, 2.0, "54.8%", "221 field photos (PlantDoc)", fill=PALE_LATE, color=LATE,
       big_size=60)
bullets(s, 0.7, 4.4, 8.0, ["Knows “diseased”: 0.9% of diseased leaves called healthy",
                           "Confuses the two blights; threshold still answers 86%, at 55%",
                           [("Next: ", B), ("field data with consent · calibration · phone benchmarks", {})]],
        16)
phone(s, "s7_c_speed_test", 9.9, 0.8, 5.9, "Phone benchmarks: still to measure")

s = new_slide(MINT, BOTH, "Five things to take home.")
title(s, "Five takeaways")
for i, (n, t) in enumerate([("1", "Measure the network cost"), ("2", "Preprocessing is part of the model"),
                            ("3", "Let the model abstain"), ("4", "Write first, sync idempotently"),
                            ("5", "Verify every update")]):
    x = 0.7 + i * 2.43
    rule(s, x, 2.6, 0.8)
    text(s, x, 2.75, 2.2, 0.9, n, 48, DARK, TITLE_FONT)
    text(s, x, 3.8, 2.2, 1.2, t, 19)

s = new_slide(DARK, BOTH, "Backup slides after this: API contract, RAGAS table, full mismatch table.")
image(s, ROOT / "mobile-app/assets/splash/splash_icon.png", 5.92, 1.0, h=1.5)
rule(s, 5.87, 3.0, 1.6, ON_DARK)
text(s, 0.7, 3.2, 11.93, 1, "Any questions?", 48, ON_DARK, TITLE_FONT, PP_ALIGN.CENTER)
text(s, 0.7, 4.35, 11.93, 0.4, f"{PAUL} · {TITUS}", 20, ON_DARK, align=PP_ALIGN.CENTER)
text(s, 0.7, 4.85, 11.93, 0.4, "github.com/Paulmburu/ai-crop-disease-platform", 14, ON_DARK_MUTED,
     align=PP_ALIGN.CENTER)

prs.save(OUT)
print(f"{OUT} · {len(prs.slides)} slides · {OUT.stat().st_size / 1e6:.1f} MB")
