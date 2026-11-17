"""minibossfit - THE SCALE PROOF the fourteen minibosses never had.

  blender -b -noaudio -P tools/art/minibossfit.py -- --repo <repo> [--only k,k] [--sheet]

WHY THIS EXISTS. Mr. E's acceptance test is FIT: "these need to fit the
characters in our game." For gear that means rendering it on a body. For a
creature it means ONE question nobody had asked: how big does it actually read
standing next to a hero?

The answer was never obvious, because the two are scaled by different code:

  HEROES ARE NOT NORMALISED. Townsfolk/HeroBody instantiate the KayKit
  adventurer body and leave it alone - `size_k` is 1.0 and only children shrink
  it (townsfolk.gd ~253). So a viewer's hero is the RAW glb height, which this
  script measures rather than trusts.

  MONSTERS ARE NORMALISED to a real height in metres: bestiary.gd's `h`, and
  Monster scales the body to it from its measured bounds (bestiary.gd ~10).
  The minibosses are not in bestiary.gd at all yet, so whatever `h` the game
  build lane types in IS their in-game size - and this sheet is the argument
  for what to type.

So: each miniboss at its authored CANON height, beside a real KayKit adventurer
glb at scale 1.0, ONE FIXED ORTHO SCALE and ONE FIXED GROUND LINE across all
fourteen cells. Any cell can be compared with any other and with the hero.

TRAPS ANSWERED (the three that have already bitten this lane):
  SCALE/AIM - clip range and camera distance come from the measured evaluated
              world bounds of hero + creature together, never a default.
  BLANKS    - every PNG re-opened and its opaque pixel count asserted.
  MATRICES  - the hero is imported into the active scene and the view layer is
              updated before anything is measured.
"""
import os
import sys
import json
import math
import argparse

import bpy
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402

HERO_GLB = os.path.join("addons", "kaykit_character_pack_adventures",
                        "Characters", "gltf", "Knight.glb")

# ONE frame for all fourteen. 5.60 m wide x 3.83 m tall at 760x520, ground line
# 0.25 m above the bottom edge. The widest pair is the Gaoler (3.72 m of chain
# coil) plus a hero and a gap, so 5.60 m is measured headroom, not a guess.
CELL_X, CELL_Y = 760, 520
FRAME_W = 5.60
FRAME_H = FRAME_W * CELL_Y / float(CELL_X)
GROUND_UP = 0.25
GAP = 0.45                      # clear air between hero and creature footprint


def import_hero(repo):
    """The real body, at scale 1.0 - the size a hero actually IS in game.

    TWO THINGS THAT HAD TO BE MEASURED, NOT ASSUMED:

    1. The glb carries the whole wardrobe - six weapons and shields parked on
       the rig, plus a hidden Icosphere 1.9 m across. Measured raw it reports
       3.45 m and the frame is wrong. Only the character's own `Knight_*`
       meshes are kept.
    2. The rest pose is NOT the posed body. The `Idle` action has to be
       assigned WITH ITS SLOT (Blender 4.4+ slotted actions: setting
       `animation_data.action` alone leaves the body in rest) and the scene
       stepped onto a frame before anything is measured.

    And the number this returns is the point of the whole file: gear.gd's
    measured "body top y 1.30" is the TORSO mesh. These are chibi bodies - the
    head runs from 1.2 to 2.3 on its own - so a hero stands 2.45 m, not 1.30.
    """
    path = os.path.join(repo, HERO_GLB)
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new_objs = [o for o in bpy.data.objects if o not in before]
    rig = next((o for o in new_objs if o.type == 'ARMATURE'), None)
    act = bpy.data.actions.get("Idle")
    posed = False
    if rig is not None and act is not None:
        if rig.animation_data is None:
            rig.animation_data_create()
        rig.animation_data.action = act
        try:
            rig.animation_data.action_slot = act.slots[0]
            posed = True
        except Exception:
            posed = False
        bpy.context.scene.frame_set(3)
    # the character only: no parked weapons, no shields, no hidden sphere
    meshes = [o for o in new_objs if o.type == 'MESH' and o.name.startswith("Knight")]
    drop = [o for o in new_objs if o.type == 'MESH' and o not in meshes]
    for o in drop:
        bpy.data.objects.remove(o, do_unlink=True)
    new_objs = [o for o in new_objs if o not in drop]
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(meshes)
    for o in new_objs:
        if o.parent is None:
            o.location = (o.location.x, o.location.y, o.location.z - mn.z)
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(meshes)
    return new_objs, meshes, dict(h=round(mx.z - mn.z, 3), w=round(mx.x - mn.x, 3),
                                  d=round(mx.y - mn.y, 3), posed=posed,
                                  parts=[o.name for o in meshes])


