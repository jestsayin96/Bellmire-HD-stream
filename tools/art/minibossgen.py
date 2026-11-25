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

THIS FILE ALSO MEASURES WHETHER THE CREATURE FITS THE DUNGEON, AND SINCE
2026-11-20 02:4x CT THAT IS TWO TERMS, NOT ONE.

  SPAN    against the clear span of a three-cell corridor (D91 stage 3).
  HEIGHT  against the underside of floorgen.gd's shadows-only LID - the box
          that keeps the overworld sun off the floor. NOBODY HAD EVER MEASURED
          IT. A gate with no height term gave a 6.60 m body a GREEN verdict
          while its head stood 0.10 m through a lid at 6.50 m, which is a thing
          a viewer can see and no number here could.

Both numbers are now READ OUT OF scripts/floorgen.gd every run by
tools/art/floorgeom.py - they are not literals in this file any more. The
supervisor is moving the lid (7.0 -> 10.0 at 02:12 CT); a gate carrying a copy
of a number under review is the next stale comment. If floorgen.gd cannot be
read the verdict is WITHHELD and the report goes RED: a gate that cannot see
the lid must not certify a creature as under it.

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

# The cell, the wall inset, the corridor width and the lid all live in
# scripts/floorgen.gd and are read from it per run. NO COPIES HERE ON PURPOSE -
# see floorgeom's own header for why the old `CORRIDOR_CLEAR = 3 * 4.0 - 2 *
# 0.5` literal was a defect even while it held the right number.
import floorgeom as FG       # noqa: E402



