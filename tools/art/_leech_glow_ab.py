"""_leech_glow_ab - CAN A VIEWER TELL THE BLOOD FROM THE BOWL IT SITS IN?

THE FAULT THIS WAS BUILT FOR, MEASURED BEFORE IT WAS BUILT. The Leech's pass-1
basin shipped at (1.00,0.17,0.11) strength 7.0 and front.png came back with a
SALMON disc. Sampled off that render:

    fill   (193,126,105)   sat 0.46
    brass  (168,132,110)   sat 0.35

Twenty-five levels apart in red and five in blue. The mechanic of this creature
is a LEVEL IN A BASIN, so a fill a viewer cannot tell from the basin is the
idea failing silently - which is the Comfitmaker's pass-3 fault in a new coat,
and I wrote that body's lesson into this one's override and then broke it with
my own colour choice: I picked BRASS, which is the same hue as blood.

WHY A SWEEP AND NOT A GUESS. Dropping the strength 7.0 -> 1.9 barely moved the
fill at all while it clearly moved the EYES, and a dial that changes one
emitter and not another is a thing to measure, not to turn again. The cause is
the view transform's shoulder: past the knee, more strength buys brightness by
spending colour, and BOTH 7.0 and 1.9 are past it.

THE TWO NUMBERS THAT DECIDE IT, and the second one is the one the Comfitmaker
never had:
  sat                - does the fill read as blood rather than as paint
  sep_from_dish      - max channel distance between the fill's mean colour and
                       the mean colour of the BRASS IMMEDIATELY AROUND IT. A
                       deeply saturated fill that still matches its dish has
                       not solved anything, so saturation alone cannot pass.

IT GOES RED ON EMPTY, by construction. The fill is found with the lane's proven
with/without instrument - render lit, zero the emission, render again through
THE SAME CAMERA, and count the pixels that MOVED - because `mask_of` renders a
group alone and answers how BIG a thing is, never whether it can be SEEN (the
pass-11 fault, 17 Nov). A row whose moved mask is empty, or whose surround ring
is empty, reports RED and carries no numbers: a metric computed over zero
pixels reads green and means nothing.

  blender -b -noaudio -P tools/art/_leech_glow_ab.py -- --repo <repo>
"""
import os
import sys
import json
import argparse
import colorsys

import bpy
import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402

SRC = 0.25
KEY = "leech"
# the basin is the far-LEFT zone of the front frame by construction (BAS_X is
# negative and the horns are the only other wide object, far right), so the
# moved mask is split on x to keep the EYES out of the fill's numbers. The
# split is reported so a later geometry change that crosses it is visible.
X_SPLIT = 0.40

ARMS = [
    ("a_pass1",    (1.000, 0.170, 0.110), 7.00),
    ("b_pass3",    (1.000, 0.120, 0.070), 1.90),
    ("c_deep110",  (1.000, 0.070, 0.035), 1.10),
    ("d_deep085",  (1.000, 0.045, 0.020), 0.85),
    ("e_deep060",  (1.000, 0.030, 0.012), 0.60),
    ("f_mid140",   (1.000, 0.090, 0.045), 1.40),
]


def _front(tmp, tag, objs, info):
    """Render the three views and hand back THE FRONT ONE, renamed.

    Straight out of _moulder_glow_ab, including the reason it exists:
    render_views leaves the camera on the LAST view it shot, so a B frame
    rendered by calling the operator directly is a SIDE view differenced
    against a FRONT one. Both frames go through render_views so both are
    front."""
    written, eng, cam = G.render_views(objs, "ab", tmp, 700, 980, info)
    src = [p for p in written if os.path.basename(p).startswith("front")][0]
    dst = os.path.join(tmp, "front_%s.png" % tag)
    if os.path.exists(dst):
        os.remove(dst)
    os.rename(src, dst)
    return dst


def _ring_around(mask, grow=9):
    """The surround: pixels within `grow` of the mask but not in it. Pure
    numpy - no scipy on this machine - by max-filtering with shifts."""
    g = mask.copy()
    for _ in range(grow):
        gg = g.copy()
        gg[1:, :] |= g[:-1, :]
        gg[:-1, :] |= g[1:, :]
        gg[:, 1:] |= g[:, :-1]
        gg[:, :-1] |= g[:, 1:]
        g = gg
    return g & ~mask


