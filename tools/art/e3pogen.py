"""e3pogen - headless Blender driver for D85, THE COMMANDER OF THE GUARDS.

  blender -b -noaudio -P tools/art/e3pogen.py -- --repo <repo> [--res 720x1000]

Reads Knight.glb for MEASUREMENT ONLY (KayKit, CC0, already in the repo and not
re-exported), builds E3PO's original kit against the real rig, exports it,
renders him alone at three wear levels and then standing between two ordinary
guards at pane distance, and asserts every PNG has opaque pixels.

The two traps this guards against, both of which cost real time on 15 Nov:
  SCALE  - clip range and camera distance come from the EVALUATED world bounds
           of the real geometry. A wrong clip_end renders an empty transparent
           frame and reports success.
  BLANKS - every PNG is re-opened and its opaque pixel count asserted.
"""
import os
import sys
import math
import json
import argparse

import bpy
import numpy as np
from mathutils import Vector, Matrix

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordlib as L          # noqa: E402
import lordgen as G          # noqa: E402  (font, png io, box2 - already proven)
import e3po as E             # noqa: E402

GUARD_TINT = (0.74, 0.82, 1.00)      # town.gd:4627 - what every guard is today
E3PO_TINT = (0.17, 0.18, 0.22)       # near-black plate: the mantle and crest carry the white
WEARS = (0.12, 0.45, 0.85)           # level 12 / mid / level 1 Bellmire
VIEWS = (("front", 0.0, 10.0), ("three_quarter", -42.0, 12.0), ("back", 180.0, 10.0))


# ------------------------------------------------------------------ rig import
def import_knight(path, tag):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [ob for ob in bpy.data.objects if ob not in before]
    # a stray 42-vertex Icosphere with no material turns up on import - never
    # render it. CORRECTED 19 Nov 2026: the file does NOT "ship" it; it is a
    # Blender glTF-import artifact for any glb with an armature. Dropping it is
    # still right. See docs/art/MONSTER_VARIANTS.md.
    for ob in list(new):
        if ob.type == 'MESH' and not ob.data.materials:
            bpy.data.objects.remove(ob, do_unlink=True)
            new.remove(ob)
    arm = next(ob for ob in new if ob.type == 'ARMATURE')
    arm.name = "rig_" + tag
    meshes = [ob for ob in new if ob.type == 'MESH']
    return arm, meshes


def tint_meshes(meshes, rgb, tag, wear=0.4):
    """Multiply the KayKit atlas by a tint, the way town.gd tints a body. The
    texture survives, so the render is honest about what the game will show."""
    done = {}
    for ob in meshes:
        for i, m in enumerate(list(ob.data.materials)):
            if m is None:
                continue
            if m.name in done:
                ob.data.materials[i] = done[m.name]
                continue
            nm = m.copy()
            nm.name = "%s_%s" % (m.name, tag)
            nt = nm.node_tree
            bsdf = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
            if bsdf is not None and 'Base Color' in bsdf.inputs:
                sock = bsdf.inputs['Base Color']
                if sock.is_linked:
                    src = sock.links[0].from_socket
                    nt.links.remove(sock.links[0])
                    mixn = nt.nodes.new('ShaderNodeMixRGB')
                    mixn.blend_type = 'MULTIPLY'
                    mixn.inputs['Fac'].default_value = 1.0
                    mixn.inputs['Color2'].default_value = (rgb[0], rgb[1], rgb[2], 1.0)
                    nt.links.new(src, mixn.inputs['Color1'])
                    nt.links.new(mixn.outputs['Color'], sock)
                else:
                    sock.default_value = (rgb[0], rgb[1], rgb[2], 1.0)
                if 'Roughness' in bsdf.inputs and not bsdf.inputs['Roughness'].is_linked:
                    bsdf.inputs['Roughness'].default_value = 0.42 + 0.34 * wear
            done[m.name] = nm
            ob.data.materials[i] = nm


def rest_anchors(arm):
    """Bone heads in rest world space, plus the measurements the kit needs."""
    a = {}
    for b in arm.data.bones:
        a[b.name] = arm.matrix_world @ b.head_local
    return a


def mesh_bounds(objs):
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    for ob in objs:
        obe = ob.evaluated_get(dg)
        try:
            me = obe.to_mesh()
        except Exception:
            continue
        mw = obe.matrix_world
        for v in me.vertices:
            pts.append(mw @ v.co)
        obe.to_mesh_clear()
    if not pts:
        raise RuntimeError("no geometry: refusing to measure an empty set")
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return mn, mx, pts