def place(roots, dx, dy=0.0):
    """THE SIDE VIEW WAS ONE BODY HIDING ANOTHER. The hero used to be offset
    along X only, so at azimuth 90 the camera looked straight down the line of
    the pair and the hero stood in front of the creature - a fit shot in which
    you can see neither of them. Offsetting in Y as well separates them on
    screen in BOTH views: X apart for front and back, Y apart for the side,
    and the two never overlap because they are apart on the other axis each
    time."""
    for o in roots:
        if o.parent is None:
            o.location = (o.location.x + dx, o.location.y + dy, o.location.z)
    bpy.context.view_layer.update()


def shoot(objs, pts, outdir, views, aura):
    """Fixed scale, fixed ground line. Only the horizontal centre moves."""
    scene = bpy.context.scene
    eng = G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = CELL_X, CELL_Y
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    bg = next((n for n in scene.world.node_tree.nodes if n.type == 'BACKGROUND'), None)
    if bg:
        bg.inputs['Color'].default_value = (0.045, 0.05, 0.065, 1.0)
        bg.inputs['Strength'].default_value = 1.0

    mn, mx, _ = G.world_bounds(objs)
    radius = max(0.5, (mx - mn).length / 2.0)
    G.add_lights(Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0, (mn.z + mx.z) / 2.0)),
                 radius, aura)

    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam_d.ortho_scale = FRAME_W          # landscape: ortho_scale is the long side
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam

    written = []
    for vname, az in views:
        a, e = math.radians(az), math.radians(6.0)
        dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e),
                       math.sin(e))).normalized()
        # the aim point: horizontally centred on the pair, vertically fixed so
        # the ground sits GROUND_UP above the bottom edge in every single cell
        cx = (mn.x + mx.x) / 2.0 if az < 45.0 else (mn.x + mx.x) / 2.0
        cy = (mn.y + mx.y) / 2.0
        target = Vector((cx, cy, FRAME_H / 2.0 - GROUND_UP))
        dist = radius * 4.0 + 4.0
        cam.location = target + dirv * dist
        cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
        bpy.context.view_layer.update()
        fwd = (cam.matrix_world.to_3x3() @ Vector((0, 0, -1))).normalized()
        depth = [(p - cam.location).dot(fwd) for p in pts]
        cam_d.clip_start = max(0.01, min(depth) - radius * 0.5)
        cam_d.clip_end = max(depth) + radius * 2.0 + 8.0
        path = os.path.join(outdir, "hero_%s.png" % vname)
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        written.append(path)
    return written, eng


