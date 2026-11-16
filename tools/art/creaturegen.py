"""creaturegen - headless Blender driver for D76, THE TWELVE SHARED BODIES.

  blender -b -noaudio -P tools/art/creaturegen.py -- --repo <repo> [--only key] [--res 560x780]
  blender -b -noaudio -P tools/art/creaturegen.py -- --repo <repo> --sheet

Reuses D75's render rig wholesale (lordgen.render_views / world_bounds /
export_glb / read_png / write_png / draw_text), so the two documented traps are
answered the same way they were for the lords:

  SCALE   - the camera's ortho scale and clip range come from the EVALUATED
            world-space bounds. These twelve span 0.35 m (spiderling) to 4.0 m
            (pit wyrm) in one batch - an eleven-fold range - so nothing may
            assume a size. A wrong clip_end renders an empty transparent frame
            and REPORTS SUCCESS.
  BLANKS  - every PNG is re-opened and its opaque pixel count asserted. On 15
            Nov the lords' first pass came back 24-for-24 empty with Blender
            reporting success on every one; this check is the only reason it
            was caught.

The silhouette sheet is the real acceptance test for this item: with the colour
thrown away, each of the twelve must read as itself, and none may read as the
creature whose mesh it is replacing.
"""
import os
import sys
import json
import argparse

import bpy
import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordlib as L          # noqa: E402
import lordgen as G          # noqa: E402
import creatures as C        # noqa: E402


def build_creature(key):
    title, height, tint, aura, note, shares = C.CANON[key]
    # Same material logic as the lords: the tint has to survive the view
    # transform, so bone is tinted rather than bleached and a fifth of the aura
    # is mixed into the body - otherwise the four beasts read as one grey beast.
    body = tuple((c * 0.80) * 0.80 + a * 0.20 for c, a in zip(tint, aura))
    mats = {
        'body': L.mat_solid(key + "_body", body, 0.54, 0.05),
        'dark': L.mat_solid(key + "_dark", tuple(c * 0.16 + 0.012 for c in body), 0.70, 0.04),
        'bone': L.mat_solid(key + "_bone", tuple(0.30 + c * 0.55 for c in tint), 0.44, 0.02),
        'glow': L.mat_glow(key + "_glow", tuple(min(1.0, c / max(aura)) for c in aura), 3.0),
    }
    P = C.BUILDERS[key]()
    # merge by material before making objects: built part-by-part these run to
    # 60-200 objects, i.e. that many draw calls per creature, and a floor can
    # hold a dozen of them at once. Merged, each is at most four meshes.
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
    # author at the bestiary height, feet on z=0 - Monster normalises on top
    mn, mx, _ = G.world_bounds(objs)
    cur = mx.z - mn.z
    k = height / cur if cur > 1e-6 else 1.0
    for ob in objs:
        ob.scale = (k, k, k)
        ob.location = (ob.location.x * k, ob.location.y * k, ob.location.z * k)
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(objs)
    for ob in objs:
        ob.location = (ob.location.x, ob.location.y, ob.location.z - mn.z)
    bpy.context.view_layer.update()
    return objs, dict(title=title, height=height, tint=tint, aura=aura,
                      note=note, shares=shares)


