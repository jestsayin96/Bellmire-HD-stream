"""lordlib - primitive mesh library for Bellmire's procedural art (D75/D76).

Everything here is built from raw vertex maths on purpose: no bpy.ops, no
bmesh.ops, so nothing depends on operator context or on argument names that
drift between Blender versions. Runs inside headless Blender only.

Original geometry. No third-party asset is read by this module (CC0 constraint:
Quaternius Bestiary / QAL is forbidden on this project, so shapes are generated).
"""
import math
import bpy
from mathutils import Vector, Matrix

TAU = math.pi * 2.0


# ---------------------------------------------------------------- object make
def make(name, verts, faces, mat=None, coll=None):
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], faces)
    me.validate(verbose=False)
    me.update()
    if mat is not None:
        me.materials.append(mat)
    ob = bpy.data.objects.new(name, me)
    (coll or bpy.context.collection).objects.link(ob)
    return ob


def xform(verts, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1)):
    """Apply scale, then XYZ-euler rotation, then translation, to a vert list."""
    m = (Matrix.Translation(Vector(loc))
         @ Matrix.Rotation(rot[2], 4, 'Z')
         @ Matrix.Rotation(rot[1], 4, 'Y')
         @ Matrix.Rotation(rot[0], 4, 'X')
         @ Matrix.Diagonal(Vector(scale).to_4d()))
    return [m @ Vector(v) for v in verts]


# ------------------------------------------------------------------ primitives
def sphere(rx, ry, rz, seg=18, rings=12):
    """Ellipsoid as a UV sphere. rings counts the latitude bands."""
    verts = [Vector((0, 0, rz))]
    for i in range(1, rings):
        phi = math.pi * i / rings
        sp, cp = math.sin(phi), math.cos(phi)
        for j in range(seg):
            th = TAU * j / seg
            verts.append(Vector((rx * sp * math.cos(th), ry * sp * math.sin(th), rz * cp)))
    verts.append(Vector((0, 0, -rz)))
    last = len(verts) - 1
    faces = []
    for j in range(seg):
        faces.append((0, 1 + j, 1 + (j + 1) % seg))
    for i in range(rings - 2):
        a = 1 + i * seg
        b = a + seg
        for j in range(seg):
            j2 = (j + 1) % seg
            faces.append((a + j, b + j, b + j2, a + j2))
    a = 1 + (rings - 2) * seg
    for j in range(seg):
        faces.append((last, a + (j + 1) % seg, a + j))
    return verts, faces


def box(sx, sy, sz):
    hx, hy, hz = sx / 2.0, sy / 2.0, sz / 2.0
    verts = [Vector(v) for v in (
        (-hx, -hy, -hz), (hx, -hy, -hz), (hx, hy, -hz), (-hx, hy, -hz),
        (-hx, -hy, hz), (hx, -hy, hz), (hx, hy, hz), (-hx, hy, hz))]
    faces = [(0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4),
             (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)]
    return verts, faces


def cone(r1, r2, h, seg=14, cap=True):
    """Tapered cylinder along +Z, base at z=0. r2==0 gives a spike."""
    verts, faces = [], []
    for j in range(seg):
        th = TAU * j / seg
        verts.append(Vector((r1 * math.cos(th), r1 * math.sin(th), 0.0)))
    top0 = len(verts)
    if r2 <= 1e-6:
        verts.append(Vector((0, 0, h)))
        tip = len(verts) - 1
        for j in range(seg):
            faces.append((j, (j + 1) % seg, tip))
    else:
        for j in range(seg):
            th = TAU * j / seg
            verts.append(Vector((r2 * math.cos(th), r2 * math.sin(th), h)))
        for j in range(seg):
            j2 = (j + 1) % seg
            faces.append((j, j2, top0 + j2, top0 + j))
        if cap:
            faces.append(tuple(range(top0, top0 + seg))[::-1])
    if cap:
        faces.append(tuple(range(seg)))
    return verts, faces


def scone(r1, r2, h, seg=14, s1=0.0, s2=0.0, cap=True):
    """A cone whose rings are OFF-CIRCLE: radius r(th) = r * (1 + s*cos th).

    cos has mean zero over a full turn, so THE MEAN RADIUS IS EXACTLY r AND
    THE SKEW ADDS NO GIRTH ON AVERAGE - it only moves girth from the -X side
    of the ring to the +X side. That is the whole point: D94's "dinner plates"
    failure came from a bigger mouth, and this is a bigger mouth on ONE SIDE
    only, paid for on the other.
    """
    verts, faces = [], []
    for j in range(seg):
        th = TAU * j / seg
        rr = r1 * (1.0 + s1 * math.cos(th))
        verts.append(Vector((rr * math.cos(th), rr * math.sin(th), 0.0)))
    top0 = len(verts)
    for j in range(seg):
        th = TAU * j / seg
        rr = r2 * (1.0 + s2 * math.cos(th))
        verts.append(Vector((rr * math.cos(th), rr * math.sin(th), h)))
    for j in range(seg):
        j2 = (j + 1) % seg
        faces.append((j, j2, top0 + j2, top0 + j))
    if cap:
        faces.append(tuple(range(top0, top0 + seg))[::-1])
        faces.append(tuple(range(seg)))
    return verts, faces


