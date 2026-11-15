"""lordgen - headless Blender driver for D75, THE EIGHT LORDS.

  blender -b -noaudio -P tools/art/lordgen.py -- --repo <repo> [--only key] [--res 720x1000]
  blender -b -noaudio -P tools/art/lordgen.py -- --repo <repo> --sheet

Builds each lord, exports a .glb, renders three views on transparent film, then
verifies every PNG has opaque pixels and lays out two contact sheets.

Two traps this script exists to avoid (both cost real time on 15 Nov):
  SCALE   - the camera's clip range and distance are derived from the EVALUATED
            world-space bounds of the actual geometry, never assumed. A default
            clip_end of 100 renders a 700-unit model as an empty transparent
            image and reports success.
  BLANKS  - every written PNG is re-opened and its opaque pixel count asserted
            above zero. A silent blank is worse than an error.

No PIL here on purpose: Blender ships numpy, not PIL. Compositing reads images
as Non-Color so the sRGB bytes round-trip unchanged.
"""
import os
import sys
import math
import json
import argparse

import bpy
import numpy as np
from mathutils import Vector

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordlib as L          # noqa: E402
import lords as LD           # noqa: E402

VIEWS = (("front", 0.0, 12.0), ("three_quarter", 38.0, 14.0), ("side", 90.0, 11.0))


# ------------------------------------------------------------------- 5x7 font
_F = {
 'A': ".###.|#...#|#...#|#####|#...#|#...#|#...#", 'B': "####.|#...#|#...#|####.|#...#|#...#|####.",
 'C': ".###.|#...#|#....|#....|#....|#...#|.###.", 'D': "####.|#...#|#...#|#...#|#...#|#...#|####.",
 'E': "#####|#....|#....|####.|#....|#....|#####", 'F': "#####|#....|#....|####.|#....|#....|#....",
 'G': ".###.|#...#|#....|#..##|#...#|#...#|.###.", 'H': "#...#|#...#|#...#|#####|#...#|#...#|#...#",
 'I': "#####|..#..|..#..|..#..|..#..|..#..|#####", 'J': "#####|....#|....#|....#|....#|#...#|.###.",
 'K': "#...#|#..#.|#.#..|##...|#.#..|#..#.|#...#", 'L': "#....|#....|#....|#....|#....|#....|#####",
 'M': "#...#|##.##|#.#.#|#...#|#...#|#...#|#...#", 'N': "#...#|##..#|#.#.#|#..##|#...#|#...#|#...#",
 'O': ".###.|#...#|#...#|#...#|#...#|#...#|.###.", 'P': "####.|#...#|#...#|####.|#....|#....|#....",
 'Q': ".###.|#...#|#...#|#...#|#.#.#|#..#.|.##.#", 'R': "####.|#...#|#...#|####.|#.#..|#..#.|#...#",
 'S': ".####|#....|#....|.###.|....#|....#|####.", 'T': "#####|..#..|..#..|..#..|..#..|..#..|..#..",
 'U': "#...#|#...#|#...#|#...#|#...#|#...#|.###.", 'V': "#...#|#...#|#...#|#...#|#...#|.#.#.|..#..",
 'W': "#...#|#...#|#...#|#...#|#.#.#|##.##|#...#", 'X': "#...#|#...#|.#.#.|..#..|.#.#.|#...#|#...#",
 'Y': "#...#|#...#|.#.#.|..#..|..#..|..#..|..#..", 'Z': "#####|....#|...#.|..#..|.#...|#....|#####",
 '0': ".###.|#...#|#..##|#.#.#|##..#|#...#|.###.", '1': "..#..|.##..|..#..|..#..|..#..|..#..|.###.",
 '2': ".###.|#...#|....#|...#.|..#..|.#...|#####", '3': "####.|....#|....#|.###.|....#|....#|####.",
 '4': "#...#|#...#|#...#|#####|....#|....#|....#", '5': "#####|#....|#....|####.|....#|....#|####.",
 '6': ".###.|#....|#....|####.|#...#|#...#|.###.", '7': "#####|....#|...#.|..#..|.#...|.#...|.#...",
 '8': ".###.|#...#|#...#|.###.|#...#|#...#|.###.", '9': ".###.|#...#|#...#|.####|....#|....#|.###.",
 ' ': ".....|.....|.....|.....|.....|.....|.....", '-': ".....|.....|.....|#####|.....|.....|.....",
 '.': ".....|.....|.....|.....|.....|.....|..#..", ',': ".....|.....|.....|.....|.....|..#..|.#...",
 "'": "..#..|..#..|.....|.....|.....|.....|.....",
}


