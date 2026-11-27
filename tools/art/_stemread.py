"""_stemread.py - DOES THE BUNDLE READ AS COMBED REED, OR AS A HANDFUL OF
SAWN DOWELS?

  blender -b -noaudio -P tools/art/_stemread.py -- --repo <W5> --tags _p9a,_p9d

WHY THIS EXISTS. The team lead looked at `_cuevalue/_p8_sheet_side_zoom.png`
and wrote a fault that NO number in this body's register or in `_cuevalue.py`
can reach: "the stems are smooth hexagonal dowels". `_cuevalue.py` says so
itself, in its own docstring - it measures VALUE and "whether either mass
READS AS WHAT IT IS ... is answered by looking, and by nothing here". This
file does not replace looking. It makes ONE part of that fault countable so
an A/B can be judged on something other than my own impression of my own work.

*** IT MEASURES TWO CAUSES IN TWO DIFFERENT PLACES, ON PURPOSE. ***
Opening the pass-8 zoom there are two independent reasons the bundle reads as
dowelling, and a single score would have let a fix for one hide a miss on the
other:
  (A) GAUGE, measured in the MIDDLE of the bundle. Seven fat stems give the
      eye a few wide crowns. Combed reed gives it many fine ones. Counted as
      CROWNS PER 100 PX of footprint width, which is scale-free, so it cannot
      be moved by the bundle merely being drawn bigger.
  (B) THE CUT END, measured in the END ZONES only. `tube(caps=True)` closes
      each stem with a flat n-gon, and a flat facet square to the camera is a
      large patch of NEARLY IDENTICAL luma. A sawn dowel has one; a cut straw
      has none. Counted as the largest connected near-constant-luma patch as
      a fraction of the end-zone footprint.

HOW IT FINDS THE REED - THE VIEWER'S QUESTION, NOT A MASK RENDERED ALONE.
It reads the pair `_cuevalue.py` already writes through ONE LOCKED CAMERA:
    B      thatcher<tag>_<view>.png      the frame that ships
    nocue  _tmp<tag>/_nocue_<view>.png   the same frame, `bone` hidden
The footprint is where those two differ: the pixels a viewer would LOSE if
the reed vanished, i.e. where the reed is the front-most thing. Rendering the
reed alone would answer how BIG it is and say nothing about whether it can be
SEEN - that is this lane's `head_glow_px: 156` fault, shipped beside the
sentence "the head now has no face at all", and it is not repeated here.

THE BAND IS DERIVED EVERY RUN, NEVER FIXED. The middle and end zones are cut
from the footprint's OWN principal axis, recomputed per view per arm. A zone
fixed at the bundle's pass-8 address is the `_bg_sil_runs.py` v1 fault - an
instrument that cannot follow the thing it is measuring - and a change that
moved the bundle would then be scored on empty air.

AND IT GOES RED ON EMPTY. A crown count over no rows, or a flat-patch
fraction over no end-zone pixels, reads green and means nothing. Under the
floors below it is an ERROR and not a pass.

WHAT THIS FILE CANNOT SEE, SAID PLAINLY, BECAUSE THAT IS THE HABIT THAT SAVED
THIS BODY TWICE:
  - It cannot see whether the stems look like REED as opposed to any other
    fine fibre - rope, wire and a wheat sheaf all score well here.
  - It counts crowns from SHADING, so a change that separates stems
    geometrically but lights them flat will not move it, and a change that
    only adds noise to a smooth tube WILL move it. A number going up is not
    by itself a fix; the picture is the evidence and the number is the
    suspect.
  - It says nothing about the three other open faults on this body (the face,
    the leggett, the lap/yealm value on the side view).
"""
import os
import sys
import json
import argparse

import bpy  # noqa: F401  (run under Blender for G.read_png)
import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402

VIEWS = ("front", "side", "back")

# floors - under these the cell is an ERROR, not a pass
MIN_FOOT = 500
MIN_ROWS = 20
MIN_ENDZONE = 300

