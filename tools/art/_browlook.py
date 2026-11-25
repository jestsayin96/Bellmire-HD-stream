#!/usr/bin/env python3
"""_browlook.py - THE PICTURE THAT DECIDES FOR THE 360p BROW, and the one
number that can tell a BAR from a SMEAR.

    python3 -I tools/art/_browlook.py

*** THIS DOES NOT RUN IN BLENDER. *** It needs PIL, which cruzader's Blender
does not have and which there is no system Python to supply - the same split
`_streamscale.py` carries at the top of its own docstring. It consumes the PNGs
`_browshot.py` already wrote.

WHAT IT ASKS. `_browshot` renders the collier WITH and WITHOUT his brow through
one locked camera. This file area-averages both frames down to the rung the
viewer is actually sent (760 -> 160 BOX, `_streamscale`'s own ladder and
filter, so the numbers are comparable with the ones pass 16 shipped) and then
asks three different questions of the same pixels:

  1. moved_px   - how many pixels the brow still changes at 360p. ZERO means
                  the brow has stopped existing at that size. A NON-ZERO COUNT
                  IS NOT A PASS: the 05:58 ruling of 25 Nov stands, no lane
                  invents a MIN_CUE_PX.
  2. marks      - THE LABELLED CONNECTED COMPONENTS of those moved pixels, and
                  this is the half that answers the actual question. A brow is
                  ONE WIDE MARK. Two or three small marks side by side is the
                  DASHED read pass 16 warned about at SKIN 1.0 and could not
                  see in its own number, because `face_front_px` fell only
                  939 -> 855 for it. A total cannot tell one bar from three
                  dashes, so the bar is asked for directly.
  3. contrast   - the luma gap across those pixels against the head BEHIND
                  them. This is the number pass 17's soot moved: the brow is
                  `dark` and the pot head is `body`, and the soot painted the
                  head 0.55x. Reported as /255 against the 8/255 house
                  threshold, measured on the RENDER and not on authored colour.

AND IT GOES RED ON EMPTY. A contrast averaged over zero moved pixels reads
perfect and means nothing - trap 4, the metric-over-zero-pairs fault. Any arm
whose rung mask is empty is printed RED and its contrast is None, never 0.0.

THE SIDE VIEW IS THE COST COLUMN, because the lever is not free. SKIN exists to
sink the brow into the skull and kill the ~47 px side nub pass 16 found ("a dark
hook hanging off the side of his head, like a broken handle"). Lowering it to
buy back the brow BUYS THE NUB BACK TOO, so the sheet prints new silhouette px
outside the SHIPPED arm's own outline on the side view beside every brow
number. Whoever reads this is choosing a point on a trade, not finding a
free win.
"""
import os
import json
from collections import deque

import numpy as np
from PIL import Image

W5 = os.environ.get("W5", os.path.expanduser("~/mnt/bellmire-art"))
ROOT = os.path.join(W5, "renders", "art", "minibosses", "_brow")
KEY = "collier"
# The side-nub baseline is THE SHIPPED ARM of whichever ladder is being read,
# so "new px outside the shipped outline" always means the same thing.
SETS = {
    "skin": ("_bs60", ["_bs00", "_bs20", "_bs40", "_bs60", "_bs80", "_bsoot100"],
             {"_bs00": "skin 0.00", "_bs20": "skin 0.20", "_bs40": "skin 0.40",
              "_bs60": "skin 0.60  SHIPPED", "_bs80": "skin 0.80",
              "_bsoot100": "soot 1.00 (pass-16 head), skin 0.60"}),
    "soot": ("_bk055", ["_bk055", "_bk065", "_bk075", "_bk085", "_bk100"],
             {"_bk055": "soot 0.55  SHIPPED", "_bk065": "soot 0.65",
              "_bk075": "soot 0.75", "_bk085": "soot 0.85",
              "_bk100": "soot 1.00 (no soot - the pass-16 head)"}),
    "head": ("_bh055", ["_bh055", "_bh075", "_bh085", "_bh100"],
             {"_bh055": "head soot 0.55 = PASS 17 (the control)",
              "_bh075": "head soot 0.75, trunk 0.55",
              "_bh085": "head soot 0.85, trunk 0.55",
              "_bh100": "head CLEAN of soot, trunk 0.55"}),
}
SHIP, ARMS, LABEL = SETS[os.environ.get("BROW_SET", "skin")]
EPS, THRESH, RUNG = 2.0 / 255.0, 8.0 / 255.0, 160
PANE = (0.045, 0.05, 0.065)


