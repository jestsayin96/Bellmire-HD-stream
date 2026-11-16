"""creatures.py - D76: the twelve creatures that were another creature with a label.

Measured on 15 Nov (docs/art/D76_SCOPE.md): WORK_PLAN's "~109 families share 10
models" does not reproduce. bestiary.gd holds 30 creature types on 18 distinct
models, and exactly TWELVE types are a second label on a body that already
belongs to another type. Those twelve are built here - a body of their own,
the way the eight lords got one in D75 - not a parametric system for 109.

Each of the twelve already differs from its stablemate in HEIGHT, TINT and
WEAPON (L27a did that). What none of them had was a different SHAPE. So the one
rule every builder here answers to: the thing must be identifiable from its
OUTLINE ALONE, with the colour thrown away, and must not read as the creature
it used to share a mesh with.

  sentinel   a door, not a swordsman        bowman     a wide low cross
  hewer      top-heavy, one huge shoulder   cutthroat  an arrow, leaning
  gravecaller a pillar ringed with stones   silkmother a dome on tall stilts
  spiderling  a flat star on the floor      slimeling  a splat, not a blob
  gloombat   a cowl of forward-swept wing   scarrat    a humped comma
  fenlurker  a mouth with a frog behind it  pitwyrm    an S with no wings

Raw vertex maths only (no bpy.ops, no bmesh.ops) - see lordlib. Original
geometry: nothing here reads a third-party asset. Quaternius Bestiary / QAL is
forbidden on this project, which is why these are generated and not bought.
"""
import math
import random

from mathutils import Vector, Matrix

import lordlib as L
from lords import Parts, aim, _skull

TAU = math.pi * 2.0

# key: (title, height(m), tint, aura, note, shares_with)
# height/tint/aura mirror bestiary.gd TYPES/NEW_TYPES; the note is the line the
# contact sheet carries, and shares_with is the mesh this body replaces.
CANON = {
    "sentinel":   ("Bone Sentinel", 1.9, (0.90, 0.89, 0.82), (0.70, 0.78, 0.92),
                   "it does not advance, it closes the way", "Skeleton_Warrior.glb"),
    "hewer":      ("Marrow Hewer", 1.85, (0.88, 0.84, 0.74), (1.00, 0.72, 0.40),
                   "it swings at the height of a man's neck", "Skeleton_Warrior.glb"),
    "bowman":     ("Bone Bowman", 1.6, (0.88, 0.88, 0.80), (0.75, 0.86, 0.96),
                   "it is already aiming when you see it", "Skeleton_Minion.glb"),
    "cutthroat":  ("Pale Cutthroat", 1.6, (0.90, 0.86, 0.96), (0.45, 0.25, 0.85),
                   "it comes at the knees and leaves at a run", "Skeleton_Rogue.glb"),
    "gravecaller": ("Gravecaller", 1.85, (0.80, 0.90, 0.76), (0.24, 1.00, 0.50),
                    "the floor answers it", "Skeleton_Mage.glb"),
    "silkmother": ("Silk Mother", 1.3, (0.45, 0.42, 0.50), (0.33, 1.00, 0.44),
                   "her brood spills off her back", "Spider.glb"),
    "spiderling": ("Spiderling", 0.35, (0.52, 0.50, 0.56), (0.40, 0.95, 0.50),
                   "there is never one", "Spider.glb"),
    "slimeling":  ("Slimeling", 0.5, (0.62, 0.90, 0.52), (0.55, 1.00, 0.40),
                   "it was part of something bigger", "Slime.glb"),
    "gloombat":   ("Gloom Bat", 1.2, (0.40, 0.36, 0.55), (0.54, 0.31, 1.00),
                   "it hunts in threes", "Bat.glb"),
    "scarrat":    ("Scar Rat", 0.8, (0.72, 0.88, 0.62), (0.40, 1.00, 0.24),
                   "not the size rats are meant to be", "Rat.glb"),
    "lurker":     ("Fen Lurker", 1.5, (0.45, 0.58, 0.40), (0.32, 1.00, 0.40),
                   "the water does not ripple before it", "Frog.glb"),
    "pitwyrm":    ("Pit Wyrm", 4.0, (0.70, 0.55, 0.45), (1.00, 0.33, 0.11),
                   "it has never had room to open its wings", "Dragon.glb"),
}
ORDER = ["sentinel", "hewer", "bowman", "cutthroat", "gravecaller", "silkmother",
         "spiderling", "slimeling", "gloombat", "scarrat", "lurker", "pitwyrm"]


# ------------------------------------------------------------------ helpers
def surf(grid, thick=0.03):
    """Thicken an open surface given as a grid of Vectors (ny rows x nx cols).

    The lords only ever needed flat panels (lordlib.membrane). Half the twelve
    need a CURVED one - a bowed tower shield, a wing cupped forward, a jaw -
    so this sweeps a quad grid and thickens it along per-vertex normals.
    """
    ny, nx = len(grid), len(grid[0])
    grid = [[Vector(p) for p in row] for row in grid]
    nrm = [[None] * nx for _ in range(ny)]
    for i in range(ny):
        for j in range(nx):
            du = grid[i][min(j + 1, nx - 1)] - grid[i][max(j - 1, 0)]
            dv = grid[min(i + 1, ny - 1)][j] - grid[max(i - 1, 0)][j]
            n = du.cross(dv)
            if n.length < 1e-9:
                n = Vector((0.0, 1.0, 0.0))
            nrm[i][j] = n.normalized()
    h = thick / 2.0
    verts = [grid[i][j] + nrm[i][j] * h for i in range(ny) for j in range(nx)]
    base = len(verts)
    verts += [grid[i][j] - nrm[i][j] * h for i in range(ny) for j in range(nx)]

    def ix(i, j):
        return i * nx + j

    faces = []
    for i in range(ny - 1):
        for j in range(nx - 1):
            faces.append((ix(i, j), ix(i, j + 1), ix(i + 1, j + 1), ix(i + 1, j)))
            faces.append((base + ix(i, j), base + ix(i + 1, j),
                          base + ix(i + 1, j + 1), base + ix(i, j + 1)))
    for j in range(nx - 1):
        faces.append((ix(0, j), ix(0, j + 1), base + ix(0, j + 1), base + ix(0, j)))
        faces.append((ix(ny - 1, j + 1), ix(ny - 1, j),
                      base + ix(ny - 1, j), base + ix(ny - 1, j + 1)))
    for i in range(ny - 1):
        faces.append((ix(i, 0), base + ix(i, 0), base + ix(i + 1, 0), ix(i + 1, 0)))
        faces.append((ix(i, nx - 1), ix(i + 1, nx - 1),
                      base + ix(i + 1, nx - 1), base + ix(i, nx - 1)))
    return verts, faces


def limb(P, pts, r0, r1=None, slot='bone', ring=8):
    """A tapering tube through a polyline. Legs, arms, tails, necks."""
    r1 = r0 if r1 is None else r1
    n = len(pts)
    radii = [r0 + (r1 - r0) * (i / max(1, n - 1)) for i in range(n)]
    P.raw(L.tube([Vector(p) for p in pts], radii, ring), slot)


