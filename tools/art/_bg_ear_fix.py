"""_bg_ear_fix.py - CANDIDATE EAR DEFORMS FOR BROODGLUT, FOR THE EYE TO CHOOSE.

THE FAULT, as the team lead wrote it after looking at the shipped sheet:
"IN THE FRONT VIEW THE EARS READ AS A SECOND PAIR OF ARMS. They leave the head
at the same angle, the same hue and nearly the same taper as the real arms."
Measured by _bg_sil_runs.py on the shipped glb: 234 of 234 ear columns carry a
SINGLE vertical run - the ear's visible outline rests flush on the arm's upper
edge with no background anywhere between them.

THE EARS HAVE NO BONE. The pack's rig is 55 bones and not one is an ear; all
1531 head-and-ear vertices are weighted to `Head`. So this cannot be a pose and
has to be geometry, and it is applied to the pack author's vertices rather than
modelled new - the class's whole saving is that no triangle here is ours.

THE DEFORM. The ear is parametrised by arc length s outward from the measured
root at |x| = 0.20, and carried along a circular arc whose tangent turns
smoothly from 0 to the requested angle. Arc length is preserved, so the ear
keeps its own length and taper and only its DIRECTION changes - one thing at a
time, which is the standing rule here.
  pitch  turns the ear in the x-z plane. Negative drops the tip toward the feet.
  yaw    turns it in the x-y plane. Positive sweeps it back behind the skull.
A rigid hinge at the root would crease the mesh where ear meets head; the
tangent is therefore ramped over the first fifth of the ear so the root keeps
its original direction and the bend is distributed.

  blender -b -noaudio -P tools/art/_bg_ear_fix.py -- <glb> <outdir> \
      <name>:<pitch>:<yaw> [<name>:<pitch>:<yaw> ...]
Writes <outdir>/<name>.glb and a front/side/back contact sheet per candidate.
"""
import bpy, sys, os, math, json
import numpy as np

EAR_X0 = 0.20
RAMP = 0.20          # the turn reaches full angle within this much of the ear


def ear_indices(body):
    inv = {g.index: g.name for g in body.vertex_groups}
    mw = body.matrix_world
    out = []
    for v in body.data.vertices:
        best, bw = None, -1.0
        for ge in v.groups:
            if ge.weight > bw:
                bw, best = ge.weight, ge.group
        if inv.get(best) == "Head" and abs((mw @ v.co).x) > EAR_X0:
            out.append(v.index)
    return out


def deform(body, idx, pitch_deg, yaw_deg):
    """Turn the ear about its own root and carry it along the resulting arc.

    *** THE FIRST VERSION OF THIS FUNCTION COULD NOT MOVE THE EAR, AND THE
    *** NUMBERS SAID SO BEFORE ANY PICTURE DID. At yaw 55 deg the tip
    travelled 0.089 on a 0.243-long ear and span_y did not change at all,
    because the turn was ramped from zero across the WHOLE ear: the thing bent
    gently and pointed almost where it started. A deform whose strongest
    setting barely displaces its subject is this lane's "instrument that cannot
    move" wearing the other hat - it would have produced four candidate sheets
    that all looked alike and invited the conclusion that no deform helps.
    The turn now reaches its full angle within the first `RAMP` of the ear and
    holds it, so the outer four-fifths rotate rigidly and only the root blends.

    The cross-section is carried on the arc's own frame - tangent plus the two
    normals - so the flap rotates with the ear instead of shearing flat, which
    the first version did by scaling z with cos(pitch).

      pitch  positive lifts the tip, negative drops it toward the feet
      yaw    positive sweeps it back behind the skull (the head leans to -Y)
    """
    if not idx:
        return {"moved": 0}
    co = {i: body.data.vertices[i].co.copy() for i in idx}
    L = max(abs(c.x) - EAR_X0 for c in co.values())
    if L <= 1e-6:
        return {"moved": 0}
    P, Y = math.radians(pitch_deg), math.radians(yaw_deg)

    # the ear's own axis at the root, measured off the vertices nearest it
    near = [c for c in co.values() if abs(c.x) - EAR_X0 < 0.15 * L]
    if not near:
        near = list(co.values())
    y_r = sum(c.y for c in near) / len(near)
    z_r = sum(c.z for c in near) / len(near)

    def turn(u):
        """Fraction of the full angle at normalised arc position u."""
        if u >= RAMP:
            return 1.0
        t = u / RAMP
        return t * t * (3.0 - 2.0 * t)      # smoothstep: no crease at the root

    N = 240
    du = 1.0 / N
    arc = [(0.0, 0.0, 0.0)]
    for k in range(N):
        u = (k + 0.5) * du
        t = turn(u)
        ap, ay = P * t, Y * t
        x, y, z = arc[-1]
        arc.append((x + math.cos(ap) * math.cos(ay) * du * L,
                    y + math.cos(ap) * math.sin(ay) * du * L,
                    z + math.sin(ap) * du * L))

    for i, c in co.items():
        sgn = 1.0 if c.x > 0 else -1.0
        s = min(1.0, max(0.0, (abs(c.x) - EAR_X0) / L))
        k = int(round(s * N))
        t = turn(s)
        ap, ay = P * t, Y * t
        # the arc frame at this station: tangent and its two normals
        n1 = (-math.sin(ay), math.cos(ay), 0.0)
        n2 = (-math.sin(ap) * math.cos(ay), -math.sin(ap) * math.sin(ay), math.cos(ap))
        oy, oz = c.y - y_r, c.z - z_r
        ax_, ay_, az_ = arc[k]
        nx = EAR_X0 + ax_ + oy * n1[0] + oz * n2[0]
        ny = y_r + ay_ + oy * n1[1] + oz * n2[1]
        nz = z_r + az_ + oy * n1[2] + oz * n2[2]
        body.data.vertices[i].co = type(c)((sgn * nx, ny, nz))
    body.data.update()
    return {"moved": len(co), "ear_len": round(L, 4),
            "root": [EAR_X0, round(y_r, 4), round(z_r, 4)],
            "tip_centreline": [round(EAR_X0 + arc[-1][0], 4),
                               round(y_r + arc[-1][1], 4),
                               round(z_r + arc[-1][2], 4)]}