def load(p):
    return np.asarray(Image.open(p).convert("RGBA"), np.float32) / 255.0


def over(a):
    al = a[:, :, 3:4]
    return a[:, :, :3] * al + np.array(PANE, np.float32) * (1.0 - al)


def luma(a):
    return 0.2126 * a[:, :, 0] + 0.7152 * a[:, :, 1] + 0.0722 * a[:, :, 2]


def rung(a):
    """Area-average the WHOLE frame down, which is what a video scaler does.
    Cropping first and then scaling would invent detail the viewer never gets."""
    W = RUNG
    H = int(round(a.shape[0] * W / float(a.shape[1])))
    im = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), "RGBA")
    return np.asarray(im.resize((W, H), Image.BOX), np.float32) / 255.0


def marks(m):
    """8-connected components of a boolean mask -> list of (px, x0, x1, y0, y1),
    biggest first. `_streamscale`'s labelling half, which exists because a
    total pixel count cannot tell one fat blob from four specks."""
    h, w = m.shape
    seen = np.zeros_like(m, bool)
    out = []
    for y in range(h):
        for x in range(w):
            if m[y, x] and not seen[y, x]:
                q = deque([(y, x)])
                seen[y, x] = True
                px = []
                while q:
                    cy, cx = q.popleft()
                    px.append((cy, cx))
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            ny, nx = cy + dy, cx + dx
                            if 0 <= ny < h and 0 <= nx < w and m[ny, nx] \
                                    and not seen[ny, nx]:
                                seen[ny, nx] = True
                                q.append((ny, nx))
                ys = [p[0] for p in px]
                xs = [p[1] for p in px]
                out.append((len(px), min(xs), max(xs), min(ys), max(ys)))
    out.sort(reverse=True)
    return out


