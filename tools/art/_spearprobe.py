"""_spearprobe - MEASURE THE CANDIDATE SPEAR BASES BEFORE AUTHORING ANYTHING.

  blender -b -noaudio -P tools/art/_spearprobe.py -- --out <json>

Rule 3 of the art charter: use the packs before generating a mesh. Unlike the
sceptre - where 30 pack hits held not one sceptre - a spear DOES exist in two
CC0 packs, so this measures them instead of assuming they are unusable.
Reports world bounds from the EVALUATED depsgraph, tri count, material names
and the dominant axis, because a shaft authored along +Y and one along +Z need
different held_rot and that is a fit question, not a taste one.
"""
import os
import sys
import json
import argparse

import bpy


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def imp(path):
    e = os.path.splitext(path)[1].lower()
    if e == ".obj":
        try:
            bpy.ops.wm.obj_import(filepath=path)
        except AttributeError:
            bpy.ops.import_scene.obj(filepath=path)
    elif e == ".fbx":
        bpy.ops.import_scene.fbx(filepath=path)
    elif e in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=path)
    else:
        raise RuntimeError("no importer for " + e)


def measure():
    dg = bpy.context.evaluated_depsgraph_get()
    lo = [1e9] * 3
    hi = [-1e9] * 3
    tris = 0
    mats = set()
    objs = []
    for o in bpy.context.scene.objects:
        if o.type != 'MESH':
            continue
        objs.append(o.name)
        oe = o.evaluated_get(dg)
        me = oe.to_mesh()
        me.calc_loop_triangles()
        tris += len(me.loop_triangles)
        for ms in o.material_slots:
            if ms.material:
                mats.add(ms.material.name)
        for v in me.vertices:
            w = oe.matrix_world @ v.co
            for i in range(3):
                lo[i] = min(lo[i], w[i])
                hi[i] = max(hi[i], w[i])
        oe.to_mesh_clear()
    if not objs:
        return None
    size = [round(hi[i] - lo[i], 4) for i in range(3)]
    axis = "XYZ"[size.index(max(size))]
    return dict(objs=objs, n_mesh=len(objs), tris=tris, mats=sorted(mats),
                lo=[round(v, 4) for v in lo], hi=[round(v, 4) for v in hi],
                size=size, long_axis=axis, length=max(size))


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    a = ap.parse_args(argv)

    P = r"C:\hd adventure\_packs"
    R = r"C:\hd adventure\jests-hd-medieval-adventure"
    cands = [
        ("quaternius_spear_obj", os.path.join(P, "quaternius_medieval_weapons_2018_CC0", "Medieval Weapons Pack - Sept 2018", "OBJ", "Spear.obj")),
        ("quaternius_spear_fbx", os.path.join(P, "quaternius_medieval_weapons_2018_CC0", "Medieval Weapons Pack - Sept 2018", "FBX", "Spear.fbx")),
        ("medievalpack_spear_obj", os.path.join(P, "medieval_pack_CC0", "MedievalPack", "OBJ", "Spear.obj")),
        # the meshes the engine ships TODAY for this kind - the control
        ("SHIPPED_spear_A", os.path.join(R, "assets", "gear", "spear_A.gltf")),
        ("SHIPPED_halberd", os.path.join(R, "assets", "gear", "halberd.gltf")),
        # the tier-5 piece that passed this house's eye last hour - the yardstick
        ("SHIPPED_sceptre_golden", os.path.join(R, "assets", "gear", "artifact", "sceptre_golden.glb")),
        ("SHIPPED_sword_golden", os.path.join(R, "assets", "gear", "artifact", "sword_golden.glb")),
    ]
    out = {}
    for name, path in cands:
        if not os.path.isfile(path):
            out[name] = {"missing": path}
            continue
        try:
            clear()
            imp(path)
            m = measure()
            m["path"] = path
            out[name] = m
        except Exception as e:
            out[name] = {"error": repr(e), "path": path}
    with open(a.out, "w", encoding="utf-8") as f:
        json.dump(out, f, indent=2)
    print("WROTE", a.out)


main()
