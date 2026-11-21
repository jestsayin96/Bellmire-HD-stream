"""_el_gc_look - COMPOSITE BEFORE|AFTER OVER WHITE AND LOOK AT IT.

The fault being fixed was stated as "sit on white with no shadow", so the
picture that judges the fix has to be composited OVER WHITE, the way the
viewer meets it. Instalment 4's sheet pasted raw RGBA and let transparency
read as black, which cannot show a contact shadow at all.

Left column: the shipped even-light view (no floor in the scene).
Right column: the same body with --ground.
Bottom strip of each tile is a 2x zoom on the ground line, because a contact
shadow is 3-4k px in a 395k px frame and a thumbnail can hide it.
"""
import os, sys, json
import numpy as np, bpy

W5 = r"C:\hd adventure\bellmire-art"
MB = os.path.join(W5, "renders", "art", "minibosses")
KEYS = sys.argv[sys.argv.index("--") + 1].split(",")
VIEWS = ("front", "side", "back")


def load(path):
    img = bpy.data.images.load(path, check_existing=False)
    img.colorspace_settings.name = 'Non-Color'
    w, h = img.size
    px = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    bpy.data.images.remove(img)
    return px.reshape(h, w, 4)[::-1]


def over_white(a):
    al = a[:, :, 3:4]
    rgb = a[:, :, :3] * al + (1.0 - al)
    return (rgb * 255.0).round().clip(0, 255).astype(np.uint8)


def thumb(a, s):
    return a[::s, ::s]


rows, tiles = {}, []
for k in KEYS:
    for v in VIEWS:
        cp = os.path.join(MB, k, "hero_%s.png" % v)
        tp = os.path.join(MB, k + "_gc", "hero_%s.png" % v)
        if not (os.path.isfile(cp) and os.path.isfile(tp)):
            rows["%s/%s" % (k, v)] = "MISSING"
            continue
        A, B = load(cp), load(tp)
        wa, wb = over_white(A), over_white(B)
        # how dark does the floor actually get, as a viewer sees it on white
        da = 255 - wa.min(axis=2).astype(np.int16)
        db = 255 - wb.min(axis=2).astype(np.int16)
        new = (A[:, :, 3] <= 0.02) & (B[:, :, 3] > 0.02)
        rows["%s/%s" % (k, v)] = {
            "new_px": int(new.sum()),
            "darkest_new_on_white": int(db[new].max()) if new.any() else 0,
            "mean_new_on_white": round(float(db[new].mean()), 1) if new.any() else 0.0,
            "control_darkest_same_px": int(da[new].max()) if new.any() else 0,
        }
        h = wa.shape[0]
        zoom = slice(int(h * 0.74), h)
        ta, tb = thumb(wa, 2), thumb(wb, 2)
        za = np.repeat(np.repeat(wa[zoom][::4, ::4], 2, 0), 2, 1)
        zb = np.repeat(np.repeat(wb[zoom][::4, ::4], 2, 0), 2, 1)
        tiles.append(("%s %s" % (k, v),
                      np.vstack([ta, za[:, :ta.shape[1]]]),
                      np.vstack([tb, zb[:, :tb.shape[1]]])))

th = max(t[1].shape[0] for t in tiles)
tw = max(t[1].shape[1] for t in tiles)
H, W = th * len(tiles), tw * 2
sheet = np.full((H, W, 4), 255, dtype=np.uint8)
for i, (lab, a, b) in enumerate(tiles):
    sheet[i*th:i*th+a.shape[0], 0:a.shape[1], :3] = a
    sheet[i*th:i*th+b.shape[0], tw:tw+b.shape[1], :3] = b
    sheet[i*th, :, :3] = 40
out = bpy.data.images.new("gc", width=W, height=H, alpha=True)
out.colorspace_settings.name = 'Non-Color'
out.pixels.foreach_set((sheet[::-1].astype(np.float32) / 255.0).ravel())
p = os.path.join(MB, "_el_gc_sheet.png")
out.filepath_raw = p; out.file_format = 'PNG'; out.save()
print("GCLOOK|", json.dumps({"sheet": p, "size": [W, H], "rows": rows}))
