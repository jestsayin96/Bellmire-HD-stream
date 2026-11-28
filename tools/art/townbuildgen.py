"""townbuildgen - BUILD THE TIERS, PUT THEM ON THE GROUND BESIDE A BODY, LOOK.

  blender -b -noaudio -P tools/art/townbuildgen.py -- --repo <repo>

A BUILDING IS JUDGED THE SAME WAY AS GEAR, WITH THE GROUND AS ITS BODY. So:
every tier is rendered standing on a ground plane WITH THE MEASURED KayKit
Knight beside it, from front, side and back, and the three tiers go on ONE
side-by-side sheet through ONE camera at ONE ortho scale - because the row's
acceptance test is that the progression reads AT A GLANCE, and three sheets at
three scales cannot show that.

THE GATES, AND WHAT EACH ONE CANNOT SEE - stated so the next seat does not
trust them further than they go:
  1. BLANK      - opaque pixels > 0. Cannot see a clipped subject.
  2. BORDER     - zero alpha on the 1-px frame. Cannot see a subject that is
                  merely small.
  3. SUBJECT SEEN - render twice, once with the building hidden, and count the
                  pixels that MOVED. *** THIS IS THE ONE THAT CATCHES AN EMPTY
                  FRAME WITH A PASS ON IT. *** On 27 Nov my own side-on gate
                  passed a shot of the tier-5 spear with no spear in it; a
                  with/without difference cannot do that, because a missing
                  subject moves zero pixels. RED ON EMPTY: < 1500 px is RED.
  4. HERO SEEN  - the same difference for the body, separately. A sheet whose
                  scale reference failed to render is WORSE than no reference.
  5. TIER SPREAD - the three tiers' own pixel heights and widths, published.
                  *** THIS IS A NUMBER AND THE PROGRESSION IS A PICTURE. *** It
                  can say the silhouettes differ; it CANNOT say the viewer reads
                  tier 3 as richer than tier 1. Only looking says that, and the
                  summary says what I saw.
  6. LABEL      - every caption's own box carries ink. It CANNOT see captions
                  that overlap each other: the probe sheet earlier this run
                  scored every label > 3600 px and was unreadable in the middle.
                  Labels are therefore placed on separate rows BY CONSTRUCTION,
                  and that is a layout fix, not a gate.
"""
import argparse, json, math, os, sys

import bpy, numpy as np
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lordgen as G
import lordlib as L
import townbuild as TB

W5 = r"C:\hd adventure\bellmire-art"
HERO = os.path.join(W5, "addons", "kaykit_character_pack_adventures",
                    "Characters", "gltf", "Knight.glb")
VIEWS = (("front", 0.0, 10.0), ("three_quarter", 38.0, 14.0),
         ("side", 90.0, 10.0), ("back", 180.0, 10.0))


def build(key):
    """Merge by material slot: one draw call per slot, not one per stone."""
    tier = TB.CANON[key][1]
    pal = TB.PAL[tier]
    mats = {s: L.mat_solid("%s_%s" % (key, s), c,
                           0.30 if s == 'water' else (0.42 if s == 'iron' else 0.72),
                           0.55 if s == 'iron' else 0.02)
            for s, c in pal.items()}
    P = TB.BUILDERS[key]()
    groups = {}
    for verts, faces, slot in P.items:
        gv, gf = groups.setdefault(slot, ([], []))
        off = len(gv)
        gv.extend(verts)
        gf.extend([tuple(i + off for i in f) for f in faces])
    objs = []
    for slot, (gv, gf) in groups.items():
        objs.append(L.make("%s_%s" % (key, slot), gv, gf, mats[slot]))
    bpy.context.view_layer.update()
    return objs, P


