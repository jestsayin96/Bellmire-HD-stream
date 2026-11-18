"""_rat_tally - CAN A VIEWER COUNT THE CATCH? Asked the viewer's way.

THE RATCATCHER'S WHOLE IDEA IS A NUMBER: five of twelve bays full, and the
seven empty ones are the half of the idea that says the party decides whether
it gets more. So the only acceptance test is whether the OCCUPANTS CAN BE
SEEN AND TOLD APART, per view.

THIS LANE HAS ALREADY SHIPPED THE WRONG VERSION OF THIS TEST AND IT IS WHY
THIS FILE IS WRITTEN THE WAY IT IS. At the Moulder's pass 11 I reported
`head_glow_px: 156` beside my own sentence "the head now has no face at all",
and both were true: a mask render of a group ALONE answers HOW BIG a thing is
and says nothing about whether it can be SEEN. The honest number was zero.

So this asks the VIEWER'S question: render the body WITH the occupants and
WITHOUT them through ONE camera, and count the pixels that MOVED. The renderer
does the depth; nothing here has to reason about occlusion. Two numbers:

  moved_px   - how much of the frame the catch actually owns
  components - how many SEPARATE moved blobs there are, which is the count a
               viewer can make. Five bundles that merge into one mass read as
               one thing, and moved_px alone would call that a pass.

THREE WAYS THIS INSTRUMENT COULD LIE, AND WHAT STOPS EACH:
  1. THE CAMERA MOVING BETWEEN A AND B. render_views derives the camera from
     the body's world bounds, so deleting geometry that touches the bounds
     re-frames the shot and EVERY pixel "moves" - the exact fault that made
     the Moulder's first glow sweep report 129,023 px of movement where the
     honest figure was 5,700. The occupants are interior, so the camera must
     be identical; it is ASSERTED equal and the run goes red if it is not.
  2. THE AUTHORED HEIGHT MOVING. build_miniboss normalises to CANON height,
     so if the deleted span reached the top or the floor the whole body would
     rescale. Asserted too.
  3. READING GREEN ON EMPTY. A view with zero moved pixels, or zero
     components, is RED. A metric computed over nothing reads clean and means
     nothing - the lesson off the gloves' centre-band at System 1.

  blender -b -noaudio -P tools/art/_rat_tally.py -- --repo <repo> [--tag pass1]
"""
import os
import sys
import json
import argparse

import bpy
import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402

KEY = "ratcatcher"
MIN_COMP = 40          # px. Below this is an antialias speck, not an occupant.
MOVE_EPS = 0.045       # linear rgb / alpha distance that counts as "moved"


def _build(drop_span=None):
    """Build the body, optionally with one named span filtered out."""
    G.purge()
    title, height, tint, aura, theme, idea, wear, line = M.CANON[KEY]
    P = M.BUILDERS[KEY]()
    items, vcols = P.items, getattr(P, "vcols", None)
    if drop_span:
        a, b = P.spans[drop_span]
        items = items[:a] + items[b:]
    # same material table the shipped body renders through - apply_overrides is
    # what minibossgen calls, so a colour measured here is the colour that ships
    body = tuple((c * 0.80) * 0.80 + a2 * 0.20 for c, a2 in zip(tint, aura))
    dull = 1.0 - 0.45 * wear
    body = tuple(c * dull + 0.010 * wear for c in body)
    rough = 0.34 + 0.40 * wear
    metal = 0.55 * (1.0 - wear) ** 1.4
    mats = {
        'body': __import__("lordlib").mat_solid(KEY + "_body", body, rough, metal),
        'dark': __import__("lordlib").mat_solid(KEY + "_dark",
                                                tuple(c * 0.16 + 0.012 for c in body), 0.74, 0.04),
        'bone': __import__("lordlib").mat_solid(KEY + "_bone",
                                                tuple((0.30 + c * 0.55) * dull for c in tint),
                                                rough * 0.9, 0.02),
        'glow': __import__("lordlib").mat_glow(KEY + "_glow",
                                               tuple(min(1.0, c / max(aura)) for c in aura), 3.2),
    }
    mats = M.apply_overrides(KEY, mats)
    objs = M.merge_objs(KEY, items, mats, vcols=vcols)
    mn, mx, _ = G.world_bounds(objs)
    cur = mx.z - mn.z
    k = height / cur if cur > 1e-6 else 1.0
    for ob in objs:
        ob.scale = (k, k, k)
        ob.location = (ob.location.x * k, ob.location.y * k, ob.location.z * k)
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(objs)
    for ob in objs:
        ob.location = (ob.location.x, ob.location.y, ob.location.z - mn.z)
    bpy.context.view_layer.update()
    info = dict(title=title, height=height, tint=tint, aura=aura, theme=theme,
                idea=idea, wear=wear, line=line)
    return objs, info, round(k, 9)


