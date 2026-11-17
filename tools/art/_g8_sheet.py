# THE PICTURE FOR _g8_knuck.py - built from the PNGs that probe already wrote,
# so nothing is re-rendered and nothing can drift between number and picture.
#
# FRAMED ON THE GLOVE, NOT ON THE HERO. The first attempt framed a fixed band
# of the hero's height and photographed the tabard: the rows looked identical
# because the hand was not in them, which is a sheet that cannot disagree with
# me. The crop now comes from the pixels that the WHOLE GLOVE changes (the
# control render), so the frame is the piece under test by construction.
import os, sys, json
import numpy as np
REPO = r"C:\hd adventure\bellmire-art"
sys.path.append(os.path.join(REPO, "tools", "art"))
import lordgen as G   # noqa: E402

TMP = os.path.join(REPO, "renders", "art", "_g8tmp")
rep = json.load(open(os.path.join(REPO, "renders", "art", "_g8_knuck.json")))
PAD = 26
cols, errs = [], []
for c in rep["cells"]:
    for view in rep["views"]:
        v = c["views"][view]
        try:
            a = G.read_png(os.path.join(TMP, "%s_%s_on.png" % (c["key"], view)))
            b = G.read_png(os.path.join(TMP, "%s_%s_off.png" % (c["key"], view)))
            n = G.read_png(os.path.join(TMP, "%s_%s_none.png" % (c["key"], view)))
        except Exception as e:
            errs.append("%s/%s %s" % (c["key"], view, e))
            continue
        d = np.abs(a[..., 0:3] * a[..., 3:4] - n[..., 0:3] * n[..., 3:4]).max(axis=2)
        ys, xs = np.nonzero(d > 0.012)
        if len(xs) == 0:
            errs.append("%s/%s: the control differs nowhere - nothing to frame"
                        % (c["key"], view))
            continue
        y0, y1 = max(0, ys.min() - PAD), min(a.shape[0], ys.max() + PAD)
        x0, x1 = max(0, xs.min() - PAD), min(a.shape[1], xs.max() + PAD)
        cols.append((c["name"], view, c["dials"]["knuck_kind"],
                     v["knuckle_verts"], v["stream"], v["control_whole_glove"],
                     a[y0:y1, x0:x1], b[y0:y1, x0:x1]))

assert cols, "no columns: " + "; ".join(errs)
ch = max(q[6].shape[0] for q in cols)
cw = max(q[6].shape[1] for q in cols)
lab = 44
sheet = np.zeros((lab + ch * 2 + 26, cw * len(cols), 4), dtype=np.float32)
sheet[..., 0:3] = np.array((0.055, 0.060, 0.075))
sheet[..., 3] = 1.0


def paste(im, x, y):
    h, w = im.shape[0], im.shape[1]
    al = im[..., 3:4]
    dst = sheet[y:y + h, x:x + w, 0:3]
    sheet[y:y + h, x:x + w, 0:3] = im[..., 0:3] * al + dst * (1.0 - al)


for i, (nm, view, kind, kv, st, ctl, ia, ib) in enumerate(cols):
    x = i * cw
    paste(ia, x, lab)
    paste(ib, x, lab + ch)
    G.draw_text(sheet, ("%s %s" % (nm[:16], view.upper()))[:28], x + 6, 5, 1,
                (0.92, 0.88, 0.74))
    G.draw_text(sheet, "%s %dv  px %.2f%%  sil %.2f%%" % (kind, kv, st["pct"],
                                                          st["sil_pct"]),
                x + 6, 19, 1, (0.95, 0.55, 0.45) if kv == 0 else (0.70, 0.88, 0.72))
    G.draw_text(sheet, "WHOLE GLOVE px %.2f%% sil %.2f%%" % (ctl["pct"], ctl["sil_pct"]),
                x + 6, 31, 1, (0.72, 0.80, 0.88))
G.draw_text(sheet, "TOP = KNUCKLE ON   BOTTOM = KNUCKLE DROPPED. Same cell, frame, "
            "light. Framed on the glove, not the hero. 'sil' is outline change; the "
            "SIDE view's whole-glove sil is 0.00% so that column cannot test outline "
            "at all - it tests shading.",
            8, lab + ch * 2 + 8, 1, (0.86, 0.80, 0.60))
out = os.path.join(REPO, "renders", "art", "_g8_knuck_sheet.png")
G.write_png(out, sheet)
chk = G.read_png(out)
op = int((chk[..., 3] > 0.02).sum())
print("G8SHEET " + json.dumps(dict(path=out, cols=len(cols), opaque_px=op,
                                   errors=errs[:5], ok=op > 5000 and not errs)))
