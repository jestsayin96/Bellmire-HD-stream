"""_moulder_glow_ab - WHY DOES AN AUTHORED sat 0.895 POUR RENDER AT sat 0.349?

_moulder_read measured the Moulder's pass-1 pour at mean (0.851, 0.694, 0.554),
saturation 0.349, hue 28.3 deg - tan, in all three views, which is what the
picture says too. The authored colour is (1.000, 0.425, 0.105), saturation
0.895. So nearly two thirds of the saturation is lost between the material and
the frame, and the question this file answers is WHICH DIAL LOSES IT.

The lane has met this twice before and both times the answer was the same
shape: the Dyer's weld clipped to CREAM at strength 2.30 and the Greener's
charcoal bed came back BEIGE until it went deeper and cooler in strength. An
emissive pushed up the view transform's shoulder desaturates - white is where
every hue ends - so STRENGTH buys brightness by spending colour.

The sweep is strength x hue, one render each, measured by the same with/without
instrument. Two numbers decide it and both are reported:
  sat                      - does it read as metal at heat rather than as wood
  share_in_frame_top1pct   - is it still the brightest thing in the frame
A pour that is deeply coloured and no longer the brightest thing has stopped
being a pour, so the second number is a guard against winning the first one by
turning the light off.

  blender -b -noaudio -P tools/art/_moulder_glow_ab.py -- --repo <repo>
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
ARMS = [
    ("a_ship",     (1.000, 0.425, 0.105), 1.60),
    ("b_greener",  (1.000, 0.265, 0.035), 1.45),
    ("c_deep110",  (1.000, 0.180, 0.020), 1.10),
    ("d_deep080",  (1.000, 0.120, 0.012), 0.80),
    ("e_greener09", (1.000, 0.265, 0.035), 0.90),
    ("f_mid130",   (1.000, 0.210, 0.025), 1.30),
]


def _front(tmp, tag, objs, info):
    """Render the three views and hand back THE FRONT ONE, renamed.

    *** THIS FUNCTION EXISTS BECAUSE THE FIRST VERSION OF THIS SWEEP WAS A
    *** LYING INSTRUMENT AND THE NUMBERS SAID SO BEFORE I DID. ***
    It took A from the front render, then zeroed the emission and called
    bpy.ops.render.render directly for B - but render_views leaves the camera
    on the LAST view it shot, which is the side. So B was a SIDE view of the
    body differenced against a FRONT view of it, 129,023 px "moved" where the
    honest figure is about 5,700, and every one of the six arms came back
    identical to three decimals. A sweep in which the independent variable
    changes nothing is not a flat result, it is an instrument measuring
    something else, and that is the only reason it was caught.
    """
    written, eng, cam = G.render_views(objs, "ab", tmp, 700, 980, info)
    src = [p for p in written if os.path.basename(p).startswith("front")][0]
    dst = os.path.join(tmp, "front_%s.png" % tag)
    if os.path.exists(dst):
        os.remove(dst)
    os.rename(src, dst)
    return dst


def one(repo, name, rgb, strength, tmp):
    G.purge()
    M.OVERRIDE["moulder"]['glow'] = (rgb, strength)
    objs, info = MG.build_miniboss("moulder")
    A = G.read_png(_front(tmp, name + "_lit", objs, info))[..., 0:3].copy()
    hit = 0
    for mat in bpy.data.materials:
        if "glow" in mat.name and mat.name.startswith("moulder") and mat.use_nodes:
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
    mask = d > SRC
    n = int(mask.sum())
    if n < 200 or hit == 0:
        return {"arm": name, "moved_px": n, "nodes_zeroed": hit,
                "verdict": "RED - measured nothing, this row means nothing"}
    px = A[mask]
    mean = px.mean(axis=0)
    h, s, v = colorsys.rgb_to_hsv(*[float(c) for c in mean])
    lum = A[..., 0] * 0.2126 + A[..., 1] * 0.7152 + A[..., 2] * 0.0722
    thr = float(np.quantile(lum, 0.99))
    au = colorsys.rgb_to_hsv(*rgb)
    return {"arm": name, "authored_rgb": list(rgb), "strength": strength,
            "authored_sat": round(au[1], 4), "moved_px": n, "nodes_zeroed": hit,
            "lit_px": int((d > 0.02).sum()),
            "mean_rgb": [round(float(c), 4) for c in mean],
            "sat": round(s, 4), "hue_deg": round(h * 360.0, 1),
            "val": round(v, 4),
            "sat_kept": round(s / max(1e-6, au[1]), 4),
            "share_in_frame_top1pct": round(float((lum[mask] >= thr).mean()), 4)}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    args = ap.parse_args(argv)
    tmp = os.path.join(args.repo, "renders", "art", "minibosses", "_moulder_ab")
    os.makedirs(tmp, exist_ok=True)
    rows = [one(args.repo, nm, rgb, st, tmp) for nm, rgb, st in ARMS]
    out = os.path.join(args.repo, "renders", "art", "minibosses", "_moulder_glow_ab.json")
    with open(out, "w") as f:
        json.dump({"rows": rows, "src": SRC}, f, indent=1)
    print("GLOW_AB " + json.dumps(rows))


if __name__ == "__main__":
    main()
