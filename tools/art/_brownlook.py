"""_brownlook.py - THE PICTURE THAT DECIDES, for the operator/clamp contrast.
A number handed back by `_brownread.py` is a suspect until a picture agrees.

  MB_KEY=collier OP_ARMS=_opCtl python3 tools/art/_brownlook.py

Per view, four panels left to right, all the same height:
  1. B at FULL res, cropped to the man's own bounding box, 3x NEAREST.
  2. The same crop at the 360p RUNG (BOX to 160 wide, then NEAREST back up) -
     what the viewer is actually sent.
  3. The under-threshold overlay: the man's ON-MOUND pixels whose contrast
     against what is behind them is under 8/255 painted MAGENTA on the 360p
     panel. Magenta because nothing on this body is magenta, so an overlay
     pixel can never be mistaken for the body.
  4. X at the rung - the frame with the man hidden, so the eye can check that
     the thing called 'behind him' really is his own mound and not air.
"""
import os
import numpy as np
from PIL import Image

W5 = os.environ.get("W5", os.path.expanduser("~/mnt/bellmire-art"))
KEY = os.environ.get("MB_KEY", "collier")
ARMS = [a for a in os.environ.get("OP_ARMS", "_opCtl").split(",") if a]
VIEWS = ("front", "side", "back")
ROOT = os.path.join(W5, "renders", "art", "minibosses", "_brown")
EPS, THRESH, RUNG = 2.0 / 255.0, 8.0 / 255.0, 160
PANE = (0.045, 0.05, 0.065)


def load(p):
    return np.asarray(Image.open(p).convert("RGBA"), np.float32) / 255.0


def over(a):
    """Composite on the pane colour the renders were shot against, so a crop
    looks like the frame and not like a cut-out on white."""
    al = a[:, :, 3:4]
    return a[:, :, :3] * al + np.array(PANE, np.float32) * (1.0 - al)


def luma(a):
    return 0.2126 * a[:, :, 0] + 0.7152 * a[:, :, 1] + 0.0722 * a[:, :, 2]


def tiles(arm):
    out = []
    base = os.path.join(ROOT, KEY + arm)
    for v in VIEWS:
        ps = {t: os.path.join(base, "%s_%s.png" % (t, v)) for t in ("B", "X", "Mo")}
        if not all(os.path.isfile(p) for p in ps.values()):
            continue
        B, X, Mo = (load(ps[t]) for t in ("B", "X", "Mo"))
        m = Mo[:, :, 3] > EPS
        ys, xs = np.where(m)
        if not len(ys):
            continue
        pad = 14
        y0, y1 = max(0, ys.min() - pad), min(B.shape[0], ys.max() + pad)
        x0, x1 = max(0, xs.min() - pad), min(B.shape[1], xs.max() + pad)
        bc, xc, mc = B[y0:y1, x0:x1], X[y0:y1, x0:x1], Mo[y0:y1, x0:x1]
        h, w = bc.shape[0], bc.shape[1]
        # panel 1: full res, 3x
        p1 = Image.fromarray((np.clip(over(bc), 0, 1) * 255).astype(np.uint8))
        p1 = p1.resize((w * 3, h * 3), Image.NEAREST)
        # the rung: downsample the WHOLE frame (a scaler does not crop first),
        # then take the matching crop, then NEAREST up to the same panel size
        sc = RUNG / float(B.shape[1])
        def rung(a):
            W = RUNG
            H = int(round(a.shape[0] * W / float(a.shape[1])))
            im = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), "RGBA")
            return np.asarray(im.resize((W, H), Image.BOX), np.float32) / 255.0
        Br, Xr, Mr = rung(B), rung(X), rung(Mo)
        ry0, ry1 = int(y0 * sc), max(int(y0 * sc) + 2, int(y1 * sc))
        rx0, rx1 = int(x0 * sc), max(int(x0 * sc) + 2, int(x1 * sc))
        brc, xrc, mrc = Br[ry0:ry1, rx0:rx1], Xr[ry0:ry1, rx0:rx1], Mr[ry0:ry1, rx0:rx1]
        def up(a3):
            im = Image.fromarray((np.clip(a3, 0, 1) * 255).astype(np.uint8))
            return im.resize((w * 3, h * 3), Image.NEAREST)
        p2 = up(over(brc))
        # panel 3: the under-threshold on-mound overlay, built at the rung
        alone = mrc[:, :, 3] > EPS
        changed = np.abs(brc - xrc).max(axis=2) > EPS
        # THE FRONTMOST TEST - the same one `_brownread` had to be corrected
        # to. `changed & alone` also catches pixels where the MOUND is in
        # front of the man and merely lost his shadow, and painting those
        # magenta drew a fault that is not there. See the note in that file.
        behind = xrc[:, :, 3] > EPS
        front = alone & changed & (np.abs(brc - mrc).max(axis=2)
                                   < np.abs(brc - xrc).max(axis=2))
        d = np.abs(luma(brc) - luma(xrc))
        bad = front & behind & (d < THRESH)
        o = over(brc).copy()
        o[bad] = np.array((1.0, 0.0, 0.85), np.float32)
        p3 = up(o)
        p4 = up(over(xrc))
        out.append((v, [p1, p2, p3, p4], int(bad.sum())))
    return out


def main():
    for arm in ARMS:
        rows = tiles(arm)
        if not rows:
            print("[brownlook] %s: nothing to draw" % arm)
            continue
        gap = 10
        wcell = max(p.width for _, ps, _ in rows for p in ps)
        hcell = max(p.height for _, ps, _ in rows for p in ps)
        W = 4 * wcell + 5 * gap
        H = len(rows) * (hcell + gap) + gap
        sheet = Image.new("RGB", (W, H), (16, 17, 21))
        for i, (v, ps, nbad) in enumerate(rows):
            for j, p in enumerate(ps):
                sheet.paste(p, (gap + j * (wcell + gap), gap + i * (hcell + gap)))
            print("[brownlook] %s %s: %d magenta px at the rung" % (arm, v, nbad))
        out = os.path.join(ROOT, "_look%s.png" % arm)
        sheet.save(out)
        print("[brownlook] wrote %s (%dx%d)" % (out, W, H))


main()
