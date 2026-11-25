"""_nubread - WHERE IS THE COLLIER'S SIDE NUB, AND WHAT PUTS IT THERE.

Pass 15 shipped a ~48 px break in the side silhouette whose cause three
guesses failed to find. This is the instrument for ABLATION, which is what
found the break's attribution in the first place: it counts, for one arm,
the pixels the arm's silhouette ADDS OUTSIDE a control silhouette, and it
localises them so the number can be looked at rather than believed.

  python3 tools/art/_nubread.py --ctl <dir> --arm <dir> [--arm ...] [--crop]

WHAT IT CANNOT SEE, SAID UP FRONT:
  * It measures the OUTLINE ONLY. A mark that is dark but inside the body's
    own alpha adds nothing here and this tool will read zero while the
    picture shows a smudge. The nub's "thin dark line curving down" may well
    be interior; that part is the eye's job, not this number's.
  * A mask is alpha > 8. An arm rendered against a different background,
    or at a different camera, is not comparable and this tool cannot tell.
  * RED ON EMPTY: if either mask is empty, or the two differ in shape, it
    raises rather than printing a comfortable zero.
"""
import argparse
import json
import os

import numpy as np
from PIL import Image

VIEWS = ("front", "side", "back")


def mask(path):
    a = np.array(Image.open(path).convert("RGBA"))
    m = a[:, :, 3] > 8
    if not m.any():
        raise SystemExit("EMPTY MASK (blank render?): %s" % path)
    return a, m


def runs(m):
    """Connected row-runs of a sparse mask, so a count becomes a shape."""
    out = []
    ys = np.nonzero(m.any(axis=1))[0]
    for y in ys:
        xs = np.nonzero(m[y])[0]
        b = [[xs[0], xs[0]]]
        for x in xs[1:]:
            if x == b[-1][1] + 1:
                b[-1][1] = x
            else:
                b.append([x, x])
        out.append([int(y), [[int(s), int(e)] for s, e in b]])
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ctl", required=True)
    ap.add_argument("--arm", action="append", required=True)
    ap.add_argument("--facectl", default="",
                    help="the COLLIER_FACE=0 arm. With it, every arm also "
                         "reports how many pixels the face CHANGES on the "
                         "front view - the thing the nub fix must not pay "
                         "with. Silhouette alone is half a verdict.")
    ap.add_argument("--crop", default="")
    ap.add_argument("--box", default="", help="y0,y1,x0,x1 for --crop")
    args = ap.parse_args()

    rep = {"ctl": args.ctl, "arms": {}}
    for arm in args.arm:
        row = {}
        for v in VIEWS:
            cp = os.path.join(args.ctl, "hero_%s.png" % v)
            ap_ = os.path.join(arm, "hero_%s.png" % v)
            for q in (cp, ap_):
                # RED ON EMPTY, and red on ABSENT: a mistyped arm directory
                # used to read as {"missing": true} beside four real numbers,
                # which is a comfortable nothing in the shape of a result.
                if not os.path.exists(q):
                    raise SystemExit("MISSING RENDER (arm not rendered?): %s" % q)
            ca, c = mask(cp)
            aa, a = mask(ap_)
            if c.shape != a.shape:
                raise SystemExit("SHAPE MISMATCH %s vs %s" % (cp, ap_))
            add = a & ~c
            lost = c & ~a
            e = {"added": int(add.sum()), "lost": int(lost.sum())}
            if add.any():
                ys, xs = np.nonzero(add)
                e["add_box"] = [int(ys.min()), int(ys.max()),
                                int(xs.min()), int(xs.max())]
                e["add_runs"] = runs(add)[:40]
            row[v] = e
        if args.facectl:
            fa = np.array(Image.open(os.path.join(args.facectl,
                          "hero_front.png")).convert("RGBA")).astype(int)
            aa = np.array(Image.open(os.path.join(arm,
                          "hero_front.png")).convert("RGBA")).astype(int)
            if fa.shape != aa.shape:
                raise SystemExit("SHAPE MISMATCH on --facectl front")
            d = np.abs(fa - aa).max(axis=2) > 6
            if not (fa[:, :, 3] > 8).any():
                raise SystemExit("EMPTY --facectl front")
            row["face_front_px"] = int(d.sum())
            if d.any():
                ys, xs = np.nonzero(d)
                row["face_box"] = [int(ys.min()), int(ys.max()),
                                   int(xs.min()), int(xs.max())]
        rep["arms"][os.path.basename(arm.rstrip("/\\"))] = row

    if args.crop:
        y0, y1, x0, x1 = (int(t) for t in args.box.split(","))
        tiles = []
        for d in [args.ctl] + args.arm:
            p = os.path.join(d, "hero_side.png")
            if not os.path.exists(p):
                continue
            im = Image.open(p).convert("RGBA").crop((x0, y0, x1, y1))
            im = im.resize(((x1 - x0) * 6, (y1 - y0) * 6), Image.NEAREST)
            tiles.append((os.path.basename(d.rstrip("/\\")), im))
        if tiles:
            w = sum(t[1].width for t in tiles) + 8 * (len(tiles) - 1)
            h = tiles[0][1].height
            sheet = Image.new("RGBA", (w, h), (24, 24, 28, 255))
            x = 0
            for _, im in tiles:
                sheet.alpha_composite(im, (x, 0))
                x += im.width + 8
            sheet.convert("RGB").save(args.crop)
            rep["crop"] = args.crop
            rep["crop_order"] = [t[0] for t in tiles]

    print("NUBREAD " + json.dumps(rep))


if __name__ == "__main__":
    main()
