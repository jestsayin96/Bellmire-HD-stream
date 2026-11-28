"""_wf_basis_audit - THE CROSSBOW BASIS DIVERGENCE, AUDITED ON A BODY.

  blender -b -noaudio -P tools/art/_wf_basis_audit.py -- --repo <R> --out <W5>

WHY THIS FILE EXISTS. artifactfit's `selftest_basis` recorded
`weaponfit_rule_divergence` and left it OPEN: weaponfit's CROSSBOW basis is
`R_godot . C^-1` while its STAFF basis is `C . R_godot . C^-1`, and the six
families it never calibrated get `Matrix.Identity` - which is what
`C . R . C^-1` reduces to at held_rot zero. So SEVEN of eight families are
carried on one rule and the crossbow alone on the other. They cannot both be
right, and 90 degrees separates them.

*** MY FIRST ANSWER WAS WRONG AND THE PICTURE CAUGHT IT. IT IS RECORDED HERE
*** RATHER THAN QUIETLY DELETED, BECAUSE THE WRONG TURN IS THE USEFUL PART. ***
Pass 1 of this file tested `R . C^-1` as the rule, on artifactfit's reasoning
that the slot side needs no conversion. Three arguments agreed with it - the
posed bone, weaponfit's own crossbow table, and gear.gd's S20 prose map - and
ALL THREE WERE ARGUMENTS, NOT PICTURES. Rendered on the body and set beside the
engine's own capture (`renders/cycles/s16/s16_front.png`, the game build's, in
Godot), `R . C^-1` points the sword STRAIGHT DOWN THE CAMERA - a 40-pixel stub
at the fist. The engine shows a full blade across the hero's front, which is
what `Matrix.Identity` renders. The engine is the ground truth and it agrees
with the seven, not with my derivation. SO THE RULE UNDER TEST HERE IS THE
CONJUGATION `C . R_godot . C^-1`, and the open question narrows to ONE family:
is weaponfit's hand-calibrated CROSSBOW table what the engine ships, or is it
90 degrees out?

THIS ALSO STRIKES A CONCLUSION IN MY OWN SHIPPED artifactfit DOCSTRING, which
says "WHICH MAKES weaponfit's CROSSBOW RIGHT AND ITS STAFF BASIS THE ODD ONE".
It is the other way round, and the register the team lead read carried my
wording, not the plan's. The plan's phrasing was the correct one.

WHAT THIS FILE MEASURES, for each family, at `common`:
  (a) the mesh's long axis, and the angle between it and the axis of the
      relative rotation between weaponfit's basis and the rule. Parallel means
      a ROLL about the weapon's own length, which is invisible on anything
      near-axisymmetric - that is the get-out the staff earned by measurement.
  (b) THE VIEWER'S QUESTION, asked the way pass 11 taught this lane: render
      body-only, body+weapon under weaponfit's basis, and body+weapon under the
      rule, THROUGH ONE CAMERA, and count the pixels that MOVED. The contact
      sheet is the evidence and it is looked at; a number that disagrees with
      the picture is the suspect, as one did above.

RED ON EMPTY: zero verts, zero families, zero views, zero added pixels under
EITHER basis all fail loudly. A moved-pixel count over an empty pair is not a
pass. Blank and border-alpha are asserted on every render, because a clipped
weapon is not a blank one.
"""
import os
import sys
import json
import math
import argparse

import bpy
import numpy as np
from mathutils import Vector, Matrix

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lordgen as G            # noqa: E402
import minibossfit as MF       # noqa: E402
import weaponfit as WF         # noqa: E402

C4 = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0))).to_4x4()   # Godot -> Blender
ORDER = "YXZ"                                              # Godot Node3D
TIER = "common"
DIFF_EPS = 0.02
BORDER = 2


def godot_rot(deg, order=ORDER):
    M = Matrix.Identity(4)
    axes = {"X": Matrix.Rotation(math.radians(float(deg[0])), 4, 'X'),
            "Y": Matrix.Rotation(math.radians(float(deg[1])), 4, 'Y'),
            "Z": Matrix.Rotation(math.radians(float(deg[2])), 4, 'Z')}
    for ax in order:
        M = M @ axes[ax]
    return M


def opaque(img):
    return int((img[:, :, 3] > 0.02).sum())


