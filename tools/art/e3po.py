"""e3po - the Commander of the Guards' kit (D85, art half).

THE PROBLEM, measured not guessed: notables.gd gives E3PO `"role": "guard"`,
and town.gd:4627 gives EVERY guard the same row -
    ["guard", "garrison", "Knight.glb", 0.74, 0.82, 1.00, 5]
- so the Commander wears the same model, the same pale-blue tint and the same
kit as the five men he commands, standing where they all stand. There is
nothing to see. Mr. E has never laid eyes on him.

THE ANSWER IS A KIT, NOT A NEW BODY. Knight.glb is a skinned KayKit mesh on
the Rig_Medium skeleton; re-exporting it as a bespoke E3PO mesh would throw the
walk and idle away. So this builds ORIGINAL geometry authored in the rig's own
rest space, one object per attachment point, each with its ORIGIN ON THE BONE
IT HANGS FROM, so the game build worker parents it and the animation carries it.

WEAR IS A VARIABLE (Mr. E, Nov 15 17:50). Every surface here takes `wear` in
0..1 - 0.0 is a level-12 prosperous Bellmire (bright madder, kept steel, clean
brass), 1.0 is a level-1 make-do town (sun-bleached cloth, dulled steel, a
patch riveted over the mantle's corner). The Commander is the RANKING officer,
so his floor is "maintained", never "rags" - the wear range is narrowed, not
removed. Drive it from town level.

HIS COLOUR IS HIS - AND IT IS NOT RED. The first pass gave him a madder-red
mantle; the contact sheet killed that idea on sight, because the KayKit knight
ALREADY wears a red cape, so every one of the five guards is red-caped and the
Commander would have been one more red man in a red line. Colour had to come
from the one axis the guards do not occupy: VALUE. His plate goes near-black
and his mantle and crest go bleached bone-white with brass. Against a line of
pale-blue steel and red wool, the only white-and-black man on the street is
the one in charge. Plain, and legible at a hundred pixels.

CC0 note: all geometry here is generated from vertex maths in lordlib. No
third-party asset is read. Knight.glb (KayKit, CC0) is READ ONLY for
measurement and for the renders, and is not re-exported.
"""
import math
from mathutils import Vector

import lordlib as L

TAU = math.pi * 2.0

# bleached linen - the one value the guard line does not hold
LINEN_NEW = (0.90, 0.88, 0.82)      # bleached, kept, a prosperous garrison
LINEN_OLD = (0.46, 0.44, 0.38)      # grey-dun, washed thin, smoke in the weave
STEEL_NEW = (0.055, 0.058, 0.070)   # near-black plate, kept
STEEL_OLD = (0.115, 0.112, 0.105)   # dulled to dirty grey
BRASS_NEW = (0.74, 0.56, 0.21)
BRASS_OLD = (0.42, 0.37, 0.22)
LEATHER = (0.16, 0.115, 0.085)
HAFT = (0.26, 0.195, 0.135)


def mix(a, b, t):
    return tuple(x + (y - x) * t for x, y in zip(a, b))


def materials(wear):
    """wear 0 = prosperous and kept, 1 = make-do. Roughness rides it too."""
    w = max(0.0, min(1.0, wear))
    return {
        'cloth': L.mat_solid("e3po_cloth", mix(LINEN_NEW, LINEN_OLD, w), 0.72 + 0.20 * w, 0.02),
        'steel': L.mat_solid("e3po_steel", mix(STEEL_NEW, STEEL_OLD, w), 0.22 + 0.52 * w, 0.92 - 0.30 * w),
        'brass': L.mat_solid("e3po_brass", mix(BRASS_NEW, BRASS_OLD, w), 0.26 + 0.44 * w, 0.88 - 0.34 * w),
        'leather': L.mat_solid("e3po_leather", mix(LEATHER, (0.21, 0.17, 0.14), w), 0.74, 0.03),
        'haft': L.mat_solid("e3po_haft", mix(HAFT, (0.30, 0.26, 0.21), w), 0.80, 0.02),
    }


class Part(object):
    """Geometry destined for one bone. verts are in the rig's REST world space."""
    def __init__(self, name, bone):
        self.name = name
        self.bone = bone
        self.items = []     # (verts, faces, slot)

    def add(self, vf, slot, loc=(0, 0, 0), rot=(0, 0, 0), scale=(1, 1, 1)):
        v, f = vf
        self.items.append((L.xform(v, loc, rot, scale), f, slot))
        return self


