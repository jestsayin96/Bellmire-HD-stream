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


def build(mark):
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
    return objs, dict(aura=aura), hit


objs, info, _ = build(False)
pa, _, _ = G.render_views(objs, key, os.path.join(OUT, "nm"), 700, 980, info)
objs, info, hit = build(True)
pb, _, _ = G.render_views(objs, key, os.path.join(OUT, "mk"), 700, 980, info)

if hit == 0:
    raise SystemExit("RED %s/%s: the landmark sphere selected ZERO parts - it is "
                     "aimed at empty space, and a diff of nothing reads clean" % (key, name))

rep, red = {}, []
for a_p, b_p in zip(pa, pb):
    v = os.path.splitext(os.path.basename(a_p))[0]
    A, B = G.read_png(a_p), G.read_png(b_p)
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
    rep[v] = dict(vis_px=vis, body_px=body_px,
                  vis_frac=round(vis / float(body_px), 4),
                  sep=round(sep, 4), pairs=pairs,
                  red=bool(sep < 0.045))
    if sep < 0.045:
        red.append("%s: %s is visible (%d px) but does NOT SEPARATE - median "
                   "luminance step across its boundary is %.3f" % (v, name, vis, sep))

out = dict(key=key, landmark=name, at=[cx, cy, cz], r=rr, parts_selected=hit,
           views=rep, red=red)
with open(os.path.join(OUT, "_%s.json" % name), "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2)
print("LANDMARK", json.dumps(out))
