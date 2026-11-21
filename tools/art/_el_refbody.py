# THE VIEWER'S QUESTION, NOT THE HARNESS'S.
# Every hero_back.png contains the SAME reference adventurer standing beside the
# miniboss. If the light is even, that reference must read the SAME COLOUR in
# every frame. If a frame carries a colour wash, the reference will carry it too
# - and the reference's material is identical across all frames, so any colour
# difference there is LIGHT, not paint. That is the test the saturation number
# cannot do: it reads one frame at a time and cannot see cross-frame drift.
#
# Isolating it: take the column-opacity profile, find the LAST run of opaque
# columns separated from the rest by a genuine gap, and measure there. If there
# is NO gap the two figures touch and the band is NOT the reference alone - that
# body is reported UNRESOLVED and excluded, never silently measured.
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
    return (px.reshape(h, w, 4) * 255.0).round().clip(0, 255).astype(np.uint8)[::-1]

def last_run(a, min_gap=6):
    cols = (a[..., 3] > 8).sum(axis=0)
    on = cols > 0
    if not on.any():
        return None
    # walk back from the right edge to the start of the last opaque run
    idx = np.where(on)[0]
    end = idx[-1]; start = end
    gap = 0
    for x in range(end, -1, -1):
        if on[x]:
            start = x; gap = 0
        else:
            gap += 1
            if gap >= min_gap:
                break
    if start == idx[0]:
        return None            # no gap anywhere: the figures touch
    return int(start), int(end)

def stats(a, x0, x1):
    sl = a[:, x0:x1 + 1]
    rgb = sl[..., :3].astype(np.float32)
    lit = (sl[..., 3] > 8) & (rgb.max(axis=2) > 24)
    if lit.sum() < 500:
        return None
    p = rgb[lit]
    mx, mn = p.max(axis=1), p.min(axis=1)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1.0), 0.0)
    return {"px": int(lit.sum()), "sat": round(float(sat.mean()), 3),
            "rgb": [int(v) for v in p.mean(axis=0).round()]}

rows = {}
for k in KEYS:
    b = load(os.path.join(BEFORE, k, "hero_back.png"))
    n = load(os.path.join(MB, k, "hero_back.png"))
    rb, rn = last_run(b), last_run(n)
    if rb is None or rn is None:
        rows[k] = {"UNRESOLVED": "no column gap - reference touches the miniboss"}
        continue
    rows[k] = {"band_before": rb, "band_after": rn,
               "before": stats(b, *rb), "after": stats(n, *rn)}
print("ELREF|", json.dumps(rows))
