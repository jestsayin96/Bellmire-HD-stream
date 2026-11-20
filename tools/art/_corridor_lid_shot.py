"""_corridor_lid_shot - A PICTURE OF THE CORRIDOR AND LID VERDICT.

  blender -b -noaudio -P tools/art/_corridor_lid_shot.py -- --repo <repo>
          [--manifest renders/art/worldfit/_packs_manifest.json]

20 Nov 2026. THIS CLOSES A GAP I LISTED AGAINST MY OWN RUN AT 09:0x CT:

    "And the biggest gap: there is no picture of the corridor or lid verdict at
     all - the 185-model '0 ROOM-LOCKED' rests on arithmetic against floorgeom's
     two terms plus the stamp."

The game build is about to batch-wire 185 models on that arithmetic. Arithmetic
compares `footprint_m` to 11.0 and `height_m` to 9.5 and never once draws the
corridor. So here the corridor is BUILT at floorgeom's own stamped numbers and
the models are put inside it, and the breach is counted IN PIXELS through one
camera - the renderer does the projection, not me.

TWO VIEWS, DIFFERENT JOBS:
  A `xsec`  - orthographic along +Y. The clear volume's corners are projected
              through `world_to_camera_view`, so the rectangle on the sheet is
              the RENDERER's idea of where the walls and the lid are. Model
              alpha outside that rectangle is a breach, counted per side.
  B `down`  - a perspective camera standing INSIDE real wall/floor/lid geometry
              at eye height. This is the one a human reads at a glance.

*** WHY THE SAME MODEL IS SHOT AT THREE YAWS, AND IT IS THE POINT OF THE RUN. ***
`footprint_m` is `max(dx, dy)`. A corridor constrains ONE horizontal axis. For a
CREATURE that can turn any way, max() is the right conservative term. For a
PLACED PROP the placer chooses the yaw, so max() can condemn a model that would
fit turned. Every one of the six Medieval Village rows flagged over-corridor is
a long modular roof strip whose SHORT axis fits 11.0 m with room to spare. So
each pick is measured at yaw 0 / 45 / 90 and the sheet shows the same mesh
breaching at one yaw and clear at another.

THE PIVOT IS NOT RE-CENTRED. A spawner puts the pivot on the corridor's centre
line; 315 of 669 rows carry `needs_centring`, so an off-centre pivot can breach
one wall with room at the other. That is a finding, not a framing error, and the
per-pick `centre_dx_m` is published beside the pixel counts.

RED ON EMPTY AND RED ON BLIND:
  - zero model pixels in a frame is RED, never clean (pass-11 lesson).
  - the picks include rows the manifest says MUST breach (the 10.774 m tree is
    1.274 m through the lid at every yaw; the 15.7059 m roof breaches at the yaw
    that puts its long axis across). If an expected breach counts ZERO pixels
    the instrument is BLIND and the run says so instead of reporting green.
"""
import argparse
import json
import math
import os
import sys

import bpy
import numpy as np
from bpy_extras.object_utils import world_to_camera_view as w2c
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lordgen as G  # noqa: E402

YAWS = (0, 45, 90)


def picks(man, corridor, lid):
    """OFF THE MANIFEST BY RANK. Two that must clear, two that must breach."""
    out = []
    d = man["dirs"]["pack:kaykit_dungeon_pack"]
    rows = [r for r in d["rows"] if not r["errors"]]
    widest = max(rows, key=lambda r: r["footprint_m"])
    tallest = max(rows, key=lambda r: r["height_m"])
    out.append(("dungeon widest", d["root"], widest, "clear"))
    out.append(("dungeon tallest", d["root"], tallest, "clear"))
    v = man["dirs"]["pack:Medieval_Village_MegaKit"]
    rows = [r for r in v["rows"] if not r["errors"]]
    out.append(("widest over-corridor row", v["root"],
                max(rows, key=lambda r: r["footprint_m"]), "breach_wall_some_yaw"))
    f = man["dirs"]["pack:KayKit_Forest_Nature"]
    rows = [r for r in f["rows"] if not r["errors"]]
    out.append(("only over-lid row", f["root"],
                max(rows, key=lambda r: r["height_m"]), "breach_lid_every_yaw"))
    return out


