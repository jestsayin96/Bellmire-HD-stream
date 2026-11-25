"""_harrow_read.py - THE HARROWMAN'S OWN INSTRUMENT, and it answers the two
questions the blank check and the border check CANNOT see.

  blender -b -noaudio -P tools/art/_harrow_read.py -- --repo <repo>

Q1 WHO OWNS THE FLOOR. minibossgen grounds a body on its GLOBAL z-minimum, so
   any prop that hangs lower than the soles silently LIFTS THE MAN off the
   floor and every render still passes blank, border and span. Pass 2 did
   exactly that. This prints z-min per span and NAMES the span that owns the
   global minimum: if that is not a leg span, the man is floating.

Q2 CAN THE HARROW BE SEEN AS A GRID. Not "is it big" - the mask_of fault of
   17 Nov was measuring a thing ALONE and calling that visibility. Here the
   question is the viewer's: the lattice's own bar directions are projected
   into each ortho camera's image plane and the SHORTEST projected bar length
   is reported as a fraction of its true length. A bar set that collapses
   (the pass-1 rake: one bar with teeth under it) scores near 0 on one axis.
   RED ON EMPTY is honoured: zero bars measured is a fault, not a pass.
"""
import os, sys, json, argparse, math
import bpy
from mathutils import Vector
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import minibosses as M


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--key", default="harrowman")
    args = ap.parse_args(argv)

    P = M.BUILDERS[args.key]()
    spans = dict(getattr(P, "spans", {}) or {})
    out = {"key": args.key, "spans": {}, "errors": [], "ok": True}

    gmin = 1e9
    for name, (a, b) in sorted(spans.items()):
        zs = [v.z for i in range(a, b) for v in P.items[i][0]]
        if not zs:
            out["errors"].append("span %s is EMPTY - red on empty" % name)
            out["ok"] = False
            continue
        out["spans"][name] = {"zmin": round(min(zs), 4), "zmax": round(max(zs), 4),
                              "items": b - a}
        gmin = min(gmin, min(zs))
    out["global_zmin"] = round(gmin, 4)
    owners = [n for n, d in out["spans"].items() if abs(d["zmin"] - gmin) < 1e-4]
    out["floor_owner"] = owners
    # THE MAN MUST OWN THE FLOOR. legs is the only acceptable owner.
    if "legs" not in owners:
        out["errors"].append("FLOOR IS OWNED BY %s, NOT THE LEGS - the man is "
                             "floating above his own soles" % owners)
        out["ok"] = False
    man = [n for n in getattr(P, "man_parts", ())]
    sole = out["spans"].get("legs", {}).get("zmin")
    tine = out["spans"].get("tines", {}).get("zmin")
    if sole is not None and tine is not None:
        out["tine_below_sole_m"] = round(sole - tine, 4)

    # ---- Q2: the grid, through each ortho camera -------------------------
    # front camera looks along +Y, side camera along -X (minibossgen's rig).
    # A bar's visible length in an ortho view is its length times the sine of
    # the angle to the view axis; we report the WORST bar in each view.
    cams = {"front": Vector((0.0, 1.0, 0.0)), "side": Vector((1.0, 0.0, 0.0))}
    # THE BAR DIRECTIONS ARE MEASURED OFF THE FRAME SPAN, NOT COPIED FROM THE
    # BUILDER. The first cut of this file carried `YAWH = 0.66` and a
    # `Z_NEAR, Z_FAR = (0.975, 0.255)` fallback - literals duplicated from
    # minibosses.py, which is precisely the stale-copy fault this house keeps
    # finding in its own gates (floorgeom's lid, _s51_names' hardcoded count).
    # Re-rake the harrow and that gate would have gone on reporting the OLD
    # geometry as green. Each frame bar is a swept cone, so its axis is the
    # line between the centroids of its two end rings; the two distinct axes
    # present ARE the grid's two directions, whatever the builder chose.
    fa, fb = spans["frame"]
    axes = []
    for it in range(fa, fb):
        vs = P.items[it][0]
        half = len(vs) // 2
        c0 = sum(vs[:half], Vector((0.0, 0.0, 0.0))) / max(1, half)
        c1 = sum(vs[half:], Vector((0.0, 0.0, 0.0))) / max(1, len(vs) - half)
        if (c1 - c0).length > 1e-6:
            axes.append((c1 - c0).normalized())
    if len(axes) < 2:
        out["errors"].append("frame span yielded %d bar axes - red on empty"
                             % len(axes))
        out["ok"] = False
        axes = [Vector((1.0, 0.0, 0.0)), Vector((0.0, 1.0, 0.0))]
    along = axes[0]
    across = next((a for a in axes if abs(a.dot(along)) < 0.7), axes[-1])
    grid = {}
    for cname, cv in cams.items():
        worst = None
        for bname, bv in (("along", along), ("across", across)):
            frac = math.sqrt(max(0.0, 1.0 - (bv.dot(cv.normalized())) ** 2))
            grid.setdefault(cname, {})[bname] = round(frac, 3)
            worst = frac if worst is None else min(worst, frac)
        grid[cname]["worst"] = round(worst, 3)
        # A grid reads when BOTH directions keep real length. 0.35 is the bar.
        if worst < 0.35:
            out["errors"].append("%s view: worst bar direction keeps only %.2f "
                                 "of its length - the lattice collapses toward "
                                 "a single line in that view" % (cname, worst))
            out["ok"] = False
    if not grid:
        out["errors"].append("no camera measured - red on empty")
        out["ok"] = False
    out["grid_projection"] = grid

    path = os.path.join(args.repo, "renders", "art", "minibosses",
                        "_harrow_read.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(out, f, indent=1)
    print("HARROW_READ " + json.dumps(out))


main()
