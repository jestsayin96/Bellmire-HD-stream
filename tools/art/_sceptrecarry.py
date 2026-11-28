"""_sceptrecarry - RENDER THE TIER-5 SCEPTRE'S CANDIDATE CARRIES ON A POSED BODY.

  blender -b -noaudio -P tools/art/_sceptrecarry.py -- --repo <repo> --gear <gear.gd>

`--gear` is a dump of `origin/main:scripts/gear.gd`, NOT this worktree's copy:
branch `art` is behind main, and the carry must be read off the engine the game
actually ships. `gearcarry.carry()` walks the real branches of `held_rot` and
`hand_scale` in source order and tells me what the engine would do with this
path TODAY, with no wiring from any lane. The first row rendered is that carry,
whatever it is - the "before" picture - and it is read, not typed in here.

THE GATE IS NOT `clip == 0`. `_wandscale.py` measured the control: the SHIPPED
`staff_rare` clips 22.7% of its checked vertices at the carry gear.gd gives it,
and `staff_B.gltf` clips 5.8%. A held shaft grazing the forearm is normal in
this game. clip is REPORTED against that control and judged by eye.

WHAT STILL GATES HARD, because these catch what the eye cannot:
  blank (no opaque pixels), border (figure cut by the frame), blind (the
  sceptre present but contributing ZERO moved pixels, measured the viewer's
  way - with and without through ONE camera, renderer does the depth), ground
  (vertices through the floor), and RED ON EMPTY (any count over zero
  vertices is a FAIL, not a pass).
"""
import os
import sys
import json
import argparse

import bpy
import numpy as np
from mathutils import Vector, Matrix, bvhtree

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibossfit as MF     # noqa: E402
import weaponfit as WF       # noqa: E402
import gearcarry as GC       # noqa: E402

MODEL = os.path.join("assets", "gear", "artifact", "sceptre_golden.glb")
RES = "res://assets/gear/artifact/sceptre_golden.glb"
OUTROOT = os.path.join("renders", "art", "sceptre")

