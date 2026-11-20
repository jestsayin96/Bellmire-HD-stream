"""CAN THE VIEWER SEE THIS PART, AND DOES IT SEPARATE FROM WHAT IS BEHIND IT?

WHY THIS EXISTS. The fit register says `seen: 1.0` on every view of the Sower
and the team lead still found, BY LOOKING, that from the side its forearm, hand
and seed-bag read as ONE PALE MASS. _mb_sil.py cannot find that either and says
so in its own docstring: a silhouette throws colour away, so two parts that
overlap are one blob there whether colour tells them apart or not. Neither
instrument asks the VIEWER'S question.

This one does, and it asks it the way pass 11 taught this lane to ask it: NOT
by rendering a part alone (mask_of answers how BIG a thing is and says nothing
about whether it can be SEEN - that is how `head_glow_px: 156` shipped beside
the sentence "the head now has no face at all"). It renders the WHOLE creature
TWICE through ONE camera, once normally and once with the landmark's geometry
swapped to a flat marker material, and counts THE PIXELS THAT MOVED. The
renderer does the depth. A part behind the body moves nothing and scores zero,
which is the honest answer.

TWO NUMBERS, BECAUSE THERE ARE TWO WAYS TO BE INVISIBLE:
  vis_px   - how many pixels of this landmark the camera can actually see.
             STRUCTURAL. Zero means occluded or pointed down the camera axis.
  sep      - the median absolute luminance difference across the landmark's
             boundary, measured in the NORMAL render, between the landmark's
             own edge pixels and the creature pixels immediately outside it.
             TONAL. Near zero means the part is visible and still does not
             read, which is the pale-on-pale fault by name.

RED ON EMPTY, BOTH OF THEM. vis_px == 0 is RED, not a clean sheet. A sep
computed over zero boundary pairs is RED, not 0.0 - a metric over an empty set
reading green is the lying-instrument class this lane has shipped before.

PASS 5 ADDS THE QUESTION THE LIT NUMBER CANNOT ANSWER: IS THE STEP IN THE
MATERIAL, OR IS IT JUST WHERE THE LIGHT IS. sep_local is read off the LIT
render, so a boundary between two patches of the SAME albedo can score well
purely because one of them happens to face the key light. That step moves with
the lamp and with the camera azimuth - the ticked pass-4 table already names
the hazard twice (the Moulder's neck cloth is the same material as the sand bed
behind him, and the Sower's hopper, legs and thorn stems are all 'bone') and
both times the honest answer was "recorded, not resolved". A third render
answers it: the same creature through the same camera with every slot flattened
to its own unlit base colour.

  sep_alb     the local step in ALBEDO LUMINANCE. Lightness the material owns.
  sep_chroma  the local step in ALBEDO CHROMA, so two parts of equal lightness
              and different colour no longer score zero - the blindness the
              pass-4 footer declares by construction on the Sower.
  frac_borrow the share of the boundary that PASSES lit and has neither albedo
              lightness nor albedo colour behind it. Separation on loan from
              the lamp.

THE VERDICT IS STILL sep_local AND NOTHING IS REMOVED, so every pass-4 row
stays comparable. What is new is a second, non-red flag: FRAGILE, raised when a
row passes lit and more than half its boundary is borrowed. Fragile is not red
and must not be reported as red - it says the row is one azimuth away from the
fault, which is exactly what the pass-4 footer wrote down and could not measure.

THE CHROMA THRESHOLD IS UNCALIBRATED. 0.045 is carried over from the luminance
channel because no stream measurement exists to set it against, so sep_chroma
is REPORTED AND IS NOT A VERDICT. Saying so is the point; an uncalibrated
number presented as a pass is this lane's lying-instrument class.

WHAT THIS STILL CANNOT SEE, said plainly so the next run does not trust it too
far: it judges ONE declared landmark. It says nothing about parts nobody
declared, nothing about whether the shape READS AS what it is meant to be, and
nothing about colour beyond luminance - two parts of equal lightness and
different hue score 0 here and may still separate on a stream. When this number
and a picture disagree, the picture is the evidence.

usage:
  blender -b -noaudio -P _mb_landmark.py -- <repo> <key> <name> <x> <y> <z> <r>
"""
import os
import sys
import json

