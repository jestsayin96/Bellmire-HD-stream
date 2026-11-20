# THE SCRAPER - "Scourstone", the 41st miniboss

Art lane, 20 Nov 2026, 15:3x-16:1x CT. Built on the team lead's 14:58 row
("A 41st MINIBOSS IS THE ONE THING YOU MAY INVENT, AND IT IS YOURS TO TAKE"),
under Mr. E's standing permission of 17:43. Body, hero trio and register are in
ONE push, which is what that row asked for after the Relief cost two firings by
shipping the mesh first and the proof second.

    key          scraper
    name         Scourstone
    theme        crypt
    height       2.55 m        ratio to a KayKit adventurer 1.04
    wear         0.40
    meshes       4 (merged by material)      faces 1266
    footprint    2.20 m span   CORRIDOR-SAFE (11.0 m clear, margin 8.80 m)
                               UNDER-LID     (lid underside 9.50 m)
    static       no `anims` entry

## THE IDEA

**IT RUBS OUT WHAT YOU HAVE JUST DONE.** It does not block a blow, it does not
heal and it takes nobody away. When the round is over it draws the stone down
the slab and the party's LAST action is undone - the blow comes off, the wound
re-opens, the guard is gone. Nothing is kept until something else has been done
after it, so the party gets its real work in early and spends its last action on
something it does not mind losing. Out-damaging it cannot work, because the
damage is the thing it removes. The answer is the PLINTH, and the FIVE CUTS on
each of its four faces are the gauge: one cut is one more wipe.

**WHY IT IS NOT A RE-SKIN.** All 40 existing `idea` strings were printed and
read this run (count taken off `_report.json`: 51 entries minus 11 `_chibi`).
Forty bodies argue about the FUTURE - how much damage, where it goes, who takes
it, who may act, where they stand. Every one of them leaves the past alone. The
nearest five are the TANNER (refuses a repeat blow BEFORE it lands), the FULLER
(returns your damage as harm - this returns nothing, it deletes), the SEXTON
(restores ITSELF; this never heals), the BEADLE (takes WHO acts; this leaves
every choice and makes the LAST one worthless) and the STRICKLER (a standing tax
on a hero; this is a one-shot delete of an EVENT). The new resource is the
record.

Theme `crypt` was chosen by counting: crypt had two bodies (Sexton, Ratcatcher)
against four in keep and four in workshop.

## THE FIT PROOF

`renders/art/minibosses/_fit_scraper_register.json`, GREEN, errors [].

    creature_h 2.55   hero_h 2.45   ratio 1.04   pair_w 3.76   fits_frame true
    views      hero_front.png, hero_side.png, hero_back.png
    visibility seen 1.0 creature and hero in all three, proves 3/3
    blank      3 files checked, 0 failures; minibossgen 0 blanks, 0 frame-edge
               alpha, errors []

**I LOOKED AT ALL SIX RENDERS** (front / three_quarter / side, and the hero
trio) and the body went through THREE PASSES because of what the pictures said,
not what the numbers said. Both earlier passes were GREEN on every number in
this file.

  PASS 1 - THE WORK WAS INVISIBLE. The man and the slab sat on opposite ends of
  a diagonal with the working face turned toward the man and therefore away from
  both cardinal cameras. Front and side both showed the arms running behind the
  slab and ending nowhere: no hands, no stone, no contact. It read as a man
  standing NEXT TO a stone, which is not the fight. Not fixable by nudging the
  yaw - the face that points at the man points away from a camera behind him -
  so he now works the slab FROM ITS LEFT END, reaching around it, which is also
  how you actually scour a wall.
  PASS 1 - THE SLAB READ AS A TOWER BLOCK. Five even rows of three even marks on
  a capped rectangle is a building with windows. Fixed by making it a TAPERED
  stele (0.820 -> 0.775 -> 0.725) with a broken top instead of a cap, and by
  giving the inscription a left margin and RAGGED LINE ENDS.
  PASS 2 - THE SPARE SLATES FLOATED 0.2-0.35 m clear of his back: three fins in
  the air, because they were placed in world y and the torso then leaned away
  from them. They are now placed in HIS frame.
  PASS 2 - THE SIDE VIEW HID HIM. With the man at the slab's left EDGE the side
  camera put him 80% behind it: hood, one shoulder and one leg. The same fault
  class as pass 1 in a different view. Fixed by separating the two masses in y
  as well as x (0.26 -> 0.58) and lifting the hands to the waist line, which
  also brought the arm reach down from 1.0 m to 0.79 m.
  PASS 2 - THE SCOURING STONE WAS PALE ON PALE and vanished against the slab.
  THIS IS THE EXACT FAULT I WROTE UP ON THE RELIEF SIX HOURS AGO (the pale arm
  bar lost against the pale capstan drum) AND THEN REPEATED. The stone is now
  dark with one thin pale edge.
  PASS 2 - TWO HEADS. The near shoulder sphere sat where a head would be and the
  front view read as a figure with two round heads. Shoulder spheres 0.150 ->
  0.125 and moved back; head raised 1.78 -> 1.845.

