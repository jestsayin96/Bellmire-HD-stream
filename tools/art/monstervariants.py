"""monstervariants.py - THE SECOND CLASS OF MINIBOSS.

PART 2 of the supervisor's 21:50 CT directive of 19 Nov 2026, which carries
Mr. E's own recipe verbatim in substance: take a creature that already exists
in the CC0/QAL packs, RECOLOUR it, SCALE IT UP past its regular version, give
it a character name and a mechanic that changes the fight, and fit-proof it on
a hero body to the same standard as the thirty-six procedural minibosses.

  blender -b -noaudio -P tools/art/monstervariants.py -- --repo <W5> \
      [--only <key>] [--export] [--fit] [--prove-red]

THE RULE THIS FILE OBEYS FIRST (Mr. E, 16 Nov 04:46): DO NOT MAKE WHAT ALREADY
EXISTS. Nothing here is modelled. Every triangle is the pack author's, and the
only two things this file does to it are the two things the directive asks for:
a different palette and a bigger number. That is the whole point of the class -
it is cheap on purpose, and the saving is why a second source of minibosses is
worth having at all.

*** THE PALETTE IS NOT A TINT, AND IT IS NOT MINE EITHER. ***
Measured, not remembered, 19 Nov 2026 22:4x CT: the Bestiary - Dungeon Monsters
Kit ships THREE base-colour maps per creature, and this repo committed only the
first. `T_Puglin_BaseColor_1` (mean rgb 0.388/0.393/0.127, dominant olive) is
the regular `puglin` in bestiary.gd. `_2` (0.437/0.205/0.207, dominant
0.438/0.188/0.188) is a RED skin by the same author, hand-authored over the
same UVs, and `_3` is a teal one. So the recolour costs nothing, keeps the
normal and ORM detail intact, and cannot go muddy the way a multiply tint over
an olive map would. Mr. E's own example for this class was "a regular Goblin is
small and green, its variant is 1.5x and dark red/black" - the Puglin is the
nearest thing this repo has to that goblin and the author already drew the red.

*** THE ONE THING THIS CLASS CANNOT DO, SAID HERE RATHER THAN DISCOVERED LATER. ***
The thirty-six hold a SILHOUETTE test: throw the colour away and each must read
as itself. A pack variant CANNOT pass that against its own regular version,
because it IS its own regular version - same mesh, same pose, same outline.
What separates them is SCALE and COLOUR, and scale is the half of that which
survives a silhouette. This is a property of the class the directive asked for,
not a defect in this creature, and the register records the silhouette ratio
rather than pretending the test was passed.

LICENCE. Quaternius Asset License (QAL) v1.0 - worldwide, royalty-free,
perpetual, commercial use permitted, no attribution required; the only
restriction is reselling or redistributing the assets AS assets, which a
creature inside our own dungeon is not. Licence text read off disk this run at
`_packs/Bestiary_Dungeon_Monsters_Kit/.../License_Standard.txt`, not off a
search snippet. Logged in docs/art/ASSET_SOURCES.md.
"""
import math
import os
import sys
import json
import argparse

import bpy
import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import lordgen as G             # noqa: E402
import floorgeom as FG          # noqa: E402

PACK = os.path.join("C:\\", "hd adventure", "_packs",
                    "Bestiary_Dungeon_Monsters_Kit",
                    "Bestiary - Dungeon Monsters Kit[Standard]")
TEXDIR = os.path.join(PACK, "Textures")

# *** THE STRAY ICOSPHERE IS NOT IN THE PACK FILE, AND THIS LANE HAS BEEN
# *** SAYING OTHERWISE IN THREE PLACES SINCE AT LEAST 17 NOV. CORRECTED HERE
# *** 19 NOV 2026 22:5x CT, ON A BYTE SEARCH AND TWO CONTROLS.
# It would have wrecked the first measurement either way: imported raw, the
# puglin reports 1.902 x 2.000 x 2.000, which is a sphere of radius 1 on the
# origin and not the creature. Dropped, the body is 1.468 x 0.611 x 0.931.
# So dropping it is right and stays. What was WRONG was the reason given for
# it - minibossfit.py, e3pogen.py and docs/art/MINIBOSS_FIT.md all say the glb
# "ships" a stray Icosphere, and it does not:
#   1. the string "Icosphere" occurs ZERO times in the bytes of a glb that
#      nonetheless imports one (broodglut.glb, 3,124,424 bytes; its JSON chunk
#      carries 59 nodes, 3 meshes, no such name);
#   2. a RIGGED pack glb gets one (Frog.glb -> Armature, Frog, Icosphere);
#   3. an UNRIGGED glb of our own does not (beadle.glb -> four meshes, clean).
# It is a Blender 5.2 glTF-import artifact that appears for a glb carrying an
# armature. It is therefore NOT in the shipped asset, NOT in Godot, and NOT a
# defect for the game build lane to chase - which is what a lane acting on the
# old wording would have been sent to do. The handling was right and the
# explanation was wrong, which is the same shape as this lane's two earlier
# instrument faults: the action passed, the reason did not.
STRAY = ("Icosphere",)

