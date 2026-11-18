"""THE KNOB INSTRUMENT, PASS 13 - THE CORE IS NOW DERIVED, NOT TYPED.

PASS 12 FIXED THE WINDOW AND LEFT THE CORE GUESSED, AND THAT IS WHY THE SIDE
VIEW DID NOT MOVE. Pass 11's lesson was a window I typed from a guess; pass 12
derived the window from the moved mask and I stopped there. Inside that window
the CORE was still typed by hue - `sat > 0.10 and warm > 0.06` - and on the
side view the warm back rim pushes the dark blue-grey wool straight past both
thresholds. Measured on the shipped renders: of 9,657 side "core" pixels only
1,335 (13.8%) are pixels the knob edit touched; the other 8,322 are warm-lit
robe and wall, and they are just as warm as the knob (0.206 vs 0.203). So
`core_lum_mean` on the side was a measurement of the ROBE. On the front the
same mask happens to land on the knob alone, which is why the front moved
0.0431 -> 0.3631 and the side sat still at 0.1225 -> 0.1217. The side number
was never about the knob.

TWO MORE FAULTS IN THE OLD NUMBER, both in `worst_local_gap = abs(core_mean -
ring_max)`:
  - abs() DISCARDS THE SIGN, so "the knob is darker than its ground" and "the
    ground is darker than the knob" report the same figure. On the side the
    ground is BRIGHTER than the core; on the front it is darker. The metric
    could not tell those apart, and an outline's whole job is to flip that sign.
  - ring_max IS AN EXTREMUM over ~900 px. One surviving bright pixel pins it,
    so it can never show partial improvement. It did not say "the worst spot is
    untouched"; it said "at least one bright pixel remains", which was true
    before and after and means nothing on its own.

AND ONE THE NUMBERS COULD NOT HAVE TOLD ME - I FOUND IT BY LOOKING AT THE MASK.
32% of the side's moved pixels (886 of 2,801) are not on the knob at all: they
are a patch of robe ~50 px to the right that DARKENED SLIGHTLY (0.585 -> 0.525)
when the knob went dark - the knob's cast response on the surface beside it.
Folding that into "the knob" drags the knob's mean up with bright wall. So the
moved mask alone is not the knob either. Here the components are split, the
ones the edit actually acted on (|dlum| >= ACTED) are the knob, and everything
else is reported as COLLATERAL by name rather than averaged in silently.

THE GROUND is taken from pixels that did NOT move, so it is the same ground in
both images and the delta is attributable to the knob and not to the ground.
RED ON EMPTY, and loud when the collateral is large enough to have skewed the
old answer.
"""
import os
import sys
import json
from collections import deque

import bpy
import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402

MOVE_T = 0.02     # an A/B pixel counts as moved past this
ACTED = 0.15      # a component the edit acted on, by luminance
ACTED_A = 0.25    # ...or by ALPHA: a surface that APPEARED is acted on too
NEAR = 0.10       # ground this close to the knob cannot be told from it
COLLATERAL_WARN = 0.25


def lum(a):
    return 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]


def grow(m, n=1):
    out = m.copy()
    for _ in range(n):
        g = out.copy()
        g[1:, :] |= out[:-1, :]
        g[:-1, :] |= out[1:, :]
        g[:, 1:] |= out[:, :-1]
        g[:, :-1] |= out[:, 1:]
        out = g
    return out


def label(m):
    """4-connected components. No scipy in Blender, so BFS."""
    lab = np.zeros(m.shape, np.int32)
    n = 0
    for y, x in zip(*np.nonzero(m)):
        if lab[y, x]:
            continue
        n += 1
        lab[y, x] = n
        q = deque([(y, x)])
        while q:
            cy, cx = q.popleft()
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = cy + dy, cx + dx
                if (0 <= ny < m.shape[0] and 0 <= nx < m.shape[1]
                        and m[ny, nx] and not lab[ny, nx]):
                    lab[ny, nx] = n
                    q.append((ny, nx))
    return lab, n