## WHAT THE GREEN DOES NOT SAY - READ THIS BEFORE TRUSTING THE REGISTER

`visibility.seen` measures ONE thing: how much of the creature survives being
drawn in the same frame as the hero, by rendering with and without and counting
the pixels that moved. It has NO opinion on a creature's own parts hiding each
other, none on build, none on whether a thing is identifiable as the object it
is meant to be. The blank-and-border check sees opaque pixels and frame-edge
alpha and nothing else. These faults are all live and NO NUMBER IN THIS FILE
REPORTS ANY OF THEM:

  1. **FROM THE SIDE, THE HANDS AND THE STONE ARE BEHIND THE SLAB.** The stone
     sits on the face that turns toward the room, so the side camera sees the
     arm meeting the slab's edge and the contact itself is occluded. The side
     view scores `seen 1.0` and proves nothing about this.
  2. **THE MAN READS THIN BESIDE A KAYKIT ADVENTURER.** Limb radius 0.100
     against a 0.250 torso, next to a chibi body whose arms are nearly as thick
     as its chest. At hero scale he is a dark stick figure. Nothing here
     measures build.
  3. **THE SHOULDER BALL STILL READS AS A SECOND SMALL HEAD** in the front view.
     Reduced at pass 3, not eliminated.
  4. **THE SCOURING STONE IS ONLY A TOOL AT BODY DISTANCE.** In the hero pair it
     is a dark blob where his hands are - the contact reads, the implement does
     not.
  5. **THE SLAB CARRIES NO FACING AT ALL, BY DESIGN** - both broad faces are
     inscribed and the waist runs all the way round. ALL of this body's facing
     is the man's dust mask, his two eyes and his slate stack. Verified by
     looking: hero_front has the pale mask and the eyes, hero_back has neither.
     But it means that if a later pass moves the mask this body loses its facing
     completely, which is the Beadle's fault one step away.
  6. **THE THREE SPARE SLATES READ AS ONE DARK BOX FROM BEHIND**, not as a
     countable stack of three.
  7. The five plinth cuts were read off the renders at body distance and are
     five separate marks on each visible face. At hero-pair distance they are a
     row of ticks and I would not claim a viewer counts them from across a room.

## WIRING - THE ART LANE DOES NOT DO THIS

  * `scripts/bestiary.gd` - add `scraper` with
    `model: "res://assets/monsters/minibosses/scraper.glb"`, `h` 2.55, and
    **NO `anims` entry** (static body).
  * `scripts/delve.gd` - `MB_NAME["scraper"] = "Scourstone"` (this is the 41st
    key; MB_NAME was 39 at 14:58 and the Watchturn row was the 40th).
  * `scripts/dungeon_hd.gd` - `THEME_MINIBOSS_MORE["crypt"]` may take
    `"scraper"`; crypt is the lightest-loaded theme at two bodies.
  * CONTENT - a `miniboss_feed.by_key["scraper"]` row. The barker line in CANON
    is "Someone is rubbing a name off the wall."
  * `assets/monsters/minibosses/scraper.glb` has **no `.glb.import` sibling**,
    the same open item as `relief.glb` and `snarer_chibi.glb`. 51 of the bodies
    have one; these three do not, and a Godot run generates it. The art lane
    does not run Godot to play the game and cannot produce it.
