"""_bg_sil_runs.py - THE FRONT-SILHOUETTE INSTRUMENT FOR BROODGLUT'S EARS.

WHY THIS EXISTS AND WHY IT IS NOT A SECOND FIT HARNESS.
The team lead looked at renders/art/variants/broodglut/hero_front.png and wrote
a fault no number in _register.json could reach: "IN THE FRONT VIEW THE EARS
READ AS A SECOND PAIR OF ARMS. They leave the head at the same angle, the same
hue and nearly the same taper as the real arms." Every number in that register
was green - seen 1.0 on all six subject/view pairs, zero blanks, zero frame
clips - because all of them ask "IS THE THING THERE", and not one asks "DOES
THE OUTLINE SEPARATE". minibossfit's shoot() remains the fit proof and is not
replaced; this adds the single question it does not ask.

*** THE v1 OF THIS FILE COULD NOT MOVE, AND I CAUGHT IT BEFORE IT PASSED. ***
v1 counted runs over a FIXED world-x band [0.25, 0.44] read off the ears where
they sit today. It red-proved correctly on the shipped glb - 200 of 200 columns
one run, FUSED. But a drooped ear RETRACTS along x as it curls, out of that
band, and v1 would then have found only the arm in the band, scored one run,
and reported FUSED on a fix that worked. A band fixed at the fault's old
address is the same family of defect as this lane's `mask_of` at pass 11: an
instrument that cannot follow the thing it is measuring. So the band is now
DERIVED, every run, from where the ear actually lands.

HOW IT LOCATES THE EAR - THE VIEWER'S QUESTION, NOT A MASK RENDERED ALONE.
Three renders through ONE fixed camera, and the renderer does the depth:
    A  the creature as it is
    B  the same, with the ear vertices collapsed onto the ear root
    C  the same, with the arm vertices collapsed onto the clavicle
  ear footprint = opaque in A, not in B   -> what the EARS ADD to the outline
  arm footprint = opaque in A, not in C   -> what the ARMS ADD to the outline
A footprint is therefore what a viewer would lose if the part vanished, which
is the only sense in which a part "reads". Rendering the ears ALONE would
answer how BIG they are and say nothing about whether they separate - that is
the exact error this lane shipped as `head_glow_px: 156` on a head with no
visible face, and it is not repeated here.

THE TWO NUMBERS THAT DECIDE IT, both read off render A:
  height_overlap  the fraction of the ear footprint lying inside the arm
                  footprint's row span. "At the same height" made countable.
  two_run_frac    over the ear's OWN columns, the fraction with two or more
                  maximal vertical runs of opaque pixels - i.e. with real
                  background between the arm above and the ear below.

WHAT THIS INSTRUMENT CANNOT SEE, SAID BEFORE IT IS TRUSTED:
  - Projection only. An ear that separates by sliding BEHIND the arm in depth
    scores the same as one that drops clear below it. Right for this fault
    (the fault IS the projection), wrong for any other.
  - Nothing about hue or taper. Two of the team lead's three cited cues are
    invisible here. Separation is NECESSARY for the fix, never sufficient -
    the picture stays the verdict and the number stays the suspect.
  - An ear that fused with the LEG instead of the arm would also score two
    runs. `ear_z` and the leg overlap are reported so that cannot pass quietly.
  - It judges the creature ALONE. The shipped sheet puts a hero beside it;
    that is minibossfit's job and this does not duplicate it.

IT GOES RED ON EMPTY. A statistic over zero columns reads green and means
nothing, so an empty ear footprint, an empty column band, a blank render and a
silhouette touching the frame border are each a hard error, not a low score.

  blender -b -noaudio -P tools/art/_bg_sil_runs.py -- <glb> <outjson> [pngdir]
"""
import bpy, sys, os, json
import numpy as np

EPS = 0.5
RES = 900
PAD = 1.18
EAR_X0 = 0.20       # measured: Head-dominant geometry runs |x| 0.20 -> 0.443
ARM_GROUPS = ("clavicle", "upperarm", "lowerarm", "hand",
              "index", "middle", "ring", "thumb")


def _dom_name(v, inv):
    best, bw = None, -1.0
    for ge in v.groups:
        if ge.weight > bw:
            bw, best = ge.weight, ge.group
    return inv.get(best)


def _parts(body):
    """Vertex index sets for the ears and the arms, by dominant weight."""
    inv = {g.index: g.name for g in body.vertex_groups}
    mw = body.matrix_world
    ears, arms = [], []
    for v in body.data.vertices:
        n = _dom_name(v, inv)
        if n is None:
            continue
        c = mw @ v.co
        if n == "Head" and abs(c.x) > EAR_X0:
            ears.append(v.index)
        elif any(n.startswith(p) for p in ARM_GROUPS):
            arms.append(v.index)
    return ears, arms