# key -> spec. Same seven-field shape as minibosses.CANON plus the source, so
# anything that reads one can read the other.
VARIANTS = {
    "broodglut": dict(
        title="Broodglut",
        source=os.path.join("assets", "monsters", "Puglin.glb"),
        regular="puglin",               # bestiary.gd key of the small version
        regular_h=0.90,                 # bestiary.gd `h` for that key, read off the file
        # PASS 2, 19 Nov 22:5x CT, AND IT IS A CHANGE MADE BY LOOKING. Pass 1
        # authored 2.30 and every number in the register was green - 0 blanks,
        # 0 frame clips, 3 of 3 proving views, seen 1.0 everywhere. Then I
        # looked at hero_front.png: at 2.30 against a 2.45 m hero this thing's
        # head sits BELOW the hero's, because the body is a hunch and its
        # height is bulk rather than stature. It read as a wide peer, not as
        # something you have met trouble in. 2.60 is still inside the band the
        # thirty-six occupy (2.00 - 2.75; the Snuffer is 2.60) and it is 2.89x
        # its own regular version, which is the number the directive actually
        # asks about. ONE thing changed in this pass and nothing else.
        #
        # PASS 4, 20 Nov 2026 00:4x CT - MR. E LOOKED AT PASS 3's SHEET AND
        # THE SUPERVISOR'S 00:10 DIRECTIVE IS THE ANSWER: "it looks the same
        # size as the hero knight... a miniboss needs to tower over the heroes
        # ... minimum 2-3x the hero's height." Pass 2's reasoning was right
        # about the body (its height is bulk, not stature) and WRONG about the
        # target: 2.60 against a 2.45 m hero is ratio 1.06, and that is
        # EYE-LEVEL. The sentence that stood here until 20 Nov 01:3x CT said
        # "every one of the thirty-six sits at the same 1.06. The whole band
        # was eye-level" - and that was WRONG, disproved by this lane's own
        # measurement in the very commit that wrote it (the team lead caught
        # the contradiction; it is web/index.html:49 again, a comment stating
        # what its author had already replaced). THE MEASURED NUMBERS, taken
        # twice this run by two different cuts:
        #   off the CANON tables in tools/art/minibosses.py - 36 procedural
        #     minibosses, authored height 1.95 m (reeve) to 2.95 m (beadle),
        #     ratio 0.80 to 1.20 against the 2.45 m hero. EXACTLY TWO sit at
        #     1.06 - snuffer and dyer, both 2.60 m. Not thirty-six. Two.
        #   off every renders/art/minibosses/_fit_*_register.json - 31 pair
        #     records over 20 bodies, ratio 0.84 to 1.20, four records at 1.06
        #     (snuffer, its chibi twice, and dyer: the extra two are chibi
        #     duplicates of one body, which is why a register sweep reads four
        #     where the authored table reads two).
        # So the band is not a point. What is true, and is the thing the 00:10
        # directive was answering, is that MORE THAN HALF THE CLASS IS AT OR
        # BELOW 1.0x A HERO - 17 of 36 authored at or under 1.00 (drover is
        # 2.44 m, 0.9959, and counts) - and nothing
        # in it towers. Broodglut's 1.06 was typical of the band, not alone in
        # it. The supervisor ruled at 01:16 CT that THE PROCEDURAL 36 STAY at
        # their current scale and only PACK VARIANTS tower; see
        # docs/art/MONSTER_VARIANTS.md for the two design languages.
        #
        # 6.60 m is NOT a free choice - IT IS THE TOP OF A MEASURED BAND AND
        # THE DIRECTIVE'S OWN 3x DOES NOT FIT IN IT. The directive keeps the
        # corridor gate ("it has to fit a three-cell corridor"), and
        # minibossgen's corridor clear is 3*4.0 - 2*0.5 = 11.0 m. This body is
        # authored in a T-POSE whose arm span scales with the height at
        # 1.576731 m of span per metre of height (4.0995 / 2.60, measured in
        # pass 3). So:
        #     ratio 2.00 -> h 4.90  span  7.73   margin 3.27
        #     ratio 2.69 -> h 6.60  span 10.41   margin 0.59   <- taken
        #     ratio 2.85 -> h 6.98  span 11.00   margin 0.00   <- the hard wall
        #     ratio 3.00 -> h 7.35  span 11.59   ROOM-LOCKED
        # 3x cannot be had corridor-safe on the T-pose span. 6.60 is 2.69x the
        # hero and 7.33x its own regular puglin, and it leaves 0.59 m of
        # corridor margin on the WORST CASE rather than on the pose the game
        # draws - bestiary.gd grafts the UAL library on at load, so the arms
        # come down and the real footprint is narrower than this gate. THE WAY
        # TO 3x, IF MR. E WANTS IT, IS TO MEASURE THE SPAN IN THE UAL IDLE
        # INSTEAD OF THE T-POSE, or to room-lock the spawn. Not taken this
        # pass: ONE thing changed and nothing else.
        height=6.60,                    # authored miniboss height, metres
        palette="T_Puglin_BaseColor_2.png",
        # PASS 3, 20 Nov 2026, AND IT IS THE TEAM LEAD'S EYE MADE INTO
        # GEOMETRY. He looked at pass 2's hero_front.png and wrote the one
        # fault no number in the register could reach: "IN THE FRONT VIEW THE
        # EARS READ AS A SECOND PAIR OF ARMS. They leave the head at the same
        # angle, the same hue and nearly the same taper as the real arms."
        # Measured afterwards by tools/art/_bg_sil_runs.py: 234 of 234 ear
        # columns carried ONE vertical run - the ear's visible outline rested
        # flush on the arm's upper edge with no background between them
        # anywhere. The pack's 55-bone rig has NO ear bone (all 1531 head-and-
        # ear vertices ride `Head`), so this is geometry and not a pose.
        # The ear is turned about its own measured root: back behind the skull
        # and lifted, so it leaves the head on a different line from the arm
        # and the sky comes through between them. Chosen over a 60 deg droop
        # and two shallower sweeps BY LOOKING at four silhouette sheets - the
        # droop squared the skull off and hung the ears as spikes under the
        # armpits, which is a worse read than the one it fixed.
        ear_pitch_deg=40.0,             # + lifts the tip
        ear_yaw_deg=45.0,               # + sweeps it back behind the skull
        theme="mess",
        aura=(1.00, 0.42, 0.30),        # the rig's warm key, red end
        idea=("IT EATS ITS OWN - while any lesser puglin in the room still "
              "lives it will take one, swallow it, and close its own wounds; "
              "the swarm is its health and the big one is not the target"),
        line="Something in here is eating the little ones.",
        note=("ADJACENCY DECLARED RATHER THAN HIDDEN: miniboss 8, Blisterhand "
              "(ex-Cook), KEEPS THE PACK ALIVE. This is the arrow reversed - "
              "the pack keeps IT alive - so the party's decision is inverted "
              "(kill the adds, not the boss) instead of repeated. If Mr. E "
              "reads it as the same idea twice, the fix is one word in the "
              "idea string and no geometry."),
    ),
    "lastcuff": dict(
        title="Lastcuff",
        source=os.path.join("assets", "monsters", "Imp.glb"),
        regular="imp",                  # bestiary.gd key of the small version
        regular_h=1.30,                 # bestiary.gd `h` for "imp", read off the file
        # THE SECOND PACK VARIANT, 20 Nov 2026 01:4x CT. The supervisor's 01:16
        # ruling is that PACK VARIANTS TOWER and the procedural 36 stay at
        # eye level, so this one is authored to tower - and the body was picked
        # on a MEASUREMENT rather than on taste.
        #
        # WHY THE IMP AND NOT ANOTHER. Measured off the pack's Textures dir
        # this run: only TWO creatures in the Bestiary - Dungeon Monsters Kit
        # ship three BaseColor maps, `T_Imp` and `T_Puglin`. The Puglin is
        # Broodglut. So the Imp is the whole remaining supply of this class,
        # and the class's recipe (recolour + scale, nothing modelled) is only
        # available where the author already drew a second skin.
        #
        # AND IT IS THE BODY THAT CAN CARRY HEIGHT. Broodglut is capped by its
        # own T-pose arm span: 4.0995 / 2.60 = 1.576731 m of span per metre of
        # height, so an 11.0 m corridor runs out at 2.85x the hero. The Imp is
        # also a T-pose, but a far narrower one - measured on the evaluated
        # depsgraph with the stray Icosphere dropped, native X 1.7538 (the arm
        # span, symmetric about the origin at +/-0.8769) over native Z 1.6779
        # (the height, feet at z -0.002) = 1.045 m of span per metre, a THIRD
        # less than the Puglin. At 6.20 m its span is 6.48 m and the corridor
        # leaves 4.52 m of margin. The corridor is not what caps this one.
        #
        # *** WHAT CAPS IT IS THE CEILING, AND NOBODY IN THIS HOUSE HAD
        # *** MEASURED THE CEILING UNTIL THIS RUN. floorgen.gd builds a lid -
        # *** `BoxMesh` size (w*G+14, 1.0, h*G+14) at `position = (0, 7.0, 0)`,
        # *** SHADOWS_ONLY, there so the overworld sun does not flood the
        # *** floor - so its UNDERSIDE is at 7.0 - 0.5 = 6.50 m. A creature
        # *** standing on z=0 is through it above 6.50 m, which is 2.653x the
        # *** 2.45 m hero. The kit wall tops are 4 m (floorgen's own stairs
        # *** comment: "3.8 m up, under the 4 m wall top"), so anything in this
        # *** class already stands head and shoulders over the walls.
        # So Mr. E's 3x (7.35 m) is NOT available to any body on any width -
        # not Broodglut's, not this one's - without raising the lid or
        # room-locking. 6.20 m leaves 0.30 m under the lid, and that margin is
        # the reason this is 2.53x rather than the 2.6x the lid would just
        # allow. See docs/art/MONSTER_VARIANTS.md; Broodglut's shipped 6.60 is
        # 0.10 m THROUGH the lid and that is a fault in this lane's own work,
        # reported rather than quietly corrected under a second change.
        height=6.20,                    # 2.53x the hero, 4.77x its own regular imp
        palette="T_Imp_BaseColor_3.png",
        # Measured, not remembered, this run: the regular `imp` wears
        # BaseColor_1 (mean rgb 0.3937/0.2130/0.2021, red-brown). `_2` is olive
        # (0.3804/0.3470/0.1638) - which is the colour the regular PUGLIN
        # already wears, so it would read as a cousin of the wrong monster.
        # `_3` is taken. All three are 2048 and hand-authored over the same UVs
        # by the pack author, so the normal and ORM detail survive the swap.
        #
        # *** AND THE NUMBER I CHOSE IT ON WAS A BAD WITNESS. I CALLED `_3`
        # *** "ASH GREY" OFF ITS MEAN (0.3897/0.3837/0.4154 - near neutral,
        # *** faintly blue) AND THEN LOOKED AT THE RENDER: IT IS A SATURATED
        # *** BLUE-CYAN SKIN WITH VIOLET FOREARMS, SHINS AND FEET.
        # A mean over a whole 2048 map averages skin, shorts, horn, claw and
        # every unused corner of the UV sheet into one neutral number, so it
        # answers HOW BRIGHT and says nothing about HUE or about WHERE on the
        # body a hue sits. Same family as `mask_of` at pass 11 - a metric that
        # cannot see the viewer's question reads green on anything. The colour
        # is kept (blue-violet is neither the red-brown imp you know nor
        # Broodglut's red, which is all the class asks of it) but the reason in
        # this file now matches the picture. THE PICTURE IS THE EVIDENCE.
        theme="cells",
        aura=(0.70, 0.76, 0.88),        # cold key: ash and iron, not Broodglut's warm red
        # *** THE IDEA THIS SPEC SHIPPED WITH WAS NOT IN THE MESH, AND THE
        # *** RENDER IS WHAT CAUGHT IT. It was called "Chainsweep" and its
        # *** mechanic was a mace running out on a chain to sweep the lane.
        # I then looked at hero_front.png: `Imp_Chains` is FOUR SHACKLE CUFFS
        # (both wrists, both ankles) plus a studded collar, and `Imp_Mace` is
        # held flat against the hand. There is no long chain and nothing runs
        # out. A mechanic the geometry cannot show is the fault this lane is
        # told to catch before it ships, not after, so the idea is replaced by
        # one the body already carries - and it is a BETTER one, because the
        # state is visible ON the model and a viewer can count it.
        idea=("IT IS STILL IN IRONS, AND EVERY ONE YOU KNOCK OFF MAKES IT "
              "FASTER - five shackles, four cuffs and a collar; hurt it and "
              "one goes, and the thing that was lumbering is not lumbering any "
              "more. Kill it early or race something you have been unlocking"),
        line="The irons in here are off something.",
        note=("THE STATE IS ON THE MODEL AND THAT IS WHY THIS IDEA WAS TAKEN: "
              "five removable pieces the pack author already modelled, so a "
              "viewer can SEE how far gone the fight is without reading a stat "
              "- Mr. E's binding principle applied to a mechanic rather than to "
              "a costume. Nothing in the thirty-six ramps speed, and none of "
              "them carries its own progress as geometry. ADJACENCY DECLARED: "
              "Shacklemaw (gaoler) also fights in chains, but his are a hook he "
              "USES on you and these are irons used ON IT, so the two read as "
              "jailer and escapee rather than as one idea twice. WIRING NOTE "
              "FOR THE GAME BUILD, NOT A REQUEST: the shackles are five named "
              "meshes in the shipped glb (Imp_Chains carries the four cuffs, "
              "Imp_SpikedCollar the fifth); hiding them one at a time is how "
              "the mechanic would show, and if that is not wanted the idea "
              "still works unseen."),
    ),
}
ORDER = ["broodglut", "lastcuff"]