def measure_rig(meshes):
    byname = {}
    for ob in meshes:
        key = ob.name.split('.')[0]
        byname.setdefault(key, []).append(ob)
    helm = byname.get("Knight_Helmet") or byname.get("Knight_Head")
    hmn, hmx, _ = mesh_bounds(helm)
    cape = byname.get("Knight_Cape")
    cmn, cmx, _ = mesh_bounds(cape) if cape else (hmn, hmx, None)
    amn, amx, _ = mesh_bounds(meshes)
    return dict(helmet_top=hmx.z, helmet_r=max(hmx.x - hmn.x, hmx.y - hmn.y) / 2.0,
                cape_top=cmx.z, cape_bottom=cmn.z, body_height=amx.z - amn.z,
                foot_z=amn.z)


# ------------------------------------------------------------------------ pose
def pose_at_post(arm, grip=False):
    """A man standing a watch: arms down, not a T-pose. Rotating about the
    armature's own Y swings a +X arm down and a -X arm down with the sign
    flipped, so the two sides take opposite angles."""
    bpy.context.view_layer.objects.active = arm
    plan = [("upperarm.l", 1.26), ("lowerarm.l", 0.16),
            ("upperarm.r", -1.20), ("lowerarm.r", -0.22)]
    for name, ang in plan:
        pb = arm.pose.bones.get(name)
        if pb is None:
            continue
        # PIVOT: the parent has already moved, so a child bone must turn about
        # its POSED head. Turning lowerarm about its rest head threw both
        # forearms across the frame in the first pass.
        head = pb.matrix.translation.copy()
        R = (Matrix.Translation(head) @ Matrix.Rotation(ang, 4, 'Y')
             @ Matrix.Translation(-head))
        pb.matrix = R @ pb.matrix
        bpy.context.view_layer.update()
    bpy.context.view_layer.update()


def bone_delta(arm, bone, translation_only=False):
    """Rigid-attach matrix taking rest-space geometry into the posed pose."""
    pb = arm.pose.bones.get(bone)
    if pb is None:
        return Matrix.Identity(4)
    rest = arm.data.bones[bone].matrix_local
    M = arm.matrix_world @ pb.matrix @ rest.inverted() @ arm.matrix_world.inverted()
    if translation_only:
        # a grounded polearm does not cartwheel when the shoulder turns, and
        # its butt stays on the cobbles - so it follows the hand in X/Y only
        head = arm.matrix_world @ arm.data.bones[bone].head_local
        posed = arm.matrix_world @ pb.matrix @ rest.inverted() @ head
        d = posed - head
        d.z = 0.0
        return Matrix.Translation(d)
    return M


# ------------------------------------------------------------------- kit build
TRANSLATION_ONLY = {"E3PO_Halberd"}
SLOTS = ('steel', 'cloth', 'brass', 'leather', 'haft')


def build_kit(anchors, measure, wear, arm=None, tag="", posed=False):
    """One object per material slot per part, merged - the Commander must not
    cost twenty draw calls. Origins sit on the bone the part hangs from."""
    mats = E.materials(wear)
    parts = E.build(anchors, measure, wear)
    objs, manifest = [], []
    for part in parts:
        groups = {}
        for verts, faces, slot in part.items:
            gv, gf = groups.setdefault(slot, ([], []))
            off = len(gv)
            gv.extend(verts)
            gf.extend([tuple(i + off for i in f) for f in faces])
        anchor = anchors[part.bone]
        delta = (bone_delta(arm, part.bone, part.name in TRANSLATION_ONLY)
                 if (posed and arm is not None) else Matrix.Identity(4))
        for slot, (gv, gf) in groups.items():
            moved = [delta @ v for v in gv]
            a = delta @ anchor if posed else anchor
            local = [v - a for v in moved]
            ob = L.make("%s_%s%s" % (part.name, slot, tag), local, gf, mats[slot])
            ob.location = a
            objs.append(ob)
        manifest.append(dict(part=part.name, bone=part.bone,
                             anchor=[round(anchor.x, 4), round(anchor.y, 4), round(anchor.z, 4)],
                             slots=sorted(groups.keys()),
                             follows_bone_rotation=(part.name not in TRANSLATION_ONLY)))
    bpy.context.view_layer.update()
    return objs, manifest


def export_glb(objs, path):
    for ob in bpy.data.objects:
        try:
            ob.select_set(ob in objs)
        except Exception:
            pass
    try:
        bpy.context.view_layer.objects.active = objs[0]
    except Exception:
        pass
    try:
        bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True)
        return True, ""
    except Exception as e:
        return False, str(e)[:300]