def draw_text(buf, text, x, y, scale=2, rgb=(0.92, 0.90, 0.86)):
    """Stamp uppercase text into an (h, w, 4) float buffer. y is the top row."""
    h, w = buf.shape[0], buf.shape[1]
    cx = x
    for ch in text.upper():
        g = _F.get(ch)
        if g is None:
            g = _F[' ']
        rows = g.split('|')
        for ry, row in enumerate(rows):
            for rx, c in enumerate(row):
                if c != '#':
                    continue
                for dy in range(scale):
                    for dx in range(scale):
                        py, px = y + ry * scale + dy, cx + rx * scale + dx
                        if 0 <= py < h and 0 <= px < w:
                            buf[py, px, 0:3] = rgb
                            buf[py, px, 3] = 1.0
        cx += 6 * scale
    return cx


# ----------------------------------------------------------------- scene admin
def purge():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                 bpy.data.cameras, bpy.data.images):
        for d in list(coll):
            try:
                coll.remove(d, do_unlink=True)
            except Exception:
                pass


def set_engine(scene):
    for name in ('BLENDER_EEVEE', 'BLENDER_EEVEE_NEXT', 'CYCLES'):
        try:
            scene.render.engine = name
            return name
        except Exception:
            continue
    return scene.render.engine


def world_bounds(objs):
    """Evaluated world-space bounds. Everything about framing hangs off this."""
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
        raise RuntimeError("no geometry: refusing to render an empty frame")
    mn = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    mx = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return mn, mx, pts


def build_lord(key):
    title, height, tint, aura, note = LD.CANON[key]
    # the tint has to survive the view transform, so the recesses go deep and
    # the bone is tinted rather than bleached - a grey lord reads as nobody
    # The tint has to survive the view transform, so recesses go deep and bone is
    # tinted rather than bleached - a grey lord reads as nobody. A fifth of the
    # aura is mixed into the body so the two wyrms do not read as the same beast.
    body = tuple((c * 0.80) * 0.80 + a * 0.20 for c, a in zip(tint, aura))
    # emission above ~4 clips to white and throws the aura colour away
    mats = {
        'body': L.mat_solid(key + "_body", body, 0.52, 0.06),
        'dark': L.mat_solid(key + "_dark", tuple(c * 0.16 + 0.012 for c in body), 0.70, 0.04),
        'bone': L.mat_solid(key + "_bone", tuple(0.30 + c * 0.55 for c in tint), 0.44, 0.02),
        'glow': L.mat_glow(key + "_glow", tuple(min(1.0, c / max(aura)) for c in aura), 3.2),
    }
    P = LD.BUILDERS[key]()
    # Merge by material before making objects. Built part-by-part a lord is up to
    # 107 separate objects, which is 107 draw calls for one boss; D23 is already
    # fighting for frame rate. Merged, every lord is at most four meshes.
    groups = {}
    for verts, faces, slot in P.items:
        gv, gf = groups.setdefault(slot, ([], []))
        off = len(gv)
        gv.extend(verts)
        gf.extend([tuple(i + off for i in f) for f in faces])
    objs = []
    for slot in ('body', 'dark', 'bone', 'glow'):
        if slot not in groups:
            continue
        gv, gf = groups[slot]
        objs.append(L.make("%s_%s" % (key, slot), gv, gf, mats.get(slot, mats['body'])))
    # author at the canon height; bestiary.gd applies LORD_SCALE on top
    mn, mx, _ = world_bounds(objs)
    cur = mx.z - mn.z
    k = height / cur if cur > 1e-6 else 1.0
    for ob in objs:
        ob.scale = (k, k, k)
        ob.location = (ob.location.x * k, ob.location.y * k, ob.location.z * k)
    bpy.context.view_layer.update()
    mn, mx, _ = world_bounds(objs)
    for ob in objs:
        ob.location = (ob.location.x, ob.location.y, ob.location.z - mn.z)
    bpy.context.view_layer.update()
    return objs, dict(title=title, height=height, tint=tint, aura=aura, note=note)


