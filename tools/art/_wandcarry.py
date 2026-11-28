"""_wandcarry - RENDER THE CANDIDATE CARRIES ON A POSED BODY AND LOOK AT THEM.

  blender -b -noaudio -P tools/art/_wandcarry.py -- --repo <repo>

THE GATE THIS FILE DOES NOT USE IS `clip == 0`, AND THAT IS THE POINT.
`_wandscale.py` measured the control my clip gate never had: the SHIPPED
`staff_rare`, at the carry gear.gd really gives it, clips 202 of 890 checked
vertices - 22.7%. A held shaft grazing the forearm is NORMAL in this game and
every upright weapon in it does it. So `clip == 0` was never the standard,
it was a number this lane's own harness made up, and it had been rejecting
carries BETTER than the ones already shipping. The control is the bar now.

WHAT STILL GATES, because these catch things the eye cannot:
  - blank: a view with no opaque pixels
  - border: the icon/figure cut by the frame
  - blind: the wand present but contributing zero moved pixels, measured the
    viewer's way (with and without, through ONE camera, renderer does depth)
  - ground: vertices through the floor
  - RED ON EMPTY: any count taken over zero vertices is a FAIL

The carry numbers are judged BY EYE against the control, and the summary says
what the eye saw. That split is deliberate: the numbers bound the search, the
picture decides.
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

WAND = os.path.join("assets", "gear", "wand_crystal.glb")

# name, held_rot, hand_scale. The FIRST is the carry the engine gives today
# with no wiring from any lane - the "before" picture, kept so the comparison
# reproduces.
CARRIES = [
    ("now_horizontal", [0, 0, 0],  0.62),
    ("up_roll00",      [0, 0, 90], 0.62),
    ("up_roll15",      [0, 15, 90], 0.62),
    ("up_roll45",      [0, 45, 90], 0.62),
    ("wandlen_roll45", [0, 45, 90], 0.45),
]


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    a = ap.parse_args(argv)

    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next((o for o in roots if o.type == 'ARMATURE'), None)
    assert rig is not None and hinfo["posed"], "hero missing or in rest pose"
    bpy.context.view_layer.update()

    # *** PASS 1 OF THIS FILE SHIPPED NO RENDER SETUP AND THE BORDER CHECK
    # *** WENT BLIND. Blender then used its OWN default 1920x1080 while
    # *** `WF.frame_outside` computes the frame half-height from FRAME_H and
    # *** the INTENDED CELL aspect (weaponfit:474-475). At 1920x1080 an
    # *** ortho_scale of 3.80 spans the WIDTH, so the real vertical field was
    # *** 3.80 * 1080/1920 = 2.14 m against a 2.45 m hero - the body was cut
    # *** at the belt in every frame and `frame_clipped` still reported [].
    # *** I saw the crop in the picture, not in the number. Same family as the
    # *** pass-11 mask fault: an instrument that cannot see is not a pass.
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

    # *** AND THE OMISSION IS NOW UNREPEATABLE, which matters more than the
    # *** fix: the border check is only meaningful when the pixels it reasons
    # *** about are the pixels that were rendered. Assert it instead of
    # *** trusting that a future edit remembers to set it.
    if (scene.render.resolution_x, scene.render.resolution_y) != (WF.CELL_X, WF.CELL_Y) \
       or scene.render.resolution_percentage != 100:
        raise SystemExit(
            "WANDCARRY FAIL - render resolution is %sx%s @%s%%, but "
            "WF.frame_outside derives the frame from FRAME_H and the "
            "CELL_X/CELL_Y aspect (%sx%s). The border check would be blind."
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
    bpy.ops.import_scene.gltf(filepath=os.path.join(a.repo, WAND))
    new = [o for o in bpy.data.objects if o not in before]
    mesh = [o for o in new if o.type == 'MESH']
    root = [o for o in new if o.parent is None]
    assert mesh, "the wand glb imported no mesh"
    bpy.context.view_layer.update()

    cz = (WF.FRAME_H / 2.0) - WF.GROUND_UP
    out = []
    for name, hr, hs in CARRIES:
        if hr == [0, 0, 0]:
            R, roll = Matrix.Identity(4), 0.0
        else:
            R, roll = WF.slot_matrix("staff",
                                     (str(hr[0]), str(hr[1]), str(hr[2])))
        S = Matrix.Diagonal((hs,) * 3).to_4x4()
        for o in root:
            o.matrix_world = base @ R @ S
        bpy.context.view_layer.update()

        wv = WF.world_verts(mesh)
        assert wv, "RED ON EMPTY - zero wand vertices in world space"
        far = [p for p in wv if (p - slot).length > WF.FIST_R]
        if not far:
            out.append(dict(name=name, held_rot=hr, hand_scale=hs,
                            ERROR="every vertex inside the fist sphere - "
                                  "the clip test would be taken over nothing"))
            continue
        clip = sum(1 for p in far if WF.inside(trees, p))
        ground = sum(1 for p in wv if p.z < -0.002)
        zs = [p.z for p in wv]
        allpts = bpts + wv

        outdir = os.path.join(a.repo, "renders", "art", "wand", name)
        os.makedirs(outdir, exist_ok=True)
        rows, blanks, framed, blind = {}, [], [], []
        for vname, az in WF.VIEWS:
            cam = WF.make_cam(az, cz, allpts)
            WF.show(mesh, False)
            without = WF.render_to(os.path.join(outdir, "_no_%s.png" % vname))
            WF.show(mesh, True)
            with_ = WF.render_to(os.path.join(outdir, "%s.png" % vname))
            moved = int(np.count_nonzero(
                np.abs(with_ - without).max(axis=2) > 0.01))
            opaque = int(np.count_nonzero(with_[:, :, 3] > 0.5))
            if opaque == 0:
                blanks.append(vname)
            fo_wand = WF.frame_outside(cam, wv)
            fo_all = WF.frame_outside(cam, allpts)
            if moved == 0 or fo_wand >= len(wv):
                blind.append(vname)
            if fo_all:
                framed.append([vname, int(fo_all)])
            rows[vname] = dict(moved=moved, opaque=opaque,
                               wand_verts_outside_frame=int(fo_wand),
                               frame_outside=int(fo_all))
            bpy.data.objects.remove(cam, do_unlink=True)

        # NOTE the gate: clip is REPORTED against the measured control, not
        # required to be zero. blanks/blind/border/ground still gate hard.
        hard_ok = (not blanks) and (not blind) and (not framed) and ground == 0
        out.append(dict(name=name, held_rot=hr, hand_scale=hs,
                        roll_applied=round(roll, 2),
                        length_in_hand=round(0.921 * hs, 3),
                        verts=len(wv), checked=len(far),
                        clip=int(clip),
                        clip_pct=round(100.0 * clip / len(far), 1),
                        ground=int(ground),
                        reach=round(max(zs) - slot.z, 3),
                        tip_z=round(max(zs), 3),
                        hard_gates_ok=hard_ok,
                        blanks=blanks, blind_views=blind,
                        frame_clipped=framed, views=rows,
                        outdir=os.path.relpath(outdir, a.repo)))

    rep = dict(model=WAND, hero_h=round(hinfo["h"], 3),
               handslot=[round(v, 4) for v in slot],
               control_note="judged against _scale_sweep.json controls: the "
                            "SHIPPED staff_rare clips 22.7% at its own carry, "
                            "so clip==0 is not the bar",
               carries=out)
    d = os.path.join(a.repo, "renders", "art", "wand")
    with open(os.path.join(d, "_carry_report.json"), "w") as f:
        json.dump(rep, f, indent=1)
    print("WANDCARRY " + json.dumps(rep))


if __name__ == "__main__":
    main()