def mat(name, rgba, rough=0.7):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = rgba
    b.inputs["Roughness"].default_value = rough
    return m


def box(name, cx, cy, cz, sx, sy, sz, material):
    """size=1 cube is a UNIT cube: scale s gives EXTENT s, not 2s.

    That arithmetic cost me a whole re-render at 09:0x CT - the slab was half
    the width I had written and the worst FLOATER had no floor line under it.
    Extents go in here, never half-extents.
    """
    bpy.ops.mesh.primitive_cube_add(size=1)
    o = bpy.context.object
    o.name = name
    o.scale = (sx, sy, sz)
    o.location = (cx, cy, cz)
    o.data.materials.append(material)
    return o


def load(path):
    before = set(bpy.data.objects)
    if path.lower().endswith((".glb", ".gltf")):
        bpy.ops.import_scene.gltf(filepath=path)
    else:
        raise RuntimeError("unsupported: " + path)
    new = [o for o in bpy.data.objects if o not in before]
    return new, [o for o in new if o.type == 'MESH']


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--manifest", default="renders/art/worldfit/_packs_manifest.json")
    args = ap.parse_args(argv)
    mpath = args.manifest if os.path.isabs(args.manifest) else os.path.join(args.repo, args.manifest)
    man = json.load(open(mpath, encoding="utf-8"))
    fg = man["floorgeom"]
    CORR = float(fg["corridor_clear_m"])
    LID = float(fg["lid_underside_m"])
    HALF = CORR / 2.0
    outdir = os.path.join(args.repo, "renders", "art", "worldfit")
    os.makedirs(outdir, exist_ok=True)
    # *** THE STALE-GREEN GUARD, 20 NOV 10:0x CT. ***
    # Run 3 died on an UnboundLocalError and `blender -b -P` STILL EXITED 0.
    # The old `_corridor_lid.json` survived, and my own check read its GREEN
    # as this run's. rc 0 is not proof a script ran. The report is removed
    # before any work, so a crash leaves NO report rather than a stale pass.
    rep_path = os.path.join(outdir, "_corridor_lid.json")
    if os.path.isfile(rep_path):
        os.remove(rep_path)

    report = {"floorgeom": {"corridor_clear_m": CORR, "lid_underside_m": LID,
                            "stamp": fg.get("stamp"), "ref_commit": fg.get("ref_commit")},
              "frames": [], "errors": [], "checks": {}}
    PK = picks(man, CORR, LID)
    tiles = []

    RESX, RESY = 900, 780
    # the frame must hold the WORST pick or the border arm will cry clipping on
    # a model that is genuinely bigger than the corridor. Sized off the picks.
    worst_w = max(max(r["dims_m"][0], r["dims_m"][1]) for _, _, r, _ in PK)
    worst_h = max(r["height_m"] for _, _, r, _ in PK)
    FRAME_W = max(CORR + 4.0, worst_w * 1.45 + 2.0)
    FRAME_H = max(LID + 2.5, worst_h + 2.5)

    for label, root, row, expect in PK:
        src = os.path.join(root, row["rel"])
        for yaw in YAWS:
            frame = {"pick": label, "file": row["rel"], "root": root, "yaw_deg": yaw,
                     "expect": expect, "dims_m": row["dims_m"],
                     "height_m": row["height_m"], "footprint_m": row["footprint_m"],
                     "centre_dx_m": row.get("centre_dx_m"),
                     "base_dz_m": row.get("base_dz_m")}
            if not os.path.isfile(src):
                frame["error"] = "missing on disk"
                report["errors"].append(frame)
                continue
            bpy.ops.wm.read_homefile(use_empty=True)
            sc = bpy.context.scene
            sc.render.engine = 'BLENDER_EEVEE'
            sc.render.resolution_x, sc.render.resolution_y = RESX, RESY
            sc.render.film_transparent = False
            sc.world = bpy.data.worlds.new("w")
            sc.world.use_nodes = True
            sc.world.node_tree.nodes["Background"].inputs[0].default_value = (0.05, 0.055, 0.07, 1)

            stone = mat("stone", (0.30, 0.285, 0.265, 1))
            floor = mat("floor", (0.17, 0.16, 0.15, 1))
            lidm = mat("lid", (0.085, 0.082, 0.080, 1))
            # *** THE LID IS MADE SEE-THROUGH FOR THE `down` VIEW, AND THIS IS
            # *** THE SECOND FAULT I FOUND BY LOOKING RATHER THAN BY A NUMBER.
            # Run 2's down view showed the 10.774 m tree sitting COMFORTABLY
            # under the ceiling beside a caption reading BREACH. Both were
            # "true": the lid is opaque, so from an eye-height camera inside
            # the corridor it HIDES anything poking through it. A persuasion
            # view that cannot show the fault it is captioned with is worse
            # than no view. The `down_occluded_frac` arm below measures what
            # the lid still swallows.
            lidm.blend_method = 'BLEND'
            try:
                lidm.surface_render_method = 'BLENDED'
            except Exception:
                pass
            try:
                lidm.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = 0.30
            except Exception:
                pass
            try:
                lidm.show_transparent_back = False
            except Exception:
                pass
            # --- the corridor, at floorgeom's own numbers -------------------
            # inner faces EXACTLY at +-HALF; floor TOP exactly z=0; lid
            # UNDERSIDE exactly z=LID. Those three planes are the verdict.
            YLO, YHI = -30.0, 34.0
            YC, YD = (YLO + YHI) / 2.0, (YHI - YLO)
            fl = box("floor", 0.0, YC, -0.25, CORR + 2.4, YD, 0.50, floor)
            wl = box("wall_l", -(HALF + 0.35), YC, LID / 2.0, 0.70, YD, LID, stone)
            wr = box("wall_r", +(HALF + 0.35), YC, LID / 2.0, 0.70, YD, LID, stone)
            ld = box("lid", 0.0, YC, LID + 0.30, CORR + 2.4, YD, 0.60, lidm)
            shell = [fl, wl, wr, ld]

            new, meshes = load(src)
            if not meshes:
                frame["error"] = "no meshes"
                report["errors"].append(frame)
                continue
            roots = [o for o in new if o.parent is None]
            for o in roots:
                o.rotation_mode = 'XYZ'
                o.rotation_euler.z += math.radians(yaw)
            bpy.context.view_layer.update()
            # PIVOT to the centre line at y=6, z=0. NOT re-centred - a spawner
            # does not re-centre, so an off-centre pivot must be allowed to show.
            for o in roots:
                o.location.y += 6.0
            bpy.context.view_layer.update()
            mn, mx, _ = G.world_bounds(meshes)
            frame["measured_world"] = {"x": [round(mn.x, 4), round(mx.x, 4)],
                                       "z": [round(mn.z, 4), round(mx.z, 4)],
                                       "x_extent": round(mx.x - mn.x, 4)}

            # ---------------- camera A: orthographic cross-section ----------
            cad = bpy.data.cameras.new("cA")
            cad.type = 'ORTHO'
            cad.ortho_scale = max(FRAME_W, FRAME_H * RESX / float(RESY))
            cam = bpy.data.objects.new("camA", cad)
            sc.collection.objects.link(cam)
            cam.location = (0.0, -12.0, FRAME_H / 2.0 - 0.9)
            cam.rotation_euler = (math.radians(90), 0, 0)
            cad.clip_start = 0.05
            cad.clip_end = (YHI - (-12.0)) * 2.0 + 60.0      # TRAP 1, never 100 by default
            sc.camera = cam
            # *** LIGHTS GO INSIDE THE CORRIDOR. *** `lordgen.add_lights` puts a
            # SUN above and in front; the lid is solid, so it would shadow the
            # whole frame black and the blank arm would fire on a scene that is
            # built correctly. Four area lights inside the clear volume instead.
            sc.world.node_tree.nodes["Background"].inputs[1].default_value = 0.55
            for lx, ly, lz, le in ((-HALF + 1.0, 0.0, LID - 1.0, 3.0),
                                   (HALF - 1.0, 0.0, LID - 1.0, 3.0),
                                   (0.0, -6.0, LID * 0.55, 2.2),
                                   (0.0, 16.0, LID * 0.55, 1.6)):
                li = bpy.data.lights.new("l", type='AREA')
                # 4000 BLEW THE DOWN VIEW OUT TO WHITE ON WHITE on the first
                # run - I found it by looking, not by a number. See the
                # `down_white_frac` arm below, which exists because of it.
                li.energy = le * 900.0
                li.size = 5.0
                ob = bpy.data.objects.new("l", li)
                ob.location = (lx, ly, lz)
                ob.rotation_euler = (math.radians(70), 0, 0)
                sc.collection.objects.link(ob)

            sc.render.image_settings.file_format = 'PNG'
            sc.render.image_settings.color_mode = 'RGBA'
            lit = os.path.join(outdir, "_corr_%s_y%02d_xsec.png" % (
                row["rel"].split(".")[0][:28].lower(), yaw))
            sc.render.filepath = lit
            bpy.ops.render.render(write_still=True)

            # the clear rectangle AS THE RENDERER PROJECTS IT, not as I compute it
            pts = {"xl": (-HALF, 6.0, LID / 2.0), "xr": (HALF, 6.0, LID / 2.0),
                   "zf": (0.0, 6.0, 0.0), "zl": (0.0, 6.0, LID)}
            proj = {}
            for k, p in pts.items():
                co = w2c(sc, cam, Vector(p))
                proj[k] = (co.x * RESX, (1.0 - co.y) * RESY)
            px_l, px_r = proj["xl"][0], proj["xr"][0]
            py_floor, py_lid = proj["zf"][1], proj["zl"][1]
            frame["rect_px"] = {"wall_l": round(px_l, 2), "wall_r": round(px_r, 2),
                                "floor": round(py_floor, 2), "lid": round(py_lid, 2)}

            # model ALONE on transparent, same camera: alpha is the silhouette
            for o in shell:
                o.hide_render = True
            sc.render.film_transparent = True
            alone = os.path.join(outdir, "_corr_probe.png")
            sc.render.filepath = alone
            bpy.ops.render.render(write_still=True)
            a = G.read_png(alone)                       # (h, w, 4) top-down
            al = a[:, :, 3] > 0.5
            ys, xs = np.nonzero(al)
            n = int(al.sum())
            frame["model_px"] = n
            if n == 0:
                frame["error"] = "RED ON EMPTY - zero model pixels"
                report["errors"].append(frame)
                for p in (alone,):
                    pass
                continue
            frame["breach_px"] = {
                "wall_left": int((xs < px_l).sum()),
                "wall_right": int((xs > px_r).sum()),
                "lid": int((ys < py_lid).sum()),
                "below_floor": int((ys > py_floor).sum()),
            }
            frame["breach_px"]["wall_any"] = (frame["breach_px"]["wall_left"]
                                              + frame["breach_px"]["wall_right"])
            frame["border_px_frac"] = round(float(
                (al[0].sum() + al[-1].sum() + al[:, 0].sum() + al[:, -1].sum())
                / float(2 * al.shape[0] + 2 * al.shape[1])), 5)
            # the picture a human reads: lit frame + the projected rectangle
            # drawn ON it, so the lines are the renderer's, and a caption.
            buf = G.read_png(lit)
            h, w = buf.shape[0], buf.shape[1]

            def vline(x, rgb):
                x = int(round(x))
                if 0 <= x < w:
                    buf[:, max(0, x - 1):x + 2, 0:3] = rgb
                    buf[:, max(0, x - 1):x + 2, 3] = 1.0

            def hline(y, rgb):
                y = int(round(y))
                if 0 <= y < h:
                    buf[max(0, y - 1):y + 2, :, 0:3] = rgb
                    buf[max(0, y - 1):y + 2, :, 3] = 1.0

            vline(px_l, (0.95, 0.30, 0.25))
            vline(px_r, (0.95, 0.30, 0.25))
            hline(py_lid, (0.35, 0.75, 0.98))
            hline(py_floor, (0.95, 0.85, 0.30))
            b = frame["breach_px"]
            verdict = "CLEAR" if (b["wall_any"] == 0 and b["lid"] == 0) else "BREACH"
            cap1 = "%s  YAW %d" % (row["rel"].split(".")[0][:26], yaw)
            cap2 = "X ACROSS %.2fM  H %.2fM  CORR %.1fM  LID %.1fM" % (
                frame["measured_world"]["x_extent"], row["height_m"], CORR, LID)
            cap3 = "%s  WALLPX %d  LIDPX %d" % (verdict, b["wall_any"], b["lid"])
            G.draw_text(buf, cap1, 10, 10, 2, (0.95, 0.93, 0.88))
            G.draw_text(buf, cap2, 10, 32, 2, (0.80, 0.84, 0.90))
            G.draw_text(buf, cap3, 10, 54, 2,
                        (0.98, 0.45, 0.35) if verdict == "BREACH" else (0.50, 0.92, 0.55))
            frame["verdict"] = verdict
            # EVERY CAPTION IS CHECKED IN ITS OWN BOX. A caption that silently
            # failed to render would make this sheet worse than no caption.
            lab_ok = 0
            for yy, txt in ((10, cap1), (32, cap2), (54, cap3)):
                bx = buf[yy:yy + 16, 8:8 + min(w - 8, 6 * 2 * len(txt) + 4), 0:3]
                if bx.size and float(bx.max()) > 0.40:
                    lab_ok += 1
            frame["captions_rendered"] = lab_ok
            G.write_png(lit, buf)
            tiles.append(buf)

            # ---------------- camera B: standing in the corridor ------------
            for o in shell:
                o.hide_render = False
            sc.render.film_transparent = False
            cbd = bpy.data.cameras.new("cB")
            cbd.type = 'PERSP'
            cbd.lens = 35.0
            cbd.clip_start = 0.05
            cbd.clip_end = 400.0
            cb = bpy.data.objects.new("camB", cbd)
            sc.collection.objects.link(cb)
            cb.location = (0.0, -20.0, 1.70)       # eye height, still inside the corridor
            cb.rotation_euler = (math.radians(90), 0, 0)
            sc.camera = cb
            down = lit.replace("_xsec.png", "_down.png")
            sc.render.filepath = down
            bpy.ops.render.render(write_still=True)
            db = G.read_png(down)
            dl = db[:, :, :3].max(axis=2)
            frame["down_nonblank"] = bool(float(dl.max()) - float(dl.min()) > 0.05)
            # *** TWO ARMS ADDED AFTER LOOKING AT RUN 1'S DOWN VIEW. ***
            # `nonblank` is true of an OVEREXPOSED frame as readily as a good
            # one, and run 1 came back white on white with every wall gone.
            frame["down_white_frac"] = round(float((dl > 0.97).mean()), 4)
            # and the 10.774 m tree ran out of the TOP of the frame, so the
            # caption read BREACH over a picture of a tree leaving the image -
            # the System 1 lesson exactly: a clipped model is not a blank one.
            for o in shell:
                o.hide_render = True
            sc.render.film_transparent = True
            dprobe = os.path.join(outdir, "_corr_probe_down.png")
            sc.render.filepath = dprobe
            bpy.ops.render.render(write_still=True)
            dp = G.read_png(dprobe)
            dal = dp[:, :, 3] > 0.5
            frame["down_model_px"] = int(dal.sum())
            frame["down_border_frac"] = round(float(
                (dal[0].sum() + dal[-1].sum() + dal[:, 0].sum() + dal[:, -1].sum())
                / float(2 * dal.shape[0] + 2 * dal.shape[1])), 5)
            # *** HOW MUCH OF THE MODEL THIS VIEW ACTUALLY SHOWS - AND THE
            # *** FIRST VERSION OF THIS ARM WAS THE WRONG KIND OF TEST.
            # It counted model-probe pixels whose LIT COLOUR was chromatic, on
            # the theory that the shell is grey and the model is not. A pale
            # grey floor tile is not chromatic either, so the arm read 21%
            # swallowed on a tile standing in clear air. That is the pass-11
            # family exactly: a number that answers a question nobody asked.
            # The test that works asks the VIEWER's question - render WITH and
            # WITHOUT the model through ONE camera and count the pixels that
            # MOVED, letting the renderer do the depth.
            # *** THE "WITHOUT" FRAME MUST BE THE SAME SCENE MINUS THE MODEL.
            # On its first run it was not: the shell was still hidden and the
            # film still transparent from the model-probe pass above, so this
            # rendered an EMPTY frame, every pixel "moved", and the arm read
            # occlusion 0.0 on all twelve - including a roof that is 40%
            # behind solid stone. An arm that cannot move is not a pass.
            for o in shell:
                o.hide_render = False
            sc.render.film_transparent = False
            for o in new:
                o.hide_render = True
            shellp = os.path.join(outdir, "_corr_probe_shell.png")
            sc.render.filepath = shellp
            bpy.ops.render.render(write_still=True)
            sb = G.read_png(shellp)
            for o in new:
                o.hide_render = False
            moved = (np.abs(db[:, :, :3] - sb[:, :, :3]).max(axis=2) > 0.02)
            seen = int((dal & moved).sum())
            frame["down_model_seen_px"] = seen
            frame["down_occluded_frac"] = round(
                1.0 - seen / float(max(frame["down_model_px"], 1)), 4)
            for o in shell:
                o.hide_render = False
            sc.render.film_transparent = False
            G.draw_text(db, cap1 + "   " + verdict, 10, 10, 2,
                        (0.98, 0.45, 0.35) if verdict == "BREACH" else (0.50, 0.92, 0.55))
            G.write_png(down, db)
            frame["png_xsec"] = os.path.relpath(lit, args.repo).replace("\\", "/")
            frame["png_down"] = os.path.relpath(down, args.repo).replace("\\", "/")
            report["frames"].append(frame)

    if not report["frames"]:
        raise RuntimeError("no frame measured - refusing to report a sheet")

    # ---- contact sheet: 3 yaws across, one pick per row --------------------
    if tiles:
        th, tw = tiles[0].shape[0], tiles[0].shape[1]
        cols = len(YAWS)
        rows_n = int(math.ceil(len(tiles) / float(cols)))
        sheet = np.zeros((rows_n * th, cols * tw, 4), dtype=np.float32)
        sheet[:, :, 3] = 1.0
        for i, t in enumerate(tiles):
            r, c = i // cols, i % cols
            sheet[r * th:(r + 1) * th, c * tw:(c + 1) * tw] = t
        sheet = G.box2(sheet)
        sheetp = os.path.join(outdir, "_corridor_lid.png")
        G.write_png(sheetp, sheet)
        report["png_sheet"] = os.path.relpath(sheetp, args.repo).replace("\\", "/")

    # ---- the arms ----------------------------------------------------------
    blind = []
    for f in report["frames"]:
        b = f["breach_px"]
        if f["expect"] == "breach_lid_every_yaw" and b["lid"] == 0:
            blind.append("%s yaw%d: manifest says %.4f m through a %.1f m lid, "
                         "sheet counts ZERO lid pixels" % (f["file"], f["yaw_deg"],
                                                           f["height_m"], LID))
        if f["expect"] == "clear" and (b["wall_any"] or b["lid"]):
            blind.append("%s yaw%d: manifest says clear, sheet counts a breach"
                         % (f["file"], f["yaw_deg"]))
    roof = [f for f in report["frames"] if f["expect"] == "breach_wall_some_yaw"]
    if roof and not any(f["breach_px"]["wall_any"] for f in roof):
        blind.append("%s: manifest flags it over-corridor at %.4f m and NO yaw "
                     "breaches a wall on the sheet" % (roof[0]["file"],
                                                       roof[0]["footprint_m"]))
    report["checks"] = {
        "frames": len(report["frames"]),
        "errors": len(report["errors"]),
        "all_nonblank": all(f["model_px"] > 0 for f in report["frames"]),
        "all_down_nonblank": all(f.get("down_nonblank") for f in report["frames"]),
        "min_model_px": min(f["model_px"] for f in report["frames"]),
        "max_border_frac": round(max(f["border_px_frac"] for f in report["frames"]), 5),
        "captions_all_rendered": all(f.get("captions_rendered") == 3
                                     for f in report["frames"]),
        "max_down_white_frac": round(max(f.get("down_white_frac", 1.0)
                                         for f in report["frames"]), 4),
        "max_down_border_frac": round(max(f.get("down_border_frac", 1.0)
                                          for f in report["frames"]), 5),
        "down_not_blown": all(f.get("down_white_frac", 1.0) < 0.35
                              for f in report["frames"]),
        "down_not_clipped": all(f.get("down_border_frac", 1.0) < 0.004
                                for f in report["frames"]),
        "max_down_occluded_frac": round(max(f.get("down_occluded_frac", 1.0)
                                            for f in report["frames"]), 4),
        # scoped: a model that breaches a WALL is behind stone in this view by
        # construction, so only the frames with nothing behind a wall are held
        # to "the view shows it".
        "down_shows_the_model": all(f.get("down_occluded_frac", 1.0) < 0.20
                                    for f in report["frames"]
                                    if not f["breach_px"]["wall_any"]),
        "down_wall_breach_is_occluded": all(
            f.get("down_occluded_frac", 0.0) > 0.05 for f in report["frames"]
            if f["breach_px"]["wall_any"]),
        "instrument_blind": blind,
    }
    good = (report["checks"]["all_nonblank"] and report["checks"]["all_down_nonblank"]
            and not blind and report["checks"]["captions_all_rendered"]
            and report["checks"]["down_not_blown"]
            and report["checks"]["down_not_clipped"]
            and report["checks"]["down_shows_the_model"]
            and report["checks"]["down_wall_breach_is_occluded"]
            and not report["errors"])
    report["verdict"] = "GREEN" if good else "RED"
    import datetime
    report["generated_ct"] = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    with open(rep_path, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=1, sort_keys=True)
    print("CORRLID " + json.dumps(report["checks"]))
    for f in report["frames"]:
        print("CORRLID %-34s yaw%-3d xacross %7.3f h %7.3f -> %-6s wall %5d lid %5d floor %5d"
              % (f["file"][:34], f["yaw_deg"], f["measured_world"]["x_extent"],
                 f["height_m"], f["verdict"], f["breach_px"]["wall_any"],
                 f["breach_px"]["lid"], f["breach_px"]["below_floor"]))
    print("CORRLID VERDICT " + report["verdict"])
    return 0


if __name__ == "__main__":
    a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    sys.exit(main(a))