def arc(a, b, lift, n=7, side=0.0):
    """Polyline from a to b bowed upward by `lift` (and sideways by `side`)."""
    a, b = Vector(a), Vector(b)
    out = []
    for i in range(n):
        t = i / (n - 1.0)
        p = a + (b - a) * t
        s = math.sin(math.pi * t)
        out.append(Vector((p.x + side * s, p.y, p.z + lift * s)))
    return out


def eyes(P, loc, sep, r, fwd, slot='glow'):
    for s in (-1, 1):
        P.add(L.sphere(r, r, r, 8, 6), slot,
              loc=(loc[0] + s * sep, loc[1] + fwd, loc[2]))


def spikes(P, pts, h0, h1, slot='bone', up=(0.0, 0.3, 1.0)):
    """A row of spikes along a polyline - dorsal ridges, bristles, rib halos."""
    n = len(pts)
    for i, p in enumerate(pts):
        t = i / max(1, n - 1.0)
        hh = h0 + (h1 - h0) * math.sin(math.pi * t) ** 0.6
        P.raw(aim(L.cone(hh * 0.22, 0.0, hh, 7), p, up), slot)


# ------------------------------------------------------- 1 BONE SENTINEL: a door
def sentinel():
    """Shares Skeleton_Warrior with the skeleton warrior and the marrow hewer.
    bestiary: h 1.9, ways {guard: 3}, large shield + blade, the slowest of the
    three. So it is not a swordsman at all - it is a doorway that walks. The
    tower shield IS the silhouette; the body is a rumour behind it."""
    P = Parts("sentinel")
    # legs: a wide braced stance, half-hidden, so the outline stands on a plinth
    for s in (-1, 1):
        limb(P, [(s * 0.17, 0.10, 0.92), (s * 0.26, 0.06, 0.50), (s * 0.34, -0.02, 0.06)],
             0.085, 0.065)
        P.add(L.box(0.26, 0.40, 0.09), 'bone', loc=(s * 0.34, -0.10, 0.045))
    # torso hunched down behind the shield, shoulders rolled forward
    limb(P, [(0.0, 0.14, 0.86), (0.0, 0.08, 1.20), (0.0, 0.02, 1.46)], 0.20, 0.25)
    for s in (-1, 1):   # shoulder blocks
        P.add(L.sphere(0.17, 0.15, 0.13, 12, 8), 'bone', loc=(s * 0.26, 0.02, 1.44))
    # helmet: just clears the shield rim, visor a single slit
    P.add(L.sphere(0.17, 0.19, 0.19, 14, 9), 'bone', loc=(0.0, 0.02, 1.70))
    P.add(L.box(0.30, 0.10, 0.07), 'dark', loc=(0.0, -0.14, 1.70))
    P.add(L.box(0.22, 0.05, 0.035), 'glow', loc=(0.0, -0.18, 1.70))
    P.add(aim(L.cone(0.055, 0.0, 0.26, 8), (0.0, 0.06, 1.86), (0.0, 0.25, 1.0)), 'bone')
    # TOWER SHIELD - bowed toward the viewer, 1.70 tall, 1.34 wide, planted
    rows, cols = 11, 9
    grid = []
    for i in range(rows):
        z = 0.03 + 1.74 * (i / (rows - 1.0))
        row = []
        for j in range(cols):
            u = -1.0 + 2.0 * (j / (cols - 1.0))
            w = 0.67 * (1.0 - 0.22 * max(0.0, (z - 1.30) / 0.47) ** 2)   # tapers at the top
            bow = -0.36 - 0.17 * (1.0 - u * u)
            row.append(Vector((u * w, bow, z)))
        grid.append(row)
    P.raw(surf(grid, 0.05), 'body')
    # boss, central rib and four rivets: iron on the face so it is not a blank board
    P.add(L.sphere(0.17, 0.10, 0.17, 14, 9), 'dark', loc=(0.0, -0.56, 0.92))
    P.add(L.box(0.10, 0.07, 1.62), 'dark', loc=(0.0, -0.50, 0.88))
    for z in (0.22, 0.60, 1.26, 1.62):
        for s in (-1, 1):
            P.add(L.sphere(0.045, 0.03, 0.045, 7, 5), 'dark', loc=(s * 0.50, -0.46, z))
    # the blade is an afterthought, low and tucked - it is not what you see
    P.raw(aim(L.box(0.07, 0.025, 0.86), (0.46, 0.22, 0.60), (0.18, 0.22, 1.0)), 'bone')
    return P


# -------------------------------------------- 2 MARROW HEWER: one huge shoulder
def hewer():
    """Shares Skeleton_Warrior with the warrior and the sentinel. bestiary:
    h 1.85, axe + small shield, atk 1.3, ways {pack: 1}. A butcher: everything
    is thrown into one side, so the outline is top-heavy and lopsided - a hook."""
    P = Parts("hewer")
    for s in (-1, 1):
        limb(P, [(s * 0.13, 0.04, 0.95), (s * 0.17, -0.04, 0.52), (s * 0.20, 0.02, 0.05)],
             0.070, 0.055)
        P.add(L.box(0.20, 0.36, 0.08), 'bone', loc=(s * 0.20, -0.08, 0.04))
    # a narrow ribcage leaning into the swing side
    limb(P, [(0.0, 0.0, 0.90), (0.06, -0.04, 1.24), (0.09, -0.10, 1.56)], 0.17, 0.21)
    for i, z in enumerate((1.02, 1.14, 1.26, 1.38)):
        rr = 0.21 - i * 0.012
        P.add(L.tube(arc((-rr, -0.02, z), (rr, -0.02, z), 0.0, 5, side=0.0), 0.028, 7), 'bone')
        P.add(L.sphere(rr * 1.05, 0.14, 0.022, 12, 5), 'bone', loc=(0.02, -0.06, z))
    # the right shoulder is a boulder; the left is barely there
    P.add(L.sphere(0.31, 0.28, 0.25, 14, 10), 'body', loc=(0.42, -0.02, 1.48))
    P.add(L.sphere(0.13, 0.12, 0.11, 10, 7), 'bone', loc=(-0.26, 0.0, 1.44))
    spikes(P, [(0.30, -0.16, 1.70), (0.46, -0.10, 1.74), (0.56, 0.04, 1.68)],
           0.16, 0.22, 'bone', up=(0.25, -0.2, 1.0))
    # swing arm up and out; cleaver cocked over the head
    limb(P, [(0.44, -0.06, 1.60), (0.74, -0.12, 1.74), (0.80, -0.06, 1.46)], 0.085, 0.065)
    haft = [(0.80, -0.04, 1.40), (0.62, 0.02, 1.88), (0.30, 0.06, 2.12)]
    limb(P, haft, 0.045, 0.038, 'dark')
    # cleaver head: a flat bit projecting OUT from the haft, built in the haft's
    # own frame - along-haft for the two horns, across-haft for the depth of the
    # bit. Three passes to get here: a constant quad read as a flag, a stack of
    # bands read as a curled sheet, and a free crescent read as a disc. An axe
    # is a plate hung off one side of a stick, and it must clear the skull.
    piv = Vector((0.30, 0.06, 2.10))
    vv = (piv - Vector(haft[0])).normalized()                  # along the haft, up
    uu = Vector((vv.z, 0.0, -vv.x)).normalized()               # out, away from the head
    if uu.x < 0:
        uu = -uu
    cols = 11
    inner, mid, outer = [], [], []
    for j in range(cols):
        t = j / (cols - 1.0)
        depth = 0.30 + 0.44 * math.sin(math.pi * t) ** 0.75
        along = 0.36 - 0.72 * t
        inner.append(piv + uu * 0.09 + vv * (along * 0.80))
        mid.append(piv + uu * (0.09 + (depth - 0.09) * 0.55) + vv * (along * 0.92))
        outer.append(piv + uu * depth + vv * along)
    P.raw(surf([inner, mid, outer], 0.05), 'body')
    limb(P, inner, 0.055, 0.055, 'dark', ring=7)               # the thick spine
    for end in (0, cols - 1):                                  # a horn at each end
        d = (outer[end] - mid[end]).normalized() + vv * (1.0 if end == 0 else -1.0)
        P.raw(aim(L.cone(0.045, 0.0, 0.22, 7), outer[end], d), 'bone')
    P.add(L.box(0.16, 0.20, 0.16), 'dark', loc=(0.31, 0.06, 2.08))     # head socket
    # left hand: a small disc shield, low
    P.raw(aim(L.cone(0.21, 0.19, 0.06, 14), (-0.34, -0.20, 1.18), (-0.3, -1.0, 0.1)), 'dark')
    limb(P, [(-0.26, 0.0, 1.40), (-0.34, -0.10, 1.22)], 0.075, 0.060)
    _skull(P, (0.08, -0.16, 1.76), 0.20, 'bone', True)
    return P


