"""_goldmatprobe - READ THE SHIPPED GOLDEN SET'S OWN MATERIAL VALUES.

  blender -b -noaudio -P tools/art/_goldmatprobe.py -- --out <json>

The sceptre's pass-2 note is the reason this exists: a gold invented at
metallic 1.0 renders as a flat dark stick, and `_goldcontrol.py` showed the
SHIPPED golden set is bright because it is barely metallic. So the tier-5
spear does not get a gold I chose - it gets the numbers the shipped
`sword_golden` and `axe_double_golden` already carry, read out of the .glb.
Also dumps the PLAIN Quaternius sword and spear so the Steel->Golden material
substitution can be shown to be Quaternius' OWN, not one I made up.
"""
import os
import sys
import json
import argparse

import bpy


def mats_of(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    e = os.path.splitext(path)[1].lower()
    if e == ".obj":
        try:
            bpy.ops.wm.obj_import(filepath=path)
        except AttributeError:
            bpy.ops.import_scene.obj(filepath=path)
    elif e == ".fbx":
        bpy.ops.import_scene.fbx(filepath=path)
    else:
        bpy.ops.import_scene.gltf(filepath=path)
    out = {}
    for m in bpy.data.materials:
        d = {"name": m.name}
        nt = m.node_tree
        if nt:
            for n in nt.nodes:
                if n.type == 'BSDF_PRINCIPLED':
                    for k in ("Base Color", "Metallic", "Roughness", "Emission Strength"):
                        if k in n.inputs:
                            v = n.inputs[k].default_value
                            try:
                                d[k] = [round(float(x), 4) for x in v]
                            except TypeError:
                                d[k] = round(float(v), 4)
        out[m.name] = d
    # which material each triangle uses, so the gold/wood split is measured
    counts = {}
    dg = bpy.context.evaluated_depsgraph_get()
    for o in bpy.context.scene.objects:
        if o.type != 'MESH':
            continue
        oe = o.evaluated_get(dg)
        me = oe.to_mesh()
        me.calc_loop_triangles()
        names = [ms.material.name if ms.material else "<none>" for ms in o.material_slots]
        for t in me.loop_triangles:
            nm = names[t.material_index] if t.material_index < len(names) else "<oob>"
            counts[nm] = counts.get(nm, 0) + 1
        oe.to_mesh_clear()
    return {"mats": out, "tris_per_mat": counts}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    a = ap.parse_args(argv)
    P = r"C:\hd adventure\_packs"
    R = r"C:\hd adventure\jests-hd-medieval-adventure"
    QMW = os.path.join(P, "quaternius_medieval_weapons_2018_CC0", "Medieval Weapons Pack - Sept 2018")
    cands = {
        "sword_golden": os.path.join(R, "assets", "gear", "artifact", "sword_golden.glb"),
        "axe_double_golden": os.path.join(R, "assets", "gear", "artifact", "axe_double_golden.glb"),
        "sceptre_golden": os.path.join(R, "assets", "gear", "artifact", "sceptre_golden.glb"),
        "pack_spear": os.path.join(QMW, "OBJ", "Spear.obj"),
    }
    # find the plain Quaternius sword for the substitution proof
    for dp, dns, fns in os.walk(QMW):
        for f in fns:
            if f.lower() in ("sword.obj",) and dp.lower().endswith("obj"):
                cands["pack_sword_plain"] = os.path.join(dp, f)
    res = {}
    for k, v in cands.items():
        if not os.path.isfile(v):
            res[k] = {"missing": v}
            continue
        try:
            res[k] = mats_of(v)
            res[k]["path"] = v
        except Exception as e:
            res[k] = {"error": repr(e), "path": v}
    with open(a.out, "w", encoding="utf-8") as f:
        json.dump(res, f, indent=2)
    print("WROTE", a.out)


main()