def add_lights(center, radius, aura):
    specs = (("key", (0.9, -1.0, 0.85), 'SUN', 2.3, (1.0, 0.97, 0.92)),
             ("fill", (-1.0, -0.6, 0.35), 'AREA', 1.0, (0.72, 0.80, 1.0)),
             ("rim", (0.1, 1.0, 0.55), 'AREA', 1.0, aura))
    for name, d, kind, e, col in specs:
        li = bpy.data.lights.new(name, type=kind)
        li.color = col
        if kind == 'SUN':
            li.energy = e
        else:
            li.energy = 1400.0 * (radius / 3.0) ** 2 * (0.85 if name == 'rim' else 0.75)
            li.size = radius * 2.2
        ob = bpy.data.objects.new(name, li)
        bpy.context.collection.objects.link(ob)
        dirv = Vector(d).normalized()
        ob.location = center + dirv * (radius * 4.0)
        ob.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()


def render_views(objs, key, outdir, resx, resy, info):
    scene = bpy.context.scene
    eng = set_engine(scene)
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
        bg.inputs['Color'].default_value = (0.045, 0.05, 0.065, 1.0)
        bg.inputs['Strength'].default_value = 1.0

    mn, mx, pts = world_bounds(objs)
    center = (mn + mx) / 2.0
    radius = max(0.35, (mx - mn).length / 2.0)
    add_lights(center, radius, info['aura'])

    cam_d = bpy.data.cameras.new("cam")
    cam_d.type = 'ORTHO'
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam

    written = []
    for vname, az, el in VIEWS:
        a, e = math.radians(az), math.radians(el)
        dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e), math.sin(e))).normalized()
        dist = radius * 4.0 + 2.0
        cam.location = center + dirv * dist
        cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
        bpy.context.view_layer.update()
        mw = cam.matrix_world
        right = (mw.to_3x3() @ Vector((1, 0, 0))).normalized()
        up = (mw.to_3x3() @ Vector((0, 1, 0))).normalized()
        fwd = (mw.to_3x3() @ Vector((0, 0, -1))).normalized()
        ru = [abs((p - center).dot(right)) for p in pts]
        uu = [abs((p - center).dot(up)) for p in pts]
        depth = [(p - cam.location).dot(fwd) for p in pts]
        wide, tall = max(ru) * 2.0, max(uu) * 2.0
        need = max(tall, wide * (resy / float(resx)))
        cam_d.ortho_scale = need * 1.10
        # SCALE TRAP: clip range comes from the measured depth span, not defaults
        cam_d.clip_start = max(0.01, min(depth) - radius * 0.5)
        cam_d.clip_end = max(depth) + radius * 2.0 + 5.0
        path = os.path.join(outdir, "%s.png" % vname)
        scene.render.filepath = path
        bpy.ops.render.render(write_still=True)
        written.append(path)
    return written, eng, dict(radius=radius, ortho=cam_d.ortho_scale,
                              clip=(cam_d.clip_start, cam_d.clip_end))


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
    kw = dict(filepath=path, export_format='GLB', use_selection=True)
    try:
        bpy.ops.export_scene.gltf(**kw)
        return True, ""
    except Exception as e1:
        try:
            bpy.ops.export_scene.gltf(filepath=path, export_format='GLB')
            return True, "no-selection-filter: %s" % e1
        except Exception as e2:
            return False, "%s / %s" % (e1, e2)


# ------------------------------------------------------------------ pixel work
def read_png(path):
    img = bpy.data.images.load(path, check_existing=False)
    try:
        img.colorspace_settings.name = 'Non-Color'
    except Exception:
        pass
    w, h = img.size
    buf = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(buf)
    bpy.data.images.remove(img)
    return buf.reshape(h, w, 4)[::-1]     # top-down


def write_png(path, arr):
    h, w = arr.shape[0], arr.shape[1]
    img = bpy.data.images.new(os.path.basename(path), width=w, height=h, alpha=True, float_buffer=False)
    try:
        img.colorspace_settings.name = 'Non-Color'
    except Exception:
        pass
    flat = np.ascontiguousarray(arr[::-1].astype(np.float32).ravel())
    img.pixels.foreach_set(flat)
    img.filepath_raw = path
    img.file_format = 'PNG'
    img.save()
    bpy.data.images.remove(img)