# ------------------------------------------------ 3 BONE BOWMAN: a wide low cross
def bowman():
    """Shares Skeleton_Minion with the skeleton minion. bestiary: h 1.6,
    crossbow, ways {ranged: 8.5} - it keeps 8.5 m off and shoots. Standing
    straight it is a minion with a stick. Braced in a shooting crouch, the
    crossbow's horizontal span is the whole silhouette: a cross, not a man."""
    P = Parts("bowman")
    # crouched brace: back leg long behind, front knee high
    limb(P, [(-0.30, 0.44, 0.06), (-0.26, 0.20, 0.44), (-0.14, -0.04, 0.74)], 0.075, 0.060)
    P.add(L.box(0.18, 0.34, 0.08), 'bone', loc=(-0.30, 0.50, 0.04))
    limb(P, [(0.28, -0.26, 0.04), (0.30, -0.16, 0.46), (0.16, 0.02, 0.76)], 0.075, 0.060)
    P.add(L.box(0.18, 0.34, 0.08), 'bone', loc=(0.28, -0.30, 0.04))
    # torso pitched forward over the weapon
    limb(P, [(0.0, 0.06, 0.76), (0.0, -0.08, 1.06), (0.0, -0.20, 1.26)], 0.165, 0.195)
    for i, t in enumerate((0.0, 0.34, 0.68)):
        z = 0.88 + t * 0.34
        P.add(L.sphere(0.19 - i * 0.01, 0.13, 0.022, 12, 5), 'bone', loc=(0.0, 0.0 - t * 0.14, z))
    for s in (-1, 1):
        P.add(L.sphere(0.13, 0.12, 0.11, 10, 7), 'bone', loc=(s * 0.25, -0.18, 1.24))
    _skull(P, (0.0, -0.30, 1.38), 0.19, 'bone', True)
    # arms thrown forward onto the stock
    limb(P, [(-0.25, -0.18, 1.22), (-0.30, -0.44, 1.14), (-0.12, -0.60, 1.08)], 0.072, 0.056)
    limb(P, [(0.25, -0.18, 1.22), (0.22, -0.40, 1.10), (0.06, -0.50, 1.06)], 0.072, 0.056)
    # stock along -Y, held level at the eye
    limb(P, [(0.0, -0.30, 1.04), (0.0, -0.78, 1.06)], 0.055, 0.045, 'dark')
    P.add(L.box(0.10, 0.22, 0.14), 'dark', loc=(0.0, -0.40, 1.00))
    # the bow: a 1.56 m span of limb, swept forward, with the string across it
    for s in (-1, 1):
        limb(P, [(s * 0.03, -0.74, 1.06), (s * 0.40, -0.70, 1.09), (s * 0.78, -0.58, 1.12)],
             0.042, 0.018, 'body')
        P.add(aim(L.cone(0.035, 0.0, 0.14, 7), (s * 0.78, -0.58, 1.12), (s * 1.0, 0.3, 0.1)), 'bone')
    limb(P, [(-0.78, -0.58, 1.12), (0.0, -0.40, 1.08), (0.78, -0.58, 1.12)], 0.012, 0.012, 'bone')
    # the loaded bolt, glowing - bolt_bone in its ways
    limb(P, [(0.0, -0.44, 1.08), (0.0, -0.96, 1.08)], 0.022, 0.010, 'glow')
    return P


# ------------------------------------------- 4 PALE CUTTHROAT: an arrow, leaning
def cutthroat():
    """Shares Skeleton_Rogue with the skeleton rogue. bestiary: h 1.6, TWO
    blades, spd 5.2 (the fastest skeleton), ways {grudge}, violet tint. The
    rogue stands upright; this one is already moving - pitched forward over its
    own knees with the blades trailed back, and long rags streaming behind.
    The outline is an arrowhead with a wake."""
    P = Parts("cutthroat")
    LEAN = math.radians(34.0)

    def pf(x, y, z):
        """Rotate a point about the hip line (X axis through z=0.86) so the whole
        body leans forward as one piece. -Y is the way it is facing."""
        dy, dz = y, z - 0.86
        c, sn = math.cos(LEAN), math.sin(LEAN)
        return (x, dy * c - dz * sn, 0.86 + dy * sn + dz * c)

    # legs: one driving back, one reaching - a stride, not a stance
    limb(P, [(-0.15, 0.10, 0.88), (-0.22, 0.46, 0.52), (-0.26, 0.74, 0.10)], 0.068, 0.050)
    P.add(L.box(0.17, 0.32, 0.07), 'bone', loc=(-0.26, 0.82, 0.05))
    limb(P, [(0.15, 0.06, 0.88), (0.22, -0.24, 0.56), (0.20, -0.48, 0.20)], 0.068, 0.050)
    P.add(L.box(0.17, 0.32, 0.07), 'bone', loc=(0.20, -0.56, 0.14))
    # spine pitched hard forward
    limb(P, [pf(0.0, 0.0, 0.86), pf(0.0, 0.0, 1.18), pf(0.0, 0.0, 1.42)], 0.150, 0.175)
    for s in (-1, 1):
        P.add(L.sphere(0.12, 0.11, 0.10, 10, 7), 'bone', loc=pf(s * 0.23, 0.0, 1.38))
    # hood with one glowing slit, no jaw showing
    hd = pf(0.0, 0.0, 1.54)
    P.add(L.sphere(0.175, 0.19, 0.20, 14, 9), 'bone', loc=hd)
    P.raw(aim(L.cone(0.21, 0.04, 0.30, 12), (hd[0], hd[1] + 0.06, hd[2] + 0.16),
              (0.0, 0.45, -1.0)), 'body')
    P.add(L.box(0.17, 0.04, 0.045), 'glow', loc=(hd[0], hd[1] - 0.17, hd[2] + 0.01))
    # both blades low and swept BACK, so they read as the arrow's flights. They
    # sit BELOW the rag line on purpose: in the first pass the rags and the
    # blades occupied the same band of the silhouette and the blades vanished.
    for s_ in (-1, 1):
        sh = pf(s_ * 0.23, 0.0, 1.36)
        wr = (s_ * 0.42, 0.40, 0.66)
        limb(P, [sh, (s_ * 0.38, 0.10, 1.00), wr], 0.066, 0.050)
        P.raw(aim(L.box(0.20, 0.06, 0.05), wr, (0.0, 1.0, 0.30)), 'dark')   # crossguard
        rows, cols = 3, 9
        grid = []
        for i in range(rows):
            t = i / (rows - 1.0)
            row = []
            for j in range(cols):
                u = j / (cols - 1.0)
                taper = (1.0 - u ** 2.2)
                row.append(Vector((wr[0] + s_ * (0.02 + 0.11 * t * taper),
                                   wr[1] + 0.86 * u,
                                   wr[2] - 0.30 * u - 0.07 * (1.0 - t) * taper)))
            grid.append(row)
        P.raw(surf(grid, 0.020), 'bone')
    # four rag tails off the shoulders, streaming back and up
    for s, lift, out in ((-1, 0.40, 0.30), (1, 0.44, 0.27)):
        sh = pf(s * 0.18, 0.06, 1.32)
        rows, cols = 3, 8
        grid = []
        for i in range(rows):
            t = i / (rows - 1.0)
            row = []
            for j in range(cols):
                u = j / (cols - 1.0)
                row.append(Vector((sh[0] + s * out * u * (0.4 + t * 0.6),
                                   sh[1] + 0.84 * u,
                                   sh[2] + 0.30 + lift * math.sin(math.pi * u * 0.8) - 0.18 * u * u)))
            grid.append(row)
        P.raw(surf(grid, 0.016), 'dark')
    return P