def _fit(report, key, geom, span, height):
    """The two-term verdict, and the report's errors are the gate's teeth.

    ROOM-LOCKED is NOT an error - it is a construction fact the game build
    gates a spawn on. THROUGH-LID IS an error: a head inside the sun-blocker
    is the fault that shipped green on 20 Nov, and a WITHHELD verdict is an
    error too, because an eye that cannot see must not sign off.
    """
    v, errs = FG.verdict(geom, span, height)
    for e in errs:
        if e not in report["errors"]:
            report["errors"].append(e)
    if errs:
        report["ok"] = False
    if v["lid"] == "THROUGH-LID":
        report["ok"] = False
        report["errors"].append(
            "%s: %.2f m stands %.2f m THROUGH the lid underside at %.2f m (%s)"
            % (key, height, -v["lid_clear_m"], v["lid_underside_m"],
               v["read_from"].get("lid_y_m", "?")))
    return v

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
    # *** THE CUE A/B SWITCH (MB_CUEOFF=1). ART, 25 Nov 04:5x CT. ***
    # WHY. `seen: 1.0` in the fit register answers "is the CREATURE visible
    # past the hero" and says NOTHING about whether the thing the fight is
    # ABOUT can be seen. The collier is shut on a fire and its four vents are
    # all on the -Y arc by construction, so from ONE SIDE a party sees a mound
    # of earth and no fire at all - and every number in the register was green.
    # *** THIS SENTENCE SAID "FROM BEHIND" UNTIL 25 Nov 05:4x CT AND THAT WAS
    # *** AN UNMEASURED GUESS, COPIED OUT OF THE BODY'S OWN FAULT LIST. ***
    # The census that this switch exists to serve contradicted it within the
    # hour: collier back 2430 px (the four pale plugs read fine from behind),
    # collier SIDE 41. The wrong word was then quoted into a plan row, which
    # sent a lane to fix the wrong face of the body. Corrected at the source so
    # it stops travelling. See docs/art/CUE_READ.md, PASS 7.
    # That is the pass-11 fault of 17 Nov in a new coat: an instrument that
    # cannot see is not a pass.
    # THE TEST IS THE VIEWER'S QUESTION, NOT A MEASUREMENT OF THE OBJECT.
    # `mask_of` renders a group ALONE and answers how BIG the cue is; it reads
    # a healthy number for a vent buried behind a shovel. So this switch does
    # the one thing that cannot lie: it swaps the glow material for the BODY
    # material, leaving every vertex exactly where it was, and the census
    # renders both arms THROUGH THE SAME CAMERA and counts the pixels that
    # MOVED. Occlusion, depth and the view transform are then the renderer's
    # problem and not mine.
    # Default OFF. With the variable unset this function is byte-for-byte what
    # it was, which is why it is a swap here and not an edit to mat_glow.
    # *** AND IT TAKES A SLOT, BECAUSE "1" WAS THE WRONG QUESTION. ***
    # First run of this switch red-flagged pledgeman, blower and stopper. I
    # went and read their CANON before believing it: pledgeman's count is
    # "THREE BRIGHT LASHINGS ... the only pale on the whole body", blower's is
    # a bag "pale and ribbed", stopper's is "five pale uprights". NONE of those
    # is emissive. They are in the `bone` slot on purpose - the Dyer's pass-3
    # lesson is that a near-white emissive is a hole and not a fire, so this
    # file deliberately carries most COUNTABLE cues as pale geometry and keeps
    # glow for things that are actually alight. An instrument that only swaps
    # `glow` therefore reads ZERO on a correct body and calls it red.
    # So the slot is named, and `both` is what a cue census must use.
    # "0" MUST MEAN OFF. The first cut of this read `== "1"`, so arm A of the
    # census was launched with MB_CUEOFF=0; the slot rewrite turned that same
    # string into a KeyError. An off-switch whose OFF value crashes is worse
    # than no switch, so both "" and "0" are off and an unknown value says so.
    _cue = os.environ.get("MB_CUEOFF", "").strip().lower()
    if _cue in ("", "0", "off", "none"):
        _cue = ""
    if _cue:
        assert _cue in ("1", "glow", "bone", "both"), \
            "MB_CUEOFF must be one of 1/glow/bone/both/0, got %r" % _cue
        _slots = {"1": ("glow",), "glow": ("glow",), "bone": ("bone",),
                  "both": ("glow", "bone")}[_cue]
        mats = dict(mats)
        for _s in _slots:
            mats[_s] = mats['body']
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
            # AND THE BORDER, 20 Nov. A blank check cannot see a CLIPPED frame:
            # System 1's first ladder shot had the artifact glow cut off by the
            # edge and every opaque-pixel count on it was healthy. The camera
            # here frames off measured bounds so this should never fire - which
            # is exactly why it was worth two lines to find out, the run that
            # re-shaped the Gaoler's chain being the first to move a silhouette
            # outward since the gate was written.
            edge = int(((a[0:2, :, 3] > 0.02).sum() + (a[-2:, :, 3] > 0.02).sum()
                        + (a[:, 0:2, 3] > 0.02).sum() + (a[:, -2:, 3] > 0.02).sum()))
            if edge:
                bad.append((p, "frame clip: %d opaque px on the border" % edge))

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
    geom = FG.read(args.repo)
    # THE RED ARM. `MBG_RED_LID=<metres>` forces the lid underside down so the
    # tallest bodies on disk must come out THROUGH-LID. It proves the PLUMBING,
    # not just the arithmetic: that report["ok"] actually flips, that the error
    # names the creature and the metres, and that the printed line lists it.
    # A gate nobody has made fail is a gate nobody has tested, and the real
    # minibosses all clear the lid by metres, so without this arm the height
    # term here would be a green number that has never moved.
    red = os.environ.get("MBG_RED_LID", "").strip()
    if red:
        geom = dict(geom, lid_underside_m=float(red),
                    at=dict(geom["at"], lid_y_m="MBG_RED_LID=%s (red arm)" % red))
    report = {"ok": True, "floor_geom": geom, "red_arm": red or None,
              "minibosses": {}, "errors": []}
    # PROVENANCE, 07:5x CT 20 Nov. `geom` now carries the tree it was parsed
    # from and a term-by-term comparison against origin/main's floorgen.gd
    # (floorgeom._provenance). A report quoting a lid out of a tree that no
    # longer ships is the fault the team lead found in _leech_span.json, so it
    # is FLAGGED here in its own field - `ok` is left to the art faults, and a
    # reader who wants the number has to see which tree it came from.
    _p = geom.get("provenance") or {}
    report["floorgeom_stale"] = bool(_p.get("drift")) or not _p.get("verified")
    report["floorgeom_stamp"] = FG.stamp(geom)
    if report["floorgeom_stale"]:
        report["errors"].append("floorgeom provenance: " + FG.stamp(geom))
    # The reader's own complaints are THIS report's errors. An unreadable
    # floorgen.gd is a red gate, not a quiet fallback to 11.0 and 6.50.
    for e in geom["errors"]:
        report["ok"] = False
        report["errors"].append(e)
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

    # AND RE-VERDICT EVERY CARRIED RECORD AGAINST TODAY'S floorgen.gd. The lid
    # is moving, so a verdict written on a previous run is a verdict against a
    # previous dungeon. These are recorded measurements of real renders, so the
    # height term costs nothing to apply: no re-render, no re-measure, and the
    # whole set answers the new question in one pass.
    for k, rec in report["minibosses"].items():
        sz = rec.get("size") or []
        sp = rec.get("footprint_span")
        if len(sz) == 3 and sp is not None:
            rec["height_m"] = round(float(sz[2]), 3)
            rec.update(_fit(report, k, geom, float(sp), float(sz[2])))
        else:
            report["ok"] = False
            report["errors"].append(
                "%s: carried record has no size/footprint_span - cannot be "
                "verdicted against the lid" % k)

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
                    height_m=round(h, 3),
                    **_fit(report, key, geom, span, h),
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

    # A RED RUN MUST NEVER OVERWRITE THE GREEN REGISTER. It reads the real
    # records and writes its evidence beside them, so the shipped report is
    # always the green pass's and the red proof is still on disk to be read.
    if red:
        out = out.replace("_report.json", "_report_red.json")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w") as f:
        json.dump(report, f, indent=1)
    print("MINIBOSSGEN_REPORT " + json.dumps({
        "ok": report["ok"], "n": len(report["minibosses"]),
        "errors": report["errors"][:3],
        "blank": report.get("blank_check", {}).get("failures", [])[:5],
        "corridor_clear_m": geom["corridor_clear_m"],
        "lid_underside_m": geom["lid_underside_m"],
        "lid_read_at": geom["at"].get("lid_y_m"),
        "through_lid": sorted(k for k, v in report["minibosses"].items()
                              if v.get("lid") == "THROUGH-LID"),
        "room_locked": sorted(k for k, v in report["minibosses"].items()
                              if v.get("corridor") == "ROOM-LOCKED"),
        "tallest": sorted(((v.get("height_m"), k)
                           for k, v in report["minibosses"].items()
                           if v.get("height_m") is not None), reverse=True)[:3],
        "spans": {k: (v["footprint_span"], v.get("corridor"), v.get("lid"),
                      v["parts"], v["faces"])
                  for k, v in report["minibosses"].items()}}))


if __name__ == "__main__":
    main()
