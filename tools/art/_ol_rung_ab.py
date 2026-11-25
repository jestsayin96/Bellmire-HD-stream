"""_ol_rung_ab.py - THE PICTURE THAT DECIDES THE OVERLOOKER'S PASS 4.

The team lead asked for a silhouette that reads as A BODY AT THE RUNG THE
PLAYER SEES, and the thing that would have let me cheat is judging it at
700 px, where a waist 22 percent narrower than a chest is obvious and at
160 px may be nothing at all. So this renders the decision, not a number:

  row 1/2  PASS 3 and PASS 4 in colour, whole frame area-averaged down to
           RUNG=160 px wide (the 360p rung this file already uses for the
           collier brow), then NEAREST back up so the eye sees the pixels
           the scaler actually produced.
  row 3/4  the same two as PURE SILHOUETTE - alpha thresholded, no shading.
           Colour is what lets a bad silhouette pass; throw it away and the
           chess piece has nowhere to hide.

RED ON EMPTY, AND RED ON CLIPPED. A rung mask with no pixels in it prints
RED and exits non-zero rather than drawing a blank panel that looks fine in
a sheet; so does any frame whose body touches the border, because a clipped
figure is not a blank one and the blank check cannot see it.
"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw

W5 = os.path.expanduser("~/mnt/bellmire-art")
NEW = os.path.join(W5, "renders", "art", "minibosses", "overlooker")
OLD = os.path.join(W5, "renders", "art", "minibosses", "_ol_p3ref")
OUT = os.path.join(W5, "renders", "art", "minibosses", "_ol_rung_ab.png")
VIEWS = ["front", "three_quarter", "side"]
PANE = (0.045, 0.05, 0.065)
RUNG = 160
A_EPS = 2.0 / 255.0

def load(p):
    return np.asarray(Image.open(p).convert("RGBA"), np.float32) / 255.0

def over(a):
    al = a[:, :, 3:4]
    return a[:, :, :3] * al + np.array(PANE, np.float32) * (1.0 - al)

def rung(a):
    h = int(round(a.shape[0] * RUNG / float(a.shape[1])))
    im = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), "RGBA")
    return np.asarray(im.resize((RUNG, h), Image.BOX), np.float32) / 255.0

def panel(img, scale):
    return img.resize((img.width * scale, img.height * scale), Image.NEAREST)

fails = []
cells = {}
for tag, root in (("PASS 3 (shipped)", OLD), ("PASS 4 (this run)", NEW)):
    for v in VIEWS:
        p = os.path.join(root, v + ".png")
        if not os.path.exists(p):
            fails.append("%s %s: MISSING %s" % (tag, v, p)); continue
        A = load(p)
        al = A[:, :, 3]
        if not (al > A_EPS).any():
            fails.append("RED %s %s: full-res frame is BLANK" % (tag, v)); continue
        # border: a clipped icon is not a blank one
        edge = max(al[0, :].max(), al[-1, :].max(), al[:, 0].max(), al[:, -1].max())
        if edge > A_EPS:
            fails.append("RED %s %s: body touches the frame border (a=%.3f)"
                         % (tag, v, edge))
        R = rung(A)
        rl = R[:, :, 3]
        if not (rl > A_EPS).any():
            fails.append("RED %s %s: rung mask is EMPTY - the body does not "
                         "survive 160 px at all" % (tag, v)); continue
        ys, xs = np.where(rl > A_EPS)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        col = over(R[y0:y1, x0:x1])
        sil = np.repeat((rl[y0:y1, x0:x1] > 0.5)[:, :, None], 3, axis=2)
        sil = sil * np.array((0.93, 0.93, 0.95), np.float32) + \
            (~sil.astype(bool)) * np.array(PANE, np.float32)
        cells[(tag, v, "col")] = Image.fromarray((col * 255).astype(np.uint8))
        cells[(tag, v, "sil")] = Image.fromarray((sil * 255).astype(np.uint8))
        px = int((rl > A_EPS).sum())
        print("[rung] %-18s %-14s rung bbox %dx%d  opaque_px %d  border %.3f"
              % (tag, v, x1 - x0, y1 - y0, px, edge))

if fails:
    for f in fails:
        print(f)
    if any(f.startswith("RED") or "MISSING" in f for f in fails):
        sys.exit(2)

SC = 5
rows = [("PASS 3 (shipped)", "col"), ("PASS 4 (this run)", "col"),
        ("PASS 3 (shipped)", "sil"), ("PASS 4 (this run)", "sil")]
pans = {k: panel(v, SC) for k, v in cells.items()}
cw = max(p.width for p in pans.values())
rh = max(p.height for p in pans.values())
gap, lab = 18, 20
W = gap + len(VIEWS) * (cw + gap)
H = gap + len(rows) * (rh + lab + gap)
sheet = Image.new("RGB", (W, H), (16, 17, 21))
dr = ImageDraw.Draw(sheet)
y = gap
for tag, kind in rows:
    x = gap
    for v in VIEWS:
        dr.text((x, y), "%s - %s - %s @360p rung"
                % (tag, v, "colour" if kind == "col" else "SILHOUETTE"),
                fill=(235, 235, 235))
        im = pans[(tag, v, kind)]
        sheet.paste(im, (x, y + lab))
        x += cw + gap
    y += rh + lab + gap
sheet.save(OUT)
print("wrote", OUT, sheet.size)