def _drop_stray(objs):
    out, dropped = [], []
    for o in list(objs):
        if o.name.split(".")[0] in STRAY:
            dropped.append(dict(name=o.name,
                                hidden_render=bool(o.hide_render),
                                hidden_view=bool(o.hide_get() if o.name in
                                                 bpy.context.view_layer.objects else False),
                                verts=len(o.data.vertices) if o.type == 'MESH' else 0))
            bpy.data.objects.remove(o, do_unlink=True)
        else:
            out.append(o)
    return out, dropped


def _repalette(spec, maxpx=1024):
    """Swap every BaseColor map for the pack's alternate, and bring all four
    maps down to `maxpx` so the shipped glb is a game asset and not a 7.8 MB
    one. The repo's own precedent is Mr. E's wand (three 1024 maps, 2.38 MB).

    Reads as Non-Color on purpose so sRGB bytes round-trip, which is this
    lane's standing rule for anything measured with numpy."""
    rep = {"swapped": [], "resized": [], "mean_before": None, "mean_after": None}
    src = os.path.join(TEXDIR, spec["palette"])
    assert os.path.isfile(src), "variant palette missing on disk: %s" % src
    new = bpy.data.images.load(src, check_existing=False)
    new.colorspace_settings.name = 'Non-Color'
    rep["mean_after"] = _mean(new)
    if max(new.size) > maxpx:
        new.scale(maxpx, maxpx)
    new.pack()
    for m in bpy.data.materials:
        if not m.node_tree:
            continue
        for n in m.node_tree.nodes:
            if n.type != 'TEX_IMAGE' or n.image is None:
                continue
            if "BaseColor" in n.image.name:
                if rep["mean_before"] is None:
                    n.image.colorspace_settings.name = 'Non-Color'
                    rep["mean_before"] = _mean(n.image)
                rep["swapped"].append("%s/%s: %s -> %s"
                                      % (m.name, n.name, n.image.name, spec["palette"]))
                n.image = new
            elif max(n.image.size) > maxpx:
                n.image.scale(maxpx, maxpx)
                n.image.pack()
                rep["resized"].append(n.image.name)
    # the base colour is sampled through an sRGB view in the end, so put it back
    new.colorspace_settings.name = 'sRGB'
    rep["palette_px"] = list(new.size)
    return rep


