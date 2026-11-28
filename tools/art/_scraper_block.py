
# =====================================================================
# 41 THE SCRAPER - "Scourstone", theme `crypt`. 20 Nov 2026, ~15:4x CT.
#
# Built under Mr. E's standing permission (17:43) on a plan row that names it:
# the team lead's 14:58 block says "A 41st MINIBOSS IS THE ONE THING YOU MAY
# INVENT, AND IT IS YOURS TO TAKE", with the chain flush for the first time
# (40 bodies, 40 feed rows, 0 bodies without a feed) so a new body starts the
# next lap clean. The same row orders the acceptance test INTO THE SAME PUSH as
# the body, because the Relief cost two firings by shipping the mesh first and
# the proof second. Body, hero trio and register go out together here.
#
# THE BAR IS ONE IDEA THAT CHANGES THE FIGHT, AND THIS ONE ATTACKS A RESOURCE
# NO BODY IN THIS FILE HAS EVER TOUCHED: WHAT THE PARTY HAS ALREADY DONE.
# Forty bodies argue about the future - how much damage, where it goes, who
# takes it, who may act, where they stand. Every one of them leaves the past
# alone: a blow that landed stays landed. This one does not fight the party's
# next action at all. It waits, and then it takes the LAST one back. The blow
# comes off, the wound re-opens, the guard is gone. Nothing the party does is
# banked until something else has been done after it, so the last thing you do
# each round is the thing you are going to lose, and the party has to put its
# real work in EARLY and spend its tail-end actions on something it does not
# mind having rubbed out. You cannot out-damage it, because the damage is
# precisely what it removes; you go for the plinth the slab stands on.
#
# WHY IT IS NOT A RE-SKIN. I printed and read all 40 `idea` strings in CANON
# this run (measured off the file, not remembered - the count came off
# `_report.json`'s 51 entries minus 11 `_chibi`, and the ideas off a regex over
# this file). The five nearest, and why this is not them:
#   TANNER     refuses a blow BEFORE it lands, and only a repeat of one. Here
#              every blow lands, from anyone, and ONE of them is taken back
#              afterwards - and it need not be a blow at all.
#   FULLER     gives back what you put in: your damage returns as harm. This
#              returns nothing. It deletes. There is no counter-punch to play
#              around, only work that did not stick.
#   SEXTON     will not stay down - it restores ITSELF out of its own graves.
#              That is a creature healing. This never heals: it un-does the
#              party's most recent act whatever that act was, and a heal or a
#              guard is as good a thing for it to rub out as a sword blow.
#   BEADLE     takes WHO acts. This leaves every choice the party has, and
#              makes the LAST of them worthless. Opposite ends of a round.
#   STRICKLER  scrapes your best hero down while it stands - a standing tax on
#              a hero. This is a one-shot delete of an EVENT, and the party
#              chooses which event by choosing what to do last.
# What is new in the file is the KIND of resource attacked: the record.
#
# THEME: crypt, which had TWO bodies (Sexton, Ratcatcher) against four in keep
# and four in workshop - counted off CANON this run. A clerk rubbing a name off
# a slab is a crypt job in the plainest possible sense, and PLAINNESS IS THE
# VOICE: he is not a sorcerer of time, he is a man with a scouring stone who
# has been told to clear the wall.
#
# THREE FAULTS FROM MY OWN RELIEF WRITE-UP ARE DESIGNED AGAINST HERE, NOT
# DISCOVERED AFTERWARDS:
#   FAULT 1 (the profile was a thin slab). The man is STAGGERED in y and
#           STOOPED into the work, and the mechanic is a mass on the far
#           diagonal, so no cardinal view collapses onto one column.
#   FAULT 3 (the back was a near-blank panel). The back carries the stack of
#           three spare slates on their strap and the chalk bag - dark, with
#           thin pale edges only, so the back has a FEATURE without getting a
#           pale mass that would cost the facing.
#   THE BEADLE'S WRAPPED BAND (no facing at all). The one pale thing above the
#           belt is the DUST MASK, and it is on the front face only. From
#           behind there is no mask, no eyes and nothing pale but two slate
#           edges.
# AND THE GAUGE IS THE PLINTH, NOT A THIRD OBJECT. The Relief learned that a
# count has to be legible at every yaw and solved it with a floor disc. Doing
# that again would be a re-skin of the solution; instead the five tally cuts
# are on ALL FOUR FACES of the stone plinth the slab stands on, which is the
# thing a player is meant to attack, costs no extra footprint, and cannot be
# turned edge-on because a square at 45 degrees shows two faces to every
# cardinal camera.
# =====================================================================
CANON.update({
    "scraper": ("Scourstone", 2.30, (0.74, 0.72, 0.66), (0.72, 0.86, 0.98),
                "crypt", "IT RUBS OUT WHAT YOU HAVE JUST DONE - it does not "
                "block a blow, it does not heal and it takes nobody away. It "
                "works, and when the round is over it draws the stone down the "
                "slab and THE LAST THING THE PARTY DID IS UNDONE: the blow that "
                "landed comes off, the wound that was closed opens again, the "
                "guard that was set is gone. Nothing is kept until something "
                "else has been done after it, so the party must get its real "
                "work in early and spend its last action on something it is "
                "willing to lose. Out-damaging it does not work, because the "
                "damage is the thing it takes away - the answer is the STONE "
                "PLINTH the slab stands on, and the FIVE CUTS on each of its "
                "four faces are the gauge: one cut is one more wipe it has in "
                "it, and you can count them from any side of the room",
                0.40, "Someone is rubbing a name off the wall."),
})
ORDER = ORDER + ["scraper"]