def sheets(repo, resx, resy):
    """Contact sheet and - the one that matters - the silhouette sheet."""
    root = os.path.join(repo, "renders", "art", "creatures")
    bad, checked = [], []
    for key in C.ORDER:
        for vname, _, _ in G.VIEWS:
            p = os.path.join(root, key, "%s.png" % vname)
            if not os.path.isfile(p):
                bad.append((p, "missing"))
                continue
            a = G.read_png(p)
            n = int((a[..., 3] > 0.02).sum())
            checked.append((os.path.relpath(p, repo), n, a.shape[1], a.shape[0]))
            if n < 400:
                bad.append((p, "blank or near-blank: %d opaque px" % n))

    cells = []
    for key in C.ORDER:
        p = os.path.join(root, key, "three_quarter.png")
        cells.append((key, G.box2(G.read_png(p)) if os.path.isfile(p) else None))

    ch, cw = resy // 2, resx // 2
    lab = 42
    cols, rows = 4, 3
    sheet = np.zeros((rows * (ch + lab), cols * cw, 4), dtype=np.float32)
    sheet[..., 0:3] = np.array((0.055, 0.060, 0.075))
    sheet[..., 3] = 1.0
    sil = np.zeros_like(sheet)
    sil[..., 0:3] = np.array((0.93, 0.93, 0.90))
    sil[..., 3] = 1.0
    for i, (key, a) in enumerate(cells):
        cx, cy = (i % cols) * cw, (i // cols) * (ch + lab)
        title, height, tint, aura, note, shares = C.CANON[key]
        if a is not None:
            al = a[..., 3:4]
            dst = sheet[cy:cy + ch, cx:cx + cw, 0:3]
            sheet[cy:cy + ch, cx:cx + cw, 0:3] = a[..., 0:3] * al + dst * (1.0 - al)
            m = (al[..., 0] > 0.45)
            cell = sil[cy:cy + ch, cx:cx + cw, 0:3]
            cell[m] = np.array((0.06, 0.06, 0.08))
        tag = "%s  %.2fM" % (title, height)
        was = "WAS " + shares.replace(".glb", "").replace("_", " ").upper()
        sc = 2 if 6 * 2 * len(tag) <= cw - 16 else 1
        for s, c1, c2 in ((sheet, (0.85, 0.80, 0.68), (0.46, 0.52, 0.60)),
                          (sil, (0.15, 0.15, 0.20), (0.45, 0.45, 0.52))):
            s[cy + ch:cy + ch + 2, cx:cx + cw, 0:3] = np.array(c1) * 0.35
            G.draw_text(s, tag, cx + 8, cy + ch + 8, sc, c1)
            G.draw_text(s, was, cx + 8, cy + ch + 10 + 7 * sc + 4, 1, c2)
    G.write_png(os.path.join(root, "_contact_sheet.png"), sheet)
    G.write_png(os.path.join(root, "_silhouettes.png"), sil)
    return bad, checked


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--res", default="560x780")
    ap.add_argument("--only", default="")
    ap.add_argument("--sheet", action="store_true")
    args = ap.parse_args(argv)
    resx, resy = (int(x) for x in args.res.split("x"))
    report = {"ok": True, "creatures": {}, "errors": []}

    if not args.sheet:
        keys = [args.only] if args.only else list(C.ORDER)
        for key in keys:
            G.purge()
            try:
                objs, info = build_creature(key)
                outdir = os.path.join(args.repo, "renders", "art", "creatures", key)
                os.makedirs(outdir, exist_ok=True)
                gdir = os.path.join(args.repo, "assets", "monsters", "creatures")
                os.makedirs(gdir, exist_ok=True)
                ok, msg = G.export_glb(objs, os.path.join(gdir, "%s.glb" % key))
                written, eng, cam = G.render_views(objs, key, outdir, resx, resy, info)
                mn, mx, _ = G.world_bounds(objs)
                report["creatures"][key] = dict(
                    title=info["title"], shares=info["shares"], parts=len(objs),
                    engine=eng, faces=sum(len(o.data.polygons) for o in objs),
                    size=[round(mx.x - mn.x, 2), round(mx.y - mn.y, 2), round(mx.z - mn.z, 2)],
                    glb=ok, glb_msg=msg, cam=cam,
                    views=[os.path.basename(p) for p in written])
            except Exception:
                import traceback
                report["ok"] = False
                report["errors"].append("%s: %s" % (key, traceback.format_exc()[-900:]))

    G.purge()
    try:
        bad, checked = sheets(args.repo, resx, resy)
        report["blank_check"] = {"files": len(checked), "failures": [list(b) for b in bad]}
        if bad:
            report["ok"] = False
    except Exception:
        import traceback
        report["ok"] = False
        report["errors"].append("sheets: %s" % traceback.format_exc()[-900:])

    out = os.path.join(args.repo, "renders", "art", "creatures", "_report.json")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w") as f:
        json.dump(report, f, indent=1)
    print("CREATUREGEN_REPORT " + json.dumps({
        "ok": report["ok"], "n": len(report["creatures"]),
        "errors": report["errors"][:3],
        "blank": report.get("blank_check", {}).get("failures", [])[:5]}))


if __name__ == "__main__":
    main()