# ----------------------------------------------------------------- swept tube
def _frames(pts):
    n = len(pts)
    tans = []
    for i in range(n):
        if i == 0:
            t = pts[1] - pts[0]
        elif i == n - 1:
            t = pts[-1] - pts[-2]
        else:
            t = pts[i + 1] - pts[i - 1]
        if t.length < 1e-9:
            t = Vector((0, 0, 1))
        tans.append(t.normalized())
    ref = tans[0].cross(Vector((0, 0, 1)))
    if ref.length < 1e-5:
        ref = tans[0].cross(Vector((0, 1, 0)))
    ref.normalize()
    out = []
    for t in tans:
        r = ref - t * ref.dot(t)
        if r.length < 1e-6:
            r = t.cross(Vector((0, 0, 1)))
            if r.length < 1e-6:
                r = t.cross(Vector((0, 1, 0)))
        r.normalize()
        s = t.cross(r).normalized()
        out.append((r, s))
        ref = r
    return out


def tube(pts, radii, ring=10, caps=True):
    """Sweep a circular cross-section along a polyline. radii is a float or a
    per-point list. Used for limbs, ribs, serpent bodies, horns, flames."""
    pts = [Vector(p) for p in pts]
    if not hasattr(radii, '__len__'):
        radii = [float(radii)] * len(pts)
    fr = _frames(pts)
    verts, faces = [], []
    for i, p in enumerate(pts):
        r, s = fr[i]
        R = radii[i]
        for j in range(ring):
            th = TAU * j / ring
            verts.append(p + r * (R * math.cos(th)) + s * (R * math.sin(th)))
    for i in range(len(pts) - 1):
        a, b = i * ring, (i + 1) * ring
        for j in range(ring):
            j2 = (j + 1) % ring
            faces.append((a + j, b + j, b + j2, a + j2))
    if caps:
        faces.append(tuple(range(ring))[::-1])
        a = (len(pts) - 1) * ring
        faces.append(tuple(range(a, a + ring)))
    return verts, faces


def membrane(pts, thickness=0.04):
    """A flat panel from an ordered loop of 3D points, thickened along the
    loop's own normal. Wings, cloaks, collar fans, frost sheets."""
    pts = [Vector(p) for p in pts]
    c = sum(pts, Vector()) / len(pts)
    n = Vector()
    for i in range(len(pts)):
        a, b = pts[i] - c, pts[(i + 1) % len(pts)] - c
        n += a.cross(b)
    if n.length < 1e-9:
        n = Vector((0, 1, 0))
    n = n.normalized() * (thickness / 2.0)
    verts = [p + n for p in pts] + [p - n for p in pts]
    k = len(pts)
    faces = [tuple(range(k)), tuple(range(k, 2 * k))[::-1]]
    for i in range(k):
        i2 = (i + 1) % k
        faces.append((i, i2, k + i2, k + i))
    return verts, faces


def helix(turns, z0, z1, r0, r1, steps=None, phase=0.0, wobble=0.0):
    """Points up a tapering helix. The lords' serpent bodies ride this."""
    steps = steps or max(24, int(turns * 24))
    pts = []
    for i in range(steps + 1):
        t = i / steps
        a = phase + TAU * turns * t
        r = r0 + (r1 - r0) * t
        z = z0 + (z1 - z0) * t
        if wobble:
            r += math.sin(a * 3.0) * wobble
        pts.append(Vector((r * math.cos(a), r * math.sin(a), z)))
    return pts


def lerp_list(a, b, n):
    return [a + (b - a) * (i / max(1, n - 1)) for i in range(n)]


# ------------------------------------------------------------------ materials
def _set_input(node, names, value):
    for nm in names:
        if nm in node.inputs:
            try:
                node.inputs[nm].default_value = value
                return True
            except Exception:
                pass
    return False


def mat_solid(name, rgb, rough=0.55, metal=0.08, spec=None):
    """spec, when given, sets the Principled SPECULAR IOR LEVEL - the strength of
    the DIELECTRIC lobe, which is white by construction because a dielectric's
    specular reflection carries the LIGHT's colour and not the surface's. Left
    None it is not touched at all, so every existing caller and every other body
    renders byte-identically. Added 17 Nov for the Greener's copper: see
    tools/art/_metal_read.py for why a tinted METALLIC lobe cannot produce a
    white highlight and so cannot read as polished metal under bare suns."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None)
    if bsdf is None:
        bsdf = nt.nodes.new('ShaderNodeBsdfPrincipled')
        out = next((n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL'), nt.nodes.new('ShaderNodeOutputMaterial'))
        nt.links.new(bsdf.outputs[0], out.inputs[0])
    _set_input(bsdf, ['Base Color'], (rgb[0], rgb[1], rgb[2], 1.0))
    _set_input(bsdf, ['Roughness'], rough)
    _set_input(bsdf, ['Metallic'], metal)
    if spec is not None:
        _set_input(bsdf, ['Specular IOR Level', 'Specular'], spec)
    m.diffuse_color = (rgb[0], rgb[1], rgb[2], 1.0)
    return m


def mat_glow(name, rgb, strength=4.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    for n in list(nt.nodes):
        if n.type != 'OUTPUT_MATERIAL':
            nt.nodes.remove(n)
    out = next((n for n in nt.nodes if n.type == 'OUTPUT_MATERIAL'), None) or nt.nodes.new('ShaderNodeOutputMaterial')
    em = nt.nodes.new('ShaderNodeEmission')
    em.inputs['Color'].default_value = (rgb[0], rgb[1], rgb[2], 1.0)
    em.inputs['Strength'].default_value = strength
    nt.links.new(em.outputs[0], out.inputs[0])
    m.diffuse_color = (rgb[0], rgb[1], rgb[2], 1.0)
    return m