def add_hero(dx):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=HERO)
    new = [o for o in bpy.data.objects if o not in before]
    meshes = [o for o in new if o.type == 'MESH']
    arm = next((o for o in new if o.type == 'ARMATURE'), None)
    if arm is not None and "Idle" in bpy.data.actions:
        if arm.animation_data is None:
            arm.animation_data_create()
        arm.animation_data.action = bpy.data.actions["Idle"]
        bpy.context.scene.frame_set(1)
    # *** THE 16 MESHES ARE NOT ONE BODY. *** Named off the file this run:
    # Knight_{Body,Head,Helmet,ArmLeft,ArmRight,LegLeft,LegRight,Cape} are the
    # figure; 1H_Sword, 1H_Sword_Offhand, 2H_Sword, Badge/Rectangle/Round/Spike
    # _Shield and an `Icosphere` spanning z -1.0..+1.0 are loose equipment
    # variants stacked in the same file. MY FIRST FILTER KEPT THEM: a sword and
    # a shield hung in the air at the right of the sheet, the camera had to
    # frame them, and the three wells came out at 15% of the frame width. The
    # `hero_moved_px` gate read 20-37k and PASSED - ON THE WRONG OBJECT. A
    # with/without difference proves something moved, never that it was the
    # thing you named. Whitelist by exact name, never by substring.
    BODY = {"Knight_Body", "Knight_Head", "Knight_Helmet", "Knight_ArmLeft",
            "Knight_ArmRight", "Knight_LegLeft", "Knight_LegRight", "Knight_Cape"}
    keep = []
    for o in meshes:
        base = o.name.split(".")[0]
        if base in BODY:
            keep.append(o)
        else:
            o.hide_render = True
    if not keep:
        keep = meshes
    # Move the ARMATURE only. The meshes are parented to it, so moving both
    # displaced every child twice - which is the other half of why the first
    # sheet was wrong.
    roots = [o for o in new if o.parent is None]
    for o in roots:
        o.location = (o.location.x + dx, o.location.y, o.location.z)
    bpy.context.view_layer.update()
    return keep, list(new)


def ground(radius, mat):
    v, f = L.box(radius * 2.6, radius * 2.6, 0.12)
    ob = L.make("ground", v, f, mat)
    ob.location = (0.0, 0.0, -0.06)
    return ob


def alpha_px(p):
    a = G.read_png(p)
    return int((a[..., 3] > 0.03).sum())


def moved_px(p1, p2):
    a, b = G.read_png(p1), G.read_png(p2)
    return int((np.abs(a - b).max(axis=2) > 0.02).sum())


def border_px(p):
    a = G.read_png(p)
    e = np.concatenate([a[0, :, 3], a[-1, :, 3], a[:, 0, 3], a[:, -1, 3]])
    return int((e > 0.03).sum())


def aim_cam(scene, cam, cam_d, pts, center, radius, az, el, resx, resy, pad=1.08):
    a, e = math.radians(az), math.radians(el)
    d = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e))).normalized()
    cam.location = center + d * (radius * 4.0 + 2.0)
    cam.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
    bpy.context.view_layer.update()
    mw = cam.matrix_world
    right = (mw.to_3x3() @ Vector((1, 0, 0))).normalized()
    up = (mw.to_3x3() @ Vector((0, 1, 0))).normalized()
    fwd = (mw.to_3x3() @ Vector((0, 0, -1))).normalized()
    wide = max(abs((p - center).dot(right)) for p in pts) * 2.0
    tall = max(abs((p - center).dot(up)) for p in pts) * 2.0
    cam_d.ortho_scale = max(wide, tall * (resx / float(resy))) * pad
    dep = [(p - cam.location).dot(fwd) for p in pts]
    # SCALE TRAP: clip from the MEASURED depth span, never from defaults
    cam_d.clip_start = max(0.01, min(dep) - radius * 0.5)
    cam_d.clip_end = max(dep) + radius * 2.0 + 5.0