def main():
    rep = {"arms": {}, "rung": RUNG, "thresh_255": 8}
    rows = []
    ship_side = None
    sp = os.path.join(ROOT, KEY + SHIP, "B_side.png")
    if os.path.isfile(sp):
        ship_side = load(sp)[:, :, 3] > EPS

    for arm in ARMS:
        d = os.path.join(ROOT, KEY + arm)
        pf = {t: os.path.join(d, "%s_front.png" % t) for t in ("B", "X")}
        if not all(os.path.isfile(p) for p in pf.values()):
            print("[browlook] %s: no front frames" % arm)
            continue
        B, X = load(pf["B"]), load(pf["X"])
        cell = {"label": LABEL.get(arm, arm)}

        # ---- full res, for the crop box and as the honest 'what was built' --
        mf = np.abs(B - X).max(axis=2) > EPS
        cell["moved_px_full"] = int(mf.sum())
        if not mf.any():
            cell["red"] = "0 px moved at full res - nothing was built to look at"
            print("[browlook] RED %s: 0 px moved at full res" % arm)
            rep["arms"][arm] = cell
            continue
        ys, xs = np.where(mf)
        # the crop is the BROW's own bbox grown to show the head it lies on, so
        # the eye judges it in context and not as a floating stripe
        bw, bh = xs.max() - xs.min() + 1, ys.max() - ys.min() + 1
        padx, pady = int(bw * 0.55), int(bh * 5.5)
        x0 = max(0, xs.min() - padx); x1 = min(B.shape[1], xs.max() + padx + 1)
        y0 = max(0, ys.min() - pady); y1 = min(B.shape[0], ys.max() + pady + 1)

        # ---- the rung ------------------------------------------------------
        Br, Xr = rung(B), rung(X)
        sc = RUNG / float(B.shape[1])
        rx0, rx1 = int(x0 * sc), max(int(x0 * sc) + 2, int(np.ceil(x1 * sc)))
        ry0, ry1 = int(y0 * sc), max(int(y0 * sc) + 2, int(np.ceil(y1 * sc)))
        dr = np.abs(luma(Br) - luma(Xr))
        mr = dr > THRESH
        nr = int(mr.sum())
        cell["moved_px_rung"] = nr
        if nr == 0:
            cell["red"] = ("0 px moved at the 360p rung - the brow has stopped "
                           "existing at the size the viewer is sent")
            cell["contrast_255"] = None
            cell["marks"] = []
            print("[browlook] RED %s: brow gone at the rung" % arm)
        else:
            # contrast is the luma gap the viewer gets, and it is only ever
            # averaged over pixels that actually moved
            v = dr[mr]
            cell["contrast_255"] = dict(
                mean=round(float(v.mean()) * 255.0, 2),
                max=round(float(v.max()) * 255.0, 2))
            mk = marks(mr)
            cell["marks"] = [dict(px=p, w=x1m - x0m + 1, h=y1m - y0m + 1)
                             for p, x0m, x1m, y0m, y1m in mk[:6]]
            cell["n_marks"] = len(mk)
            cell["widest_mark_px"] = mk[0][0]
            cell["widest_mark_w"] = mk[0][2] - mk[0][1] + 1
            print("[browlook] %-10s rung_moved=%3d marks=%d widest=%dpx w=%d "
                  "contrast mean=%.1f/255 max=%.1f/255"
                  % (arm, nr, len(mk), mk[0][0], cell["widest_mark_w"],
                     cell["contrast_255"]["mean"], cell["contrast_255"]["max"]))

        # ---- the cost column: the side nub against the SHIPPED outline -----
        sp2 = os.path.join(d, "B_side.png")
        if ship_side is not None and os.path.isfile(sp2):
            S = load(sp2)[:, :, 3] > EPS
            cell["side_new_px_vs_shipped"] = int((S & ~ship_side).sum())
            cell["side_lost_px_vs_shipped"] = int((ship_side & ~S).sum())

        # ---- panels --------------------------------------------------------
        bc = B[y0:y1, x0:x1]
        h, w = bc.shape[0], bc.shape[1]
        up = 4
        p1 = Image.fromarray((np.clip(over(bc), 0, 1) * 255).astype(np.uint8))
        p1 = p1.resize((w * up, h * up), Image.NEAREST)
        brc = Br[ry0:ry1, rx0:rx1]

        def big(a3):
            im = Image.fromarray((np.clip(a3, 0, 1) * 255).astype(np.uint8))
            return im.resize((w * up, h * up), Image.NEAREST)

        p2 = big(over(brc))
        o = over(brc).copy()
        sub = mr[ry0:ry1, rx0:rx1]
        o[sub] = np.array((1.0, 0.0, 0.85), np.float32)
        p3 = big(o)
        rows.append((arm, cell, [p1, p2, p3]))
        rep["arms"][arm] = cell

    if rows:
        gap = 12
        wc = max(p.width for _, _, ps in rows for p in ps)
        hc = max(p.height for _, _, ps in rows for p in ps)
        W = 3 * wc + 4 * gap
        H = len(rows) * (hc + gap) + gap
        sheet = Image.new("RGB", (W, H), (16, 17, 21))
        for i, (_a, _c, ps) in enumerate(rows):
            for j, p in enumerate(ps):
                sheet.paste(p, (gap + j * (wc + gap), gap + i * (hc + gap)))
        out = os.path.join(ROOT, "_browlook_%s.png" % os.environ.get("BROW_SET","skin"))
        sheet.save(out)
        print("[browlook] wrote %s (%dx%d) - rows top to bottom: %s"
              % (out, W, H, ", ".join(a for a, _, _ in rows)))
        print("[browlook] columns: 1 full-res head crop | 2 the same crop at "
              "the 360p rung | 3 the rung with moved px magenta")

    with open(os.path.join(ROOT, "_browlook_%s.json" % os.environ.get("BROW_SET","skin")), "w") as fh:
        json.dump(rep, fh, indent=1)


main()
