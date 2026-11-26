"""_ol_eyeablate.py - CAN THE VIEWER SEE AN EYE FROM BEHIND THE OVERLOOKER?

I looked at `_ol_back_head.png` and there is a pale sliver at the edge of the
skull in the BACK view. The wrong way to answer what it is worth is to measure
how many pixels of eye geometry exist - that is the pass-11 fault of 17 Nov
exactly: `mask_of` rendered a group ALONE and answered how BIG it was while the
honest answer to "can it be seen" was ZERO. Rendering the eyes alone here would
report two bright spheres from every angle including from inside the skull.

SO THIS ASKS THE VIEWER'S QUESTION. One camera, two renders - the body WITH its
eyes and the same body with the eye mesh hidden - and the count is the pixels
THAT MOVED. The renderer does the occlusion and the number cannot be larger
than what a viewer can actually see.

RED ON EMPTY: if the two frames are byte-identical the eyes contribute nothing
through that camera and the result is 0, printed as such and not as a pass. A
difference computed over a blank pair is REFUSED, not scored.

  blender -b -noaudio -P tools/art/_ol_eyeablate.py -- --repo <repo>
"""
import os
import sys
import json
import argparse

import bpy
import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibossgen as MBG    # noqa: E402

KEY = "overlooker"
VIEWS = (("front", 0.0, 12.0), ("side", 90.0, 11.0), ("back", 180.0, 12.0))
A_EPS = 2.0 / 255.0
D_EPS = 6.0 / 255.0          # a channel move a viewer could notice at all


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--res", default="700x980")
    args = ap.parse_args(argv)
    resx, resy = (int(x) for x in args.res.split("x"))
    outdir = os.path.join(args.repo, "renders", "art", "minibosses", "_ol_eyeablate")
    os.makedirs(outdir, exist_ok=True)

    G.purge()
    objs, info = MBG.build_miniboss(KEY)
    # the eyes are the ONLY 'glow' geometry on this body (the builder says so in
    # terms: "WHAT IS PALE: the pointing forearm and the mitt. The head has no
    # pale at all"), so the glow mesh IS the eye pair. Asserted, not assumed.
    # FIRST TRY WAS WRONG AND THE GUARD CAUGHT IT, which is the only reason
    # this file is correct: I selected on the MATERIAL name and got zero, so
    # the harness refused to score instead of silently ablating nothing and
    # reporting "the eyes contribute 0 pixels" - which is the exact shape of a
    # green number that means nothing. The merged mesh is named for its slot.
    eyes = [o for o in objs if o.name.endswith("_glow")]
    rep = {"ok": True, "errors": [], "views": {},
           "eye_objs": [o.name for o in eyes],
           "all_objs": [o.name for o in objs]}
    if len(eyes) != 1:
        rep["ok"] = False
        rep["errors"].append(
            "expected exactly one glow mesh to ablate, found %d - the "
            "assumption that glow == the eye pair is NOT safe, refusing to "
            "score" % len(eyes))
        print(json.dumps(rep, indent=1))
        sys.exit(2)

    # THE SECOND THING THIS HARNESS GOT WRONG, AND IT REPORTED A CLEAN 100%.
    # My first version called render_views TWICE INTO THE SAME SCENE. That
    # function ADDS a key/fill/rim rig and a camera every call, so the second
    # pass was lit by two rigs and every lit pixel on the body changed value.
    # The number that came back was "the eye pair moves 100.0% of the body",
    # which is not a small error - it is the instrument measuring itself. A
    # harness that can return a figure like that must not be allowed to return
    # it quietly, so the scene is now TORN DOWN AND REBUILT between the two
    # renders, and the contamination guard below refuses any result where the
    # move is too large to be the thing that was ablated.
    saved = G.VIEWS
    on = os.path.join(outdir, "on")
    off = os.path.join(outdir, "off")
    os.makedirs(on, exist_ok=True)
    os.makedirs(off, exist_ok=True)
    try:
        G.VIEWS = VIEWS
        G.render_views(objs, KEY, on, resx, resy, info)
        G.purge()
        objs2, info2 = MBG.build_miniboss(KEY)
        eyes2 = [o for o in objs2 if o.name.endswith("_glow")]
        if len(eyes2) != 1:
            rep["ok"] = False
            rep["errors"].append("rebuild produced %d glow meshes, refusing"
                                 % len(eyes2))
            print(json.dumps(rep, indent=1))
            sys.exit(2)
        for o in eyes2:
            o.hide_render = True
        G.render_views(objs2, KEY, off, resx, resy, info2)
    finally:
        G.VIEWS = saved

    for vname, _, _ in VIEWS:
        A = G.read_png(os.path.join(on, vname + ".png"))
        B = G.read_png(os.path.join(off, vname + ".png"))
        if not ((A[:, :, 3] > A_EPS).any() and (B[:, :, 3] > A_EPS).any()):
            rep["ok"] = False
            rep["errors"].append("RED %s: one of the ablation pair is BLANK - "
                                 "a difference over a blank pair is refused" % vname)
            continue
        d = np.abs(A - B).max(axis=2)
        moved = int((d > D_EPS).sum())
        body = int((A[:, :, 3] > A_EPS).sum())
        # CONTAMINATION GUARD. Two eyes 0.048 m across on a 2.40 m body cannot
        # legitimately change a fifth of the rendered body. Anything above that
        # means the pair of frames differs for a reason that is not the
        # ablation - a second lamp rig, a moved camera, a rebuilt mesh - and
        # the honest output is a REFUSAL, not a large impressive number.
        if moved > 0.20 * body:
            rep["ok"] = False
            rep["errors"].append(
                "RED %s: %d px moved on a %d px body (%.1f%%) - an eye pair "
                "cannot do that. The frames differ for some reason other than "
                "the ablation; result REFUSED, not scored."
                % (vname, moved, body, 100.0 * moved / max(1, body)))
        rep["views"][vname] = {
            "moved_px": moved,
            "body_px": body,
            "moved_pct_of_body": round(100.0 * moved / max(1, body), 3),
            # and at the 360p rung the player actually sees: 700 -> 160 is
            # 1/4.375 linear, so ~1/19 of the pixels. Reported, not inferred.
            "moved_px_at_160_rung_est": round(moved * (160.0 / resx) ** 2, 1),
        }
    print(json.dumps(rep, indent=1))
    with open(os.path.join(outdir, "_eyeablate.json"), "w") as f:
        json.dump(rep, f, indent=1)
    if not rep["ok"]:
        sys.exit(2)


main()
