"""_brownread.py - THE MEASURING HALF OF "THE OPERATOR, BROWN-ON-BROWN WITH HIS
CLAMP". Linux bridge; PIL + numpy. Reads the B/X/Mo triples `_opshot.py` wrote.

  MB_KEY=collier OP_ARMS=_opCtl,_opV55 python3 tools/art/_brownread.py

THE QUESTION IT ASKS, AND IT IS THE VIEWER'S AND NOT A HARNESS'S. At the rung
the stream actually gives him, can you tell the man from the mound he stands on?
Not "is the man visible" - `_backread` answers that and the collier reads
`man_seen` high on every view. Not "does the man have range in him" - that is
_backread's value cell and it measures the man against HIMSELF. The open fault,
carried in the pass 14/15/16 lists in the same words each time, is that the man
and the mound ARE THE SAME MATERIAL - `minibosses.py` builds his trunk and both
arms from the `body` slot, and the clamp is that same `body` slot - so the only
separation he has anywhere is shading, and on the side view the pass notes say
it is background silhouette doing the work.

SO THE NUMBER IS A CONTRAST ACROSS A BOUNDARY THE VIEWER HAS TO SEE THROUGH:

    dL_on_mound = | luma(B) - luma(X) |  at the man's seen ON-MOUND pixels

B is everything; X is the same frame with the man hidden, so at an ON-MOUND
pixel X is LITERALLY WHAT WOULD BE THERE IF HE WERE NOT - his own mound. The
renderer does the depth and the lighting; nothing here reasons about occlusion.
Reported at `_streamscale`'s rungs with `_streamscale`'s BOX filter (760 -> 160
for 360p) so the numbers are comparable with the ones pass 16 shipped.

THREE THINGS IT REPORTS THAT A SINGLE MEAN WOULD HIDE:
  - `p50` and `p90` of dL, because a man with one bright rim and a dead middle
    has a fine mean and still reads as part of the hill.
  - `frac_under_8_255`, the share of on-mound pixels whose contrast is under the
    8/255 threshold `_streamscale` already treats as "did not move". That is the
    fraction of him that is, at that rung, INDISTINGUISHABLE from his mound.
  - `on_air_frac`, the share of his seen pixels whose boundary is against
    background instead. That is the kindness the dark pane gives him for free
    and a lit floor takes away - pass 15's own sentence, now a number.

IT GOES RED, NOT BLIND:
  - a missing arm, or a missing B/X/Mo in an arm        -> RED
  - shapes that disagree between B, X and Mo            -> RED
  - man-alone mask under 500 px                         -> RED (nothing split)
  - ON-MOUND under 300 px at full res                   -> RED, AND NOT 'clean'.
        This is the trap-4 arm and on this body it is the live risk: a contrast
        averaged over no overlap reads perfect. A view where the man never
        crosses his own mound answers nothing and must say so.
  - every arm's dL identically zero                     -> RED (the A/B did not
        take, or the split hid nothing)
A LOW dL IS NOT A FAILURE AND A HIGH ONE IS NOT A PASS. This file hands back a
contrast; the picture decides, and pass 16 is the precedent - the numbers wanted
1.0 and the picture forbade it.
"""
import os
import sys
import json

import numpy as np
from PIL import Image

W5 = os.environ.get("W5", os.path.expanduser("~/mnt/bellmire-art"))
KEY = os.environ.get("MB_KEY", "collier")
ARMS = [a for a in os.environ.get("OP_ARMS", "_opCtl").split(",") if a]
VIEWS = ("front", "side", "back")
RUNGS = [("full", 760), ("1080p", 480), ("720p", 320), ("480p", 213), ("360p", 160)]
THRESH = 8.0 / 255.0
EPS = 2.0 / 255.0
ROOT = os.path.join(W5, "renders", "art", "minibosses", "_brown")


def load(p):
    """RGBA as float 0-1 in the sRGB the viewer gets. No background composite:
    the alpha channel is the whole point of the partition."""
    return np.asarray(Image.open(p).convert("RGBA"), np.float32) / 255.0


def box(a, w):
    """`_streamscale`'s own downsample - PIL BOX, i.e. area average on the
    encoded bytes, which is what a stream scaler does to the frame the viewer
    is sent. Same filter and same rungs or the numbers are not comparable."""
    h, w0 = a.shape[0], a.shape[1]
    H = int(round(h * w / float(w0)))
    im = Image.fromarray((np.clip(a, 0, 1) * 255.0 + 0.5).astype(np.uint8), "RGBA")
    return np.asarray(im.resize((w, H), Image.BOX), np.float32) / 255.0


def luma(a):
    return 0.2126 * a[:, :, 0] + 0.7152 * a[:, :, 1] + 0.0722 * a[:, :, 2]


def stats(d, m, floor_px):
    """dL over a mask. RED - never green, never skipped - on too few pixels."""
    n = int(m.sum())
    if n < floor_px:
        return dict(px=n, red="mask %d px under the %d px floor - a contrast "
                             "averaged over no overlap is not a separation" % (n, floor_px))
    v = d[m]
    return dict(px=n,
                mean=round(float(v.mean()), 4),
                p50=round(float(np.percentile(v, 50)), 4),
                p90=round(float(np.percentile(v, 90)), 4),
                p99=round(float(np.percentile(v, 99)), 4),
                frac_under_8_255=round(float((v < THRESH).mean()), 4),
                frac_under_4_255=round(float((v < 4.0 / 255.0).mean()), 4))


