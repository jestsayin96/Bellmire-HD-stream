"""_trade_read - DOES THE TRADE READ FROM THIS CAMERA?

  blender -b -noaudio -P tools/art/_trade_read.py -- --repo <repo> --keys strickler,pressman,tapster

WHY THIS EXISTS. The team lead's note on the Pressman (17:58 CT): its trade
reads from the front and the side collapses to a narrow post, and "if the
twenty-third can carry its trade in the SIDE view as strongly as the front,
that is worth more than a twenty-fourth." That is a claim about what a VIEWER
can see, and this lane has already shipped one number that answered a different
question than the sentence beside it - `head_glow_px: 156` next to "the head
has no face at all", because mask_of rendered the group ALONE and so measured
how BIG it was, not whether it could be SEEN.

So this asks the viewer's question the only way that works: render the creature
THROUGH ONE FIXED CAMERA with the group present and again with it removed, and
count the pixels that MOVED. The renderer does the depth. A group hidden behind
the body moves nothing and scores zero, which is the honest answer.

THE FRAMING IS COMPUTED ONCE FROM THE WHOLE CREATURE AND NEVER RECOMPUTED.
If the camera were re-derived per variant, removing a part would change the
bounds, the frame would shift, and EVERY pixel would read as moved - a number
that goes up when the instrument is wrong is worse than no number.

IT GOES RED ON EMPTY, which is the rule this lane wrote for itself after
measuring a ratio over zero pairs and calling it green:
  - a silhouette under 400 px is a failed render, not a small creature
  - a group with no items in it is an ERROR, not a 0.000 share
  - a trade group that moves nothing in EVERY view is reported as BLIND
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
# which spans are THE TRADE for each creature - the thing a viewer is meant to
# name it by. Named here and not guessed, so the number cannot drift.
TRADE = {
    "strickler": ("beam", "pan", "weights", "measure", "strickle"),
    "pressman": ("yoke", "collars", "taken"),
    "tapster": None,          # filled from the builder's own spans minus body
    # THE DYER: the frame is structure, not trade. A tenter frame with nothing
    # on it is a drying rack; the cloth, the vat, the paddle, the skeins and
    # the splashes are the job.
    "dyer": ("sheets", "vat", "paddle", "skeins", "splashes"),
}
BODY_SPANS = ("man", "body", "arms", "legs", "head")


def _mats(key):
    title, height, tint, aura, theme, idea, wear, line = M.CANON[key]
    body = tuple((c * 0.80) * 0.80 + a * 0.20 for c, a in zip(tint, aura))
    dull = 1.0 - 0.45 * wear
    body = tuple(c * dull + 0.010 * wear for c in body)
    rough = 0.34 + 0.40 * wear
    metal = 0.55 * (1.0 - wear) ** 1.4
    mats = {
        'body': L.mat_solid(key + "_tb", body, rough, metal),
        'dark': L.mat_solid(key + "_td", tuple(c * 0.16 + 0.012 for c in body), 0.74, 0.04),
        'bone': L.mat_solid(key + "_tn", tuple((0.30 + c * 0.55) * dull for c in tint),
                            rough * 0.9, 0.02),
        'glow': L.mat_glow(key + "_tg", tuple(min(1.0, c / max(aura)) for c in aura), 3.2),
    }
    # the SHIPPING materials, or this harness measures a creature that does not
    # exist. Added with the Dyer, 17 Nov; a no-op for all twenty-three.
    return M.apply_overrides(key, mats)


def _objs(key, items, mats, suffix):
    groups = {}
    for verts, faces, slot in items:
        gv, gf = groups.setdefault(slot, ([], []))
        off = len(gv)
        gv.extend(verts)
        gf.extend([tuple(i + off for i in f) for f in faces])
    out = []
    for slot in ('body', 'dark', 'bone', 'glow'):
        if slot not in groups:
            continue
        gv, gf = groups[slot]
        out.append(L.make("%s_%s_%s" % (key, slot, suffix), gv, gf, mats.get(slot, mats['body'])))
    return out


def _clear():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)


def _rig(mn, mx):
    """Camera and lights, set ONCE from the whole creature's bounds."""
    scene = bpy.context.scene
    G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = RES
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    ctr = Vector(((mn.x + mx.x) / 2.0, (mn.y + mx.y) / 2.0, (mn.z + mx.z) / 2.0))
    rad = max(1e-3, max(mx.x - mn.x, mx.y - mn.y, mx.z - mn.z))
    cam_d = rad * 4.0
    cam = bpy.data.cameras.new("tr_cam")
    cam.type = 'ORTHO'
    cam.ortho_scale = rad * 1.34
    cam.clip_start = max(0.01, cam_d - rad * 3.0)
    cam.clip_end = cam_d + rad * 3.0
    ob = bpy.data.objects.new("tr_cam", cam)
    scene.collection.objects.link(ob)
    scene.camera = ob
    for ang, energy in ((40.0, 3.4), (-120.0, 1.5)):
        li = bpy.data.lights.new("tr_l", 'SUN')
        li.energy = energy
        lo = bpy.data.objects.new("tr_l", li)
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