def box2(a):
    h, w = a.shape[0] // 2 * 2, a.shape[1] // 2 * 2
    return a[:h, :w].reshape(h // 2, 2, w // 2, 2, a.shape[2]).mean(axis=(1, 3))


def sheets(repo, resx, resy):
    root = os.path.join(repo, "renders", "art", "lords")
    bad, checked = [], []
    for key in LD.ORDER:
        for vname, _, _ in VIEWS:
            p = os.path.join(root, key, "%s.png" % vname)
            if not os.path.isfile(p):
                bad.append((p, "missing"))
                continue
            a = read_png(p)
            n = int((a[..., 3] > 0.02).sum())
            checked.append((os.path.relpath(p, repo), n, a.shape[1], a.shape[0]))
            if n < 500:
                bad.append((p, "blank or near-blank: %d opaque px" % n))
    cells = []
    for key in LD.ORDER:
        p = os.path.join(root, key, "three_quarter.png")
        cells.append((key, box2(read_png(p)) if os.path.isfile(p) else None))

    ch, cw = resy // 2, resx // 2
    lab = 34
    cols, rows = 4, 2
    sheet = np.zeros((rows * (ch + lab), cols * cw, 4), dtype=np.float32)
    sheet[..., 0:3] = np.array((0.055, 0.060, 0.075))
    sheet[..., 3] = 1.0
    sil = np.zeros_like(sheet)
    sil[..., 0:3] = np.array((0.93, 0.93, 0.90))
    sil[..., 3] = 1.0
    for i, (key, a) in enumerate(cells):
        cx, cy = (i % cols) * cw, (i // cols) * (ch + lab)
        title, height, tint, aura, note = LD.CANON[key]
        if a is not None:
            al = a[..., 3:4]
            dst = sheet[cy:cy + ch, cx:cx + cw, 0:3]
            sheet[cy:cy + ch, cx:cx + cw, 0:3] = a[..., 0:3] * al + dst * (1.0 - al)
            m = (al[..., 0] > 0.45)
            cell = sil[cy:cy + ch, cx:cx + cw, 0:3]
            cell[m] = np.array((0.06, 0.06, 0.08))
        tag = "%s  %.1fM" % (title, height)
        sc = 2 if 6 * 2 * len(tag) <= cw - 16 else 1
        for s, colr in ((sheet, (0.85, 0.80, 0.68)), (sil, (0.15, 0.15, 0.20))):
            s[cy + ch:cy + ch + 2, cx:cx + cw, 0:3] = np.array(colr) * 0.35
            draw_text(s, tag, cx + 8, cy + ch + 10, sc, colr)
    write_png(os.path.join(root, "_contact_sheet.png"), sheet)
    write_png(os.path.join(root, "_silhouettes.png"), sil)
    return bad, checked


# ------------------------------------------------------------------------ main
def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--only", default="")
    ap.add_argument("--res", default="720x1000")
    ap.add_argument("--sheet", action="store_true")
    args = ap.parse_args(argv)
    resx, resy = (int(x) for x in args.res.split("x"))
    report = {"ok": True, "lords": {}, "errors": []}

    if not args.sheet:
        keys = [args.only] if args.only else list(LD.ORDER)
        for key in keys:
            purge()
            try:
                objs, info = build_lord(key)
                outdir = os.path.join(args.repo, "renders", "art", "lords", key)
                os.makedirs(outdir, exist_ok=True)
                gdir = os.path.join(args.repo, "assets", "monsters", "lords")
                os.makedirs(gdir, exist_ok=True)
                ok, msg = export_glb(objs, os.path.join(gdir, "%s.glb" % key))
                written, eng, cam = render_views(objs, key, outdir, resx, resy, info)
                mn, mx, _ = world_bounds(objs)
                report["lords"][key] = dict(
                    title=info["title"], parts=len(objs), engine=eng,
                    tris=sum(len(o.data.polygons) for o in objs),
                    size=[round(mx.x - mn.x, 2), round(mx.y - mn.y, 2), round(mx.z - mn.z, 2)],
                    glb=ok, glb_msg=msg, cam=cam, views=[os.path.basename(p) for p in written])
            except Exception as e:
                import traceback
                report["ok"] = False
                report["errors"].append("%s: %s" % (key, traceback.format_exc()[-900:]))

    purge()
    try:
        bad, checked = sheets(args.repo, resx, resy)
        report["blank_check"] = {"files": len(checked), "failures": [list(b) for b in bad]}
        if bad:
            report["ok"] = False
    except Exception as e:
        import traceback
        report["ok"] = False
        report["errors"].append("sheets: %s" % traceback.format_exc()[-900:])

    out = os.path.join(args.repo, "renders", "art", "lords", "_report.json")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w") as f:
        json.dump(report, f, indent=1)
    print("LORDGEN_REPORT " + json.dumps({"ok": report["ok"],
                                          "n": len(report["lords"]),
                                          "errors": report["errors"][:3],
                                          "blank": report.get("blank_check", {}).get("failures", [])[:5]}))


main()