# ------------------------------------------- 5 GRAVECALLER: a pillar of stones
def gravecaller():
    """Shares Skeleton_Mage with the skeleton mage. bestiary: h 1.85, staff,
    casts, ways {ranged 7.0, raise 2} - it raises two of the dead at a time -
    and the only green glow among the skeletons. The mage walks; this one does
    not show its legs at all. A robed column with its arms thrown wide and the
    graves it is calling orbiting the hem as glowing stones."""
    P = Parts("gravecaller")
    # robe to the floor: no legs, so the base is a cone and the outline a pillar
    P.raw(aim(L.cone(0.56, 0.21, 1.34, 16), (0.0, 0.0, 0.0), (0.0, 0.0, 1.0)), 'body')
    P.raw(aim(L.cone(0.60, 0.56, 0.08, 16), (0.0, 0.0, 0.02), (0.0, 0.0, 1.0)), 'dark')
    # hem scallops: eight panels so the bottom is cloth, not a traffic cone
    for k in range(8):
        a = TAU * k / 8.0
        rows, cols = 3, 4
        grid = []
        for i in range(rows):
            t = i / (rows - 1.0)
            row = []
            for j in range(cols):
                u = -0.5 + j / (cols - 1.0)
                aa = a + u * (TAU / 8.0) * 0.95
                r = 0.56 + 0.12 * t - 0.05 * abs(u) * 2.0
                row.append(Vector((r * math.cos(aa), r * math.sin(aa), 0.30 - t * 0.28)))
            grid.append(row)
        P.raw(surf(grid, 0.02), 'body')
    # torso and the stole hanging down the front
    limb(P, [(0.0, 0.0, 1.28), (0.0, 0.0, 1.52)], 0.21, 0.19, 'body')
    P.add(L.box(0.16, 0.05, 0.86), 'dark', loc=(0.0, -0.19, 1.06))
    # arms thrown wide and up - the raise gesture
    for s in (-1, 1):
        limb(P, [(s * 0.19, 0.0, 1.50), (s * 0.50, -0.08, 1.62), (s * 0.74, -0.16, 1.82)],
             0.075, 0.055, 'bone')
        # sleeve
        P.raw(aim(L.cone(0.17, 0.09, 0.34, 10), (s * 0.19, 0.0, 1.48), (s * 1.0, -0.25, 0.5)), 'body')
        for f in range(3):      # fingers splayed
            P.raw(aim(L.cone(0.018, 0.0, 0.13, 6), (s * 0.74, -0.16, 1.82),
                      (s * (0.5 + f * 0.25), -0.3, 0.9)), 'bone')
    # hood, deep, with the green lights where a face is not
    P.raw(aim(L.cone(0.25, 0.05, 0.36, 14), (0.0, 0.0, 1.58), (0.0, 0.10, 1.0)), 'body')
    P.add(L.sphere(0.155, 0.17, 0.17, 12, 8), 'bone', loc=(0.0, -0.02, 1.68))
    eyes(P, (0.0, 0.0, 1.70), 0.065, 0.040, -0.13)
    # staff, planted, head a ring of green fire
    limb(P, [(0.56, -0.12, 0.0), (0.60, -0.14, 1.96)], 0.030, 0.026, 'dark')
    P.raw(aim(L.cone(0.10, 0.03, 0.14, 10), (0.60, -0.14, 1.96), (0.0, 0.0, 1.0)), 'bone')
    for k in range(9):
        a = TAU * k / 9.0
        P.add(L.sphere(0.035, 0.035, 0.035, 7, 5), 'glow',
              loc=(0.60 + 0.13 * math.cos(a), -0.14 + 0.13 * math.sin(a), 2.08))
    # THE RING OF RAISED STONES - seven grave markers tilting out of the floor,
    # lit from under. This is what makes the silhouette unmistakable.
    rng = random.Random("gravecaller-stones")
    for k in range(7):
        a = TAU * k / 7.0 + 0.22
        r = 0.86 + rng.uniform(-0.07, 0.10)
        h = 0.30 + rng.uniform(0.0, 0.22)
        x, y = r * math.cos(a), r * math.sin(a)
        P.raw(aim(L.box(0.17, 0.09, h), (x, y, h * 0.42),
                  (math.sin(a) * 0.30, -math.cos(a) * 0.30, 1.0)), 'bone')
        P.add(L.sphere(0.055, 0.055, 0.030, 8, 5), 'glow', loc=(x, y, 0.035))
    return P