def bounds(meshes):
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    for o in meshes:
        ev = o.evaluated_get(dg)
        me = ev.to_mesh()
        for v in me.vertices:
            pts.append(ev.matrix_world @ v.co)
        ev.to_mesh_clear()
    xs = [p.x for p in pts]; ys = [p.y for p in pts]; zs = [p.z for p in pts]
    return (min(xs), min(ys), min(zs)), (max(xs), max(ys), max(zs))


def sheet(meshes, outpng, res=560):
    """Front / side / back of the creature alone, one row, for the eye."""
    (ax, ay, az), (bx, by, bz) = bounds(meshes)
    cx, cy, cz = (ax+bx)/2.0, (ay+by)/2.0, (az+bz)/2.0
    span = max(bx-ax, by-ay, bz-az) * 1.25
    d = span * 4.0 + 10.0
    sc = bpy.context.scene
    sc.render.engine = 'BLENDER_EEVEE'
    sc.render.resolution_x = res; sc.render.resolution_y = res
    sc.render.resolution_percentage = 100
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = 'PNG'
    sc.render.image_settings.color_mode = 'RGBA'
    cd = bpy.data.cameras.new("c"); cd.type='ORTHO'; cd.ortho_scale=span
    cd.clip_start=0.01; cd.clip_end=d*4.0+100.0
    cam = bpy.data.objects.new("c", cd)
    sc.collection.objects.link(cam); sc.camera = cam
    tiles = []
    for name, ang in (("front",0.0), ("side",90.0), ("back",180.0)):
        th = math.radians(ang)
        cam.location = (cx + math.sin(th)*d, cy - math.cos(th)*d, cz)
        cam.rotation_euler = (math.radians(90.0), 0.0, th)
        tmp = outpng.replace(".png", "_%s.png" % name)
        sc.render.filepath = tmp
        bpy.ops.render.render(write_still=True)
        img = bpy.data.images.load(tmp)
        w,h = img.size
        a = np.empty(w*h*4, dtype=np.float32); img.pixels.foreach_get(a)
        tiles.append(a.reshape(h,w,4)[::-1])
    strip = np.concatenate(tiles, axis=1)
    # flatten onto a pale ground so the outline is unambiguous to the eye
    bg = np.ones_like(strip); bg[...,:3] = 0.93
    al = strip[...,3:4]
    comp = strip[...,:3]*al + bg[...,:3]*(1.0-al)
    outa = np.concatenate([comp, np.ones_like(al)], axis=2)
    oi = bpy.data.images.new("sheet", width=strip.shape[1], height=strip.shape[0], alpha=True)
    oi.pixels.foreach_set(outa[::-1].ravel())
    oi.filepath_raw = outpng; oi.file_format='PNG'; oi.save()
    return outpng, int((strip[...,3] > 0.5).sum())


def main():
    argv = sys.argv[sys.argv.index("--")+1:]
    glb, outdir = argv[0], argv[1]
    specs = argv[2:]
    os.makedirs(outdir, exist_ok=True)
    rep = []
    for spec in specs:
        name, pitch, yaw = spec.split(":")
        pitch, yaw = float(pitch), float(yaw)
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.gltf(filepath=glb)
        for o in list(bpy.data.objects):
            if o.type=='MESH' and o.name.lower().startswith("icosphere"):
                bpy.data.objects.remove(o, do_unlink=True)
        body = bpy.data.objects["Puglin_Body"]
        idx = ear_indices(body)
        d = deform(body, idx, pitch, yaw)
        meshes = [o for o in bpy.data.objects if o.type=='MESH']
        roots = [o for o in bpy.data.objects if o.parent is None]
        mn, mx = bounds(meshes)
        png, opq = sheet(meshes, os.path.join(outdir, name + ".png"))
        out = os.path.join(outdir, name + ".glb")
        for o in bpy.data.objects:
            o.select_set(False)
        for o in bpy.data.objects:
            if o.type in ('MESH','ARMATURE'):
                o.select_set(True)
        bpy.ops.export_scene.gltf(filepath=out, export_format='GLB',
                                  use_selection=True, export_apply=False,
                                  export_animations=False)
        rep.append({"name": name, "pitch": pitch, "yaw": yaw, "ear_verts": len(idx),
                    "deform": d, "sheet": png, "sheet_opaque_px": opq,
                    "glb": out, "bytes": os.path.getsize(out),
                    "span_x": round(mx[0]-mn[0],4), "span_y": round(mx[1]-mn[1],4),
                    "height": round(mx[2]-mn[2],4)})
        print("CAND", name, rep[-1]["deform"], "span_x", rep[-1]["span_x"])
    with open(os.path.join(outdir, "_candidates.json"), "w", encoding="utf-8") as f:
        json.dump(rep, f, indent=1)


main()
