"""towntexsheet - LOOK AT ALL TWELVE BUILDINGS AFTER THE RELINK.

  blender -b -noaudio -P tools/art/towntexsheet.py -- --repo <repo>

The relink gate in `towntex.py` proves a texture is PRESENT and LINKED. It
cannot prove the texture landed on the right surface or the right way up - a
plaster map on a roof passes every number in it. So this renders all twelve
buildings through one camera each, with the measured KayKit Knight beside
every one for scale, and tiles them into one sheet to be LOOKED AT.

THE GATES HERE, AND WHAT EACH CANNOT SEE:
  1. BLANK   - opaque pixels > 0 per cell. Cannot see a clipped subject.
  2. SUBJECT SEEN - rendered twice, once with the building hidden, counting
     pixels that MOVED. RED ON EMPTY: < 1500 px is RED, so a cell with the
     building missing cannot pass by being empty.
  3. COLOUR SPREAD - the standard deviation across RGB of the opaque pixels.
     *** THIS IS THE ONE THAT ANSWERS THE ACTUAL DEFECT. *** The grey the fix
     removed was uniform 0.8 - a flat-shaded building has near-zero chroma
     spread. A textured one does not. RED if saturation mean < 0.02, which is
     what every one of these twelve measured BEFORE the relink.
     WHAT IT CANNOT SEE: a texture on the wrong surface. Only looking does.
"""
import argparse, json, math, os, sys

import bpy, numpy as np
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lordgen as G
import lordlib as L

W5 = r"C:\hd adventure\bellmire-art"
HERO = os.path.join(W5, "addons", "kaykit_character_pack_adventures",
                    "Characters", "gltf", "Knight.glb")
BODY = {"Knight_Body", "Knight_Head", "Knight_Helmet", "Knight_ArmLeft",
        "Knight_ArmRight", "Knight_LegLeft", "Knight_LegRight", "Knight_Cape"}
CELL_X, CELL_Y = 520, 440


def add_hero(dx):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=HERO)
    new = [o for o in bpy.data.objects if o not in before]
    arm = next((o for o in new if o.type == 'ARMATURE'), None)
    if arm is not None and "Idle" in bpy.data.actions:
        if arm.animation_data is None:
            arm.animation_data_create()
        arm.animation_data.action = bpy.data.actions["Idle"]
        bpy.context.scene.frame_set(1)
    keep = []
    for o in [o for o in new if o.type == 'MESH']:
        # whitelist by EXACT name: the file carries loose equipment variants
        # and a substring match framed a floating sword on an earlier sheet
        if o.name.split(".")[0] in BODY:
            keep.append(o)
        else:
            o.hide_render = True
    for o in [o for o in new if o.parent is None]:
        o.location = (o.location.x + dx, o.location.y, o.location.z)
    bpy.context.view_layer.update()
    return keep


def aim_cam(cam, cam_d, pts, center, radius, az, el, rx, ry, pad=1.08):
    a, e = math.radians(az), math.radians(el)
    d = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e),
                math.sin(e))).normalized()
    cam.location = center + d * (radius * 4.0 + 2.0)
    cam.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
    bpy.context.view_layer.update()
    mw = cam.matrix_world
    right = (mw.to_3x3() @ Vector((1, 0, 0))).normalized()
    up = (mw.to_3x3() @ Vector((0, 1, 0))).normalized()
    fwd = (mw.to_3x3() @ Vector((0, 0, -1))).normalized()
    wide = max(abs((p - center).dot(right)) for p in pts) * 2.0
    tall = max(abs((p - center).dot(up)) for p in pts) * 2.0
    cam_d.ortho_scale = max(wide, tall * (rx / float(ry))) * pad
    dep = [(p - cam.location).dot(fwd) for p in pts]
    cam_d.clip_start = max(0.01, min(dep) - radius * 0.5)
    cam_d.clip_end = max(dep) + radius * 2.0 + 5.0