# -------------------------------------- 6 SILK MOTHER: a dome on tall stilts
def silkmother():
    """Shares Spider with the cave spider and the spiderling. bestiary: h 1.3
    (double the cave spider), hp 1.5, ways {venom, summon spiderling} with the
    line 'Spiderlings spill from the silk mother's back'. So the brood sac IS
    the creature: a swollen abdomen carried HIGH on legs that arch well above
    it, with the brood breaking her outline. The spider is a flat disc of legs;
    she is a dome on stilts."""
    P = Parts("silkmother")
    # abdomen, carried high and back
    P.add(L.sphere(0.46, 0.56, 0.42, 18, 12), 'body', loc=(0.0, 0.40, 0.86))
    # segment banding so it reads as a sac, not a ball
    for i, t in enumerate((0.18, 0.46, 0.74)):
        P.add(L.sphere(0.47 - i * 0.07, 0.05, 0.43 - i * 0.07, 14, 8),
              'dark', loc=(0.0, 0.40 + 0.56 * (t - 0.5) * 1.5, 0.86))
    # cephalothorax, lower and forward
    P.add(L.sphere(0.27, 0.30, 0.22, 14, 10), 'body', loc=(0.0, -0.16, 0.70))
    # head, fangs, eight eyes in two rows
    P.add(L.sphere(0.16, 0.17, 0.14, 12, 8), 'body', loc=(0.0, -0.44, 0.64))
    for s in (-1, 1):
        P.raw(aim(L.cone(0.045, 0.0, 0.22, 7), (s * 0.07, -0.54, 0.58), (s * 0.25, -0.5, -1.0)), 'bone')
    for row, (dz, sep, rr) in enumerate(((0.06, 0.055, 0.030), (0.0, 0.105, 0.022))):
        for s in (-1, 1):
            for k in range(2):
                P.add(L.sphere(rr, rr, rr, 7, 5), 'glow',
                      loc=(s * (sep + k * 0.042), -0.56, 0.66 + dz))
    # THE BROOD - eleven young breaking out of the top and back of the sac
    rng = random.Random("silkmother-brood")
    for k in range(11):
        a = TAU * k / 11.0
        t = rng.uniform(0.25, 1.0)
        x = 0.40 * math.cos(a) * t
        y = 0.40 + 0.48 * math.sin(a) * t
        z = 0.86 + 0.40 * (1.0 - t * 0.5)
        r = 0.075 + rng.uniform(0.0, 0.035)
        P.add(L.sphere(r, r * 1.15, r * 0.9, 9, 6), 'dark', loc=(x, y, z))
        P.add(L.sphere(r * 0.4, r * 0.4, r * 0.4, 7, 5), 'glow', loc=(x, y - r * 0.9, z + r * 0.2))
        for ls in (-1, 1):      # a couple of legs each, so they are not eggs
            limb(P, [(x, y, z), (x + ls * r * 1.9, y + rng.uniform(-0.1, 0.1), z - r * 0.7)],
                 r * 0.22, r * 0.12, 'dark', ring=5)
    # EIGHT LEGS: each arches to 1.30 - above the abdomen - then drops to the floor
    for s in (-1, 1):
        for k, (sy, out, top) in enumerate((( -0.30, 1.02, 1.30), (-0.02, 1.16, 1.26),
                                            (0.30, 1.10, 1.18), (0.58, 0.92, 1.06))):
            hip = (s * 0.20, sy + 0.08, 0.74)
            knee = (s * out * 0.55, sy + out * 0.18, top)
            foot = (s * out, sy + out * 0.34, 0.0)
            pts = [hip, knee, ((knee[0] + foot[0]) * 0.55, (knee[1] + foot[1]) * 0.55, top * 0.45), foot]
            limb(P, pts, 0.062, 0.022, 'body', ring=7)
            P.add(L.sphere(0.055, 0.055, 0.05, 8, 6), 'dark', loc=knee)
    # a few strands of silk off the abdomen, hanging
    for k in range(4):
        x = -0.30 + 0.20 * k
        limb(P, [(x, 0.76, 0.86), (x * 1.1, 0.86, 0.46), (x * 1.2, 0.80, 0.08)],
             0.012, 0.006, 'bone', ring=5)
    return P


# ------------------------------------- 7 SPIDERLING: a flat star on the floor
def spiderling():
    """Shares Spider with the cave spider and the silk mother. bestiary: h 0.35,
    hp 0.3, spd 5.2 - it is summoned two at a time and swarms. A cave spider
    scaled to 0.35 is just a small cave spider. This one is built flat: the body
    is almost nothing and the legs are splayed nearly level with the floor, so
    it reads as a skittering star, and a pack of them reads as a floor that
    moves."""
    P = Parts("spiderling")
    P.add(L.sphere(0.115, 0.145, 0.082, 14, 9), 'body', loc=(0.0, 0.07, 0.17))
    P.add(L.sphere(0.075, 0.085, 0.060, 12, 8), 'body', loc=(0.0, -0.09, 0.15))
    P.add(L.sphere(0.090, 0.030, 0.070, 10, 6), 'dark', loc=(0.0, 0.07, 0.17))
    # four big glowing eyes - at this size the eyes are the readable feature
    for s in (-1, 1):
        for k in range(2):
            r = 0.022 - k * 0.006
            P.add(L.sphere(r, r, r, 7, 5), 'glow',
                  loc=(s * (0.030 + k * 0.040), -0.155, 0.17 + 0.012 - k * 0.018))
    for s in (-1, 1):
        P.raw(aim(L.cone(0.016, 0.0, 0.075, 6), (s * 0.028, -0.17, 0.12), (s * 0.3, -0.5, -1.0)), 'bone')
    # eight legs, long for the body and held LOW: knee only just above the back
    for s in (-1, 1):
        for sy, out, top in ((-0.14, 0.92, 0.265), (0.0, 1.00, 0.250),
                             (0.14, 0.94, 0.235), (0.28, 0.80, 0.215)):
            hip = (s * 0.08, sy * 0.5 + 0.05, 0.17)
            knee = (s * out * 0.17, sy * 0.8 + 0.05, top)
            foot = (s * out * 0.34, sy * 1.05 + 0.05, 0.0)
            limb(P, [hip, knee, foot], 0.019, 0.007, 'body', ring=6)
    return P


# --------------------------------------------- 8 SLIMELING: a splat, not a blob
def slimeling():
    """Shares Slime with the slime. bestiary: h 0.5, hp 0.35, and it is what a
    slime SPLITS INTO when it dies (and what the Grubmother spills). A slime at
    half scale is a small slime. This is the half that fell off: a low wide
    puddle with a ripple collar and the drips still running off it - broader
    than it is tall, which the parent never is."""
    P = Parts("slimeling")
    # the puddle: squashed, with a slight lean so it is not a symmetrical dome
    P.add(L.sphere(0.40, 0.37, 0.21, 20, 12), 'body', loc=(0.0, 0.0, 0.19))
    P.add(L.sphere(0.21, 0.19, 0.13, 14, 9), 'body', loc=(0.06, -0.05, 0.33))
    # the collar of displaced ooze where it meets the floor
    P.raw(aim(L.cone(0.50, 0.40, 0.065, 20), (0.0, 0.0, 0.0), (0.0, 0.0, 1.0)), 'body')
    # tongues of ooze running out along the floor - this is the splat
    rng = random.Random("slimeling-splat")
    for k in range(7):
        a = TAU * k / 7.0 + 0.3
        ln = 0.18 + rng.uniform(0.0, 0.22)
        x, y = math.cos(a), math.sin(a)
        limb(P, [(x * 0.38, y * 0.38, 0.05), (x * (0.38 + ln * 0.6), y * (0.38 + ln * 0.6), 0.035),
                 (x * (0.38 + ln), y * (0.38 + ln), 0.012)], 0.055, 0.012, 'body', ring=7)
        P.add(L.sphere(0.035, 0.035, 0.014, 8, 5), 'body',
              loc=(x * (0.40 + ln), y * (0.40 + ln), 0.012))
    # drips coming off the cap, caught mid-fall
    for x, y, z in ((-0.26, 0.10, 0.26), (0.22, -0.14, 0.30), (0.04, 0.27, 0.24)):
        limb(P, [(x, y, z), (x * 1.12, y * 1.12, z - 0.12)], 0.035, 0.016, 'body', ring=6)
        P.add(L.sphere(0.042, 0.042, 0.050, 8, 6), 'body', loc=(x * 1.2, y * 1.2, z - 0.20))
    # two eyes and the swallowed grit every ooze carries
    eyes(P, (0.06, 0.0, 0.33), 0.085, 0.045, -0.16)
    for k in range(5):
        a = TAU * k / 5.0 + 0.8
        P.add(L.box(0.055, 0.055, 0.045), 'dark',
              loc=(0.17 * math.cos(a), 0.15 * math.sin(a), 0.11))
    return P