# --------------------------------------------------------------------- the kit
def build(anchor, measure, wear=0.35):
    """anchor: {bone: Vector(head)} in rest world space.
       measure: {'helmet_top','helmet_r','cape_top','cape_bottom','body_height'}

    SIZED AGAINST THE REAL RIG, NOT GUESSED. Measured from Knight.glb: the body
    is 2.54 tall, the helmet crown sits at 2.40 and the shoulders at 1.11 - so
    the HEAD IS 46% OF THE MAN. The first pass sized a 0.15 crest for a head
    1.16 tall and it vanished. On a chibi body the helm is the billboard, so
    the crest is the loudest thing here and everything small was cut: the sash
    and the neck gorget read as clutter at pane distance and are gone.

    Four material slots, merged by the driver, so the Commander costs at most
    four extra draw calls on a town street."""
    w = max(0.0, min(1.0, wear))
    parts = []

    head = anchor['head']
    chest = anchor['chest']
    ual = anchor['upperarm.l']
    uar = anchor['upperarm.r']
    slot_r = anchor['handslot.r']

    htop = measure['helmet_top']
    hr = measure['helmet_r']

    # ---- 1. THE CREST. Sized to the helm, which on this rig is half the man.
    # A fore-aft comb: the one mark that still reads from behind and above,
    # which is how a pane usually catches a man standing a post.
    crest = Part("E3PO_Crest", "head")
    # ONE fin, not a comb. The first pass fanned eleven blades and at render
    # size they merged into a white slab that read as a paper hat. Plainness is
    # the voice: a single scalloped fin on a brass keel says officer and
    # nothing else, and it keeps its shape at a hundred pixels.
    n = 13
    keel = []
    for i in range(n):
        t = i / (n - 1.0)
        y = -hr * 0.80 + (hr * 1.56) * t
        z = htop - 0.075 + math.sin(math.pi * t) * 0.075
        keel.append(Vector((0.0, y, z)))
    crest.add(L.tube(keel, [0.034 + 0.020 * math.sin(math.pi * (i / (n - 1.0)))
                            for i in range(n)], ring=7), 'brass')
    # the fin: a tall profile, highest just forward of the crown, scalloped
    # along the top so it is not a rectangle
    prof = []
    m = 15
    for i in range(m):
        t = i / (m - 1.0)
        y = -hr * 0.62 + (hr * 1.18) * t
        base = htop - 0.050 + math.sin(math.pi * t) * 0.070
        # one clean arc, peaking just forward of the crown. The scalloped
        # version read as a lumpy white tombstone at pane distance - a crest
        # has to be a SHAPE, and the plainest shape is an arc.
        h = 0.46 * math.sin(math.pi * (0.10 + 0.84 * t)) ** 0.80
        h *= (1.0 - 0.20 * w)                      # a poor town's crest is cropped
        prof.append((y, base, base + h))
    top_edge = [Vector((0.0, y, zt)) for y, zb, zt in prof]
    bot_edge = [Vector((0.0, y, zb)) for y, zb, zt in prof]
    crest.add(L.membrane(top_edge + bot_edge[::-1], 0.038), 'cloth')
    parts.append(crest)

    # ---- 2. PAULDRONS. Rank reads first in the shoulder line. Three lames a
    # side, brass-edged on the top lame only - plain is the voice.
    for side, a in (('l', ual), ('r', uar)):
        sgn = 1.0 if side == 'l' else -1.0
        p = Part("E3PO_Pauldron" + side.upper(), "upperarm." + side)
        for k in range(3):
            rr = 0.235 - 0.034 * k
            dz = -0.015 - 0.098 * k
            dx = sgn * (0.028 + 0.070 * k)
            v, f = L.sphere(rr * 1.02, rr * 1.16, rr * 0.60, seg=14, rings=8)
            vv = [Vector((q.x, q.y, max(q.z, -rr * 0.10))) for q in v]
            p.add((vv, f), 'steel', loc=(a.x + dx, a.y, a.z + dz))
        rim = [Vector((a.x + sgn * 0.010, a.y + 0.252 * math.sin(TAU * i / 20.0),
                       a.z - 0.012 + 0.228 * math.cos(TAU * i / 20.0) * 0.52))
               for i in range(11)]
        p.add(L.tube(rim, 0.022, ring=6, caps=False), 'brass')
        parts.append(p)

    # ---- 3. THE MANTLE. A shoulder cape that hangs from the shoulder line to
    # mid-thigh, OVER the knight's own cape, open at the front. The first pass
    # put a short band across the chest and it read as an apron; this one is
    # cut from the shoulders down, which is the only way a mantle reads.
    mant = Part("E3PO_Mantle", "chest")
    # IT STOPS AT THE HIP. Cut to mid-thigh it read as a white dress - this
    # body is 46% head, so anything below the belt swallows the figure.
    top = ual.z + 0.120                  # the shoulder line, not the chest
    bot = 0.640 + 0.075 * w              # the hip; a poor town cuts it shorter
    ring = 15
    r_t, r_b = 0.250, 0.395
    for i in range(ring - 1):
        t0, t1 = i / (ring - 1.0), (i + 1) / (ring - 1.0)
        a0 = math.pi * 0.30 + (TAU * 0.86) * t0
        a1 = math.pi * 0.30 + (TAU * 0.86) * t1
        loop = [Vector((r_t * math.cos(a0), r_t * math.sin(a0), top)),
                Vector((r_t * math.cos(a1), r_t * math.sin(a1), top)),
                Vector((r_b * math.cos(a1), r_b * math.sin(a1), bot)),
                Vector((r_b * math.cos(a0), r_b * math.sin(a0), bot))]
        mant.add(L.membrane(loop, 0.038), 'cloth')
    # a brass band along the shoulder seam - where rank is actually worn
    band = [Vector((0.268 * math.cos(math.pi * 0.30 + TAU * 0.86 * (i / 14.0)),
                    0.268 * math.sin(math.pi * 0.30 + TAU * 0.86 * (i / 14.0)),
                    top + 0.010)) for i in range(15)]
    mant.add(L.tube(band, 0.030, ring=6, caps=False), 'brass')
    # ONE patch, riveted, only when the town is poor. This is the receipt.
    if w > 0.55:
        pa = math.pi * 1.30
        r = (r_t + r_b) * 0.5
        base = (top + bot) * 0.5
        loop = [Vector((r * math.cos(pa) - 0.085, r * math.sin(pa) - 0.070, base - 0.085)),
                Vector((r * math.cos(pa) + 0.105, r * math.sin(pa) + 0.045, base - 0.110)),
                Vector((r * math.cos(pa) + 0.090, r * math.sin(pa) + 0.060, base + 0.130)),
                Vector((r * math.cos(pa) - 0.095, r * math.sin(pa) - 0.055, base + 0.150))]
        mant.add(L.membrane(loop, 0.030), 'leather')
    parts.append(mant)

    # ---- 4. THE HALBERD. The rank-and-file carry swords; nobody else on the
    # street holds a two-metre haft, so this is the silhouette that survives
    # being a hundred pixels tall. Lives on handslot.r.
    hal = Part("E3PO_Halberd", "handslot.r")
    s = slot_r
    # Authored about its own butt at the origin, then LEANED OUT and carried to
    # the hand. A man resting a polearm leans it away from himself, and on this
    # rig that lean is also the only way the axe head clears a helm 1.14 wide.
    lean = -0.165
    at = dict(loc=(s.x, s.y, 0.0), rot=(0.0, lean, 0.0))
    z1 = 2.86
    hal.add(L.tube([Vector((0, 0, -0.03)), Vector((0, 0, z1 - 0.55)),
                    Vector((0, 0, z1))], [0.052, 0.046, 0.040], ring=9), 'haft', **at)
    for zz in (0.30, 0.95):
        hal.add(L.tube([Vector((0, 0, zz - 0.030)), Vector((0, 0, zz + 0.030))],
                       0.062, ring=9), 'leather', **at)
    blade, m = [], 11
    for i in range(m):
        t = i / (m - 1.0)
        zz = z1 - 0.86 + 0.74 * t
        yy = -(0.110 + 0.420 * math.sin(math.pi * t) ** 0.70)
        blade.append(Vector((0.0, yy, zz)))
    back = [Vector((0.0, -0.055, z1 - 0.84)), Vector((0.0, -0.055, z1 - 0.10))]
    hal.add(L.membrane(blade + back[::-1], 0.052), 'steel', **at)
    # the top spike: raised to the haft's tip in haft space first, then
    # carried out with the same lean as everything else on the shaft
    cv, cf = L.cone(0.058, 0.0, 0.56, seg=10)
    hal.add((L.xform(cv, loc=(0, 0, z1 - 0.04)), cf), 'steel', **at)
    fl = [Vector((0.0, 0.050, z1 - 0.76)), Vector((0.0, 0.360, z1 - 0.52)),
          Vector((0.0, 0.300, z1 - 0.38)), Vector((0.0, 0.050, z1 - 0.42))]
    hal.add(L.membrane(fl, 0.046), 'steel', **at)
    # a linen pennon at the collar - the one bright thing above the crowd line
    pz = z1 - 1.05
    pen = [Vector((0.0, -0.030, pz)), Vector((0.0, -0.560, pz - 0.105)),
           Vector((0.0, -0.470, pz - 0.290)), Vector((0.0, -0.030, pz - 0.235))]
    hal.add(L.membrane(pen, 0.026), 'cloth', **at)
    parts.append(hal)

    return parts