DIP = 0.030        # luma prominence a trough needs to split two crowns
FLAT = 0.004       # luma window that counts as "the same flat facet"
END_FRAC = 0.12    # fraction of the axis at each end that is the cut end
MID_LO, MID_HI = 0.30, 0.70


def _luma(a):
    return 0.2126 * a[:, :, 0] + 0.7152 * a[:, :, 1] + 0.0722 * a[:, :, 2]


def _crowns(vals):
    """Prominence-based crown count along one run of luma samples.

    A crown is a local maximum separated from the next by a trough at least
    DIP below the lower of the two. That is the eye's test for "two stems"
    rather than "one wide stem", and it ignores gentle shading across a
    single round surface, which is exactly what must NOT count.
    """
    n = len(vals)
    if n < 3:
        return 0
    peaks = 0
    last_peak = None
    run_min = None
    for i in range(n):
        v = vals[i]
        if last_peak is None:
            if run_min is None or v > run_min:
                pass
            last_peak = v
            run_min = v
            peaks = 1
            continue
        if v > last_peak:
            # climbing: if we came up out of a deep enough trough, new crown
            if run_min is not None and (last_peak - run_min) >= DIP \
                    and (v - run_min) >= DIP:
                peaks += 1
                run_min = v
            last_peak = v
        else:
            if run_min is None or v < run_min:
                run_min = v
            if (last_peak - v) >= DIP:
                last_peak = v
    return peaks


def _components(mask):
    """Largest 4-connected component in a boolean mask. Pure BFS - Blender
    has numpy and no scipy, and the end zone is a few thousand pixels."""
    h, w = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    best = 0
    ys, xs = np.nonzero(mask)
    for sy, sx in zip(ys.tolist(), xs.tolist()):
        if seen[sy, sx]:
            continue
        stack = [(sy, sx)]
        seen[sy, sx] = True
        size = 0
        while stack:
            y, x = stack.pop()
            size += 1
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = y + dy, x + dx
                if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] \
                        and not seen[ny, nx]:
                    seen[ny, nx] = True
                    stack.append((ny, nx))
        if size > best:
            best = size
    return best