# PER-SLOT MATERIALS, same argument the Dyer measured and the Relief re-stated:
# the tint-derived path pulls ONE hue over a whole body, and this body's whole
# read depends on a VALUE SPREAD - a near-black man against pale cut stone.
# 0.070 / 0.040 / 0.755 across three slots is a 19x range, and it is what makes
# the slab the brightest object in the frame and the man the darkest, so the
# thing the fight is about is the thing the eye lands on from the doorway.
OVERRIDE_ALLOWED = set(OVERRIDE_ALLOWED) | {"scraper"}

OVERRIDE.update({
    "scraper": {
        # THE MAN: crypt wool and dusty leather, the darkest value on the body
        # on purpose. The Moulder measured this and the Ratcatcher, Drover and
        # Beadle applied it: a DARK body against PALE furniture has its outline
        # carried by contrast, so no rim light has to be invented. Rough 0.88,
        # no metal - a clerk's coat is not the shiny thing here.
        'body': ((0.070, 0.066, 0.060), 0.88, 0.00),
        # STRAPS, BOOTS, THE HANDLE, THE SPARE SLATES AND EVERY CUT MARK. Near
        # black at 0.040 so the carved name-rows are countable dark marks on
        # pale stone and the five plinth cuts are five separate marks.
        # NAMED COMPROMISE, the same one the Relief and the Hooper named rather
        # than hid: the boots and the shoulder strap are leather and they live
        # in this slot, so they take an iron highlight they have not earned.
        'dark': ((0.040, 0.042, 0.048), 0.58, 0.28),
        # THE SLAB, THE PLINTH, THE SCOURING STONE, THE DUST HEAP, THE MASK:
        # pale dry limestone. Rough 0.82, no metal - a polished slab would read
        # as a mirror or a pot and this is chalk-dry worked stone.
        'bone': ((0.755, 0.730, 0.665), 0.82, 0.00),
        # THE EYES ONLY, and nothing else. Cold, small, and SUNK INSIDE THE
        # HOOD's own shadow so the glow cannot reach the frame edge at any yaw -
        # System 1's clipped-glow fault is a border check now, but a glow that
        # cannot get near the border is better than one the check has to catch.
        # NO LAMP ON THIS BODY: the light claim belongs to the Snuffer and this
        # creature makes none.
        'glow': ((0.72, 0.86, 0.98), 2.4),
    },
})