def side(li_c, li_g):
    """The viewer's question: can the ground be told from the knob, and which
    way round. SIGNED - an outline's job is to flip this sign negative."""
    cm = float(li_c.mean())
    near = np.abs(li_g - cm) < NEAR
    return {"knob_lum_mean": round(cm, 4),
            "knob_p05": round(float(np.percentile(li_c, 5)), 4),
            "knob_p95": round(float(np.percentile(li_c, 95)), 4),
            "ground_lum_mean": round(float(li_g.mean()), 4),
            "ground_p05": round(float(np.percentile(li_g, 5)), 4),
            "ground_p95": round(float(np.percentile(li_g, 95)), 4),
            "signed_gap": round(cm - float(li_g.mean()), 4),
            "indistinguishable_px": int(near.sum()),
            "indistinguishable_frac": round(float(near.sum()) / len(li_g), 4),
            "ground_brighter_frac": round(float((li_g > cm).sum()) / len(li_g), 4)}


def bulb(B, lB, acted, mv):
    """THE RESIDUAL THE COLLARS DO NOT COVER. The outline darkened the collars
    above and below the knob; the knob's pale BULB between them did not move at
    all, so no A/B-derived instrument looks at it - and on the side view it is
    the bulb, not the collars, that sits against pale wall. Measured here
    because the collar numbers cannot see it and the eye can. RED ON EMPTY: a
    view where the bulb has no eligible ground returns a reason, not a pass."""
    ys, xs = np.nonzero(acted)
    box = np.zeros_like(mv)
    box[ys.min():ys.max() + 1, xs.min():xs.max() + 1] = True
    opB = B[..., 3] > 0.5
    cand = box & opB & (~mv) & (lB > 0.45)
    lb, n = label(cand)
    if n == 0:
        return {"EMPTY_NO_BULB": True}
    big = max(range(1, n + 1), key=lambda i: int((lb == i).sum()))
    bb = lb == big
    if int(bb.sum()) < 100:
        return {"EMPTY_BULB_TOO_SMALL": int(bb.sum())}
    ring = grow(bb, 3) & opB & (~grow(bb, 1)) & (~mv) & (~acted)
    if int(ring.sum()) < 20:
        return {"EMPTY_NO_GROUND": int(ring.sum()),
                "why": "the bulb is wholly enclosed by the collars and the "
                       "cloak on this view - there is no boundary to read"}
    c, g = lB[bb], lB[ring]
    cm = float(c.mean())
    near = np.abs(g - cm) < NEAR
    return {"bulb_px": int(bb.sum()), "ground_px": int(ring.sum()),
            "bulb_lum_mean": round(cm, 4),
            "ground_lum_mean": round(float(g.mean()), 4),
            "signed_gap": round(cm - float(g.mean()), 4),
            "indistinguishable_frac": round(float(near.sum()) / len(g), 4)}