# ------------------------------------------------- 9 GLOOM BAT: a cowl of wing
def gloombat():
    """Shares Bat with the cave bat. bestiary: h 1.2 (the cave bat is 0.9),
    lift 1.8, ways {pack: 2}, violet tint and the strongest glow of the beasts.
    A cave bat spreads its wings flat to the sides. This one carries them SWEPT
    FORWARD and cupped around itself like a cowl, with a long tail membrane
    hanging below - so hanging in the dark it reads as a hooded figure, and the
    only thing inside the hood is the glow."""
    P = Parts("gloombat")
    # body hangs vertical; everything is measured off the shoulder line
    limb(P, [(0.0, 0.0, 0.30), (0.0, -0.04, 0.68), (0.0, -0.02, 0.92)], 0.115, 0.145, 'body')
    P.add(L.sphere(0.145, 0.165, 0.150, 14, 9), 'body', loc=(0.0, -0.06, 1.02))
    # snout and the two ears, long and swept back
    P.raw(aim(L.cone(0.085, 0.035, 0.14, 10), (0.0, -0.12, 0.99), (0.0, -1.0, -0.15)), 'body')
    for s in (-1, 1):
        rows, cols = 3, 5
        grid = []
        for i in range(rows):
            t = i / (rows - 1.0)
            row = []
            for j in range(cols):
                u = j / (cols - 1.0)
                row.append(Vector((s * (0.07 + 0.11 * u + 0.03 * t), 0.02 + 0.16 * u,
                                   1.10 + 0.34 * u - 0.10 * t * u)))
            grid.append(row)
        P.raw(surf(grid, 0.014), 'body')
    eyes(P, (0.0, 0.0, 1.03), 0.060, 0.030, -0.145)
    P.add(L.box(0.085, 0.03, 0.025), 'glow', loc=(0.0, -0.17, 0.955))   # bared teeth
    # THE COWL: four fingers from each shoulder - up over the head, round to the
    # front, then down past the knee - with the membrane strung between them and
    # SCALLOPED between every pair. The first pass built this as one smooth grid
    # and it read as a flat box in silhouette: a wing is the fingers, not a sheet.
    for s in (-1, 1):
        sh = Vector((s * 0.10, -0.03, 0.94))
        fingers = [(Vector((s * 0.42, -0.30, 0.86)).normalized(), 0.74),
                   (Vector((s * 0.80, -0.46, 0.20)).normalized(), 0.86),
                   (Vector((s * 0.72, -0.44, -0.34)).normalized(), 0.90),
                   (Vector((s * 0.40, -0.26, -0.86)).normalized(), 0.82)]
        for d, ln in fingers:          # the finger bones themselves
            limb(P, [sh, sh + d * (ln * 0.55), sh + d * ln], 0.024, 0.009, 'dark', ring=6)
            P.add(L.sphere(0.018, 0.018, 0.018, 6, 4), 'dark', loc=sh + d * ln)
        for k in range(len(fingers) - 1):
            (d0, l0), (d1, l1) = fingers[k], fingers[k + 1]
            rows, cols = 5, 7
            grid = []
            for i in range(rows):
                v = i / (rows - 1.0)
                d = (d0 * (1.0 - v) + d1 * v).normalized()
                ln = l0 + (l1 - l0) * v
                # the trailing edge pulls IN between the fingers - the scallop
                ln *= 1.0 - 0.21 * math.sin(math.pi * v)
                row = []
                for j in range(cols):
                    u = j / (cols - 1.0)
                    cup = -0.16 * math.sin(math.pi * u) * math.sin(math.pi * v)
                    grid_pt = sh + d * (ln * u) + Vector((0.0, cup, 0.0))
                    row.append(grid_pt)
                grid.append(row)
            P.raw(surf(grid, 0.013), 'body')
        # the arm that carries them, and a thumb claw at the wrist
        limb(P, [(s * 0.10, -0.03, 0.92), sh + fingers[0][0] * 0.30], 0.045, 0.028, 'body', ring=6)
        P.raw(aim(L.cone(0.016, 0.0, 0.10, 6), sh + fingers[0][0] * 0.34,
                  (s * 0.4, -0.4, 1.0)), 'bone')
    # feet, curled as if it were still hanging
    for s in (-1, 1):
        limb(P, [(s * 0.07, 0.0, 0.32), (s * 0.11, 0.06, 0.18), (s * 0.08, -0.02, 0.07)],
             0.034, 0.020, 'dark', ring=6)
        for f in range(3):
            P.raw(aim(L.cone(0.013, 0.0, 0.055, 6), (s * 0.08, -0.02, 0.07),
                      (s * 0.3, -0.5 + f * 0.5, -1.0)), 'bone')
    # tail membrane, hanging between the legs and down - the hem of the cowl
    rows, cols = 4, 6
    grid = []
    for i in range(rows):
        t = i / (rows - 1.0)
        row = []
        for j in range(cols):
            u = -1.0 + 2.0 * (j / (cols - 1.0))
            row.append(Vector((u * 0.21 * (1.0 - t * 0.55), 0.11 + 0.06 * t,
                               0.28 - 0.34 * t - 0.05 * (1.0 - u * u))))
        grid.append(row)
    P.raw(surf(grid, 0.014), 'dark')
    return P