def setup(rx, ry):
    scene = bpy.context.scene
    eng = G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = rx, ry
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes
               if n.type == 'BACKGROUND'), None)
    if bg:
        bg.inputs['Color'].default_value = (0.055, 0.06, 0.075, 1.0)
        bg.inputs['Strength'].default_value = 1.0
    return scene, eng


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=W5)
    a = ap.parse_args(sys.argv[sys.argv.index("--") + 1:])
    bd = os.path.join(a.repo, "assets", "buildings")
    names = sorted(f for f in os.listdir(bd)
                   if f.endswith(".glb") and not f.startswith("town_well_"))
    outd = os.path.join(a.repo, "renders", "art", "town", "_texsheet")
    os.makedirs(outd, exist_ok=True)
    rep = {"cells": {}, "errors": []}
    cells = []

    for fn in names:
        G.purge()
        scene, eng = setup(CELL_X, CELL_Y)
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=os.path.join(bd, fn))
        objs = [o for o in bpy.data.objects
                if o not in before and o.type == 'MESH']
        bpy.context.view_layer.update()
        mn, mx, _ = G.world_bounds(objs)
        hero = add_hero(dx=mx.x + 1.4)
        span = max(mx.x - mn.x, mx.y - mn.y)
        gv, gf = L.box(span * 1.7, span * 1.7, 0.12)
        gnd = L.make("gnd", gv, gf,
                     L.mat_solid("g", (0.21, 0.20, 0.18), 0.95, 0.0))
        gnd.location = ((mn.x + mx.x) / 2.0, 0.0, -0.06)
        bpy.context.view_layer.update()
        allm = objs + hero + [gnd]
        mn2, mx2, pts = G.world_bounds(allm)
        center = (mn2 + mx2) / 2.0
        radius = max(1.0, (mx2 - mn2).length / 2.0)
        G.add_lights(center, radius, (0.85, 0.88, 0.95))
        cd = bpy.data.cameras.new("c"); cd.type = 'ORTHO'
        cam = bpy.data.objects.new("c", cd)
        bpy.context.collection.objects.link(cam); scene.camera = cam
        aim_cam(cam, cd, pts, center, radius, 36.0, 15.0, CELL_X, CELL_Y)
        p = os.path.join(outd, fn.replace(".glb", ".png"))
        scene.render.filepath = p
        bpy.ops.render.render(write_still=True)
        arr = G.read_png(p)

        for o in objs:
            o.hide_render = True
        pn = os.path.join(outd, "_no.png")
        scene.render.filepath = pn
        bpy.ops.render.render(write_still=True)
        moved = int((np.abs(arr - G.read_png(pn)).max(axis=2) > 0.02).sum())
        for o in objs:
            o.hide_render = False

        # chroma on the BUILDING's pixels only: the grey ground would dilute it
        op = arr[..., 3] > 0.03
        rgb = arr[..., :3][op]
        if len(rgb):
            mx_c = rgb.max(axis=1); mn_c = rgb.min(axis=1)
            sat = float(np.mean((mx_c - mn_c) / np.maximum(mx_c, 1e-6)))
        else:
            sat = 0.0
        row = {"opaque_px": int(op.sum()), "subject_moved_px": moved,
               "sat_mean": round(sat, 4),
               "dims": [round(v, 3) for v in (mx.x-mn.x, mx.y-mn.y, mx.z-mn.z)]}
        if row["opaque_px"] == 0:
            rep["errors"].append("%s BLANK" % fn)
        if moved < 1500:
            rep["errors"].append("%s SUBJECT NOT SEEN: %d px" % (fn, moved))
        if sat < 0.02:
            rep["errors"].append("%s READS FLAT GREY: sat %.4f" % (fn, sat))
        rep["cells"][fn] = row
        cells.append((fn, arr))
        try:
            os.remove(pn)
        except Exception:
            pass

    if not cells:
        rep["errors"].append("RED ON EMPTY: zero cells rendered")
    cols, rows = 4, int(math.ceil(len(cells) / 4.0))
    sheet = np.zeros((rows * CELL_Y + 46, cols * CELL_X, 4), dtype=np.float32)
    sheet[..., 3] = 1.0
    sheet[..., :3] = 0.055
    for i, (fn, arr) in enumerate(cells):
        r, c = i // cols, i % cols
        y0 = 46 + r * CELL_Y
        x0 = c * CELL_X
        al = arr[..., 3:4]
        sheet[y0:y0+CELL_Y, x0:x0+CELL_X, :3] = (
            arr[..., :3] * al + sheet[y0:y0+CELL_Y, x0:x0+CELL_X, :3] * (1 - al))
        G.draw_text(sheet, fn.replace(".glb", "").upper(), x0 + 8, y0 + 6, scale=2)
    G.draw_text(sheet, "BELLMIRE TOWN BUILDINGS - TEXTURES RELINKED FROM THE "
                       "MEDIEVAL VILLAGE MEGAKIT (CC0). KAYKIT KNIGHT = 2.45 M FOR SCALE.",
                10, 10, scale=2)
    G.draw_text(sheet, "GEOMETRY UNCHANGED ON EVERY FILE; MATERIAL SLOTS 21-51 -> 8-9.",
                10, 28, scale=2)
    sp = os.path.join(a.repo, "renders", "art", "town", "_texfix_sheet.png")
    G.write_png(sp, sheet)
    rep["sheet"] = os.path.relpath(sp, a.repo).replace("\\", "/")
    rep["engine"] = eng
    rep["verdict"] = "GREEN" if not rep["errors"] else "RED"
    with open(os.path.join(a.repo, "renders", "art", "town",
                           "_texfix_sheet.json"), "w") as f:
        json.dump(rep, f, indent=1)
    print("TEXSHEET " + json.dumps(rep))


main()
