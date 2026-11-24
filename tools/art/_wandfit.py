"""_wandfit - THE FIT PROOF MR. E'S OWN WAND HAS NEVER HAD.

  blender -b -noaudio -P tools/art/_wandfit.py -- --repo <repo> --basis engine
  blender -b -noaudio -P tools/art/_wandfit.py -- --repo <repo> --basis staff

WHY THIS FILE EXISTS. `assets/gear/wand_crystal.glb` is Mr. E's own asset. He
dropped it on 16 Nov 05:03 CT and the art lane made it game-weight the same
hour (306,024 tris / 24 MB -> 8,000 tris / 2.38 MB, origin moved to the base
of the grip). It had sat in the repo for EIGHT DAYS with, measured rather than
remembered, no render of it on a body anywhere under renders/. The fit rule is
binding and it is this lane's own: a piece that has never been rendered on a
body is NOT DONE. So this is the missing proof and nothing else.

WHY NOT weaponfit.py. That gate resolves models as
`assets/gear/dungeon/<fam>_<tier>.glb` and reads its per-family carry out of
gear.gd. The wand is at neither path and has NO gear.gd ROW, so weaponfit
cannot see it, and widening a working gate to take one arbitrary file is how a
gate stops meaning what its name says. This file BORROWS weaponfit's machinery
by import - the hero, the calibrated handslot basis, the BVH clip test, the
camera, the blank and frame checks - and changes none of it.

===========================================================================
*** PASS 2, 24 NOV 05:4x CT. THE CAVEAT PASS 1 PRINTED WAS NOT A CAVEAT,
*** IT WAS A FAULT, AND THE TEAM LEAD FOUND IT BY READING PAST WHERE I
*** STOPPED.
===========================================================================
Pass 1 said out loud that gear.gd has no entry for this model, recorded
`carry_assumed: "staff"`, measured the staff basis, and came back RED with
clip 938. The honesty was real and the reading was half. `gear.gd` keys BOTH
accessors by PATH and BOTH END IN A DEFAULT ARM:

    held_rot   (gear.gd:250-271) ... return Vector3.ZERO
    hand_scale (gear.gd:290-315) ... return 0.62 if path.begins_with(KIT) else 1.0

and `KIT` is `res://assets/gear/` (gear.gd:10) - exactly where the wand sits.
There is no hole. The carry this model would get in the engine TODAY, with no
wiring from any lane, is held_rot (0, 0, 0) at hand_scale 0.62. I have now
read it rather than been told it: `gearcarry.py` walks the real branches of
both functions in source order, resolves gear.gd's own path consts, and
reproduces every row the engine does carry (staff_ -> (0,0,90) x1.9,
crossbow_ -> (-90,35,90) x1.0, bow_golden -> (0,0,90) x0.6, sword_common ->
ZERO x0.8) before it is trusted on the wand. SO PASS 1's 938-VERT CLIP
DESCRIBES A CARRY NOTHING SHIPS - a staff rotation the wand never gets, AND,
separately, at scale 1.0, which is neither the wand's 0.62 nor the staff's own
1.9. The staff run was wrong about the wand and was never right about the
staff either.

THE BASIS AT held_rot ZERO IS NOT A NEW CONSTANT AND NOT A FORMULA I FITTED.
weaponfit's `slot_matrix` refuses to derive a basis when gear.gd moves any
angle but the roll, and it is right to. But ZERO needs no derivation: six of
weaponfit's eight families (sword, axe, hammer, dagger, axeDouble, shield)
have NO held_rot branch in gear.gd, so the engine hands them Vector3.ZERO,
and weaponfit measures every one of them at `Matrix.Identity(4)` - rows that
have been rendered, looked at and shipped. Identity IS this lane's calibrated
basis for the zero carry, confirmed across six families, and the wand is the
seventh case of it. THIS FILE ASSERTS THAT RATHER THAN CLAIMING IT: it reads
one zero-rot family's carry out of gear.gd, checks the family is absent from
`WF.SLOT_ROT`, and only then rides identity. And if gear.gd ever gives the
wand a NONZERO row, this file does NOT rotate it - there is no calibration
record for that carry, so it stops, exactly as weaponfit would.

AND IT GOES RED ON EMPTY, same rule as every instrument this lane ships: a
clip or ground count taken over zero vertices is a FAIL, not a silent green.
"""
import os
import sys
import json
import struct
import argparse