import numpy as np
import bpy

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordlib as L          # noqa: E402
import lordgen as G          # noqa: E402
import minibosses as M       # noqa: E402
import minibossgen as MG     # noqa: E402

argv = sys.argv[sys.argv.index("--") + 1:]
repo, key, name = argv[0], argv[1], argv[2]
cx, cy, cz, rr = (float(v) for v in argv[3:7])

OUT = os.path.join(repo, "renders", "art", "minibosses", "_landmark", key)
os.makedirs(OUT, exist_ok=True)
os.makedirs(os.path.join(OUT, "nm"), exist_ok=True)
os.makedirs(os.path.join(OUT, "mk"), exist_ok=True)
os.makedirs(os.path.join(OUT, "ab"), exist_ok=True)


def wipe():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    for me in list(bpy.data.meshes):
        bpy.data.meshes.remove(me, do_unlink=True)


def lum(a):
    return 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]


def dil(m):
    o = m.copy()
    o[1:, :] |= m[:-1, :]
    o[:-1, :] |= m[1:, :]
    o[:, 1:] |= m[:, :-1]
    o[:, :-1] |= m[:, 1:]
    return o


def local_steps(chans, ring_in, ring_out):
    """For every landmark edge pixel, the LARGEST distance across the supplied
    channels to a body pixel ACTUALLY TOUCHING IT. Returns (steps, touched).

    Generalised at pass 5 from the single luminance field of pass 4. With ONE
    channel sqrt(d*d) is abs(d), so this is bit-for-bit the pass-4 arithmetic
    and no ticked row moves because of the refactor - that is the only reason
    it was worth refactoring rather than copying. With TWO channels it is a
    distance in the opponent-colour plane.

    RED ON EMPTY IS STILL THE CALLER'S JOB and the caller still does it: this
    returns an empty `touched` rather than a comforting zero, because a median
    over no pixels is the number this lane has shipped wrong before.
    """
    steps = np.zeros(chans[0].shape, dtype=np.float32)
    touched = np.zeros(chans[0].shape, dtype=bool)
    for ax, sh in ((0, 1), (0, -1), (1, 1), (1, -1)):
        o_m = np.roll(ring_out, sh, axis=ax)
        # a roll wraps, so the wrapped edge row/column is not a neighbour
        if ax == 0:
            (o_m.__setitem__((slice(0, 1), slice(None)), False) if sh > 0
             else o_m.__setitem__((slice(-1, None), slice(None)), False))
        else:
            (o_m.__setitem__((slice(None), slice(0, 1)), False) if sh > 0
             else o_m.__setitem__((slice(None), slice(-1, None)), False))
        d2 = np.zeros(steps.shape, dtype=np.float32)
        for ch in chans:
            d2 = d2 + (ch - np.roll(ch, sh, axis=ax)) ** 2
        d = np.sqrt(d2)
        hitm = ring_in & o_m
        steps = np.where(hitm, np.maximum(steps, d), steps)
        touched |= hitm
    return steps, touched