def view(out, v):
    pb = os.path.join(out, "base_%s.png" % v)
    pk = os.path.join(out, "knob_%s.png" % v)
    if not (os.path.exists(pb) and os.path.exists(pk)):
        return {"SKIPPED_NO_RENDER": v}
    A, B = G.read_png(pb), G.read_png(pk)
    d = np.maximum(np.max(np.abs(A[..., :3] - B[..., :3]), axis=-1),
                   np.abs(A[..., 3] - B[..., 3]))
    mv = d > MOVE_T
    if int(mv.sum()) == 0:
        return {"RED": "nothing moved - the knob change is invisible on " + v}
    lA, lB = lum(A), lum(B)
    lab, n = label(mv)
    comps, acted, collateral = [], [], []
    for i in range(1, n + 1):
        m = lab == i
        sz = int(m.sum())
        if sz < 30:
            continue
        ys, xs = np.nonzero(m)
        c = {"px": sz, "bbox_yyxx": [int(ys.min()), int(ys.max()),
                                     int(xs.min()), int(xs.max())],
             "lum_base": round(float(lA[m].mean()), 4),
             "lum_knob": round(float(lB[m].mean()), 4)}
        c["dlum"] = round(c["lum_knob"] - c["lum_base"], 4)
        c["alpha_base"] = round(float(A[..., 3][m].mean()), 4)
        c["alpha_knob"] = round(float(B[..., 3][m].mean()), 4)
        c["dalpha"] = round(c["alpha_knob"] - c["alpha_base"], 4)
        # A COMPONENT THAT APPEARED IS THE KNOB EVEN IF ITS LUMINANCE BARELY
        # MOVED. My first pass-13 draft tested luminance alone, and the front
        # and back upper collar - alpha 0.13 -> 0.86, new geometry, plainly
        # part of the piece - fell out as "collateral" on a dlum of +0.14. I
        # caught that by LOOKING at the mask overlay, not from any number: the
        # collar was painted collateral-yellow in a picture where it is
        # obviously the knob. It is also exactly why the front and back
        # magnitudes were unstable under the threshold sweep and the side,
        # whose collars both moved in luminance, was not.
        c["acted"] = bool(abs(c["dlum"]) >= ACTED or abs(c["dalpha"]) >= ACTED_A)
        c["acted_by"] = ("lum" if abs(c["dlum"]) >= ACTED else "") + \
                        ("alpha" if abs(c["dalpha"]) >= ACTED_A else "")
        comps.append(c)
        (acted if c["acted"] else collateral).append((i, c))
    rep = {"view": v, "moved_px": int(mv.sum()), "components": comps,
           "acted_on_px": sum(c["px"] for _, c in acted),
           "collateral_px": sum(c["px"] for _, c in collateral),
           "collateral": [c for _, c in collateral]}
    rep["collateral_frac_of_moved"] = round(
        rep["collateral_px"] / max(1, int(mv.sum())), 4)
    if not acted:
        rep["RED"] = ("no component moved by %.2f lum or %.2f alpha - "
                      "nothing was acted on" % (ACTED, ACTED_A))
        return rep
    asm = np.zeros_like(mv)
    for i, _ in acted:
        asm |= (lab == i)
    opA, opB = A[..., 3] > 0.5, B[..., 3] > 0.5
    asm &= opB
    if int(asm.sum()) < 40:
        rep["RED"] = "assembly is %d px - too small to measure" % int(asm.sum())
        return rep
    ring = grow(asm, 3) & opA & opB & (~grow(asm, 1)) & (~mv)
    if int(ring.sum()) < 20:
        rep["RED"] = "ground ring is %d px - nothing to read the knob against" % int(ring.sum())
        return rep
    rep["assembly_px"] = int(asm.sum())
    rep["ground_px"] = int(ring.sum())
    rep["base"] = side(lA[asm], lA[ring])
    rep["knob"] = side(lB[asm], lB[ring])
    rep["delta_signed_gap"] = round(
        rep["knob"]["signed_gap"] - rep["base"]["signed_gap"], 4)
    rep["delta_indistinguishable_frac"] = round(
        rep["knob"]["indistinguishable_frac"]
        - rep["base"]["indistinguishable_frac"], 4)
    rep["bulb"] = bulb(B, lB, asm, mv)
    if rep["collateral_frac_of_moved"] >= COLLATERAL_WARN:
        rep["WARN_COLLATERAL"] = (
            "%.0f%% of the moved pixels are NOT the knob - a surface beside it "
            "responded. They are excluded here and listed under 'collateral'; "
            "any instrument that treats the moved mask as the knob is wrong on "
            "this view by that much."
            % (100 * rep["collateral_frac_of_moved"]))
    return rep


def main():
    repo = sys.argv[sys.argv.index("--") + 1]
    out = os.path.join(repo, "renders", "art", "minibosses", "_ab_beadle")
    rep = {"instrument": "pass13-derived-core",
           "note": ("core derived from the A/B's own acted-on components; "
                    "ground is unmoved pixels only; gap is SIGNED"),
           "views": {v: view(out, v) for v in ("side", "front", "back")}}
    print("GAP_JSON_BEGIN")
    print(json.dumps(rep))
    print("GAP_JSON_END")
    with open(os.path.join(out, "_knobgap.json"), "w") as fh:
        json.dump(rep, fh, indent=1)


main()