# --------------------------------------------------------------------- lights
def add_lights(center, radius, night=False):
    specs = (("key", (0.75, -1.0, 0.80), 'SUN', 2.6 if not night else 0.55, (1.0, 0.97, 0.91)),
             ("fill", (-1.0, -0.55, 0.30), 'AREA', 1.0, (0.70, 0.78, 1.0)),
             ("rim", (0.15, 1.0, 0.50), 'AREA', 1.0, (1.0, 0.86, 0.66) if not night else (0.55, 0.70, 1.0)))
    for name, d, kind, e, col in specs:
        li = bpy.data.lights.new(name, type=kind)
        li.color = col
        if kind == 'SUN':
            li.energy = e
        else:
            li.energy = 1500.0 * (radius / 3.0) ** 2 * (0.60 if night else 0.80)
            li.size = radius * 2.4
        ob = bpy.data.objects.new(name, li)
        bpy.context.collection.objects.link(ob)
        dirv = Vector(d).normalized()
        ob.location = center + dirv * (radius * 4.0)
        ob.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()


def setup_scene(resx, resy, transparent=True, night=False):
    scene = bpy.context.scene
    eng = G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = resx, resy
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = transparent
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes if n.type == 'BACKGROUND'), None)
    if bg:
        c = (0.012, 0.016, 0.030) if night else (0.055, 0.062, 0.078)
        bg.inputs['Color'].default_value = (c[0], c[1], c[2], 1.0)
        bg.inputs['Strength'].default_value = 1.0
    return eng


def render_ortho(objs, path, az, el, resx, resy, pad=1.10):
    """Framing derived from measured bounds. This is the anti-SCALE-trap path."""
    scene = bpy.context.scene
    mn, mx, pts = mesh_bounds(objs)
    center = (mn + mx) / 2.0
    radius = max(0.35, (mx - mn).length / 2.0)
    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    a, e = math.radians(az), math.radians(el)
    dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e))).normalized()
    cam.location = center + dirv * (radius * 4.0 + 2.0)
    cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
    bpy.context.view_layer.update()
    mw = cam.matrix_world
    right = (mw.to_3x3() @ Vector((1, 0, 0))).normalized()
    up = (mw.to_3x3() @ Vector((0, 1, 0))).normalized()
    fwd = (mw.to_3x3() @ Vector((0, 0, -1))).normalized()
    wide = max(abs((p - center).dot(right)) for p in pts) * 2.0
    tall = max(abs((p - center).dot(up)) for p in pts) * 2.0
    depth = [(p - cam.location).dot(fwd) for p in pts]
    cam_d.ortho_scale = max(tall, wide * (resy / float(resx))) * pad
    cam_d.clip_start = max(0.01, min(depth) - radius * 0.5)
    cam_d.clip_end = max(depth) + radius * 2.0 + 5.0
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam, do_unlink=True)
    return dict(ortho=round(cam_d.ortho_scale, 3),
                clip=[round(cam_d.clip_start, 3), round(cam_d.clip_end, 3)])


def render_pane(objs, path, resx, resy, az=26.0, el=11.0, zoom=1.0):
    """A perspective camera at the distance the stream's panes actually use:
    a 40-degree lens far enough back that three men fit the frame."""
    scene = bpy.context.scene
    mn, mx, pts = mesh_bounds(objs)
    center = (mn + mx) / 2.0
    center.z = mn.z + (mx.z - mn.z) * 0.52
    span = max((mx - mn).x, (mx - mn).y, (mx - mn).z)
    cam_d = bpy.data.cameras.new("pcam")
    cam_d.type = 'PERSP'
    cam_d.lens = 46.0
    cam = bpy.data.objects.new("pcam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    a, e = math.radians(az), math.radians(el)
    dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e))).normalized()
    dist = span * 1.85 / zoom
    cam.location = center + dirv * dist
    cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
    cam_d.clip_start = max(0.05, dist - span * 2.0)
    cam_d.clip_end = dist + span * 3.0 + 10.0
    bpy.context.view_layer.update()
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam, do_unlink=True)
    return dict(dist=round(dist, 2), clip=[round(cam_d.clip_start, 3), round(cam_d.clip_end, 3)])


