"""_moulder_read - DOES THE POUR READ AS MOLTEN METAL, OR AS A PALE STICK?

Pass 1 of the Moulder shipped a glow at (1.000, 0.425, 0.105) strength 1.60 and
in BOTH the front and the side render every emissive element - the pour stream,
the parting seam, the crucible mouth, the man's eyes - came back PALE TAN. A
viewer names that as wood, not as metal at pouring heat, and the whole idea of
this creature is that something is being poured right now.

THE INSTRUMENT ASKS THE VIEWER'S QUESTION AND LETS THE RENDERER DO THE DEPTH -
the lesson this lane learned the hard way at the Pressman (pass 11, 17 Nov):
rendering a group ALONE answers how BIG it is and says nothing about whether it
can be SEEN, and a `head_glow_px: 156` shipped beside the sentence "the head has
no face at all" because of it. So:

    A = the body as it ships
    B = the same body with the glow material's emission taken to zero
    moved = pixels that differ between A and B by more than EPS

`moved` is what the pour actually PUTS ON SCREEN. It cannot be fooled by
occlusion, it needs no object names, and it goes RED on zero - a metric computed
over no pixels reads green and means nothing.

WHAT IT MEASURES AND WHAT IT DOES NOT. It measures the COLOUR a viewer reads off
those pixels: mean saturation and hue in HSV, and the share of them that are
among the frame's brightest. It does NOT measure whether the pour is in a
sensible place or whether the shape reads - that is the picture's job, and the
picture is the evidence. When a number and a picture disagree, the picture wins.

  blender -b -noaudio -P tools/art/_moulder_read.py -- --repo <repo> [--key moulder]
"""
import os
import sys
import json
import math
import argparse
import colorsys

import bpy
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402

EPS = 0.02
SRC = 0.25         # above this the pixel IS the emissive surface, not
                    # something the emissive surface is lighting
MIN_MOVED = 200          # below this the instrument has measured nothing: RED


def kill_emission(key):
    """Take the glow material to black with zero emission. Returns what it
    touched, so a run that silently matched NOTHING cannot report a pass."""
    hit = []
    for mat in bpy.data.materials:
        if "glow" not in mat.name or not mat.name.startswith(key):
            continue
        if not mat.use_nodes:
            continue
        for n in mat.node_tree.nodes:
            for nm in ("Strength", "Emission Strength"):
                if nm in n.inputs:
                    n.inputs[nm].default_value = 0.0
                    hit.append(mat.name + "/" + n.name + "/" + nm)
            for nm in ("Color", "Emission Color", "Base Color"):
                if nm in n.inputs:
                    try:
                        n.inputs[nm].default_value = (0.0, 0.0, 0.0, 1.0)
                        hit.append(mat.name + "/" + n.name + "/" + nm)
                    except Exception:
                        pass
    return hit


def shoot(objs, info, outdir, tag, resx=700, resy=980):
    written, eng, cam = G.render_views(objs, info["title"], outdir, resx, resy, info)
    out = {}
    for p in written:
        v = os.path.splitext(os.path.basename(p))[0]
        q = os.path.join(outdir, "%s_%s.png" % (v, tag))
        if os.path.exists(q):
            os.remove(q)
        os.rename(p, q)
        out[v] = q
    return out


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--key", default="moulder")
    args = ap.parse_args(argv)
    key = args.key
    tmp = os.path.join(args.repo, "renders", "art", "minibosses", "_%s_read" % key)
    os.makedirs(tmp, exist_ok=True)
    rep = {"ok": True, "key": key, "views": {}, "errors": [], "eps": EPS,
           "src": SRC}

    G.purge()
    objs, info = MG.build_miniboss(key)
    lit = shoot(objs, info, tmp, "lit")
    touched = kill_emission(key)
    rep["emission_nodes_zeroed"] = touched
    if not touched:
        rep["ok"] = False
        rep["errors"].append("kill_emission matched NO material for key %r - the "
                             "B arm is identical to A by construction and every "
                             "number below would be a number about nothing" % key)
    dark = shoot(objs, info, tmp, "dark")

    for v in sorted(lit):
        A = G.read_png(lit[v])[..., 0:3]
        B = G.read_png(dark[v])[..., 0:3]
        d = np.abs(A - B).max(axis=2)
        # *** THE FIRST VERSION OF THIS INSTRUMENT MEASURED THE WRONG THING AND
        # *** THE NUMBER IS HOW I KNEW. It took every pixel that moved at all
        # *** and called that "the pour": 181,928 px of 686,000, a QUARTER of
        # *** the frame, for geometry that is four tubes about 2 cm across.
        # A pour does not only show itself, it LIGHTS the body around it, and
        # those lit pixels move by a little while the emissive surface itself
        # moves by a lot. Averaging the two together reported sat 0.0775 - the
        # colour of a dimly warmed dark body, not the colour of the pour - and
        # that average would have been a number about nothing, said beside a
        # sentence about something else. Same family as the Pressman's
        # head_glow_px, caught one step earlier this time.
        # So the two are SEPARATED and both are reported: `lit_px` is the
        # footprint of what the pour illuminates (a real and useful number),
        # `moved_px` is the emissive SURFACE, and only the surface is asked
        # what colour it is.
        lit_mask = d > EPS
        mask = d > SRC
        n = int(mask.sum())
        row = {"moved_px": n, "lit_px": int(lit_mask.sum()), "frame_px": int(mask.size),
               "src_threshold": SRC}
        if n < MIN_MOVED:
            row["verdict"] = "RED - the glow puts %d px on screen; it is not there" % n
            rep["ok"] = False
            rep["errors"].append("%s: moved_px %d < %d" % (v, n, MIN_MOVED))
        else:
            px = A[mask]
            mean = px.mean(axis=0)
            h, s, val = colorsys.rgb_to_hsv(*[float(c) for c in mean])
            hs = [colorsys.rgb_to_hsv(*[float(c) for c in q]) for q in px]
            lum = A[..., 0] * 0.2126 + A[..., 1] * 0.7152 + A[..., 2] * 0.0722
            thr = float(np.quantile(lum, 0.99))
            hot = float((lum[mask] >= thr).mean())
            row.update(mean_rgb=[round(float(c), 4) for c in mean],
                       hue_deg=round(h * 360.0, 1), sat=round(s, 4),
                       val=round(val, 4),
                       sat_median=round(float(np.median([q[1] for q in hs])), 4),
                       share_in_frame_top1pct=round(hot, 4))
            # A pour is metal at heat. Tan is what pass 1 shipped: sat ~0.3 at
            # hue ~30. The bar is stated here so the next seat can argue with a
            # number instead of with my taste.
            row["reads_as"] = ("MOLTEN" if (row["sat"] >= 0.55 and 8.0 <= row["hue_deg"] <= 34.0)
                               else "PALE/TAN - a viewer names this wood, not metal")
        rep["views"][v] = row

    out = os.path.join(args.repo, "renders", "art", "minibosses",
                       "_%s_read.json" % key)
    with open(out, "w") as f:
        json.dump(rep, f, indent=1)
    print("MOULDER_READ " + json.dumps(rep))


if __name__ == "__main__":
    main()