def build(mark, albedo=False):
    """Exactly minibossgen.build_miniboss, with the landmark's items moved into
    their own slot when `mark` is set. Geometry is IDENTICAL either way, so
    render_views derives the same bounds and the same camera - which is the
    whole premise of a with/without diff."""
    wipe()
    title, height, tint, aura, theme, idea, wear, line = M.CANON[key]
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
    mats = M.apply_overrides(key, mats)
    # ------------------------------------------------------------------ PASS 5
    # THE ALBEDO VARIANT. Every slot flattened to its OWN declared base colour
    # as unlit emission, so the render carries material and nothing else: no
    # key light, no fill, no rim, no normal. Geometry, camera and framing are
    # untouched, which is the same premise the with/without diff already rests
    # on. mat_glow at strength 1.0 is a flat emitter - the same node this file
    # already uses for the magenta marker, and NOT at the strength 6.0 that
    # pass 1 got burnt by, because here nothing needs to outshine anything.
    rgbs = {
        'body': tuple(body),
        'dark': tuple(c * 0.16 + 0.012 for c in body),
        'bone': tuple((0.30 + c * 0.55) * dull for c in tint),
        'glow': tuple(min(1.0, c / max(aura)) for c in aura),
    }
    approx = []
    ov = M.OVERRIDE.get(key) or {}
    for slot in list(rgbs):
        # an overridden slot ships a DECLARED colour and the tint arithmetic
        # above is not what the viewer sees. apply_overrides records the
        # non-glow ones in SLOT_RGB; 'glow' is not recorded there, so it is
        # read off the override row itself rather than guessed.
        dec = M.SLOT_RGB.get((key, slot))
        if dec is not None:
            rgbs[slot] = tuple(dec)
        elif slot == 'glow' and 'glow' in ov:
            rgbs['glow'] = tuple(ov['glow'][0])
        if slot in (M.VCOL_SLOTS.get(key) or set()):
            # THE COLOUR IS ON THE MESH, NOT IN THE SLOT. A vertex-driven slot
            # has many colours and this flattening gives it one - the fill. The
            # albedo channel is APPROXIMATE for that slot and the report says so
            # by name, because a number whose caveat lives only in a comment is
            # a number that will be trusted too far.
            approx.append(slot)
    if albedo:
        for slot, rgb in rgbs.items():
            mats[slot] = L.mat_glow(key + "_alb_" + slot, rgb, 1.0)
    # FLAT, NOT EMISSIVE. Pass 1 used mat_glow at strength 6.0. An emissive
    # marker can light or bloom onto its NEIGHBOURS, so pixels move that the
    # landmark does not occupy - an instrument that sees TOO MUCH, which reads
    # as a healthy number and is the same lie as one that sees nothing. A flat
    # unlit magenta changes exactly the pixels the marked geometry covers.
    mats['_mark'] = L.mat_glow(key + "_mark", (1.0, 0.0, 1.0), 1.0)
    P = M.BUILDERS[key]()
    # PASS 3, AND PASS 2 DELETED THE THING IT MEANT TO MARK. merge_objs walks
    # ONLY ('body','dark','bone','glow'), so moving an item into a '_mark' slot
    # dropped it from the render entirely - render B was the creature with a
    # HOLE in it. Pass 1's diff was therefore "geometry removed" plus the
    # shading jitter that re-merging causes everywhere, which is how the
    # Sower's head measured 79% of its own side silhouette.
    # Here the landmark geometry is kept and given its own object with a flat
    # magenta emission, so every triangle that was in render A is still in
    # render B and only its COLOUR has changed.
    keep, land, hit = [], ([], []), 0
    for it in P.items:
        verts, faces, slot = it
        take = False
        if mark:
            c = np.asarray(verts, dtype=np.float64).mean(axis=0)
            take = ((c[0] - cx) ** 2 + (c[1] - cy) ** 2
                    + (c[2] - cz) ** 2) ** 0.5 <= rr
        if take:
            off = len(land[0])
            land[0].extend(verts)
            land[1].extend([tuple(i + off for i in f) for f in faces])
            hit += 1
        else:
            keep.append((verts, faces, slot))
    objs = M.merge_objs(key, keep, mats, suffix=("mk" if mark else "nm"),
                        vcols=getattr(P, "vcols", None))
    if mark and hit:
        objs = objs + [L.make("%s_mark" % key, land[0], land[1], mats['_mark'])]
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
    return objs, dict(aura=aura), hit, approx


objs, info, _, approx = build(False)
pa, _, _ = G.render_views(objs, key, os.path.join(OUT, "nm"), 700, 980, info)
objs, info, hit, _ = build(True)
pb, _, _ = G.render_views(objs, key, os.path.join(OUT, "mk"), 700, 980, info)
objs, info, _, _ = build(False, albedo=True)
pc, _, _ = G.render_views(objs, key, os.path.join(OUT, "ab"), 700, 980, info)

if hit == 0:
    raise SystemExit("RED %s/%s: the landmark sphere selected ZERO parts - it is "
                     "aimed at empty space, and a diff of nothing reads clean" % (key, name))