def _mean(img):
    w, h = img.size
    a = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(a)
    a = a.reshape(h, w, 4)
    m = a[..., 3] > 0.5
    if not m.any():
        return None
    return [round(float(x), 4) for x in a[..., :3][m].mean(axis=0)]


EAR_X0 = 0.20       # measured: Head-dominant geometry runs |x| 0.20 -> 0.443
EAR_RAMP = 0.20     # the turn reaches its full angle within this much of the ear


def ear_indices(body, x0=EAR_X0):
    """The ear vertices, found by weight and reach rather than by name.

    THE RIG HAS NO EAR BONE. tools/art/_bg_ears_probe.py read all 55 and not
    one is an ear; the whole head, both ears included, is 1531 vertices riding
    `Head`. So the ears are the Head-dominant vertices that reach past the
    skull, and `x0` is where the head's own vertex count collapses (394 in the
    slice 0.15-0.20, then 166 in 0.20-0.25) - the ear root, measured."""
    inv = {g.index: g.name for g in body.vertex_groups}
    mw = body.matrix_world
    out = []
    for v in body.data.vertices:
        best, bw = None, -1.0
        for ge in v.groups:
            if ge.weight > bw:
                bw, best = ge.weight, ge.group
        if inv.get(best) == "Head" and abs((mw @ v.co).x) > x0:
            out.append(v.index)
    return out


def ear_turn(body, idx, pitch_deg, yaw_deg, x0=EAR_X0, ramp=EAR_RAMP):
    """Turn each ear about its own root and carry it along the resulting arc.

    Arc length is preserved, so the ear keeps the pack author's length and
    taper and only its DIRECTION changes - one thing at a time. The turn
    reaches full angle within `ramp` of the ear and holds it, so the outer
    four-fifths rotate rigidly and only the root blends; a smoothstep over the
    root means no crease where ear meets skull. The cross-section rides the
    arc's own frame (tangent plus its two normals) so the flap rotates with
    the ear instead of shearing flat.

    *** THE FIRST VERSION OF THIS RAMPED THE TURN ACROSS THE WHOLE EAR AND
    *** COULD NOT MOVE IT: at yaw 55 deg the tip travelled 0.089 on a 0.243
    long ear and span_y did not change at all. Four candidate sheets would
    have come out looking alike and invited the conclusion that no deform
    helps. A deform whose strongest setting barely displaces its subject is
    this lane's "instrument that cannot move" wearing the other hat."""
    if not idx:
        return {"moved": 0}
    co = {i: body.data.vertices[i].co.copy() for i in idx}
    L = max(abs(c.x) - x0 for c in co.values())
    if L <= 1e-6:
        return {"moved": 0}
    P, Y = math.radians(pitch_deg), math.radians(yaw_deg)
    near = [c for c in co.values() if abs(c.x) - x0 < 0.15 * L] or list(co.values())
    y_r = sum(c.y for c in near) / len(near)
    z_r = sum(c.z for c in near) / len(near)

    def turn(u):
        if u >= ramp:
            return 1.0
        t = u / ramp
        return t * t * (3.0 - 2.0 * t)

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
        u = min(1.0, max(0.0, (abs(c.x) - x0) / L))
        k = int(round(u * N))
        t = turn(u)
        ap, ay = P * t, Y * t
        n1 = (-math.sin(ay), math.cos(ay), 0.0)
        n2 = (-math.sin(ap) * math.cos(ay), -math.sin(ap) * math.sin(ay), math.cos(ap))
        oy, oz = c.y - y_r, c.z - z_r
        ax_, ay_, az_ = arc[k]
        body.data.vertices[i].co = type(c)((
            sgn * (x0 + ax_ + oy * n1[0] + oz * n2[0]),
            y_r + ay_ + oy * n1[1] + oz * n2[1],
            z_r + az_ + oy * n1[2] + oz * n2[2]))
    body.data.update()
    return {"moved": len(co), "ear_len": round(L, 4),
            "root": [x0, round(y_r, 4), round(z_r, 4)],
            "tip_centreline": [round(x0 + arc[-1][0], 4),
                               round(y_r + arc[-1][1], 4),
                               round(z_r + arc[-1][2], 4)],
            "pitch_deg": pitch_deg, "yaw_deg": yaw_deg}