# ------------------------------------------- 10 SCAR RAT: a humped comma
def scarrat():
    """Shares Rat with the giant rat. bestiary: h 0.8 (the giant rat is 0.55),
    ways {venom 4.0, pack 2}, green glow, and the town's own line about it:
    'Scar rats have got into the old root pits, and they are not the size rats
    are meant to be.' So it is not a bigger rat - it is a WRONG one: the spine
    arches up into a hump of scarred bristle, the ribs show, the tail is held
    up and curled, and the head is low and narrow. A humped comma."""
    P = Parts("scarrat")
    spine = [(0.0, 0.46, 0.34), (0.0, 0.26, 0.50), (0.0, 0.02, 0.58),
             (0.0, -0.22, 0.52), (0.0, -0.44, 0.40), (0.0, -0.60, 0.33)]
    limb(P, spine, 0.135, 0.085, 'body', ring=10)
    # the hump: thicker over the shoulders, and the ribs pushing through
    P.add(L.sphere(0.20, 0.26, 0.19, 14, 10), 'body', loc=(0.0, 0.08, 0.54))
    for i, t in enumerate((0.12, 0.34, 0.56, 0.78)):
        y = 0.30 - t * 0.52
        P.add(L.sphere(0.175 - i * 0.012, 0.030, 0.145, 12, 7), 'dark', loc=(0.0, y, 0.48))
    # head: low, narrow, long snout, ears back
    P.add(L.sphere(0.115, 0.145, 0.105, 12, 8), 'body', loc=(0.0, -0.66, 0.31))
    P.raw(aim(L.cone(0.085, 0.030, 0.20, 10), (0.0, -0.70, 0.29), (0.0, -1.0, -0.22)), 'body')
    P.add(L.box(0.055, 0.045, 0.030), 'bone', loc=(0.0, -0.88, 0.235))   # teeth
    for s in (-1, 1):
        P.raw(aim(L.cone(0.070, 0.015, 0.115, 9), (s * 0.085, -0.60, 0.39), (s * 0.5, 0.5, 0.8)), 'body')
        P.raw(aim(L.cone(0.009, 0.0, 0.16, 5), (s * 0.03, -0.86, 0.26), (s * 0.5, -0.8, 0.1)), 'bone')
    eyes(P, (0.0, 0.0, 0.345), 0.072, 0.028, -0.70)
    # bristles: a scarred ridge all down the hump, the tallest at the shoulder
    spikes(P, [(0.0, 0.34 - 0.11 * k, 0.56 + (0.04 if 1 <= k <= 3 else 0.0)) for k in range(8)],
           0.10, 0.22, 'bone', up=(0.0, 0.35, 1.0))
    # four legs, the back pair crouched under the hump
    for s in (-1, 1):
        limb(P, [(s * 0.10, 0.34, 0.34), (s * 0.19, 0.42, 0.18), (s * 0.17, 0.32, 0.0)],
             0.050, 0.030, 'body', ring=7)
        limb(P, [(s * 0.10, -0.34, 0.40), (s * 0.16, -0.40, 0.20), (s * 0.15, -0.46, 0.0)],
             0.046, 0.028, 'body', ring=7)
        for f in (-1, 0, 1):
            P.raw(aim(L.cone(0.011, 0.0, 0.05, 5), (s * 0.17, 0.26, 0.015), (s * 0.2, -1.0, -0.2)), 'bone')
            P.raw(aim(L.cone(0.011, 0.0, 0.05, 5), (s * 0.15, -0.52, 0.015), (s * 0.2, -1.0, -0.2)), 'bone')
    # TAIL held UP and curled over - naked, segmented, as long as the body
    tail = [(0.0, 0.52, 0.34), (0.0, 0.76, 0.46), (0.05, 0.94, 0.66),
            (0.10, 0.92, 0.86), (0.12, 0.74, 0.94), (0.11, 0.58, 0.88)]
    limb(P, tail, 0.050, 0.012, 'dark', ring=8)
    for p in tail[1:5]:
        P.add(L.sphere(0.038, 0.016, 0.038, 9, 5), 'dark', loc=p)
    return P


# ------------------------------- 11 FEN LURKER: a mouth with a frog behind it
def lurker():
    """Shares Frog with the bog frog. bestiary: h 1.5 (the bog frog is 0.8),
    hp 1.6 - the toughest beast on the roster - ways {venom}, and it is at home
    in flooded rooms. An ambusher that size is all mouth: the gape is most of
    the silhouette, the eyes sit on TOP where the water line would be, and the
    body is a small sack folded behind it. You read the mouth first, always."""
    P = Parts("lurker")
    # the lower jaw: a wide shallow trough, the floor of the gape
    rows, cols = 5, 11
    low = []
    for i in range(rows):
        t = i / (rows - 1.0)
        row = []
        for j in range(cols):
            u = -1.0 + 2.0 * (j / (cols - 1.0))
            w = 0.66 * math.sqrt(max(0.0, 1.0 - t * t * 0.55))
            row.append(Vector((u * w, -0.30 - 0.74 * t, 0.46 + 0.16 * t + 0.10 * u * u)))
        low.append(row)
    P.raw(surf(low, 0.05), 'body')
    # the upper jaw, hinged open about 30 degrees over it
    up = []
    for i in range(rows):
        t = i / (rows - 1.0)
        row = []
        for j in range(cols):
            u = -1.0 + 2.0 * (j / (cols - 1.0))
            w = 0.64 * math.sqrt(max(0.0, 1.0 - t * t * 0.55))
            row.append(Vector((u * w, -0.30 - 0.70 * t, 0.88 + 0.44 * t - 0.12 * u * u)))
        up.append(row)
    P.raw(surf(up, 0.07), 'body')
    # the dark of the throat, and a double row of needle teeth on both jaws
    P.add(L.sphere(0.46, 0.34, 0.20, 14, 9), 'dark', loc=(0.0, -0.46, 0.70))
    for j in range(9):
        u = -1.0 + 2.0 * (j / 8.0)
        w = 0.60 * math.sqrt(max(0.0, 1.0 - 0.1))
        P.raw(aim(L.cone(0.030, 0.0, 0.17, 6), (u * w * 0.95, -0.96, 0.88), (0.0, 0.1, 1.0)), 'bone')
        P.raw(aim(L.cone(0.030, 0.0, 0.17, 6), (u * w * 0.95, -0.92, 1.14), (0.0, 0.1, -1.0)), 'bone')
    # skull plate over the top, and the eyes ON TOP of it
    P.add(L.sphere(0.56, 0.44, 0.22, 16, 10), 'body', loc=(0.0, -0.44, 1.18))
    for s in (-1, 1):
        P.add(L.sphere(0.16, 0.17, 0.15, 12, 8), 'body', loc=(s * 0.31, -0.50, 1.36))
        P.add(L.sphere(0.115, 0.125, 0.105, 10, 7), 'glow', loc=(s * 0.33, -0.56, 1.42))
        P.add(L.box(0.035, 0.11, 0.09), 'dark', loc=(s * 0.37, -0.63, 1.43))   # slit pupil
    # the body: a small hunched sack BEHIND the head, nearly an afterthought
    P.add(L.sphere(0.42, 0.44, 0.38, 16, 10), 'body', loc=(0.0, 0.30, 0.74))
    spikes(P, [(0.0, 0.14 + 0.13 * k, 1.04 - 0.03 * k) for k in range(5)], 0.09, 0.17, 'dark')
    for s in (-1, 1):   # warty back
        for k in range(4):
            P.add(L.sphere(0.055, 0.055, 0.040, 8, 5), 'dark',
                  loc=(s * (0.16 + 0.09 * (k % 2)), 0.10 + 0.17 * k, 0.98 - 0.05 * k))
    # hind legs folded high - the coil it ambushes out of
    for s in (-1, 1):
        limb(P, [(s * 0.30, 0.42, 0.72), (s * 0.52, 0.52, 1.00), (s * 0.56, 0.18, 0.44),
                 (s * 0.50, 0.04, 0.06)], 0.105, 0.055, 'body', ring=8)
        # webbed foot, splayed forward
        rows2, cols2 = 2, 5
        fg = []
        for i in range(rows2):
            row = []
            for j in range(cols2):
                u = -1.0 + 2.0 * (j / (cols2 - 1.0))
                row.append(Vector((s * 0.50 + u * 0.15, 0.04 - 0.28 * (i / (rows2 - 1.0)) - 0.04,
                                   0.035 + 0.02 * abs(u))))
            fg.append(row)
        P.raw(surf(fg, 0.03), 'body')
        # front legs, short, braced under the jaw
        limb(P, [(s * 0.26, -0.26, 0.56), (s * 0.34, -0.52, 0.30), (s * 0.32, -0.66, 0.05)],
             0.065, 0.040, 'body', ring=7)
        for f in (-1, 0, 1):
            P.raw(aim(L.cone(0.022, 0.0, 0.11, 6), (s * 0.32, -0.66, 0.04),
                      (s * 0.25 * f, -1.0, -0.1)), 'body')
    return P