def main():
    rep = {"key": KEY, "arms": ARMS, "thresh_255": 8,
           "rungs_from": "_streamscale.py:55 - spotlight.gd half-res panes",
           "measures": "dL = |luma(B)-luma(X)| at the man's SEEN ON-MOUND px; "
                       "X is what is behind him, rendered, not reasoned about",
           "not_a_pass": "a contrast is handed back, the picture decides",
           "rows": {}, "errors": []}
    for arm in ARMS:
        base = os.path.join(ROOT, KEY + arm)
        row = {"dir": base, "views": {}}
        if not os.path.isdir(base):
            rep["errors"].append("%s: arm directory missing" % arm)
            rep["rows"][arm] = row
            continue
        for v in VIEWS:
            ps = {t: os.path.join(base, "%s_%s.png" % (t, v)) for t in ("B", "X", "Mo")}
            missing = [t for t, p in ps.items() if not os.path.isfile(p)]
            if missing:
                rep["errors"].append("%s %s: missing %s" % (arm, v, ",".join(sorted(missing))))
                continue
            B, X, Mo = (load(ps[t]) for t in ("B", "X", "Mo"))
            if not (B.shape == X.shape == Mo.shape):
                rep["errors"].append("%s %s: shape mismatch B/X/Mo" % (arm, v))
                continue
            cell = {}
            for lab, W in RUNGS:
                b, x, mo = box(B, W), box(X, W), box(Mo, W)
                alone = mo[:, :, 3] > EPS
                n_alone = int(alone.sum())
                changed = np.abs(b - x).max(axis=2) > EPS
                # *** THE FRONTMOST TEST, AND THE FIRST VERSION OF THIS FILE
                # *** GOT IT WRONG IN A WAY THAT INVENTED A FAULT.
                # `changed & alone` is _backread's rule and it is right for
                # _backread's question. It is NOT right for this one. Hiding
                # the man also changes pixels where the MOUND IS IN FRONT OF
                # HIM, because he was shadowing or occluding ambient on it -
                # by one to three parts in 255, which clears EPS. Those pixels
                # then arrived in the on-mound column with a tiny dL and read
                # as "the man is indistinguishable from his mound". They are
                # not a contrast failure, they are the mound. On the collier's
                # side view they were 1701 of 3548 - just under half the
                # evidence - and a soot sweep sized against them would have
                # been sized against a shadow.
                # The honest rule asks which of the two the pixel actually
                # LOOKS like, and lets the renderer keep doing the depth: the
                # man is frontmost where B is nearer his own render than it is
                # to the render without him.
                dm = np.abs(b - mo).max(axis=2)
                dx = np.abs(b - x).max(axis=2)
                seen = alone & changed & (dm < dx)
                behind = x[:, :, 3] > EPS
                on_mound = seen & behind
                on_air = seen & ~behind
                d = np.abs(luma(b) - luma(x))
                # the px floor scales with the rung, or the 360p cell would be
                # red by arithmetic on a body that is fine at full size
                floor = max(12, int(300 * (W / 760.0) ** 2))
                c = dict(man_alone_px=n_alone,
                         man_seen_px=int(seen.sum()),
                         on_mound_px=int(on_mound.sum()),
                         on_air_px=int(on_air.sum()),
                         px_floor=floor)
                c["on_air_frac"] = (round(c["on_air_px"] / float(c["man_seen_px"]), 4)
                                    if c["man_seen_px"] else None)
                c["on_mound"] = stats(d, on_mound, floor)
                # THE OTHER HALF OF THE LEDGER, ADDED THE SAME HOUR THE FIRST
                # SWEEP CAME BACK. A value move that darkens the man to lift
                # him off his mound also darkens him against the PANE, and on
                # this body 90% of his boundary is pane, not mound. Reporting
                # only the on-mound column would have let a change that helps
                # one tenth of his outline and hurts nine tenths read as a win.
                c["on_air"] = stats(d, on_air, floor)
                cell[lab] = c
                if lab == "full":
                    if n_alone < 500:
                        rep["errors"].append("%s %s: man-alone mask %d px - the "
                                             "split grabbed nothing" % (arm, v, n_alone))
                    if "red" in c["on_mound"]:
                        rep["errors"].append("%s %s full: %s"
                                             % (arm, v, c["on_mound"]["red"]))
            row["views"][v] = cell
        rep["rows"][arm] = row
    # RED ON EMPTY, both shapes of it
    got = [c for r in rep["rows"].values() for c in r["views"].values()]
    if not got:
        rep["errors"].append("no views measured - a run over zero views is RED")
    else:
        means = [c["full"]["on_mound"].get("mean") for c in got
                 if "full" in c and "mean" in c["full"]["on_mound"]]
        if means and all(m == 0.0 for m in means):
            rep["errors"].append("dL is identically zero on every view - the "
                                 "A/B did not take, or the split hid nothing")
    rep["ok"] = not rep["errors"]
    out = os.path.join(ROOT, "_brownread.json")
    os.makedirs(ROOT, exist_ok=True)
    json.dump(rep, open(out, "w"), indent=1)
    print(json.dumps(rep, indent=1))
    sys.exit(0 if rep["ok"] else 1)


main()
