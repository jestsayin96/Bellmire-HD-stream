"""_t5_slotframe - IS THE BLENDER BONE BASIS LABELLED THE SAME WAY AS GODOT'S SLOT?

This is the one measurement that settles which rule turns a gear.gd euler into a
slot basis, and it replaces an argument with a number.

gear.gd:245-249 states, MEASURED by the game build's own tools/_s19_hand.gd on
the posed idle: "the slot's +Y is world-forward and its +X is world-DOWN
(-0.99)". That is a claim about the GODOT slot frame.

  - If the BLENDER bone basis carries the SAME labelling, the slot side needs no
    conversion and the rule is Rslot = R_godot . C^-1  (weaponfit's crossbow).
  - If it is permuted, the slot side must be converted too and the rule is
    Rslot = C . R_godot . C^-1 (weaponfit's staff, and the only rule that maps a
    ZERO held_rot to a zero correction).

Also derives each mesh's LONG axis from its own local bounds instead of a label.
The first version of this probe hardcoded the crossbow's axis names (prod X,
stock Y, thin Z - gear.gd measured those) and applied them to the staff too,
and so reported the staff's "shaft" horizontal under BOTH conventions. That was
my label, not the staff: an instrument that cannot see what it claims to.
"""
import os, sys, json, math, argparse
import bpy
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import minibossfit as MF
import weaponfit as WF
import artifactfit as AF


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    a = ap.parse_args(argv)
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next(o for o in roots if o.type == 'ARMATURE')
    assert hinfo["posed"], "hero in REST pose - the whole measurement would be of nothing"
    bpy.context.view_layer.update()
    base = rig.matrix_world @ rig.pose.bones["handslot.r"].matrix
    M3 = base.to_3x3()
    # Blender world: body faces -Y (WF.make_cam az=0 puts the camera at -Y), up +Z
    REF = {"world_forward(-Y)": Vector((0, -1, 0)),
           "world_up(+Z)": Vector((0, 0, 1)),
           "world_down(-Z)": Vector((0, 0, -1)),
           "world_across(+X)": Vector((1, 0, 0))}
    out = {"hero_h": round(hinfo["h"], 3), "slot_axes_world": {}, "dots": {}}
    for nm, v in (("slot+X", (1, 0, 0)), ("slot+Y", (0, 1, 0)), ("slot+Z", (0, 0, 1))):
        w = (M3 @ Vector(v)).normalized()
        out["slot_axes_world"][nm] = [round(c, 3) for c in w]
        out["dots"][nm] = {k: round(w.dot(r), 3) for k, r in REF.items()}
    # mesh long axes, DERIVED
    out["meshes"] = {}
    for res in ("res://assets/gear/dungeon/crossbow_common.glb",
                "res://assets/gear/dungeon/staff_common.glb",
                "res://assets/gear/artifact/sword_golden.glb"):
        objs, p = AF.load_res(a.repo, res)
        meshes = [o for o in objs if o.type == 'MESH']
        assert meshes, "RED ON EMPTY - no mesh from %s" % res
        lv = WF.world_verts(meshes)
        assert lv, "RED ON EMPTY - zero verts from %s" % res
        dim = [max(v[i] for v in lv) - min(v[i] for v in lv) for i in range(3)]
        out["meshes"][res.rsplit("/", 1)[-1]] = {
            "dim_blender": [round(d, 4) for d in dim],
            "long_axis": "XYZ"[dim.index(max(dim))],
            "thin_axis": "XYZ"[dim.index(min(dim))]}
        for o in objs:
            bpy.data.objects.remove(o, do_unlink=True)
    print(json.dumps(out, indent=1))
    rp = os.path.join(a.repo, "renders", "art", "gear_t5", "_axisab", "_slotframe.json")
    os.makedirs(os.path.dirname(rp), exist_ok=True)
    with open(rp, "w") as f:
        json.dump(out, f, indent=1)
    print("SLOTFRAME_DONE", rp)


if __name__ == "__main__":
    main()
