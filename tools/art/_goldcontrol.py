"""_goldcontrol - HOW BRIGHT AND HOW FAT IS A SHIPPED GOLDEN WEAPON IN THIS RIG?

  blender -b -noaudio -P tools/art/_goldcontrol.py -- --repo <repo>

Pass 1 of the sceptre read as a thin DARK stick in the picture. Before I touch
my own material I measure the control I do not have: the SHIPPED golden set,
rendered through the same camera, the same two suns and the same world. If
`sword_golden` also reads dark, the rig is the cause and my material is
innocent; if it reads bright, my material is the cause. Either way the number
is taken off the pixels the weapon ADDED (with vs without), never off the
whole frame, so the body cannot flatter it.
"""
import os, sys, json, argparse
import bpy, numpy as np
from mathutils import Vector, Matrix
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G
import minibossfit as MF
import weaponfit as WF

SUBJECTS = [
    ("sword_golden", "assets/gear/artifact/sword_golden.glb", [0, 0, 0], 0.6),
    ("hammer_double_golden", "assets/gear/artifact/hammer_double_golden.glb", [0, 0, 0], 0.4),
    ("sceptre_golden", "assets/gear/artifact/sceptre_golden.glb", [0, 15, 90], 0.6),
]


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    ap = argparse.ArgumentParser(); ap.add_argument("--repo", required=True)
    a = ap.parse_args(argv)
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next(o for o in roots if o.type == 'ARMATURE')
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
    for nm, rot, en in (("key", (-0.95, 0.0, 0.7), 3.2), ("fill", (-1.2, 0.0, -2.1), 1.3)):
        if nm not in bpy.data.objects:
            ld = bpy.data.lights.new(nm, 'SUN'); ld.energy = en
            lo = bpy.data.objects.new(nm, ld); lo.rotation_euler = rot
            bpy.context.collection.objects.link(lo)
    base = rig.matrix_world @ rig.pose.bones["handslot.r"].matrix
    bmn, bmx, bpts = G.world_bounds(body)
    cz = (WF.FRAME_H / 2.0) - WF.GROUND_UP
    outdir = os.path.join(a.repo, "renders", "art", "sceptre", "_goldcontrol")
    os.makedirs(outdir, exist_ok=True)
    rows = []
    for name, path, hr, hs in SUBJECTS:
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=os.path.join(a.repo, path))
        new = [o for o in bpy.data.objects if o not in before]
        mesh = [o for o in new if o.type == 'MESH']
        root = [o for o in new if o.parent is None]
        R = Matrix.Identity(4) if list(hr) == [0, 0, 0] else WF.slot_matrix("staff", tuple(str(v) for v in hr))[0]
        for o in root:
            o.matrix_world = base @ R @ Matrix.Diagonal((hs,) * 3).to_4x4()
        bpy.context.view_layer.update()
        wv = WF.world_verts(mesh)
        assert wv, "RED ON EMPTY - %s has no vertices" % name
        cam = WF.make_cam(0.0, cz, bpts + wv)
        WF.show(mesh, False)
        without = WF.render_to(os.path.join(outdir, "_no_%s.png" % name))
        WF.show(mesh, True)
        with_ = WF.render_to(os.path.join(outdir, "%s.png" % name))
        d = np.abs(with_ - without).max(axis=2) > 0.01
        n = int(np.count_nonzero(d))
        assert n > 0, "RED ON EMPTY - %s moved zero pixels; no colour to measure" % name
        px = with_[d][:, :3]
        rows.append(dict(name=name, hand_scale=hs, held_rot=hr, moved_px=n,
                         mean_rgb=[round(float(v), 3) for v in px.mean(axis=0)],
                         p90_luma=round(float(np.percentile(
                             0.2126 * px[:, 0] + 0.7152 * px[:, 1] + 0.0722 * px[:, 2], 90)), 3),
                         mean_luma=round(float((0.2126 * px[:, 0] + 0.7152 * px[:, 1]
                                                + 0.0722 * px[:, 2]).mean()), 3)))
        bpy.data.objects.remove(cam, do_unlink=True)
        for o in new:
            bpy.data.objects.remove(o, do_unlink=True)
    # THE GATE IS THE CONTROL, NOT A NUMBER I CHOSE. The bar is the SHIPPED
    # golden set measured in this same frame on this same run - if those two
    # ever change, this gate moves with them instead of going stale.
    ctrl = [r for r in rows if r["name"] != "sceptre_golden"]
    mine = next((r for r in rows if r["name"] == "sceptre_golden"), None)
    if not ctrl or mine is None:
        raise SystemExit("GOLDCONTROL FAIL - RED ON EMPTY: %d controls, "
                         "subject %s. A comparison over no control is not a "
                         "pass." % (len(ctrl), "present" if mine else "MISSING"))
    floor_p90 = min(r["p90_luma"] for r in ctrl)
    floor_px = min(r["moved_px"] for r in ctrl)
    verdict = dict(
        p90_floor=floor_p90, p90_mine=mine["p90_luma"],
        px_floor=floor_px, px_mine=mine["moved_px"],
        reads_as_bright_as_shipped=mine["p90_luma"] >= floor_p90 * 0.85,
        carries_as_much_silhouette=mine["moved_px"] >= floor_px * 0.80)
    rows.append(dict(name="_verdict", **verdict))
    with open(os.path.join(outdir, "_control.json"), "w") as f:
        json.dump(rows, f, indent=1)
    print("GOLDCONTROL " + json.dumps(rows))
    if not (verdict["reads_as_bright_as_shipped"] and verdict["carries_as_much_silhouette"]):
        print("GOLDCONTROL AMBER - below the shipped band: %s" % json.dumps(verdict))


if __name__ == "__main__":
    main()
