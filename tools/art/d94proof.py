"""d94proof - D94's DONE BAR: six different items of a slot, side by side.

  blender -b -noaudio -P tools/art/d94proof.py -- --repo <repo> [--res 840x1200]

WORK_PLAN, D94, verbatim:
    "A single render, one row per slot, showing SIX DIFFERENT items of that
     slot side by side on real hero bodies at stream distance. If a viewer
     cannot tell them apart in that shot, it is not done. Then the same for
     weapons and armour."

So this is not another beauty sheet. It is a TEST, and it is built to be able
to FAIL - and on the first pass the ring row failed it outright, which is the
reason the sheet has three strips instead of one.

EVERY ROW HAS THREE STRIPS, and they answer three different questions:

  1. DETAIL - a tight ortho on the body part that wears the thing. Question:
     ARE these six actually six different objects? (D94's build half.)
  2. RENDER - the whole hero, one framing for all six. Question: where does
     the piece sit on a body, and does it fit?
  3. STREAM - strip 2 block-averaged down by STREAM_DIV and blown back up,
     which is what a viewer on a 1080p stream actually receives of a hero
     standing in a delve. Question: CAN A VIEWER TELL. This strip is Mr. E's
     bar; the other two are evidence.

SAME BODY, SAME POSE, SAME LIGHT, SAME FRAME, AND NOTHING ELSE WORN. The only
difference between the six cells of a row is the item under test, so anything
you can tell apart, you can tell apart because of the item.

AND A MEASURED NUMBER, NOT AN OPINION. For every pair in a row the STREAM
images are differenced and the row reports its worst pair - the two hardest to
tell apart - as the percentage of the hero's own pixels that change. A row
whose worst pair changes almost nothing has failed D94 whatever strip 1 looks
like. That is the number the verdict comes from.

The six are chosen for SPREAD, not prettiness: distinct name-derived variants
first (a Guard Helm must not render as a hood), then across the cost range,
because cost drives metal, ornateness and WEAR - Mr. E's receipt.

Derivations are D73's and D95's, imported rather than copied, so the icon in
the hub and the thing on the hero stay the same object.

The two traps this lane has already been bitten by are handled the same way as
every other driver here: framing and clip range come from measured bounds, and
every PNG is reopened and its opaque pixel count asserted.
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
import lordlib as L            # noqa: E402
import icons as IC             # noqa: E402
import showcase as SC          # noqa: E402
import lordgen as G            # noqa: E402
import e3pogen as EG           # noqa: E402
import showcasegen as SG       # noqa: E402

STREAM_DIV = 3          # render px -> stream px. A hero ends up ~105 px tall.
BODY = "Knight"         # ONE body for every cell, so the body is never the
                        # thing that tells two cells apart.
N = 6

# Where to point the DETAIL camera, per slot: anchor candidates, ortho height
# in metres, azimuth, elevation. A ring is 2 cm across on a 1.1 m body - it
# needs its own shot or the sheet cannot tell "they are the same" from
# "they are different and too small to see", which are opposite verdicts.
DETAIL = {
    "ring":   (("hand.l", "wrist.l", "lowerarm.l"), 0.34, 40.0, 18.0),
    "gloves": (("hand.l", "wrist.l", "lowerarm.l"), 0.50, 40.0, 18.0),
    "amulet": (("chest", "spine", "upperarm.l"), 0.80, 0.0, 6.0),
    "boots":  (("foot.l", "shin.l", "leg.l"), 0.60, 25.0, 14.0),
    "cloak":  (("chest", "spine"), 1.70, 180.0, 6.0),
    "hat":    (("head", "neck"), 0.80, 0.0, 6.0),
    "weapon": (("handslot.r", "hand.r"), 1.90, 28.0, 8.0),
    "armour": (("chest", "spine"), 1.70, 0.0, 6.0),
}


# --------------------------------------------------------------- choosing six
def khash(k):
    h = 0
    for c in k:
        h = (h * 131 + ord(c)) & 0xFFFFFFFF
    return h


def spread(pool, variant_of, n=N):
    """Six that are actually different. Distinct variants first (the NAME
    decides the silhouette), then fill by cost spread. Deterministic."""
    pool = sorted(pool, key=lambda q: (q[0], q[1]))      # (cost, key, rec)
    picked, seen = [], set()
    for cost, k, v in pool:
        var = variant_of(k, v)
        if var not in seen:
            seen.add(var)
            picked.append((cost, k, v))
        if len(picked) >= n:
            break
    if len(picked) < n:
        have = set(k for _, k, _ in picked)
        rest = [q for q in pool if q[1] not in have]
        need = n - len(picked)
        for i in range(need):
            if not rest:
                break
            j = int(i * (len(rest) - 1) / max(1, need - 1)) if need > 1 else 0
            picked.append(rest.pop(j))
    picked.sort(key=lambda q: q[0])
    return picked[:n]


def acc_rows(items):
    lo, hi = {}, {}
    for k, v in items["accessories"].items():
        s = v["slot"]
        lo[s] = min(lo.get(s, 1e9), v["cost"])
        hi[s] = max(hi.get(s, 0), v["cost"])
    rows = []
    for slot in ("ring", "amulet", "cloak", "boots", "gloves"):
        pool = [(v["cost"], k, v) for k, v in items["accessories"].items()
                if v["slot"] == slot]
        six = spread(pool, lambda k, v, s=slot: IC.variant_for(s, k, v["name"], khash(k)))
        cells = []
        for cost, k, v in six:
            stat = next((s for s in IC.STAT_ORDER if s in v), None)
            ctx = dict(variant=IC.variant_for(slot, k, v["name"], khash(k)),
                       orn=(cost - lo[slot]) / max(1.0, float(hi[slot] - lo[slot])),
                       gem=IC.STAT_GEM.get(stat, (0.72, 0.72, 0.76)))
            cells.append(dict(kind="acc", slot=slot, key=k, rec=v, ctx=ctx,
                              stat=stat, cost=cost, name=v["name"]))
        rows.append(dict(slot=slot, view="back" if slot == "cloak" else "front",
                         cells=cells))
    return rows


def hat_row(items):
    pool = [(v["cost"], k, v) for k, v in items["cosmetics"].items()
            if isinstance(v, dict) and v.get("kind") == "hat"]
    six = spread(pool, lambda k, v: IC.variant_for("hat", k, v["name"], khash(k)))
    costs = [c for c, _, _ in pool]
    lo, hi = min(costs), max(costs)
    cells = []
    for cost, k, v in six:
        ctx = dict(variant=IC.variant_for("hat", k, v["name"], khash(k)),
                   orn=(cost - lo) / max(1.0, float(hi - lo)),
                   gem=IC.STAT_GEM["ac"])
        cells.append(dict(kind="hat", slot="hat", key=k, rec=v, ctx=ctx,
                          stat="ac", cost=cost, name=v["name"]))
    return dict(slot="hat", view="front", cells=cells)


def weapon_row(items):
    """One per family, tiers spread so the ladder is visible too."""
    w = items["equipment"]["weapons"]
    byfam = {}
    for k, v in sorted(w.items()):
        byfam.setdefault(v["family"], []).append((v["tier"], k, v))
    cells, fams = [], sorted(byfam)
    for i, fam in enumerate(fams):
        cand = sorted(byfam[fam])
        tier_want = 1 + (i * 5) // max(1, len(fams))
        pick = min(cand, key=lambda q: (abs(q[0] - tier_want), q[1]))
        cells.append(dict(kind="weapon", slot="weapon", key=pick[1], rec=pick[2],
                          cost=0, name=pick[2]["name"]))
    # the sixth is the top of the ladder - the piece a viewer spends months of
    # points on, which must not come back looking second-hand.
    top = max(w.items(), key=lambda kv: (kv[1]["tier"], kv[0]))
    if top[0] not in [c["key"] for c in cells]:
        cells.append(dict(kind="weapon", slot="weapon", key=top[0], rec=top[1],
                          cost=0, name=top[1]["name"]))
    # FRONT, not side: a carried weapon hangs beside the right hand and the
    # body occludes it completely from 90 degrees. Pass 1 of this sheet showed
    # six heroes holding nothing at all, which is why the view is named here.
    return dict(slot="weapon", view="front", cells=cells[:N])


def armour_row(items):
    a = items["equipment"]["armour"]
    bycut = {}
    for k, v in sorted(a.items()):
        bycut.setdefault(v["cut"], []).append((v["tier"], k, v))
    cells = []
    for cut in sorted(bycut):
        cand = sorted(bycut[cut])
        for want in (1, 5):
            pick = min(cand, key=lambda q: (abs(q[0] - want), q[1]))
            if pick[1] not in [c["key"] for c in cells]:
                cells.append(dict(kind="armour", slot="armour", key=pick[1], rec=pick[2],
                                  cost=0, name=pick[2]["name"]))
    return dict(slot="armour", view="front", cells=cells[:N])


# ------------------------------------------------------------- build one cell
def acc_mats(key, ctx, tag):
    """D73's derivation, as D95 uses it: metal from the COST QUARTILE, gem
    from the STAT, and WEAR RIDING COST - cheap is handled, dear is kept."""
    q = min(3, int(ctx["orn"] * 4.0))
    tone = ((0.30, 0.25, 0.20), (0.22, 0.19, 0.17), (0.36, 0.28, 0.20),
            (0.24, 0.26, 0.29), (0.31, 0.22, 0.22), (0.21, 0.26, 0.23),
            (0.38, 0.34, 0.27), (0.26, 0.23, 0.30))
    h = khash(key)
    aw = max(0.08, min(0.92, 0.95 - 0.85 * ctx["orn"]))
    return SC.materials(max(1, min(5, 1 + q)), aw, gem=ctx["gem"],
                        cloth=tone[(h >> 8) % len(tone)], tag=tag,
                        metal=IC.METALS[q])


def render_detail(objs, focus, ortho, az, el, path, resx, resy):
    """A tight ortho on one body part. Clip range comes from the measured
    depth of the real geometry - a default clip_end renders an empty frame
    and reports success, which has already cost this lane three batches."""
    scene = bpy.context.scene
    mn, mx, pts = EG.mesh_bounds(objs)
    cam_d = bpy.data.cameras.new("dcam")
    cam_d.type = 'ORTHO'
    cam = bpy.data.objects.new("dcam", cam_d)
    bpy.context.collection.objects.link(cam)
    scene.camera = cam
    a, e = math.radians(az), math.radians(el)
    dirv = Vector((math.sin(a) * math.cos(e), -math.cos(a) * math.cos(e),
                   math.sin(e))).normalized()
    cam.location = Vector(focus) + dirv * 8.0
    cam.rotation_euler = dirv.to_track_quat('Z', 'Y').to_euler()
    bpy.context.view_layer.update()
    fwd = (cam.matrix_world.to_3x3() @ Vector((0, 0, -1))).normalized()
    depth = [(p - cam.location).dot(fwd) for p in pts]
    cam_d.ortho_scale = ortho
    cam_d.clip_start = max(0.01, min(depth) - 0.5)
    cam_d.clip_end = max(depth) + 2.0
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam, do_unlink=True)
    return dict(ortho=round(ortho, 3),
                clip=[round(cam_d.clip_start, 3), round(cam_d.clip_end, 3)])


def build_cell(repo, cell, resx, resy, full_path, det_path):
    """One body, one item, nothing else."""
    bodydir = os.path.join(repo, "assets", "characters", "kaykit_adv2")
    G.purge()
    EG.setup_scene(resx, resy, transparent=True)
    bg = next((n for n in bpy.context.scene.world.node_tree.nodes
               if n.type == 'BACKGROUND'), None)
    if bg:
        bg.inputs['Color'].default_value = (0.19, 0.20, 0.23, 1.0)
        bg.inputs['Strength'].default_value = 1.0
    tag = "_%s_%s" % (cell["slot"], cell["key"])
    arm, meshes = EG.import_knight(os.path.join(bodydir, BODY + ".glb"), cell["key"][:28])

    # the body's own hat/cape comes off where we replace it, or the test is a
    # lie: two capes stacked tell you nothing about either one.
    hidden = []
    sfx = list(SG.HIDE_FOR.get(cell["slot"], ()))
    # the Knight's own red cape hangs past the hands and fills a tight detail
    # shot with red cloth - pass 2 of this sheet "proved" all six rings were
    # one object when what it had photographed was the cape. It comes off for
    # every row that is not about a cape.
    if cell["slot"] in ("ring", "gloves", "amulet", "boots", "weapon"):
        sfx.append("_Cape")
    for ob in list(meshes):
        if sfx and any(ob.name.split('.')[0].endswith(x) for x in sfx):
            hidden.append(ob.name)
            bpy.data.objects.remove(ob, do_unlink=True)
            meshes.remove(ob)

    EG.tint_meshes(meshes, (1.0, 1.0, 1.0), "p" + tag, 0.18)
    EG.pose_at_post(arm)
    anchors = EG.rest_anchors(arm)
    bpy.context.view_layer.update()

    torso = [ob for ob in meshes if any(w in ob.name for w in ("_Body", "_Head"))]
    S = SG.Surf(SG.bvh_for(torso or meshes))
    body_trees = SG.bvh_for(meshes)
    bmn, bmx, _ = EG.mesh_bounds(meshes)

    parts = []
    if cell["kind"] == "weapon":
        tier = cell["rec"]["tier"]
        mats = SC.materials(tier, SC.wear_for(tier), tag=tag)
        wp = SC.weapon(cell["rec"]["name"], cell["rec"]["family"], tier,
                       cell["key"], key=cell["key"])
        hs = anchors["handslot.r"]
        hs0 = Vector((hs.x - 0.135, hs.y - 0.115, hs.z))
        wp.items = [([v + (hs0 - Vector((0, 0, 0))) for v in verts], f, m)
                    for verts, f, m in wp.items]
        wmn = min(v.z for verts, f, m in wp.items for v in verts)
        wmx = max(v.z for verts, f, m in wp.items for v in verts)
        wk = max(0.45, min(1.0, (anchors["upperarm.l"].z * 1.02) / max(0.2, wmx - wmn)))
        wp.items = [([Vector((hs0.x + (v.x - hs0.x) * wk, hs0.y + (v.y - hs0.y) * wk,
                              hs0.z + (v.z - hs0.z) * wk)) for v in verts], f, m)
                    for verts, f, m in wp.items]
        parts.append(wp)
    elif cell["kind"] == "armour":
        tier = cell["rec"]["tier"]
        mats = SC.materials(tier, SC.wear_for(tier), tag=tag)
        for q in SC.armour(cell["rec"]["name"], cell["rec"]["cut"], tier, S, anchors):
            parts.append(q)
    else:
        mats = SC.materials(2, 0.4, tag=tag)
        am = acc_mats(cell["key"], cell["ctx"], tag)
        if cell["kind"] == "hat":
            headobjs = [ob for ob in meshes if "_Head" in ob.name or "Hair" in ob.name]
            headbox = None
            if headobjs:
                hmn, hmx, _ = EG.mesh_bounds(headobjs)
                headbox = ((hmn.z + hmx.z) * 0.5,
                           max(hmx.x - hmn.x, hmx.y - hmn.y) * 0.5 + 0.012)
            for q in SC.acc_helm(cell["rec"]["name"], cell["key"],
                                 cell["rec"].get("cost", 100), cell["ctx"],
                                 anchors, S, headbox=headbox):
                q.mats = am
                parts.append(q)
        else:
            fL = anchors["foot.l"]
            fw = max(SG.ray_out(body_trees, Vector((fL.x, fL.y, 0.075)), (1, 0, 0)) or 0.055,
                     SG.ray_out(body_trees, Vector((fL.x, fL.y, 0.075)), (-1, 0, 0)) or 0.055)
            hL = anchors["hand.l"]
            hr = max(SG.ray_out(body_trees, hL, (0, 0, 1)) or 0.045,
                     SG.ray_out(body_trees, hL, (0, -1, 0)) or 0.045)
            boot_k = max(0.80, min(1.9, (fw + 0.016) / 0.058))
            glove_k = max(0.80, min(1.9, (hr + 0.012) / 0.044))
            for q in SC.ACC_BUILDERS[cell["slot"]](cell["rec"]["name"], cell["key"],
                                                   cell["cost"], cell["ctx"], anchors, S):
                q.mats = am
                if q.name.startswith("Acc_Boot"):
                    f = anchors["foot." + q.name[-1].lower()]
                    SG.scale_part(q, (f.x, f.y, 0.0), boot_k, boot_k, 1.0)
                elif q.name.startswith("Acc_Glove"):
                    h = anchors["hand." + q.name[-1].lower()]
                    SG.scale_part(q, h, glove_k, glove_k, glove_k)
                parts.append(q)

    objs, manifest = SG.merge_parts(parts, mats, anchors, arm, cell["key"][:28], posed=True)
    allobjs = meshes + objs
    EG.add_lights(Vector((0.0, 0.0, 1.20)), 1.65)
    fit_rows, faults = SG.fit_check(parts, body_trees, bmn.z)

    az = {"front": 0.0, "side": 90.0, "back": 180.0}[cell["view"]]
    cam = SG.render_fixed(allobjs, full_path, az, 0.0, resx, resy)
    if cam["outside"] > 0:
        faults.append("%s: %d vertices outside the fixed frame - CROPPED"
                      % (cell["key"], cam["outside"]))

    # STRIP 1 IS THE ITEM ON ITS OWN, framed to its own measured bounds.
    # Pass 2 aimed a tight camera at the worn piece and photographed the cape;
    # pass 3 aimed it at the ring and photographed the hero's hip - because a
    # ring is two centimetres across and sits 67% INSIDE the hand (see the fit
    # report), so no angle exists that shows it worn. Which of the two
    # questions this sheet asks - "are they different objects" and "can a
    # viewer see it" - needs separating anyway, and the body occludes only
    # the first. So the body is hidden for this shot and nothing can block it.
    _, _, daz, del_ = DETAIL[cell["slot"]]
    for ob in meshes:
        ob.hide_render = True
    if objs:
        pmn, pmx, _ = EG.mesh_bounds(objs)
        focus = (pmn + pmx) * 0.5
        ortho = max(0.06, max(pmx.x - pmn.x, pmx.y - pmn.y, pmx.z - pmn.z) * 1.35)
    else:
        focus = Vector((0.0, 0.0, (bmn.z + bmx.z) * 0.5))
        ortho = 0.5
    dcam = render_detail(objs or allobjs, focus, ortho, daz, del_, det_path, resx, resy)
    dcam["item_only"] = True
    for ob in meshes:
        ob.hide_render = False

    return dict(key=cell["key"], name=cell["name"], slot=cell["slot"],
                cost=cell.get("cost", 0), stat=cell.get("stat"),
                variant=cell.get("ctx", {}).get("variant"),
                tier=cell["rec"].get("tier"), cut=cell["rec"].get("cut"),
                family=cell["rec"].get("family"),
                pieces=len(objs), tris=sum(len(o.data.polygons) for o in objs),
                hidden=hidden, cam=cam, detail_cam=dcam,
                focus=[round(float(c), 3) for c in focus],
                fit=fit_rows, faults=faults)


# ----------------------------------------------------------- stream + numbers
def stream_of(a, div=STREAM_DIV):
    """Block-average down. This is the only honest way to ask 'can a viewer
    tell these apart' - it is what the encoder does to the hero."""
    h, w = a.shape[0] // div * div, a.shape[1] // div * div
    return a[:h, :w].reshape(h // div, div, w // div, div, a.shape[2]).mean(axis=(1, 3))


def upscale(b, div=STREAM_DIV):
    return np.repeat(np.repeat(b, div, axis=0), div, axis=1)


def pair_difference(small):
    """How different are two cells TO A VIEWER? Composite each over the same
    background, then count the fraction of the hero's own pixels that actually
    change by more than a visible amount. Percent of the hero, not of the
    frame - a frame is mostly empty and would flatter every row."""
    out = []
    for i in range(len(small)):
        for j in range(i + 1, len(small)):
            a, b = small[i], small[j]
            h = min(a.shape[0], b.shape[0])
            w = min(a.shape[1], b.shape[1])
            aa, bb = a[:h, :w], b[:h, :w]
            pa = aa[..., 0:3] * aa[..., 3:4]
            pb = bb[..., 0:3] * bb[..., 3:4]
            d = np.abs(pa - pb).max(axis=2)
            body = ((aa[..., 3] > 0.02) | (bb[..., 3] > 0.02))
            n = max(1, int(body.sum()))
            changed = int((d > 0.012).sum())
            out.append((round(100.0 * changed / n, 3), i, j,
                        round(float(d.max()) * 100.0, 2), changed))
    return out


SAME = 0.40      # below this a viewer is looking at the same picture


def classify(detail_pairs, stream_pairs, names):
    """Two failures wear the same face on a contact sheet and they are not
    the same fault, so they are separated here:

      DUPLICATE   - the DETAIL shots match too. The builder made one object
                    for two items. This is a D94 bug and someone must fix it.
      TOO SMALL   - the detail shots differ but the stream shots do not. The
                    items ARE different; a viewer at stream distance cannot
                    see it. That is a design answer for Mr. E, not a bug.
    """
    dup, small = [], []
    dmap = {(p[1], p[2]): p[0] for p in detail_pairs}
    for pct, i, j, peak, n in stream_pairs:
        dpct = dmap.get((i, j), 0.0)
        if dpct < SAME:
            dup.append((names[i], names[j], dpct, pct))
        elif pct < SAME:
            small.append((names[i], names[j], dpct, pct))
    total = len(stream_pairs)
    if dup:
        v = "DUPLICATES %d/%d" % (len(dup), total)
    elif len(small) == total:
        v = "TOO SMALL ON STREAM"
    elif small:
        v = "PARTLY TOO SMALL %d/%d" % (len(small), total)
    else:
        v = "TELLS APART"
    return v, dup, small


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--res", default="840x1200")
    ap.add_argument("--only", default="")
    args = ap.parse_args(argv)
    resx, resy = (int(x) for x in args.res.split("x"))
    repo = args.repo
    outdir = os.path.join(repo, "renders", "art", "d94")
    os.makedirs(outdir, exist_ok=True)
    items = SG.load_items(repo)

    rows = acc_rows(items) + [hat_row(items), weapon_row(items), armour_row(items)]
    if args.only:
        want = args.only.split(",")
        rows = [r for r in rows if r["slot"] in want]

    report = {"ok": True, "errors": [], "rows": [], "blank": {}, "verdict": []}
    checked, bad = [], []

    for row in rows:
        d = os.path.join(outdir, row["slot"])
        os.makedirs(d, exist_ok=True)
        rrec = dict(slot=row["slot"], view=row["view"], cells=[], faults=[])
        for cell in row["cells"]:
            cell["view"] = row["view"]
            fp = os.path.join(d, cell["key"] + ".png")
            dp = os.path.join(d, cell["key"] + "_detail.png")
            try:
                rec = build_cell(repo, cell, resx, resy, fp, dp)
                rrec["cells"].append(rec)
                rrec["faults"] += ["%s: %s" % (cell["key"], f) for f in rec["faults"]]
            except Exception:
                import traceback
                report["ok"] = False
                report["errors"].append("%s/%s: %s" % (row["slot"], cell["key"],
                                                       traceback.format_exc()[-900:]))
        report["rows"].append(rrec)

    # ------------------------------------------------ blank check, then sheets
    full_img, det_img = {}, {}
    for row, rrec in zip(rows, report["rows"]):
        for rec in rrec["cells"]:
            for suffix, store in ((".png", full_img), ("_detail.png", det_img)):
                p = os.path.join(outdir, row["slot"], rec["key"] + suffix)
                if not os.path.isfile(p):
                    bad.append([p, "missing"])
                    continue
                a = G.read_png(p)
                n = int((a[..., 3] > 0.02).sum())
                checked.append([os.path.relpath(p, repo), n])
                if n < 2000:
                    bad.append([p, "blank or near-blank: %d opaque px" % n])
                store[(row["slot"], rec["key"])] = G.box2(a)
    report["blank"] = dict(files=len(checked), failures=bad)
    if bad:
        report["ok"] = False

    try:
        lab = 46
        smalls_by_row = {}
        for row, rrec in zip(rows, report["rows"]):
            fulls = [full_img.get((row["slot"], r["key"])) for r in rrec["cells"]]
            dets = [det_img.get((row["slot"], r["key"])) for r in rrec["cells"]]
            keep = [i for i, im in enumerate(fulls) if im is not None]
            if not keep:
                continue
            fulls = [fulls[i] for i in keep]
            dets = [dets[i] for i in keep]
            names = [rrec["cells"][i]["name"] for i in keep]
            ch, cw = fulls[0].shape[0], fulls[0].shape[1]

            smalls = [stream_of(im) for im in fulls]
            smalls_by_row[row["slot"]] = smalls
            diffs = sorted(pair_difference(smalls))
            if all(d is not None for d in dets):
                ddiffs = pair_difference(dets)
            else:   # no detail shot - never call a pair a duplicate on no evidence
                ddiffs = [(100.0, i, j, 100.0, 0) for i in range(len(fulls))
                          for j in range(i + 1, len(fulls))]
            v, dup, small = classify(ddiffs, diffs, names)
            worst = diffs[0] if diffs else (0.0, 0, 0, 0.0, 0)
            best = diffs[-1] if diffs else (0.0, 0, 0, 0.0, 0)
            rrec["verdict"] = v
            rrec["stream_difference"] = dict(
                metric="percent of the hero's own stream pixels that change",
                pairs=len(diffs),
                worst=worst[0], worst_pair=[names[worst[1]], names[worst[2]]],
                worst_peak_pct=worst[3],
                best=best[0], best_pair=[names[best[1]], names[best[2]]],
                median=sorted(q[0] for q in diffs)[len(diffs) // 2] if diffs else 0.0,
                duplicate_pairs=[dict(a=a, b=b, detail=da, stream=sa) for a, b, da, sa in dup],
                too_small_pairs=[dict(a=a, b=b, detail=da, stream=sa) for a, b, da, sa in small])
            report["verdict"].append(
                "%-7s %-20s worst %5.2f%% median %5.2f%% of hero px   %s"
                % (row["slot"], v, worst[0],
                   sorted(q[0] for q in diffs)[len(diffs) // 2] if diffs else 0.0,
                   ("same object: " + "; ".join("%s = %s" % (a, b) for a, b, _, _ in dup))
                   if dup else ""))

            sheet = np.zeros((lab * 2 + ch * 3, cw * len(fulls), 4), dtype=np.float32)
            sheet[..., 0:3] = np.array((0.055, 0.060, 0.075))
            sheet[..., 3] = 1.0

            def paste(im, x, y):
                h, w = im.shape[0], im.shape[1]
                al = im[..., 3:4]
                dst = sheet[y:y + h, x:x + w, 0:3]
                sheet[y:y + h, x:x + w, 0:3] = im[..., 0:3] * al + dst * (1.0 - al)

            for i in range(len(fulls)):
                x = i * cw
                if dets[i] is not None:
                    paste(dets[i], x, lab)
                paste(fulls[i], x, lab + ch)
                paste(upscale(smalls[i]), x, lab * 2 + ch * 2)
                r = rrec["cells"][keep[i]]
                sub = (("%d g  %s" % (r["cost"], r["stat"] or "-")) if r["cost"]
                       else ("tier %s %s" % (r["tier"], r["family"] or r["cut"] or "")))
                G.draw_text(sheet, r["name"][:30], x + 8, lab + 6, 2, (0.92, 0.88, 0.74))
                G.draw_text(sheet, sub, x + 8, lab + 24, 1, (0.72, 0.80, 0.88))
            G.draw_text(sheet, "%s - SIX DIFFERENT, ONE BODY, ONE LIGHT, NOTHING ELSE WORN"
                        % row["slot"].upper(), 8, 6, 2, (0.95, 0.90, 0.72))
            note = ("SAME OBJECT: " + "; ".join("%s = %s" % (a, b) for a, b, _, _ in dup)) \
                if dup else ("worst pair %.2f%% of hero pixels change" % worst[0])
            G.draw_text(sheet, "%s   -   %s" % (v, note[:150]), 8, 26, 1,
                        (0.95, 0.55, 0.45) if dup else
                        (0.95, 0.82, 0.45) if "SMALL" in v else (0.70, 0.88, 0.72))
            G.draw_text(sheet, "1 THE ITEM ALONE, framed to its own bounds - "
                        "are they six different objects?",
                        8, lab + ch - 20, 1, (0.80, 0.78, 0.70))
            G.draw_text(sheet, "2 RENDER - where it sits, and does it fit",
                        8, lab + ch * 2 - 20, 1, (0.80, 0.78, 0.70))
            G.draw_text(sheet, "3 STREAM SIZE (/%d) - CAN A VIEWER TELL? this is the bar"
                        % STREAM_DIV, 8, lab * 2 + ch * 3 - 20, 1, (0.86, 0.80, 0.60))
            G.write_png(os.path.join(outdir, "_row_%s.png" % row["slot"]), sheet)

        # the overview: stream strips only, every row, nothing flattered
        keys = [r["slot"] for r in rows if r["slot"] in smalls_by_row]
        if keys:
            sh, sw = smalls_by_row[keys[0]][0].shape[0], smalls_by_row[keys[0]][0].shape[1]
            labo = 26
            over = np.zeros((len(keys) * (sh + labo), N * sw, 4), dtype=np.float32)
            over[..., 0:3] = np.array((0.045, 0.050, 0.062))
            over[..., 3] = 1.0
            for ri, slot in enumerate(keys):
                y = ri * (sh + labo)
                rrec = next(r for r in report["rows"] if r["slot"] == slot)
                for i, sm in enumerate(smalls_by_row[slot][:N]):
                    al = sm[..., 3:4]
                    dst = over[y + labo:y + labo + sh, i * sw:(i + 1) * sw, 0:3]
                    over[y + labo:y + labo + sh, i * sw:(i + 1) * sw, 0:3] = \
                        sm[..., 0:3] * al + dst * (1.0 - al)
                G.draw_text(over, "%s  %s  worst %.2f%%"
                            % (slot.upper(), rrec.get("verdict", "?"),
                               rrec.get("stream_difference", {}).get("worst", 0.0)),
                            6, y + 6, 1, (0.92, 0.88, 0.74))
            G.write_png(os.path.join(outdir, "_overview.png"), over)
    except Exception:
        import traceback
        report["ok"] = False
        report["errors"].append("sheets: %s" % traceback.format_exc()[-900:])

    report["fit_faults"] = sum((r["faults"] for r in report["rows"]), [])
    with open(os.path.join(outdir, "_report.json"), "w") as f:
        json.dump(report, f, indent=1)
    print("D94PROOF " + json.dumps(dict(
        ok=report["ok"], rows=len(report["rows"]),
        errors=report["errors"][:2],
        blank=report["blank"].get("failures", [])[:5],
        verdict=report["verdict"],
        faults=report["fit_faults"][:30])))


if __name__ == "__main__":
    main()
