"""minibossgen - headless Blender driver for THE MINIBOSSES (Mr. E's standing
permission, 15 Nov 17:43 - minibosses need no lore).

  blender -b -noaudio -P tools/art/minibossgen.py -- --repo <repo> [--only key] [--res 700x980]
  blender -b -noaudio -P tools/art/minibossgen.py -- --repo <repo> --sheet

Reuses D75's render rig wholesale (lordgen.render_views / world_bounds /
export_glb / read_png / write_png / draw_text), so the two documented traps are
answered exactly as they were for the lords and the twelve creatures:

  SCALE   - ortho scale and clip range come from the EVALUATED world-space
            bounds of the real geometry. A wrong clip_end renders an empty
            transparent frame and REPORTS SUCCESS.
  BLANKS  - every PNG is re-opened and its opaque pixel count asserted. Three
            batches on 15 Nov came back blank with Blender reporting success on
            every file; this assertion is the only reason none of them shipped.

THIS FILE ALSO MEASURES THE CORRIDOR QUESTION so nobody has to hope. D91 widens
dungeon corridors to THREE CELLS and floorgen.gd's cell is G = 4.0 m, with walls
reaching WALL_IN = 0.5 m into the edge cells - so the clear span of a three-cell
corridor is 11.0 m. Every miniboss's measured footprint is compared against that
and the report says ROOM-LOCKED or CORRIDOR-SAFE per creature. Room-locking is a
construction fact, never a hope that something fails to fit.

WEAR IS A VARIABLE: each miniboss carries its own `wear` (minibosses.CANON) and
it drives the materials here, not the geometry - roughness up, metal down, and
the colour pulled toward the dark as wear rises. The contact sheet prints the
value so the difference is checkable, not asserted.
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
import minibosses as M       # noqa: E402

# floorgen.gd: G = 4.0 (cell), WALL_IN = 0.5 (a wall reaches this far into its
# cell). D91 stage 3: corridors become three cells wide. Hence:
CELL_M = 4.0
WALL_IN = 0.5
CORRIDOR_CLEAR = 3 * CELL_M - 2 * WALL_IN      # 11.0 m


def build_miniboss(key):
    title, height, tint, aura, theme, idea, wear, line = M.CANON[key]
    # Same material logic as the creatures (the tint has to survive the view
    # transform, so bone is tinted rather than bleached and a fifth of the aura
    # is mixed into the body), with WEAR applied on top: a worn thing is
    # rougher, less metallic and pulled toward the dark.
    body = tuple((c * 0.80) * 0.80 + a * 0.20 for c, a in zip(tint, aura))
    dull = 1.0 - 0.45 * wear
    body = tuple(c * dull + 0.010 * wear for c in body)
    rough = 0.34 + 0.40 * wear
    metal = 0.55 * (1.0 - wear) ** 1.4
    mats = {
        'body': L.mat_solid(key + "_body", body, rough, metal),
        'dark': L.mat_solid(key + "_dark", tuple(c * 0.16 + 0.012 for c in body), 0.74, 0.04),
        'bone': L.mat_solid(key + "_bone", tuple((0.30 + c * 0.55) * dull for c in tint),
                            rough * 0.9, 0.02),
        'glow': L.mat_glow(key + "_glow", tuple(min(1.0, c / max(aura)) for c in aura), 3.2),
    }
    # 17 Nov, THE DYER: a key may declare its own per-slot materials. Without
    # this every material in this file was derived from ONE tint, so every body
    # was monochrome BY CONSTRUCTION - measured off the register's own renders
    # (median satMean 0.087, max 0.207, and ZERO bodies in two of five hue
    # bands). That was a defect in this generator, not a taste problem.
    # The override list is asserted EMPTY for every pre-existing key, so the
    # twenty-three render byte-for-byte as before.
    # 17 Nov, THE GREENER: the permitted set is DECLARED IN minibosses.py
    # (OVERRIDE_ALLOWED) instead of hard-coded here, because this assertion
    # exists to stop an override being pointed at an ALREADY-SHIPPED body and
    # a literal in this file would have made every new key trip it. Falls back
    # to {"dyer"} so an older minibosses.py still asserts.
    _LEGACY = set(M.ORDER) - getattr(M, "OVERRIDE_ALLOWED", {"dyer"})
    assert not (set(M.OVERRIDE) & _LEGACY), \
        "OVERRIDE must not touch an already-shipped key: %s" % sorted(set(M.OVERRIDE) & _LEGACY)
    mats = M.apply_overrides(key, mats)
    P = M.BUILDERS[key]()
    # 17 Nov: the Quartermaster loads real pack geometry out of assets/gear and
    # falls back to procedural if it cannot. A silent fallback would be the same
    # fault class as a lying gate, so the builder's own flag is RECORDED.
    pack_used = getattr(P, "used_pack", None)
    # merge by material before making objects: built part-by-part these run to
    # 60-200 objects, i.e. that many draw calls for one set piece. Merged, each
    # is at most four meshes - the same bar the lords and the creatures hold to.
    # ONE merge, shared with _metal_read / _trade_read / _colour_read - see
    # minibosses.merge_objs. Four private copies of this loop is four things to
    # disagree about, and a colour measured through a different merge than the
    # one that ships is a number about nothing.
    objs = M.merge_objs(key, P.items, mats, vcols=getattr(P, "vcols", None))
    # author at the intended height with feet on z=0 - Monster normalises on top
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
                      theme=theme, idea=idea, wear=wear, line=line,
                      pack_used=pack_used)


def sheets(repo, resx, resy):
    """Contact sheet and - the acceptance test - the silhouette sheet."""
    root = os.path.join(repo, "renders", "art", "minibosses")
    bad, checked = [], []
    for key in M.ORDER:
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
    for key in M.ORDER:
        p = os.path.join(root, key, "three_quarter.png")
        cells.append((key, G.box2(G.read_png(p)) if os.path.isfile(p) else None))

    # the grid follows the set size: 2x2 for four, 4x2 for eight. A fixed 2x2
    # silently dropped everything past the fourth when the second set landed.
    ch, cw = resy // 2, resx // 2
    # draw_text advances 6*scale px per character, so a cell fits (cw-16)//12
    # characters at scale 2. The third set's hooks are longer than that and ran
    # straight over the neighbouring cell's label - "IT PLANTS THE GROUND
    # AGAINST YOU" collided with "IT HAS ALREADY SET THE ROOM" and the firepit
    # hook was cut off by the sheet edge. The hook is the one line that says
    # what the thing DOES, so it wraps rather than shrinks.
    maxc = max(8, (cw - 16) // 12)
    lab = 74
    n = len(cells)
    cols = 2 if n <= 4 else 4
    rows = (n + cols - 1) // cols
    sheet = np.zeros((rows * (ch + lab), cols * cw, 4), dtype=np.float32)
    sheet[..., 0:3] = np.array((0.055, 0.060, 0.075))
    sheet[..., 3] = 1.0
    sil = np.zeros_like(sheet)
    sil[..., 0:3] = np.array((0.93, 0.93, 0.90))
    sil[..., 3] = 1.0
    for i, (key, a) in enumerate(cells):
        cx, cy = (i % cols) * cw, (i // cols) * (ch + lab)
        title, height, tint, aura, theme, idea, wear, line = M.CANON[key]
        if a is not None:
            al = a[..., 3:4]
            dst = sheet[cy:cy + ch, cx:cx + cw, 0:3]
            sheet[cy:cy + ch, cx:cx + cw, 0:3] = a[..., 0:3] * al + dst * (1.0 - al)
            m = (al[..., 0] > 0.45)
            cell = sil[cy:cy + ch, cx:cx + cw, 0:3]
            cell[m] = np.array((0.06, 0.06, 0.08))
        tag = "%s  %.2fM" % (title, height)
        meta = "%s THEME   WEAR %.2f" % (theme.upper(), wear)
        words, hook_lines, cur = idea.split(" - ")[0].split(), [], ""
        for w in words:
            trial = (cur + " " + w).strip()
            if len(trial) > maxc and cur:
                hook_lines.append(cur)
                cur = w
            else:
                cur = trial
        if cur:
            hook_lines.append(cur)
        hook_lines = hook_lines[:2]
        for s, c1, c2, c3 in ((sheet, (0.85, 0.80, 0.68), (1.00, 0.86, 0.52), (0.46, 0.52, 0.60)),
                              (sil, (0.15, 0.15, 0.20), (0.30, 0.30, 0.38), (0.45, 0.45, 0.52))):
            s[cy + ch:cy + ch + 2, cx:cx + cw, 0:3] = np.array(c1) * 0.35
            G.draw_text(s, tag[:maxc], cx + 8, cy + ch + 7, 2, c1)
            for li, hl in enumerate(hook_lines):
                G.draw_text(s, hl, cx + 8, cy + ch + 25 + li * 18, 2, c2)
            G.draw_text(s, meta, cx + 8, cy + ch + 61, 1, c3)
    G.write_png(os.path.join(root, "_contact_sheet.png"), sheet)
    G.write_png(os.path.join(root, "_silhouettes.png"), sil)
    return bad, checked


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--res", default="700x980")
    ap.add_argument("--only", default="")
    ap.add_argument("--sheet", action="store_true")
    args = ap.parse_args(argv)
    resx, resy = (int(x) for x in args.res.split("x"))
    report = {"ok": True, "corridor_clear_m": CORRIDOR_CLEAR, "minibosses": {}, "errors": []}
    out = os.path.join(args.repo, "renders", "art", "minibosses", "_report.json")

    # a --sheet-only pass used to start from an empty report and overwrite the
    # file, so the last run's report shipped with "minibosses": {} - every
    # span, face count and corridor verdict for all fourteen gone. Carry the
    # per-creature half forward and merge whatever this pass rebuilds over it.
    if os.path.isfile(out):
        try:
            with open(out) as f:
                report["minibosses"] = dict(json.load(f).get("minibosses", {}))
        except Exception:
            pass

    if not args.sheet:
        # --only takes a COMMA LIST: the third set is six keys and one blender
        # launch per key threw away the report of the five before it.
        keys = [k for k in args.only.split(",") if k] if args.only else list(M.ORDER)
        for key in keys:
            G.purge()
            try:
                objs, info = build_miniboss(key)
                outdir = os.path.join(args.repo, "renders", "art", "minibosses", key)
                os.makedirs(outdir, exist_ok=True)
                gdir = os.path.join(args.repo, "assets", "monsters", "minibosses")
                os.makedirs(gdir, exist_ok=True)
                ok, msg = G.export_glb(objs, os.path.join(gdir, "%s.glb" % key))
                written, eng, cam = G.render_views(objs, key, outdir, resx, resy, info)
                mn, mx, _ = G.world_bounds(objs)
                w, d, h = mx.x - mn.x, mx.y - mn.y, mx.z - mn.z
                span = max(w, d)
                report["minibosses"][key] = dict(
                    title=info["title"], theme=info["theme"], idea=info["idea"],
                    wear=info["wear"], feed_line=info["line"],
                    pack_used=info.get("pack_used"),
                    parts=len(objs), engine=eng,
                    faces=sum(len(o.data.polygons) for o in objs),
                    size=[round(w, 2), round(d, 2), round(h, 2)],
                    footprint_span=round(span, 2),
                    corridor="ROOM-LOCKED" if span > CORRIDOR_CLEAR else "CORRIDOR-SAFE",
                    glb=ok, glb_msg=msg, cam=cam,
                    views=[os.path.basename(p) for p in written])
                if len(objs) > 4:
                    report["ok"] = False
                    report["errors"].append("%s: %d meshes, the bar is four" % (key, len(objs)))
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

    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w") as f:
        json.dump(report, f, indent=1)
    print("MINIBOSSGEN_REPORT " + json.dumps({
        "ok": report["ok"], "n": len(report["minibosses"]),
        "errors": report["errors"][:3],
        "blank": report.get("blank_check", {}).get("failures", [])[:5],
        "spans": {k: (v["footprint_span"], v["corridor"], v["parts"], v["faces"])
                  for k, v in report["minibosses"].items()}}))


if __name__ == "__main__":
    main()
