"""_t5_dagcensus - DOES A READABLE FACING EXIST AT ALL? GEOMETRY ONLY, NO RENDERS.

`_t5_dagread` found ONE distinct upright carry on the 90-degree grid and
`_t5_dagyaw` found that the z term is the STAND-UP term, not a facing term
(z=0 lays the blade flat at hang 89.9). Neither tool answered the question
those two raise: among all 64 grid triples, is there one that stands the
blade UP **and** turns its broad local axis (X, 0.2972 m) along world X so the
FRONT camera sees the face instead of the 0.1109 m edge - and if there is,
which gate kills it?

This records all 64 with no gate filtering and no renders, so the answer is
in the open whether it is the one I want or not. `face_axis` is the world
axis the broad local axis lies closest to: X means the front/back cameras see
the face, Y means the side camera does.
"""
import os, sys, json, math, argparse
import bpy
from mathutils import Vector, bvhtree

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lordgen as G            # noqa: E402
import minibossfit as MF       # noqa: E402
import weaponfit as WF         # noqa: E402
import gearcarry as GC         # noqa: E402
import artifactfit as AF       # noqa: E402
import _t5_dagread as DR       # noqa: E402


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--gear", required=True)
    ap.add_argument("--tier", type=int, default=5)
    a = ap.parse_args(argv)

    tier_paths, _b = AF.kinds_tier(a.gear, a.tier)
    res_path = tier_paths[DR.KIND]
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next((o for o in roots if o.type == 'ARMATURE'), None)
    assert rig is not None and hinfo["posed"], "hero missing or in REST pose"
    bpy.context.view_layer.update()
    base = rig.matrix_world @ rig.pose.bones["handslot.r"].matrix
    slot = base @ Vector((0, 0, 0))
    order = AF.selftest_basis(a.gear, base)["euler_order"]
    dg = bpy.context.evaluated_depsgraph_get()
    body_trees = []
    for ob in body:
        try:
            body_trees.append(bvhtree.BVHTree.FromObject(ob, dg))
        except Exception:
            pass
    assert body_trees, "no BVH from the body"

    objs, _p = AF.load_res(a.repo, res_path)
    meshes = [o for o in objs if o.type == 'MESH']
    rest = {o.name: o.matrix_world.copy() for o in objs}
    hs = GC.carry(a.gear, res_path)["hand_scale"]
    lv = WF.world_verts(meshes)
    li = [max(v[i] for v in lv) - min(v[i] for v in lv) for i in range(3)]
    laxis = li.index(max(li))
    maxis = li.index(sorted(li)[1])          # the BROAD axis, 0.2972
    print("DAGCENSUS long=%s broad=%s hs=%.2f" % ("XYZ"[laxis], "XYZ"[maxis], hs),
          flush=True)

    rows = []
    for x in DR.GRID:
        for y in DR.GRID:
            for z in DR.GRID:
                deg = [x, y, z]
                Rslot = AF.slot_basis(deg, order)
                DR.place(objs, rest, base, Rslot, 0.0, hs)
                gm = DR.geom(meshes, body_trees, slot, base, Rslot, laxis)
                if gm is None:
                    continue
                gm.pop("key")
                M = (base @ Rslot).to_3x3()
                bw = M @ Vector(tuple(1.0 if i == maxis else 0.0
                                      for i in range(3)))
                bw.normalize()
                ax = max(range(3), key=lambda i: abs(bw[i]))
                upright = gm["hang_deg_from_vertical"] <= DR.HANG_MAX
                rows.append(dict(
                    triple=deg, upright=upright,
                    hang=gm["hang_deg_from_vertical"],
                    clip_frac=gm["clip_frac"], ground=gm["ground"],
                    clip_ok=gm["clip_frac"] <= DR.CLIP_FRAC_MAX,
                    no_ground=gm["ground"] == 0,
                    face_axis="XYZ"[ax],
                    face_dot=round(abs(bw[ax]), 3),
                    world_len_m=gm["world_len_m"]))

    up = [r for r in rows if r["upright"]]
    upx = [r for r in up if r["face_axis"] == "X"]
    passing = [r for r in up if r["clip_ok"] and r["no_ground"]]
    out = dict(tool="_t5_dagcensus", kind=DR.KIND, model=res_path,
               hand_scale=hs, euler_order=order,
               long_axis_local="XYZ"[laxis], broad_axis_local="XYZ"[maxis],
               gates=dict(hang_max=DR.HANG_MAX,
                          clip_frac_max=DR.CLIP_FRAC_MAX),
               n=len(rows), n_upright=len(up),
               n_upright_face_front=len(upx),
               n_upright_passing=len(passing),
               upright_face_front=upx, upright=up, all=rows)
    outdir = os.path.join(a.repo, "renders", "art", "gear_t%d" % a.tier, "_rx",
                          "_dagread")
    os.makedirs(outdir, exist_ok=True)
    jp = os.path.join(outdir, "_t5_dagcensus.json")
    with open(jp, "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=1)
    print("DAGCENSUS_DONE %s n=%d upright=%d upright_face_X=%d upright_passing=%d"
          % (jp, len(rows), len(up), len(upx), len(passing)), flush=True)
    for r in up:
        print("  UP %-22s face=%s(%.2f) hang=%4.1f cf=%.3f ground=%d len=%.3f"
              % (r["triple"], r["face_axis"], r["face_dot"], r["hang"],
                 r["clip_frac"], r["ground"], r["world_len_m"]), flush=True)


if __name__ == "__main__":
    main()