import bpy
import numpy as np
from mathutils import Vector, Matrix, bvhtree

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G          # noqa: E402
import minibossfit as MF     # noqa: E402
import weaponfit as WF       # noqa: E402
import gearcarry as GC       # noqa: E402

MODEL = os.path.join("assets", "gear", "wand_crystal.glb")
RES_PATH = "res://assets/gear/wand_crystal.glb"
# a family the engine hands Vector3.ZERO, used to assert the identity basis
# rather than assume it. Read, not copied: see zero_basis_is_sound().
ZERO_WITNESS = "res://assets/gear/dungeon/sword_common.glb"
ZERO_WITNESS_FAM = "sword"


def zero_basis_is_sound(gear_path):
    """Identity is the calibrated basis for held_rot ZERO, and this proves it
    off the engine and off weaponfit rather than asserting it in prose."""
    w = GC.carry(gear_path, ZERO_WITNESS)
    if w["held_rot_deg"] != [0.0, 0.0, 0.0]:
        raise SystemExit(
            "WANDFIT FAIL - %s no longer reads held_rot ZERO in gear.gd (now "
            "%s), so it can no longer witness the zero basis. Pick a family "
            "the engine still hands ZERO before measuring."
            % (ZERO_WITNESS, w["held_rot_deg"]))
    if ZERO_WITNESS_FAM in WF.SLOT_ROT:
        raise SystemExit(
            "WANDFIT FAIL - weaponfit now carries a SLOT_ROT basis for %r, so "
            "it no longer measures that family at identity and cannot witness "
            "the zero basis." % ZERO_WITNESS_FAM)
    return dict(witness=ZERO_WITNESS, witness_held_rot=w["held_rot_deg"],
                witness_arm=w["held_rot_arm"],
                witness_in_slot_rot=False,
                note="six weaponfit families get Vector3.ZERO from gear.gd and "
                     "are measured at Matrix.Identity in the shipped register; "
                     "the wand is the same carry, so identity is read off the "
                     "engine's default arm and not invented here")