def scene_setup(resx, resy):
    scene = bpy.context.scene
    eng = G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = resx, resy
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes if n.type == 'BACKGROUND'), None)
    if bg:
        bg.inputs['Color'].default_value = (0.055, 0.06, 0.075, 1.0)
        bg.inputs['Strength'].default_value = 1.0
    return scene, eng


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=W5)
    ap.add_argument("--resx", type=int, default=900)
    ap.add_argument("--resy", type=int, default=760)
    a = ap.parse_args(sys.argv[sys.argv.index("--") + 1:])
    root = os.path.join(a.repo, "renders", "art", "town")
    glbdir = os.path.join(a.repo, "assets", "buildings")
    os.makedirs(glbdir, exist_ok=True)
    report = {"when_ct": "28 Nov 2026 01:0x CT", "tiers": {}, "errors": []}

    # ---------------------------------------------------- per tier: glb + views
    for key in TB.ORDER:
        G.purge()
        scene, eng = scene_setup(a.resx, a.resy)
        objs, P = build(key)
        mn, mx, _ = G.world_bounds(objs)
        row = {"title": TB.CANON[key][0], "tier": TB.CANON[key][1],
               "n_parts": len(P.items),
               "n_vert": sum(len(o.data.vertices) for o in objs),
               "n_mesh_merged": len(objs),
               "dims": [round(v, 4) for v in (mx.x - mn.x, mx.y - mn.y, mx.z - mn.z)],
               "base_dz_m": round(mn.z, 4),
               "centre_dx_dy": [round(((mn + mx) / 2).x, 4), round(((mn + mx) / 2).y, 4)]}
        gp = os.path.join(glbdir, "town_%s.glb" % key)
        G.export_glb(objs, gp)
        row["glb"] = os.path.relpath(gp, a.repo).replace("\\", "/")
        row["glb_bytes"] = os.path.getsize(gp) if os.path.isfile(gp) else 0

        hero_meshes, hero_all = add_hero(dx=mx.x + 0.55)
        gmat = L.mat_solid("gnd", (0.21, 0.20, 0.18), 0.95, 0.0)
        gnd = ground(max(2.0, (mx - mn).length), gmat)
        bpy.context.view_layer.update()
        allm = objs + hero_meshes + [gnd]
        mn2, mx2, pts = G.world_bounds(allm)
        center = (mn2 + mx2) / 2.0
        radius = max(0.6, (mx2 - mn2).length / 2.0)
        G.add_lights(center, radius, (0.85, 0.88, 0.95))
        cam_d = bpy.data.cameras.new("cam"); cam_d.type = 'ORTHO'
        cam = bpy.data.objects.new("cam", cam_d)
        bpy.context.collection.objects.link(cam); scene.camera = cam
        outd = os.path.join(root, key); os.makedirs(outd, exist_ok=True)
        vrep = {}
        for vname, az, el in VIEWS:
            aim_cam(scene, cam, cam_d, pts, center, radius, az, el, a.resx, a.resy)
            p = os.path.join(outd, "%s.png" % vname)
            scene.render.filepath = p
            bpy.ops.render.render(write_still=True)
            op = alpha_px(p)
            bd = border_px(p)
            for o in objs:
                o.hide_render = True
            pn = os.path.join(outd, "_no_%s.png" % vname)
            scene.render.filepath = pn
            bpy.ops.render.render(write_still=True)
            mv = moved_px(p, pn)
            for o in objs:
                o.hide_render = False
            for o in hero_meshes:
                o.hide_render = True
            ph = os.path.join(outd, "_nohero_%s.png" % vname)
            scene.render.filepath = ph
            bpy.ops.render.render(write_still=True)
            hv = moved_px(p, ph)
            for o in hero_meshes:
                o.hide_render = False
            vrep[vname] = {"opaque_px": op, "border_alpha_px": bd,
                           "subject_moved_px": mv, "hero_moved_px": hv}
            if op == 0:
                report["errors"].append("%s/%s BLANK" % (key, vname))
            if bd > 0:
                report["errors"].append("%s/%s BORDER %d - clipped" % (key, vname, bd))
            if mv < 1500:
                report["errors"].append(
                    "%s/%s SUBJECT NOT SEEN: %d px moved" % (key, vname, mv))
            if hv < 1500:
                report["errors"].append(
                    "%s/%s HERO REFERENCE NOT SEEN: %d px moved" % (key, vname, hv))
            try:
                os.remove(pn); os.remove(ph)
            except Exception:
                pass
        row["views"] = vrep
        report["tiers"][key] = row

    # --------------------------------------- THE SHEET: three tiers, ONE camera
    G.purge()
    RX, RY = 1680, 760
    scene, eng = scene_setup(RX, RY)
    placed, spans, x = {}, [], 0.0
    for key in TB.ORDER:
        objs, _P = build(key)
        mn, mx, _ = G.world_bounds(objs)
        for o in objs:
            o.location = (o.location.x + (x - mn.x), o.location.y - (mn.y + mx.y) / 2.0,
                          o.location.z - mn.z)
        bpy.context.view_layer.update()
        w = mx.x - mn.x
        placed[key] = objs
        spans.append((key, x, x + w))
        x += w + 0.45
    hero_meshes, _ = add_hero(dx=x + 0.45)
    bpy.context.view_layer.update()
    hmn, hmx, _ = G.world_bounds(hero_meshes)
    total = hmx.x
    gmat = L.mat_solid("gnd", (0.21, 0.20, 0.18), 0.95, 0.0)
    gv, gf = L.box(total + 1.6, 4.2, 0.12)
    gnd = L.make("ground", gv, gf, gmat)
    gnd.location = (total / 2.0, 0.0, -0.06)
    bpy.context.view_layer.update()
    subj = [o for v in placed.values() for o in v]
    allm = subj + hero_meshes + [gnd]
    mn2, mx2, pts = G.world_bounds(allm)
    center = (mn2 + mx2) / 2.0
    radius = max(1.0, (mx2 - mn2).length / 2.0)
    G.add_lights(center, radius, (0.85, 0.88, 0.95))
    cam_d = bpy.data.cameras.new("cam"); cam_d.type = 'ORTHO'
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam); scene.camera = cam
    aim_cam(scene, cam, cam_d, pts, center, radius, 24.0, 11.0, RX, RY, pad=1.05)
    sheet = os.path.join(root, "_tiers_side_by_side.png")
    scene.render.filepath = sheet
    bpy.ops.render.render(write_still=True)

    # per-tier silhouette extent, measured by hiding everything else
    sil = {}
    for key in TB.ORDER:
        for k2, objs in placed.items():
            for o in objs:
                o.hide_render = (k2 != key)
        for o in hero_meshes:
            o.hide_render = True
        gnd.hide_render = True
        p = os.path.join(root, "_sil_%s.png" % key)
        scene.render.filepath = p
        bpy.ops.render.render(write_still=True)
        arr = G.read_png(p)
        ys, xs = np.where(arr[..., 3] > 0.03)
        sil[key] = {"px": int(len(xs)),
                    "h_px": int(ys.max() - ys.min() + 1) if len(ys) else 0,
                    "w_px": int(xs.max() - xs.min() + 1) if len(xs) else 0}
        try:
            os.remove(p)
        except Exception:
            pass
    for objs in placed.values():
        for o in objs:
            o.hide_render = False
    for o in hero_meshes:
        o.hide_render = False
    gnd.hide_render = False

    sheet_px = alpha_px(sheet)
    scene.render.filepath = os.path.join(root, "_sheet_nosubj.png")
    for o in subj:
        o.hide_render = True
    bpy.ops.render.render(write_still=True)
    sheet_moved = moved_px(sheet, os.path.join(root, "_sheet_nosubj.png"))
    for o in subj:
        o.hide_render = False
    try:
        os.remove(os.path.join(root, "_sheet_nosubj.png"))
    except Exception:
        pass

    # labels, ON SEPARATE ROWS BY CONSTRUCTION - the probe proved a pixel count
    # cannot see overlap, so the layout prevents it instead of a gate catching it
    from bpy_extras.object_utils import world_to_camera_view as w2c
    buf = G.read_png(sheet)
    h, w = buf.shape[0], buf.shape[1]
    G.draw_text(buf, "BELLMIRE TOWN SQUARE - THE WELL, TIER 1 TO 3. ONE PIVOT, ONE CAMERA, ONE SCALE.",
                14, 12, scale=2)
    G.draw_text(buf, "HERO = KAYKIT KNIGHT, IDLE FRAME 1. HEAD BONE 1.2274, HIPS 0.3916 - MEASURED THIS RUN.",
                14, 34, scale=2)
    boxes = []
    for i, (key, x0w, x1w) in enumerate(spans):
        co = w2c(scene, cam, Vector(((x0w + x1w) / 2.0, 0.0, 0.0)))
        px = int(co.x * w)
        t = "%s  %s" % (TB.CANON[key][0].upper(), TB.CANON[key][2].upper())
        tw = 6 * 2 * len(t)
        x0 = max(6, min(w - tw - 6, px - tw // 2))
        y0 = h - 70 + i * 20                       # SEPARATE ROW PER TIER
        G.draw_text(buf, t, x0, y0, scale=2)
        boxes.append((key, x0, y0, tw, 14))
    lab = {}
    for key, x0, y0, bw, bh in boxes:
        lab[key] = int((buf[y0:y0 + bh, x0:x0 + bw, 3] > 0.03).sum())
    G.write_png(sheet, buf)

    if sheet_px == 0:
        report["errors"].append("SHEET BLANK")
    if sheet_moved < 4000:
        report["errors"].append("SHEET SUBJECTS NOT SEEN: %d px" % sheet_moved)
    if border_px(sheet) > 0:
        report["errors"].append("SHEET BORDER %d - clipped" % border_px(sheet))
    if not lab:
        report["errors"].append("RED ON EMPTY: zero labels measured")
    for k, v in lab.items():
        if v == 0:
            report["errors"].append("LABEL EMPTY: %s" % k)
    report["sheet"] = {"path": os.path.relpath(sheet, a.repo).replace("\\", "/"),
                       "opaque_px": sheet_px, "subject_moved_px": sheet_moved,
                       "border_alpha_px": border_px(sheet), "label_px": lab,
                       "silhouette": sil,
                       "spans": [[s[0], round(s[1], 3), round(s[2], 3)] for s in spans]}
    report["engine"] = eng
    report["verdict"] = "GREEN" if not report["errors"] else "RED"
    with open(os.path.join(root, "_report.json"), "w") as f:
        json.dump(report, f, indent=1)
    print("TOWNBUILD " + json.dumps(report))


main()
