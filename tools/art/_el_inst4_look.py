# Instalment 4: measure the even-light CLAIM (not just "pixels moved") and
# build a before|after contact sheet to LOOK at. Numbers and picture together.
import os, sys, json
import numpy as np, bpy

W5 = r"C:\hd adventure\bellmire-art"
MB = os.path.join(W5, "renders", "art", "minibosses")
BEFORE = os.path.join(W5, "_scratch", "_el_inst4_before")
KEYS = sys.argv[sys.argv.index("--") + 1].split(",")

def load(path):
    img = bpy.data.images.load(path, check_existing=False)
    img.colorspace_settings.name = 'Non-Color'
    w, h = img.size
    px = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    bpy.data.images.remove(img)
    a = (px.reshape(h, w, 4) * 255.0).round().clip(0, 255).astype(np.uint8)
    return a[::-1]  # blender rows are bottom-up

def stats(a):
    rgb = a[..., :3].astype(np.float32)
    alpha = a[..., 3]
    lit = (alpha > 8) & (rgb.max(axis=2) > 24)
    if lit.sum() == 0:
        return None
    p = rgb[lit]
    mx, mn = p.max(axis=1), p.min(axis=1)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1.0), 0.0)
    warm = (p[:, 0] > p[:, 2] + 18)
    return {"lit_px": int(lit.sum()),
            "mean_sat": round(float(sat.mean()), 3),
            "warm_frac": round(float(warm.mean()), 3),
            "mean_rgb": [int(v) for v in p.mean(axis=0).round()]}

def thumb(a, tw):
    h, w = a.shape[:2]
    s = max(1, int(round(w / float(tw))))
    return a[::s, ::s]

rows, tiles = {}, []
for k in KEYS:
    b = load(os.path.join(BEFORE, k, "hero_back.png"))
    n = load(os.path.join(MB, k, "hero_back.png"))
    rows[k] = {"before": stats(b), "after": stats(n)}
    tiles.append((k, thumb(b, 300), thumb(n, 300)))

th, tw = tiles[0][1].shape[:2]
H, W = th * len(tiles), tw * 2
sheet = np.zeros((H, W, 4), dtype=np.uint8)
sheet[..., 3] = 255
for i, (k, b, n) in enumerate(tiles):
    sheet[i*th:i*th+b.shape[0], 0:b.shape[1]] = b
    sheet[i*th:i*th+n.shape[0], tw:tw+n.shape[1]] = n
out = bpy.data.images.new("el4", width=W, height=H, alpha=True)
out.colorspace_settings.name = 'Non-Color'
flat = (sheet[::-1].astype(np.float32) / 255.0).ravel()
out.pixels.foreach_set(flat)
p = os.path.join(MB, "_el_inst4_sheet.png")
out.filepath_raw = p; out.file_format = 'PNG'; out.save()
print("EL4LOOK|", json.dumps({"sheet": p, "size": [W, H], "rows": rows}))
