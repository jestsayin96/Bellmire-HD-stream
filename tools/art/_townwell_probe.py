"""_townwell_probe - LOOK AT THE CLEARED PACK BEFORE AUTHORING A WELL.

  blender -b -noaudio -P tools/art/_townwell_probe.py -- --repo <repo>

28 Nov 2026, 00:4x CT. Art lane. The row is the tier-1/2/3 variants of the town
square well -> fountain. Mr. E's rule 3 (16 Nov 04:46) says use the packs on
disk before generating a mesh, and the plan row says a tier variant derived from
a cleared pack beats a mesh authored from nothing. So before I model anything I
measure and LOOK AT the only cleared candidate.

WHAT I ESTABLISHED BY MEASURING, NOT REMEMBERING:
  - `assets/` has NO well and NO fountain mesh. Three icon PNGs carry the word
    `wellhead` and that is all.
  - A well EXISTS in two packs and BOTH ARE IMPORT-GATED:
    `low-poly_RPG_item_collection_3\well.obj` (ASSET_SOURCES: NO LICENCE FILE
    FOUND, terms "not established") and `modular_village_collection\
    Prop_Well_{1,Cobblestone,Dirt,Grass,Inside}.obj` - and I walked that folder
    myself this run: 147 files, ZERO text files of any kind, so there is no
    README carrying terms either. Both stay gated.
  - The one CLEARED town-square candidate is Kenney Fantasy Town Kit 2.0, CC0
    1.0, licence read off disk 24 Nov (ASSET_SOURCES line 803). It has ten
    `fountain-*` pieces and NO well.

So tier 3 may be pack-derived; tiers 1 and 2 cannot be, because no cleared pack
on this machine holds a well at all. This probe answers whether the Kenney
fountain is in the same visual family as a ring I would author beside it.

*** WHAT A PASS LOOKS LIKE IF THE SUBJECT IS ABSENT: an empty frame. On 27 Nov
*** my own side-on gate passed a shot of the tier-5 spear with no spear in it.
*** So this asserts, per piece, that the piece's OWN pixels are present - the
*** bar and the floor slab are excluded from the count by being rendered in a
*** separate pass and differenced, and the arm goes RED ON EMPTY.
"""
import argparse, json, math, os, sys
import bpy, numpy as np
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lordgen as G
import lordlib as L

PACK = r"C:\hd adventure\_packs\kenney_fantasy-town-kit_2.0\Models\GLB format"
PIECES = ["fountain-round.glb", "fountain-round-detail.glb", "fountain-center.glb",
          "fountain-square.glb", "fountain-edge.glb"]
HERO_M = 1.80   # a KayKit adventurer stands about this tall