# ------------------------------------------------------------------ main pass
def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--res", default="700x980")
    ap.add_argument("--stage", default="all")
    args = ap.parse_args(argv)
    resx, resy = (int(x) for x in args.res.split("x"))
    repo = args.repo
    knight = os.path.join(repo, "assets", "characters", "kaykit_adv2", "Knight.glb")
    outdir = os.path.join(repo, "renders", "art", "e3po")
    os.makedirs(outdir, exist_ok=True)
    report = {"ok": True, "errors": [], "knight": {}, "wear": {}, "pane": {}}

    # ---------- 1. solo, three wear levels, three views each
    for wear in WEARS:
        tagw = "w%02d" % int(wear * 100)
        G.purge()
        setup_scene(resx, resy, transparent=True)
        try:
            arm, meshes = import_knight(knight, tagw)
            measure = measure_rig(meshes)
            anchors = rest_anchors(arm)
            report["knight"] = {k: round(v, 4) for k, v in measure.items()}
            tint_meshes(meshes, E3PO_TINT, "e3po_" + tagw, wear * 0.5)
            pose_at_post(arm)
            kit, manifest = build_kit(anchors, measure, wear, arm, "_" + tagw, posed=True)
            allobjs = meshes + kit
            mn, mx, _ = mesh_bounds(allobjs)
            add_lights((mn + mx) / 2.0, max(0.5, (mx - mn).length / 2.0))
            cams = {}
            for vname, az, el in VIEWS:
                d = os.path.join(outdir, tagw)
                os.makedirs(d, exist_ok=True)
                cams[vname] = render_ortho(allobjs, os.path.join(d, vname + ".png"),
                                           az, el, resx, resy)
            report["wear"][tagw] = dict(wear=wear, parts=len(kit), manifest=manifest,
                                        tris=sum(len(o.data.polygons) for o in kit),
                                        cams=cams,
                                        height=round(mx.z - mn.z, 3))
        except Exception:
            import traceback
            report["ok"] = False
            report["errors"].append("solo %s: %s" % (tagw, traceback.format_exc()[-900:]))

    # ---------- 2. the exported kit, in REST space (what the game parents)
    G.purge()
    try:
        arm, meshes = import_knight(knight, "exp")
        measure = measure_rig(meshes)
        anchors = rest_anchors(arm)
        kit, manifest = build_kit(anchors, measure, 0.45, arm, "", posed=False)
        for ob in list(meshes) + [arm]:
            bpy.data.objects.remove(ob, do_unlink=True)
        # 18 Nov: these kits are ART WORKING BODIES, not game content, and
        # nothing in scripts/, web/ or data/ has ever referenced them. They
        # lived under assets/ where Godot imports everything it finds, which
        # is what put them on the supervisor's unreferenced-asset list two
        # hours running. renders/ carries a .gdignore, so this is also the
        # directory that stops Godot generating .import siblings for them.
        gdir = os.path.join(repo, "renders", "art", "d85")
        os.makedirs(gdir, exist_ok=True)
        ok, msg = export_glb(kit, os.path.join(gdir, "e3po_kit.glb"))
        report["export"] = dict(ok=ok, msg=msg, objects=[o.name for o in kit],
                                tris=sum(len(o.data.polygons) for o in kit),
                                manifest=manifest)
        if not ok:
            report["ok"] = False
    except Exception:
        import traceback
        report["ok"] = False
        report["errors"].append("export: %s" % traceback.format_exc()[-900:])

    # ---------- 3. THE DONE TEST: E3PO between two ordinary guards, day & night
    for night in (False, True):
        G.purge()
        setup_scene(1280, 720, transparent=False, night=night)
        try:
            allobjs = []
            for i, (tag, x, is_cmd) in enumerate((("guardA", -1.55, False),
                                                  ("e3po", 0.0, True),
                                                  ("guardB", 1.60, False))):
                arm, meshes = import_knight(knight, tag + ("_n" if night else ""))
                measure = measure_rig(meshes)
                anchors = rest_anchors(arm)
                yaw = math.radians(-9.0 + 9.0 * i)
                tint_meshes(meshes, E3PO_TINT if is_cmd else GUARD_TINT,
                            tag + ("_n" if night else ""), 0.45 if is_cmd else 0.55)
                pose_at_post(arm)
                objs = list(meshes)
                if is_cmd:
                    kit, _ = build_kit(anchors, measure, 0.45, arm,
                                       "_" + tag + ("_n" if night else ""), posed=True)
                    objs += kit
                R = Matrix.Translation((x, 0.35 if is_cmd else 0.0, 0.0)) @ Matrix.Rotation(yaw, 4, 'Z')
                # A mesh with an ARMATURE modifier already follows its rig.
                # Moving the mesh TOO double-applied the transform and threw
                # both forearms across the frame in the first two passes.
                for ob in objs:
                    if any(md.type == 'ARMATURE' for md in ob.modifiers):
                        continue
                    ob.matrix_world = R @ ob.matrix_world
                arm.matrix_world = R @ arm.matrix_world
                bpy.context.view_layer.update()
                allobjs += objs
            # a ground plane so they read as standing at a post, not floating
            mn, mx, _ = mesh_bounds(allobjs)
            gv, gf = L.box(14.0, 14.0, 0.2)
            ground = L.make("ground", gv, gf,
                            L.mat_solid("cobble", (0.085, 0.082, 0.078) if not night
                                        else (0.030, 0.032, 0.040), 0.85, 0.02))
            ground.location = (0, 0, mn.z - 0.1)
            bpy.context.view_layer.update()
            add_lights(Vector(((mn + mx) / 2.0)), max(0.8, (mx - mn).length / 2.0), night)
            nm = "_done_test_night.png" if night else "_done_test_day.png"
            report["pane"]["night" if night else "day"] = render_pane(
                allobjs, os.path.join(outdir, nm), 1280, 720, zoom=0.82)
        except Exception:
            import traceback
            report["ok"] = False
            report["errors"].append("pane %s: %s" % (night, traceback.format_exc()[-900:]))

    # ---------- 4. blank check + contact sheet
    G.purge()
    try:
        checked, bad, cells = [], [], []
        for tagw in ["w%02d" % int(w * 100) for w in WEARS]:
            for vname, _, _ in VIEWS:
                p = os.path.join(outdir, tagw, vname + ".png")
                if not os.path.isfile(p):
                    bad.append([p, "missing"])
                    continue
                a = G.read_png(p)
                n = int((a[..., 3] > 0.02).sum())
                checked.append([os.path.relpath(p, repo), n])
                if n < 800:
                    bad.append([p, "blank or near-blank: %d opaque px" % n])
                if vname == "three_quarter":
                    cells.append((tagw, a))
        for nm in ("_done_test_day.png", "_done_test_night.png"):
            p = os.path.join(outdir, nm)
            if not os.path.isfile(p):
                bad.append([p, "missing"])
                continue
            a = G.read_png(p)
            # opaque film: check it is not a flat frame instead
            lum = a[..., 0:3].mean(axis=2)
            spread = float(lum.max() - lum.min())
            checked.append([os.path.relpath(p, repo), int((a[..., 3] > 0.02).sum())])
            if spread < 0.05:
                bad.append([p, "flat frame: luminance spread %.3f" % spread])

        ch, cw = resy // 2, resx // 2
        lab = 34
        sheet = np.zeros((2 * (ch + lab), 3 * cw, 4), dtype=np.float32)
        sheet[..., 0:3] = np.array((0.055, 0.060, 0.075))
        sheet[..., 3] = 1.0
        for i, (tagw, a) in enumerate(cells[:3]):
            a2 = G.box2(a)
            cx, cy = i * cw, 0
            al = a2[..., 3:4]
            dst = sheet[cy:cy + ch, cx:cx + cw, 0:3]
            sheet[cy:cy + ch, cx:cx + cw, 0:3] = a2[..., 0:3] * al + dst * (1.0 - al)
            # silhouette of the same cell on the row below - the readability test
            m = (al[..., 0] > 0.45)
            cell = sheet[ch + lab:ch + lab + ch, cx:cx + cw, 0:3]
            cell[...] = np.array((0.93, 0.93, 0.90))
            cell[m] = np.array((0.06, 0.06, 0.08))
            wv = float(tagw[1:]) / 100.0
            tag = "WEAR %.2f  %s" % (wv, "LVL12 KEPT" if wv < 0.3 else
                                     ("LVL1 MAKE-DO" if wv > 0.6 else "MID"))
            G.draw_text(sheet, tag, cx + 8, cy + ch + 10, 2, (0.85, 0.80, 0.68))
            G.draw_text(sheet, "SILHOUETTE", cx + 8, ch + lab + ch + 10, 2, (0.85, 0.80, 0.68))
        G.write_png(os.path.join(outdir, "_contact_sheet.png"), sheet)
        report["blank_check"] = {"files": len(checked), "failures": bad, "checked": checked}
        if bad:
            report["ok"] = False
    except Exception:
        import traceback
        report["ok"] = False
        report["errors"].append("sheet: %s" % traceback.format_exc()[-900:])

    with open(os.path.join(outdir, "_report.json"), "w") as f:
        json.dump(report, f, indent=1)
    print("E3POGEN_REPORT " + json.dumps({"ok": report["ok"], "errors": report["errors"][:3],
                                          "blank": report.get("blank_check", {}).get("failures", [])[:6],
                                          "export": report.get("export", {}).get("ok"),
                                          "tris": report.get("export", {}).get("tris")}))


if __name__ == "__main__":
    main()