def one(name, rgb, strength, tmp):
    G.purge()
    M.OVERRIDE[KEY]['glow'] = (rgb, strength)
    objs, info = MG.build_miniboss(KEY)
    A = G.read_png(_front(tmp, name + "_lit", objs, info))[..., 0:3].copy()
    hit = 0
    for mat in bpy.data.materials:
        if "glow" in mat.name and mat.name.startswith(KEY) and mat.use_nodes:
            for n in mat.node_tree.nodes:
                for k in ("Strength", "Emission Strength"):
                    if k in n.inputs:
                        n.inputs[k].default_value = 0.0
                        hit += 1
                for k in ("Color", "Emission Color", "Base Color"):
                    if k in n.inputs:
                        try:
                            n.inputs[k].default_value = (0.0, 0.0, 0.0, 1.0)
                            hit += 1
                        except Exception:
                            pass
    B = G.read_png(_front(tmp, name + "_dark", objs, info))[..., 0:3]
    d = np.abs(A - B).max(axis=2)
    moved = d > SRC
    xs = np.arange(A.shape[1])[None, :] / float(A.shape[1])
    fill = moved & (xs < X_SPLIT)
    eyes = moved & (xs >= X_SPLIT)
    row = {"arm": name, "authored_rgb": list(rgb), "strength": strength,
           "nodes_zeroed": hit,
           "moved_px": int(moved.sum()), "fill_px": int(fill.sum()),
           "eye_px": int(eyes.sum())}
    if hit == 0 or row["fill_px"] < 200:
        row["verdict"] = "RED - the instrument measured nothing; this row carries no numbers"
        return row
    ring = _ring_around(fill, 9)
    # the surround must be the DISH, not the white background: drop anything
    # that is background-pale in all three channels.
    opaque = ~((A[..., 0] > 0.90) & (A[..., 1] > 0.90) & (A[..., 2] > 0.90))
    ring = ring & opaque
    if int(ring.sum()) < 200:
        row["verdict"] = "RED - no dish found around the fill; separation means nothing"
        return row
    fm = A[fill].mean(axis=0)
    rm = A[ring].mean(axis=0)
    fh, fs, fv = colorsys.rgb_to_hsv(*[float(c) for c in fm])
    rh, rs, rv = colorsys.rgb_to_hsv(*[float(c) for c in rm])
    au = colorsys.rgb_to_hsv(*rgb)
    sep = float(np.abs(fm - rm).max())
    row.update({
        "fill_rgb255": [round(float(c) * 255, 1) for c in fm],
        "dish_rgb255": [round(float(c) * 255, 1) for c in rm],
        "ring_px": int(ring.sum()),
        "sat": round(fs, 4), "dish_sat": round(rs, 4),
        "sat_gap": round(fs - rs, 4),
        "hue_deg": round(fh * 360.0, 1), "dish_hue_deg": round(rh * 360.0, 1),
        "val": round(fv, 4), "dish_val": round(rv, 4),
        "sep_from_dish": round(sep, 4),
        "sat_kept": round(fs / max(1e-6, au[1]), 4),
    })
    # THE BAR, stated before the numbers were seen: the fill must be clearly
    # more saturated than its dish AND clearly separated from it in colour.
    row["verdict"] = ("PASS" if (row["sat_gap"] >= 0.30 and sep >= 0.12)
                      else "FAIL")
    return row


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    args = ap.parse_args(argv)
    tmp = os.path.join(args.repo, "renders", "art", "minibosses", "_leech_ab")
    os.makedirs(tmp, exist_ok=True)
    keep = M.OVERRIDE[KEY]['glow']
    rows = [one(nm, rgb, st, tmp) for nm, rgb, st in ARMS]
    M.OVERRIDE[KEY]['glow'] = keep
    out = os.path.join(args.repo, "renders", "art", "minibosses",
                       "_leech_glow_ab.json")
    with open(out, "w") as f:
        json.dump({"rows": rows, "src": SRC, "x_split": X_SPLIT}, f, indent=1)
    print("LEECH_GLOW_AB " + json.dumps(rows))


if __name__ == "__main__":
    main()