def build_variant(key, repo):
    """Same contract as minibossgen.build_miniboss: returns (objs, info) with
    the creature scaled to its authored height and its feet on z = 0."""
    spec = VARIANTS[key]
    path = os.path.join(repo, spec["source"])
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new_objs = [o for o in bpy.data.objects if o not in before]
    new_objs, dropped = _drop_stray(new_objs)
    ear = {"moved": 0}
    if spec.get("ear_pitch_deg") or spec.get("ear_yaw_deg"):
        _body = next((o for o in new_objs
                      if o.type == 'MESH' and o.name.startswith("Puglin_Body")), None)
        if _body is not None:
            ear = ear_turn(_body, ear_indices(_body),
                           spec.get("ear_pitch_deg", 0.0), spec.get("ear_yaw_deg", 0.0))
    pal = _repalette(spec)
    meshes = [o for o in new_objs if o.type == 'MESH']
    rig = next((o for o in new_objs if o.type == 'ARMATURE'), None)
    roots = [o for o in new_objs if o.parent is None]
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(meshes)
    native = mx.z - mn.z
    k = spec["height"] / native if native > 1e-6 else 1.0
    for o in roots:
        o.scale = (o.scale.x * k, o.scale.y * k, o.scale.z * k)
        o.location = (o.location.x * k, o.location.y * k, o.location.z * k)
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(meshes)
    for o in roots:
        o.location = (o.location.x, o.location.y, o.location.z - mn.z)
    bpy.context.view_layer.update()
    mn, mx, _ = G.world_bounds(meshes)
    info = dict(spec)
    info.update(native_h=round(native, 5), scale_k=round(k, 5),
                measured_h=round(mx.z - mn.z, 4),
                span_x=round(mx.x - mn.x, 4), span_y=round(mx.y - mn.y, 4),
                stray_dropped=dropped, palette_report=pal, ear_turn=ear,
                bones=(len(rig.data.bones) if rig else 0),
                meshes=[o.name for o in meshes],
                tris=_tris(meshes),
                aura=spec["aura"])
    return meshes, roots, info


def _tris(meshes):
    dg = bpy.context.evaluated_depsgraph_get()
    n = 0
    for o in meshes:
        ev = o.evaluated_get(dg)
        me = ev.to_mesh()
        me.calc_loop_triangles()
        n += len(me.loop_triangles)
        ev.to_mesh_clear()
    return n


def export_variant(key, repo, roots, meshes):
    """Export at NATIVE scale, not at the authored miniboss height.

    WHY, and it is a measurement and not a preference: `Monster` in
    bestiary.gd normalises every monster body to the entry's `h` from its own
    measured bounds (bestiary.gd ~10), so the glb's authored size is thrown
    away at load. Shipping a pre-scaled mesh would therefore put the number in
    two places that can disagree, and the number that wins is the one in
    bestiary.gd. The scale goes in the WIRING, where the engine reads it; the
    glb carries only what the engine keeps - the geometry and the new skin."""
    for o in roots:
        o.scale = (1.0, 1.0, 1.0)
        o.location = (0.0, 0.0, 0.0)
    bpy.context.view_layer.update()
    out = os.path.join(repo, "assets", "monsters", "minibosses", "%s.glb" % key)
    for o in bpy.data.objects:
        o.select_set(False)
    for o in roots + meshes:
        try:
            o.select_set(True)
        except Exception:
            pass
    bpy.ops.export_scene.gltf(filepath=out, export_format='GLB',
                              use_selection=True, export_apply=False,
                              export_animations=False)
    return out, os.path.getsize(out)


