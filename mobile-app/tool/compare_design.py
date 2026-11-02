"""Side-by-side review: Stitch design (left) vs Flutter golden (right).

Usage (from mobile-app/): python3 tool/compare_design.py s1_a_scan_online [golden_name]
Writes build/compare/<id>.png.
"""
import sys
from pathlib import Path

from PIL import Image

design_id = sys.argv[1]
golden = sys.argv[2] if len(sys.argv) > 2 else design_id
g = Image.open(f"test/goldens/{golden}.png").convert("RGB")

# Exports vary (2560-wide canvases with the screen centred or left, or a bare
# 780/824-wide screen; some have transparency). Composite onto the surface
# colour, find the content box, and derive the 412-wide screen from it:
# content spans the 16..396 dp column, so screen = content width * 412/380.
SURFACE = (247, 251, 242)
rgba = Image.open(f"designs/{design_id}/screen.png").convert("RGBA")
bg = Image.new("RGBA", rgba.size, SURFACE + (255,))
d = Image.alpha_composite(bg, rgba).convert("RGB")
w, h = d.size
px = d.load()
xs = [x for x in range(0, w, 2) for y in range(0, h, 16)
      if sum(abs(a - b) for a, b in zip(px[x, y], SURFACE)) > 60]
cl, cr = min(xs), max(xs)
scale = (cr - cl) / 380
left = max(0, int(cl - 16 * scale))
design = d.crop((left, 0, left + int(412 * scale), min(h, int(915 * scale))))
design = design.resize((412, 915))

out = Image.new("RGB", (412 * 2 + 16, 915), "white")
out.paste(design, (0, 0))
out.paste(g.resize((412, 915)), (412 + 16, 0))
Path("build/compare").mkdir(parents=True, exist_ok=True)
out.save(f"build/compare/{design_id}.png")
print(f"build/compare/{design_id}.png")