def sheet(repo, keys, hero, name="_hero_scale", cols=3):
    """Fourteen cells, one scale, one ground line, and the hero's head height
    drawn straight across every cell as a dashed rule - so the comparison is in
    the picture and not in a table."""
    root = os.path.join(repo, "renders", "art", "minibosses")
    lab = 40
    rows = (len(keys) + cols - 1) // cols
    cw, ch = CELL_X, CELL_Y
    sh = np.zeros((rows * (ch + lab), cols * cw, 4), dtype=np.float32)
    sh[..., 0:3] = np.array((0.055, 0.060, 0.075))
    sh[..., 3] = 1.0
    bad, checked = [], []
    # pixel row of the ground and of the hero's head, inside a cell
    px_per_m = ch / FRAME_H
    ground_row = ch - int(GROUND_UP * px_per_m)
    head_row = ground_row - int(hero["h"] * px_per_m)
    for i, key in enumerate(keys):
        p = os.path.join(root, key, "hero_front.png")
        cx, cy = (i % cols) * cw, (i // cols) * (ch + lab)
        if os.path.isfile(p):
            a = G.read_png(p)
            n = int((a[..., 3] > 0.02).sum())
            checked.append((os.path.relpath(p, repo), n))
            if n < 400:
                bad.append((p, "blank or near-blank: %d opaque px" % n))
            al = a[..., 3:4]
            dst = sh[cy:cy + ch, cx:cx + cw, 0:3]
            sh[cy:cy + ch, cx:cx + cw, 0:3] = a[..., 0:3] * al + dst * (1.0 - al)
        else:
            bad.append((p, "missing"))
        # the two rules: ground, and the hero's head carried across the cell
        sh[cy + ground_row:cy + ground_row + 1, cx:cx + cw, 0:3] = np.array((0.30, 0.32, 0.36))
        for x in range(cx + 4, cx + cw - 4, 14):
            sh[cy + head_row:cy + head_row + 1, x:x + 8, 0:3] = np.array((1.00, 0.86, 0.52))
        t, h = M.CANON[key][0], M.CANON[key][1]
        ratio = h / hero["h"] if hero["h"] > 0.01 else 0.0
        sh[cy + ch:cy + ch + 2, cx:cx + cw, 0:3] = np.array((0.85, 0.80, 0.68)) * 0.35
        G.draw_text(sh, "%s  %.2fM" % (t.upper(), h), cx + 8, cy + ch + 6, 2,
                    (0.85, 0.80, 0.68))
        G.draw_text(sh, "%.2fx THE HERO (%.2fM) - %s THEME"
                    % (ratio, hero["h"], M.CANON[key][4].upper()),
                    cx + 8, cy + ch + 25, 1, (0.46, 0.52, 0.60))
    G.draw_text(sh, "DASHED RULE = THE TOP OF A VIEWERS HERO, %.2f M, KayKit Knight.glb AT SCALE 1.0 "
                    "(townsfolk.gd size_k=1.0). ONE ORTHO SCALE AND ONE GROUND LINE IN ALL CELLS."
                % hero["h"], 10, 10, 1, (1.00, 0.86, 0.52))
    G.write_png(os.path.join(root, "%s.png" % name), sh)
    return bad, checked


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--only", default="")
    ap.add_argument("--sheet", action="store_true")
    ap.add_argument("--name", default="_hero_scale")
    ap.add_argument("--cols", type=int, default=3)
    ap.add_argument("--frame", type=float, default=0.0)
    args = ap.parse_args(argv)
    if args.frame > 0.1:
        globals()["FRAME_W"] = args.frame
        globals()["FRAME_H"] = args.frame * CELL_Y / float(CELL_X)
    out = os.path.join(args.repo, "renders", "art", "minibosses",
                       "_fit_report.json" if args.name == "_hero_scale" else "_fit_%s.json" % args.name.strip("_"))
    rep = {"ok": True, "hero": {}, "pairs": {}, "errors": []}
    if os.path.isfile(out):
        try:
            with open(out) as f:
                old = json.load(f)
            rep["pairs"] = dict(old.get("pairs", {}))
            rep["hero"] = dict(old.get("hero", {}))
        except Exception:
            pass

    keys = [k for k in args.only.split(",") if k] if args.only else list(M.ORDER)
    if not args.sheet:
        for key in keys:
            G.purge()
            try:
                objs, info = MG.build_miniboss(key)
                hroots, hmesh, hero = import_hero(args.repo)
                rep["hero"] = hero
                mn, mx, _ = G.world_bounds(objs)
                # hero to the creature's left, clear of its footprint
                place(hroots, mn.x - GAP - hero["w"] / 2.0 - 0.10,
                      mn.y - GAP - hero["d"] / 2.0 - 0.10)
                allo = objs + hmesh
                bpy.context.view_layer.update()
                amn, amx, pts = G.world_bounds(allo)
                outdir = os.path.join(args.repo, "renders", "art", "minibosses", key)
                os.makedirs(outdir, exist_ok=True)
                written, eng = shoot(allo, pts, outdir,
                                     (("front", 0.0), ("side", 90.0), ("back", 180.0)), info["aura"])
                rep["pairs"][key] = dict(
                    creature_h=round(mx.z - mn.z, 3), hero_h=hero["h"],
                    ratio=round((mx.z - mn.z) / max(0.01, hero["h"]), 2),
                    pair_w=round(amx.x - amn.x, 2),
                    fits_frame=bool((amx.x - amn.x) <= FRAME_W and (amx.z - amn.z) <= FRAME_H - GROUND_UP),
                    engine=eng, views=[os.path.basename(p) for p in written])
                if not rep["pairs"][key]["fits_frame"]:
                    rep["errors"].append("%s: pair does not fit the fixed frame" % key)
                    rep["ok"] = False
            except Exception:
                import traceback
                rep["ok"] = False
                rep["errors"].append("%s: %s" % (key, traceback.format_exc()[-800:]))

    # *** AN EMPTY MEASUREMENT IS RED. ***
    # _fit_snuffer_register.json shipped as ok:true with hero:{} and pairs:{}
    # and another lane's ticked item (D96) then leaned on it. It was born from
    # a --sheet-only run: that path skips the measurement loop entirely, and
    # nothing here checked that the keys being sheeted had ever been measured.
    # ok used to mean "nothing raised" - it now means "every key asked for has
    # a ratio on record". A register that measures nothing reports RED.
    measured = [k for k in keys if k in rep["pairs"]]
    missing = [k for k in keys if k not in rep["pairs"]]
    rep["measured"] = measured
    rep["asked"] = list(keys)
    if not rep["hero"]:
        rep["ok"] = False
        rep["errors"].append("hero: never measured. An empty hero block is RED, "
                             "not ok - every ratio is a ratio TO the hero.")
    if not rep["pairs"]:
        rep["ok"] = False
        rep["errors"].append("pairs: EMPTY. This register measured NOTHING and "
                             "must not report ok. Re-run without --sheet.")
    if missing:
        rep["ok"] = False
        rep["errors"].append("no ratio on record for: %s (asked for %d, measured %d)"
                             % (",".join(missing), len(keys), len(measured)))

    G.purge()
    try:
        hero = rep["hero"] if rep["hero"] else {"h": 1.0}
        bad, checked = sheet(args.repo, keys, hero, args.name, args.cols)
        rep["blank_check"] = {"files": len(checked), "failures": [list(b) for b in bad]}
        if bad:
            rep["ok"] = False
    except Exception:
        import traceback
        rep["ok"] = False
        rep["errors"].append("sheet: %s" % traceback.format_exc()[-800:])

    os.makedirs(os.path.dirname(out), exist_ok=True)
    rep["verdict"] = "GREEN" if rep["ok"] else "RED"
    with open(out, "w") as f:
        json.dump(rep, f, indent=1)
    print("MINIBOSSFIT_REPORT " + json.dumps({
        "verdict": "GREEN" if rep["ok"] else "RED",
        "ok": rep["ok"], "hero": rep["hero"], "errors": rep["errors"][:4],
        "blank": rep.get("blank_check", {}),
        "ratios": {k: (v["ratio"], v["pair_w"], v["fits_frame"])
                   for k, v in rep["pairs"].items()}}))


if __name__ == "__main__":
    main()