def fit(key, repo, prove_red=False):
    """THE FIT PROOF, AND IT IS NOT A SECOND STANDARD.

    This calls minibossfit's own `import_hero`, `place` and `shoot` rather than
    re-deriving them, so the variant is measured by the same instrument as the
    thirty-six: the real KayKit adventurer at scale 1.0, one fixed ortho frame,
    one fixed ground line, front/side/back, and all three of that file's
    checks - blank, frame-border per edge, and the with/without occlusion test
    that asks the VIEWER'S question instead of rendering a thing alone.

    A second harness would be a second set of numbers to disagree about, and
    this lane has already shipped one instrument that could not see and one
    that could not move. Reuse is the cheaper honesty."""
    import minibossfit as F
    if prove_red:
        F.PROVE_RED = True
    meshes, roots, info = build_variant(key, repo)
    hroots, hmesh, hero = F.import_hero(repo)
    mn, mx, _ = G.world_bounds(meshes)
    F.place(hroots, mn.x - F.GAP - hero["w"] / 2.0 - 0.10,
            mn.y - F.GAP - hero["d"] / 2.0 - 0.10)
    allo = meshes + hmesh
    bpy.context.view_layer.update()
    amn, amx, pts = G.world_bounds(allo)

    # *** THE FRAME, AND PASS 2 REPORTED THIS WRONG. ***
    # minibossfit's standard cell is FRAME_W 5.60 m. This pair is 5.96 m wide,
    # because the pack body is authored in a T-pose and its 4.10 m arm span
    # plus a hero and the gap simply do not fit a 5.60 m cell. Pass 2 recorded
    # `fits_frame: true` with `frame_w: 6.4` - that run was made with
    # minibossfit's `--frame` override and NOTHING in the register said so, so
    # it read as a creature that passed the standard cell. It did not.
    # Re-rendering at the default 5.60 cuts the HERO off at the left border
    # (frame_edge front left 228 px), and a sheet that crops a subject hides
    # whatever fault is under the crop - which is the whole reason this lane
    # asserts border alpha at all. So the frame is widened to hold the pair,
    # and the override is RECORDED rather than left to be inferred.
    # VERIFIED BY A/B, tools/art/_bg_frame_ab.py: the clip is byte-identical
    # with the ear turn off, so it is pass 2's to answer and not pass 3's.
    std_w = F.FRAME_W
    # *** THE FRAME WAS SIZED OFF WIDTH ALONE AND THAT CANNOT FRAME A TALL
    # *** CREATURE. FOUND 20 NOV 01:4x CT BY THE BORDER CHECK, ON MY OWN FIRST
    # *** LASTCUFF RUN (then still named Chainsweep): frame_w grew to 9.01 m for an 8.34 m pair, FRAME_H
    # *** came out of the 760x520 cell aspect at 6.16 m, and a 6.20 m creature
    # *** lost 65 / 47 / 65 px of HEAD off the TOP of front / side / back.
    # The run went red and shipped nothing, which is the border assertion doing
    # exactly the job System 1's cut glow bought it - but the harness also
    # could not have produced a passing sheet for ANY creature taller than the
    # frame its own width happened to buy, and that is a defect and not a
    # setting. Height is now a DRIVER of the frame and not a consequence of it:
    # take the wider of what width needs and what height needs, keep the cell
    # ASPECT fixed so one cell is still comparable with another, and record
    # which of the two drove it rather than leaving it to be inferred.
    need_w_wide = (amx.x - amn.x) * 1.08
    need_w_tall = ((amx.z - amn.z) + F.GROUND_UP) * 1.08 * F.CELL_X / float(F.CELL_Y)
    need_w = max(need_w_wide, need_w_tall)
    frame_driver = "height" if need_w_tall >= need_w_wide else "width"
    frame_overridden = bool(need_w > std_w)
    if frame_overridden:
        F.FRAME_W = need_w
        F.FRAME_H = need_w * F.CELL_Y / float(F.CELL_X)
    outdir = os.path.join(repo, "renders", "art", "variants", key)
    os.makedirs(outdir, exist_ok=True)
    tmpdir = os.path.join(repo, "renders", "art", "variants", "_vis_tmp")
    os.makedirs(tmpdir, exist_ok=True)
    written, eng, vis, edge = F.shoot(
        allo, pts, outdir, (("front", 0.0), ("side", 90.0), ("back", 180.0)),
        info["aura"], creature=meshes, hero_meshes=hmesh, tmpdir=tmpdir)

    errors, blind = [], []
    for vname, c in vis.items():
        for who in ("creature", "hero"):
            if c[who]["alone"] == 0:
                errors.append("%s/%s: the %s renders EMPTY alone - its seen "
                              "fraction would be computed over nothing"
                              % (key, vname, who))
    proving = sum(1 for c in vis.values() if c["proves"])
    if proving < F.MIN_PROVING:
        blind.append("%s: only %d of %d views show BOTH subjects"
                     % (key, proving, len(vis)))
    clipped = {v: e for v, e in edge.items() if any(e.values())}
    blanks = []
    for p in written:
        a = G.read_png(p)
        if int((a[:, :, 3] > F.DIFF_EPS).sum()) == 0:
            blanks.append(os.path.basename(p))

    # THE SILHOUETTE NUMBER THIS CLASS CAN HONESTLY REPORT. Not "does it read
    # as itself with the colour thrown away" - it cannot, it is the same mesh -
    # but HOW MUCH BIGGER the outline is than the regular version's, which is
    # the only part of the difference that survives a silhouette.
    sil = round(info["height"] / max(0.01, info["regular_h"]), 3)
    rec = dict(
        title=info["title"], regular=info["regular"], regular_h=info["regular_h"],
        height=info["height"], scale_vs_regular=sil,
        creature_h=round(mx.z - mn.z, 3), hero_h=hero["h"],
        ratio=round((mx.z - mn.z) / max(0.01, hero["h"]), 2),
        pair_w=round(amx.x - amn.x, 2),
        span_x=info["span_x"], span_y=info["span_y"],
        frame_w=round(F.FRAME_W, 3), frame_h=round(F.FRAME_H, 3),
        frame_w_standard=round(std_w, 3), frame_overridden=frame_overridden,
        frame_driver=frame_driver,
        frame_need_w_wide=round(need_w_wide, 3), frame_need_w_tall=round(need_w_tall, 3),
        fits_standard_cell=bool((amx.x - amn.x) <= std_w
                                and (amx.z - amn.z) <= (std_w * F.CELL_Y / float(F.CELL_X))
                                - F.GROUND_UP),
        # TWO TERMS, AND NEITHER IS A LITERAL ANY MORE. The old pair here was
        # `corridor_clear=11.0` and `> 11.0`, hand-copied out of floorgen.gd,
        # with NO height term at all - which is how Broodglut shipped GREEN at
        # 6.60 m standing 0.10 m through a shadows-only lid at 6.50 m that no
        # gate had measured. floorgeom reads the corridor AND the lid out of
        # scripts/floorgen.gd per run and WITHHOLDS a verdict it cannot read.
        **_fit_terms(info, max(info["span_x"], info["span_y"]),
                     max(float(info["height"]), round(mx.z - mn.z, 3))),
        fits_frame=bool((amx.x - amn.x) <= F.FRAME_W
                        and (amx.z - amn.z) <= F.FRAME_H - F.GROUND_UP),
        engine=eng, views=[os.path.basename(p) for p in written],
        visibility=vis, frame_edge=edge, proving_views=proving,
        blanks=blanks, frame_clips=clipped, errors=errors, blind_views=blind,
        tris=info["tris"], bones=info["bones"], meshes=info["meshes"],
        native_h=info["native_h"], stray_dropped=info["stray_dropped"],
        palette=info["palette"], palette_report=info["palette_report"],
        ear_turn=info.get("ear_turn"),
        theme=info["theme"], idea=info["idea"], line=info["line"],
        note=info["note"], prove_red=bool(prove_red),
    )
    # A fit error is a verdict error. A variant whose head is in the sun-blocker,
    # or whose verdict could not be computed at all, is NOT ok - that is the
    # whole reason this term exists.
    rec["ok"] = bool(not errors and not blanks and not clipped and not blind
                     and not rec.get("fit_errors"))
    return rec, roots, meshes


def _fit_terms(info, span, height):
    """floorgeom's two-term verdict, flattened into the register record.

    The height used is the WORSE of the authored target (what bestiary.gd will
    carry) and the measured world height of the mesh - if those two disagree
    the gate must answer for the taller of them, not pick the kinder one.

    `fit_errors` is the honest field: a verdict the reader could not compute is
    recorded as None WITH its reason, never as a pass.
    """
    geom = _fit_terms.geom if getattr(_fit_terms, "geom", None) else FG.read(_fit_terms.repo)
    v, errs = FG.verdict(geom, span, height)
    out = dict(
        corridor_clear_m=v["corridor_clear_m"],
        room_locked=bool(v["corridor"] == "ROOM-LOCKED"),
        corridor=v["corridor"], corridor_margin_m=v["corridor_margin_m"],
        lid_underside_m=v["lid_underside_m"], lid=v["lid"],
        lid_clear_m=v["lid_clear_m"], gate_height_m=round(height, 3),
        fits_dungeon=v["fits"], floor_read_from=v["read_from"],
        fit_errors=list(errs),
    )
    if v["lid"] == "THROUGH-LID":
        out["fit_errors"].append(
            "%.2f m stands %.2f m THROUGH the lid underside at %.2f m (%s)"
            % (height, -v["lid_clear_m"], v["lid_underside_m"],
               v["read_from"].get("lid_y_m", "?")))
    return out


