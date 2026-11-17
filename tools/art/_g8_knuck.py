# D94 GLOVES, PASS 8 PROBE - DOES THE KNUCKLE READ ON THE BODY?
#
# The team lead's 03:58 row, out of MY OWN honest fit list: the hand is hidden
# behind the cuff on Quarreller's, Forgemaster's and Raidbreaker's from the
# front AND the side, so the knuckle treatments - spikes, studs, dome - live
# only in strip 1. Knuckle treatment is one of the four dials Mr. E's ruling
# names BY NAME, so a dial that cannot be seen is a dial we cannot spend later.
#
# "DOES IT READ" IS A QUESTION ABOUT PIXELS, SO IT IS MEASURED IN PIXELS.
# For each of the six cells of the ticked gloves row, and for each view, the
# cell is rendered TWICE at the proof sheet's own framing - once as it is, once
# with showcase.DROP = {'knuck'} - and the two images are differenced. The
# metric is the proof sheet's own: percent of the HERO'S OWN pixels that change
# by more than a visible amount, both at render size and at STREAM size
# (block-averaged by STREAM_DIV, which is Mr. E's bar). So the knuckle's number
# can be read straight against the row's worst-pair number.
#
# IT GOES RED ON EMPTY, which is the rule that saved System 1:
#   - a cell whose two builds have the SAME vertex count built no knuckle
#     geometry at all: that is reported as HAS_NO_KNUCKLE, never as 0.00% read
#   - if NO cell builds knuckle geometry the probe fails outright, because that
#     means the switch or the dial is broken, not that the art is bad
#   - every PNG is reopened and its opaque pixel count asserted
import os, sys, json, traceback
import bpy
import numpy as np

REPO = r"C:\hd adventure\bellmire-art"
sys.path.append(os.path.join(REPO, "tools", "art"))
import lordgen as G                # noqa: E402
import showcasegen as SG           # noqa: E402
import showcase as SC              # noqa: E402
import d94proof as P               # noqa: E402
import icons as IC                 # noqa: E402

RES = (840, 1200)
VIEWS = ("front", "side")
TMP = os.path.join(REPO, "renders", "art", "_g8tmp")
os.makedirs(TMP, exist_ok=True)


def glove_verts():
    n = 0
    for o in bpy.context.scene.objects:
        if o.type == 'MESH' and "Glove" in o.name:
            n += len(o.data.vertices)
    return n


def read(path):
    a = G.read_png(path)
    n = int((a[..., 3] > 0.02).sum())
    return a, n


def delta(a, b, div=None):
    """Proof-sheet metric: percent of the hero's own pixels that change.

    AND THE SILHOUETTE, SEPARATELY, because they are two different claims.
    `pct` counts any visible change, shading included; `sil_pct` counts only
    pixels the knuckle ADDS TO OR TAKES FROM THE HERO'S OUTLINE. At stream
    distance the outline is most of what a viewer gets, so a knuckle that
    moves `pct` but not `sil_pct` is decoration on the inside of the glove,
    not a shape anybody can name. Reported apart so neither can flatter.
    """
    if div:
        a, b = P.stream_of(a, div), P.stream_of(b, div)
    h = min(a.shape[0], b.shape[0]); w = min(a.shape[1], b.shape[1])
    aa, bb = a[:h, :w], b[:h, :w]
    pa = aa[..., 0:3] * aa[..., 3:4]
    pb = bb[..., 0:3] * bb[..., 3:4]
    d = np.abs(pa - pb).max(axis=2)
    body = ((aa[..., 3] > 0.02) | (bb[..., 3] > 0.02))
    nb = max(1, int(body.sum()))
    changed = int((d > 0.012).sum())
    ma, mb = (aa[..., 3] > 0.35), (bb[..., 3] > 0.35)
    sil = int((ma ^ mb).sum())
    return dict(pct=round(100.0 * changed / nb, 3), changed=changed,
                sil_pct=round(100.0 * sil / nb, 3), sil_px=sil,
                hero_px=nb, peak=round(float(d.max()) * 100.0, 2))


