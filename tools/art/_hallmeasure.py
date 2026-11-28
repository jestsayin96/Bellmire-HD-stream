"""_hallmeasure - measure the MegaKit modules the Hall ladder needs, and
lm_hall's pivot. BACKGROUND BLENDER ONLY (blender -b); never the live session.

  blender -b -noaudio -P tools/art/_hallmeasure.py -- --out <json>

Every number the build uses comes from here, measured this run, not carried
from the design doc. The design doc's own numbers are RE-STATED here so a
disagreement is visible instead of silent.
"""
import argparse, json, os, sys
import bpy
from mathutils import Vector

PACK = (r"C:\hd adventure\_packs\Medieval_Village_MegaKit"
        r"\Medieval Village MegaKit[Standard]\glTF")
W5 = r"C:\hd adventure\bellmire-art"

MODS = ["Wall_Plaster_WoodGrid", "Wall_Plaster_Door_Flat", "Wall_Plaster_Straight",
        "Wall_Plaster_Window_Wide_Round", "Wall_UnevenBrick_Straight",
        "Wall_UnevenBrick_Window_Wide_Round", "Wall_UnevenBrick_Door_Round",
        "Corner_Exterior_Wood", "Corner_ExteriorWide_Brick", "Floor_Brick",
        "Prop_MetalFence_Ornament", "Prop_Chimney", "Stairs_Exterior_Straight",
        "Roof_RoundTiles_4x6", "Roof_RoundTiles_6x8", "Roof_Tower_RoundTiles"]


def bounds(objs):
    """World-space bounds off the EVALUATED depsgraph.

    TRAP 3: an object that is not the active one never gets matrix_world
    evaluated by some paths, so this walks the depsgraph explicitly rather
    than reading o.bound_box against a stale matrix."""
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    for o in objs:
        if o.type != 'MESH':
            continue
        oe = o.evaluated_get(dg)
        mw = oe.matrix_world
        for c in oe.bound_box:
            pts.append(mw @ Vector(c))
    if not pts:
        return None, None, []
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return mn, mx, pts


def measure_file(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=path)
    objs = [o for o in bpy.data.objects if o.type == 'MESH']
    if objs:
        bpy.context.view_layer.objects.active = objs[0]
    bpy.context.view_layer.update()
    mn, mx, _ = bounds(objs)
    if mn is None:
        return {"error": "no mesh"}
    c = (mn + mx) / 2.0
    mats = sorted({sl.material.name for o in objs for sl in o.material_slots
                   if sl.material is not None})
    return {"dims": [round(mx.x - mn.x, 4), round(mx.y - mn.y, 4), round(mx.z - mn.z, 4)],
            "min": [round(v, 4) for v in mn], "max": [round(v, 4) for v in mx],
            "centre": [round(v, 4) for v in c],
            "n_mesh": len(objs),
            "n_tri": sum(len(o.data.polygons) for o in objs),
            "materials": mats}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    a = ap.parse_args(sys.argv[sys.argv.index("--") + 1:])
    rep = {"pack": PACK, "modules": {}, "errors": []}
    for m in MODS:
        p = os.path.join(PACK, m + ".gltf")
        if not os.path.isfile(p):
            rep["errors"].append("MISSING MODULE %s" % m)
            continue
        try:
            rep["modules"][m] = measure_file(p)
        except Exception as e:
            rep["errors"].append("%s: %s" % (m, e))
    # the existing tier-3 body and the hero, both measured not remembered
    for name, p in (("lm_hall", os.path.join(W5, "assets", "buildings", "lm_hall.glb")),
                    ("Knight", os.path.join(W5, "addons", "kaykit_character_pack_adventures",
                                            "Characters", "gltf", "Knight.glb"))):
        if os.path.isfile(p):
            try:
                rep[name] = measure_file(p)
            except Exception as e:
                rep["errors"].append("%s: %s" % (name, e))
        else:
            rep["errors"].append("MISSING %s at %s" % (name, p))
    with open(a.out, "w") as f:
        json.dump(rep, f, indent=1)
    print("HALLMEASURE " + json.dumps({"n": len(rep["modules"]), "errors": rep["errors"]}))


main()