def measure(outdir, tag, view, errs):
    key = "thatcher"
    pb = os.path.join(outdir, "%s%s_%s.png" % (key, tag, view))
    pn = os.path.join(outdir, "_tmp%s" % tag, "_nocue_%s.png" % view)
    for p in (pb, pn):
        if not os.path.exists(p):
            errs.append("%s/%s: missing %s - nothing was measured"
                        % (tag, view, os.path.basename(p)))
            return None
    B = G.read_png(pb)
    N = G.read_png(pn)
    if B.shape != N.shape:
        errs.append("%s/%s: frame pair differs in shape - the camera moved "
                    "between the two builds and the footprint is meaningless"
                    % (tag, view))
        return None
    lb, ln = _luma(B), _luma(N)
    # the reed is the FRONT-MOST thing wherever the two frames disagree
    foot = (np.abs(lb - ln) > (2.0 / 255.0)) | \
           (np.abs(B[:, :, 3] - N[:, :, 3]) > (2.0 / 255.0))
    nfoot = int(foot.sum())
    if nfoot < MIN_FOOT:
        errs.append("%s/%s: reed footprint is %d px (floor %d) - the bundle "
                    "is not front-most anywhere and a crown count over no "
                    "pixels is not a pass" % (tag, view, nfoot, MIN_FOOT))
        return dict(foot_px=nfoot, red="footprint under floor")

    ys, xs = np.nonzero(foot)
    pts = np.stack([xs.astype(np.float64), ys.astype(np.float64)], 1)
    c = pts.mean(0)
    u, s, vt = np.linalg.svd(pts - c, full_matrices=False)
    axis = vt[0]                       # the bundle's own screen direction
    proj = (pts - c) @ axis
    lo, hi = proj.min(), proj.max()
    span = max(1e-9, hi - lo)
    t = (proj - lo) / span

    # ---- (A) GAUGE, in the MIDDLE of the bundle only
    midsel = (t >= MID_LO) & (t <= MID_HI)
    midmask = np.zeros_like(foot)
    midmask[ys[midsel], xs[midsel]] = True
    rows = []
    for y in range(midmask.shape[0]):
        rx = np.nonzero(midmask[y])[0]
        if rx.size < 8:
            continue
        # split into maximal contiguous x-runs; a crown count across a gap
        # would count two different parts of the bundle as one run
        brk = np.nonzero(np.diff(rx) > 1)[0]
        segs = np.split(rx, brk + 1)
        tot_c, tot_w = 0, 0
        for sgm in segs:
            if sgm.size < 8:
                continue
            tot_c += _crowns(lb[y, sgm].tolist())
            tot_w += int(sgm.size)
        if tot_w >= 8:
            rows.append((tot_c, tot_w))
    if len(rows) < MIN_ROWS:
        errs.append("%s/%s: only %d usable rows in the mid band (floor %d) - "
                    "the gauge number would be computed over almost nothing"
                    % (tag, view, len(rows), MIN_ROWS))
        return dict(foot_px=nfoot, red="mid rows under floor",
                    rows=len(rows))
    cr = sum(r[0] for r in rows)
    wd = sum(r[1] for r in rows)
    crowns_per_row = cr / float(len(rows))
    crowns_per_100 = 100.0 * cr / float(max(1, wd))

    # ---- (B) THE CUT END, in the END ZONES only
    endsel = (t <= END_FRAC) | (t >= (1.0 - END_FRAC))
    endmask = np.zeros_like(foot)
    endmask[ys[endsel], xs[endsel]] = True
    nend = int(endmask.sum())
    if nend < MIN_ENDZONE:
        errs.append("%s/%s: end zone is %d px (floor %d) - the flat-plate "
                    "number would be computed over almost nothing"
                    % (tag, view, nend, MIN_ENDZONE))
        return dict(foot_px=nfoot, red="end zone under floor",
                    crowns_per_100=round(crowns_per_100, 3))
    q = np.round(lb / FLAT).astype(np.int32)
    biggest = 0
    for lev in np.unique(q[endmask]):
        m = endmask & (q == lev)
        if int(m.sum()) <= biggest:
            continue        # cannot beat the best even if fully connected
        biggest = max(biggest, _components(m))
    flat_frac = biggest / float(nend)

    return dict(foot_px=nfoot,
                mid_rows=len(rows),
                crowns_per_row=round(crowns_per_row, 3),
                crowns_per_100=round(crowns_per_100, 3),
                end_px=nend,
                flat_patch_px=int(biggest),
                flat_frac=round(float(flat_frac), 4))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--tags", required=True)
    ap.add_argument("--out", default="")
    args = ap.parse_args(argv)
    outdir = os.path.join(args.repo, "renders", "art", "minibosses",
                          "_cuevalue")
    errs = []
    rep = {"asks": "(A) crowns per 100 px of reed footprint across the MIDDLE "
                   "of the bundle - is the eye given many fine stems or a few "
                   "fat poles; (B) largest connected near-constant-luma patch "
                   "in the CUT-END zones as a fraction of them - a flat sawn "
                   "cap, or not",
           "method": "with/without through the one locked camera _cuevalue.py "
                     "already writes; zones derived per run from the "
                     "footprint's own principal axis",
           "cannot_see": "whether it reads as REED specifically; a flat-lit "
                         "geometric fix; and the body's other open faults. "
                         "The picture is the evidence, this is the suspect.",
           "floors": {"foot_px": MIN_FOOT, "mid_rows": MIN_ROWS,
                      "end_px": MIN_ENDZONE},
           "arms": {}, "errors": errs}
    for tag in args.tags.split(","):
        tag = tag.strip()
        if not tag:
            continue
        rep["arms"][tag] = {}
        for v in VIEWS:
            rep["arms"][tag][v] = measure(outdir, tag, v, errs)
    rep["verdict"] = "RED" if errs else "GREEN"
    out = args.out or os.path.join(outdir, "_stemread.json")
    with open(out, "w") as fh:
        json.dump(rep, fh, indent=1)
    print("STEMREAD " + json.dumps(rep))


if __name__ == "__main__":
    main()