_fit_terms.repo = "."
_fit_terms.geom = None


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True)
    ap.add_argument("--only", default="")
    ap.add_argument("--export", action="store_true")
    ap.add_argument("--fit", action="store_true")
    ap.add_argument("--prove-red", action="store_true")
    ap.add_argument("--ab", action="store_true")
    ap.add_argument("--reverdict", action="store_true")
    # THE T-POSE IS WIDER THAN THE THIRTY-SIX'S FRAME, AND THE BORDER CHECK
    # CAUGHT IT RATHER THAN MY EYE. At 2.60 the pair spans 5.96 m against
    # minibossfit's fixed 5.60 m cell, and the front and back views lost 228
    # and 233 px of arm off the left and right edges - a clip, not a blank,
    # which is precisely the fault class that check was built for after
    # System 1's cut glow. The frame is widened for this register and the
    # width is RECORDED in it, because a cell shot at 6.40 m cannot be
    # compared with a thirty-six cell shot at 5.60 m and nobody should have
    # to find that out by eye.
    ap.add_argument("--frame", type=float, default=0.0)
    args = ap.parse_args(argv)
    if args.frame > 0.1:
        import minibossfit as _F
        _F.FRAME_W = args.frame
        _F.FRAME_H = args.frame * _F.CELL_Y / float(_F.CELL_X)
    keys = [k for k in args.only.split(",") if k] or list(ORDER)
    _fit_terms.repo = args.repo
    _fit_terms.geom = FG.read(args.repo)
    outp = os.path.join(args.repo, "renders", "art", "variants", "_register.json")
    os.makedirs(os.path.dirname(outp), exist_ok=True)
    reg = {}
    if os.path.isfile(outp):
        try:
            with open(outp) as f:
                reg = json.load(f)
        except Exception:
            reg = {}
    reg.setdefault("variants", {})
    reg["floor_geom"] = _fit_terms.geom

    # --reverdict: RE-ANSWER THE DUNGEON QUESTION FOR THE RECORDS ALREADY
    # MEASURED, WITHOUT RE-RENDERING ANYTHING. The lid is moving (7.0 -> 10.0,
    # supervisor 02:12 CT), so a corridor verdict written before anyone had
    # measured the lid is a verdict against a dungeon that no longer exists.
    # These are stored measurements of real renders: the new term costs one
    # comparison each, and refusing to re-verdict them would leave the register
    # asserting a pass nobody has checked against today's floorgen.gd.
    if args.reverdict:
        for key, rec in reg["variants"].items():
            h = max(float(rec.get("height") or 0.0), float(rec.get("creature_h") or 0.0))
            sp = max(float(rec.get("span_x") or 0.0), float(rec.get("span_y") or 0.0))
            if h <= 0.0 or sp <= 0.0:
                rec["fit_errors"] = ["carried record has no height/span - verdict withheld"]
                rec["ok"] = False
                continue
            rec.update(_fit_terms({"span_x": rec.get("span_x"), "span_y": rec.get("span_y"),
                                   "height": h}, sp, h))
            rec["ok"] = bool(not rec.get("errors") and not rec.get("blanks")
                             and not rec.get("frame_clips") and not rec.get("blind_views")
                             and not rec.get("fit_errors"))
        reg["verdict"] = ("GREEN" if all(v.get("ok") for v in reg["variants"].values())
                          else "NOT PASSED")
        with open(outp, "w") as f:
            json.dump(reg, f, indent=1)
        print("MONSTERVARIANTS_REVERDICT " + json.dumps({
            "verdict": reg["verdict"],
            "corridor_clear_m": _fit_terms.geom["corridor_clear_m"],
            "lid_underside_m": _fit_terms.geom["lid_underside_m"],
            "lid_read_at": _fit_terms.geom["at"].get("lid_y_m"),
            "geom_errors": _fit_terms.geom["errors"],
            "variants": {k: (v.get("gate_height_m"), v.get("lid"), v.get("lid_clear_m"),
                             v.get("corridor"), v.get("corridor_margin_m"),
                             v.get("fits_dungeon"), v.get("fit_errors"))
                         for k, v in reg["variants"].items()}}))
        return

    for key in keys:
        G.purge()
        if args.ab:
            for lname, light in (("mess", (1.00, 0.68, 0.34)),
                                 ("crypt", (0.70, 0.74, 1.00))):
                G.purge()
                reg.setdefault("ab_palette", {}).setdefault(key, {})[lname] = \
                    ab_palette(key, args.repo, light=light, tag=lname)
            continue
        if args.fit:
            rec, roots, meshes = fit(key, args.repo, prove_red=args.prove_red)
        else:
            meshes, roots, info = build_variant(key, args.repo)
            rec = dict(title=info["title"], native_h=info["native_h"],
                       tris=info["tris"], ok=None)
        if args.export:
            path, size = export_variant(key, args.repo, roots, meshes)
            rec["glb"] = os.path.relpath(path, args.repo).replace("\\", "/")
            rec["glb_bytes"] = size
        else:
            # *** A DEFECT IN THIS FILE, FOUND AT PASS 4 BY READING THE
            # *** REGISTER I HAD JUST WRITTEN INSTEAD OF THE VERDICT ON IT. ***
            # fit() builds `rec` from scratch, so a `--fit` run WITHOUT
            # `--export` replaced the record wholesale and SILENTLY ERASED
            # `glb` and `glb_bytes` - the two fields naming the asset that
            # actually ships. Verdict stayed GREEN throughout, because no
            # check in this file asks whether the record still points at a
            # file. The game build lane reads this register for the path.
            # Carry the shipped-asset fields across any pass that did not
            # re-export, so a re-render can never quietly un-name the asset.
            prev = reg["variants"].get(key, {})
            for f in ("glb", "glb_bytes"):
                if f in prev and f not in rec:
                    rec[f] = prev[f]
        if args.prove_red:
            reg.setdefault("red_proof", {})[key] = rec
        else:
            reg["variants"][key] = rec
    reg["verdict"] = ("GREEN" if all(v.get("ok") for v in reg["variants"].values())
                      else "NOT PASSED")
    with open(outp, "w") as f:
        json.dump(reg, f, indent=1)
    print("MV_DONE", outp, reg["verdict"])