def border_alpha(img):
    a = img[:, :, 3]
    return float(max(a[:BORDER, :].max(), a[-BORDER:, :].max(),
                     a[:, :BORDER].max(), a[:, -BORDER:].max()))


def moved_px(a, b):
    d = np.abs(a - b).max(axis=2)
    return int((d > DIFF_EPS).sum())


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--fams", default=",".join(WF.FAMS))
    a = ap.parse_args(argv)
    fams = [f for f in a.fams.split(",") if f]
    if not fams:
        raise SystemExit("AUDIT FAIL - zero families. An audit over nothing is not a pass.")

    outdir = os.path.join(a.out, "renders", "art", "_wf_basis")
    tmp = os.path.join(outdir, "_tmp")
    os.makedirs(tmp, exist_ok=True)

    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)

    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next((o for o in roots if o.type == 'ARMATURE'), None)
    assert rig is not None, "no armature in the hero glb"
    assert hinfo["posed"], "hero is in REST pose - the idle action did not take"
    bpy.context.view_layer.update()

    gear_path = os.path.join(a.repo, "scripts", "gear.gd")
    if not os.path.exists(gear_path):
        raise SystemExit("AUDIT FAIL - no gear.gd at %s" % gear_path)
    OVR = WF.gear_overrides(gear_path)
    GRIP, GRIP_VEC = WF.grip_shift(gear_path)

    pb = rig.pose.bones["handslot.r"]
    base = rig.matrix_world @ pb.matrix

    # THE PREMISE, re-measured. artifactfit's gate 1, repeated here so this file
    # does not inherit a claim it has not checked.
    b3 = base.to_3x3()
    sx = (b3 @ Vector((1, 0, 0))).normalized().dot(Vector((0, 0, -1)))
    sy = (b3 @ Vector((0, 1, 0))).normalized().dot(Vector((0, -1, 0)))
    premise = dict(slotX_dot_worlddown=round(sx, 4), slotY_dot_worldfwd=round(sy, 4))
    if sx < 0.98 or sy < 0.98:
        raise SystemExit("AUDIT FAIL - the slot premise is void on this rig: %s. "
                         "The rule's foundation is gone; refusing to score." % premise)

    scene = bpy.context.scene
    G.set_engine(scene)
    scene.render.resolution_x, scene.render.resolution_y = WF.CELL_X, WF.CELL_Y
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    if scene.world is None:
        scene.world = bpy.data.worlds.new("w")
    scene.world.use_nodes = True
    for nm, rot, en in (("key", (-0.95, 0.0, 0.7), 3.2), ("fill", (-1.2, 0.0, -2.1), 1.3)):
        if nm not in bpy.data.objects:
            ld = bpy.data.lights.new(nm, 'SUN')
            ld.energy = en
            lo = bpy.data.objects.new(nm, ld)
            lo.rotation_euler = rot
            bpy.context.collection.objects.link(lo)

    bmn, bmx, bpts = G.world_bounds(body)
    cz = (WF.FRAME_H / 2.0) - WF.GROUND_UP

    reg, errors, sheet = {}, [], {}

    def carry(fam, Rslot):
        """Import the family's mesh and put it in the hand under Rslot.
        Returns (objs, meshes, world verts)."""
        objs, path = WF.load_model(a.repo, fam, TIER)
        meshes = [o for o in objs if o.type == 'MESH']
        if not meshes:
            for o in objs:
                bpy.data.objects.remove(o, do_unlink=True)
            return [], [], [], path
        hs = OVR[fam]["scale"] if fam in OVR else WF.HAND_SCALE
        S = Matrix.Diagonal((hs,) * 3).to_4x4()
        T = (Matrix.Translation(GRIP_VEC) if fam == GRIP["fam"] else Matrix.Identity(4))
        for o in objs:
            if o.parent is None:
                o.matrix_world = base @ Rslot @ S @ T @ o.matrix_world
        bpy.context.view_layer.update()
        return objs, meshes, WF.world_verts(meshes), path

    for fam in fams:
        rec = {"family": fam, "tier": TIER}

        # ---- the mesh's own frame: extents and long axis, BEFORE any carry ----
        objs0, path0 = WF.load_model(a.repo, fam, TIER)
        m0 = [o for o in objs0 if o.type == 'MESH']
        lv = WF.world_verts(m0) if m0 else []
        if not lv:
            errors.append("%s: zero vertices imported - every number below would be "
                          "measured over nothing" % fam)
            for o in objs0:
                bpy.data.objects.remove(o, do_unlink=True)
            reg[fam] = dict(rec, ok=False, reason="no verts")
            continue
        ext = [max(v[i] for v in lv) - min(v[i] for v in lv) for i in range(3)]
        li = int(np.argmax(ext))
        srt = sorted(ext, reverse=True)
        rec["mesh_extent_xyz"] = [round(e, 4) for e in ext]
        rec["long_axis"] = "XYZ"[li]
        rec["elongation"] = round(srt[0] / srt[1], 3) if srt[1] > 1e-9 else None
        long_u = Vector((0, 0, 0))
        long_u[li] = 1.0
        for o in objs0:
            bpy.data.objects.remove(o, do_unlink=True)

        # ---- the two bases ----
        rot_deg = OVR[fam]["engine_rot_deg"] if fam in OVR else ("0", "0", "0")
        rec["held_rot_deg_from_gear_gd"] = list(rot_deg)
        rec["engine_mirrored"] = fam in OVR
        Rg = godot_rot(rot_deg)
        # THE CONJUGATION. At held_rot zero this is Identity, which is what
        # weaponfit ships for the six uncalibrated families and what the
        # engine capture shows. See the note at the top of this file.
        R_rule = C4 @ Rg @ C4.inverted()
        if fam in WF.SLOT_ROT:
            R_wf, roll = WF.slot_matrix(fam, rot_deg if fam in OVR else None)
        else:
            R_wf, roll = Matrix.Identity(4), 0.0
        rec["weaponfit_rule"] = ("hand-calibrated SLOT_ROT" if fam in WF.SLOT_ROT
                                 else "Matrix.Identity (never calibrated)")
        rec["rule_under_test"] = "C . R_godot(YXZ) . C^-1"
        rec["roll_applied_deg"] = round(roll, 3)
        rec["bases_equal"] = bool(all(abs(R_wf[r][c] - R_rule[r][c]) < 1e-6
                                      for r in range(4) for c in range(4)))

        # relative rotation, in the MESH frame: is it a roll about the long axis?
        D = (R_wf.inverted() @ R_rule).to_3x3()
        q = D.to_quaternion()
        ang = math.degrees(q.angle)
        axis = q.axis.normalized() if q.angle > 1e-6 else Vector((0, 0, 1))
        par = abs(axis.dot(long_u))
        rec["relative_rotation_deg"] = round(ang, 3)
        rec["relative_axis_mesh"] = [round(c, 4) for c in axis]
        rec["axis_dot_longaxis"] = round(par, 4)
        rec["is_roll_about_long_axis"] = bool(ang < 1e-3 or par > 0.98)

        # ---- the viewer's question, through ONE camera per view ----
        o_wf, m_wf, v_wf, path = carry(fam, R_wf)
        o_rl, m_rl, v_rl, _ = carry(fam, R_rule)
        if not v_wf or not v_rl:
            errors.append("%s: a carried point set is empty - the A/B pair would be "
                          "measured over nothing" % fam)
            for o in list(o_wf) + list(o_rl):
                bpy.data.objects.remove(o, do_unlink=True)
            reg[fam] = dict(rec, ok=False, reason="empty carry")
            continue
        rec["model"] = os.path.relpath(path, a.repo).replace("\\", "/")
        rec["verts"] = len(v_wf)

        views = {}
        for vname, az in WF.VIEWS:
            cam = WF.make_cam(az, cz, list(bpts) + list(v_wf) + list(v_rl))
            WF.show(o_wf, False)
            WF.show(o_rl, False)
            base_img = WF.render_to(os.path.join(tmp, "%s_%s_body.png" % (fam, vname)))
            WF.show(o_wf, True)
            a_img = WF.render_to(os.path.join(tmp, "%s_%s_wf.png" % (fam, vname)))
            WF.show(o_wf, False)
            WF.show(o_rl, True)
            b_img = WF.render_to(os.path.join(tmp, "%s_%s_rule.png" % (fam, vname)))
            WF.show(o_rl, False)

            add_wf = moved_px(base_img, a_img)
            add_rl = moved_px(base_img, b_img)
            ab = moved_px(a_img, b_img)
            v = dict(added_px_weaponfit=add_wf, added_px_rule=add_rl, moved_px_AB=ab,
                     opaque_body=opaque(base_img), opaque_wf=opaque(a_img),
                     opaque_rule=opaque(b_img),
                     border_alpha_wf=round(border_alpha(a_img), 4),
                     border_alpha_rule=round(border_alpha(b_img), 4),
                     frame_outside_wf=WF.frame_outside(cam, v_wf),
                     frame_outside_rule=WF.frame_outside(cam, v_rl))
            if v["opaque_wf"] == 0 or v["opaque_rule"] == 0:
                errors.append("%s/%s: BLANK render - %s" % (fam, vname, json.dumps(v)))
            if add_wf == 0 and add_rl == 0:
                errors.append("%s/%s: the weapon adds ZERO pixels under BOTH bases - "
                              "this pair proves nothing and must not read as agreement"
                              % (fam, vname))
            if v["border_alpha_wf"] > 0.02 or v["border_alpha_rule"] > 0.02:
                errors.append("%s/%s: border alpha - something is CUT BY THE FRAME "
                              "(wf %.3f rule %.3f)" % (fam, vname,
                                                       v["border_alpha_wf"],
                                                       v["border_alpha_rule"]))
            views[vname] = v
            sheet[(fam, vname)] = (a_img, b_img)
            bpy.data.objects.remove(cam, do_unlink=True)

        for o in list(o_wf) + list(o_rl):
            bpy.data.objects.remove(o, do_unlink=True)

        if not views:
            errors.append("%s: zero views measured" % fam)
            reg[fam] = dict(rec, ok=False, reason="no views")
            continue
        rec["views"] = views
        worst = max(v["moved_px_AB"] for v in views.values())
        ref = max(1, max(max(v["added_px_weaponfit"], v["added_px_rule"])
                         for v in views.values()))
        rec["worst_moved_px_AB"] = worst
        rec["worst_moved_frac_of_weapon"] = round(worst / float(ref), 4)
        # VISIBLE means the two bases do not put the same pixels on screen. The
        # threshold is deliberately low and the picture is the arbiter.
        rec["visibly_different"] = bool(worst > 200)
        reg[fam] = rec
        print("AUDIT %-9s long=%s elong=%s rel=%6.1f deg roll_about_long=%-5s "
              "worst_moved=%6d frac=%.3f" %
              (fam, rec["long_axis"], rec["elongation"], rec["relative_rotation_deg"],
               rec["is_roll_about_long_axis"], worst,
               rec["worst_moved_frac_of_weapon"]))
        sys.stdout.flush()

    # ---- the contact sheet: wf on top, rule below, one column per fam/view ----
    cols = [k for k in sheet.keys()]
    if not cols:
        errors.append("no sheet columns - nothing was rendered")
    else:
        th = 190
        gw, gh = th, th
        W = gw * len(WF.VIEWS)
        H = gh * 2 * len(fams)
        canvas = np.zeros((H, W, 4), dtype=np.float32)
        vorder = [v for v, _ in WF.VIEWS]
        for fi, fam in enumerate(fams):
            for vi, vname in enumerate(vorder):
                if (fam, vname) not in sheet:
                    continue
                aimg, bimg = sheet[(fam, vname)]
                for row, img in ((0, aimg), (1, bimg)):
                    s = img[::max(1, img.shape[0] // th), ::max(1, img.shape[1] // th)]
                    s = s[:th, :th]
                    y = (fi * 2 + row) * gh
                    canvas[y:y + s.shape[0], 0 + vi * gw:vi * gw + s.shape[1]] = s
        im = bpy.data.images.new("sheet", width=W, height=H, alpha=True)
        im.pixels = canvas.reshape(-1).tolist()
        im.filepath_raw = os.path.join(outdir, "_sheet_basis_AB.png")
        im.file_format = 'PNG'
        im.save()

    verdict = ("RED" if errors else
               ("DIVERGENCE IS VISIBLE" if any(r.get("visibly_different")
                                               for r in reg.values())
                else "DIVERGENCE IS LATENT"))
    out = dict(tool="_wf_basis_audit", premise=premise, order=ORDER,
               families=len(reg), errors=errors, verdict=verdict, register=reg,
               sheet="renders/art/_wf_basis/_sheet_basis_AB.png")
    with open(os.path.join(outdir, "_wf_basis_audit.json"), "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=1, sort_keys=True)
    print("AUDIT VERDICT %s errors=%d" % (verdict, len(errors)))
    for e in errors:
        print("  ERR %s" % e)
    print("AUDIT DONE")


main()