def glb_root_translations(path):
    """The node translations the ASSET itself carries, read out of the glb's
    own JSON chunk - not through Blender's importer. Pass 1 found a +30.5 on X
    in the imported object's matrix_world and OVERWROTE it, which is right for
    a fit render and says nothing about what the ENGINE would do with it. The
    engine sets scale and rotation_degrees on the instanced scene and does not
    touch position, so a translation on a glTF node would survive into the
    game. Whether it does is the game build's call; locating it is mine."""
    with open(path, "rb") as fh:
        magic, ver, total = struct.unpack("<III", fh.read(12))
        if magic != 0x46546C67:
            raise SystemExit("WANDFIT FAIL - %s is not a glb" % path)
        js = None
        while fh.tell() < total:
            hdr = fh.read(8)
            if len(hdr) < 8:
                break
            ln, kind = struct.unpack("<II", hdr)
            data = fh.read(ln)
            if kind == 0x4E4F534A:
                js = json.loads(data.decode("utf-8"))
                break
        if js is None:
            raise SystemExit("WANDFIT FAIL - no JSON chunk in %s" % path)
    nodes = js.get("nodes", [])
    children = set()
    for n in nodes:
        children.update(n.get("children", []))
    roots = [i for i in range(len(nodes)) if i not in children]
    out = []
    for i, n in enumerate(nodes):
        # a glTF node carries EITHER trs components OR a full `matrix`, and a
        # reader that looks only at `translation` would report a clean asset
        # for a node whose offset lives in the matrix. Both, or this check is
        # the same half-reading fault as pass 1's.
        t = n.get("translation")
        m = n.get("matrix")
        if m is not None and len(m) == 16:
            t = [float(m[12]), float(m[13]), float(m[14])]
        if t and any(abs(float(v)) > 1e-6 for v in t):
            out.append(dict(node=i, name=n.get("name", ""),
                            is_root=(i in roots),
                            translation=[round(float(v), 4) for v in t],
                            from_matrix=(m is not None),
                            has_mesh=("mesh" in n),
                            n_children=len(n.get("children", []))))
    return dict(n_nodes=len(nodes), roots=roots, nonzero_translations=out,
                nodes_with_matrix=[i for i, n in enumerate(nodes) if "matrix" in n])


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--gear", default="",
                    help="scripts/gear.gd of the main repo. Default: the sibling "
                         "checkout. The carry is READ from it, never copied in.")
    ap.add_argument("--basis", default="engine", choices=("engine", "staff"),
                    help="engine: the carry gear.gd's own default arms give this "
                         "path (held_rot ZERO at hand_scale 0.62). staff: pass 1's "
                         "reference run, the staff rotation at scale 1.0, kept so "
                         "the comparison reproduces.")
    a = ap.parse_args(argv)

    gear_path = a.gear or os.path.join(os.path.dirname(os.path.abspath(a.repo)),
                                       "jests-hd-medieval-adventure", "scripts", "gear.gd")
    if not os.path.exists(gear_path):
        raise SystemExit("WANDFIT FAIL - cannot read the engine carry at %s. "
                         "Without it every number below is an assumption with a "
                         "decimal point on it." % gear_path)

    cc = GC.carry(gear_path, RES_PATH)
    zw = zero_basis_is_sound(gear_path)
    grip, grip_vec = WF.grip_shift(gear_path)

    outdir = os.path.join(a.repo, "renders", "art", "wand", a.basis)
    os.makedirs(outdir, exist_ok=True)
    path = os.path.join(a.repo, MODEL)
    if not os.path.isfile(path):
        raise SystemExit("WANDFIT FAIL - no model at %s" % path)
    asset_nodes = glb_root_translations(path)

    # THE CARRY THIS RUN MEASURES, chosen before anything is imported so the
    # register can never describe one carry while the picture shows another.
    if a.basis == "engine":
        if cc["held_rot_deg"] != [0.0, 0.0, 0.0]:
            raise SystemExit(
                "WANDFIT FAIL - gear.gd now carries this model at held_rot %s. "
                "There is no calibration record for that basis, so this file "
                "will not score a carry nobody derived - same refusal as "
                "weaponfit's slot_matrix. Derive the basis against the engine "
                "first." % cc["held_rot_deg"])
        Rslot = Matrix.Identity(4)
        hs = cc["hand_scale"]
        carry_src = ("gear.gd's own default arms for this path: held_rot %s (%s) "
                     "at hand_scale %.3f (%s)"
                     % (cc["held_rot_deg"], cc["held_rot_arm"], hs,
                        cc["hand_scale_arm"]))
    else:
        Rslot, _roll = WF.slot_matrix("staff")
        hs = 1.0
        carry_src = ("PASS 1's REFERENCE RUN, kept only so the comparison "
                     "reproduces. The staff ROTATION (0,0,90) at scale 1.0. The "
                     "engine gives this path held_rot %s at x%.3f, and gives the "
                     "STAFF x1.9, so this run describes neither the wand's carry "
                     "nor the staff's."
                     % (cc["held_rot_deg"], cc["hand_scale"]))
    # the engine gates its grip shift to one family, READ not assumed; the wand
    # is not that family, so there is no translation term in the carry.
    T = Matrix.Identity(4)
    grip_applies = RES_PATH.startswith("res://assets/gear/%s_" % grip["fam"]) or \
        ("%s_" % grip["fam"]) in RES_PATH
    if grip_applies:
        raise SystemExit("WANDFIT FAIL - gear.gd's grip shift is gated to %r and "
                         "this path now matches it; the carry would need the "
                         "translation term. Refusing to measure without it."
                         % grip["fam"])

    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o, do_unlink=True)

    roots, body, hinfo = MF.import_hero(a.repo)
    rig = next((o for o in roots if o.type == 'ARMATURE'), None)
    assert rig is not None, "no armature in the hero glb"
    assert hinfo["posed"], "hero is in REST pose - the idle action did not take"
    bpy.context.view_layer.update()

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

    pb = rig.pose.bones["handslot.r"]
    base = rig.matrix_world @ pb.matrix
    slot = base @ Vector((0, 0, 0))

    dg = bpy.context.evaluated_depsgraph_get()
    body_trees = []
    for ob in body:
        try:
            body_trees.append(bvhtree.BVHTree.FromObject(ob, dg))
        except Exception:
            pass
    assert body_trees, "no BVH built from the body - the clip test would read 0 over nothing"

    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    wand = [o for o in bpy.data.objects if o not in before and o.type == 'MESH']
    assert wand, "WANDFIT FAIL - the wand glb imported no mesh; every metric below would be over nothing"
    bpy.context.view_layer.update()

    root = [o for o in bpy.data.objects if o not in before and o.parent is None]
    imported = [dict(name=o.name, type=o.type,
                     parent=(o.parent.name if o.parent else None),
                     local_translation=[round(v, 4) for v in o.matrix_local.translation])
                for o in bpy.data.objects if o not in before]
    # *** PASS 1's "+30.5 ON X" NOTE DOES NOT REPRODUCE, AND I AM STRIKING IT
    # *** RATHER THAN CARRYING IT. Pass 1 recorded that `wand_crystal.glb`
    # carries a translation of +30.5 on X in its own node transform, that its
    # mesh bounds were x 30.426..30.574, and that composing
    # `base @ M @ o.matrix_world` therefore put the wand thirty metres from the
    # hand. MEASURED AGAIN THIS PASS, against an asset git says has not changed
    # since d9a6a3d3: the glb has ONE node, no `matrix`, NO translation, and
    # the imported object's local translation is [0, 0, 0]. So either that note
    # was wrong when it was written or it described a state I cannot reproduce;
    # either way it is not true of the file in the repo today, and a note that
    # is not true is worse than no note. `asset_nodes` in the register is the
    # live reading, taken out of the glb's own JSON chunk rather than through
    # the importer, and it reads whichever of trs/matrix the node uses.
    # THE OVERWRITE STAYS, and not because of that story: setting matrix_world
    # rather than composing is what makes the carry exactly
    # `base @ Rslot @ S` - the engine's own order - with nothing of the
    # asset's own placement smuggled into it. If the asset ever does carry a
    # node offset, the ENGINE would keep it (it sets scale and
    # rotation_degrees and never touches position), so the register names it
    # for the game build instead of silently absorbing it.
    for o in root:
        o.matrix_world = base @ Rslot @ Matrix.Diagonal((hs,) * 3).to_4x4() @ T
    bpy.context.view_layer.update()

    wv = WF.world_verts(wand)
    assert wv, "WANDFIT FAIL - zero wand vertices in world space"
    bmn, bmx, bpts = G.world_bounds(body)
    allpts = bpts + wv

    # the fist sphere is excluded exactly as weaponfit does: the grip is inside
    # the hand BY DESIGN and is not a clip.
    FIST = WF.FIST_R
    far = [p for p in wv if (p - slot).length > FIST]
    if not far:
        raise SystemExit("WANDFIT FAIL - every wand vertex is inside the fist "
                         "sphere, so the clip test would be taken over nothing")
    clip = sum(1 for p in far if WF.inside(body_trees, p))
    ground = sum(1 for p in wv if p.z < -0.002)
    floor_depth = round(max(0.0, -min(p.z for p in wv)), 4)
    reach = max(p.z for p in wv) - slot.z
    drop = slot.z - min(p.z for p in wv)
    length = max(sorted([max(p[i] for p in wv) - min(p[i] for p in wv)
                         for i in range(3)]))

    cz = (WF.FRAME_H / 2.0) - WF.GROUND_UP
    rows, blanks, framed, blind = {}, [], [], []
    for name, az in WF.VIEWS:
        cam = WF.make_cam(az, cz, allpts)
        out = os.path.join(outdir, "%s.png" % name)
        WF.show(wand, False)
        without = WF.render_to(os.path.join(outdir, "_no_%s.png" % name))
        WF.show(wand, True)
        with_ = WF.render_to(out)
        # THE VIEWER'S QUESTION, not the object's: how many pixels MOVED when
        # the wand was added, through ONE camera, letting the renderer do the
        # depth. A mask of the wand alone would answer how BIG it is and say
        # nothing about whether it can be SEEN. (Pass 11, 17 Nov.)
        moved = int(np.count_nonzero(np.abs(with_ - without).max(axis=2) > 0.01))
        opaque = int(np.count_nonzero(with_[:, :, 3] > 0.5))
        if opaque == 0:
            blanks.append(name)
        # *** AND THE MOVED-PIXEL TEST ON ITS OWN IS NOT ENOUGH EITHER, WHICH
        # *** PASS 1 PROVED AGAINST ME. With the wand thirty metres away this
        # *** test reported moved = 427 / 869 / 539 and `blind_views: []`, and
        # *** the render has NO WAND IN IT. The moving pixels were the SHADOW
        # *** an off-camera object still casts onto the body. So the diff
        # *** answers "did anything change", not "can the viewer see the
        # *** thing" - the same family as the pass-11 mask fault, one level up.
        # *** The guard is cheap and it is a different question: an object with
        # *** NO vertex inside the frame is blind by construction, whatever the
        # *** pixels did. Both terms, and the out-of-frame count is taken over
        # *** the WAND, never over body-plus-wand, or the body's own points
        # *** would dilute it.
        fo_wand = WF.frame_outside(cam, wv)
        fo_all = WF.frame_outside(cam, allpts)
        if moved == 0 or fo_wand >= len(wv):
            blind.append(name)
        if fo_all:
            framed.append([name, int(fo_all)])
        rows[name] = dict(moved=moved, opaque=opaque,
                          wand_verts_outside_frame=int(fo_wand),
                          frame_outside=int(fo_all))
        bpy.data.objects.remove(cam, do_unlink=True)

    # *** AND `clip` IS GATED, WHICH IS THE THIRD THING PASS 1 OF THIS FILE GOT
    # *** WRONG IN ONE SITTING. I copied weaponfit's measures and I copied its
    # *** FAULT 7 with them: `clip` was computed, printed, and conjoined into
    # *** NOTHING, so the register said GREEN over 938 wand vertices buried
    # *** inside the body. A number that gates on nothing is decoration.
    ok = ((not blanks) and (not blind) and (not framed)
          and ground == 0 and clip == 0 and len(wv) > 0)
    rep = dict(verdict="GREEN" if ok else "RED", ok=ok, model=MODEL,
               basis=a.basis, carry_source=carry_src,
               engine_carry=cc, zero_basis_witness=zw,
               rslot_is_identity=(a.basis == "engine"),
               hand_scale=hs, grip_shift_applies=False,
               grip_shift_gate=dict(grip),
               asset_nodes=asset_nodes, imported=imported,
               verts=len(wv), checked=len(far),
               reach=round(reach, 4), drop=round(drop, 4),
               longest_axis=round(length, 4),
               clip=int(clip), ground=int(ground), floor_depth=floor_depth,
               handslot=[round(v, 4) for v in slot], views=rows,
               blanks=blanks, blind_views=blind, frame_clipped=framed,
               hero=hinfo)
    with open(os.path.join(outdir, "_report.json"), "w") as f:
        json.dump(rep, f, indent=1)
    print("WANDFIT_REPORT " + json.dumps(rep))


if __name__ == "__main__":
    main()