def _components(mask):
    """Connected components (4-neighbour), iterative flood fill. No scipy on
    this machine and a recursive fill blows the stack on a 700x980 frame."""
    h, w = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    sizes = []
    ys, xs = np.nonzero(mask)
    for y0, x0 in zip(ys, xs):
        if seen[y0, x0]:
            continue
        stack = [(y0, x0)]
        seen[y0, x0] = True
        n = 0
        while stack:
            y, x = stack.pop()
            n += 1
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                yy, xx = y + dy, x + dx
                if 0 <= yy < h and 0 <= xx < w and mask[yy, xx] and not seen[yy, xx]:
                    seen[yy, xx] = True
                    stack.append((yy, xx))
        sizes.append(n)
    return sorted(sizes, reverse=True)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--tag", default="pass1")
    args = ap.parse_args(argv)
    root = os.path.join(args.repo, "renders", "art", "minibosses", "_rat_tally")
    os.makedirs(root, exist_ok=True)

    rep = {"ok": True, "tag": args.tag, "min_comp_px": MIN_COMP,
           "move_eps": MOVE_EPS, "views": {}, "errors": []}

    objs, info, kA = _build(None)
    wrA, _, camA = G.render_views(objs, "A", os.path.join(root, args.tag + "_A"),
                                  700, 980, info)
    objs, info, kB = _build("occupants")
    wrB, _, camB = G.render_views(objs, "B", os.path.join(root, args.tag + "_B"),
                                  700, 980, info)

    if camA != camB:
        rep["ok"] = False
        rep["errors"].append("CAMERA MOVED between A and B - every number below "
                             "is about the camera, not the catch: %r vs %r"
                             % (camA, camB))
    if abs(kA - kB) > 1e-6:
        rep["ok"] = False
        rep["errors"].append("HEIGHT NORMALISER MOVED %.9f -> %.9f" % (kA, kB))
    rep["cam"] = camA

    for pa in wrA:
        name = os.path.basename(pa)
        pb = [p for p in wrB if os.path.basename(p) == name]
        if not pb:
            rep["ok"] = False
            rep["errors"].append("%s: no B frame" % name)
            continue
        A = G.read_png(pa).astype(np.float64)
        B = G.read_png(pb[0]).astype(np.float64)
        if A.shape != B.shape:
            rep["ok"] = False
            rep["errors"].append("%s: shape %r vs %r" % (name, A.shape, B.shape))
            continue
        d = np.abs(A - B).max(axis=2)
        mask = d > MOVE_EPS
        sizes = [s for s in _components(mask) if s >= MIN_COMP]
        alphaA = A[..., 3] > 0.5
        rep["views"][name.replace(".png", "")] = {
            "moved_px": int(mask.sum()),
            "body_px": int(alphaA.sum()),
            "moved_share_of_body": round(float(mask.sum()) / max(1, int(alphaA.sum())), 4),
            "components": len(sizes),
            "component_px": sizes[:12],
        }
    # RED ON EMPTY. A view the catch cannot be seen in is a failure of the
    # creature, not a quiet zero in a report.
    for vn, v in rep["views"].items():
        if v["moved_px"] == 0 or v["components"] == 0:
            rep["ok"] = False
            rep["errors"].append("%s: THE CATCH IS INVISIBLE IN THIS VIEW "
                                 "(moved %d px, %d components)"
                                 % (vn, v["moved_px"], v["components"]))
    out = os.path.join(args.repo, "renders", "art", "minibosses",
                       "_rat_tally_%s.json" % args.tag)
    with open(out, "w") as f:
        json.dump(rep, f, indent=1)
    print("RAT_TALLY " + json.dumps({"ok": rep["ok"], "tag": args.tag,
                                     "errors": rep["errors"][:3],
                                     "views": {k: (v["moved_px"], v["components"])
                                               for k, v in rep["views"].items()}}))


if __name__ == "__main__":
    main()
