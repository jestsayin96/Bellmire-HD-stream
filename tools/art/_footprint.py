"""_footprint - THE CORRIDOR CHECK, as a number rather than an eyeball.

  blender -b -noaudio -P tools/art/_footprint.py -- --repo <repo> --only k,k

A three-cell dungeon corridor is 11.0 m across. A set piece whose own
footprint - its X/Y span on the floor, not its height - is wider than that
is ROOM-LOCKED BY CONSTRUCTION and the game build lane has to gate its
spawn. Every conversion in docs/art/MINIBOSS_FIT.md quotes this span; this
file is the thing that produced it, so a skip can be measured the same way
a conversion is.

Reports the span at the AUTHORED height and again at any recommended `h`,
because bestiary.gd normalises a monster to `h` and the footprint scales
with it.
"""
import os
import sys
import json
import argparse

import bpy  # noqa: F401

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402

CORRIDOR = 11.0


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--only", required=True)
    ap.add_argument("--at", type=float, default=0.0, help="recommended in-game h")
    args = ap.parse_args(argv)
    rows = {}
    for key in [k for k in args.only.split(",") if k]:
        G.purge()
        objs, info = MG.build_miniboss(key)
        mn, mx, _ = G.world_bounds(objs)
        h = mx.z - mn.z
        sx, sy = mx.x - mn.x, mx.y - mn.y
        span = max(sx, sy)
        faces = sum(len(o.data.polygons) for o in objs if o.type == 'MESH')
        row = dict(key=key, authored_h=round(h, 3), x=round(sx, 2), y=round(sy, 2),
                   footprint_span=round(span, 2), meshes=len(objs), faces=faces,
                   corridor_safe=bool(span <= CORRIDOR))
        if args.at > 0.1:
            k = args.at / max(0.01, h)
            row["at_h"] = args.at
            row["span_at_h"] = round(span * k, 2)
            row["corridor_safe_at_h"] = bool(span * k <= CORRIDOR)
        rows[key] = row
    out = os.path.join(args.repo, "renders", "art", "minibosses", "_footprint.json")
    old = {}
    if os.path.isfile(out):
        try:
            with open(out) as f:
                old = json.load(f)
        except Exception:
            old = {}
    old.update(rows)
    with open(out, "w") as f:
        json.dump(old, f, indent=1)
    print("FOOTPRINT " + json.dumps(rows))


if __name__ == "__main__":
    main()
