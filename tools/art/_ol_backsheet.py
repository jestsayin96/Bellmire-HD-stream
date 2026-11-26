"""_ol_backsheet.py - DOES THE OVERLOOKER HAVE A FACING? THE PICTURE, AND THE
ONE NUMBER THAT IS ALLOWED TO SUPPORT IT.

Built for the team lead's 16:58 row of 25 Nov: the back view at the same 160 px
/ 360p rung as _ol_rung_ab.py, in colour AND as pure silhouette, so the facing
can be judged at the resolution the player sees instead of at 700 px where a
turned head is obvious.

THE TEST IS A DIFFERENCE BETWEEN TWO PICTURES, NOT A METRIC OVER ONE.
A body with no facing reads THE SAME from front and back - that is the Beadle
fault in one sentence. A back view is, for a front/back-symmetric body, just
the front view MIRRORED IN X. So the number here is the IoU of the front
silhouette against the BACK SILHOUETTE MIRRORED, both normalised to their own
bounding box at the rung:

    IoU near 1.0  -> the outline carries NO facing. Whatever facing the body
                     has lives in shading or in a cue the outline loses, and
                     must be claimed on the colour row only.
    IoU well under -> the outline itself differs, and the figure can be told
                     front from back as a shape.

It is reported WITH the raw front-vs-back IoU (unmirrored) so neither can be
quietly swapped for the other, and the panels are drawn either way so the eye
gets the last word. THE NUMBER IS THE SUSPECT AND THE PICTURE IS THE EVIDENCE.

RED ON EMPTY and RED ON CLIPPED, same as _ol_rung_ab.py: a rung mask with no
pixels reads green and means nothing, and a clipped figure is not a blank one.
"""
import os
import sys
import numpy as np
from PIL import Image, ImageDraw

W5 = os.path.expanduser("~/mnt/bellmire-art")
SRC = os.path.join(W5, "renders", "art", "minibosses", "_ol_back4")
OUT = os.path.join(W5, "renders", "art", "minibosses", "_ol_back_facing.png")
VIEWS = ["front", "side", "back"]
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


fails, cells, masks = [], {}, {}
for v in VIEWS:
    p = os.path.join(SRC, v + ".png")
    if not os.path.exists(p):
        fails.append("MISSING %s" % p)
        continue
    A = load(p)
    al = A[:, :, 3]
    if not (al > A_EPS).any():
        fails.append("RED %s: full-res frame is BLANK" % v)
        continue
    edge = max(al[0, :].max(), al[-1, :].max(), al[:, 0].max(), al[:, -1].max())
    if edge > A_EPS:
        fails.append("RED %s: body touches the frame border (a=%.3f)" % (v, edge))
    R = rung(A)
    rl = R[:, :, 3]
    if not (rl > A_EPS).any():
        fails.append("RED %s: rung mask is EMPTY - the body does not survive "
                     "160 px at all" % v)
        continue
    ys, xs = np.where(rl > A_EPS)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    col = over(R[y0:y1, x0:x1])
    m = rl[y0:y1, x0:x1] > 0.5
    masks[v] = m
    sil = np.repeat(m[:, :, None], 3, axis=2)
    sil = sil * np.array((0.93, 0.93, 0.95), np.float32) + \
        (~sil.astype(bool)) * np.array(PANE, np.float32)
    cells[(v, "col")] = Image.fromarray((col * 255).astype(np.uint8))
    cells[(v, "sil")] = Image.fromarray((sil * 255).astype(np.uint8))
    print("[rung] %-6s bbox %dx%d  opaque_px %d  border %.3f"
          % (v, x1 - x0, y1 - y0, int(m.sum()), edge))

if fails:
    for f in fails:
        print(f)
    if any(f.startswith("RED") or "MISSING" in f for f in fails):
        sys.exit(2)


def iou(a, b):
    """a, b boolean masks of possibly different size -> resample b onto a's
    grid at the rung. RED ON EMPTY: a union of zero is not a score of 1."""
    if b.shape != a.shape:
        bi = Image.fromarray((b * 255).astype(np.uint8))
        b = np.asarray(bi.resize((a.shape[1], a.shape[0]), Image.BOX)) > 127
    u = (a | b).sum()
    if u == 0:
        return None
    return float((a & b).sum()) / float(u)


note = []
if "front" in masks and "back" in masks:
    f, b = masks["front"], masks["back"]
    raw = iou(f, b)
    mir = iou(f, b[:, ::-1])
    note.append("front vs back  IoU %.3f" % raw if raw is not None
                else "front vs back  IoU RED-EMPTY")
    note.append("front vs back MIRRORED  IoU %.3f" % mir if mir is not None
                else "front vs back MIRRORED  IoU RED-EMPTY")
    for v in VIEWS:
        if v in masks:
            m = masks[v]
            note.append("%s w/h %.3f" % (v, m.shape[1] / float(m.shape[0])))
    print("\n".join("[facing] " + n for n in note))

SC = 5
rows = [("col", "colour"), ("sil", "SILHOUETTE")]
pans = {k: panel(v, SC) for k, v in cells.items()}
cw = max(p.width for p in pans.values())
rh = max(p.height for p in pans.values())
gap, lab = 18, 20
W = gap + len(VIEWS) * (cw + gap)
H = gap + len(rows) * (rh + lab + gap) + (len(note) + 1) * 16 + gap
sheet = Image.new("RGB", (W, H), (16, 17, 21))
dr = ImageDraw.Draw(sheet)
y = gap
for kind, kname in rows:
    x = gap
    for v in VIEWS:
        dr.text((x, y), "OVERLOOKER pass4 - %s - %s @360p rung" % (v, kname),
                fill=(235, 235, 235))
        sheet.paste(pans[(v, kind)], (x, y + lab))
        x += cw + gap
    y += rh + lab + gap
dr.text((gap, y), "THE FACING TEST - a back view is a mirrored front view if the "
        "body has no facing:", fill=(235, 235, 235))
y += 16
for n in note:
    dr.text((gap + 10, y), n, fill=(200, 205, 215))
    y += 16
sheet.save(OUT)
print("wrote", OUT, sheet.size)
