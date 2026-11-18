"""_moulder_wear - the Moulder's CANON wear, DERIVED.

The Moulder is a split body: the man is old (burnt leather, soot, iron handled
daily - 0.80) and the mould furniture and the castings are remade for every
cast, so they are nearly new (0.10). CANON carries ONE scalar per creature, so
the honest value is the surface-area-weighted mean of the two, measured off the
merged mesh that actually ships. It is not a taste number and nobody picked it.

  blender -b -noaudio -P tools/art/_moulder_wear.py -- --repo <repo>
"""
import os, sys, json, argparse
import bpy
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G
import minibossgen as MG

MAN_WEAR, NEW_WEAR = 0.80, 0.10

argv = sys.argv[sys.argv.index("--")+1:]
ap = argparse.ArgumentParser(); ap.add_argument("--repo", required=True)
a = ap.parse_args(argv)
G.purge()
objs, info = MG.build_miniboss("moulder")
area = {}
for ob in objs:
    me = ob.data
    s = sum(p.area for p in me.polygons)
    k = ob.data.materials[0].name if me.materials else ob.name
    area[k] = area.get(k, 0.0) + s
man = sum(v for k, v in area.items() if "body" in k)
new = sum(v for k, v in area.items() if "body" not in k and "glow" not in k)
tot = man + new
w = (man * MAN_WEAR + new * NEW_WEAR) / tot if tot > 0 else 0.0
print("MOULDER_WEAR " + json.dumps({
    "area_by_material": {k: round(v, 4) for k, v in area.items()},
    "man_area": round(man, 4), "new_area": round(new, 4),
    "man_wear": MAN_WEAR, "new_wear": NEW_WEAR,
    "derived_wear": round(w, 4), "canon_should_be": round(w, 2)}))
