
import os, sys, json
import bpy
from mathutils import Vector
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G
import minibossfit as F
import argparse
argv = sys.argv[sys.argv.index("--")+1:]
ap = argparse.ArgumentParser(); ap.add_argument("--repo", required=True)
a = ap.parse_args(argv)
G.purge()
roots, meshes, hero = F.import_hero(a.repo)
out = {"hero": hero, "parts": {}}
for o in meshes:
    mn, mx, _ = G.world_bounds([o])
    out["parts"][o.name] = dict(z=[round(mn.z,3), round(mx.z,3)],
                                w=round(mx.x-mn.x,3), d=round(mx.y-mn.y,3),
                                h=round(mx.z-mn.z,3))
H = hero["h"]
head = [v for k,v in out["parts"].items() if "Head" in k or "Helmet" in k]
if head:
    z0 = min(h["z"][0] for h in head); z1 = max(h["z"][1] for h in head)
    out["head_block"] = dict(z=[round(z0,3), round(z1,3)], h=round(z1-z0,3),
                             frac_of_body=round((z1-z0)/H,3),
                             widest=round(max(h["w"] for h in head),3))
body = out["parts"].get("Knight_Body")
if body: out["body_frac"] = round(body["h"]/H, 3)
out["hero_total_h"] = H
print("CHIBI_PROBE " + json.dumps(out))