# ------------------------------------------- 12 PIT WYRM: an S with no wings
def pitwyrm():
    """Shares Dragon with the grave-whelp. bestiary: h 4.0 (the whelp is 2.3),
    hp 1.8/atk 1.5 - the hardest non-lord on the roster - spd 2.6, lift 0.6,
    ways {breath}, red glow, at home in the firepit and the keep. The whelp can
    be a small winged dragon. This one has lived its whole life in a shaft:
    NO WINGS AT ALL, a long neck doubled back on itself, four short digging
    limbs and a plated spine. In outline it is an S, which no winged dragon is."""
    P = Parts("pitwyrm")
    # the spine: tail low and back, body coiled, neck rising then dropping forward
    spine = [(0.00, 2.05, 0.30), (0.00, 1.55, 0.42), (0.02, 1.05, 0.62),
             (0.00, 0.58, 0.92), (-0.02, 0.22, 1.42), (0.00, 0.06, 2.02),
             (0.04, 0.16, 2.62), (0.02, -0.18, 3.06), (0.00, -0.70, 3.18),
             (0.00, -1.18, 2.96), (0.00, -1.48, 2.62)]
    rad = [0.10, 0.18, 0.30, 0.42, 0.46, 0.40, 0.32, 0.26, 0.23, 0.22, 0.21]
    P.raw(L.tube([Vector(p) for p in spine], rad, 12), 'body')
    # chest and haunch mass, so the middle is a body and not a hose
    P.add(L.sphere(0.50, 0.58, 0.52, 16, 11), 'body', loc=(0.0, 0.34, 1.12))
    P.add(L.sphere(0.42, 0.46, 0.44, 14, 10), 'body', loc=(0.0, 0.08, 1.92))
    # belly scutes up the front of the coil
    for k in range(9):
        t = k / 8.0
        y = 1.30 - t * 1.26
        z = 0.52 + t * 1.42
        P.add(L.box(0.46 - 0.10 * t, 0.16, 0.05), 'bone', loc=(0.0, y - 0.34, z))
    # DORSAL PLATES all the way from the tail to the skull - the spine reads even
    # in pure silhouette, which is what the whelp's smooth back does not do
    for k in range(len(spine) - 1):
        a, b = Vector(spine[k]), Vector(spine[k + 1])
        for sub in (0.0, 0.5):
            p = a + (b - a) * sub
            t = (k + sub) / float(len(spine) - 1)
            hh = 0.16 + 0.34 * math.sin(math.pi * min(1.0, t * 1.15)) ** 0.7
            d = (b - a).normalized()
            n = d.cross(Vector((1, 0, 0)))
            if n.length < 1e-6:
                n = Vector((0, 0, 1))
            n = (-n).normalized() if n.z < 0 else n.normalized()
            rows, cols = 2, 4
            grid = []
            for i in range(rows):
                row = []
                for j in range(cols):
                    u = j / (cols - 1.0)
                    off = (0.055 if i else -0.055)
                    row.append(p + d * (off + 0.10 * math.sin(math.pi * u) * 0.0)
                               + n * (rad[min(k, len(rad) - 1)] * 0.85 + hh * u)
                               - d * (0.22 * u * u))
                grid.append(row)
            P.raw(surf(grid, 0.045), 'bone')
    # four short limbs - a digger's, not a flyer's
    for s in (-1, 1):
        limb(P, [(s * 0.34, 0.26, 1.02), (s * 0.64, 0.14, 0.62), (s * 0.70, -0.14, 0.22),
                 (s * 0.68, -0.30, 0.04)], 0.135, 0.070, 'body', ring=8)
        for f in (-1, 0, 1):
            P.raw(aim(L.cone(0.040, 0.0, 0.26, 7), (s * 0.68, -0.34, 0.05),
                      (s * 0.3 * f, -1.0, -0.25)), 'bone')
        limb(P, [(s * 0.30, 1.14, 0.60), (s * 0.52, 1.24, 0.34), (s * 0.54, 1.06, 0.05)],
             0.105, 0.055, 'body', ring=8)
        for f in (-1, 1):
            P.raw(aim(L.cone(0.032, 0.0, 0.19, 6), (s * 0.54, 1.02, 0.05),
                      (s * 0.3 * f, -1.0, -0.25)), 'bone')
    # skull: a flat wedge, jaw slightly open, vents glowing along the cheek
    head = Vector((0.0, -1.48, 2.62))
    P.raw(aim(L.cone(0.24, 0.10, 0.62, 12), head, (0.0, -1.0, -0.42)), 'body')
    P.add(L.sphere(0.24, 0.26, 0.19, 14, 9), 'body', loc=(0.0, -1.52, 2.60))
    P.raw(aim(L.box(0.30, 0.52, 0.10), (0.0, -1.82, 2.38), (0.0, -0.9, -1.0)), 'body')  # lower jaw
    for s in (-1, 1):
        for k in range(4):     # teeth
            P.raw(aim(L.cone(0.030, 0.0, 0.13, 6),
                      (s * (0.07 + k * 0.045), -1.80 + k * 0.10, 2.46), (0.0, -0.2, -1.0)), 'bone')
        for k in range(3):     # heat vents
            P.add(L.sphere(0.045, 0.045, 0.030, 8, 5), 'glow',
                  loc=(s * 0.21, -1.46 + k * 0.17, 2.56 - k * 0.04))
        # horns swept back along the neck
        P.raw(aim(L.cone(0.055, 0.0, 0.46, 8), (s * 0.17, -1.34, 2.74), (s * 0.35, 0.85, 0.45)), 'bone')
    eyes(P, (0.0, 0.0, 2.68), 0.145, 0.055, -1.62)
    # the breath, banked in the throat
    for k in range(4):
        P.add(L.sphere(0.075 - k * 0.012, 0.075, 0.060, 8, 6), 'glow',
              loc=(0.0, -1.92 + k * 0.12, 2.44 + k * 0.05))
    return P


BUILDERS = {
    "sentinel": sentinel, "hewer": hewer, "bowman": bowman, "cutthroat": cutthroat,
    "gravecaller": gravecaller, "silkmother": silkmother, "spiderling": spiderling,
    "slimeling": slimeling, "gloombat": gloombat, "scarrat": scarrat,
    "lurker": lurker, "pitwyrm": pitwyrm,
}
