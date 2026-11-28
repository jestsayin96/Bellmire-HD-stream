"""_t5_dagyaw - CAN THE DAGGER READ WITHOUT BECOMING A SHORT SWORD?

`_t5_dagread` settled two things and refuted one of my own guesses.
  * The 90-degree grid offers exactly ONE distinct upright carry. Its four
    passing triples - (-90,0,90), (-90,90,0), (-90,-90,180), (-90,180,-90) -
    are the SAME world placement, because once x is -90 the y and z terms both
    act about the vertical and all four sum to yaw 90. So "turn the broad face
    to the front" is NOT reachable on the grid, and the front view keeps its
    13-px edge-on `minor` whichever of the four you write.
  * The scale arm works but costs the object: hand_scale 0.70 is the smallest
    that clears WF.VIS_MIN on two views, and it carries a 0.97 m blade. 0.75
    carries 1.04 m. gear.gd:304 records the .blend at 1.39 m and picked 0.5 to
    put it "at a long knife"; 1.04 m is a short sword. Mr. E's rule is that
    things look like what they are FOR, so buying pixels with length is a real
    cost and not a free pass.

WHAT THIS TOOL TESTS. Yaw is a CONTINUUM, and the engine already ships an
off-grid value - gear.gd gives the pack crossbow held_rot (-90, 35, 90), a 35
degree roll - so a non-90 prescription is expressible and has precedent. If
some yaw between broad-face-front and edge-on both clears the pixel floor on
two views AND keeps clip under the ceiling, the dagger stays a dagger and the
scale arm is not needed. If none does, the scale arm is the only fix and I
will say so with the numbers that forced it.

RED ON EMPTY and the same shipped gates as rxproof, deliberately.
"""
import os, sys, json, argparse
import bpy
import numpy as np
from mathutils import Vector, bvhtree

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lordgen as G            # noqa: E402
import minibossfit as MF       # noqa: E402
import weaponfit as WF         # noqa: E402
import gearcarry as GC         # noqa: E402
import artifactfit as AF       # noqa: E402
import _t5_dagread as DR       # noqa: E402

