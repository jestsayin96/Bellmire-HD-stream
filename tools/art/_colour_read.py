"""_colour_read - DOES THE COLOUR ARRIVE IN THE PICTURE?

  blender -b -noaudio -P tools/art/_colour_read.py -- --repo <repo> \
      --keys dyer,strickler,drillmaster --bar 0.207 --bands 2

WHY THIS EXISTS, AND IT IS THE SAME FAULT CLASS TWICE OVER.
The team lead's 18:58 note said the register is drifting grey and asked whether
a twenty-fourth could carry its trade in COLOUR. A tint table cannot answer
that. I checked: CANON gives the Tallyman HSV saturation 0.66 and its shipped
front.png measures 0.136, so the tint table is a claim about the INPUT and the
question is about the OUTPUT. This lane has already shipped one number that
answered a different question than the sentence beside it (`head_glow_px: 156`
next to "the head has no face at all", because mask_of rendered a group alone).

So this asks the viewer's question the only way that works: RENDER the creature
through the shipping materials and measure the pixels. Nothing here reads CANON
for a colour.

IT GOES RED, AND IT CAN GO RED ON ITS AUTHOR - that is the point of the
controls. Run it with an already-shipped body in --keys and that body must FAIL
the bar; if everything passes, the instrument is not measuring.
  - a silhouette under 400 px is a FAILED RENDER, not a small creature
  - zero chroma pixels is BLIND, reported as an error, never as "0.000 sat"
  - a hue band computed over ZERO pixels is an ERROR, not a 0.0 share
  - satMean at or below --bar FAILS. The bar is the register's own measured
    maximum, so "more colourful than anything we have" is the test, not
    "has a colour".
  - fewer than --bands hue bands holding >= 8% of the chroma mass FAILS. One
    band is a monochrome body however bright it is, and monochrome is exactly
    what the lead asked to be broken.
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
import lordlib as L          # noqa: E402
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402

RES = (520, 700)
# five bands, the same cut used on the register census so the numbers compare
BANDS = (("red_orange", 0, 60), ("yellow_green", 60, 110), ("green_teal", 110, 190),
         ("blue", 190, 260), ("violet_magenta", 260, 360))


def _mats(key):
    title, height, tint, aura, theme, idea, wear, line = M.CANON[key]
    body = tuple((c * 0.80) * 0.80 + a * 0.20 for c, a in zip(tint, aura))
    dull = 1.0 - 0.45 * wear
    body = tuple(c * dull + 0.010 * wear for c in body)
    rough = 0.34 + 0.40 * wear
    metal = 0.55 * (1.0 - wear) ** 1.4
    mats = {
        'body': L.mat_solid(key + "_cb", body, rough, metal),
        'dark': L.mat_solid(key + "_cd", tuple(c * 0.16 + 0.012 for c in body), 0.74, 0.04),
        'bone': L.mat_solid(key + "_cn", tuple((0.30 + c * 0.55) * dull for c in tint),
                            rough * 0.9, 0.02),
        'glow': L.mat_glow(key + "_cg", tuple(min(1.0, c / max(aura)) for c in aura), 3.2),
    }
    return M.apply_overrides(key, mats)


def _objs(key, items, mats, suffix, vcols=None):
    """Delegates to minibosses.merge_objs - THE one merge the shipping generator
    uses. This file used to carry its own identical copy, and so did two other
    readers; measuring a body through a different merge than the one that ships
    is the same fault class as measuring it through a different material table.
    `vcols` must be passed through from the builder or a vertex-painted slot is
    measured UNPAINTED, which would read as a fix that is not there."""
    return M.merge_objs(key, items, mats, suffix=suffix, vcols=vcols)


def _clear():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)


def _rig(mn, mx):
    scene = bpy.context.scene
    G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = RES
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    ctr = Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0, (mn.z + mx.z) / 2.0))
    rad = max(1e-3, max(mx.x - mn.x, mx.y - mn.y, mx.z - mn.z))
    cam_d = rad * 4.0
    cam = bpy.data.cameras.new("c_cam")
    cam.type = 'ORTHO'
    cam.ortho_scale = rad * 1.34
    cam.clip_start = max(0.01, cam_d - rad * 3.0)
    cam.clip_end = cam_d + rad * 3.0
    ob = bpy.data.objects.new("c_cam", cam)
    scene.collection.objects.link(ob)
    scene.camera = ob
    for ang, energy in ((40.0, 3.4), (-120.0, 1.5)):
        li = bpy.data.lights.new("c_l", 'SUN')
        li.energy = energy
        lo = bpy.data.objects.new("c_l", li)
        scene.collection.objects.link(lo)
        lo.rotation_euler = (math.radians(55.0), 0.0, math.radians(ang))
    return ob, ctr, cam_d


def _place(camob, ctr, d, yaw_deg, pitch_deg):
    a = math.radians(yaw_deg)
    p = math.radians(pitch_deg)
    camob.location = (ctr.x + d * math.sin(a) * math.cos(p),
                      ctr.y - d * math.cos(a) * math.cos(p),
                      ctr.z + d * math.sin(p))
    camob.rotation_euler = (math.radians(90.0 - pitch_deg), 0.0, a)
    bpy.context.view_layer.update()


def detached(a, min_px=12):
    """How many pieces is this creature in, and how big is each stray one?

    ADDED AT THE DYER'S PASS 7, AFTER A FAULT THAT GOT PAST EVERY CHECK THIS
    LANE HAS. Two glow spheres sat 0.23 m in front of the creature's face. The
    FRONT camera put them on the face by projection and they looked right; the
    blank check saw opaque pixels and passed; the border check saw nothing at
    the frame edge and passed. A FLOATING PIECE IS NEITHER BLANK NOR CLIPPED,
    so neither instrument could ever have caught it. This one can: a creature
    should be ONE connected silhouette, and anything else is a part that is
    not attached to it. Reported, not fatal on its own - a chain link or a
    thrown thing may be detached on purpose - but it must be NAMED, because
    the whole fault was that nobody was told.
    """
    m = (a[..., 3] > 0.3)
    h, w = m.shape
    seen = np.zeros((h, w), dtype=bool)
    comps = []
    for sy in range(h):
        row = m[sy]
        for sx in range(w):
            if not row[sx] or seen[sy, sx]:
                continue
            stack = [(sy, sx)]
            seen[sy, sx] = True
            n = 0
            ys0 = ys1 = sy
            xs0 = xs1 = sx
            while stack:
                cy, cx = stack.pop()
                n += 1
                if cy < ys0: ys0 = cy
                if cy > ys1: ys1 = cy
                if cx < xs0: xs0 = cx
                if cx > xs1: xs1 = cx
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    ny, nx = cy + dy, cx + dx
                    if 0 <= ny < h and 0 <= nx < w and m[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        stack.append((ny, nx))
            comps.append((n, ys0, ys1, xs0, xs1))
    if not comps:
        return {"error": "no silhouette at all - RED ON EMPTY"}
    comps.sort(reverse=True)
    stray = [{"px": c[0], "bbox": [c[3], c[1], c[4], c[2]]} for c in comps[1:] if c[0] >= min_px]
    return {"components": len(comps), "main_px": comps[0][0], "stray": stray}


def measure(a):
    """HSV saturation and chroma-weighted hue over the opaque, non-black body.

    Returns a dict, or an error string. NEVER returns a green-looking zero:
    an empty population is an error, because a metric computed over nothing
    reads as 'no problem' and means nothing - this lane wrote that rule for
    itself after measuring a ratio over zero pairs.
    """
    al = a[..., 3]
    m = al > 0.6
    sil = int((al > 0.02).sum())
    if sil < 400:
        return "silhouette %d px - a failed render, not a small creature" % sil
    rgb = a[..., :3][m]
    if rgb.size == 0:
        return "no opaque pixels at alpha>0.6 - RED ON EMPTY"
    mx = rgb.max(1)
    mn = rgb.min(1)
    keep = mx > 0.10                      # drop the unlit black, not the colour
    rgb, mx, mn = rgb[keep], mx[keep], mn[keep]
    if rgb.shape[0] < 200:
        return "only %d lit pixels - RED ON EMPTY" % rgb.shape[0]
    sat = (mx - mn) / np.maximum(mx, 1e-6)
    chroma = mx - mn
    r, g, b = rgb[:, 0], rgb[:, 1], rgb[:, 2]
    hue = np.zeros_like(r)
    d = np.maximum(chroma, 1e-6)
    i_r = (mx == r)
    i_g = (mx == g) & ~i_r
    i_b = ~i_r & ~i_g
    hue[i_r] = ((g[i_r] - b[i_r]) / d[i_r]) % 6.0
    hue[i_g] = ((b[i_g] - r[i_g]) / d[i_g]) + 2.0
    hue[i_b] = ((r[i_b] - g[i_b]) / d[i_b]) + 4.0
    hue = (hue * 60.0) % 360.0
    cm = chroma > 0.04                    # only pixels a viewer would call coloured
    if cm.sum() == 0:
        return "BLIND - zero chroma pixels; this body has no colour at all"
    hv, wv = hue[cm], chroma[cm]
    ang = np.deg2rad(hv)
    mean_hue = float(np.degrees(np.arctan2(float((np.sin(ang) * wv).sum()),
                                           float((np.cos(ang) * wv).sum()))) % 360.0)
    total = float(wv.sum())
    if total <= 0:
        return "chroma mass is zero over %d chroma pixels - instrument fault" % int(cm.sum())
    bands = {}
    for name, lo, hi in BANDS:
        sel = (hv >= lo) & (hv < hi)
        bands[name] = round(float(wv[sel].sum()) / total, 4)
    held = sorted([n for n, v in bands.items() if v >= 0.08])
    return {"sil_px": sil, "lit_px": int(rgb.shape[0]), "chroma_px": int(cm.sum()),
            "sat_mean": round(float(sat.mean()), 4),
            "sat_p90": round(float(np.percentile(sat, 90)), 4),
            "mean_hue": round(mean_hue, 1),
            "bands": bands, "bands_held": held, "n_bands_held": len(held)}


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--keys", required=True)
    ap.add_argument("--judge", default="",
                    help="comma list of keys the bar is a PASS/FAIL for; the rest "
                         "are controls and are only reported")
    ap.add_argument("--bar", type=float, default=0.207,
                    help="satMean must EXCEED this in the front view. Default is the "
                         "register's own measured maximum (the Drillmaster).")
    ap.add_argument("--bands", type=int, default=2)
    args = ap.parse_args(argv)

    tmp = os.path.join(args.repo, "renders", "art", "minibosses", "_colour_tmp")
    os.makedirs(tmp, exist_ok=True)
    judge = set(k.strip() for k in args.judge.split(",") if k.strip())
    rep = {"ok": True, "errors": [], "bar_sat_mean": args.bar, "bar_bands": args.bands,
           "judged": sorted(judge), "creatures": {}, "verdict": {}}

    for key in [k.strip() for k in args.keys.split(",") if k.strip()]:
        if key not in M.BUILDERS:
            rep["errors"].append("%s: no builder" % key)
            rep["ok"] = False
            continue
        _clear()
        mats = _mats(key)
        P = M.BUILDERS[key]()
        height = M.CANON[key][1]
        obs = _objs(key, P.items, mats, "c", getattr(P, "vcols", None))
        mn, mx, _ = G.world_bounds(obs)
        cur = mx.z - mn.z
        k = height / cur if cur > 1e-6 else 1.0
        for ob in obs:
            ob.scale = (k, k, k)
            ob.location = (ob.location.x * k, ob.location.y * k, ob.location.z * k)
        bpy.context.view_layer.update()
        mn, mx, _ = G.world_bounds(obs)
        camob, ctr, d = _rig(mn, mx)
        cell = {"override": key in M.OVERRIDE, "by_view": {}}
        for vname, yaw in (("front", 0.0), ("side", 90.0), ("back", 180.0)):
            _place(camob, ctr, d, yaw, 2.0)
            path = os.path.join(tmp, "%s_%s.png" % (key, vname))
            bpy.context.scene.render.filepath = path
            bpy.ops.render.render(write_still=True)
            a = G.read_png(path)
            r = measure(a)
            if isinstance(r, str):
                rep["errors"].append("%s/%s: %s" % (key, vname, r))
                rep["ok"] = False
                cell["by_view"][vname] = {"error": r}
            else:
                dt = detached(a)
                r["detached"] = dt
                if "error" in dt:
                    rep["errors"].append("%s/%s detached: %s" % (key, vname, dt["error"]))
                    rep["ok"] = False
                elif dt["stray"]:
                    rep["errors"].append(
                        "%s/%s: silhouette is in %d pieces - %s floats off the body"
                        % (key, vname, dt["components"],
                           ", ".join("%d px at %s" % (x["px"], x["bbox"]) for x in dt["stray"])))
                    rep["ok"] = False
                cell["by_view"][vname] = r
        rep["creatures"][key] = cell

        fv = cell["by_view"].get("front", {})
        if "error" in fv or not fv:
            v = {"pass": False, "why": "front view did not measure"}
        else:
            ok_sat = fv["sat_mean"] > args.bar
            ok_bands = fv["n_bands_held"] >= args.bands
            v = {"pass": bool(ok_sat and ok_bands),
                 "sat_mean": fv["sat_mean"], "n_bands_held": fv["n_bands_held"],
                 "why": ("sat %.4f %s bar %.3f; bands %d %s %d"
                         % (fv["sat_mean"], ">" if ok_sat else "<=", args.bar,
                            fv["n_bands_held"], ">=" if ok_bands else "<", args.bands))}
        v["judged"] = key in judge
        rep["verdict"][key] = v
        if key in judge and not v["pass"]:
            rep["ok"] = False
            rep["errors"].append("%s FAILS the colour bar: %s" % (key, v["why"]))

    # THE INSTRUMENT MUST DISCRIMINATE. If every control passed the bar too,
    # the bar is not measuring anything and this run is not evidence.
    ctrl = [k for k in rep["verdict"] if k not in judge]
    if ctrl and all(rep["verdict"][k]["pass"] for k in ctrl):
        rep["ok"] = False
        rep["errors"].append("EVERY CONTROL PASSED (%s) - the bar discriminates nothing, "
                             "so no PASS in this run is evidence" % ",".join(sorted(ctrl)))

    out = os.path.join(args.repo, "renders", "art", "minibosses", "_colour_read.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(rep, f, indent=1, sort_keys=True)
    print("COLOUR_READ %s" % ("OK" if rep["ok"] else "FAIL"))
    for e in rep["errors"]:
        print("  ERR %s" % e)
    for key in sorted(rep["verdict"]):
        v = rep["verdict"][key]
        print("  %-14s %-7s %s%s" % (key, "PASS" if v["pass"] else "FAIL", v["why"],
                                     "" if v["judged"] else "   (control)"))
    print("  json -> %s" % out)
    return 0 if rep["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