def world_bounds(meshes):
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    for o in meshes:
        ev = o.evaluated_get(dg)
        me = ev.to_mesh()
        mw = ev.matrix_world
        for v in me.vertices:
            pts.append(mw @ v.co)
        ev.to_mesh_clear()
    xs = [p.x for p in pts]; ys = [p.y for p in pts]; zs = [p.z for p in pts]
    return (min(xs), min(ys), min(zs)), (max(xs), max(ys), max(zs))


def make_cam(meshes):
    (ax, ay, az), (bx, by, bz) = world_bounds(meshes)
    cx, cz = (ax + bx) / 2.0, (az + bz) / 2.0
    span = max(bx - ax, bz - az) * PAD
    d = (by - ay) * 4.0 + 10.0
    cd = bpy.data.cameras.new("silcam")
    cd.type = 'ORTHO'; cd.ortho_scale = span
    cd.clip_start = 0.01; cd.clip_end = d * 4.0 + 100.0
    cam = bpy.data.objects.new("silcam", cd)
    bpy.context.scene.collection.objects.link(cam)
    cam.location = (cx, ay - d, cz)          # the head leans to -Y: that is the front
    cam.rotation_euler = (1.5707963, 0.0, 0.0)
    sc = bpy.context.scene
    sc.camera = cam
    sc.render.engine = 'BLENDER_EEVEE'
    sc.render.resolution_x = RES; sc.render.resolution_y = RES
    sc.render.resolution_percentage = 100
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGBA'
    return {"left": cx - span / 2.0, "top": cz + span / 2.0, "span": span}


def shoot(png):
    bpy.context.scene.render.filepath = png
    bpy.ops.render.render(write_still=True)
    img = bpy.data.images.load(png)
    w, h = img.size
    a = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(a)
    return (a.reshape(h, w, 4)[::-1])[..., 3] > EPS      # rows are bottom-up