rep, red = {}, []
for a_p, b_p, c_p in zip(pa, pb, pc):
    v = os.path.splitext(os.path.basename(a_p))[0]
    A, B, C = G.read_png(a_p), G.read_png(b_p), G.read_png(c_p)
    alpha = A[..., 3] > 0.5
    # PASS 2 OF THIS INSTRUMENT, AND PASS 1 WAS A LIAR. Pass 1 defined the
    # landmark as "any pixel where A and B differ by more than 0.02". Moving
    # items into their own slot re-merges the meshes, and the re-merge shifts
    # shading by a hair EVERYWHERE - so the mask I wrote out and LOOKED AT had
    # the Sower's legs, boots and thorn stalks in it and the head read as 79%
    # of the side silhouette. The number was noise with a head-shaped bit in
    # it. The picture is the evidence and the number was the suspect, exactly
    # as this lane learned at pass 11.
    # The fix is to stop asking "did anything change" and ask "is THIS pixel
    # the marker": the marker is unlit pure magenta, a colour no palette slot
    # in this file can produce, so the test is categorical and shading noise
    # cannot enter it.
    # categorical, and tolerant of the view transform: magenta is the only
    # thing in the frame whose red AND blue both stand clear of its green.
    moved = ((B[..., 0] - B[..., 1] > 0.15) & (B[..., 2] - B[..., 1] > 0.15)
             & (B[..., 3] > 0.5))
    vis = int(moved.sum())
    body_px = int(alpha.sum())
    if body_px == 0:
        red.append("%s: the creature render is EMPTY" % v)
        rep[v] = dict(vis_px=0, body_px=0, sep=None, pairs=0, red=True)
        continue
    if vis == 0:
        red.append("%s: %s is NOT VISIBLE - zero pixels moved" % (v, name))
        rep[v] = dict(vis_px=0, body_px=body_px, sep=None, pairs=0, red=True)
        continue
    # the boundary: creature pixels one step outside the landmark, still on the
    # body. Luminance read off the NORMAL render, which is what a viewer sees.
    ring_out = dil(moved) & alpha & ~moved
    ring_in = dil(~moved) & moved
    pairs = int(min(ring_out.sum(), ring_in.sum()))
    if pairs == 0:
        red.append("%s: %s has NO boundary against the body - nothing to compare, "
                   "and a separation measured over zero pairs is not a pass" % (v, name))
        rep[v] = dict(vis_px=vis, body_px=body_px, sep=None, pairs=0, red=True)
        continue
    # WRITE THE MASK SO A HUMAN CAN LOOK AT WHAT THE NUMBER COUNTED. A count
    # nobody has seen a picture of is the class of number this lane has shipped
    # wrong twice.
    vizm = np.ones(A.shape, dtype=np.float32)
    vizm[..., :3] = np.where(alpha[..., None], 0.80, 1.0)
    vizm[moved] = (0.90, 0.05, 0.55, 1.0)
    G.write_png(os.path.join(OUT, "_%s_%s_mask.png" % (name, v)), vizm)
    Lm = lum(A)
    sep = float(abs(np.median(Lm[ring_in]) - np.median(Lm[ring_out])))
    # ---------------------------------------------------------------- PASS 4
    # `sep` ABOVE IS NOT REPRODUCIBLE ON A MIXED BOUNDARY, AND I FOUND THAT BY
    # RE-RUNNING IT RATHER THAN BY THINKING ABOUT IT. 18 Nov 20:4x CT, nothing
    # in the tree changed between the two runs:
    #     sower head front          0.0386 -> 0.0504   CROSSES THE 0.045 LINE
    #     sower head three_quarter  0.0191 -> 0.0103
    #     moulder head front/side   0.0012 / 0.0174    reproduced exactly
    #     sower casthand all three                     reproduced exactly
    # The cause is the statistic, not the renderer. `sep` is the difference of
    # TWO GLOBAL MEDIANS over two separate pixel sets, so when a landmark's
    # boundary is a MIXTURE - the Sower's head touches shoulders, hat, hopper
    # rim, strap and two arms - each median sits between two populations and a
    # few pixels of EEVEE drift (vis_px moved 16 px between the runs) tip it.
    # A verdict that flips across its own threshold on an unchanged tree is a
    # coin toss wearing a number, which is this lane's lying-instrument class.
    #
    # THE LOCAL NUMBER BELOW DOES NOT HAVE THAT PROPERTY. It asks the question
    # per pixel: for every landmark edge pixel, the LARGEST luminance step to a
    # body pixel actually touching it. No global population, so no knife edge.
    # `sep_local` is the median of those steps and `frac_flat` is the share of
    # the boundary where the step is under the threshold - which is the number
    # `sep` cannot express at all: a boundary that separates sharply along the
    # hat and not at all along the neck has ONE median and TWO truths.
    # BOTH ARE REPORTED AND NOTHING IS REMOVED, so the ticked table stays
    # comparable row for row.
    steps, touched = local_steps([Lm], ring_in, ring_out)
    n_touch = int(touched.sum())
    if n_touch == 0:
        # RED ON EMPTY, same rule as every other count in this file.
        red.append("%s: %s - ZERO landmark edge pixels touch the body, so the "
                   "local step is computed over nothing and is not a pass" % (v, name))
        rep[v] = dict(vis_px=vis, body_px=body_px, sep=round(sep, 4), pairs=pairs,
                      sep_local=None, frac_flat=None, touch=0, red=True)
        continue
    sv = steps[touched]
    sep_local = float(np.median(sv))
    frac_flat = float((sv < 0.045).mean())

    # ---------------------------------------------------------------- PASS 5
    # IS THE STEP IN THE MATERIAL OR IS IT JUST WHERE THE LIGHT IS. Everything
    # above is read off the LIT render, so a boundary between two patches of
    # the SAME albedo scores well whenever one of them happens to face the key
    # light - and that step moves with the lamp and with the azimuth. The
    # pass-4 footer wrote the hazard down twice and could not measure it. The
    # third render is the same creature through the same camera with every slot
    # flattened to its own unlit base colour, so the only thing left in the
    # frame is material.
    alpha_c = C[..., 3] > 0.5
    if int(alpha_c.sum()) == 0:
        # RED ON EMPTY. An albedo render that came out blank must not be
        # allowed to report "no borrowed separation" - that reads as the
        # healthiest answer on the sheet and would mean nothing at all.
        red.append("%s: %s - the ALBEDO render is EMPTY, so sep_alb/sep_chroma "
                   "are computed over nothing" % (v, name))
        rep[v] = dict(vis_px=vis, body_px=body_px, sep=round(sep, 4), pairs=pairs,
                      sep_local=round(sep_local, 4), frac_flat=round(frac_flat, 4),
                      touch=n_touch, sep_alb=None, sep_chroma=None,
                      frac_borrow=None, red=True)
        continue
    Ca = np.clip(C[..., :3], 0.0, None)
    La = lum(Ca)
    # opponent axes off the albedo render: red-green and yellow-blue. Crude and
    # deliberately so - it is here to stop two parts of EQUAL LIGHTNESS and
    # different colour scoring a flat zero, which the pass-4 footer declares
    # this instrument does by construction on the Sower ('body' 0.498 against
    # 'bone' 0.549). It is NOT a perceptual colour difference and its threshold
    # is not calibrated against anything, so it is reported and never a verdict.
    opp_a = Ca[..., 0] - Ca[..., 1]
    opp_b = 0.5 * (Ca[..., 0] + Ca[..., 1]) - Ca[..., 2]
    s_alb, t_alb = local_steps([La], ring_in, ring_out)
    s_chr, _ = local_steps([opp_a, opp_b], ring_in, ring_out)
    if int(t_alb.sum()) != n_touch:
        # the two renders share geometry, camera and framing, so the boundary
        # must be the same pixels. If it is not, something upstream moved and
        # the comparison is void - say so rather than compare two boundaries.
        red.append("%s: %s - the albedo boundary is %d px against the lit %d. "
                   "The two renders are not the same geometry and the albedo "
                   "channels are VOID for this view"
                   % (v, name, int(t_alb.sum()), n_touch))
        rep[v] = dict(vis_px=vis, body_px=body_px, sep=round(sep, 4), pairs=pairs,
                      sep_local=round(sep_local, 4), frac_flat=round(frac_flat, 4),
                      touch=n_touch, sep_alb=None, sep_chroma=None,
                      frac_borrow=None, red=True)
        continue
    av, cv = s_alb[touched], s_chr[touched]
    sep_alb = float(np.median(av))
    sep_chroma = float(np.median(cv))
    frac_flat_alb = float((av < 0.045).mean())
    # BORROWED: this pixel passes on the lit render and has NEITHER albedo
    # lightness NOR albedo colour behind it. Whatever separates it is the lamp.
    pass_lit = touched & (steps >= 0.045)
    n_pass = int(pass_lit.sum())
    borrowed = pass_lit & (s_alb < 0.045) & (s_chr < 0.045)
    # RED ON EMPTY once more: a share over zero passing pixels is None, not 0.0.
    frac_borrow = (float(int(borrowed.sum()) / float(n_pass)) if n_pass else None)

    # THE PICTURE THE NUMBER OWES. Green where the boundary is carried by the
    # material, red where it is on loan from the light. This lane has twice
    # shipped a count nobody had seen a picture of.
    vizb = np.ones(A.shape, dtype=np.float32)
    vizb[..., :3] = np.where(alpha[..., None], 0.82, 1.0)
    vizb[pass_lit & ~borrowed] = (0.10, 0.70, 0.30, 1.0)
    vizb[borrowed] = (0.95, 0.10, 0.10, 1.0)
    vizb[touched & ~pass_lit] = (0.25, 0.25, 0.25, 1.0)
    G.write_png(os.path.join(OUT, "_%s_%s_borrow.png" % (name, v)), vizb)

    fragile = bool(sep_local >= 0.045 and frac_borrow is not None
                   and frac_borrow > 0.50)
    rep[v] = dict(vis_px=vis, body_px=body_px,
                  vis_frac=round(vis / float(body_px), 4),
                  sep=round(sep, 4), pairs=pairs,
                  sep_local=round(sep_local, 4),
                  frac_flat=round(frac_flat, 4), touch=n_touch,
                  sep_alb=round(sep_alb, 4),
                  frac_flat_alb=round(frac_flat_alb, 4),
                  sep_chroma=round(sep_chroma, 4),
                  pass_lit=n_pass,
                  frac_borrow=(round(frac_borrow, 4) if frac_borrow is not None
                               else None),
                  albedo_approx_slots=approx,
                  fragile=fragile,
                  red=bool(sep_local < 0.045))
    # THE VERDICT IS STILL THE LIT LOCAL NUMBER, because it is the one that
    # reproduces and the one every ticked row was measured with. FRAGILE below
    # is a WARNING and is deliberately not red: it does not say the viewer
    # cannot see the part today, it says the part is one azimuth from the fault.
    if sep_local < 0.045:
        red.append("%s: %s is visible (%d px) but does NOT SEPARATE - the median "
                   "local step along its boundary is %.3f and %.0f%% of that "
                   "boundary is flatter than 0.045 (global sep %.3f)"
                   % (v, name, vis, sep_local, 100.0 * frac_flat, sep))
    elif frac_flat > 0.50:
        red.append("%s: %s separates on the median (%.3f) but %.0f%% of its "
                   "boundary is FLAT - it reads along part of its outline only"
                   % (v, name, sep_local, 100.0 * frac_flat))

fragile_views = [v for v, d in rep.items() if d.get("fragile")]
warn = ["%s: %s PASSES lit (sep_local %.3f) and %.0f%% of its passing boundary "
        "is BORROWED FROM THE LIGHT - albedo step %.3f, chroma step %.3f. Not "
        "red: one azimuth from the fault."
        % (v, name, rep[v]["sep_local"], 100.0 * rep[v]["frac_borrow"],
           rep[v]["sep_alb"], rep[v]["sep_chroma"]) for v in fragile_views]
out = dict(key=key, landmark=name, at=[cx, cy, cz], r=rr, parts_selected=hit,
           views=rep, red=red, fragile=fragile_views, warn=warn,
           albedo_approx_slots=approx)
with open(os.path.join(OUT, "_%s.json" % name), "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2)
print("LANDMARK", json.dumps(out))