def scraper():
    """IT RUBS OUT WHAT YOU HAVE JUST DONE. The 41st body.

    WHAT A VIEWER READS FROM THE DOORWAY, AT ANY YAW:
      WHAT IS IT?        A stooped hooded clerk, near-black, bent over a PALE
                         GRAVE SLAB that stands on a stone plinth on the far
                         diagonal from him. He is the darkest thing in the
                         frame and the slab is the brightest.
      WHAT IS IT DOING?  SCOURING. Both hands are on a scouring stone pressed
                         flat against the slab's lower face, arms braced and
                         straight, shoulders rolled into it, and a PALE HEAP OF
                         DUST has piled at the slab's foot. The work is plainly
                         being done rather than stood beside.
      HOW FAR ALONG?     THE SLAB'S BOTTOM THIRD IS ALREADY GONE - it is
                         GROUND THINNER than the carved part above it, so the
                         slab has a waist in its SILHOUETTE and the before and
                         after are the same object. Above the waist: five rows
                         of cut name-marks. Below it: clean blank stone. The
                         bottom carved row is half-erased, mid-wipe.
      HOW MANY MORE?     FIVE CUTS on each of the plinth's four faces. One cut
                         is one more wipe. A square plinth yawed 45 degrees
                         shows two faces to every cardinal camera, so the count
                         is legible from front, back and both sides without a
                         floor disc - the Relief's problem, not the Relief's
                         answer.

    FACING IS BY CONSTRUCTION. FRONT (-Y): the pale dust mask, the two glow
    eyes under the hood brow, the braced arms, the stone. BACK (+Y): the strap
    cross, the stack of three spare slates and the chalk bag, and nothing pale
    above the belt but two thin slate edges. The slab itself is deliberately
    yaw-symmetric - BOTH broad faces are carved and both have the same scoured
    waist - because the facing is carried by the MAN and a slab that only reads
    from one side is a mechanic that disappears at the wrong camera angle. That
    is the Sealer's press fault answered in advance.

    ONE THING IS BROKEN ON PURPOSE. The slab's top cap is CHIPPED OFF at one
    end. A clean rectangle on a clean plinth reads as a door or a panel; a
    chipped cap and a waisted shaft read as a stone that has been worked on for
    a long time, and the irregularity is what keeps it out of the door family.

    Static: no `anims` entry, so bestiary.gd needs a `model` path and NO `anims`
    entry. The before and after are said by the geometry - the ground-away
    bottom third, the half-erased row, the dust on the floor.

    ROOM-LOCKED is NOT claimed here and NOT pre-judged: minibossgen measures
    the real footprint against floorgen's own corridor clear span and lid and
    the report says the verdict.
    """
    P = Parts("scraper")
    P.spans = {}
    _m = [0]

    def _open():
        _m[0] = len(P.items)

    def _close(name):
        P.spans[name] = (_m[0], len(P.items))

    # THE TWO MASSES SIT ON OPPOSITE ENDS OF A TRUE DIAGONAL, equal offsets in
    # x and y. This is the Relief's pass-2 lesson taken as a STARTING
    # CONDITION rather than discovered at pass 2: an offset that is longer in
    # one axis than the other is a cardinal offset with a lean on it, and the
    # camera that looks along the long axis sees the mechanic standing behind
    # the man. 0.78 in x and 0.64 in y is close enough to a true diagonal that
    # the worst case is a 45-degree yaw, and both cardinals see both masses
    # clear of each other.
    MX, MY = -0.38, 0.30          # the man
    SX, SY = 0.40, -0.34          # the slab and its plinth
    YAW = math.radians(45.0)
    CY, SI = math.cos(YAW), math.sin(YAW)

    def sw(u, v, z):
        """LOCAL SLAB FRAME -> WORLD. u runs along the slab's width, v out of
        its broad face, and +v is the face the man is working (checked
        numerically, not assumed: the slab->man vector dots +1.0 with it)."""
        return (SX + u * CY - v * SI, SY + u * SI + v * CY, z)

    T_UP = 0.150                  # carved shaft thickness
    T_LO = 0.092                  # scoured shaft thickness - THE WAIST
    W = 0.82                      # slab width
    Z_PL = 0.46                   # plinth top / slab foot
    Z_WAIST = 0.92                # where the scouring has reached
    Z_CAP = 1.88                  # top of the carved shaft

    _open()
    # ------------------------------------------------- THE MAN: BENT INTO IT
    # Staggered stance: right foot 0.17 forward, left 0.15 back, 0.32 apart in
    # y - comfortably more than a boot's depth, so a side camera sees two legs
    # and not one column with a single boot. seat() lifts each raked limb so
    # its bottom ring touches z=0 instead of dipping through it; minibossgen
    # grounds the merged body on its global minimum, so a hidden dip would lift
    # every honestly-placed foot on the body into the air.
    for s, fy in ((-1, 0.15), (1, -0.17)):
        pts = seat([(MX + s * 0.185, MY + fy * 0.35, 0.84),
                    (MX + s * 0.235, MY + fy * 0.80, 0.44),
                    (MX + s * 0.255, MY + fy, 0.095)], 0.100)
        limb(P, pts, 0.100, 0.080, 'body')
        P.add(L.box(0.235, 0.385, 0.105), 'dark',
              loc=(MX + s * 0.255, MY + fy - 0.035, 0.0525))
    # THE STOOP. Hip 0.82, shoulder 1.56, and the whole torso carried 0.30 m
    # forward in y over that run - a man leaning on a stone with his weight,
    # not standing to attention. The lean is also what makes the arms reach the
    # slab without being authored over-long.
    limb(P, [(MX, MY + 0.03, 0.80), (MX - 0.02, MY - 0.11, 1.20),
             (MX - 0.04, MY - 0.27, 1.56)], 0.250, 0.230, 'body')
    P.add(L.box(0.545, 0.275, 0.085), 'dark', loc=(MX, MY - 0.01, 0.98))
    for s in (-1, 1):
        P.add(L.sphere(0.150, 0.140, 0.125, 12, 8), 'body',
              loc=(MX + s * 0.265, MY - 0.27, 1.56))
    # THE HOOD. A cowl sphere and a drawn peak over it, crown at 2.02 - the
    # MAN is the top of the silhouette and the slab is a clear second mass, so
    # the read is A MAN DOING A JOB and not a wall with a crumb beside it.
    P.add(L.sphere(0.170, 0.180, 0.205, 14, 10), 'body',
          loc=(MX - 0.05, MY - 0.30, 1.78))
    P.add(aim(L.cone(0.225, 0.070, 0.255, 14), (MX - 0.05, MY - 0.26, 1.77),
              (0.0, -0.26, 1.0)), 'body')
    # THE DUST MASK: the ONE pale thing above the belt, front face only, and a
    # brow bar over it so the eyes sit in their own shadow.
    P.add(L.box(0.185, 0.050, 0.105), 'bone',
          loc=(MX - 0.05, MY - 0.445, 1.735), rot=(0.20, 0.0, 0.0))
    P.add(L.box(0.215, 0.075, 0.045), 'dark',
          loc=(MX - 0.05, MY - 0.425, 1.845))
    eyes(P, (MX - 0.05, MY, 1.820), 0.058, 0.0245, -0.375)
    _close("man")

    _open()
    # ---------------------------------------------- THE BACK: NOT A BLANK PANEL
    # Fault 3 of my own Relief write-up, designed against. Three spare slates on
    # a strap across the shoulders, dark with thin pale edges only, plus the
    # chalk bag at the hip. The back gets a FEATURE and still gets no pale mass,
    # so the facing survives it.
    for i in range(3):
        P.add(L.box(0.425 - i * 0.035, 0.055, 0.315 - i * 0.030), 'dark',
              loc=(MX + 0.01, MY + 0.175 + i * 0.062, 1.33 - i * 0.020),
              rot=(0.0, 0.0, 0.10 * (i - 1)))
        P.add(L.box(0.425 - i * 0.035, 0.016, 0.028), 'bone',
              loc=(MX + 0.01, MY + 0.175 + i * 0.062,
                   1.33 - i * 0.020 + (0.315 - i * 0.030) * 0.5))
    for s in (-1, 1):             # the strap cross
        limb(P, [(MX + s * 0.245, MY - 0.24, 1.60),
                 (MX - s * 0.085, MY + 0.215, 1.16)], 0.038, 0.034, 'dark')
    P.add(L.sphere(0.135, 0.105, 0.145, 12, 8), 'dark',
          loc=(MX - 0.235, MY + 0.175, 0.90))
    _close("back")

    _open()
    # --------------------------------------- THE ARMS AND THE SCOURING STONE
    # Both hands on one stone, pressed flat on the slab's lower face. The stone
    # TOUCHES the slab and the handle TOUCHES both hands, so the force has
    # somewhere to go and the machine is being worked - the Drillmaster's
    # pass-2 lesson and the Relief's heaving arms, applied here at pass 1.
    HAND_N = sw(-0.055, T_LO * 0.5 + 0.145, 0.735)      # near hand
    HAND_F = sw(0.135, T_LO * 0.5 + 0.185, 0.800)       # far hand
    for s, H in ((1, HAND_N), (-1, HAND_F)):
        limb(P, [(MX + s * 0.265, MY - 0.27, 1.54),
                 ((MX + s * 0.265) * 0.45 + H[0] * 0.55,
                  (MY - 0.30) * 0.45 + H[1] * 0.55, 1.14),
                 H], 0.095, 0.072, 'body')
        P.add(L.sphere(0.085, 0.085, 0.080, 10, 7), 'dark', loc=H)
    # THE STONE: a pale block flat on the face, and its dark handle bar behind
    # it running through both grips.
    P.add(L.box(0.285, 0.105, 0.095), 'bone',
          loc=sw(0.040, T_LO * 0.5 + 0.055, 0.768), rot=(0.0, 0.0, YAW))
    limb(P, [sw(-0.095, T_LO * 0.5 + 0.145, 0.735),
             sw(0.175, T_LO * 0.5 + 0.185, 0.805)], 0.030, 0.030, 'dark')
    _close("stone")

    _open()
    # ------------------------------- THE PLINTH: THE GAUGE AND THE WEAK POINT
    # 0.62 square, 0.46 tall, yawed with the slab. FIVE cuts on EACH of the
    # four faces. The cuts are 0.055 wide on a 0.62 face with ~0.055 of stone
    # between them - the Hooper's pass-6 spacing finding (five rings at 0.13 m
    # read as one helix) applied before the first render: at 0.11 m pitch on a
    # 0.62 m face they are five marks, not a hatch.
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
    # TWO shafts, not one, and the lower is THINNER. That step is the mechanic
    # in the SILHOUETTE: a slab with a waist where the stone has been ground
    # away. A surface-only erasure would have been invisible in outline and
    # invisible to every number this lane computes.
    P.add(L.box(W, T_LO, Z_WAIST - Z_PL), 'bone',
          loc=sw(0.0, 0.0, (Z_PL + Z_WAIST) * 0.5), rot=(0.0, 0.0, YAW))
    P.add(L.box(W, T_UP, Z_CAP - Z_WAIST), 'bone',
          loc=sw(0.0, 0.0, (Z_WAIST + Z_CAP) * 0.5), rot=(0.0, 0.0, YAW))
    # THE CAP, CHIPPED OFF AT ONE END - see the docstring. 0.70 of the width
    # instead of 0.88, pushed to the -u end, so the top corner is missing.
    P.add(L.box(0.700, T_UP + 0.055, 0.062), 'bone',
          loc=sw(-0.085, 0.0, Z_CAP + 0.031), rot=(0.0, 0.0, YAW))
    # THE NAME ROWS, ON BOTH BROAD FACES. Five rows of three cuts above the
    # waist; the BOTTOM row is half-erased (two cuts, both short) because the
    # wipe is in progress and that is the one row the stone has reached.
    for sv in (1.0, -1.0):
        vf = sv * (T_UP * 0.5 - 0.010)
        for row in range(5):
            z = 1.035 + row * 0.170
            n_marks = 2 if row == 0 else 3
            for c in range(n_marks):
                wmark = 0.105 if row == 0 else 0.195
                u = -0.245 + c * 0.245
                P.add(L.box(wmark, 0.055, 0.042), 'dark',
                      loc=sw(u, vf, z), rot=(0.0, 0.0, YAW))
    _close("slab")

    _open()
    # --------------------------------------------- THE DUST: THE WORK IS REAL
    # A low pale heap on the floor at the working face. Built through _rev so it
    # is the same width at every yaw, and it lies ON the floor, which is the one
    # place a camera standing on the floor cannot hide.
    P.add(_rev([(0.000, 0.430), (0.055, 0.370), (0.135, 0.215),
                (0.205, 0.000)], 20), 'bone', loc=sw(0.015, 0.365, 0.0))
    # and the scoured spill running back toward his boots, so the heap belongs
    # to HIM and is not a rock that happens to be there.
    P.add(_rev([(0.000, 0.215), (0.038, 0.160), (0.075, 0.000)], 16),
          'bone', loc=sw(-0.225, 0.560, 0.0))
    _close("dust")
    return P


BUILDERS.update({"scraper": scraper})