def main():
    out = {"ok": True, "errors": [], "res": list(RES), "views": list(VIEWS),
           "metric": "percent of the hero's own pixels the knuckle changes",
           "stream_div": P.STREAM_DIV, "cells": []}
    items = SG.load_items(REPO)
    row = [r for r in P.acc_rows(items) if r["slot"] == "gloves"][0]
    built_any = False
    checked = []
    sheet_src = []
    for cell in row["cells"]:
        F = IC.glove_form(cell["ctx"]["variant"], cell["ctx"]["orn"],
                          SC.sig(cell["key"], cell["name"]))
        rec = {"key": cell["key"], "name": cell["name"], "cost": cell["cost"],
               "variant": cell["ctx"]["variant"],
               "orn": round(cell["ctx"]["orn"], 3),
               "dials": {k: (round(v, 4) if isinstance(v, float) else v)
                         for k, v in F.items()},
               "views": {}}
        for view in VIEWS:
            c = dict(cell); c["view"] = view
            paths = {}
            # THE CONTROL IS NOT OPTIONAL. A silhouette check that reads
            # 0.000% needs to prove it COULD have read more than zero: if the
            # whole glove adds nothing to this view's outline, then the view
            # cannot test silhouette and a zero there is the instrument's
            # blindness, not the knuckle's fault. "none" drops the whole piece.
            for which, drop in (("on", set()), ("off", {"knuck"}),
                                ("none", {"glove"})):
                SC.DROP = set(drop)
                fp = os.path.join(TMP, "%s_%s_%s.png" % (cell["key"], view, which))
                dp = os.path.join(TMP, "%s_%s_%s_det.png" % (cell["key"], view, which))
                r = P.build_cell(REPO, c, RES[0], RES[1], fp, dp)
                paths[which] = (fp, glove_verts(), r)
                SC.DROP = set()
            a, na = read(paths["on"][0])
            b, nb = read(paths["off"][0])
            c0, nc = read(paths["none"][0])
            checked.append([os.path.basename(paths["on"][0]), na])
            checked.append([os.path.basename(paths["off"][0]), nb])
            if na < 2000 or nb < 2000:
                out["ok"] = False
                out["errors"].append("blank render: %s %d / %s %d"
                                     % (paths["on"][0], na, paths["off"][0], nb))
            kv = paths["on"][1] - paths["off"][1]
            if kv > 0:
                built_any = True
            rec["views"][view] = {
                "knuckle_verts": kv,
                "has_knuckle": kv > 0,
                "render": delta(a, b),
                "stream": delta(a, b, P.STREAM_DIV),
                "glove_verts_on": paths["on"][1],
                "glove_verts_off": paths["off"][1],
                "glove_verts_none": paths["none"][1],
                "control_whole_glove": delta(a, c0, P.STREAM_DIV),
            }
            v = rec["views"][view]
            print("G8 %-18s %-5s kind %-6s verts %4d  stream %6.3f%%  "
                  "SIL %6.3f%%  | CONTROL whole glove %6.3f%% SIL %6.3f%%"
                  % (cell["key"], view, rec["dials"].get("knuck_kind"), kv,
                     v["stream"]["pct"], v["stream"]["sil_pct"],
                     v["control_whole_glove"]["pct"],
                     v["control_whole_glove"]["sil_pct"]))
            sheet_src.append((cell["name"], view, rec["dials"].get("knuck_kind"),
                              kv, a, b, v))
            sys.stdout.flush()
        out["cells"].append(rec)
    out["blank"] = {"files": len(checked), "failures": []}
    out["any_knuckle_geometry"] = built_any
    if not built_any:
        out["ok"] = False
        out["errors"].append("NO cell built knuckle geometry - the instrument is "
                             "measuring nothing; this is a harness fault, not an art verdict")
    # the honest summary: which cells do not read at stream size
    dead = []
    for c in out["cells"]:
        for v, d in c["views"].items():
            if d["has_knuckle"] and d["stream"]["pct"] < 0.05:
                dead.append("%s/%s %.3f%%" % (c["key"], v, d["stream"]["pct"]))
    out["does_not_read_at_stream"] = dead
    blind = []
    for c in out["cells"]:
        for vw, d in c["views"].items():
            if d["control_whole_glove"]["sil_pct"] < 0.02:
                blind.append("%s/%s control sil %.3f%%"
                             % (c["key"], vw, d["control_whole_glove"]["sil_pct"]))
    out["views_blind_to_silhouette"] = blind
    if len(blind) == len(VIEWS) * len(out["cells"]):
        out["ok"] = False
        out["errors"].append("EVERY view is blind to silhouette - the sil_pct "
                             "column is measuring nothing anywhere")
    # THE PICTURE. A number is evidence; the sheet is the judge. Each cell
    # gets a crop round the glove hand with the knuckle ON above the same crop
    # with it OFF, so the question "can you see the difference" is answered by
    # looking and not by me.
    try:
        rows = []
        for nm, view, kind, kv, a, b, v in sheet_src:
            m = (a[..., 3] > 0.35)
            ys, xs = np.nonzero(m)
            # frame on the HAND, not the hero: the lower outboard quarter
            if len(xs) == 0:
                continue
            x0, x1 = int(xs.min()), int(xs.max())
            y0, y1 = int(ys.min()), int(ys.max())
            hh = y1 - y0
            cy0 = y0 + int(hh * 0.42)
            cy1 = min(a.shape[0], cy0 + int(hh * 0.30))
            cx0, cx1 = max(0, x0 - 6), min(a.shape[1], x1 + 6)
            rows.append((nm, view, kind, kv, v,
                         a[cy0:cy1, cx0:cx1], b[cy0:cy1, cx0:cx1]))
        if rows:
            ch = max(r[5].shape[0] for r in rows)
            cw = max(r[5].shape[1] for r in rows)
            lab = 40
            sheet = np.zeros((lab + (ch * 2 + lab) * 1, cw * len(rows), 4),
                             dtype=np.float32)
            sheet = np.zeros((lab + ch * 2 + 22, cw * len(rows), 4), dtype=np.float32)
            sheet[..., 0:3] = np.array((0.055, 0.060, 0.075))
            sheet[..., 3] = 1.0

            def paste(im, x, y):
                h, w = im.shape[0], im.shape[1]
                al = im[..., 3:4]
                dst = sheet[y:y + h, x:x + w, 0:3]
                sheet[y:y + h, x:x + w, 0:3] = im[..., 0:3] * al + dst * (1.0 - al)

            for i, (nm, view, kind, kv, v, ia, ib) in enumerate(rows):
                x = i * cw
                paste(ia, x, lab)
                paste(ib, x, lab + ch)
                G.draw_text(sheet, ("%s %s" % (nm[:17], view))[:26], x + 6, 6, 1,
                            (0.92, 0.88, 0.74))
                G.draw_text(sheet, "%s  %d v  %.2f%% sil %.2f%%"
                            % (kind, kv, v["stream"]["pct"], v["stream"]["sil_pct"]),
                            x + 6, 22, 1,
                            (0.95, 0.55, 0.45) if kv == 0 else (0.70, 0.88, 0.72))
            G.draw_text(sheet, "KNUCKLE ON (top)  /  KNUCKLE DROPPED (bottom) - "
                        "same cell, same frame, same light. CAN YOU SEE IT?",
                        8, lab + ch * 2 + 4, 1, (0.86, 0.80, 0.60))
            G.write_png(os.path.join(REPO, "renders", "art", "_g8_knuck_sheet.png"),
                        sheet)
    except Exception:
        out["errors"].append("sheet: " + traceback.format_exc()[-500:])
        out["ok"] = False

    p = os.path.join(REPO, "renders", "art", "_g8_knuck.json")
    with open(p, "w") as f:
        json.dump(out, f, indent=1)
    print("G8KNUCK " + json.dumps(dict(ok=out["ok"], errors=out["errors"][:3],
                                       dead=dead, any=built_any,
                                       blind=out["views_blind_to_silhouette"])))


try:
    main()
except Exception:
    print("G8KNUCK_CRASH " + traceback.format_exc()[-1500:])
