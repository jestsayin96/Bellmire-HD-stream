def scraper():
    """IT RUBS OUT WHAT YOU HAVE JUST DONE. The 41st body. PASS 2.

    WHAT A VIEWER READS FROM THE DOORWAY:
      WHAT IS IT?        A stooped hooded clerk, near-black, working a PALE
                         TAPERED GRAVE SLAB that stands on a cut-stone plinth.
                         He is the darkest thing in the frame and the slab is
                         the brightest, so the eye lands on the mechanic.
      WHAT IS IT DOING?  SCOURING. He stands at the slab's LEFT EDGE, turned
                         into it, both hands on a pale scouring stone pressed
                         flat on the face, and a HEAP OF PALE DUST has piled
                         on the floor between them.
      HOW FAR ALONG?     THE SLAB'S BOTTOM THIRD IS ALREADY GONE - ground
                         THINNER than the inscribed part above it, so the slab
                         has a waist in its SILHOUETTE: the before and the
                         after are the same object. Above the waist, lines of
                         cut name-marks; below it, clean blank stone; and the
                         bottom line is down to a single stub, mid-wipe.
      HOW MANY MORE?     FIVE CUTS on each of the plinth's four faces. One cut
                         is one more wipe. A square plinth yawed off the
                         cardinals shows two faces to every camera standing on
                         the floor, so the count survives every yaw without
                         needing a floor disc.

    *** PASS 2. FOUR CHANGES, AND PASS 1 IS WHY. I LOOKED AT front.png AND
    *** side.png AND BOTH SAID THE SAME TWO THINGS.
      (A) THE WORK WAS INVISIBLE. Pass 1 put the man and the slab on opposite
          ends of a diagonal with the working face turned toward the man - and
          therefore AWAY from both cardinal cameras. Front and side both showed
          the arms running behind the slab and ending nowhere: no hands, no
          stone, no contact. The creature read as a man standing NEXT TO a
          stone, which is not the fight. It cannot be fixed by nudging the
          yaw, because the face that points at the man is the face that points
          away from a camera standing behind him - so the man now works the
          slab FROM ITS LEFT EDGE, reaching across, and the face is free to
          turn toward the room. That is also how you actually scour a wall.
      (B) THE SLAB READ AS A TOWER BLOCK. Five even rows of three even marks on
          a plain rectangle with a flat cap is a building with windows, and it
          was the first thing I saw in both views. Fixed by making the slab a
          TAPERED stele with a broken top instead of a capped box, and by
          giving the inscription a left margin and RAGGED LINE ENDS - lines of
          writing do not all finish in the same place, and windows do.
      (C) THE SPARE SLATES FLOATED. In side.png the three slates on his back
          hung 0.2-0.35 m clear of him, three fins in the air, because I placed
          them behind his hips and then leaned the torso forward away from
          them. They are now seated on the back surface the lean actually
          produces, in his own frame rather than in world y.
      (D) THE HOOD WAS NEARLY SHOULDER-WIDE and made the head read as the
          biggest mass on the man. Peak radius 0.225 -> 0.185.
    THEY SHARE ONE RENDER PASS BECAUSE (A) MOVES EVERY NUMBER (B)-(D) USE, but
    each is judged separately below and in the write-up: (A) by whether the
    stone and both hands are visible and touching in all three views, (B) by
    whether a viewer calls it a stone or a building, (C) by whether the slates
    touch the coat, (D) by head width against shoulder width.

    FACING IS BY CONSTRUCTION. The man is turned 37 degrees off the front
    camera, into the work. FRONT: the pale dust mask, the brow bar, two small
    eyes, both arms. BACK: the strap cross, three spare slates and the chalk
    bag, and nothing pale above the belt but two thin slate edges. The SLAB is
    deliberately yaw-symmetric - both broad faces inscribed, the same waist all
    the way round - because the facing is the MAN's job and a mechanic that
    only reads from one side is the Sealer's press fault.

    Static: no `anims` entry, so bestiary.gd needs a `model` path and NO
    `anims` entry.

    ROOM-LOCK is not claimed or pre-judged here: minibossgen measures the real
    footprint against floorgen's own corridor span and lid, and the report says
    the verdict.
    """
    P = Parts("scraper")
    P.spans = {}
    _m = [0]

    def _open():
        _m[0] = len(P.items)

    def _close(name):
        P.spans[name] = (_m[0], len(P.items))

    # ------------------------------------------------------------ THE FRAMES
    # Two local frames, because pass 1's faults were both frame faults: a man
    # placed in world y while his torso leans somewhere else grows floating
    # luggage, and a slab placed by eye turns its working face at the wall.
    MX, MY = -0.28, 0.14          # the man, at the slab's left edge
    SX, SY = 0.42, -0.12          # the slab and its plinth
    YAW = math.radians(-28.0)     # the slab's own yaw
    CS, SN = math.cos(YAW), math.sin(YAW)
    # HIS FACING: straight at the work. Derived from the two placements above
    # and not dialled, so moving either mass re-aims him.
    FX, FY = (SX - 0.30) - MX, (SY + 0.10) - MY
    _fl = math.hypot(FX, FY)
    FX, FY = FX / _fl, FY / _fl
    RX, RY = FY, -FX              # his right
    BF = math.atan2(FY, FX)

    def sw(u, v, z):
        """SLAB FRAME -> WORLD. u along the width, v out of the broad face.
        THE WORKING FACE IS -v and it is turned toward the room, not at him."""
        return (SX + u * CS - v * SN, SY + u * SN + v * CS, z)

    def mw(a, b, z):
        """MAN FRAME -> WORLD. a to his right, b forward along his facing."""
        return (MX + a * RX + b * FX, MY + a * RY + b * FY, z)

    T_UP = 0.150                  # inscribed shaft thickness at the waist
    T_LO = 0.092                  # scoured shaft thickness - THE WAIST
    Z_PL = 0.46                   # plinth top / slab foot
    Z_WAIST = 0.92                # how far the scouring has got
    Z_TOP = 1.88                  # top of the inscribed shaft

    _open()
    # ------------------------------------------------- THE MAN: BENT INTO IT
    # Staggered stance along HIS OWN forward axis: lead foot 0.17 forward,
    # trailing foot 0.15 back. seat() lifts each raked limb so its bottom ring
    # touches z=0 - minibossgen grounds the merged body on its global minimum,
    # so one hidden dip lifts every honest foot on the body into the air.
    for s, fb in ((1, 0.17), (-1, -0.15)):
        pts = seat([mw(s * 0.185, fb * 0.35, 0.84),
                    mw(s * 0.235, fb * 0.80, 0.44),
                    mw(s * 0.255, fb, 0.095)], 0.100)
        limb(P, pts, 0.100, 0.080, 'body')
        P.add(L.box(0.235, 0.385, 0.105), 'dark',
              loc=mw(s * 0.255, fb - 0.035, 0.0525), rot=(0.0, 0.0, BF))
    # THE STOOP: hip 0.80, shoulder 1.56, torso carried 0.30 m forward along
    # his facing over that run. He is leaning his weight on the stone.
    limb(P, [mw(0.0, -0.03, 0.80), mw(-0.01, 0.13, 1.20),
             mw(-0.02, 0.29, 1.56)], 0.250, 0.230, 'body')
    P.add(L.box(0.545, 0.275, 0.085), 'dark', loc=mw(0.0, 0.02, 0.98),
          rot=(0.0, 0.0, BF))
    for s in (-1, 1):
        P.add(L.sphere(0.150, 0.140, 0.125, 12, 8), 'body',
              loc=mw(s * 0.265, 0.26, 1.56))
    # THE HOOD, pass 2 size: a cowl and a drawn peak, crown 2.00. Head width
    # 0.37 against a shoulder span 0.83 - pass 1 was 0.45 against 0.83 and the
    # head was the biggest single mass on the man.
    P.add(L.sphere(0.155, 0.165, 0.190, 14, 10), 'body', loc=mw(-0.02, 0.30, 1.78))
    P.add(aim(L.cone(0.185, 0.060, 0.215, 14), mw(-0.02, 0.26, 1.785),
              (FX * 0.26, FY * 0.26, 1.0)), 'body')
    # THE DUST MASK: the one pale thing above the belt, on his front only, with
    # a brow bar over it so the eyes sit in their own shadow and no glow can
    # reach the frame edge at any yaw.
    P.add(L.box(0.175, 0.050, 0.100), 'bone', loc=mw(-0.02, 0.455, 1.730),
          rot=(0.0, 0.0, BF))
    P.add(L.box(0.205, 0.075, 0.045), 'dark', loc=mw(-0.02, 0.435, 1.840),
          rot=(0.0, 0.0, BF))
    for s in (-1, 1):
        P.add(L.sphere(0.0245, 0.0245, 0.0245, 8, 6), 'glow',
              loc=mw(s * 0.058, 0.425, 1.818))
    _close("man")

    _open()
    # ---------------------------------------------- THE BACK: NOT A BLANK PANEL
    # Fault 3 of my own Relief write-up answered, and pass 1's floating fins
    # fixed: the slates are placed in HIS frame at b = -0.02 and back, which is
    # the back surface his 0.25 m torso and his 0.29 m lean actually produce,
    # so the first one touches the coat.
    for i in range(3):
        P.add(L.box(0.420 - i * 0.035, 0.052, 0.310 - i * 0.030), 'dark',
              loc=mw(0.01, -0.02 - i * 0.052, 1.31 - i * 0.020),
              rot=(0.0, 0.0, BF + 0.10 * (i - 1)))
        P.add(L.box(0.420 - i * 0.035, 0.015, 0.026), 'bone',
              loc=mw(0.01, -0.02 - i * 0.052,
                     1.31 - i * 0.020 + (0.310 - i * 0.030) * 0.5),
              rot=(0.0, 0.0, BF + 0.10 * (i - 1)))
    for s in (-1, 1):             # the strap cross, over the shoulders
        limb(P, [mw(s * 0.245, 0.24, 1.60), mw(-s * 0.085, -0.02, 1.16)],
             0.038, 0.034, 'dark')
    P.add(L.sphere(0.130, 0.105, 0.140, 12, 8), 'dark', loc=mw(-0.235, -0.05, 0.90))
    _close("back")

    _open()
    # --------------------------------------- THE ARMS AND THE SCOURING STONE
    # PASS 2 FAULT (A), FIXED HERE. Both hands are on one stone pressed on the
    # slab's -v face, which is the face turned toward the room, and the hands
    # sit near the slab's LEFT EDGE where a man standing beside it can actually
    # reach. The stone TOUCHES the slab, the handle TOUCHES both grips, and the
    # arms are 0.84-0.88 m of bent polyline against a 0.87 m straight reach -
    # measured, because pass 1's layout needed 1.0 m arms and I only found that
    # out by failing to place them.
    HAND_N = sw(-0.300, -(T_LO * 0.5 + 0.085), 0.800)
    HAND_F = sw(-0.060, -(T_LO * 0.5 + 0.105), 0.860)
    for a, H in ((-0.265, HAND_N), (0.265, HAND_F)):
        S = mw(a, 0.26, 1.56)
        limb(P, [S, (S[0] * 0.45 + H[0] * 0.55, S[1] * 0.45 + H[1] * 0.55, 1.18),
                 H], 0.095, 0.072, 'body')
        P.add(L.sphere(0.082, 0.082, 0.078, 10, 7), 'dark', loc=H)
    # THE STONE, flat on the face, and its dark handle bar through both grips.
    P.add(L.box(0.300, 0.100, 0.095), 'bone',
          loc=sw(-0.180, -(T_LO * 0.5 + 0.048), 0.828), rot=(0.0, 0.0, YAW))
    limb(P, [sw(-0.345, -(T_LO * 0.5 + 0.085), 0.800),
             sw(-0.015, -(T_LO * 0.5 + 0.105), 0.862)], 0.030, 0.030, 'dark')
    _close("stone")

    _open()
    # ------------------------------- THE PLINTH: THE GAUGE AND THE WEAK POINT
    # 0.62 square, 0.46 tall. FIVE cuts on EACH of the four faces, 0.055 wide
    # at 0.112 pitch - the Hooper's pass-6 spacing finding (five rings at
    # 0.13 m read as one helix) applied before the first render, not after it.
    PL = 0.62
    P.add(L.box(PL, PL, Z_PL), 'bone', loc=sw(0.0, 0.0, Z_PL * 0.5),
          rot=(0.0, 0.0, YAW))
    for face in range(4):
        fa = YAW + face * (TAU / 4.0)
        nx, ny = math.cos(fa), math.sin(fa)
        tx, ty = -ny, nx
        for k in range(5):
            o = (k - 2) * 0.112
            P.add(L.box(0.055, 0.075, 0.175), 'dark',
                  loc=(SX + nx * (PL * 0.5 - 0.012) + tx * o,
                       SY + ny * (PL * 0.5 - 0.012) + ty * o, 0.265),
                  rot=(0.0, 0.0, fa))
    _close("plinth")

    _open()
    # ------------------------------------------- THE SLAB: THE RECORD ITSELF
    # PASS 2 FAULT (B), FIXED HERE. A TAPERED STELE, not a capped box: three
    # stacked segments 0.82 -> 0.775 -> 0.725 wide and 0.150 -> 0.140 thick, so
    # the stone narrows as it rises the way cut stone does and a cabinet does
    # not. The SCOURED SHAFT below the waist keeps the full 0.82 width and
    # drops to 0.092 thick - that step is the mechanic in the SILHOUETTE, and a
    # surface-only erasure would have been invisible in outline and to every
    # number this lane computes.
    P.add(L.box(0.82, T_LO, Z_WAIST - Z_PL), 'bone',
          loc=sw(0.0, 0.0, (Z_PL + Z_WAIST) * 0.5), rot=(0.0, 0.0, YAW))
    SEGS = [(0.92, 1.24, 0.820, 0.150), (1.24, 1.58, 0.775, 0.145),
            (1.58, Z_TOP, 0.725, 0.140)]
    for z0, z1, w, t in SEGS:
        P.add(L.box(w, t, z1 - z0), 'bone', loc=sw(0.0, 0.0, (z0 + z1) * 0.5),
              rot=(0.0, 0.0, YAW))
    # THE BROKEN TOP. Not a cap: a short run of the original crown at the left
    # and one surviving corner block at the right, with the middle gone. A
    # clean top edge is a panel; a broken one is a stone that has been worked.
    P.add(L.box(0.400, 0.165, 0.070), 'bone', loc=sw(-0.155, 0.0, Z_TOP + 0.035),
          rot=(0.0, 0.0, YAW))
    P.add(L.box(0.130, 0.150, 0.042), 'bone', loc=sw(0.280, 0.0, Z_TOP + 0.021),
          rot=(0.0, 0.0, YAW))
    # THE INSCRIPTION, ON BOTH BROAD FACES. A LEFT MARGIN AND RAGGED LINE ENDS:
    # lines of writing start together and finish in different places, which is
    # exactly what pass 1's even grid did not do. The BOTTOM line is down to a
    # single short stub - the stone has reached it and it is half gone.
    ROWS = [(1.035, [(-0.300, 0.105)]),
            (1.205, [(-0.330, 0.215), (-0.050, 0.300)]),
            (1.375, [(-0.330, 0.160), (-0.120, 0.120), (0.065, 0.250)]),
            (1.545, [(-0.310, 0.300), (0.045, 0.175)]),
            (1.715, [(-0.300, 0.200), (-0.040, 0.100), (0.115, 0.155)])]
    for z, marks in ROWS:
        tt = 0.150
        for z0, z1, w, t in SEGS:
            if z0 <= z < z1:
                tt = t
        for sv in (1.0, -1.0):
            vf = sv * (tt * 0.5 - 0.009)
            for u0, wm in marks:
                P.add(L.box(wm, 0.055, 0.040), 'dark',
                      loc=sw(u0 + wm * 0.5, vf, z), rot=(0.0, 0.0, YAW))
    _close("slab")

    _open()
    # --------------------------------------------- THE DUST: THE WORK IS REAL
    # A low pale heap on the floor at the working face, built through _rev so
    # it is the same width at every yaw and lying ON the floor, which is the one
    # place a camera standing on the floor cannot hide. The second, smaller
    # heap runs back toward his boots so the dust is plainly HIS and not a rock
    # that happens to be there.
    P.add(_rev([(0.000, 0.420), (0.055, 0.360), (0.135, 0.205),
                (0.200, 0.000)], 20), 'bone', loc=sw(-0.090, -0.380, 0.0))
    P.add(_rev([(0.000, 0.205), (0.038, 0.150), (0.072, 0.000)], 16),
          'bone', loc=sw(-0.430, -0.285, 0.0))
    _close("dust")
    return P