def _shoot(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return G.read_png(path)


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--keys", required=True)
    args = ap.parse_args(argv)

    tmp = os.path.join(args.repo, "renders", "art", "minibosses", "_trade_tmp")
    os.makedirs(tmp, exist_ok=True)
    rep = {"ok": True, "errors": [], "blind": [], "views": ["front", "side", "back"],
           "creatures": {}}

    for key in [k.strip() for k in args.keys.split(",") if k.strip()]:
        if key not in M.BUILDERS:
            rep["errors"].append("%s: no builder" % key)
            rep["ok"] = False
            continue
        _clear()
        mats = _mats(key)
        P = M.BUILDERS[key]()
        spans = dict(getattr(P, "spans", {}) or {})
        if not spans:
            rep["errors"].append("%s: builder exposes NO spans - nothing to measure" % key)
            rep["ok"] = False
            continue
        trade = TRADE.get(key)
        if trade is None:
            trade = tuple(s for s in spans if s not in BODY_SPANS)
        trade = tuple(s for s in trade if s in spans)
        if not trade:
            rep["errors"].append("%s: no trade spans resolved - RED ON EMPTY" % key)
            rep["ok"] = False
            continue

        height = M.CANON[key][1]
        full = _objs(key, P.items, mats, "full")
        mn, mx, _ = G.world_bounds(full)
        cur = mx.z - mn.z
        k = height / cur if cur > 1e-6 else 1.0

        def _scaled(items, sfx):
            obs = _objs(key, items, mats, sfx)
            for ob in obs:
                ob.scale = (k, k, k)
                ob.location = (ob.location.x * k, ob.location.y * k, ob.location.z * k)
            bpy.context.view_layer.update()
            return obs

        for ob in full:
            bpy.data.objects.remove(ob, do_unlink=True)
        full = _scaled(P.items, "full")
        mn, mx, _ = G.world_bounds(full)
        camob, ctr, d = _rig(mn, mx)

        cell = {"spans": {s: (spans[s][1] - spans[s][0]) for s in spans},
                "trade_spans": list(trade), "faces": sum(len(f) for _, f, _ in P.items),
                "by_view": {}}
        for vname, yaw, pitch in (("front", 0.0, 2.0), ("side", 90.0, 2.0), ("back", 180.0, 2.0)):
            _place(camob, ctr, d, yaw, pitch)
            a_full = _shoot(os.path.join(tmp, "%s_%s_full.png" % (key, vname)))
            sil = int((a_full[..., 3] > 0.02).sum())
            if sil < 400:
                rep["errors"].append("%s/%s: silhouette %d px - a failed render, not a "
                                     "small creature" % (key, vname, sil))
                rep["ok"] = False
                continue
            shares = {}
            for s in trade:
                i0, i1 = spans[s]
                if i1 <= i0:
                    rep["errors"].append("%s/%s: span '%s' is EMPTY - red on empty"
                                         % (key, vname, s))
                    rep["ok"] = False
                    continue
                items = P.items[:i0] + P.items[i1:]
                for ob in list(bpy.data.objects):
                    if ob.type == 'MESH':
                        bpy.data.objects.remove(ob, do_unlink=True)
                cut = _scaled(items, "cut")
                a_cut = _shoot(os.path.join(tmp, "%s_%s_%s.png" % (key, vname, s)))
                moved = ((np.abs(a_full[..., 3] - a_cut[..., 3]) > 0.02) |
                         (np.abs(a_full[..., 0:3] - a_cut[..., 0:3]).max(axis=-1) > 0.02))
                shares[s] = round(float(moved.sum()) / float(sil), 4)
                for ob in cut:
                    bpy.data.objects.remove(ob, do_unlink=True)
                full = _scaled(P.items, "full")
            cell["by_view"][vname] = {"silhouette_px": sil, "shares": shares,
                                      "trade_total": round(sum(shares.values()), 4)}
        f = cell["by_view"].get("front", {}).get("trade_total", 0.0)
        s_ = cell["by_view"].get("side", {}).get("trade_total", 0.0)
        cell["front_total"] = f
        cell["side_total"] = s_
        cell["side_over_front"] = round(s_ / f, 3) if f else None
        for s in trade:
            if all(cell["by_view"].get(v, {}).get("shares", {}).get(s, 0.0) <= 0.0
                   for v in ("front", "side", "back")):
                rep["blind"].append("%s: trade group '%s' moves NOTHING in any view" % (key, s))
        rep["creatures"][key] = cell
        _clear()

    print("TRADEREAD " + json.dumps(rep))


main()