# The candidates BEYOND the engine's own fallback. A sceptre is carried
# upright, and upright is also what the wand could not manage: (0,0,90) is the
# arm the staff and the golden bow already use, so it is this house's own
# convention and not a new idea.
EXTRA = [
    ("up_roll00", [0, 0, 90], None),
    ("up_roll15", [0, 15, 90], None),
    ("up_roll15_big", [0, 15, 90], 0.75),
]


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--gear", required=True)
    a = ap.parse_args(argv)

    eng = GC.carry(a.gear, RES)
    carries = [("engine_fallback", [float(v) for v in eng["held_rot_deg"]],
                eng["hand_scale"])]
    for nm, hr, hs in EXTRA:
        carries.append((nm, hr, eng["hand_scale"] if hs is None else hs))

    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next((o for o in roots if o.type == 'ARMATURE'), None)
    assert rig is not None and hinfo["posed"], "hero missing or in rest pose"
    bpy.context.view_layer.update()

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
            ld = bpy.data.lights.new(nm, 'SUN')
            ld.energy = en
            lo = bpy.data.objects.new(nm, ld)
            lo.rotation_euler = rot
            bpy.context.collection.objects.link(lo)
    # The pass-1 omission on the wand, made unrepeatable: the border check only
    # means anything when the pixels it reasons about are the pixels rendered.
    if (scene.render.resolution_x, scene.render.resolution_y) != (WF.CELL_X, WF.CELL_Y) \
       or scene.render.resolution_percentage != 100:
        raise SystemExit("SCEPTRECARRY FAIL - resolution %sx%s @%s%% but "
                         "WF.frame_outside derives the frame from FRAME_H and "
                         "the %sx%s aspect; the border check would be blind."
                         % (scene.render.resolution_x, scene.render.resolution_y,
                            scene.render.resolution_percentage, WF.CELL_X, WF.CELL_Y))

    pb = rig.pose.bones["handslot.r"]
    base = rig.matrix_world @ pb.matrix
    slot = base @ Vector((0, 0, 0))

    dg = bpy.context.evaluated_depsgraph_get()
    trees = []
    for ob in body:
        try:
            trees.append(bvhtree.BVHTree.FromObject(ob, dg))
        except Exception:
            pass
    assert trees, "no BVH from the body - every clip count would be over nothing"
    bmn, bmx, bpts = G.world_bounds(body)

    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(a.repo, MODEL))
    new = [o for o in bpy.data.objects if o not in before]
    mesh = [o for o in new if o.type == 'MESH']
    root = [o for o in new if o.parent is None]
    assert mesh, "the sceptre glb imported no mesh"
    bpy.context.view_layer.update()

    # RED ON WRONG AXIS, measured AFTER the round trip: the carry numbers below
    # only mean what gear.gd means by them if the shaft comes back on +Y.
    rv = WF.world_verts(mesh)
    assert rv, "RED ON EMPTY - the imported sceptre has no vertices"
    sx = max(p.x for p in rv) - min(p.x for p in rv)
    sy = max(p.y for p in rv) - min(p.y for p in rv)
    sz = max(p.z for p in rv) - min(p.z for p in rv)
    # RED ON WRONG AXIS, and this gate caught pass 1's real fault only after I
    # MEASURED the control: imported into Blender, sword_golden spans z 2.302,
    # staff_rare 1.162, wand_crystal 0.921 - the long axis of every shipped
    # weapon is +Z, and the calibrated staff basis sends mesh +Z to slot -X,
    # which is up. Pass 1 of the generator built on +Y, so (0,0,90) left the
    # shaft lying forward and the engine's identity carry looked the SAME as
    # the upright one (reach 0.107 vs 0.101) - two carries 90 degrees apart
    # that could not both be right. That near-equality is what gave it away.
    if not (sz > sx * 3 and sz > sy * 3):
        raise SystemExit("SCEPTRECARRY FAIL - reimported shaft is not on +Z "
                         "(span x %.3f y %.3f z %.3f), so it is not built like "
                         "the golden set and every held_rot below would mean "
                         "something else." % (sx, sy, sz))
    raw_len = sz

    cz = (WF.FRAME_H / 2.0) - WF.GROUND_UP
    out = []
    for name, hr, hs in carries:
        if list(hr) == [0, 0, 0]:
            R, roll = Matrix.Identity(4), 0.0
        else:
            R, roll = WF.slot_matrix("staff", (str(hr[0]), str(hr[1]), str(hr[2])))
        S = Matrix.Diagonal((hs,) * 3).to_4x4()
        for o in root:
            o.matrix_world = base @ R @ S
        bpy.context.view_layer.update()

        wv = WF.world_verts(mesh)
        assert wv, "RED ON EMPTY - zero sceptre vertices in world space"
        far = [p for p in wv if (p - slot).length > WF.FIST_R]
        if not far:
            out.append(dict(name=name, held_rot=hr, hand_scale=hs,
                            ERROR="every vertex inside the fist sphere - the "
                                  "clip test would be taken over nothing"))
            continue
        clip = sum(1 for p in far if WF.inside(trees, p))
        ground = sum(1 for p in wv if p.z < -0.002)
        zs = [p.z for p in wv]
        allpts = bpts + wv

        outdir = os.path.join(a.repo, OUTROOT, name)
        os.makedirs(outdir, exist_ok=True)
        rows, blanks, framed, blind = {}, [], [], []
        for vname, az in WF.VIEWS:
            cam = WF.make_cam(az, cz, allpts)
            WF.show(mesh, False)
            without = WF.render_to(os.path.join(outdir, "_no_%s.png" % vname))
            WF.show(mesh, True)
            with_ = WF.render_to(os.path.join(outdir, "%s.png" % vname))
            moved = int(np.count_nonzero(np.abs(with_ - without).max(axis=2) > 0.01))
            opaque = int(np.count_nonzero(with_[:, :, 3] > 0.5))
            if opaque == 0:
                blanks.append(vname)
            fo_self = WF.frame_outside(cam, wv)
            fo_all = WF.frame_outside(cam, allpts)
            if moved == 0 or fo_self >= len(wv):
                blind.append(vname)
            if fo_all:
                framed.append([vname, int(fo_all)])
            rows[vname] = dict(moved=moved, opaque=opaque,
                               sceptre_verts_outside_frame=int(fo_self),
                               frame_outside=int(fo_all))
            bpy.data.objects.remove(cam, do_unlink=True)

        hard_ok = (not blanks) and (not blind) and (not framed) and ground == 0
        out.append(dict(name=name, held_rot=hr, hand_scale=hs,
                        roll_applied=round(roll, 2),
                        length_in_hand=round(raw_len * hs, 3),
                        reach_above_fist=round(max(zs) - slot.z, 3),
                        tip_z=round(max(zs), 3),
                        verts=len(wv), checked=len(far),
                        clip=int(clip), clip_pct=round(100.0 * clip / len(far), 1),
                        ground=int(ground), hard_gates_ok=hard_ok,
                        blanks=blanks, blind_views=blind, frame_clipped=framed,
                        views=rows, outdir=os.path.relpath(outdir, a.repo)))

    rep = dict(model=MODEL, res_path=RES, hero_h=round(hinfo["h"], 3),
               handslot=[round(v, 4) for v in slot],
               raw_len_y=round(raw_len, 3),
               engine_carry_read_off_main=eng,
               control_note="clip judged against _scale_sweep.json controls: "
                            "SHIPPED staff_rare clips 22.7%, staff_B 5.8%, so "
                            "clip==0 is not the bar",
               carries=out)
    d = os.path.join(a.repo, OUTROOT)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "_carry_report.json"), "w") as f:
        json.dump(rep, f, indent=1)
    print("SCEPTRECARRY " + json.dumps(rep))


if __name__ == "__main__":
    main()
