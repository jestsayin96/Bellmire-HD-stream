"""Contact sheet for the stirrup A/B: base beside parts, three views, three
tiers, cropped to the weapon so the eye can actually judge it. Composited with
numpy inside Blender (no PIL on cruzader), reading PNGs as Non-Color so the
sRGB bytes round-trip."""
import bpy, numpy as np, os, sys

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
repo = argv[argv.index("--repo") + 1] if "--repo" in argv else "."
tag = argv[argv.index("--tag") + 1] if "--tag" in argv else "sheet"
D = os.path.join(repo, "renders", "art", "system2_stirrup")
T = os.path.join(D, "_tmp")

def rd(p):
    im = bpy.data.images.load(p, check_existing=False)
    im.colorspace_settings.name = 'Non-Color'
    w, h = im.size
    a = np.array(im.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    bpy.data.images.remove(im)
    return a

TIERS = ("common", "uncommon", "rare")
VIEWS = ("front", "side", "back")
CELL = 300
rows = []
for tier in TIERS:
    row = []
    for vname in VIEWS:
        k = "crossbow_%s" % tier
        try:
            mb = rd(os.path.join(T, "_w_%s_base_%s.png" % (k, vname)))[:, :, 3] > 0.02
            mc = rd(os.path.join(T, "_w_%s_parts_%s.png" % (k, vname)))[:, :, 3] > 0.02
        except Exception as e:
            raise SystemExit("sheet: missing mask for %s %s: %s" % (k, vname, e))
        m = mb | mc
        ys, xs = np.nonzero(m)
        assert len(ys) > 10, "empty mask %s %s - refusing to crop to nothing" % (k, vname)
        pad = 55
        y0, y1 = max(0, ys.min() - pad), min(m.shape[0], ys.max() + pad)
        x0, x1 = max(0, xs.min() - pad), min(m.shape[1], xs.max() + pad)
        s = max(y1 - y0, x1 - x0)
        cy, cx = (y0 + y1) // 2, (x0 + x1) // 2
        y0, x0 = max(0, cy - s // 2), max(0, cx - s // 2)
        y1, x1 = y0 + s, x0 + s
        for vk in ("base", "parts"):
            a = rd(os.path.join(D, "%s_%s_%s.png" % (k, vk, vname)))[y0:y1, x0:x1]
            # flatten onto a mid grey so the dark iron is not lost in alpha
            bg = np.zeros((a.shape[0], a.shape[1], 3), np.float32) + 0.42
            al = a[:, :, 3:4]
            rgb = a[:, :, :3] * al + bg * (1 - al)
            idx_y = (np.arange(CELL) * a.shape[0] // CELL).clip(0, a.shape[0] - 1)
            idx_x = (np.arange(CELL) * a.shape[1] // CELL).clip(0, a.shape[1] - 1)
            cell = rgb[idx_y][:, idx_x]
            cell[0, :] = cell[-1, :] = cell[:, 0] = cell[:, -1] = (0.9 if vk == "parts" else 0.1)
            row.append(cell)
    rows.append(np.concatenate(row, axis=1))
sheet = np.concatenate(rows, axis=0)
h, w, _ = sheet.shape
out = np.ones((h, w, 4), np.float32)
out[:, :, :3] = sheet
im = bpy.data.images.new("sheet", w, h, alpha=True)
im.colorspace_settings.name = 'Non-Color'
im.pixels = out[::-1].ravel().tolist()
p = os.path.join(D, "_%s.png" % tag)
im.filepath_raw = p
im.file_format = 'PNG'
im.save()
print("SHEET %s %dx%d rows=tiers cols=(front base|parts, side base|parts, back base|parts)" % (p, w, h))