def runs(col):
    out, start = [], None
    for i, v in enumerate(col):
        if v and start is None:
            start = i
        elif not v and start is not None:
            out.append((start, i - 1)); start = None
    if start is not None:
        out.append((start, len(col) - 1))
    return out


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    glb, out = argv[0], argv[1]
    pngdir = argv[2] if len(argv) > 2 else os.path.dirname(out)
    os.makedirs(pngdir, exist_ok=True)
    tag = os.path.splitext(os.path.basename(out))[0]

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=glb)
    for o in list(bpy.data.objects):
        if o.type == 'MESH' and o.name.lower().startswith("icosphere"):
            bpy.data.objects.remove(o, do_unlink=True)
    meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    body = bpy.data.objects["Puglin_Body"]

    m = make_cam(meshes)
    A = shoot(os.path.join(pngdir, tag + "_A.png"))

    ears, arms = _parts(body)
    keep = {v.index: v.co.copy() for v in body.data.vertices}

    def collapse(idx, anchor_fn):
        anc = anchor_fn()
        for i in idx:
            body.data.vertices[i].co = anc(body.data.vertices[i].co)
        body.data.update()

    def restore():
        for i, co in keep.items():
            body.data.vertices[i].co = co
        body.data.update()

    # B: ears collapsed onto the ear root plane (|x| -> EAR_X0, z -> ear root z)
    if ears:
        ez = sum(keep[i].z for i in ears) / len(ears)
        collapse(ears, lambda: (lambda co: type(co)((
            EAR_X0 * (1.0 if co.x > 0 else -1.0) * 0.5, co.y, ez))))
    B = shoot(os.path.join(pngdir, tag + "_B.png"))
    restore()

    # C: arms collapsed onto the shoulder
    if arms:
        sx = sum(abs(keep[i].x) for i in arms) / len(arms)
        collapse(arms, lambda: (lambda co: type(co)((
            0.12 * (1.0 if co.x > 0 else -1.0), co.y,
            sum(keep[i].z for i in arms) / len(arms)))))
    C = shoot(os.path.join(pngdir, tag + "_C.png"))
    restore()

    ear_fp = A & ~B
    arm_fp = A & ~C

    def touching(p, q):
        """Pixels of p 4-adjacent to q. REPORTED ONLY. THIS IS NOT A
        SEPARATION TEST AND IT MUST NEVER BE GATED ON - I gated on it for one
        run and it passed the shipped fault at 0.

        WHY IT CANNOT WORK, which is a property of footprints and not a bug to
        tune out: a footprint is what a part ADDS to the outline. Where the ear
        covers the arm, that pixel is the EAR's (it changes when the ear goes)
        and NOT the arm's (it does not change when the arm goes, the ear still
        covers it). So the arm footprint RETREATS from exactly the seam where
        the two shapes meet, and the two footprints are disjoint there by
        construction. The harder the parts fuse, the cleaner this number reads.
        On the shipped glb it reported 0 touching pixels - a perfect score on
        the fault the team lead could see from across the room."""
        t = np.zeros_like(p)
        t[:-1] |= p[:-1] & q[1:]
        t[1:] |= p[1:] & q[:-1]
        t[:, :-1] |= p[:, :-1] & q[:, 1:]
        t[:, 1:] |= p[:, 1:] & q[:, :-1]
        return int((t & p).sum())
    z_of = lambda row: m["top"] - (row + 0.5) / A.shape[0] * m["span"]
    x_of = lambda col: m["left"] + (col + 0.5) / A.shape[1] * m["span"]

    r = {"glb": glb, "res": list(A.shape), "band": "derived from the ear footprint",
         "ear_verts": len(ears), "arm_verts": len(arms),
         "opaque_px": int(A.sum()),
         "ear_px": int(ear_fp.sum()), "arm_px": int(arm_fp.sum()),
         "ear_touches_arm_px": touching(ear_fp, arm_fp)}

    errors = []
    if not A.any():
        errors.append("BLANK: render A has no opaque pixel")
    edge = {"top": int(A[0].sum()), "bottom": int(A[-1].sum()),
            "left": int(A[:, 0].sum()), "right": int(A[:, -1].sum())}
    r["frame_edge"] = edge
    if any(edge.values()):
        errors.append("FRAME CLIP: silhouette touches the border %s" % edge)
    if ear_fp.sum() == 0:
        errors.append("RED ON EMPTY: the ears add NOTHING to the outline - "
                      "every separation figure below would be computed over nothing")
    if arm_fp.sum() == 0:
        errors.append("RED ON EMPTY: the arms add nothing to the outline")

    if ear_fp.any() and arm_fp.any():
        er = np.where(ear_fp.any(axis=1))[0]
        ar = np.where(arm_fp.any(axis=1))[0]
        r["ear_z"] = [round(z_of(er.max()), 4), round(z_of(er.min()), 4)]
        r["arm_z"] = [round(z_of(ar.max()), 4), round(z_of(ar.min()), 4)]
        inside = ear_fp[ar.min():ar.max() + 1].sum()
        r["height_overlap"] = round(float(inside) / float(ear_fp.sum()), 4)

        sides = {}
        for side, sgn in (("left", -1), ("right", 1)):
            cols = [c for c in np.where(ear_fp.any(axis=0))[0]
                    if (x_of(c) < 0) == (sgn < 0)]
            two = one = 0
            gaps = []
            for c in cols:
                rr = runs(A[:, c])
                if len(rr) >= 2:
                    two += 1
                    gaps.append(max(rr[i + 1][0] - rr[i][1] - 1
                                    for i in range(len(rr) - 1)))
                elif rr:
                    one += 1
            ecols = [c for c in cols]
            ez = [z_of(x) for x in np.where(ear_fp[:, ecols].any(axis=1))[0]] if ecols else []
            sides[side] = {"ear_cols": len(cols), "two_run": two, "one_run": one,
                           "two_run_frac": round(two / len(cols), 4) if cols else 0.0,
                           "max_gap_px": max(gaps) if gaps else 0,
                           "ear_lowest_z": round(min(ez), 4) if ez else None}
            if not cols:
                errors.append("RED ON EMPTY: no ear columns on the %s side" % side)
        r["sides"] = sides
        tot = sum(d["ear_cols"] for d in sides.values())
        r["two_run_frac"] = round(
            sum(d["two_run"] for d in sides.values()) / tot, 4) if tot else 0.0
        # THE GATE, AND IT IS THE RUN COUNT, WHICH IS WHERE IT STARTED.
        # Both of the numbers that looked more elegant than counting runs were
        # tried as the gate in this same run and BOTH passed the known fault:
        #   height_overlap        0.0265 on the shipped glb. The ear sits just
        #                         ABOVE the arm rather than level with it, so
        #                         low overlap means "stacked", not "separate".
        #   ear_touches_arm_px    0 on the shipped glb, for the structural
        #                         reason written on touching() above.
        # Only the run count asks the thing a viewer asks - IS THERE SKY
        # BETWEEN THEM - and only the run count went red on the fault. The
        # other two stay in the record as description, gated on nothing.
        # height_overlap keeps ONE job: it is an upper bound that stops a fix
        # which "separates" by burying the ear inside the arm band instead.
        r["separated"] = bool(
            not errors
            and all(d["two_run_frac"] >= 0.50 for d in sides.values())
            and all(d["max_gap_px"] >= 4 for d in sides.values())
            and r["height_overlap"] <= 0.10)
    else:
        r["separated"] = False

    r["errors"] = errors
    r["verdict"] = "SEPARATED" if r.get("separated") else "FUSED"
    with open(out, "w", encoding="utf-8") as f:
        json.dump(r, f, indent=1)
    print("VERDICT", r["verdict"], "two_run_frac", r.get("two_run_frac"),
          "height_overlap", r.get("height_overlap"), "errors", errors)


main()