# ---------------------------------------------------------------- the A/B
def ab_palette(key, repo, light=(1.00, 0.68, 0.34), tag=""):
    """DOES THE RECOLOUR SURVIVE THE LIGHT IT WILL BE SEEN IN?

    The texture means say the two skins are far apart - olive 0.388/0.393/0.127
    against red 0.437/0.205/0.207. That is a number about a FILE. The question
    a viewer asks is whether a big red puglin reads as a different animal from
    the little ones NEXT TO IT.

    *** WHAT THIS FILE CLAIMED AND COULD NOT DO, CORRECTED 19 NOV 22:5x CT. ***
    The first version of this docstring said the two skins were compared
    "under the theme's own key light". THEY WERE NOT, and the run's own
    numbers are how I know: the mess key (1.00/0.68/0.34) and the crypt key
    (0.70/0.74/1.00) are as far apart as two theme lights get in floorgen, and
    they returned mean_rgb_distance 0.1343 and 0.1339 - the same answer to
    four decimal places. The cause is in lordgen.add_lights: its third
    argument colours the RIM only, from behind; the key is a fixed warm white
    (1.0, 0.97, 0.92) that no caller can reach. So the light argument moved a
    back edge and nothing else, and a theme-light claim built on it would have
    been a sentence with no measurement under it.
    WHAT IS MEASURED AND STANDS: the two skins under the STANDARD FIT RIG -
    same mesh, same camera, same lights, only the map swapped. WHAT IS NOT
    ANSWERED: whether a theme's own key collapses the difference. Answering it
    needs the KEY colour driven, not the aura - a change in lordgen that
    touches every register this lane has shipped, and not a thing to do inside
    a variant's first pass.

    So: the same mesh, the same camera, the same lights, rendered twice - once
    wearing BaseColor_1 and once BaseColor_2 - and the separation measured on
    the PIXELS THAT MOVED, not on the maps. An instrument that renders a thing
    alone answers how big it is; this one answers whether it looks different,
    which is the question.

    GOES RED ON EMPTY: if the two renders share no opaque pixels the separation
    is computed over nothing and the verdict is NO VERDICT, not a pass."""
    import minibossfit as F
    spec = VARIANTS[key]
    lsuf = ("_" + tag) if tag else ""
    rows = {}
    for tag, pal in (("regular", "T_Puglin_BaseColor_1.png"),
                     ("variant", spec["palette"])):
        G.purge()
        sp = dict(spec); sp["palette"] = pal
        saved, VARIANTS[key] = VARIANTS[key], sp
        try:
            meshes, roots, info = build_variant(key, repo)
        finally:
            VARIANTS[key] = saved
        mn, mx, pts = G.world_bounds(meshes)
        outdir = os.path.join(repo, "renders", "art", "variants", key, "_ab")
        os.makedirs(outdir, exist_ok=True)
        # THE THEME'S OWN KEY, not the register's red aura - using the aura
        # would bias the test toward the answer I want.
        written, eng, _, edge = F.shoot(meshes, pts, outdir,
                                        (("%s%s" % (tag, lsuf), 0.0),), tuple(light))
        rows[tag] = dict(png=written[0], edge=edge)
    a = G.read_png(rows["regular"]["png"])
    b = G.read_png(rows["variant"]["png"])
    ma = a[:, :, 3] > F.DIFF_EPS
    mb = b[:, :, 3] > F.DIFF_EPS
    both = ma & mb
    n = int(both.sum())
    rep = dict(pixels_compared=n, light=[round(float(c), 3) for c in light],
               regular_png=os.path.basename(rows["regular"]["png"]),
               variant_png=os.path.basename(rows["variant"]["png"]))
    if n < 1000:
        rep["verdict"] = "NO VERDICT - only %d shared opaque pixels" % n
        rep["ok"] = False
        return rep
    pa = a[:, :, :3][both]
    pb = b[:, :, :3][both]
    rep["mean_regular"] = [round(float(x), 4) for x in pa.mean(axis=0)]
    rep["mean_variant"] = [round(float(x), 4) for x in pb.mean(axis=0)]
    # per-pixel distance, and the one component a warm light cannot fake:
    # green-minus-red. Olive is g > r; the red skin is r > g. A sign flip is
    # the thing a viewer sees across a dim room.
    d = np.sqrt(((pa - pb) ** 2).sum(axis=1))
    gr_a = (pa[:, 1] - pa[:, 0])
    gr_b = (pb[:, 1] - pb[:, 0])
    rep["mean_rgb_distance"] = round(float(d.mean()), 4)
    rep["p10_rgb_distance"] = round(float(np.percentile(d, 10)), 4)
    rep["frac_over_jnd"] = round(float((d > 0.05).mean()), 4)
    rep["green_minus_red_regular"] = round(float(gr_a.mean()), 4)
    rep["green_minus_red_variant"] = round(float(gr_b.mean()), 4)
    rep["gr_shift"] = round(float(gr_b.mean() - gr_a.mean()), 4)
    rep["sign_flipped_frac"] = round(float(((gr_a > 0) & (gr_b < 0)).mean()), 4)
    # *** THE FIRST VERSION OF THIS VERDICT WAS WRONG AND ITS OWN NUMBERS SAID
    # *** SO. It required sign_flipped_frac >= 0.50 - "olive is green-dominant,
    # the red skin is not, so most pixels must flip". The run returned
    # green_minus_red_regular = -0.0102: under the mess theme's warm key the
    # REGULAR puglin is already red-dominant, so there was no sign left to
    # flip and the criterion could never be met by any recolour whatsoever.
    # That is this lane's own recurring fault - a gate that cannot move - and
    # it was built into the gate by an assumption about the art rather than a
    # measurement of it. Replaced with two things that are measured and not
    # assumed: how far the pixels moved, and how many of them moved further
    # than a just-noticeable 0.05. sign_flipped_frac is KEPT in the record as
    # a reading, with no power to pass or fail anything.
    rep["ok"] = bool(rep["mean_rgb_distance"] >= 0.08 and rep["frac_over_jnd"] >= 0.75)
    rep["theme_light_test"] = ("NOT PROVEN - lordgen.add_lights colours the rim "
                               "only; the key is fixed warm white and this "
                               "argument cannot reach it")
    rep["verdict"] = ("SEPARATED UNDER THE FIT RIG" if rep["ok"]
                      else "TOO CLOSE UNDER THE FIT RIG")
    return rep


if __name__ == "__main__":
    main()