YAWS = [0.0, 15.0, 25.0, 35.0, 45.0, 55.0, 65.0, 75.0, 90.0]
HS = [0.5, 0.55, 0.6, 0.65]


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--gear", required=True)
    ap.add_argument("--tier", type=int, default=5)
    a = ap.parse_args(argv)

    outdir = os.path.join(a.repo, "renders", "art", "gear_t%d" % a.tier, "_rx",
                          "_dagyaw")
    cells = os.path.join(outdir, "cells")
    os.makedirs(cells, exist_ok=True)

    tier_paths, _bare = AF.kinds_tier(a.gear, a.tier)
    res_path = tier_paths[DR.KIND]
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next((o for o in roots if o.type == 'ARMATURE'), None)
    assert rig is not None and hinfo["posed"], "hero missing or in REST pose"
    bpy.context.view_layer.update()
    base = rig.matrix_world @ rig.pose.bones["handslot.r"].matrix
    slot = base @ Vector((0, 0, 0))
    ST = AF.selftest_basis(a.gear, base)
    order = ST["euler_order"]
    print("DAGYAW basis selftest PASSED order=%s" % order, flush=True)

    scene = bpy.context.scene
    G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = WF.CELL_X, WF.CELL_Y
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    for nm, rot, en in (("key", (-0.95, 0.0, 0.7), 3.2),
                        ("fill", (-1.2, 0.0, -2.1), 1.3)):
        if nm not in bpy.data.objects:
            ld = bpy.data.lights.new(nm, 'SUN'); ld.energy = en
            lo = bpy.data.objects.new(nm, ld); lo.rotation_euler = rot
            bpy.context.collection.objects.link(lo)

    dg = bpy.context.evaluated_depsgraph_get()
    body_trees = []
    for ob in body:
        try:
            body_trees.append(bvhtree.BVHTree.FromObject(ob, dg))
        except Exception:
            pass
    assert body_trees, "no BVH from the body"
    _bmn, _bmx, bpts = G.world_bounds(body)
    cz = (WF.FRAME_H / 2.0) - WF.GROUND_UP

    objs, _path = AF.load_res(a.repo, res_path)
    meshes = [o for o in objs if o.type == 'MESH']
    assert meshes, "DAGYAW FAIL - no mesh from %s" % res_path
    rest = {o.name: o.matrix_world.copy() for o in objs}
    cr = GC.carry(a.gear, res_path)
    lv = WF.world_verts(meshes)
    li = [max(v[i] for v in lv) - min(v[i] for v in lv) for i in range(3)]
    laxis = li.index(max(li))
    local_ext = sorted(li)

    body_only, cams, results = {}, {}, []
    for hs in HS:
        for yaw in YAWS:
            deg = [-90.0, 0.0, yaw]
            Rslot = AF.slot_basis(deg, order)
            DR.place(objs, rest, base, Rslot, 0.0, hs)
            gm = DR.geom(meshes, body_trees, slot, base, Rslot, laxis)
            assert gm is not None, "DAGYAW FAIL - no geometry at %s" % deg
            gm.pop("key")
            tag = "y%03d_hs%03d" % (round(yaw), round(hs * 100))
            rec = DR.measure(meshes, body, bpts, cz, body_only, cams, tag,
                             cells, local_ext[1] * hs * WF.PX_PER_M)
            rec.update(triple=deg, yaw=yaw, hand_scale=hs, **gm)
            rec["geom_ok"] = (gm["hang_deg_from_vertical"] <= DR.HANG_MAX
                              and gm["ground"] == 0
                              and gm["clip_frac"] <= DR.CLIP_FRAC_MAX)
            results.append(rec)
            print("  YAW %4.0f hs=%.2f hang=%4.1f len=%.3f cf=%.3f geom_ok=%s "
                  "minor=%s vis=%s proving=%d show=%s border=%.3f"
                  % (yaw, hs, gm["hang_deg_from_vertical"], gm["world_len_m"],
                     gm["clip_frac"], gm["geom_ok"] if "geom_ok" in gm
                     else rec["geom_ok"], rec["minor"], rec["vis"],
                     rec["proving_views"], rec.get("show"),
                     max(rec["border"].values())), flush=True)

    clean = [r for r in results
             if r["geom_ok"] and r["proving_views"] >= WF.MIN_PROVING
             and not r["blanks"] and not r["frame_clips"] and not r["errors"]
             and not r.get("lath")]
    clean.sort(key=lambda r: (r["hand_scale"], -min(r["vis"].values())))
    out = dict(tool="_t5_dagyaw", tier=a.tier, kind=DR.KIND, model=res_path,
               hero=hinfo, euler_order=order, basis_selftest=ST,
               engine_hand_scale=cr["hand_scale"],
               local_ext=[round(x, 4) for x in local_ext],
               gates=dict(seen_min=WF.SEEN_MIN, vis_min=WF.VIS_MIN,
                          show_min=WF.SHOW_MIN, min_proving=WF.MIN_PROVING,
                          hang_max=DR.HANG_MAX,
                          clip_frac_max=DR.CLIP_FRAC_MAX),
               yaws=YAWS, hand_scales=HS, candidates=len(results),
               clean=len(clean), recommended=(clean[0] if clean else None),
               results=results)
    jp = os.path.join(outdir, "_t5_dagyaw.json")
    with open(jp, "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=1)
    print("DAGYAW_DONE %s candidates=%d clean=%d" % (jp, len(results), len(clean)),
          flush=True)
    if not clean:
        print("  DAGYAW NO YAW SAVES IT at hand_scale <= %.2f - the scale arm "
              "is the only fix and the dagger gets longer." % max(HS), flush=True)
    else:
        r0 = clean[0]
        print("  DAGYAW RECOMMEND yaw=%.0f hs=%.2f len=%.3f m vis=%s proving=%d"
              % (r0["yaw"], r0["hand_scale"], r0["world_len_m"], r0["vis"],
                 r0["proving_views"]), flush=True)


if __name__ == "__main__":
    main()