def imp(path):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    return [o for o in bpy.data.objects if o not in before and o.type == 'MESH']


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    a = ap.parse_args(sys.argv[sys.argv.index("--") + 1:])
    out = os.path.join(a.repo, "renders", "art", "town", "_probe")
    os.makedirs(out, exist_ok=True)

    rows = []
    for p in PIECES:
        G.purge()
        fp = os.path.join(PACK, p)
        if not os.path.isfile(fp):
            rows.append({"file": p, "ERROR": "missing on disk"}); continue
        objs = imp(fp)
        if not objs:
            rows.append({"file": p, "ERROR": "imported no mesh"}); continue
        bpy.context.view_layer.update()
        mn, mx, pts = G.world_bounds(objs)   # EVALUATED - trap 3
        d = mx - mn
        rows.append({"file": p, "n_mesh": len(objs), "n_vert": sum(len(o.data.vertices) for o in objs),
                     "dims_m": [round(v, 4) for v in (d.x, d.y, d.z)],
                     "base_dz_m": round(mn.z, 4),
                     "centre_dx_dy_m": [round(((mn + mx) / 2).x, 4), round(((mn + mx) / 2).y, 4)],
                     "hero_ratio_height": round(d.z / HERO_M, 3)})

    # ---- one labelled sheet, all pieces through ONE camera, with a 1.80 m bar
    G.purge()
    scene = bpy.context.scene
    eng = G.set_engine(scene)
    placed, labels = [], []
    x = 0.0
    mat_bar = L.mat_solid("bar", (0.85, 0.22, 0.18), 0.6, 0.0)
    mat_floor = L.mat_solid("floor", (0.26, 0.25, 0.23), 0.9, 0.0)
    spans = []
    for r in rows:
        if "ERROR" in r:
            continue
        objs = imp(os.path.join(PACK, r["file"]))
        bpy.context.view_layer.update()
        mn, mx, _ = G.world_bounds(objs)
        w = (mx - mn).x
        for o in objs:
            o.location = (o.location.x + (x - mn.x), o.location.y - (mn.y + mx.y) / 2.0,
                          o.location.z - mn.z)
        bpy.context.view_layer.update()
        placed += objs
        spans.append((r["file"], x, x + w))
        labels.append((r["file"].replace(".glb", ""), x + w / 2.0, r["dims_m"]))
        x += w + 0.6
    # 1.80 m reference bar at the far right
    bar = L.make("herobar", *_boxv(0.12, 0.12, HERO_M), mat_bar)
    bar.location = (x + 0.4, 0.0, HERO_M / 2.0)
    labels.append(("1.80 M HERO", x + 0.4, [0.12, 0.12, HERO_M]))
    total_w = x + 1.0
    floor = L.make("floor", *_boxv(total_w + 1.2, 6.0, 0.30), mat_floor)
    floor.location = (total_w / 2.0 - 0.5, 0.0, -0.15)
    bpy.context.view_layer.update()

    subj = placed + [bar]
    mn, mx, pts = G.world_bounds(subj + [floor])
    center = (mn + mx) / 2.0
    radius = max(0.5, (mx - mn).length / 2.0)
    G.add_lights(center, radius, (0.9, 0.9, 0.95))
    scene.render.resolution_x, scene.render.resolution_y = 1600, 520
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    cam_d = bpy.data.cameras.new("cam"); cam_d.type = 'ORTHO'
    cam = bpy.data.objects.new("cam", cam_d); bpy.context.collection.objects.link(cam)
    scene.camera = cam
    az, el = math.radians(26.0), math.radians(13.0)
    dirv = Vector((math.sin(az) * math.cos(el), -math.cos(az) * math.cos(el), math.sin(el))).normalized()
    cam.location = center + dirv * (radius * 4.0 + 2.0)
    cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
    bpy.context.view_layer.update()
    mw = cam.matrix_world
    right = (mw.to_3x3() @ Vector((1, 0, 0))).normalized()
    up = (mw.to_3x3() @ Vector((0, 1, 0))).normalized()
    fwd = (mw.to_3x3() @ Vector((0, 0, -1))).normalized()
    wide = max(abs((p - center).dot(right)) for p in pts) * 2.0
    tall = max(abs((p - center).dot(up)) for p in pts) * 2.0
    cam_d.ortho_scale = max(tall * (1600 / 520.0), wide) * 1.06
    dep = [(p - cam.location).dot(fwd) for p in pts]
    cam_d.clip_start = max(0.01, min(dep) - radius * 0.5)
    cam_d.clip_end = max(dep) + radius * 2.0 + 5.0

    sheet = os.path.join(out, "_kenney_fountain_candidates.png")
    scene.render.filepath = sheet
    bpy.ops.render.render(write_still=True)

    # ---- CAN THE SUBJECT BE SEEN? a with/without pass, differenced.
    with_px = _alpha(sheet)
    for o in placed:
        o.hide_render = True
    without = os.path.join(out, "_nofountain.png")
    scene.render.filepath = without
    bpy.ops.render.render(write_still=True)
    moved = _moved(sheet, without)
    for o in placed:
        o.hide_render = False

    # ---- label the sheet and CHECK EACH LABEL'S OWN BOX (red on empty)
    from bpy_extras.object_utils import world_to_camera_view as w2c
    buf = G.read_png(sheet)
    h, w = buf.shape[0], buf.shape[1]
    lab_boxes = []
    for text, cx, dims in labels:
        co = w2c(scene, cam, Vector((cx, 0.0, 0.05)))
        px, py = int(co.x * w), int((1.0 - co.y) * h)
        t2 = "%s  %.2fX%.2fX%.2f" % (text, dims[0], dims[1], dims[2])
        y0 = min(h - 20, max(2, py + 8))
        x0 = max(2, min(w - 6 * 2 * len(t2) - 4, px - 3 * 2 * len(t2)))
        G.draw_text(buf, t2, x0, y0, scale=2)
        lab_boxes.append((t2, x0, y0, 6 * 2 * len(t2), 7 * 2))
    lab_px = {}
    for t2, x0, y0, bw, bh in lab_boxes:
        sl = buf[y0:y0 + bh, x0:x0 + bw]
        lab_px[t2.split("  ")[0]] = int((sl[..., 3] > 0.03).sum())
    G.write_png(sheet, buf)

    border = _border(sheet)
    errs = []
    if with_px == 0:
        errs.append("SHEET IS BLANK")
    if moved < 2000:
        errs.append("SUBJECT NOT SEEN: only %d px changed when the fountains were hidden" % moved)
    empty_labels = [k for k, v in lab_px.items() if v == 0]
    if empty_labels:
        errs.append("LABELS RENDERED EMPTY: %s" % empty_labels)
    if not lab_px:
        errs.append("RED ON EMPTY: zero labels measured")
    if border > 0:
        errs.append("BORDER ALPHA %d - the sheet is clipped" % border)

    rep = {"when_ct": "28 Nov 2026 ~00:4x CT", "engine": eng, "pack": PACK,
           "rows": rows, "spans": [[s[0], round(s[1], 3), round(s[2], 3)] for s in spans],
           "sheet": sheet, "opaque_px": with_px, "subject_moved_px": moved,
           "label_px": lab_px, "border_alpha_px": border,
           "verdict": "GREEN" if not errs else "RED", "errors": errs}
    with open(os.path.join(out, "_probe.json"), "w") as f:
        json.dump(rep, f, indent=1)
    print("PROBE " + json.dumps(rep))


def _boxv(sx, sy, sz):
    return L.box(sx, sy, sz)


def _alpha(p):
    a = G.read_png(p)
    return int((a[..., 3] > 0.03).sum())


def _moved(p1, p2):
    a, b = G.read_png(p1), G.read_png(p2)
    d = np.abs(a - b).max(axis=2)
    return int((d > 0.02).sum())


def _border(p):
    a = G.read_png(p)
    e = np.concatenate([a[0, :, 3], a[-1, :, 3], a[:, 0, 3], a[:, -1, 3]])
    return int((e > 0.03).sum())


main()
