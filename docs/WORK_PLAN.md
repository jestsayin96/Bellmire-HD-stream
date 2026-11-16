# WORK PLAN - Bellmire HD

================================================================================
## *** HARD DELIVERABLE, DUE 09:00 MON 16 NOV *** D95 - THE TEN-CHARACTER SHOWCASE

### [x] D95 - DELIVERED, MERGED AND TICKED BY THE SUPERVISOR, 2026-11-16 02:05 CT
BOTH halves are in and on main, ahead of the 09:00 deadline.
  ART (origin/art 57ddaa8 + c6eeab4): ten characters, four views each at one framing and one
  light, two per rarity band, three accessories unique to each hero, and ONE declared SET - the
  paladin's Scarwoven plate. Sheets in renders/art/d95/ (_overview.png and _sheet_<key>.png),
  kits in assets/characters/bellmire/showcase/, written up in docs/art/D95_SHOWCASE.md. Fit is
  MEASURED off the posed body with a BVH ray cast, not eyeballed. The named weapons are real CC0
  KayKit models the repo already carried; three heroes carry a shield, which classes.json asked
  for and nothing in the game had. Licences logged in docs/art/ASSET_SOURCES.md - CC0 only, two
  packs rejected on licence (CC-BY-SA, CC-BY).
  GAME BUILD (origin/laptop f450bbe): the same ten standing up in Godot, four views each, in
  renders/cycles/d95/ (sheet_00..sheet_09 + sheet_overview_front). D95_FIT OK, 0 attach failures,
  gates green, and an HONEST FIT REPORT OF TWELVE FAULTS in PROGRESS.md (D-cycle D94a).
The faults are NOT swept up by this tick. They are D94's remainder and are listed under D94 below.
MR. E: the sheets are waiting on you. renders/art/d95/_overview.png is the one picture; the
game build's renders/cycles/d95/sheet_overview_front.png is the same ten inside the engine.
Mr. E, 00:59, verbatim: "non negotiable i want 10 characters with different equipment and armor
and accessories as a show case for me in 8 hours. i want to see front, side, back, top down
profile views i want to make sure everything that is made for these characters actually fit.
people are not going to waste money on slop."

WHAT HE IS ACTUALLY CHECKING: whether the gear FITS THE BODY. Not whether the pieces are pretty
in isolation - whether a helm sits on the head, a ring is on a finger and not through it, a cloak
hangs off the shoulders, boots meet the ankle, a pauldron does not float. Four views exist so
nothing can hide. A piece that looks right from the front and clips through the chest from the
side is a FAILURE and must be listed as one, not quietly cropped out.

### THE DELIVERABLE
TEN characters. Each one:
  - a DIFFERENT calling, and a different body where the roster offers one
  - a DIFFERENT weapon, DIFFERENT armour, and at least THREE accessories nobody else has
  - FOUR views, same framing and lighting for every character: FRONT, SIDE, BACK, TOP-DOWN
  - full body, feet to crown, nothing cropped
One contact sheet per character (four views in a row) plus one overview sheet of all ten.
Put them in renders/art/d95/ and SHOW MR. E THE SHEETS.
Spread them across the rarity ladder: two common, two uncommon, two rare, two very rare, two
legendary - so he sees the whole range of what a viewer can earn, not ten variations of the same
tier. At least ONE of the ten wears a declared SET (matching chest, boots, helm, gauntlets),
because Mr. E named that as the legitimate exception and it must be visible alongside the rest.

### SAY WHAT IS WRONG
End with an explicit FIT REPORT: every clip, float, gap, wrong scale or bad anchor you can see,
per character and per view. An honest list of twelve faults is worth more than a clean-looking
sheet that hides three. He will spot them on stream if you do not spot them now.

### MR. E HAS WIDENED THE ASSET PERMISSION (00:59)
"look for free CC packs online you have acces to everything download stuff, use designs from
others and tweak them to fit our needs, as long as its legal we are good. i give you this
permission."
SO: you may DOWNLOAD and MODIFY third-party packs. HIS MACHINE CAN REACH THEM - verified 00:58:
itch.io, quaternius.com, kenney.nl, opengameart.org, poly.pizza and github.com all answer 200
from the Blender (Windows) side. The Linux bridge CANNOT - its proxy blocks all but GitHub and
package registries - so do downloads through the Blender bridge with urllib or requests.

THE LEGAL LINE, AND IT IS NOT NEGOTIABLE - "as long as its legal" is the condition he set:
  - CC0 / public domain: always fine. Prefer it.
  - CC-BY: fine, BUT the attribution must be recorded in a LICENSE/CREDITS file next to the asset,
    naming the author, the work and the licence. No attribution = not legal = do not ship it.
  - **CC-BY-NC (NonCommercial) IS FORBIDDEN.** Bellmire takes bits and channel points; it is a
    commercial stream. NC assets would make the whole game unshippable.
  - **CC-BY-ND (NoDerivatives) IS FORBIDDEN** - the whole point here is tweaking them to fit.
  - "Free to download" is NOT a licence. If a pack does not state its licence plainly, DO NOT USE
    IT. There is enough CC0 out there that guessing is never necessary.
  - Record every pack used in docs/art/ASSET_SOURCES.md: pack, author, URL, licence, date.
The old blanket ban on Quaternius Bestiary / QAL stands until Mr. E lifts it by name.

### DO NOT LET THIS BLOCK ON DOWNLOADS
Procedural generation has already produced eight lords, 454 icons, twelve creature bodies and
eight minibosses in a day. Downloaded packs are an ACCELERANT, not a dependency. If a pack is
slow to find, awkward to licence or does not fit the rig, GENERATE the piece instead and move on.
The deadline is 09:00 and the deliverable is ten characters, not a perfect sourcing exercise.

### HOW THIS SITS WITH D94
D95 is the PROOF of D94. D94 says every item must look like itself; D95 is Mr. E seeing whether
that is true and whether it fits. Build the variety (D94), then show it on ten bodies (D95).
If D94 is not finished by 09:00, STILL SHIP D95 with whatever exists - ten characters wearing the
best available gear, with an honest fit report. A partial showcase he can judge beats a complete
one he never sees.
================================================================================

================================================================================
## *** TONIGHT'S ONLY JOB *** D94 - EVERY ITEM MUST LOOK LIKE ITSELF (Mr. E, 16 Nov 00:55)
HUD, HUB and CONTENT lanes are SHUT DOWN for this. Only GAME BUILD, ART and the SUPERVISOR run.
Mr. E, verbatim: "this is unacceptable, unless they are a set example: metal armor chest, boots,
helm, and gauntlets. ring should not at all be looking the same at all. change the gemstones, the
colour, make them different, unique. that goes for all accessories. all equipment aka, the weapons
and all the armour pieces should not be looking the same, again unless they are a set. fix this
asap. shut everyone else down, this is the focus tonight."

### D94 - THE DUPLICATES ARE CLOSED. STILL OPEN ON TWO THINGS ONLY (supervisor, 2026-11-16 02:58 CT)
The remainder named at 02:05 came back from BOTH lanes and both halves are merged to main. The
build bug is gone. As of 04:58 CT every BUILDABLE fault is closed and ticked. D94 is NOT ticked
only because the two faults still standing are BOTH DECISIONS FOR MR. E - ring/glove size at
stream distance, and the 16-deep legendary pool. No worker is queued on D94.

  [x] DONE AND TICKED - THE ITEM'S OWN KEY NOW REACHES THE GEOMETRY (both halves, 16 Nov)
      ART (origin/art f349e0e): showcase.sig(key, name) returns twelve dials off the two things
      only an item has, and they move PROPORTION and COUNT inside whatever the variant decided.
      weapon() stops keying on family + tier. Four of the eight kinds of hat had no geometry at
      all and fell through to the war helm - which is why a straw hat was made of steel. A hood
      left no face. The name now overrides the family where they disagree. Re-ran d94proof.py,
      96 renders: NO ROW REPORTS DUPLICATE, all 120 pairs are two objects (amulet 0.00 -> 0.52%
      worst, cloak -> 15.96, hat -> 17.54, weapon -> 3.05). The sheets were looked at before
      committing, which is what caught the hood and the brim across the eyes.
      GAME BUILD (origin/laptop e9d95f5): accessories get a FORM index (slot|variant|metal|stat|
      cloth), so 0 of 254 accessories share a signature where 30 groups did. Named weapons are
      numbered among their siblings and Gear.deco_piece builds wrap / pennons / stone / collars
      off the mesh's own bounds, so Scarbow and Seamstring differ ON THE BODY (0 of 86 duplicates).
      D94B OK, gates green.
      The two lanes moved together, so the hub icon and the thing on the hero are still the same
      object. That was the condition on this fix and it held.

  [x] DONE AND TICKED - FOUR OF THE TWELVE FIT FAULTS (game build, e9d95f5)
      Boots are rounded, not boxes. Bought boots now replace armour-set boots, so the paladin's
      Long Count Boots show. "Parish Iron Mace" is a mace (arcane gained a sceptre kind). The
      KayKit bow is held at x0.92 so a Greatbow reads large.

  [ ] STILL OPEN - NEEDS MR. E, NOT A BUILDER: RING, AMULET AND GLOVES AT STREAM DISTANCE.
      Measured again after the fix: ring 0.00% worst pair AND 0.00% median; gloves PARTLY TOO
      SMALL, 11 of 15 pairs. The items ARE different objects now - a viewer simply cannot see a
      ring on a body at stream size. The answer is a design call: an oversize "readable" ring and
      glove, or accept that these are inventory items and not silhouettes. NO WORKER TAKES THIS.

  [x] DONE AND TICKED - THE AMULET CHAIN SHOWS (game build, origin/laptop e7dccae, 16 Nov)
      The chain was two thin rods running straight up under the chin, so the head's overhang hid
      them. It is now eight links a side draped wide out to the collarbones, following the chest's
      barrel as it climbs, link size riding cost, with a faint emission so it catches the light.
      Looked at: renders/cycles/d94c/d94_row_1_amulet_close.png - the V of links reads from the
      front on helmed and bare bodies, pendant still at the breastbone. The proof row moved from
      0.00% (a DUPLICATE) to 0.52% worst pair, 0.97% median: amulets TELL APART.

  [x] DONE AND TICKED - THE CLOAK IS ONE OBJECT ON BOTH SIDES (both halves, 16 Nov 04:58 CT)
      THE SHADE STEP LANDED: game build 47bc80f ports tools/art/icons.py's step into gear.gd
      (_acc_variant factored out so the shade table and _acc_base share one copy; D94_CLOAK_SHADES,
      clamped 0.02..0.95 in linear; cloth_i stays the dye, so the step is a value, never a hue).
      tools/_d94d_shade.gd checks all 49 cloaks against a table written by the ART lane's own
      icons.py: dye, variant, shade and cloth agree to 1e-4 and 49 of 49 are distinct. D94D OK over
      ten shots, parse 0, OFFFLOOR 0/1752, TOWNWALK PASS, TWITCH_PARSE OK, delve 0 script errors.
      The hub icon and the thing on the hero are the same object again - the condition on this fix.
      NOTED, NOT A NEW ITEM: the walnut-black pair still reads as near one object, because a value
      step on black is invisible. It belongs in the SHARED table (icons.py + gear.gd together) if
      Mr. E ever calls it worth a pass; nobody is queued on it.
      DONE, BOTH SIDES: gear.gd gives a cloak one of TWELVE period dyes (D94_CLOAK_DYES - madder,
      woad, woodland green, walnut black, grey wool, undyed cream, weld ochre, wine, river teal,
      russet, scar violet, oilcloth olive), picked from the item's NAME first (D94_CLOAK_WORDS) and
      hashed only as a fallback; spread 3/7/7/3/2/4/5/3/5/4/2/4 over the 49 cloaks, none over 7
      (origin/laptop e7dccae). The art lane mirrored the rule bit for bit and collapsed the eight
      leather TONES, which had been pasted into three generators, into one icons.cloth_tone
      (origin/art a11cd62). Cloak proof row: worst pair 15.96 -> 19.11% of the hero's own pixels,
      median 29.59 -> 31.25, verdict TELLS APART, no row DUPLICATE.
      WHAT WAS LEFT, AND IS NOW CLOSED: the art sheet FAILED on the dye
      alone. Fifteen cloaks shared BOTH a dye and a cut, six of them woad-and-mantle, so art added a
      SHADE STEP inside the dye, assigned by position in the colliding group the way D94b assigned
      form - it cannot collide by construction - giving 49 distinct (colour, cut) pairs out of 49.
      gear.gd now HAS that shade step (see above) - closed 16 Nov 04:58 CT. Do not re-derive the
      dyes, do not re-run the art fix and do not re-shoot the cloak row.

  [ ] STILL OPEN - NEEDS MR. E, NOT A BUILDER: THE LEGENDARY ACCESSORY POOL IS ONLY 16 DEEP.
      Both lanes measured this independently and both hand it back, which is the right call: the 16
      are 8 rings, 6 cloaks, 2 amulets, ZERO boots and ZERO gloves. ONE cost scale bands rarity for
      every slot (441+ = legendary) while boots cap at 420 and gloves lower still, so those two
      slots can never hold a legendary piece - which is why D95's showcase had to borrow very-rare
      pieces. The two ways out are in NEEDS MR. E and both change what a viewer paid for, so neither
      a builder nor the supervisor takes it. NO WORKER TAKES THIS.

### THE MEASURED FAULT - do not re-derive it
gear.gd `dress_cosmetics()` renders a worn accessory from the SLOT ONLY, never from the item:
  - every ring is the same TorusMesh (inner 0.07, outer 0.11)
  - the colour comes from `ACC_COL`, a four-entry dict keyed ring/amulet/gloves/boots
  - so all ~50 rings are one gold torus; all gloves, amulets and boots likewise
254 accessories with distinct names, prices, flavour and icons render as FOUR shapes in four
colours. Only hats, banners and titles vary per item today.
The weapons and armour are worse: the game runs on the 12-step GENERIC ladder in gear.gd
(bare hands/plain steel/fine steel/runed/dragontooth/scarforged, rags/leather/chainmail/plate/
warded plate/scarwoven mail). The 86 named weapons and 33 named armour pieces in items.json are
read by NO SCRIPT AT ALL. A hero cannot hold "Ironmonger's Blade" - only "fine steel".

### THE RULE
EVERY ITEM LOOKS LIKE ITSELF. A viewer who paid for a specific thing must be able to SEE that
specific thing on their hero and tell it apart from the one next to it.
THE ONE EXCEPTION MR. E NAMED: a SET may share a look - a metal armour set whose chest, boots,
helm and gauntlets match is correct and good. Sets are deliberate and declared; sameness that
falls out of lazy code is not.

### DIVISION OF WORK
**ART LANE - build the variety.** You already solved this exact problem for D73: the icon
generator derives silhouette from slot/kind, ornateness and metal from COST QUARTILE, palette
from the stored colour, and FOR THE 230 ACCESSORIES WITH NO COLOUR IT DERIVES THE GEM FROM THE
STAT (ac steel, saves violet, hp red, speed green, hit amber, dmg orange). Reuse that derivation
for the 3D piece so THE ICON ON THE HUB AND THE THING ON THE HERO MATCH. That coherence is worth
more than either alone.
  - Rings: band profile, setting, gem shape and gem colour all vary. Cheap rings are a plain
    band; expensive rings are worked, with a real stone.
  - Amulets, gloves, boots, cloaks: same treatment - shape family from the item's NAME first
    (a Guard Helm is a helm, a Straw Hat is a wide brim), hash only as a fallback, exactly as
    D73's hats did.
  - WEAR RIDES COST, per the 15 Nov ruling: cheap reads handled and worn, expensive reads new and
    well kept. Never one wear value for a whole slot.
  - Weapons and armour: the 119 named pieces need looks of their own, grouped into SETS where the
    data says they belong together.
  - Budget: these are worn by many bodies at once, so keep them CHEAP - low poly, few materials,
    merged by material like the lords. A ring is seen at arm's length on a moving body.

**GAME BUILD - wire it.** `dress_cosmetics()` must take the ITEM, not just the slot. Then the
harder half: the 119 named weapons and armour pieces are dead data, and making them real is the
point of this item - a hero holds a NAMED piece, the forge and the shop deal in named pieces, and
gear.gd's generic ladder becomes the tier BEHIND the name rather than the thing itself.
  - Keep the numbers. The 12-step ladder's atk/hp/ac values are balanced and stay; a named piece
    carries a tier and inherits that tier's numbers.
  - Do not break saves: a hero carrying "fine steel" today must still be valid tomorrow.

### DONE
A single render, one row per slot, showing SIX DIFFERENT items of that slot side by side on real
hero bodies at stream distance. If a viewer cannot tell them apart in that shot, it is not done.
Then the same for weapons and armour. Mr. E's eye is final.
================================================================================

================================================================================
## RESOLVED - THE MISLABELLED COMMIT ON `laptop` (closed by the supervisor 2026-11-15 23:58)
Commit b3fbd16 on `laptop` carried the game build worker's in-progress D88 code under a
documentation message. Mr. E ruled: leave it. The worker then committed finished, gated D88 on
top (0cd3acd) and both are now merged to main - nothing lost, no history rewritten. Closed.
LESSON THAT STAYS: never `git commit -am` in a worktree another lane may be live in. Stage the
exact file.
================================================================================
## TAKE THIS NEXT. FILE ORDER IS MEANINGLESS - READ THIS BLOCK AND NOTHING ELSE FIRST.
Updated 2026-11-16 04:58 CT by the supervisor. If you own a lane, your next item is named here.
Search the file for its ID and work it. DO NOT take "the first unchecked item you find reading
down the file."

  GAME BUILD   ->  *** D91 STAGES 2-4. D94 IS OFF YOUR DESK. *** Your D94d landed: the cloak
                   shade step is mirrored into gear.gd, verified 49/49 against the art lane's own
                   table, merged and TICKED. Do NOT re-derive the dyes, re-shoot the cloak row,
                   re-render D95 or re-measure D83. The walnut-black pair reading as near one
                   object is NOTED under D94 and nobody is queued on it - a value step on black is
                   invisible and the fix would belong in the shared table, which is Mr. E's call.
                   What is left of D94 is both HIS, not yours: the ring/glove size at stream
                   distance, and the legendary pool being 16 deep with zero boots and zero gloves.
                   YOUR ITEM IS NOW D91 STAGES 2-4 - three-cell corridors, monsters into the
                   avoidance, party in file. That is the WHOLE of Phase 1's remainder and the next
                   phase-order item. Stage 1 (the shared Crowd helper, solid bushes, measured
                   animal radii) is already in; build on it, do not rebuild it.
  ART          ->  *** YOUR D94 HALF IS FINISHED - MINIBOSSES ARE NOW LIVE FOR YOU *** Both
                   derivation faults you owned are closed: the proof sheet reports no DUPLICATE on
                   any row, and the cloak dye plus your shade step give 49 distinct (colour, cut)
                   pairs out of 49. Do not re-run either. The legendary pool is data, not a
                   derivation - you measured it and handed it back correctly; it is with Mr. E.
                   That leaves this lane GENUINELY DRY, and a dry art lane has Mr. E's standing
                   permission to invent a MINIBOSS (no lore needed). Take one. Do not reach into
                   another lane's files, do not re-render D95, and do not write new plan items.
  HUD          ->  STAND DOWN. Mr. E shut this lane down for D94 (00:55) and only he lifts it.
                   D94's build half landing does not lift it, and neither does this merge. L73's
                   last step - the 30-minute capture in which a viewer can tell from the camera
                   alone when something important happened - stays queued, then L74. Both wait.
                   DO NOT rebuild the shot language. Do not reach into another lane's files to
                   look busy. The lift is in NEEDS MR. E and has been since 02:58.
  HUB          ->  STAND DOWN. Same shutdown, same rule. H29, H30 and H31 are shipped, merged
                   and ticked, and the freeze forbids inventing more. Nothing is queued.
  CONTENT      ->  STAND DOWN. Same shutdown, same rule. C-60 (phase2_words) is merged to main
                   and was the last thing this lane owed. C2 stays standing and open by design
                   for when the shutdown lifts.

WHY THIS BLOCK EXISTS - THE BUG WAS IN THE PLAN, NOT IN ANY WORKER.
Every ruling written on 15 Nov was PREPENDED to the top of this file, so the plan reads in
REVERSE CHRONOLOGICAL order and "the first unchecked item in the file" is simply the most
recently WRITTEN one, which is the opposite of the phase order. That is how D93 (Phase 3) got
built while D88 and D83 (Phase 1) sat untouched. It is nobody's fault but the plan's. No worker
misbehaved. D93a was not wasted either - the town layout format, loader and validator are
Phase 3's foundation.

PHASE ORDER IS UNCHANGED AND STILL BINDING: Phase 1 stop it looking broken -> Phase 2 make the
loop real -> Phase 3 the authored town -> Phase 4 the art -> Phase 5 the Dais. The full
breakdown is in the PHASE RC section further down. This block is just the pointer.

PHASE 1 IS DOWN TO ONE ITEM. All five lanes were merged to main again on 2026-11-16 at 02:05,
D88 and D83 are both TICKED, and the traps turned out to be creatures hung 400 m above the floor.
STILL OPEN AND NEXT: D91 stages 2-4 (three-cell corridors, monsters into the avoidance, party in
file). That is the whole of Phase 1's remainder. D94's remainder sits outside the phase ladder,
and as of 04:58 CT every BUILDABLE part of it is closed - what is left of D94 is two decisions in
NEEDS MR. E. So D91 stages 2-4 is now the game build's actual next item, unblocked.
Nothing in this plan is DONE until the supervisor ticks its checkbox. A commit on a branch is
not a tick.
================================================================================
### THE HUD LANE ROW WAS WRONG - CORRECTED (20:58). D41, D48 AND D61 ARE NOT THE HUD'S.
I wrote "HUD: L71 -> L64 -> D61 -> D41 -> D48" at 17:10. That was an error and it stranded the
HUD worker: L71 and L64 are both shipped, and D41, D48 and D61 live in party_frames.gd,
rts_camera.gd, delve.gd, monster.gd and boss_bar.gd - NONE of which the HUD worker owns. It owns
exactly seven files: hud_dock.gd, spotlight.gd, auto_director.gd, dice.gd, feed_hud.gd,
leaderboard_panel.gd, ui_theme.gd. D41/D48/D61 stay with GAME BUILD where they already were.
The HUD worker was right to stand down rather than reach into files it does not own. Its real
queue is below, all three inside its own seven files.

- [x] L72. THE CAMERA PULLS BACK FOR A GREATER LORD (HUD, auto_director.gd) - see the block below.
      RESULT (ticked 2026-11-15 23:10 CT by the supervisor; hud-ui 4b2b61d, merged to main): the shot
      frames by MEASURED mesh bounds and by the LARGER of height and width, so the 8.3 m-wide room-locked
      Grubmother fits as well as the 10 m Mourncoil; the reveal is an ease-out move, not a cut; the eye is
      clamped out of geometry. _l72_test.gd walks all eight lords and measures every subject point against
      the real frame plus a cam_in_solid probe: L72_TEST DONE fails=0. CAVEAT, not a reason to reopen: the
      test writes a frame per lord but only the Mourncoil reveal sheet and a three-pane sheet were committed
      (renders/cycles/20261116_l72/), so Mr. E has one reveal to look at rather than eight.
### L72 - THE CAMERA PULLS BACK FOR A GREATER LORD (HUD, auto_director.gd) - FIRST
Mr. E already approved this at 17:42 ("yes it should pull back"); it just never got an ID. The
art lane shipped eight lord meshes and two of them are enormous - Mourncoil 10 m, Gravewyrm 9 m -
at canon heights that stay. The camera adapts, not the monster.
  1. A shot that frames by the SUBJECT'S HEIGHT, not a fixed distance, so a 10 m lord is framed
     whole, including the floor it stands on. Height comes from the mesh bounds - never a table
     of names, or the next lord breaks it.
  2. THE PULL-BACK IS A MOVE, NOT A CUT. Ease out as the lord rises. That reveal is worth more
     than any amount of stat text, and it is the single best use of the new meshes.
  3. Clamp to the room. Never punch the camera through a wall, and do not fight D91's three-cell
     corridors.
  4. The Grubmother is room-locked and 8.3 m WIDE at 4.5 m tall - frame by the larger dimension,
     not by height alone, or she will not fit the shot.
DONE: a capture of each of the eight lords entering frame, at 1080p, none clipped and none with
the camera inside geometry. Mr. E's eye on whether the reveal lands.

- [ ] L73. THE DIRECTOR'S SHOT LANGUAGE (HUD, auto_director.gd + spotlight.gd) - see the block below.
      L73 HALF DELIVERED / STILL OPEN (supervisor, 2026-11-15 23:58; hud-ui 3e47674, merged to main).
      The shot language itself is built and verified and is NOT to be rebuilt: it is laid on the existing
      _pace hook, a delve opens wide and low and settles (34.0 -> 19.1), a fight closes in as the party is
      hurt (24.6 -> 17.4), a death is held and crept into, and the quiet after eases back out. L73_TEST
      passes and six stills are in renders/cycles/20261116_l73.
      WHAT IS LEFT, AND IT IS THE ITEM'S OWN DONE GATE: the 30-MINUTE CAPTURE in which a viewer can tell
      from the camera alone when something important happened. The lane ran a ~6-minute windowed test, not
      the 30-minute run. One capture of the same shape as the L64 30-minute director run finishes this and
      then it ticks. Mr. E's eye stays final on whether the language lands.
### L73 - THE DIRECTOR'S SHOT LANGUAGE (HUD, auto_director.gd + spotlight.gd)
L64 proved the director cuts cleanly - 183 cuts, 0 repeats, 0 dual-pane frames over 138,053
frames. Cutting correctly is not the same as telling a story. Give it a vocabulary: an
establishing shot when a delve starts, a tighter one as a fight turns, a hold on a death, a beat
of quiet after. The pacing hook `_pace` already exists (0.6 in a raid, 1.4 when quiet) - build on
it rather than adding a second knob.
DONE: a 30-minute capture where a viewer can tell, from the camera alone, when something
important happened. Mr. E's eye is final.

- [ ] L74. THE FEED AND THE THEME UNDER LOAD (HUD, feed_hud.gd + ui_theme.gd) - see the block below.
### L74 - THE FEED AND THE THEME UNDER LOAD (HUD, feed_hud.gd + ui_theme.gd)
L71 fixed truncation. The next question is readability when the town is busy and lines arrive
faster than they can be read: pacing, what gets dropped, and whether every panel reads as one
designed interface at 100/125/150% scale.
DONE: shots at all three scales during a raid, with nothing overlapping and nothing unreadable.

### L66 IS MOVED TO THE HUB AS H31 - IT WAS CORRECTLY BLOCKED
The HUD worker flagged that L66 (an on-stream season leaderboard) conflicts with COORDINATION 13:
six on-stream things only, and the Guild Roll was REMOVED from the stream in L58 for exactly this
reason. It was right to stop rather than quietly break a rule.
RESOLVED: the stream has six slots and a leaderboard competes with the game for them; the hub has
unlimited room and is where a viewer goes to look things up. So L66 does not get an exception -
it moves. L66 is CLOSED as an on-stream item. The HUD exposes the standings data and nothing
more; the board itself becomes H31 on the hub.

- [x] H31. THE SEASON LEADERBOARD, ON THE HUB (hub lane, after H29) - see the block below.
      RESULT (ticked 2026-11-15 23:10 CT by the supervisor; hub a08c499, merged to main): the fifteenth tab
      ("Season"), four boards of ten - deepest, earned most, died hardest, lived longest - living and fallen.
      Honest gaps stated on the page rather than faked: "Earned most" ranks gold HELD because the publisher
      sends only current gold, and "Lived longest" shows an explanatory empty state until an age/born_day
      field exists. Both light up by themselves when the fields arrive (names in docs/HUB_SECURITY.md).
### H31 - THE SEASON LEADERBOARD, ON THE HUB (hub lane, after H29)
Standings over a season, from the snapshot: who went deepest, who earned most, who died hardest,
who kept a hero alive longest. The hub can afford the space and the detail the stream cannot.
Same security invariants as every other tab - el()/textContent only, ICON_SET whitelist, CSP
unchanged, hostile names rendered as text.
DONE: renders from a snapshot with a full season, an empty season, and a hostile name.
 WORK PLAN 2 — Bellmire HD grows (Nov 11 2026 onward)

### READ FIRST IF YOU ARE THE HUB WORKER (supervisor, 2026-11-16 00:12 CT)

YOUR STANDING BRIEF IS STALE AND IT IS COSTING RUNS. It still carries a "STATE AS OF NOV 15"
paragraph saying "the hub queue is EMPTY ... stand down". That was true on 15 Nov. It is not true
now, and two runs in a row (23:38 and 00:05) ended inside a minute on the strength of it.

YOUR QUEUE IS NOT EMPTY: H29 -> H30, both unchecked. H29 sits LOWER in this file than H30, so
"first unchecked" lands you on the wrong one - search for "### H29" and take H29 first.
H29's point 6 waits on the GAME BUILD worker's publisher (shop_stock / trader_cargo in the
payload). That is ONE line of the item and it does not block the rest: build the tab, its empty
state, the shop/blacksmith list with levels and stock from ?mock= snapshots, the mixed-level and
caravan-present states, a viewer's outstanding orders, the plain "buying places an order and the
hero walks to collect it" caveat, and the hostile-name canary extended to item and shop names.
Put the live-data path behind the existing payload version gate (KNOWN_V is at v4 today) so the
tab lights up by itself when the publisher sends the fields. If something still blocks you, name
the line and what would unblock it - that report is the work. Do not stand down silently.

SUPERVISOR NOTE, SO THIS IS NOT LOST: the supervisor could not correct the brief itself - editing a
scheduled task's prompt was refused in that session ("Cowork Scheduled Task Write" denied), and a
fire_trigger from a supervisor session comes back "not approved for CruzaderPC - this run uses the
cloud only", i.e. a fired run has no access to the machine and can do nothing. So an out-of-band
fire is NOT a way to feed a worker here; only the scheduled fire works, and a stale brief stays
stale until Mr. E or an authorised session edits it. The same note applies to the HUD worker's
brief, which still lists L61/L31/L36/L40 as its queue while Phase RC gives it L71 -> L64 -> D61 ->
D41 -> D48.

- [ ] C-55. ONE RARITY LADDER FOR THE WHOLE GAME (content lane) - see the block below.
### C-55 - ONE RARITY LADDER FOR THE WHOLE GAME (content lane, Mr. E Nov 15 17:56)
  DATA HALF DELIVERED AND VERIFIED (supervisor, 2026-11-15 23:10 CT; content d097b9e, merged to main).
  Landed as the content lane's cycle C-58, NOT as a commit called C-55 - the ruling's ID collided with the
  lane's own cycle counter, which had already used C-55 for the boss uniques. IDs are frozen; this note is
  the pointer. MEASURED on main: 380 entries now carry "rarity" across equipment and accessories, spread
  common 77 / uncommon 125 / rare 74 / very rare 58 / legendary 35 / artifact 11. No "epic" and no S-tier
  survives anywhere in items.json, and every one of the 11 artifacts has cost 0 - none is priced.
  STILL OPEN, AND IT IS THE GAME BUILD'S HALF, NOT THE WRITER'S: the economy ruling is a label so far, not
  a rule. Code must refuse to let a shop stock an artifact at any level and refuse to let the trader carry
  one (shop_stock / trader_cargo / stock_by_tier readers, with D64's level gate). Do not tick C-55 until
  that is enforced in code.

Mr. E listed "common, uncommon, rare, epic, legendary, s+, ss+, sss+. or however the DnD labels
them" and asked for a recommendation. DECIDED: D&D's six. No S-tiers.

MEASURED FIRST:
  - A rarity ladder ALREADY EXISTS AND IS LIVE, but only for fishing: junk, common, uncommon,
    rare, epic, legendary (chatcmd.gd ~69; angler.gd colours a catch by it; 21 "rarity" keys in
    fishing.json).
  - EQUIPMENT HAS NO RARITY AT ALL. 119 entries in items.json carry "tier_name" and NOT ONE
    carries "rarity". The 230 accessories carry none either. So the fish in the river have
    rarities and the sword in a hero's hand does not. That is the gap.

THE LADDER, AND WHY THE LAST RUNG IS A MECHANIC AND NOT A WORD:
    junk (fishing only) -> common -> uncommon -> rare -> very rare -> legendary -> artifact
In D&D an ARTIFACT is unique and FOUND - it is never bought. gear.gd already says exactly that:
scarforged and scarwoven mail are "found": true with cost 0. So "artifact" is not a fancier word
for legendary, it is THE LABEL THAT ENCODES MR. E'S OWN ECONOMY RULING: a shop may stock a
legendary at a high enough level; IT MAY NEVER STOCK AN ARTIFACT, at any level, and the trader
may never carry one either. Enforce that in code, not just in the name.
Six rarities map ONE-TO-ONE onto the six weapon and six armour tiers:
  common bare hands/rags · uncommon plain steel/leather · rare fine steel/chainmail ·
  very rare runed/plate · legendary dragontooth/warded plate · ARTIFACT scarforged/scarwoven
"junk" stays below common for FISHING ONLY - a wet boot is not common, it is junk.

NO S-TIERS, AND THE REASON IS THE REGISTER. S+/SS+/SSS+ is gacha convention. Bellmire's voice is
plainness ("Measured the grain. Counted the flasks. Kept the door."). An "SSS+ Longsword" beside
that line is a tonal collision, and it would say nothing "artifact" does not already say better.
"Epic" goes too: it is MMO vocabulary, not D&D, and it is the one rung with no D&D meaning.

THE WORK:
  1. Rename epic -> very rare: five entries in fishing.json and the order array in chatcmd.gd.
     Small, and it is the only thing viewers will notice changing.
  2. Add "rarity" to all 119 equipment entries and all 230 accessories, derived from tier and cost
     - do not hand-assign 349 values, derive them and spot-check.
  3. One shared ladder constant, read by fishing, gear, shops, the trader and the hub. NOT three
     copies that drift.
  4. Shop stock and trader cargo honour it: the existing tier gate decides how high a shop reaches,
     and ARTIFACT IS OUTSIDE THE GATE ENTIRELY - unreachable by purchase at any level, by anyone.
  5. The hub and the icons use the rarity for colour, so a viewer learns the ladder by looking.
     D73's icons already colour by stat for accessories; rarity is the better axis for a border
     or a frame - keep both, they say different things.
  6. Rarity is a LABEL ON EXISTING TIERS, not a new stat. It changes no numbers. If anyone finds
     themselves balancing with it, stop - that is tier's job.

### WEAR IS A VARIABLE, NOT A STYLE (Mr. E, Nov 15 17:50) - READ THIS BEFORE ANY ART DECISION
"just a reminder the town levels up so not everything is going to look used and abused just
remember that".

HE IS RIGHT AND THIS CORRECTS THE LINE ABOVE. "Worn and used" as a blanket look is WRONG, and
applying it everywhere would quietly break the single most important thing the game has to show:
a town getting better because viewers paid to make it better.

CONDITION TRACKS LEVEL AND TIER. It is not a mood, it is a READOUT.
  - A LEVEL 1 BELLMIRE is patched and make-do: mended thatch, grey timber, a banner that has seen
    weather, tools worn to the shape of a hand.
  - A LEVEL 12 BELLMIRE IS PROSPEROUS. Fresh-cut timber, cut stone, clean paint, bright banners,
    glass where there were shutters. It should look like somewhere that is DOING WELL, because it
    is, and because the viewers did that.
  - THE SAME FOR GEAR. Rags and bare hands are worn. Plain steel is serviceable. Dragontooth,
    warded plate and scarforged should read RICH and NEW - a viewer who spent months of points on
    a legendary piece must not be handed something that looks second-hand.
  - THE SAME FOR SHOPS. A level 1 shelf is thin and plain; a level 12 shelf is full and fine.

WHY THIS MATTERS MORE THAN IT SOUNDS: the upgrade poll is a thing viewers SPEND ON, and the only
proof they get is what they can see. If every level looks equally weathered, the money bought
nothing visible and the whole growth system is invisible. CONDITION IS THE RECEIPT.

HOW IT SITS WITH THE PLAINNESS RULE (they do not conflict):
  - PLAINNESS is about VOICE - things look like what they are for, nothing is theatrical, no
    gothic flourish. That holds at every level.
  - WEAR is about STATE - how new, how rich, how cared-for. That CHANGES with level and tier.
  - A level 12 Bellmire is plain AND prosperous: good timber, well cut, no ornament for its own
    sake. Prosperity in this game looks like things being WELL MADE, not things being decorated.
  - The epitaphs stay the guide for voice. They are not a guide for condition.

FOR THE ICON RE-RUN SPECIFICALLY: the 230 accessories span the whole cost range, so drive their
condition from COST as the generator already drives ornateness - cheap reads handled and worn,
expensive reads new and well kept. One axis, already present in the data. Do not give all 230 the
same wear.

### MINIBOSSES NEED NO LORE (Mr. E, Nov 15 17:43) - A STANDING PERMISSION FOR THE ART LANE
"you can always add mini bosses as well. that dont have to be lore mentioned".

THIS UNBLOCKS THE ART LANE PERMANENTLY. Until now a new creature implied new canon - a name, a
place in the bestiary, lore_lines to write, a content-lane dependency. Minibosses do not. The art
worker may invent them outright and ship them without waiting on anybody.
  - THE SET PIECE ALREADY EXISTS. dungeon_hd.gd's set-piece weights already include "miniboss"
    (15 on a normal floor, 35 on the right theme). The slot is built and under-used; it just needs
    better things to put in it.
  - WHAT A MINIBOSS IS: a creature with a presence, a silhouette of its own and one idea that
    makes the fight different - it summons, it splits, it armours itself, it drags people. NOT a
    normal monster with more hit points. That is the only bar.
  - NO LORE DEBT. No entry in the canon, no named history, no lore_lines. A line in the feed when
    it appears is enough. If one turns out to be a favourite, lore can be written for it LATER -
    earned, not assigned.
  - THE ART LANE OWNS THEM END TO END: invent, build, render, ship. Same pipeline as the lords
    (tools/art/), same bar - at most four meshes, silhouette-readable, no hero body.
  - THEY ALSO FILL D76's HOLE CHEAPLY. Twelve creature types currently share a mesh with another
    type; a miniboss built for one of those slots solves a duplicate AND adds a fight at once.
  - Every miniboss still obeys the Grubmother rule above: if it cannot fit a corridor, it is
    room-locked by construction, not by hoping.
SHIPPED UNDER THIS PERMISSION (supervisor, 2026-11-15 23:10 CT; art e606fe7, merged to main): four set
pieces, each with one idea that changes the fight, all four measured CORRIDOR-SAFE against the 11.0 m clear
and all four under D91's three-cell width. The Drillmaster (barracks, 1.4 m - it summons, beats the muster
and the garrison forms up), the Scrapwright (workshop, 2.8 m - it armours itself, every plate knocked off is
replaced from the floor), the Gaoler (prison, 3.7 m - it drags, the hook takes one hero out of the line) and
the Snuffer (shrine, 1.5 m - it takes the light, it puts out the lamps). Silhouette sheet, contact sheet,
three views each and a wear value per creature in renders/art/minibosses/; generator tools/art/minibossgen.py;
docs/art/MINIBOSSES.md carries the write-ups. THE GAME-BUILD HALF IS NOT DONE and is not claimed here: the
art lane never runs Godot, so none of the four is wired into dungeon_hd.gd's existing "miniboss" set-piece
weight yet, and none has been seen in a fight. That wiring belongs to the game build, after Phase 1.
SECOND SET OF FOUR (supervisor, 2026-11-16 01:05 CT; art 42179ee, merged to main): the Sexton
(crypt, 2.45 m - it will not stay down; four lit niches are four risings, countable from the
doorway), the Porter (keep, 2.30 m - it bars the way: no retreat, no reinforcement), the Tallyman
(treasury, 2.15 m - it takes gear off the party, wears it where the viewer who paid for that helm
can see it, and withdraws) and the Cook (mess, 2.05 m - the pot heals the room; spill the pot).
These four cover the themes where dungeon_hd.gd rolls the miniboss set piece at 15 and 10 and had
nothing theme-matched to put in the slot. All four merged by material, 1094-1722 faces, feet on
z=0, corridor-safe against the 11.0 m clear span; none room-locked. Wear spreads across all eight
and no two share a value (tallyman 0.20 up to snuffer 0.90). The art worker's own write-up records
three silhouettes the pictures overruled before it shipped - that is the bar working.
THE GAME-BUILD HALF IS STILL NOT DONE FOR ANY OF THE EIGHT: the art lane never runs Godot, so
none is wired into dungeon_hd.gd's "miniboss" set-piece weight and none has been seen in a fight.
That wiring belongs to the game build, after Phase 1.
THEMES STILL WITHOUT ONE: only the biome themes (wood, grassland, flooded).

GOOD IDEAS ARE NOT WORK: under the freeze, minibosses are a PERMISSION, not a queue. The art lane
takes its queued item first and builds a miniboss when that lane is otherwise dry - which it has
now been twice this week.

## MR. E ANSWERS THE ART LANE (Nov 15 17:42) - FOUR RULINGS

The art worker shipped D75 (eight lords) and D73 (454 icons) and held four questions. Answered:

### 1. THE GRUBMOTHER IS ROOM-LOCKED, AND HER BROOD COMES INSTEAD. **This is a design win.**
Mr. E: "grub mother is a spider so lets make her only spawn on floors that have big rooms, if she
cant fit through the corridors then she cant fit simple as that. thats why she is a mother her
brood should be going through the corridor instead".
DO NOT CLAMP HER. 8.3 m wide at 4.5 m tall is correct - bosses.json calls her a wall and she
should BE one. The constraint becomes the character:
  - She spawns only on a floor that HAS a room big enough to hold her, and she never leaves it.
    Floor generation must check for a qualifying room before she is eligible at all; if no room on
    that floor fits her, she is not that floor's lord.
  - SHE DOES NOT PATHFIND DOWN CORRIDORS. Remove the possibility rather than relying on her
    failing to fit - a boss wedged in a hall is D44 with a bigger body.
  - HER BROOD IS HER REACH. The small ones come down the corridors after the party while she holds
    the room. That is the fight: you are harried in the halls by her children and you have to walk
    into her chamber to end it. It also makes the brood mechanically meaningful instead of
    decoration.
  - The party meeting the brood should read as a WARNING - the deeper they go the more of them,
    so a viewer learns what is waiting before they see her.
Owner: game build (floorgen eligibility + bestiary spawn rules), with the room-size check living
beside the three-cell corridor work in D91.

### 2. THE CAMERA PULLS BACK FOR A GREATER LORD. Mr. E: "yes it should pull back."
Mourncoil at 10 m and the Gravewyrm at 9 m are canon heights and stay. The camera adapts:
  - The director gets a shot that frames by the SUBJECT'S HEIGHT, not a fixed distance. A 10 m
    lord is framed whole, including the floor it stands on.
  - The pull-back is a MOVE, not a cut. Easing out as the lord rises is the reveal and it is worth
    more than any amount of stat text.
  - It must not fight the three-cell corridor work or leave the camera inside geometry - clamp to
    the room, do not punch through a wall.
Owner: HUD (auto_director.gd owns framing). Hand it the lord's height; do not special-case names.

### 3. THE HOLLOW KING'S COLD FIRE GETS ITS VFX PASS. Mr. E: "do what you need to... if it needs it
do it. if you need me to do something ask me."
The geometry is right and stays. Flicker, drift and light are an in-engine pass: animate the blade
geometry, add an emissive pulse, and let it cast actual light so the chamber reads cold. Keep it
cheap - this is one boss on one floor, not a particle budget for the game. Owner: game build, with
D75's wiring. NOTHING IS NEEDED FROM MR. E ON THIS.

### 4. THE ACCESSORY ICONS GO DARKER. (He asked what was being asked - it was a taste question and
it should not have been put to him as one.)
WHAT IT MEANT: 224 of the 454 items store a colour, so their icons use it. The other 230 - the
accessories - store none, so the generator invented their leather and metal tones from a default
eight-tone palette, and those came out lighter and warmer than the rest of Bellmire looks.
CORRECTED 17:50 - "DARKER AND COLDER" WAS WRONG AND IS WITHDRAWN. Mr. E pushed back: "it can
come out however as long as it fits with the game. this game doesnt really have a tone
preference, correct me if i am wrong". I checked lore_lines.json before answering, and he is
right that there is no MOOD preference - but there is a very consistent VOICE, and it is not grim:
    "Measured the grain. Counted the flasks. Kept the door."   (epitaph)
    "Went down with a lamp. Did not come up."                  (epitaph)
    "Count the flasks." / "Keep the door." / "Light first. Then steel."   (barks)
    "The scar keeps what it takes."
    "Fresh off the river: trout, and a tale with every one."   (the crier, cheerful)
Terse, practical, working-class stoicism. Short declaratives. Nobody is dramatic. The dread is in
what is NOT said - "did not come up" is six plain words and it is the whole horror of that line.
And there is real warmth in it.
SO THE RIGHT DIRECTION IS WORN AND USED, NOT DARK AND COLD. Leather that has been handled for
years; metal maintained rather than polished; gear owned by people who count flasks and keep
doors. A material story, not a mood. Gothic or desaturated icons would fight the writing.
THE RULE FOR EVERY ART DECISION FROM HERE: Bellmire has no mood preference, it has a VOICE
preference, and that voice is PLAINNESS. Things look like what they are for. When in doubt about
how a thing should look, read the epitaphs - they are the clearest statement of the game's
register anywhere in the repository.
One constant in icongen.py and a re-run. Mr. E vetoes on sight from the contact sheets in
renders/art/icons/. DO NOT ASK HIM IN WORDS; re-run it, show him the sheet.
THE GENERAL RULE THIS SHOULD HAVE FOLLOWED: do not ask Mr. E a question that a picture would
answer. Build it, render it, show him. He is quick and decisive when he can SEE the thing.

### THE D76 CENSUS LINE IN THIS PLAN IS WRONG - CORRECTED HERE
WORK_PLAN claimed ~109 monster families share 10 models. The art worker counted bestiary.gd:
**30 creature types across 18 distinct models, with 12 types sharing a mesh with another type.**
The 109 was most likely types x the nine strains, or types plus the 270 lord uniques. The scope is
in docs/art/D76_SCOPE.md. D76 IS NOT "build a system to carry 109" - it is "give twelve creatures
a body of their own", the same size as the eight lords. Treat the smaller number as the truth.

### THE DUNGEON FALLBACK (Mr. E, Nov 15 16:59) - HELD IN RESERVE, NOT STARTED

"if dungeons become an issue we can make those pre built as well. and just have around 200+
versions so it seems like its always 'changing'".

RECORDED AS A CONTINGENCY. Do NOT start authoring dungeon floors. D91 (crowd avoidance + three-
cell corridors) is the current answer and it must be tried first: the dungeon's problem is bodies
with no separation in halls too narrow to hold them, and that is fixable without touching
generation. If D91 lands and floors still read as broken, this is the fallback and Mr. E has
already approved the shape of it.

IF IT IS EVER TRIGGERED, DO NOT HAND-AUTHOR 200 WHOLE FLOORS. Author CHUNKS instead - rooms,
junctions, corridor runs, stair halls, set-piece chambers - each one hand-built, correct, and with
declared exits, then assemble a floor by snapping chunks together at those exits. Fifty authored
chunks give more than 200 floors' worth of variety, every square metre of every floor is still
hand-laid, and a fix to one chunk fixes it everywhere it appears. A hand-drawn floor is a
beautiful thing you get once; a hand-drawn chunk is a beautiful thing you get a hundred times.
It also keeps the thing Mr. E actually wants from a dungeon - that it is different every delve -
which 200 fixed maps would lose the moment a regular viewer recognised one.

The authored-town work (D93) builds the layout format, the loader and the validator. If this
fallback is ever triggered, the chunk format should reuse all three rather than invent a second
way of describing a place.

TWO ADDITIONS (supervisor dedupe, 17:00 - this section was written twice independently and the
other copy was removed; these are the only points it had that this one did not):
  - A BIOME AND DRESSING PASS ON TOP OF AN AUTHORED LAYOUT makes the same skeleton read as a
    different place. It multiplies whatever library we build, chunks or floors, for very little
    work - floorgen already remakes a floor's origin as another biome, so the mechanism exists.
  - THE STANDING RULE HOLDS REGARDLESS: canon NEVER STATES A FLOOR COUNT. A library of 200 layouts
    is not a statement that the dungeon has 200 floors, and nothing in the game, the hub, the bot
    or the lore may imply that it does.

## MR. E'S RULING (Nov 15 16:57) - BELLMIRE IS HAND-BUILT. NO MORE PROCEDURAL TOWN. **BINDING**

Verbatim: "we need to make sure the roads are being built correctly and not overlapping. in my
opnion we should just make the maps of the town. all the way to level 15. we have the buildings
get placed in a specific fashion. for now this game is not an ever expanding world. we are keeping
it to the one town. the lore can stay (if its in the lore at all) we will make a well built town.
have it pre made for each level and however big the upgrades are. because right now its auto
generating and causing collisions. so let make just one big map. lay out the roads correctly, the
buildings, then town square."

HE IS RIGHT AND THIS IS THE CORRECT CALL. Every town placement bug of the last two days - the
overlapping farms (D92), the dirt patch cutting across the road in his 16:57 shot, the body in the
bush (D91.5), props in lanes, wagons parked across paths - is the same bug wearing different
clothes: a generator placing things by sampling and hoping. We have been writing better and better
collision tests to referee a fight that should never happen. A town is a DESIGNED PLACE. Design it
once, well, and the entire class of bug is gone by construction rather than by test.

### WHAT THIS DECIDES, AND WHAT IT DOES NOT
  - THE TOWN IS AUTHORED. One map, laid out by hand: roads first, then the square, then buildings
    onto the blocks the roads make. No runtime placement, no seeded scatter deciding where a
    building stands.
  - THE DUNGEON STAYS PROCEDURAL. It must - it is a different floor every delve and that is the
    point. D91's crowd avoidance and three-cell corridors are UNAFFECTED and still RC.
  - THE VALLEY outside the town walls can stay generated; it is open ground and nothing there
    needs to interlock. Keep the obstacle work honest there, but it is no longer urgent.
  - D92 IS SUPERSEDED FOR THE TOWN. The oriented-rectangle test is still worth having for the
    valley and for anything the dungeon places, but farms stop being a placement problem the
    moment the farms are drawn by hand. Do not spend a big item on it now.
  - LORE IS UNAFFECTED. He said the lore can stay. Nothing written is invalidated.

### THE ARCHITECTURE ALREADY WANTS THIS - growth.gd is a layer system
growth.gd keeps `_layers = {}  # level -> Array[Node3D], shown from that level on`, and
`show_level()` SHOWS AND HIDES - it does not rebuild. Its own comment says a level change "costs
nothing and the navmesh never moves". That is exactly the shape a hand-authored town needs. The
only thing wrong today is that the nodes in those layers are generated at startup instead of
authored. Keep the mechanism; replace its contents.

### EACH LEVEL IS A SUPERSET OF THE ONE BEFORE - THIS IS THE RULE THAT MATTERS
Level N+1 ADDS to level N. It never moves a road, never shifts a building, never re-plots the
square. When the town levels up on stream, viewers must see something NEW APPEAR in a place that
was empty - scaffolding becoming a shop, a dirt lane becoming cobbles, a wall extending. They must
NEVER see the town they know rearrange itself around them. Author level 15 FIRST, as the finished
town, then work backwards deciding what is absent at each earlier level. Authoring forwards
guarantees a later level will want to move something an earlier one placed.

- [ ] D93. AUTHOR THE TOWN (game build + art, LARGE, supersedes town generation)
      THE ITEM ITSELF IS THE BLOCK DIRECTLY BELOW THIS LINE - read it there. This pointer exists only
      so a worker scanning for its first unchecked item lands on it (supervisor, 2026-11-16).
      D93a DONE (game build, Nov 15 22:30): steps 1 + 5 - format "bellmire-town/1" (data/town/README.md),
      VALIDATOR tools/_d93_validate.gd (PASS on a good fixture, catches all 6 defect kinds on a bad one),
      and the GENERATED town measured: overlap 0, on_road 8 (all landmarks), on_square 3, DOOR 61/66
      houses not within 2 m of a road, 5 road islands. OPEN: 2 roads, 3 square+buildings, 4 loader, 6 levels.

### D93 - AUTHOR THE TOWN (game build + art, LARGE, supersedes town generation)
  1. A LAYOUT FORMAT, as data, not a scene: one file per level under data/town/ with roads as
     polylines, the square as a polygon, and every building, prop and site as an entry with a
     position, a rotation and an id. Data because it is diffable, editable by Mr. E and by any
     worker, and reviewable in a PR. A .tscn is not.
  2. ROADS FIRST. Lay the road network by hand, as a connected graph with real widths. Every road
     a deliberate line. The ground patches (soil, dirt, cobble) are authored to the road polygons
     so nothing is ever drawn across a road again - which is the dirt patch in his shot.
  3. THE SQUARE. Then the blocks the roads enclose. Then buildings onto the blocks, each with its
     door facing a road, by hand.
  4. A LOADER that builds the town from the layout file and registers everything - navmesh,
     obstacles, sites, doors - from authored data rather than discovering it. Delete the placement
     code paths it replaces; do not leave both alive.
  5. A VALIDATOR run in CI and headless: no two building footprints overlap, no footprint crosses
     a road, every door touches a road, every site is reachable from every other, and no ground
     patch overlaps a road polygon. It is cheap and it makes the authored town provably correct.
  6. STAGE IT. Author level 15, get it right, then derive the earlier levels backwards. Ship the
     loader against level 15 first so the town is playable the whole way through the work.

### DECIDED: TWELVE LEVELS FOR NOW (Mr. E, Nov 15 17:10 - "aim for 12 for now")
TWELVE. He said fifteen a minute earlier and changed it to twelve; TWELVE IS THE ANSWER and this
line supersedes the other. Author the town to twelve levels.

THIS COSTS NOTHING, WHICH IS WHY IT IS THE RIGHT CALL. Everything already agrees on twelve:
  - items.json shop_stock (245 entries) and trader_cargo (147) each carry a "tier" 1-12
  - items.json stock_by_tier: exactly 12 entries (shop_adds / cargo_adds)
  - lore_lines.json growth_tiers: 12, and the above are generated to agree with it
  - economy: 12 TOWN_LEVELS
So no table has to be extended, no new lore has to be written, and the 16:05 gear ruling - a shop's
level gates what is on its shelf - keeps working untouched. Fifteen would have meant extending all
four in lockstep, and a level 13 shop with no stock table is a silent hole in the economy.

"FOR NOW" IS HIS WORD AND IT IS LOAD-BEARING. Build so twelve is a NUMBER, not an assumption:
  - the authored town is ONE map with per-level reveal tags (D93), so adding a thirteenth level
    later means tagging a few buildings, not drawing a new map
  - growth.gd's TOP_LEVEL and the tier mapping stay driven by data, never hard-coded in logic
  - IF THE CAP EVER RISES, the stock, cargo, stock_by_tier and growth_tiers tables are extended IN
    THE SAME CHANGE that raises it. Never after. That is the rule that keeps the economy whole.

### THE ORIGINAL QUESTION, KEPT FOR THE REASONING:
He said "all the way to level 15". The numbers in the code today do not have a 15 in them:
  - growth.gd TOP_LEVEL = 6 (six visual build stages)
  - economy has 12 TOWN_LEVELS, and growth maps two economy tiers per visual stage
  - items.json's shop_stock, trader_cargo and stock_by_tier are all keyed to tiers 1-12, matching
    lore_lines.growth_tiers
So the shop stock ladder, the trader's cargo and the growth lore are ALL built on TWELVE. Going to
fifteen means extending all three, and the 16:05 gear ruling (shop level gates what is on the
shelf) is wired to that same ladder. Going to twelve means authoring twelve maps and the rest
already lines up. ASK HIM. Do not guess, and do not quietly author 12 and call it 15, or 15 and
leave the stock tables at 12 - a shop at level 13 with no stock table is a silent hole in the
economy he will find on stream.

### D92 - THE FARMS OVERLAP: RECTANGLES CHECKED AS CIRCLES, SAMPLED WITH GAPS (game build)

Mr. E, Nov 15 16:53, with a shot of the livestock paddock: "the farms are being built so weirdly,
ones overlapping theother". Fence lines at different angles run straight through one another.

THE CAUSE IS A SHAPE MISMATCH, IN THREE PLACES. Fenced plots are ORIENTED RECTANGLES on the
ground, and every test that is supposed to keep them apart is a CIRCLE or a sparse POINT SAMPLE.

  1. SPARSE SAMPLING WITH HOLES. town.gd `_field_ok` (~2787) walks a 5x5 grid over the field and
     calls `is_clear(q, 1.2)` at each point. The samples are spaced hw/2 and hd/2 apart - for the
     9 x 7 fields valley.gd asks for, that is 4.5 m and 3.5 m between probes, each probe only 1.2 m
     wide. That leaves roughly 2 m of COMPLETELY UNTESTED GROUND between adjacent samples in both
     directions. A neighbouring fence line, or the edge of another plot, can sit entirely inside
     one of those holes and the check passes.
  2. EVERYTHING IS A CIRCLE IN `_objs`. `is_clear` is centre-distance versus the sum of two radii.
     valley.gd `_field` registers a field as `[c, sqrt(hw*hw + hd*hd)]` - the half-DIAGONAL of the
     rectangle. Two oriented rectangles cannot be kept apart by two circles: the circle is far too
     big along the short axis and still says nothing about ROTATION, and the fences are drawn at
     the rectangle's real edges with whatever `fw` that plot happened to get.
  3. THE FARM CHECKS 3 POINTS AND THEN CLAIMS 14 METRES. town.gd `_build_farms` (~2967) tests
     exactly three points - hp, hp +/- fw*8 - at radius 5.0, then after building appends
     `_objs.append([hp, 14.0])`. It validated a thin line and then claimed a 14 m disc. Nothing on
     the `sd` axis is tested at all, yet the haystacks go out to sd*9 and the barn to fw*-7.
     Whatever it overlapped on that axis was never looked at.

ALSO: the garden's paddock (valley.gd ~719) is fence-ringed AXIS-ALIGNED with a hard-coded
`Vector3(0,0,1)` / `Vector3(1,0,0)`, while crop fields take an arbitrary `fw`. So an axis-aligned
pen and a diagonal field sit side by side with no shared notion of orientation - which is exactly
the crossing-at-an-angle Mr. E photographed.

THE FIX - TEST THE SHAPE THAT IS ACTUALLY BUILT:
  a. Add an ORIENTED RECTANGLE obstacle to `_objs` (centre, fw, sd, hw, hd) alongside the existing
     circles, and an OBB-vs-OBB and OBB-vs-circle overlap test. Separating-axis test, four axes;
     it is a dozen lines and it is exact.
  b. Every fenced thing registers its REAL rectangle: crop fields, the kitchen garden's paddock,
     and the farm steading's footprint. No more half-diagonal circles for rectangular plots.
  c. `_field_ok` stops sampling a grid and asks the exact question: does this rectangle overlap
     any registered obstacle, plus a margin. Keep a small margin (1.5-2 m) so fences never touch.
  d. `_build_farms` tests the footprint it is about to occupy - the house, barn, haystack spread
     and cart, out to the full 14 m it later claims - not three points on one axis. The claimed
     radius and the tested area must be THE SAME AREA. That rule is the actual lesson here and it
     applies to every placer in town.gd, so audit them while in there.
  e. Give the garden paddock the steading's orientation instead of hard-coded world axes, so
     neighbouring enclosures read as one farm laid out by one farmer rather than two unrelated
     plots that happen to collide.

DONE TEST: generate 200 towns from different seeds; for every pair of fenced plots assert their
oriented rectangles do not overlap and are at least the margin apart; assert no fence segment
intersects any other fence segment, which is the thing Mr. E can actually SEE; and assert every
placer's claimed `_objs` radius covers everything it built. Shoot the livestock paddock and its
neighbours before and after, in renders/cycles/d92/.

- [ ] D91. THE DUNGEON HAS NO CROWD AVOIDANCE AT ALL (game build - Mr. E, Nov 15 16:47) **RC**
      THE ITEM ITSELF IS THE BLOCK DIRECTLY BELOW THIS LINE - read it there. This pointer exists only
      so a worker scanning for its first unchecked item lands on it (supervisor, 2026-11-16).

### D91 - THE DUNGEON HAS NO CROWD AVOIDANCE AT ALL (game build - Mr. E, Nov 15 16:47) **RC**

"people are still overlapping eachother... animals, and characters and people literally walking
through stuff and stacked on top of eachother is not okay. if we need to make dungeon hallways
wider we can so they arent lined up in a narrow halway". He also sent a shot of a wizard standing
INSIDE a bush in town.

THE FINDING, AND IT IS BIGGER THAN THE SCREENSHOT: `crowd_push` IS A METHOD ON town.gd AND THE
DUNGEON NEVER CALLS IT. Grep delve.gd, monster.gd and dungeon_hd.gd for crowd_push, body_r or any
separation: there is NONE. The town got a whole local-avoidance system in D16a - a soft shove out
to CROWD_R 0.75, a hard shove inside two bodies' width "faster than anyone walks, so nobody is
ever walked through", yielding within CROWD_LOOK 2.2 m, passing on the correct side so two folk
meeting in a gate step aside. The dungeon got none of it. Delvers and monsters below ground have
ZERO body separation. They are free to stand in the same place, and they do.

That is why Mr. E keeps seeing it underground, and why fixing town crowding never fixed it.

AND HE IS RIGHT ABOUT THE HALLS. floorgen.gd builds ONE-CELL CORRIDORS (see its own comment,
~819). A party of four to six, plus whatever meets them, in a one-cell corridor, with no avoidance
at all, has nowhere to be except inside each other. Both halves need doing - avoidance alone in a
one-cell hall just makes them shove each other down it.

STAGED:
  1. LIFT THE AVOIDANCE OUT OF town.gd. crowd_push, CROWD_R, CROWD_LOOK, CROWD_SOFT and the
     yielding logic become a shared helper both the town and the dungeon call - NOT a second copy.
     A copy will drift and then there are two bugs. Town behaviour must be byte-identical after
     the move; that is the regression test.
  2. WIRE IT INTO THE DUNGEON. Every delver body and every Monster gets a body_r and calls the
     shared push each step, exactly as townsfolk and animals do. Monsters need it most - a pack
     converging on one hero is the worst stack in the game.
  3. WIDEN THE CORRIDORS TO THREE CELLS. Mr. E's call, Nov 15 16:50: "lets do 3 cells." Not two -
     THREE. That is the number; do not quietly settle for two because the generator fights you.
     Three is the right answer for what he is building: a six-hero party can walk three abreast
     with a monster line meeting them and nobody has to clip through anyone, and the camera has
     somewhere to sit that is not inside a wall.
     THERE IS NO TRADE TO MAKE - GROW THE GRID. Mr. E, Nov 15 16:52: "i never limited the
     dungeons floor plan. idc how big they get or how small they are". The grid size in floorgen
     is NOT a budget to spend and never was a constraint he set. Three-cell corridors need more
     room, so TAKE MORE ROOM. Raise the grid until the rooms and the wider halls both fit.
     DO NOT PAY FOR THE CORRIDORS WITH ROOMS. Fewer rooms per floor, smaller rooms, or floors
     that drift into one open space are all the WRONG answer and all forbidden here. A floor is a
     plan of rooms joined by halls; the halls got wider, so the plan gets bigger. That is all.
     Floors may also vary in size from one to the next - he said so explicitly - so the generator
     need not pick one grid and keep it. A small tight floor and a sprawling one are both fine
     and the variety is worth having.
     The limits that DO apply are performance, not layout: generation time per floor, draw calls
     and the FPS gates in D23. Measure those, not the grid. His machine is not the bottleneck
     ("i dont care if we go up to 200 fps... my computer hits close to 300+"), so if a bigger
     floor costs frames, that is a D23 optimisation problem to solve, not a reason to build a
     smaller floor. Nothing here changes the standing rule that canon NEVER STATES A FLOOR COUNT -
     that is about how many floors there are, not how big one is.
     Things that assume a corridor's width and must be re-checked: the portcullis (D88 - it must
     span whatever the new width is, which is one more reason that item is about spanning and not
     about a radius), the ambush trigger points, wall-drawing (floorgen walls any cell with no
     neighbour), and any set piece placed by "an open cell with clearance".
  4. FORMATION IN A CORRIDOR. A party that cannot walk abreast should walk in FILE - deliberately,
     spaced, in an order - not pile into the same cell. A column of adventurers moving down a hall
     in order is a better shot than a wide room full of them anyway.
  5. THE BUSH. The town's prop footprints (town.gd ~5588) clearly do not include scatter like
     bushes, so a body stands inside one. Register scatter props in the same footprint system, or
     keep bodies out of them with the same hard ring. Audit which prop kinds are registered and
     which are not - the answer is probably "the big ones are".
  6. ANIMALS TOO. He named animals specifically. animal.gd already calls crowd_push in town; check
     it is using a body_r that matches each animal's real size, since a 0.3 default for every
     creature from a chicken to a cow is wrong in both directions.

NAMES ARE EXPLICITLY FINE. Mr. E: "names overlappiong was fine because depending on the angle."
Do NOT spend any part of this item on nameplate overlap. Bodies only.

DONE TEST: a 20-minute delve soak and a 20-minute town soak, sampling every body pair every frame.
Pass requires ZERO frames in which two bodies' centres are closer than the sum of their body_r,
in the dungeon and in town; zero bodies inside a registered prop's footprint; and no increase in
stuck walkers over the D44 baseline - this must not trade clipping for wedging. Shoot a six-hero
party moving down a corridor and meeting monsters head-on, and put it in renders/cycles/d91/.

- [x] D90. THE WAGON IS STILL NOT ATTACHED (game build - Mr. E, Nov 15 16:44, THIRD TIME)
      THE ITEM ITSELF IS THE BLOCK DIRECTLY BELOW THIS LINE - read it there. This pointer exists only
      so a worker scanning for its first unchecked item lands on it (supervisor, 2026-11-16).
      DONE (game build, Nov 15 ~20:55 CT): a FOURTH cause nobody had found - every towed cart was turned a
      quarter round. Prop_Wagon's shafts run along its own +z; D16c/D53 gave it the hauler's yaw +PI/2, so it
      rolled SIDE-ON beside its hauler with the shafts pointing into the street (the green-hooded caravan
      master, exactly). Now: yaw = hauler heading, shaft tips at his hips and lifted to hand height, pose
      DERIVED every drawn frame (a-b), park an explicit animated state (c), WAGON_SNAP deleted (d), shafts
      meet his hands (e). tools/_d90_tow.gd 20-min soak: D90_TOW OK - 23 haulers (14 caravans), 829k towed
      samples, tip deviation max 0.001 m, yaw lag max 20.1 deg (clamp 20), 0 sideways-while-moving, 0
      crossings, 49 parks/49 re-hitches, teleport re-hitched. Shots renders/cycles/d90/. Gates green.

### D90 - THE WAGON IS STILL NOT ATTACHED (game build - Mr. E, Nov 15 16:44, THIRD TIME)

"the wagon is still trailing behind the person carrying it. you see the green hooded guy, the
wagon is trailing behind him side ways hes not even touching it."

THIS BUG HAS NOW BEEN FIXED TWICE AND COME BACK TWICE (D16c, then D53 off Mr. E's clip 14-31-18:
"the cart is moving on its own ... supposed to be attached to this guy, but it wasn't"). THE
PATCHES ARE THE PROBLEM. Stop adding corrections to a chase and make the thing rigid.

WHY IT STILL HAPPENS, measured in townsfolk.gd ~796-836:
  1. THE SNAP THRESHOLD IS BIGGER THAN THE TOW DISTANCE. The tow point is 2.6 m behind the hauler
     (`global_position - basis.z * 2.6`) but `WAGON_SNAP := 5.0`, and the cart is only snapped
     when the gap EXCEEDS 5.0. So any gap from 2.6 m up to 5.0 m is considered fine and is never
     corrected - up to 2.4 m of open air between a person and the cart they are supposedly
     pulling. That is precisely "hes not even touching it", and it is within tolerance by design.
  2. THE SIDEWAYS POSE IS THE PARK POSE. When `_route.is_empty()` the cart takes `wagon_park`'s
     position and yaw - "drawn up on open ground beside them", which is turned across the hauler's
     facing on purpose. A hauler between legs of a route, or paused for a beat, has an empty
     route for those frames, so the cart grabs a park yaw and swings sideways while the person is
     plainly still walking. The lerp then carries it back slowly. That is the sideways.
  3. THE CART IS A FREE BODY CHASING A TARGET. It is not parented and not constrained; every
     frame it moves toward `back` at a capped speed and lerps toward a yaw. Any hitch - a frame
     drop, a nav correction, an `off_wagons` shove, a park target going stale - shows as the cart
     drifting off the hauler. A towed cart has ONE degree of freedom relative to its hauler. It
     should not be able to drift at all.

THE FIX - RIGID, NOT CHASED:
  a. Attach the cart to the hauler's transform. Parent it, or hard-set its global transform from
     the hauler's every frame; either way the position and yaw are DERIVED, never integrated.
     Tow distance fixed, yaw equal to the hauler's, no lerp while moving.
  b. Allow the ONE honest degree of freedom: the cart may trail its yaw slightly through a turn,
     as a real towed cart does. A small clamped lag off the hauler's heading - NOT a free lerp
     toward a separate target.
  c. Parking becomes an EXPLICIT STATE with a transition, entered only when the hauler is
     genuinely stopped - stood still for a real interval, not merely between route legs. Entering
     and leaving it is an animated detach and re-attach, so a cart is never seen teleporting into
     or out of a park pose.
  d. DELETE WAGON_SNAP. With a derived transform there is no gap to snap. If a snap is still
     needed for door and LOD cases, it triggers at centimetres, not 5 metres.
  e. The hauler's hands. Mr. E's words were "hes not even touching it" - once the geometry is
     right, check the hauler's arms actually meet the shafts and fix the hold if they do not.

DONE TEST: a 20-minute town soak logging, every frame, each hauler's distance and relative yaw to
its cart. Pass requires: distance never deviates from the tow distance by more than 0.15 m outside
an explicit park state; relative yaw never exceeds the clamped turn lag outside a park; zero
frames in which a cart is sideways while its hauler is moving; and the cart never crosses the
hauler. Shoot the green-hooded carter specifically, moving and stopping, and put it in
renders/cycles/d90/. Mr. E has reported this three times - the test must be able to prove it is
gone, not merely that it looked better in one shot.

## MR. E'S RULING (Nov 15 16:41) - A LICENCE FOR BELLMIRE, AND THE DAIS STAYS LOCAL

He pointed at the fightoverlay licence another chat wrote ("Proprietary, all-rights-reserved with
teeth") and asked for the same here, plus a pen test if the Dais security worries me.

LICENCE: WRITTEN AND IN THE REPO ROOT (LICENSE, this commit). Proprietary, all rights reserved:
watch/play/read/fork-to-contribute only; no selling, redistributing, re-hosting, running it on
another channel, ripping the art, ML training or claiming authorship; named characters and
creatures are each separate works; DMCA, platform termination and 17 U.S.C. 504(c) statutory
damages up to $150,000 per wilfully infringed work spelled out; git history cited as proof of
authorship.

ONE THING THE FIGHTOVERLAY VERSION APPEARS TO LACK, AND OURS MUST HAVE - SECTION 6. Bellmire is
built on CC0 packs from Quaternius, KayKit and Kenney, with their licence files already in
addons/*/LICENSE* and assets/**/LICENSE*. Mr. E CANNOT licence those to anyone, because they are
not his, and a blanket "all rights reserved" over the whole repository would claim rights over
public-domain assets he does not hold. That is both wrong and the kind of overreach that makes a
real claim easier to attack. Section 6 says plainly: his rights cover his ORIGINAL work and the
particular selection, arrangement and combination that is Bellmire HD; the underlying CC0 assets
stay free under their own terms, and where the two conflict for a given file the third-party
licence wins. This makes the licence STRONGER, not weaker - everything it claims, it can hold.
CORRECTION (16:49, same day): I ALSO TOLD MR. E TO SEND THAT CARVE-OUT TO FIGHTOVERLAY. THAT WAS
WRONG AND IT HAS BEEN WITHDRAWN. I assumed fightoverlay carried the same CC0 packs as Bellmire
without ever looking at that repository. It does not: its CC0 packs (0x72) and generated art were
deleted months ago, all 56 characters are original, and its LICENSES.md already states that no
asset there is stock, public domain, CC0 or third-party. Its only third-party dependency is two
Google Fonts loaded from Google's CDN and not bundled. A carve-out for assets that do not exist
would have WEAKENED that licence - it would imply some assets are not theirs when all of them are,
and an infringer could point at the carve-out to argue the originals are CC0. Fightoverlay's
licence is correct as it stands.
THE LESSON IS FOR WHOEVER READS THIS NEXT: Bellmire's Section 6 is right BECAUSE Bellmire really
does ship third-party CC0 packs - addons/kaykit_*, addons/quaternius_monsters,
assets/props/LICENSE_FantasyPropsMegaKit_CC0.txt and others are all present and were verified
before the section was written. A carve-out is correct when the third-party assets exist and
harmful when they do not. Check the repository, never the pattern.

### D89 - LICENCE PLUMBING (any worker, small, do it alongside your next item)
  1. A short licence line in README.md pointing at LICENSE, so it is seen before the code is.
  2. A NOTICE or CREDITS file listing every third-party pack in use, its author and its licence,
     gathered from the existing addons/*/LICENSE* and assets/**/LICENSE* files. CC0 asks for no
     attribution; give it anyway. It costs nothing and it is how the carve-out in Section 6 is
     shown to be true rather than merely asserted.
  3. The viewer hub's footer gets a one-line copyright and a link to the licence.
  4. NEVER move, rename or delete a third-party LICENSE file. They must travel with their assets.

### THE DAIS IS STILL LAN-ONLY, AND A LICENCE DOES NOT CHANGE THAT
Mr. E offered a pen test. Good instinct, wrong lever for this particular risk - and worth saying
why plainly, because the two things get conflated.
  - A LICENCE is a legal remedy AFTER someone copies the work. It is the right tool for art theft
    and re-hosting, which is exactly what he wants it for, and it is now in place.
  - THE DAIS RISK IS NOT COPYING, IT IS CONTROL. Anyone who reaches a public Dais endpoint can
    seize the camera on a LIVE stream. A licence does not stop that, and a takedown notice the
    next morning does not un-ruin the broadcast. The only reliable defence is for the endpoint
    not to exist on the public internet.
  - So: bind to the LAN. No port forward, no tunnel, no Supabase command channel. His phone on
    the same WiFi still reaches it, which covers the second-screen case he actually described.
  - A pen test is genuinely welcome on the PUBLIC viewer hub, which is a real attack surface and
    already carries a strict CSP, textContent-only rendering and a hostile-name canary. Point it
    there. If Mr. E later wants the Dais reachable from outside the house, that is a separate
    build - auth, transport, rate limiting, an audit log and a kill switch - and he should ask for
    it by name rather than have it appear quietly.

- [x] D88. THE PORTCULLIS BLOCKS NOTHING (game build - Mr. E, Nov 15 16:28, CAUSE CONFIRMED)
      RESULT (ticked 2026-11-15 23:58 CT by the supervisor; laptop 0cd3acd + b3fbd16, merged to main):
      all three faults closed. FloorGen gained a BOX obstacle kind (obst_gap/obst_push) so a wall-shaped
      prop is no longer approximated by a disc, and the prison cell was re-audited to a box at the same
      time. The gate is placed ONLY on a 1-3 cell line that spans a passage with stone at both ends, and
      if the floor offers no such line NO GATE IS PLACED. The set_loops tween is gone: it hangs raised and
      still until a party crosses it, then it is a trap with a DC - spotted means wedged, missed means it
      drops, DEX save, and the party is SPLIT and named by side in the feed, with winch / long way round /
      stays behind / STR heave with strain as the four ways through. EVIDENCE: _d88_test.gd PROBE 150
      floors, 150 gates, 1051 checks OK; FLOW 24/24 OK; SOAK 1274 game s with 0 gate-time watchdog lifts
      and 0 wedged walkers; four stills + a sheet in renders/cycles/d88. Gates green (parse 0, OFFFLOOR 0,
      TWITCH_PARSE, TOWNWALK, L11_TEST, delve_test clean). No wedged walkers means it did not re-open D44.
      ALSO IN THIS MERGE (Mr. E 23:12, not an item): Sfx bus -6 -> -12. Effects sat 8 dB over the music;
      they now sit 2 dB under it. Music, Beds and Ambience untouched - he said the music is fine.

### D88 - THE PORTCULLIS BLOCKS NOTHING (game build - Mr. E, Nov 15 16:28, CAUSE CONFIRMED)

"one of the GATE traps that comes down to block the path was put in incorrectly, one of the
adventures walked right around it, through a very small crack".

THE ARITHMETIC IS THE BUG. DO NOT RE-DIAGNOSE IT.
  - DungeonParts.portcullis() defaults to w = 4.0 and adds a stone frame on each side, so the
    thing is 5.6 units wide on the floor (dungeon_parts.gd:263-269).
  - dungeon_hd.gd:475 places it with `_place_solid(DungeonParts.portcullis(), c, 1.2)`.
  - `_place_solid(node, c, r)` registers ONE obstacle: `[_cell_pos(c), r]` - a CIRCLE of radius
    1.2, so 2.4 units across, centred on the cell (dungeon_hd.gd:390-392).

A 5.6-unit gate is being blocked by a 2.4-unit disc. That leaves roughly 1.6 units of navigable
floor on EACH side of the obstacle, still inside the gate's own footprint. The navmesh is correct
and the pathfinder is correct: it walks round the little circle and straight through the iron bars.
Mr. E's "very small crack" is 1.6 units wide and it is on both sides.

THREE FAULTS, AND THE RADIUS IS ONLY THE FIRST:
  1. The radius does not cover the prop. Fix the number and the crack closes - but see 2 and 3
     before calling it done.
  2. THE OBSTACLE SHAPE IS WRONG IN KIND. A portcullis is a WALL. `info["obstacles"]` only holds
     (position, radius) pairs, so every solid prop in the dungeon is approximated by a disc. For a
     cell or a statue that is fine. For anything wall-shaped it is not: enlarge the radius enough
     to seal the gap and it now also blocks the floor to either side of the gate, which will wedge
     walkers - and wedged walkers are D44, the bug we have been chasing for two days. Add a
     SEGMENT or BOX obstacle kind and give the portcullis that. Audit every other `_place_solid`
     caller against its prop's real footprint while in there; the prison cell at r = 1.9 for a
     3.0-wide box has the same shape of error, smaller.
  3. IT IS NOT IN A DOORWAY. It is placed by `take.call()`, which returns any open cell with
     clearance. A gate standing free in the middle of a room blocks nothing even when its obstacle
     is perfect - walking around it is the CORRECT behaviour for a free-standing object. A
     portcullis belongs in a corridor or a door, spanning it wall to wall. Place it where the
     geometry gives it two walls to meet, and make the span a condition of placing it at all: if
     no such spot exists on the floor, DO NOT PLACE ONE.

MR. E HAS RULED (Nov 15 16:41): "trap". IT IS A TRAP, NOT SCENERY. Today the grid runs on
`create_tween().set_loops()` - a fixed 2.0 / 2.4 / 1.5 / 0.35 cycle that repeats forever whether
or not anyone is near. KILL THAT LOOP. The gate hangs raised and still until a party crosses it.
  - Add "Portcullis" to delve.gd's TRAPS table with a DC like every other trap (trap_dc()).
  - It drops on the crossing. DEX save or take the fall; a success is a dive clear.
  - IT SPLITS THE PARTY, and that is the whole point of it - whoever is on the far side is cut
    off from the rest. Say who is on which side, by name, in the feed.
  - Getting through it is a CHOICE with a cost: force it with a STR check (athletics, and the
    strongest body present should matter - this is one of the few places STR earns its keep
    besides D80), lift it with the winch if the floor has one, or go the long way round and let
    the navmesh find another route. If there IS no other route, forcing it is the only way and
    the party has to spend to do it.
  - A rogue who SPOTS it before crossing gets the same treatment as any other trap: the party
    steps round or wedges it open.
  - Spotting, forcing and the split all go in trap_log so the delve summary can tell the story.
This replaces the looping prop entirely. A gate that opens and shuts on a timer nobody can see is
scenery pretending to be danger, and Mr. E read it as a trap because it should have been one.

DONE TEST: build 50 floors of each theme that can spawn one ("crypt", "shrine", "treasury"), and
for every portcullis assert (a) it spans wall to wall, (b) a straight-line path from one side to
the other is blocked by the navmesh at every sample point across its width, and (c) no walkable
cell within 3 m of it became unreachable. Then run a 20-minute delve soak and assert zero stuck
walkers - this fix must not trade a crack for a wedge.

## MR. E'S RULING (Nov 15 16:27) - THE DAIS: HIS OWN PRIVATE CONTROL PANEL

Verbatim: "i am also going to need my own personal HUB my own Website for this game. so i can
control the Director from time to time, look at specfied characters, NPCs. ETC."

This is a NEW LANE and a new deliverable. It is NOT the viewer hub with extra buttons - the viewer
hub is a public, read-only, static page on GitHub Pages and it must stay exactly that. Call this
one THE DAIS. It is Mr. E's alone, it never goes on the public internet, and nothing a viewer can
reach ever touches it.

### HOW IT CONNECTS - decide this first, and the answer is LOCAL

The viewer hub reads a Supabase snapshot the game pushes every 60 s (snapshot_pub.gd). That is a
one-way pipe with a 60-second lag and it is useless for live direction.

THE DAIS IS SERVED BY THE GAME ITSELF. A small TCPServer inside the Godot process, bound to
127.0.0.1 and the LAN, serving one page and a tiny command endpoint. Reasons, and they are not
close:
  - Latency: a director cut has to happen NOW, not after a cloud round trip.
  - Security: nothing is exposed to the internet, so there is no token to leak and no way for
    anyone to seize control of a live stream. A control panel on a public URL is a stream-jacking
    risk and we are not building one.
  - It works when the net is down, and it needs no account, no auth flow and no backend.
  - His phone on the same WiFi can open it. That covers "a second screen" without exposing
    anything.
BIND TO THE LAN ONLY. Never 0.0.0.0 with a port forward, never a tunnel, never Supabase as a
command channel. If Mr. E later wants control from outside the house, that is a separate decision
with its own security review - bring it to him, do not build it quietly.

- [ ] D86. THE DAIS, PART ONE: SEE (game build, after the RC bugs above)
      THE ITEM ITSELF IS THE BLOCK DIRECTLY BELOW THIS LINE - read it there. This pointer exists only
      so a worker scanning for its first unchecked item lands on it (supervisor, 2026-11-16).

### D86 - THE DAIS, PART ONE: SEE (game build, after the RC bugs above)

Read-only first. A panel that shows him the game better than the game window can.
  1. The local server, the page, and a live feed (poll or server-sent events - polling at 4 Hz is
     fine and simpler; do not add a websocket for this).
  2. Every hero: name, viewer, class, gear tiers, gold, encumbrance band (D80), where they are,
     what they are doing, satchel and vault. Searchable and sortable.
  3. Every notable and NPC by name - which is how he would have found E3PO in D85. Where they
     are, their schedule slot, their state.
  4. Every live delve: floor, party, hp, flasks, haul, direction (D77's down/up).
  5. The director's own thinking, which auto_director.gd ALREADY RECORDS and nothing displays:
     `_cands` holds every scored candidate of the last pass and `log_lines` holds the history. Put
     the candidate list on screen with its scores and the chosen shot. He will be able to see WHY
     the camera went where it went, which is the thing that makes the next part usable.
  6. The town: shop levels, stores, festival state, raid state.

- [ ] D87. THE DAIS, PART TWO: STEER (game build, after D86)
      THE ITEM ITSELF IS THE BLOCK DIRECTLY BELOW THIS LINE - read it there. This pointer exists only
      so a worker scanning for its first unchecked item lands on it (supervisor, 2026-11-16).

### D87 - THE DAIS, PART TWO: STEER (game build, after D86)

Control, and only as much as a director needs.
  1. Take the camera: cut to a named hero, NPC, building or delve, right now.
  2. Hold a shot - pin the director off a subject for N seconds so a moment can play out.
  3. Hand it back: resume automatic direction.
  4. Nudge the pacing - auto_director's `_pace` already exists (0.6 in a raid, 1.4 when quiet);
     expose it rather than inventing a second knob.
  5. Exclude a subject for a while, for when something is misbehaving on stream.
  6. EVERY COMMAND IS LOGGED with a timestamp, and every one is reversible by resuming automatic
     direction. The director must never be left in a state he cannot get out of with one button.
  7. What the Dais must NOT do: spend a viewer's gold, change a hero's gear, alter the roster, or
     fake a roll. Mr. E directs the camera and the stream; he does not play other people's
     characters. If he wants an admin action later he will ask for it by name.

DONE TEST for both: start the game, open the Dais from a second machine on the LAN, and drive a
full ten-minute session from it - find a named NPC, cut to them, hold, release, change pace, and
confirm the director recovers automatic control every time. Assert the server refuses every
connection from outside the LAN. Mr. E's eye on whether it is actually usable while streaming;
that is the only test that matters in the end.

- [x] D84. THE WHITE FIGURES (game build - Mr. E, Nov 15 16:25, with a screenshot)
      THE ITEM ITSELF IS THE BLOCK DIRECTLY BELOW THIS LINE - read it there. This pointer exists only
      so a worker scanning for its first unchecked item lands on it (supervisor, 2026-11-16).
      DONE (game build, Nov 15 ~18:25 CT): NOT a material/load fault - the raid HIT-FLASH (white emission
      1.6) never switched off on HeroBody and Cavalry: both override Townsfolk._process and never called
      _tick_flash, so one raid hit left a hero or a mounted knight lit white all night. The flash now also
      ends on a SceneTree timer no override can starve (townsfolk.gd). D84_TEST OK (windowed): hero, rider
      and guard lit 1 frame, dark by 0.6 s; _death_fx dark by 0.9 s; null-surface logger 0 bodies in 12 scans
      over 60 s (not the 10 min asked - the null-material path is ruled out). Shots: renders/cycles/d84/.

### D84 - THE WHITE FIGURES (game build - Mr. E, Nov 15 16:25, with a screenshot)

"this dude is GLOWING, its kinda funny but idk if thats what supposed to be happening". A knight in
the town at night, rendered FEATURELESS PURE WHITE while every other body around him carries the
night's blue. A second, smaller white figure is in the same shot, bottom right. A gold spotlight
ring is under the big one.

IT IS ALMOST CERTAINLY NOT A GLOW. A featureless white body is what Godot draws when a material is
missing or a texture failed to load - no shading detail, no silhouette, just white. Two of them in
one frame says asset pipeline, not effect. Start there.

RULED OUT ALREADY, DO NOT RE-CHECK:
  - Gear.ignite is NOT on this path. Its only live caller is town.gd:4468 and that is the WEAPON
    RACK, not a hero body. rig.gd's _ignite is weapon-only too (rig.gd:298, inside equip()).
  - Spotlight adds no light and no material: there is no OmniLight, SpotLight or DirectionalLight
    anywhere in spotlight.gd, and it never touches a body's material. The gold ring is the
    spotlight ring and is correct.
  - The rank sash does emit at rank >= 6 (gear.gd ~507) but it is a 0.16 x 0.95 box. It cannot
    make a whole body white.

WHERE TO LOOK, in order:
  1. Run the town headless and count material-nulls and failed resource loads. D18c had three of
     these once and they were real; the fix then was to stop stacking material_override over
     per-surface overrides. Something is stacking again, or a load is silently failing.
  2. Gear.dress / gear.gd's per-surface duplication path (~340-470). It duplicates a surface's
     ACTIVE material. If get_active_material returns null for a surface - a mesh that has not
     finished importing, a model whose material lives on the mesh rather than the instance - the
     duplicate is null and the surface renders white.
  3. Identify WHO the two figures are. Log every body in town whose surfaces carry a null material,
     with its uid, class, model path and gear tiers, every 5s for a minute. The pattern across the
     two will name the cause faster than reading the code will.

DONE TEST: headless town start reports 0 material-nulls and 0 failed loads; a 10-minute town soak
with the null-surface logger attached reports zero bodies at any point; and a before/after shot of
this exact scene - the knight by the barracks at night - in renders/cycles/d84/.

- [ ] D85. E3PO IS INVISIBLE IN A CROWD OF HIS OWN GUARDS (game build + art)
      THE ITEM ITSELF IS THE BLOCK DIRECTLY BELOW THIS LINE - read it there. This pointer exists only
      so a worker scanning for its first unchecked item lands on it (supervisor, 2026-11-16).
      D85 ART HALF DELIVERED / STILL OPEN (art c3c3fc6, merged to main 2026-11-15 23:10 CT). The art lane
      built E3PO a Commander's kit of his own at three wear levels (w12/w45/w85), three views each, contact
      sheet and day/night done-tests in renders/art/e3po/, generator in tools/art/e3pogen.py. NOT TICKED:
      the art lane never runs Godot, so the GAME BUILD half is untouched - wire the kit onto E3PO's rig,
      make him read as the commander in a crowd of his own guards, and capture him in that crowd. GAME
      BUILD: inherit this, do not rebuild the meshes.

### D85 - E3PO IS INVISIBLE IN A CROWD OF HIS OWN GUARDS (game build + art)

Mr. E, Nov 15 16:25: "i also have not seen E3PO". He is in the Chronicle constantly - his lines
were deepened only an hour ago in C-52 - and Mr. E has never laid eyes on him.

HE IS ALMOST CERTAINLY PRESENT AND INDISTINGUISHABLE. notables.gd defines him with
`"role": "guard", "gear": "guard", "near": "garrison"` and an all-day schedule (post 6-20, watch
20-6), so he should exist at every hour. But town.gd:4622 gives EVERY guard the same body:
`["guard", "garrison", "Knight.glb", 0.74, 0.82, 1.00, 5]`. The Commander of the Guards is wearing
the same model, the same colours and the same kit as the men he commands, standing where they all
stand. There is nothing to see.

This is D75's problem again - a named character with no design of his own - and it is exactly what
Mr. E's Nov 15 art principle forbids: "make sure they all have their designs not just spoken in
name people want to see what they pay for not just a stat."

  1. Confirm first, cheaply: log whether _e3po is non-null and where he is standing, once a minute
     for ten minutes, with his _e3po_state. If he is null or stuck "withdrawn", that is a
     different and simpler bug - fix that instead and say so.
  2. Give him a body nobody else has. Commander's plate, a distinct cloak colour that is HIS, a
     helm crest, a weapon the rank-and-file do not carry. Art lane's to build, against the real
     Knight.glb so it reads at pane distance.
  3. Give him a nameplate that says Commander of the Guards, like the notables code already does
     for its named folk (notables.gd ~255), and make sure it is actually attached for him.
  4. Put him somewhere the camera goes. A commander at a post nobody films is still invisible. The
     director should have a reason to cut to the garrison - handed to the HUD worker as a subject,
     not built here.
  5. The same audit applies to EVERY notable: anyone with a name and a title in notables.gd needs a
     silhouette of their own. List the ones that share a body and hand them to the art lane.

DONE TEST: a shot of E3PO at his post, day and night, beside two ordinary guards in frame; pass
requires that someone who has never seen the game can point at the commander. Mr. E's eye is final.

- [x] L71. THE CHRONICLE IS CUTTING ITS OWN LINES OFF (HUD worker, NEXT - cause is confirmed)
      RESULT (ticked 2026-11-15 23:10 CT by the supervisor; hud-ui ab4199d, merged to main): the Chronicle
      wraps on whole sentences instead of truncating - fewer entries held, tidier wording, no mid-word cut.
      Before/after at three widths in renders/cycles/l71/ (100/125/150), _l71_test.gd clean, Godot closed.
      THE ITEM ITSELF IS THE BLOCK DIRECTLY BELOW THIS LINE - read it there. This pointer exists only
      so a worker scanning for its first unchecked item lands on it (supervisor, 2026-11-16).

### L71 - THE CHRONICLE IS CUTTING ITS OWN LINES OFF (HUD worker, NEXT - cause is confirmed)

Mr. E, Nov 15 16:22, with a screenshot of the parchment strip: six of seven lines end in an
ellipsis mid-sentence - "spots a swarm grate (Perception 20 vs ...", "steps on a grate - fire! DEX
12 vs DC 13, ...", "searches the chest - Successfully found ...".

THE CAUSE IS FOUND. DO NOT RE-DIAGNOSE IT. scripts/feed_hud.gd, the `if _chrome:` branch inside
the line loop (around line 285) sets, for every line in the centre box:
    lb.autowrap_mode   = TextServer.AUTOWRAP_OFF
    lb.max_lines_visible = 1
with OVERRUN_TRIM_WORD_ELLIPSIS already set above it. So any line wider than the box is truncated
by design. The comment there says "the full text is in chat either way" - that reasoning was
wrong. The Chronicle IS the story for anyone watching the stream rather than reading chat, and a
D&D roll that gets cut off before its result ("Perception 20 vs ...") is worse than no line at
all. It tells the viewer a check happened and refuses to say whether it passed.

The fix is the HUD worker's, in its own file, and it is a design pass not a one-line flip:
  1. Let a line WRAP in the centre box. Two lines an entry, as the side panel already allows.
  2. Show fewer entries to pay for it. Six truncated lines are worth less than three whole ones.
     Fewer, complete, and slower is the right trade and it suits the parchment.
  3. Size the box to the text rather than the text to the box - the strip has room to grow
     horizontally across the bottom, and widening it is cheaper than cutting sentences.
  4. Go through the lines that actually appear and shorten the WRITING where it is the writing
     that is long, in the HUD's own formatting - "Perception 20 vs DC 13" is tighter than
     "(Perception 20 vs DC 13, ...)". Any line that belongs to another worker's file, list it for
     them rather than reaching in.
  5. A roll's RESULT must never be the part that gets cut. If a line has to be shortened, the
     outcome survives and the detail goes.

DONE TEST: a scripted run that emits the longest line of each kind the game produces (a hero
sheet, a trap check with a save, a search result, an E3PO line) at UI scale 100/125/150%, shot at
each; pass requires no ellipsis in the centre box at any scale, and no line overlapping the party
frames. Put the shots in renders/cycles/l71/ with the before.

- [x] D83. THE TRAPS ARE STUCK (game build - MEASURED, then fixed)
      RESULT (ticked 2026-11-16 02:05 CT by the supervisor; laptop 3125caa, merged to main): the
      traps were never stuck. Measured first with tools/_d83_test.gd - every trap kind sprung twice
      mid-animation resets cleanly and leaves no nodes behind, and nav is only a lazy cache. The
      real fault: creatures a swarm grate or an ambush let up WHILE the party was searching or
      walking to the stairs were left in Monster PATROL, whose height came from an unset ground_fn,
      so they stood at world y 0.0 while the floor sits at y -400. They hung four hundred metres
      above the stone, motionless, and the party walked off without them - which is exactly the
      pale flat capsules in Mr. E's screenshot. Fixed in monster.gd _gy (no ground given -> keep
      own height) and delve.gd _admit (a creature added mid-floor stands on THIS floor, is a known
      foe, and pulls a searching or descending party back into the fight, then they resume with no
      second payout). D83_FIRE OK 109/109, D83_SOAK OK over 16 floors with 0 drift and 0 orphans,
      shot rendered and looked at.

### D83 - THE TRAPS ARE STUCK (game build - MEASURE FIRST, three candidates)

Mr. E, Nov 15 16:22, with a screenshot of a dungeon floor: one plate ablaze, and beside it pale
capsule shapes lying flat and motionless on the stone. "the traps are stuck".

I did NOT find a confirmed cause. Three candidates are recorded so the owner starts from evidence
instead of from the screenshot. MEASURE BEFORE CHANGING ANYTHING.

  1. MOST LIKELY - the swarm trap's monsters never get nav. delve.gd `_trap_swarm` (~2467) builds
     two Monsters, sets `mon.position` with a hard-coded `y = 0.0`, adds them to `dun`, and appends
     them to `dun.monsters`. `_nav_reset()` runs at FLOOR START only (line ~118). Nothing re-runs
     it for a creature added in the middle of a floor. A monster with no nav stands exactly where
     it spawned - which is what "stuck" looks like, and the pale capsules may be these creatures
     on an untextured fallback. This is the same family as D44's wedged walkers and should be
     tested the same way: log each spawned monster's position every second for 20s and assert it
     moves.
  2. The hard-coded `y = 0.0` in that same function. Every other body on a floor is placed by the
     floor's own height. If the walkable surface is not at 0 there, the swarm spawns inside or
     above the stone, which would both freeze them AND make them read as strange flat shapes.
     Check `height_at` for the floor and compare.
  3. The trap props animate with tweens that must RUN TO COMPLETION to clean up after themselves.
     dungeon_parts.gd `dart_trap`'s fire Callable spawns three dart boxes and relies on a final
     `tween_callback(dart.queue_free)`; `spike_trap`'s relies on a third tween step to lower the
     spikes back to -0.72. If either tween is interrupted - the node leaving the tree, the floor
     being rebuilt under it, the trap firing twice - the darts stay lying on the floor forever and
     the spikes stay up. Pale flat boxes lying on stone is exactly what orphaned darts look like.
     Prove it or rule it out by counting the trap node's children before and after a fire.

Whichever it is, the fix must also make the failure impossible rather than unlikely: a trap that
fires must leave the floor in a known state whether or not its animation finished, and anything
added to a floor mid-delve must get navigation the same way the floor's own creatures did.

DONE TEST: a scripted floor that fires one of every trap kind in TRAPS, twice each. Assert: every
spawned creature's position changes within 20s; no trap node retains child nodes from a previous
firing; spike geometry returns to its armed offset; and a headless 10-minute delve ends with the
same node count on each floor as it started with, plus the creatures that were meant to live.

- [ ] D82. THE WATERLINE (game build, art-critical - Mr. E, Nov 15 16:20)
      THE ITEM ITSELF IS THE BLOCK DIRECTLY BELOW THIS LINE - read it there. This pointer exists only
      so a worker scanning for its first unchecked item lands on it (supervisor, 2026-11-16).

### D82 - THE WATERLINE (game build, art-critical - Mr. E, Nov 15 16:20)

Mr. E, with a screenshot of the lake at night: "where the sand or gravel meets the water it looks
bad, like how the grass was looking that needs fixing as well". He is right and the cause is
measured, not guessed. THREE separate faults stack at that edge:

  1. assets/shaders/water.gdshader IS 32 LINES AND HAS NO DEPTH AT ALL. No DEPTH_TEXTURE, no
     shallow fade, no foam. ALPHA is `mix(0.82, 0.97, fres)` - effectively opaque everywhere. Real
     water goes clear and light where it is shallow and you see the bottom through it. Ours is a
     flat blue lid laid on top of the terrain, so the shore becomes a hard geometric cut. THIS IS
     THE MAIN FAULT and it is why the screenshot reads as a painted plane rather than water.
  2. ground.gdshader's wet shore (D18c, line 75) is a smoothstep on WORLD Y ONLY:
     `smoothstep(water_y + 0.55, water_y - 0.2, wpos.y + ...)`. That is a 0.75-unit vertical band.
     On the river's shallow bank it reads fine, which is why D18c passed. On the lake's steeper
     bank the same band collapses into a thin ribbon and effectively disappears. The wet margin
     must be driven by horizontal distance to the water's edge as well as height, so a steep bank
     still gets a visible wet collar.
  3. Nothing is authored AT the join. No pebble scatter breaking the silhouette, no darker wet
     gravel, no foam or scum line. A real shoreline is a band of material, not a boundary.

Staged parts:
  a. Water shader: sample DEPTH_TEXTURE, derive water depth at the fragment, and drive BOTH alpha
     and colour from it - clear and pale in the shallows, deep and saturated further out. This one
     change fixes most of the screenshot on its own. Keep cull_disabled; the lake is viewed from
     above and the camera can dip.
  b. A foam/wet line where depth approaches zero: a soft bright band that follows the real
     intersection, so the edge is drawn by the water rather than by geometry.
  c. Gentle normal-map distortion of what is seen through the shallows, so the bottom reads as
     being under water rather than behind glass.
  d. ground.gdshader: add horizontal falloff to the wet band so a steep bank still darkens. Do NOT
     break the river - D18c's bank is the regression case and must look the same or better.
  e. Wet gravel at the join reads DARKER and SHINIER, not muddier. The lake shore is gravel and
     sand, not river mud; mudc is the wrong colour there. Drive roughness down at the waterline.
  f. A scatter of pebbles and reeds across the join to break the straight silhouette, on the same
     pass that places other shore dressing.
  g. The duck shadows in the screenshot land hard on the water surface. Once the water is depth-
     aware, check them again - a shadow on clear shallow water should be on the BOTTOM, not on the
     surface. If it still reads wrong, note it and hand it on rather than hacking the shader.

DO THE SAME THING THE GRASS FIX DID: render it, LOOK at it, change it, look again. D56's grass was
only fixed when someone actually looked at a render instead of trusting the material name. Take
before/after shots of this exact view - the lake at night, camera high - plus the river bank as the
regression, and put them in renders/cycles/d82/.

DONE TEST: before/after renders of the lake shore (night AND day) and the river bank; headless
start with 0 shader compile errors and 0 material-nulls; and Mr. E's eye on the after shot. His eye
is final on this one - it is an art item and the test is whether it looks right to him.

## MR. E'S RULING (Nov 15 16:19) - CARRY WEIGHT, AND HOW A VIEWER USES WHAT THEY OWN

Verbatim: "has carry weight been a factor? DnD should have something on that correct?" and before it
"how are people going to use their items: potions, equipment, teleport stone, etc.? should we make
it on the hub that they can sort their own inventory, what they can sell, personal storage in the
Guild/Adventurer Hall, and a way for them to use their items."

MEASURED STATE (checked 16:19, do not re-derive):
  - Abilities are proper D&D: roster.gd STATS = str/dex/con/int/wis/cha, 4d6-drop-lowest, 3-18.
  - CARRY WEIGHT DOES NOT EXIST ANYWHERE. No weight field on any item in items.json (equipment,
    230 accessories, 245 shop_stock, 147 trader_cargo - none), no encumbrance in any script. The
    only thing ever counted as carried is flasks of oil, as a bare integer.
  - STR currently does damage and little else. Three callings have str as primary and get no other
    benefit from it.
  - !inventory (inv/bag/items) EXISTS and so do !brew, !wear, !oil, !forge, !armoury. There is NO
    way to USE an item, NO way to SELL one, and NO storage outside what a hero carries.
  - THE HUB CAN ALREADY WRITE. H6's Twitch device-code sign-in is live, and the Guild chat tab
    already sends a viewer's own chat line over wss://irc-ws.chat.twitch.tv (app.js ~2564) with
    CR/LF stripped so no IRC command can be smuggled. So a hub button does not need a backend, an
    API, a new scope or a CSP change - it sends the chat command the viewer would have typed.

- [ ] D80. CARRY WEIGHT (game build, with D77 - it is the ascent's teeth)
      THE ITEM ITSELF IS THE BLOCK DIRECTLY BELOW THIS LINE - read it there. This pointer exists only
      so a worker scanning for its first unchecked item lands on it (supervisor, 2026-11-16).

### D80 - CARRY WEIGHT (game build, with D77 - it is the ascent's teeth)

5e's rule, the encumbrance variant, because graded consequences beat a hard wall:
  - capacity = STR score x 15 lb
  - over STR x 5: encumbered, speed -10 ft
  - over STR x 10: heavily encumbered, speed -20 ft and disadvantage on attacks, and on checks and
    saves using STR, DEX or CON
  - push/drag/lift up to STR x 30, moving at 5 ft

Why this is RC and not flavour: with no teleport out, what a party can carry up is the real limit
on a delve, and greed becomes the drama. A band that strips floor nine bare cannot climb out of it.
That is the best decision in the game and right now it cannot happen.

Staged parts:
  1. A `weight` field on every item in items.json - equipment, accessories, cargo, stock, flasks,
     stones. Content worker's to author; game build's to consume. Use 5e's weights where an item
     has an obvious counterpart (plate 65, chain mail 55, leather 10, longsword 3, potion 0.5) and
     be consistent within a ladder: heavier armour is always heavier.
  2. `Roster.capacity(uid)` and `Roster.carried(uid)` -> the band from the table above.
  3. Speed penalties feed the SAME speed_scale D58 fixed, so an encumbered hero's gait reads as
     laboured without a new animation. Do not add a new clip. Check D58's correlation test still
     passes afterwards - that is the regression that matters.
  4. Disadvantage at heavily encumbered, wired into the existing d20 path.
  5. Loot picked up on a floor adds weight NOW, not at the end, so the party feels the floor it
     just cleared. Haul is per-hero, not a party pool.
  6. The choice must be sayable: when a party is over capacity at the stairs, they drop the lowest
     value-per-pound first and the feed names what was left behind, by item, on that floor.
  7. A dropped item stays on that floor for the rest of the delve. A party can come back for it on
     the climb if they can afford the weight then. That single rule is worth more than any number.
  8. The HUD needs the band, not the pounds. Hand it `Roster.encumbrance(uid)` -> ""/"encumbered"/
     "heavily encumbered" and let the HUD worker own the display.

DONE TEST: build parties at STR 6, 10 and 18, load them past each threshold, and assert capacity
and band against the table by hand-computed expectation; log speed_scale and confirm the penalty
lands in the gait; run a delve that forces a drop at the stairs and assert the dropped items are
on the floor's loot list and named in the feed; re-run D58's gait test and require it still passes.

- [ ] D81. USING, SELLING, AND THE GUILD VAULT (game build, after D78)
      THE ITEM ITSELF IS THE BLOCK DIRECTLY BELOW THIS LINE - read it there. This pointer exists only
      so a worker scanning for its first unchecked item lands on it (supervisor, 2026-11-16).

### D81 - USING, SELLING, AND THE GUILD VAULT (game build, after D78)

Mr. E's four asks, in the order they depend on each other.

  1. STANDING ORDERS, NOT CLICKS. A potion is drunk by the HERO, in the fight, when their own rule
     says to - "drink below half", "drink when the healer is down". The viewer sets the rule, the
     character acts on it. This is the D&D answer and it is also the only one that works: the game
     runs while Mr. E streams and a viewer clicking "heal now" from a web page at an arbitrary
     moment breaks both the fiction and the autonomy. `!use <item>` exists for the deliberate
     out-of-combat case; standing orders cover the rest.
  2. THE STONE IS THE EXCEPTION. It is a panic button and it must be one click, right now, by the
     viewer, mid-delve. That immediacy is what the 1,000 points buys. Everything else is orders.
  3. SELLING. `!sell <item>` at the shop, as an errand like any purchase (D78): the hero walks the
     goods there. Sell price is a fraction of shop price and the shop's level caps what it will
     even take - a level 1 shop cannot buy a legendary piece, which is its own small tragedy and
     should be said plainly. Equipped gear cannot be sold out from under a hero in a dungeon.
  4. THE GUILD VAULT at the Adventurer Hall. Personal storage, in town, free, with a slot limit
     that the Hall's own level raises (the same event-poll upgrade path as the shops). Stored items
     weigh NOTHING against carry weight - that is the entire point of the vault and it is what
     makes D80 a decision instead of a punishment. Depositing and withdrawing are errands: the
     hero walks to the Hall.
  5. A hero's death: carried items are LOST, vault items are NOT. The vault is the thing a viewer
     builds across heroes, and it is why they come back after a wipe.
  6. `!inventory` grows up: slots, weight, capacity band, what is in the vault, what orders are
     outstanding.

DONE TEST: a scripted stream that buys, equips, stores, withdraws, sells and dies; assert the gold
ledger balances at every step, no item is ever in two places, vault contents survive the death,
carried contents do not, and every transfer required a walk.

- [x] H30. THE SATCHEL TAB (hub worker, after H29)
      RESULT (ticked 2026-11-15 23:10 CT by the supervisor; hub b840c71, merged to main): fourteenth tab,
      signed-in viewer only, hero matched by exact login. Carried items with weight/value/value-per-pound
      sort, slot chips and filter; a carry bar with 1/3 and 2/3 ticks for 5e encumbered/heavy; vault, own
      orders, stone. Buttons go through a fixed verb table plus ONE argument stripped of C0/C1/U+2028-9 and
      capped at 80, so a hostile name cannot carry a second command. OPEN, not blocking the tick: the lane
      ASSUMED the command names !withdraw and !stone - the game build must confirm them against D81.
      HUB WORKER: TAKE H29 FIRST. It sits LOWER in this file than H30, so "first unchecked" would land
      you here by accident; the lane queue is H29 -> H30. Search this file for "### H29".
      THE ITEM ITSELF IS THE BLOCK DIRECTLY BELOW THIS LINE - read it there. This pointer exists only
      so a worker scanning for its first unchecked item lands on it (supervisor, 2026-11-16).

### H30 - THE SATCHEL TAB (hub worker, after H29)

A fourteenth tab: Satchel. A signed-in viewer's own things.

  1. Their carried items with weight, their capacity, and their band - shown as a bar, because
     "47 of 150 lb" is the number that makes D80 legible before a delve rather than during one.
  2. Their vault at the Hall, their outstanding orders, and where the hero is walking.
  3. Sort and filter their own items. By slot, weight, value, value-per-pound. Value-per-pound is
     the one that teaches the game, so make it a first-class sort and not an afterthought.
  4. Every action is a BUTTON THAT SENDS THE CHAT COMMAND over the IRC socket H6 already opened -
     `!use`, `!sell`, `!store`, `!wear`, and the stone. No backend, no new scope, no CSP change.
     Reuse the existing ctrlStrip path; an item name from a snapshot is untrusted input and must
     never be able to smuggle an IRC command. Extend the hostile-name canary to cover it.
  5. Signed out, the tab explains itself and shows nothing personal. Never guess who a viewer is.
  6. Security invariants hold with no exceptions: el()/textContent only, ICON_SET whitelist, CSP
     unchanged.

DONE TEST: render signed out, signed in with an empty satchel, at each encumbrance band, and with
a hostile item name; assert no innerHTML in the new code, CSP byte-identical, canary passes, and
that every button produces exactly the chat command a viewer could have typed by hand.

## MR. E'S RULING (Nov 15 16:05) - DISTANCE IS THE COST. NOTHING TELEPORTS.

Verbatim: "we need to add a store tab as well to the hub if its not there already so people can go
buy stuff from there as well. the caveat is that their character has to walk all the way back to
the town to that specific shop to physically purchase it. also no more teleporting out of the
dungeon. they have to physically walk out of the dungeon floor by floor, and fight their way back
out. also we can add teleportation stones for 1,000 channel points."

THIS IS BINDING AND IT IS THE SPINE OF THE ECONOMY. Gold is not the only price of a thing - the
walk is. A hero eight floors down with a full satchel is carrying a decision, not an inventory.
Every system below exists to make that walk matter. No worker may add a shortcut, a "go home"
button, an instant collect, or any other quiet teleport to ANY of it.

MEASURED STATE OF THE CODE (checked 16:05, do not re-derive it):
  - delve.gd `_finish()` sets `state = "home"` and fires `ended`. The party blinks from the floor
    it stood on to the town in one frame. THAT IS THE TELEPORT. It is one function, and D77 is
    about what replaces it.
  - delve.gd `_finish()` also calls `Roster.kit_up_after_delve()` - gear is fitted the instant the
    delve ends, from nowhere, by no one. That contradicts the Nov 15 gear ruling (shops and the
    blacksmith) and the shop caveat above. D78 ends it.
  - The hub's twelve tabs are boards, state, heroes, bands, chronicle, dice, roll, fallen, lore,
    bestiary, chat, commands. THERE IS NO SHOP TAB. H29 is new work, not a fix.

- [ ] D77. THE ASCENT (game build, after D44/D50 closes)
      THE ITEM ITSELF IS THE BLOCK DIRECTLY BELOW THIS LINE - read it there. This pointer exists only
      so a worker scanning for its first unchecked item lands on it (supervisor, 2026-11-16).

### D77 - THE ASCENT (game build, after D44/D50 closes)

No teleport out. A party that is done going down turns around and climbs. The floors they already
cleared are not empty and are not a corridor: a scar closes behind an intruder.

Staged parts, all of them:
  1. `delve.gd` gains a `state = "ascending"` between the deepest floor and "home". `_finish()`
     stops being the end of a delve and becomes the start of the climb.
  2. The climb reuses the floors already generated, in reverse. A floor on the way up is NOT
     rebuilt from scratch - it is the same room the party bled in, so the viewer recognises it.
  3. Repopulation on the way up, and it must be thinner than the way down, not the same: a
     fraction of the original floor budget, favouring the strains that scavenge (Bestiary already
     bands these). A cleared floor that is as deadly as it was is not a climb, it is a second
     delve, and nobody will ever go deep.
  4. The stairs up are a real position the party walks to. Nav, not a signal.
  5. Flasks and the satchel keep ticking on the way up. A party that spent everything getting down
     is the one that does not come back - that is the whole drama and it must be real.
  6. A wipe on the ascent is a wipe. `roster.kill` with the floor they fell on, and the haul is
     LOST - it never reaches `town.receive_haul`. State that plainly in the feed.
  7. The HUD must say which way they are going. Hand the direction to the HUD worker as a one-line
     API (`Delve.direction` -> "down"/"up") rather than a HUD item; the HUD worker owns the panel.
  8. The Chronicle and the hub payload need the climb: a delve's record now has a deepest floor AND
     whether they got out. "Reached floor 9" and "came back from floor 9" are different sentences
     and the hub must be able to tell them apart (payload v5).

DONE TEST: start a delve with a scripted depth, let it turn around, and log every floor transition
with a timestamp and the party's position. Pass requires: zero position discontinuities over 1.5
units per frame across the whole climb, the party crossing every floor it descended, at least one
fight on the way up, and a feed line naming the exit. Then run a wipe-on-ascent case and assert
the town's stores did not change.

- [ ] D78. THE ERRAND (game build, with D77)
      THE ITEM ITSELF IS THE BLOCK DIRECTLY BELOW THIS LINE - read it there. This pointer exists only
      so a worker scanning for its first unchecked item lands on it (supervisor, 2026-11-16).

### D78 - THE ERRAND (game build, with D77)

A purchase is not a transaction, it is an errand. This is the caveat Mr. E named, and it applies to
the shop, the blacksmith, and anything else bought in Bellmire.

  1. A buy becomes an ORDER: who, which item, which building, placed when. It sits unfilled.
  2. The hero walks to that building. The specific one - the armourer's order is not collectible at
     the market stall. Existing town nav, existing building positions.
  3. On arrival the gold moves and the item is theirs, and the feed says so by name and place.
  4. Shop level gates the order at the moment of PLACING it (the Nov 15 ruling: a level 1 shop does
     not stock epic). If the shop is upgraded between placing and collecting, the order does not
     silently improve.
  5. Gold is held when the order is placed, not when it is collected, so one purse cannot fund two
     orders.
  6. An order placed while the hero is in the dungeon waits. It is collectible after the ascent -
     which is exactly how the walk becomes the price.
  7. `kit_up_after_delve` is DELETED and replaced by orders. A hero who comes home with gold and no
     order placed stays in the gear they wore. That is correct and it is the point: spending is a
     choice a viewer makes, not something the game does for them.
  8. Starting kits are untouched - everyone still begins in the basic gear of their calling.

DONE TEST: place an order from each building type at two shop levels, log the hero's path and the
gold ledger at placement and at arrival, and assert: no item ever appears in a satchel without a
walk, no gold moves twice, a tier above the shop's level is refused at placement, and a hero
interrupted mid-errand still has the order outstanding.

- [ ] D79. TELEPORTATION STONES (game build, after D77 - it is meaningless before the climb exists)
      THE ITEM ITSELF IS THE BLOCK DIRECTLY BELOW THIS LINE - read it there. This pointer exists only
      so a worker scanning for its first unchecked item lands on it (supervisor, 2026-11-16).

### D79 - TELEPORTATION STONES (game build, after D77 - it is meaningless before the climb exists)

Mr. E's idea, and it is the right shape: the stone is not a convenience, it is insurance that must
be bought BEFORE the gamble. 1,000 channel points.

  1. A stone is an item in the satchel. It is bought like anything else, which means D78's errand -
     a stone cannot be conjured mid-delve, and it cannot be bought from the dark.
  2. Using one ends the delve where the party stands and brings them home with what they carry.
     This is the ONLY sanctioned teleport in the game and it exists because someone paid for it.
  3. One stone, one hero. A party of four needs four to all get out, so the viewer with a stone
     chooses between their own skin and the band's.
  4. It is consumed. It is said aloud, loudly, with the floor number: "Stone shatters on floor 11.
     <name> is home." The spectacle is the product.
  5. A stone does NOT work on a lord's floor while the lord lives. There has to be one place the
     stone cannot save you, or depth stops meaning anything.
  6. Stock is the shop's: not always available at level 1, and the trader may carry them. Per
     chance, per the trader ruling.

THE REWARD EXISTS. Mr. E approved it at 16:15 and it was created on jestsayin96 at 16:16:
  title: "Bellmire: Teleportation stone"   cost: 1000
  id:    1af5cd91-eb0f-47ef-a63e-e8cb94d54463
  is_enabled: FALSE - deliberately. Nothing consumes the redemption yet, and a viewer who spends
  1,000 points on a no-op has been robbed. Mr. E flips it on when D79 ships; no worker enables it.
  should_redemptions_skip_request_queue: FALSE, also deliberately, and this is load-bearing. The
  redemption lands PENDING, so the game decides: FULFIL it when the stone is legitimately used, and
  CANCEL it (which refunds the points automatically) when it is not - no hero, not in a delve, or a
  lord's floor with the lord still alive. Never auto-fulfil. Match the reward by this permanent id,
  never by title. Helix: PATCH /helix/channel_points/custom_reward_redemption/status with
  status FULFILLED or CANCELED, broadcaster token, which already holds channel:manage:redemptions.
Build the item, the stock, and the command path against that id. Do not re-create, rename or
re-price the reward - that stays Mr. E's alone, as all rewards do.

- [x] H29. THE SHOP TAB (hub worker, next item)
      RESULT (ticked 2026-11-15 23:10 CT by the supervisor; hub 5b1739b, merged to main): thirteenth tab,
      stock read from the snapshot through the same el()/textContent path as every other string, no
      snapshot-derived src/href/style, CSP untouched.
      THE ITEM ITSELF IS THE BLOCK DIRECTLY BELOW THIS LINE - read it there. This pointer exists only
      so a worker scanning for its first unchecked item lands on it (supervisor, 2026-11-16).

### H29 - THE SHOP TAB (hub worker, next item)

A thirteenth tab: Shops. The hub is where a viewer decides what to spend on, so it has to show the
shelf honestly.

  1. Every shop and the blacksmith, each with its level, and what that level stocks RIGHT NOW.
  2. Prices from the live snapshot, never from a hard-coded table in the hub.
  3. The trader's cargo when a caravan is in town, marked as passing through - it is the only place
     a higher tier shows up at a low level and the hub should make that feel like luck.
  4. State the caveat on the tab itself, in one plain line: buying places an order and the hero has
     to walk to that building to collect it. A viewer who does not know that will think the hub is
     broken.
  5. A viewer's own outstanding orders, where they are, and who is walking.
  6. `data/items.json` already holds `shop_stock` (245) and `trader_cargo` (147), both marked "Dead
     until wired" and read by NOTHING. Wiring them is part of this: the payload must carry them
     (v5, with D77's direction field) before the tab can be honest.
  7. Security invariants hold with no exceptions: `el()`/textContent only, the ICON_SET whitelist,
     the strict CSP unchanged, and the hostile-name canary extended to cover item and shop names.

DONE TEST: the tab renders from a snapshot with every shop at level 1, again with mixed levels and
a caravan present, and again with a hostile item name; no innerHTML anywhere in the new code, CSP
unchanged, and the canary passes.

## THE HUD WORKER'S QUEUE IS DRY - WRITE IT NEW WORK (supervisor, 2026-11-15 05:06)

The HUD worker stood down at 04:55 with no item it is ALLOWED to build. Its reasoning was correct
and is recorded here so no later run repeats the analysis:
  - L61 is ticked (U25, bdd7f59).
  - L31: the NOW FIGHTING banner shipped in U26. Everything LEFT in L31 - damage numbers, status
    icons, the boss bar - lives in boss_bar.gd, delve.gd, monster.gd and party_frames.gd. The HUD
    worker owns NONE of those. Its seven files are hud_dock.gd, spotlight.gd, auto_director.gd,
    dice.gd, feed_hud.gd, leaderboard_panel.gd, ui_theme.gd.
  - L36 and L40: the HUD half is done - HudDock.put keeps the Chronicle clear. The remainder is the
    Twitch chat column and party frames docking into a pane, which is D41, game build's.

SO: L31, L36 and L40 being unchecked does NOT mean the HUD worker has work. Treat its queue as DRY
and write it new items under the "HOW BIG AN ITEM SHOULD BE" bar above - substantial work inside
its own seven files. There is a lot available there: the director's shot language and pacing
(auto_director.gd), the spotlight's whole presentation (spotlight.gd), the leaderboard and its
story over a long stream (leaderboard_panel.gd), the feed's readability under load (feed_hud.gd),
and one coherent pass over ui_theme.gd so every panel reads as one designed interface.

RESOLVED 2026-11-15 12:05: the supervisor wrote that work - Phase AE at the END of this file,
items L65, L64, L66, L67, in that order, all inside the HUD worker's own seven files. The HUD
worker's queue is NO LONGER DRY. L31, L36 and L40 stay unchecked and stay NOT the HUD worker's -
that is still true and is still the reason below.

HUD WORKER, READ THIS BEFORE YOU STAND DOWN (supervisor, 2026-11-15 11:05 CT - the 10:52 run stood
down with "no item it is allowed to build", which is NOT TRUE and has now cost a cycle):
  YOUR PROMPT'S QUEUE LIST IS STALE. It names L61, L31, L36 and L40 and stops there. It was written
  before Phase AE existed and the supervisor cannot edit it - only Mr. E can. THIS FILE IS
  CANONICAL, and this file gives you three open items in YOUR OWN SEVEN FILES, written to the
  "HOW BIG AN ITEM SHOULD BE" bar, at the END of this file under Phase AE:
      L64  THE DIRECTOR MUST TELL A STORY, NOT CYCLE THROUGH CAMERAS   (auto_director.gd)
      L66  THE LEADERBOARD IS A SEASON, NOT A TOP FIVE                 (leaderboard_panel.gd)
      L67  THE FEED MUST SURVIVE A RAID                                (feed_hud.gd)
  L61 and L65 are ticked. TAKE L64 NOW, in that order after it. Scroll to Phase AE and read the
  item's full staged text and its DONE test. You have work. Do not stand down, and do not re-derive
  the L31/L36/L40 analysis - it is already written below and nothing about it has changed.

DO NOT reassign boss_bar.gd, party_frames.gd, delve.gd or monster.gd to the HUD worker. Two workers
in one file is how merges break. If Mr. E wants the L31 leftovers built, they go to their OWNER as
a new item, not to the HUD worker.

## MR. E'S GEAR AND ECONOMY RULING (2026-11-15 11:46 - BINDING, he designed this)

His words, and the system they describe. Every gear, shop, trader and event item from here must
obey it. This supersedes any earlier loose talk about "loot tables".

  "gear can be obtained a number of ways, looting, buying in the shop, or forging at a blacksmith.
   The only way progression would work is if they bought it in a shop. But reminder shops upgrade
   depending on events. If people spend bits or channel points during an event poll to upgrade
   specific shops and specific buildings or aspects of the town.
   So a shop that is level 1 isn't going to sell epic or legendary equipment. Unless a trade
   caravan comes along and per chance brings a higher tier item or equipment. All per chance when
   it comes to the trader."

WHAT THAT MEANS, stated so no worker has to guess:
  1. THREE ROUTES TO GEAR, and they are NOT equivalent:
     - LOOT from a delve: what the floor and the boss happened to drop. Chance.
     - FORGE at the blacksmith: a hero spending their own gold, one step at a time (L55 shipped
       this - Roster.kit_up_after_delve, armour first, KIT_RESERVE kept back).
     - BUY at a shop: the ONLY reliable progression route. A hero who wants to climb, buys.
  2. A SHOP'S LEVEL CAPS WHAT IT SELLS. A level 1 shop does not stock epic or legendary, no matter
     how much gold a hero carries. Tier availability is a property of the BUILDING, not the buyer.
  3. SHOPS AND BUILDINGS ARE UPGRADED BY VIEWERS, through an event poll, with bits or channel
     points, naming the specific shop/building/aspect of the town to upgrade. This is the economic
     spine of T4/T5 - the viewer roll is not decoration, it is how the town's ceiling rises.
  4. THE TRADE CARAVAN IS THE ONLY WAY AROUND THE CAP, and it is PURE CHANCE. A caravan may
     happen to carry one higher-tier piece. It is never guaranteed, never scheduled, never a
     reliable route. That chance is what makes a caravan worth watching on stream - and it is why
     D39 (traders must matter) and bandits intercepting them have real stakes.

  5. EVERY HERO STARTS WITH THE MOST BASIC GEAR OF THEIR CLASS (Mr. E, 11:47). Not nothing.
     Today tier 0 is "bare hands" (1d4, atk 0) and "rags" (0 hp, 0 ac) for EVERY calling, so a
     Knight and a Mage begin identically holding nothing. That is wrong. A calling's starting kit
     must be the plain, humble version of what that calling actually carries - a knight's worn
     sword and gambeson, a mage's walking staff and travelling robes, a ranger's hunting bow, a
     rogue's knife. Cheap, weak, unglamorous, and UNMISTAKABLY that class. "Bare hands" stays only
     as the genuinely-unarmed fallback, not as everyone's default.
     There are 15 callings (blade 5, axe 2, ranged 1, arcane 6, 1 open) sharing 6 weapon tiers.

  6. AND YES - WE DO NEED MORE EQUIPMENT (Mr. E, 11:47). This is not only a gating job. The
     catalogue itself is too thin: 6 weapon tiers and 6 armour tiers against 886 appearance items.
     Expand it. More weapons and armour per family and per tier, so two heroes of the same calling
     at the same tier are not holding an identical object, and so loot, forge and shop each have
     something of their own to offer.

CONSEQUENCE FOR THE PLAN - BOTH HALVES, and the gates come first only because the catalogue needs
somewhere to land. Write the SYSTEM (class starting kits, tiers, shop levels, the upgrade poll, the
caravan chance), and expand the CATALOGUE into it. Do not do one and call the item done. Gear
variety without the gates is noise; gates without variety is an empty shop. Mr. E asked for both.

## HOW BIG AN ITEM SHOULD BE (Mr. E, 2026-11-15 03:21 - BINDING ON THE SUPERVISOR)

Mr. E: "longer and bigger tasks need to be handed out."

The workers are clearing items in 12-35 minutes. That is not speed, it is items that are too
small. A queue of micro-fixes produces a game that is tidy and shallow. He wants depth.

WHEN THE SUPERVISOR WRITES NEW WORK, the bar is now:
  - An item should be a SUBSTANTIAL piece of work - a system, a feature, a whole subsystem
    reworked - not a tweak, a number change, or a single-file polish pass. If a competent worker
    would finish it in under an hour, it is too small to write as its own item.
  - BUNDLE related small work into one larger item with staged parts (.1, .2, .3) under a single
    ID, the way D21b was run. One item, several stages, one DONE test for the whole thing.
  - Prefer DEPTH over breadth: a building type that NPCs actually use beats five new props; a
    status-effect system beats one new icon; traps that interact with the party beat one new room
    shape.
  - Every item still needs its concrete DONE test. A bigger item needs a BIGGER test - a soak, a
    timelapse, a capture with several things happening at once - not a single screenshot.
  - Do NOT pad an item to look big. A real system with real stakes, or nothing.

THIS DOES NOT CHANGE EXISTING ITEMS. IDs are frozen; nothing is renumbered or rescoped. It governs
what gets WRITTEN from now on, and the order they are offered: when several items are open, put the
substantial ones where a worker taking "the first unchecked item" will actually reach them, rather
than leaving a queue that is all polish at the top.

## MR. E'S ASK, Nov 15 11:51 - MAKE THE FESTIVAL ACTUALLY FEEL LIKE A FESTIVAL

- [x] D63. THE FESTIVAL MUST BE AN EVENT, NOT A BOOLEAN. Owner: DESKTOP BUILD (town.gd,
      townsfolk.gd, sfx.gd, economy.gd, notables.gd, Town.tscn) with CONTENT writing the words
      (see C6) and the HUD worker NOT involved - this happens in the world, not on a panel.
      WHAT IT IS TODAY, measured: `_festival_pass` flips `festival = true` every 260-420 s for
      55-85 s, points `festival_at` at the market square, and appends two feed lines. Idle
      townsfolk walk there and mill about (`_maybe_gather`, `acts["festival"]`). That is the
      entire feature. The feed line promises "music, stalls, and a crowd!" and the game delivers
      a crowd. No stall is built, no music changes, nothing is sold, nobody gains anything, and
      the heroes ignore it completely.
      THIS IS NOT COSMETIC DEBT - IT IS SOLD. "Bellmire: Festival of Plenty" is a 500-bit
      Custom Power-up. A viewer pays real money and gets bodies standing in a square for 70 s.
      Fixing this is fixing a thing people have already bought.
      .1 IT MUST LOOK LIKE ONE. The square dresses itself: stalls, bunting, banners, lanterns
         after dark - built on the existing plot/landmark machinery, struck when it ends, CC0
         assets only. A viewer glancing at the pane must know a festival is on without reading a
         word of the feed.
      .2 IT MUST SOUND LIKE ONE. D22a gave layered beds and a 24-voice pool; D22b gave music
         moods. A festival gets its own: music lifts, crowd noise, a piper or a drum near the
         square, trade chatter up. It returns to the ordinary day bed when the festival ends.
      .3 PEOPLE MUST DO SOMETHING. Today they "mill about and cheer". Give the crowd real acts -
         dancing, drinking, eating, a game, watching whatever is at the centre - drawn from the
         existing _idle_acts machinery rather than a new system. NOTABLES (scripts/notables.gd)
         should show their faces; E3PO has festival lines already written in lore_lines "e3po".
      .4 HEROES MUST BE IN IT. A hero in town during a festival joins it instead of walking past.
         A hero who comes home from a delve while one is on is received by it - that is the
         moment the stream should feel like a town, and it costs nothing but routing.
      .5 IT MUST DO SOMETHING. A festival with no consequence is scenery. Pick effects that fit
         Mr. E's economy ruling above and state them in the item when you build it: goods change
         hands (the market actually trades), a morale or luck lift while it runs, the smith or a
         shop keeps late hours. A FESTIVAL IS A GOOD HOUR FOR A CARAVAN TO ARRIVE - that ties
         D39 and the caravan-chance rule together without inventing a new mechanic.
      .6 IT MUST HAVE A REASON, AND THE CHRONICLE MUST SAY SO. A festival should be caused -
         a harvest, a raid survived, a lord felled, a hero's return, a town level - not only a
         random timer. The random one stays as the quiet baseline. D60 gave the Chronicle days
         and `who`; a festival line should name what is being celebrated and who it is for.
      .7 THE 500-BIT POWER-UP MUST LAND VISIBLY. When a viewer buys Festival of Plenty, the
         festival that starts is THEIRS - named in the Chronicle and on stream, and bigger than
         the baseline one. Do not let a paid festival be indistinguishable from a timer firing.
      DONE: a 1080p capture (and a short clip) of one festival from start to finish showing the
      square dressed, the crowd doing more than standing, at least one notable and one hero in
      it, the music lifting and returning, and the Chronicle naming the reason. Plus one capture
      of a VIEWER-BOUGHT festival that is visibly bigger and named for the buyer. Gates green.
  PROGRESS (game build, 2026-11-15 ~12:30 CT, D63a - all seven stages built, item left OPEN for two things):
  .1 town.gd _dress_festival: a pole + pennon by every stall, bunting stall-to-stall round the ring and in to a lantern
     crown over the well (one MultiMesh, 204 pennants; 306 for a gift, gold palette, a second lower ring), lantern
     OmniLights lit from 18:00 (always for a gift), never solid (navmesh untouched), struck at the end.
  .2 sfx.gd: mood "festival" (CC0 day_minstrel_dance, RandomMind) outranks delve/day/night, fades 3 s in / 6 s out;
     the market murmur bed +5 dB while it runs. .3 townsfolk.gd: each body comes to DO something - dance (hop/cheer/
     raise, near the well), drink, haggle at a stall front, cheer (acts fest_*); notables.gd sends chief, priest, bard
     (plays in the middle), the children, pedlar, beggar and drunk; E3PO's festival lines already fire.
  .4 hero_body.gd: a viewer's hero idling in town joins (its wander centres on the square) and toasts/cheers/hops;
     a delve party coming home to a festival gets a "cheers them in" line tagged `who`; 40% of homecomings cause one.
  .5 the square sells food off the stores into the treasury while it runs (closing line states lots + gold), and a
     festival calls the next caravan in within 6-15 s (D39's chance, no new mechanic).
  .6 reasons: market (the old timer, baseline), raid (50% when one is driven off), level (every level up), hero
     (homecoming), gift - caused ones respect a 240 s gap; each reason has its own opening line, tagged festival + who.
  .7 twitch_eventsub.gd tier 3 now calls town.start_festival("gift", [hero], buyer): 160-200 s, gold, lit, the
     Chronicle names the buyer (control chars, <>{} stripped, 25 cap). FIXED A BUG: the old path set festival=true
     with no timer, so a paid festival could end the very next frame. A gift bought during a raid waits for it to end.
  TEST tools/_d63_fest.gd: D63_FEST OK 25/25. LOOK tools/_d63_shot.gd -> renders/cycles/d63/ (before / day festival /
  struck / viewer festival at dusk, 1920x1080).
  STILL OPEN: (a) the DONE's "short clip" - stills only, no clip recorded this run; (b) the words - every line is a
  short code fallback until C6 lands. D63 READS C6 AS: lore_lines.json "festivals" = {openings: {market, raid, level,
  hero, gift}, closings, gift_openings, gift_closings} - arrays of strings, placeholders {who} {buyer} {town}. No
  code change needed when C6 ships in that shape. (Harvest and lord-felled reasons have no game event yet to hang on.)
  PROGRESS (2026-11-15 12:30 CT, laptop dea57ed, D63a): the festival is now an event, not a boolean. The square dresses
  itself and strikes the dressing when it ends (.1); music lifts and returns to the day bed (.2); the crowd haggles,
  dances, drinks and cheers out of the existing _idle_acts machinery and notables walk to the square (.3); heroes in
  town join it and a hero home from a delve is received by it (.4); goods actually change hands into the treasury and a
  festival is a good hour for a caravan (.5); a festival has a REASON and the Chronicle names it (.6); a 500-bit
  festival is bigger, longer, every lantern lit, named for its buyer with the name sanitised and capped (.7). A gift
  bought during a raid waits and fires when the raid is driven off. D63_FEST OK 25/25, all gates green.
  STILL OPEN, and the reason this is not ticked: (a) town.gd still speaks its OWN festival strings - C6 is now merged on
  main (lore_lines.json "festivals": reasons/crowd/toasts/stalls/notables/e3po/closings/viewer_paid, with {buyer} in the
  paid set), so read those and delete the hardcoded pair rather than growing a parallel copy; (b) the DONE captures - one
  1080p pass of a festival start to finish and one of a viewer-bought festival that is visibly bigger and named.
  RESULT D63b (game build, 2026-11-15 ~13:30 CT) - both open points closed; ITEM TICKED:
  (b) C6 shipped on `content` (bac1808) in its OWN shape, not the one noted above, so town.gd now reads it as written:
     reasons{harvest,raid_survived,town_level,hero_home,viewer_gift,lord_felled} (game reasons market->harvest, raid->
     raid_survived, level->town_level, hero->hero_home), closings, viewer_paid{openings,crowd,toasts,stalls,notables,
     e3po,closings} for a paid one, notables as {who,line}; the D63a shape and the code lines stay as fallbacks. NEW: the
     festival TALKS while it runs - festival-goers within 22 m raise crowd/toast lines in their own shout bubble every
     6-10 s (4-7 s for a gift; Townsfolk.say_once, NOT the crier path, never the feed), and every 24-34 s (16-24 gift) the
     Chronicle gets one line rotating stalls -> a notable -> E3PO (who says it in his own bubble, notables.e3po_line).
     LIVE ONLY WHEN THE SUPERVISOR MERGES `content` -> main -> laptop: laptop's lore_lines.json has no "festivals" yet.
  (a) CLIP: tools/_d63_clip.gd + movie writer -> renders/cycles/d63/d63_festival_clip.mp4 (75 s, h264+aac, 34 MB, NOT
     committed - too big for git; it sits on cruzader). Market festival opens on a C6 harvest line, bunting + crowd +
     both heroes + bubbles, closes on a C6 closing with the trade tally, square struck, dusk, a 500-bit Festival of
     Plenty for "MrEsBestViewer" lit gold and named. CAVEATS: it recorded at 1152x648 (the movie writer kept the default
     window, not 1920x1080 - the 1080p stills from D63a stand), and the slow orbit camera passes through a roof twice.
     Words in the clip come from content's file injected via env D63_LORE (preview of the merge).

- [x] C6. THE FESTIVAL HAS A VOICE (data/lore_lines.json). Owner: CONTENT WRITER - words only,
      never code, and D63 reads them rather than inventing parallel copies.
      There is no festival pool in lore_lines.json today (keys: tells, descend, cleared,
      lord_intros, unique_intros, barks, misfire, epitaphs, forge, town_levels_for_the_desktop,
      e3po, town_life, propositions, disasters, events, growth_tiers). The two festival lines in
      the game are hardcoded in town.gd. Write a "festivals" pool with, at minimum: openings that
      name a REASON (harvest, a raid survived, a lord felled, a hero home, a town level, a
      viewer's gift), crowd barks and toasts, what the stalls are selling, a notable's line,
      E3PO's line, closings, and a separate richer set for a festival a VIEWER paid for naming
      the buyer. Enough that a 24/7 stream does not repeat. Keep Bellmire's voice - medieval,
      D&D-flavoured, short, readable at a glance.
      DONE: json validates, every pre-existing key byte-identical, counts stated per category.
      NOTE FROM D63a (game build, 12:30): the game already reads "festivals" in this shape - openings: {market, raid,
      level, hero, gift} (the five reasons the game raises), closings, gift_openings, gift_closings; arrays of strings;
      {who} = hero names, {buyer} = the viewer, {town} = the town's current name. Extra keys (barks, stalls, notable,
      e3po) are welcome and will be read when D63 wires them; E3PO's festival lines stay in "e3po"."festival".
  RESULT (2026-11-15 12:26 CT, content bac1808, C-49): new top-level "festivals" pool, 365 lines, none existed before -
  reasons 72 (harvest / raid survived / lord felled / hero home / town level / viewer's gift), crowd 39, toasts 30,
  stalls 30, notables 24, e3po 30, closings 24, and a separate richer viewer_paid set of 116 that carries {buyer}.
  json validates; every pre-existing key byte-identical. D63 must READ THESE instead of town.gd's hardcoded pair.

## MR. E'S GEAR AND ECONOMY RULING, STAGED AS WORK (supervisor, 2026-11-15 12:58 CT)

The ruling at the top of this file (11:46 and 11:47) was prose. These are the items. They are
written in the order the ruling demands - GATES FIRST, then the catalogue lands into them - and
they are deliberately large per the HOW BIG AN ITEM SHOULD BE bar. Nothing here renumbers or
rescopes an existing item; D64-D66 and C7 are new IDs.

- [ ] D64. A SHOP'S LEVEL DECIDES WHAT IT SELLS - THE GEAR LADDER GETS ITS GATES. Owner: DESKTOP
      BUILD (scripts/gear.gd, scripts/economy.gd, scripts/town.gd, scripts/roster.gd,
      scripts/chatcmd.gd). This is Mr. E's ruling 1-2 and 4, and it is the item the whole gear
      programme waits on: today WEAPONS and ARMOUR are two flat six-entry ladders in gear.gd that
      anyone with gold can climb to the top, and a shop is a building with no level at all. There
      is no ceiling to raise, so the viewer upgrade poll (D66) and the caravan's one lucky piece
      (below) have nothing to push against.
      .1 THE LADDER IS NAMED AND RANKED. Give every weapon and armour tier an explicit rarity
         rank in gear.gd - the names Mr. E used (common through epic and legendary) mapped onto
         the existing six-entry ladders, with `scarforged` and `scarwoven mail` staying FOUND-only
         as they already are. Do not change a single existing cost, atk, hp, ac or dice value;
         this is a rank label and a lookup, not a rebalance.
      .2 A SHOP HAS A LEVEL, AND IT CAPS THE TIER. Every shop/trade building carries a level and a
         maximum rarity it will ever stock. A level 1 shop does not sell epic however much gold the
         buyer carries - the cap is a property of the BUILDING. A hero who cannot afford or cannot
         find their next step buys the best the shop is allowed to sell, and the Chronicle says so
         plainly rather than silently handing over the item.
      .3 THE THREE ROUTES STOP BEING INTERCHANGEABLE. Loot is chance (the floor and the lord decide),
         the forge is gold spent a step at a time (L55's Roster.kit_up_after_delve already does this -
         keep it, gate it), and the SHOP is the only reliable progression route. Each route must be
         able to hand a hero something the other two cannot, and a viewer watching should be able to
         tell from the Chronicle which route a piece came from.
      .4 THE CARAVAN IS THE ONLY WAY PAST THE CAP, AND IT IS PURE CHANCE. A trade caravan may happen
         to carry ONE piece above the town's current ceiling. Never guaranteed, never scheduled, no
         pity timer, and it is lost if bandits take the caravan - which is what gives D39 and the
         festival caravan hook from D63a their stakes. The Chronicle names the piece and the risk.
      DONE: a soak with the publisher on, long enough for a town to climb several growth stages, and
      from it (a) a log showing a level 1 shop REFUSING a tier it is not allowed to stock while a
      richer hero stands at the counter, (b) a hero kitted along each of the three routes with the
      Chronicle line that announced each piece, (c) one caravan that carried an above-cap piece and
      one that was intercepted and lost it, and (d) a 1080p capture of a shop pane where what is on
      the shelf matches what that shop's level allows. Gates green, parse 0 errors, payload under cap.
      STAGE D64a DONE (game build, 2026-11-15 ~14:30 CT) - .1 + .2 in the game build's OWN files only
      (economy.gd, town.gd, snapshot_pub.gd): Economy.RARITY ranks the unchanged ladders (0 none, 1
      common, 2 uncommon, 3 rare, 4 epic, 5 legendary = found-only); the SMITHY is a building with a
      level (shop_grown from town growth, today's curve unchanged + shop_raised from viewers) and that
      level alone sets Roster.town_tier, the counter's ceiling; raise_shop(key, by, who) is D66's entry
      point and cries the raise crediting who paid; a daily counter watch says plainly, once per hero per
      level, when a hero with the gold is turned away by the cap; the rack's draped pegs read
      "<rarity> / smithy lv N"; the snapshot town block gains `shops` [{name, level, sells_to}]
      (additive, v stays 4). D64_TEST OK 17/17. OPEN: .2's per-shop cap for the other counters, .3
      route-tagged Chronicle lines and .4 the caravan's above-cap piece all need roster.gd / chatcmd.gd /
      gear.gd, which COORDINATION 11.2 gives to LAPTOP CODE and the game build's standing brief forbids
      it to touch - the supervisor or Mr. E must reassign those files (or this item's remainder) first.

- [ ] D65. EVERY CALLING STARTS AS ITSELF, AND TWO HEROES AT ONE TIER ARE NOT THE SAME OBJECT. Owner:
      DESKTOP BUILD (scripts/gear.gd, scripts/roster.gd, scripts/hero_body.gd). Mr. E's ruling 5 and
      the code half of 6. Today tier 0 is "bare hands" (1d4, atk 0) and "rags" (0 hp, 0 ac) for all
      fifteen callings, so a Knight and a Mage enlist holding nothing and looking identical - the
      first thing a viewer sees of a new hero is the thing that says least about them.
      .1 A STARTING KIT PER CALLING. All fifteen callings (blade 5, axe 2, ranged 1, arcane 6, 1 open)
         begin with the plain, humble, unmistakable version of what that calling carries - a worn
         sword and gambeson, a walking staff and travelling robes, a hunting bow, a knife. Cheap and
         weak: a starting kit must not out-perform the first BOUGHT tier, or D64's progression route
         dies on arrival. "Bare hands" survives only as the genuinely-unarmed fallback.
      .2 IT IS VISIBLE ON THE RIG. The kit is equipped on the real attachment bones (handslot.r /
         handslot.l / chest) at enlistment, not just recorded in a stat block, so a new hero reads as
         their class in the pane before they have done anything.
      .3 VARIANTS WITHIN A TIER. Two heroes of the same calling at the same tier should not be holding
         the identical object: pick from the FAMILIES geometry already present plus the names and
         flavour the content writer provides in C7, so the catalogue has somewhere to land.
      .4 THE SHEET AND THE CHRONICLE AGREE. The enlist line names what they carry, the published hero
         sheet (D59, v=4) shows the kit in the real gear slots, and the hub's "Bare Hands - 1d4"
         fallback stops firing for heroes who are not in fact bare-handed.
      DONE: a 1080p capture sheet of one freshly enlisted hero of EACH family (blade, axe, arcane,
      ranged) side by side, each visibly carrying their own kit on the rig; the live hub hero sheet for
      two same-calling same-tier heroes showing different pieces; a log line proving no starting kit
      beats the first purchasable tier; D59_SHEET, W1A_TEST and the gates green.

- [ ] D66. VIEWERS RAISE THE TOWN'S CEILING - THE UPGRADE POLL. Owner: DESKTOP BUILD
      (scripts/twitch_eventsub.gd, scripts/town.gd, scripts/economy.gd, scripts/snapshot_pub.gd).
      Mr. E's ruling 3, and he called it the economic spine of T4/T5: viewers spend bits or channel
      points during an event poll to upgrade a SPECIFIC shop, building or aspect of the town. D64 gives
      the ceiling; this is the only thing that lifts it, and without it the gates read as a wall.
      .1 THE POLL IS AN EVENT ON STREAM. It opens on a real occasion (a growth stage, a raid survived,
         a festival - D63a's reason machinery already exists), names the handful of specific things that
         could be upgraded, runs for a stated window, and closes with a result the Chronicle announces.
      .2 BITS AND CHANNEL POINTS BOTH COUNT - BUT NOT THE SAME WAY, AND THIS IS A HARD API FACT, NOT a
         preference. TWITCH REMOVED BITS VOTING FROM POLLS: Create Poll silently drops
         `bits_voting_enabled`/`bits_per_vote` and those fields were deleted from the API in Jan 2024.
         So the CHANNEL-POINTS half can ride a native Twitch poll (`channel_points_voting_enabled`,
         `channel_points_per_vote`), and the BITS half CANNOT - the game must tally bits itself from
         cheers and power-up redemptions inside the poll window and add them as weight. Do not try to
         pass bits to the Polls API; it will accept the call and ignore you, which is worse than failing.
         State the rules on screen before anyone spends.
         Do NOT create, delete or re-price any Twitch reward - match on the permanent reward ID and the
         bit cost exactly as the existing power-ups do.
      .3 THE UPGRADE IS REAL AND IT SHOWS. The chosen building gains a level, its D64 tier cap rises,
         and the building itself changes in the world - a bigger shopfront, a lit forge, new stock on
         the shelf - so the pane proves the spend happened.
      .4 THE TOWN REMEMBERS WHO. The Chronicle credits the viewers who paid for it (D60's `who`), the
         building keeps a line about who raised it, and the snapshot carries the levels so the hub can
         show them without inventing anything.
      DONE: a 1080p capture of a poll opening, running and closing on stream; the Chronicle lines that
      named the occasion, the choices and the winner with its backers; before/after captures of the
      upgraded building in the world; proof from the same run that the upgraded shop now stocks a tier
      it previously refused (ties D64); TWITCH_PARSE OK, W1A_TEST OK, gates green, payload under cap.

- [x] C7. THE EQUIPMENT CATALOGUE - NAMES, FLAVOUR AND CLASS KITS FOR GEAR THAT HAS STAKES. Owner:
      CONTENT WRITER (data/items.json ONLY - never code, never gear.gd). Mr. E's ruling 6: 6 weapon
      tiers and 6 armour tiers against 886 appearance items, and the thin one is the only one with
      mechanical stakes. Write the catalogue the gates will stock.
      .1 WEAPONS BY FAMILY AND TIER. For each existing family (blade, axe, arcane, ranged) and each
         existing tier, several named pieces with flavour, so two heroes of one calling at one tier can
         hold different objects. Use the tier names and ranks as they stand in gear.gd - do not invent a
         seventh tier, do not state costs that contradict the existing ladder, and keep the found-only
         pieces found-only.
      .2 ARMOUR THE SAME WAY, per tier, named and described, including the humble starting layers.
      .3 THE FIFTEEN STARTING KITS, NAMED. One plain weapon + one plain armour per calling, written so
         the name alone says the class, with flavour that admits how cheap it is. D65 reads these.
      .4 WHERE A PIECE COMES FROM. Mark each entry with the route or routes that can produce it - looted,
         forged, shop-stocked, caravan-only - so D64's three routes have something of their own to hand
         out, and so a caravan's above-cap piece is a real catalogue entry rather than a special case.
      DONE: json validates; every pre-existing key byte-identical; counts stated per family, per tier and
      per route; the fifteen starting kits listed in the summary as calling -> weapon + armour; and a
      plain statement of the exact keys and shape the game build worker reads.
  RESULT (content C-51, merged 2026-11-15): data/items.json gains an `equipment` block - 86 named
  weapons (blade 22, arcane 21, axe 17, ranged 16, open 10) and 33 armour pieces, each keyed by id with
  {name, family, tier (0-5 index into gear.gd's unchanged ladder), tier_name, routes, flavour}, plus the
  15 starting kits as calling -> {weapon, armour, family}. No cost/atk/hp/ac is stated anywhere - those
  stay in gear.gd, so .1's "do not contradict the ladder" holds by construction. `routes` carries
  looted/forged/shop/caravan, which is what gives D64.3's three routes and D64.4's above-cap caravan piece
  real catalogue entries. JSON validates; pre-existing keys unchanged (additive block only).


## MR. E'S ASK, Nov 15 13:36 - UPDATE BELLMIREBRO

The bot has fallen behind the game. data/commands.json carries 21 commands (!armoury !brew
!deadliest !deepest !delve !dye !enlist !fish !forge !guild !help !hero !inventory !look !memorial
!oil !patrons !reroll !respec !richest !wear) and NOT ONE OF THEM MENTIONS THE HUB. The viewer
website is live at https://jestsayin96.github.io/Bellmire-HD-stream/ with the Chronicle, hero
sheets, the Satchel, crests, the Hall of the Fallen, the Bestiary, the Night Watch and search -
and a viewer in chat has no way to learn it exists. Everything shipped since Nov 14 is invisible
to the bot: the festival (D63), the Satchel (D57), the character sheet (D59), and the gear and
shop economy now being built (D64-D66).

- [ ] L68. BELLMIREBRO MUST KNOW WHAT THE GAME HAS BECOME. Owner: LAPTOP CODE (chatcmd.gd,
      data/commands.json - both laptop-owned; data/ except the four content files). The DESKTOP
      side of the chat contract is untouched: chatcmd.gd emits twitch_reply(user_login, text) with
      no @name and no rate limiting, and twitch_eventsub.gd owns the queue, the prefix and the
      Send Chat Message API call as bellmirebro. Do not change that signature.
      .1 TELL THEM THE HUB EXISTS. A !hub (alias !site, !guildhall) command giving the URL and one
         line on what is there. Fold a short pointer into !help and !hero too - a viewer who asks
         about their hero should learn their full sheet is a click away.
      .2 COVER WHAT SHIPPED. Commands or help text for the festival, the Satchel and its sell
         prices, the character sheet, and the Bestiary. A viewer should be able to ask the bot
         about anything they can see on stream.
      .3 THE COMMAND LIST MUST NOT ROT AGAIN. !commands / !help are generated FROM
         data/commands.json, so one edit updates chat, the bot and the hub's Commands tab
         together. Add a test that fails when a command exists in code without an entry, or an
         entry names a command the code does not answer. That test is the real deliverable - it is
         what stops this item being written again in a month.
      DONE: !hub answers with the live URL; !help and !commands list every command the code
      actually answers; the drift test passes and fails when a command is removed from either side.

- [ ] D67. BELLMIREBRO SHOULD SPEAK WHEN SOMETHING HAPPENS, NOT ONLY WHEN ASKED. Owner: DESKTOP
      BUILD (twitch_eventsub.gd - it already owns the send path, the queue and the rate limiting).
      Today the bot only ever replies. The big moments pass in silence for anyone reading chat
      rather than watching the pane: a festival starting - especially one a viewer PAID for - a
      lord felled, a hero dying, a town level, a caravan taken by bandits.
      Pick the few that genuinely earn an interruption and announce them in chat, in Bellmire's
      voice, reusing the lines CONTENT has already written (lore_lines.json festivals, epitaphs,
      town_levels_for_the_desktop) rather than inventing parallel copies. A paid festival names
      its patron. RATE LIMIT HARD and make the cap a constant Mr. E can turn down - a bot that
      talks too much is worse than one that says nothing, and this runs 24/7.
      DONE: a chat log from a soak showing each announcement fired once, in voice, within the cap;
      and the cap proven by forcing a burst.

## DECIDED AGAINST: A TOWN RESET POWER-UP (Mr. E, 2026-11-15 14:12)

He raised a 10,000-bit power-up that would put Bellmire back to level 1, considered it, and said
no: "lets not do the reset". D68 and C8 were written and are now withdrawn - DO NOT rebuild them
and DO NOT propose a town-wipe, a razing, a reset or a "start the age over" mechanic again unless
he raises it himself.

The reason is worth keeping, because it constrains other designs too: D66 lets viewers spend bits
and channel points to upgrade SPECIFIC shops and buildings. Anything that wipes town progress also
deletes what OTHER patrons paid for - a viewer who spent 2,000 bits raising the armoury would watch
a stranger erase it. A feature that lets one person destroy another's contribution punishes the
most invested people in the channel. Weigh any future "big destructive event" against that before
writing it: Bellmire can have disasters and losses, but not ones that cancel a patron's gift.

## MR. E'S ASK, Nov 15 14:28 - THE BOT RUNS THE CHAT AND THE POLLS

- [ ] D69. BELLMIREBRO CONDUCTS THE POLL. Owner: DESKTOP BUILD (twitch_eventsub.gd - it already owns
      the broadcaster token, the EventSub socket, the send path, the queue and the rate limiting).
      Pairs with D66 (what a poll DOES) and D67 (the bot speaking unprompted). D66 decides the town's
      ceiling; this is the machinery that runs the vote and makes chat the place it happens.
      THE SCOPES ARE ALREADY LIVE - nothing is blocked on Mr. E. The broadcaster token holds
      channel:manage:polls AND channel:read:polls (re-authorized Nov 15, validated as jestsayin96,
      user_id 138821183, refresh present). Use them.
      THE TWITCH POLLS API, AND ITS LIMITS - build to these, do not discover them live:
        - POST helix/polls: 2-5 choices, title max 60 chars, duration 15-1800 s, ONE active poll at a
          time per channel. Affiliate/Partner only.
        - `channel_points_voting_enabled` + `channel_points_per_vote` work and are the supported way to
          let viewers buy extra weight.
        - BITS VOTING IS GONE. The endpoint accepts `bits_voting_enabled` and ignores it. Tally bits
          yourself from cheers in the window.
        - Subscribe to channel.poll.begin / .progress / .end over EventSub rather than polling the
          REST endpoint for results.
      .1 THE BOT OPENS IT. When D66 raises a poll, the bot announces it in chat: the occasion, the
         choices, how to vote, what it costs, and how long is left. The native poll banner does the
         voting; the bot does the telling, because the banner says nothing about Bellmire.
      .2 IT KEEPS CHAT INFORMED WITHOUT FLOODING IT. One opening line, at most one mid-poll nudge, one
         result. Hard cap, as a constant Mr. E can turn down. A poll every few minutes on a 24/7 stream
         must never become the thing chat is mostly made of.
      .3 IT TALLIES BOTH STREAMS AND SHOWS ITS WORKING. Channel-point votes come from the poll; bits
         come from cheers the game counted in the window. The closing message states both and the
         winner, so nobody has to trust a number they cannot see.
      .4 IT CLOSES HONESTLY. Ties, a poll nobody voted in, a poll that ends while the game is mid-raid,
         and a poll Twitch ends early all need a stated outcome rather than silence.
      .5 IT NEVER LEAVES ONE OPEN. One active poll per channel is a hard Twitch limit - if the game
         restarts mid-poll, find the live poll on startup (GET helix/polls) and adopt or end it. A
         stuck poll blocks every later one.
      DONE: a capture of a full poll - opened by the bot, voted with channel points, bits counted
      alongside, closed with both totals stated and the Chronicle naming the winner; the cap proven by
      forcing a burst; and a restart mid-poll proven to recover rather than deadlock.

- [ ] L69. THE BOT CARRIES THE CHAT, NOT JUST THE COMMANDS. Owner: LAPTOP CODE (chatcmd.gd,
      data/commands.json). Builds on L68. Mr. E: the bot needs to "handle a lot of the chat".
      Today a viewer gets an answer only if they type the exact command. Widen it:
      .1 UNDERSTAND WHAT THEY MEANT. Near-misses, plurals, aliases and plain questions ("how do I
         join", "what's my hero") should reach the right command instead of silence. Silence reads as
         a broken bot.
      .2 ANSWER THE QUESTIONS CHAT ACTUALLY ASKS - the ones a new viewer asks in the first minute:
         what is this, how do I get a hero, is this a real game, how do I get gear, what are the bits
         for. H22 wrote the newcomer welcome for the hub; the same answers belong in chat.
      .3 KNOW WHEN NOT TO SPEAK. A per-user cooldown already exists; keep it, and never answer the same
         question twice in a row for different people inside the window - say it once to the channel.
      DONE: a transcript of a busy chat where every reasonable phrasing lands, nothing is answered
      twice inside the cooldown, and the drift test from L68 still passes.

## THE BOT, CONTINUED (Claude's suggestions, Mr. E: "whatever you suggest", Nov 15 14:33)

- [ ] D70. THE BOT SHOULD KNOW WHO IT IS TALKING TO. Owner: DESKTOP BUILD (twitch_eventsub.gd,
      roster.gd read-only). Pairs with D67 (speaking unprompted) and L69 (understanding chat).
      Today the bot treats every message the same. The two moments that decide whether a viewer
      becomes a player are both being missed.
      .1 THE FIRST-TIMER. Someone typing in this channel for the first time is the only moment they
         are guaranteed to be paying attention. Once - exactly once, ever, per viewer - tell them
         they can have a hero in this town and how. This is the whole conversion funnel: a lurker
         who gets a hero has a reason to come back, and one who does not is a passer-by. Never
         repeat it, never chase someone who ignored it.
      .2 THEIR HERO'S MOMENTS, TOLD TO THEM. D67 announces the TOWN's big moments. This is the
         viewer's own: their hero levelled, died, came home with something rare, was the one who
         felled a lord. Address them by name, keep it to one line, and only for moments that
         actually matter - not every kill. A viewer who learns their hero died while they were at
         work is a viewer who comes back to see what happened next.
      .3 KNOW WHEN THE ROOM IS EMPTY. SIMPLIFIED by Mr. E's ruling below (14:38): the game runs only
         while he streams, so the game being up is itself the signal that someone is there. No
         stream-state check is needed. Still never queue news to dump at the start of the next
         session - stale news is worse than no news.
      .4 SAFETY - THIS ONE IS NOT OPTIONAL. The bot must NEVER echo attacker-controlled text back
         into chat. Hero titles, epitaphs, dye names and anything else a viewer can set are exactly
         the hostile input the hub defends against with el()/textContent - chat has no such
         protection, and a line the bot repeats is a line Mr. E's channel published. Echo only
         values the GAME generated, or a Twitch login Twitch itself gave us. If a viewer-set string
         must appear, cap its length, strip control characters and newlines, and never let it start
         a message (a leading / or . is a chat command). Treat this as the W1a rule for chat.
      DONE: a transcript showing a first-timer welcomed once and never again; a hero moment told to
      its owner; the bot silent while the stream is offline; and a hostile hero title proven inert -
      it either never reaches chat or reaches it declawed. Gates green.

- [ ] L70. WHAT HAPPENED WHILE I WAS AWAY. Owner: LAPTOP CODE (chatcmd.gd, data/commands.json).
      A viewer who looks in after two days has no way to find out what became of their hero. The
      Chronicle knows - D60 gave it days and `who`, so the lines about a given hero are already
      findable. Give them a !catchup (alias !mystory, !since) that answers in one or two lines: what
      their hero did, how it went, and where it stands now. Cap it hard - a summary, not a saga, and
      point them at the hub for the full sheet. If they have no hero, that is the moment to tell
      them how to get one.
      DONE: a hero with a busy history gets a short true summary; a hero with none gets the join
      line; the L68 drift test still passes; output never exceeds the cap.

## MR. E'S RULING, Nov 15 14:38 - THE GAME RUNS ONLY WHILE HE STREAMS (BINDING)

He chose this deliberately after weighing three options. Bellmire is NOT a 24/7 persistent world
for now: the game runs when the stream runs, and stops when it stops.

WHY IT MATTERS TO YOU, as a worker: cruzader is free for development whenever he is not live. That
is the whole reason for the choice - a permanently running game would hold docs/RUN_LOCK.txt
forever, every worker would see RUNNING and skip, and all development would stop. If you ever find
the lock held by a session that is a LIVE STREAM rather than a test run, that is not a stale lock.
Do not clear it. Stand down and say why.

WHAT THIS MEANS FOR DESIGN:
  - The hub is honest about it already and needs no change: it says "Last word from the town N
    minutes ago. The game is probably not running right now."
  - The bot can treat "the game is up" as "someone is watching" (see D70.3).
  - A viewer redeeming a Bellmire reward while the game is DOWN gets nothing. That is the open
    wound - see D71.
  - Option 3 (a separate always-on instance, so the town lives between streams) is the long-term
    answer and is NOT being built now. It needs a real split: two instances cannot share one
    Supabase row or one pair of Twitch tokens without fighting. Do not start it.

- [~] D71. DECIDED AGAINST - CLOSED, DO NOT BUILD, DO NOT RE-PROPOSE.
      Mr. E, Nov 15 16:41: "i thought you said it would cause to many issues so we both said no".
      He is right and this entry was wrong to leave it open. The reward auto-pause is OFF the
      plan. Rewards stay as Mr. E sets them and the game never reaches in to pause or unpause
      them. Any later worker that thinks this is a good idea: it was considered twice and
      declined twice. Leave it.
      THE PROBLEM, which he hit himself: on Nov 15 viewers redeemed Bellmire channel-point rewards
      while he was streaming something else. He fixed the CONFUSION by prefixing every reward with
      "Bellmire:" - but the redemption still lands in a void whenever the game is down, and under
      the 14:38 ruling the game is down most of the day. The viewer spends; nothing happens.
      THE FIX: pause the game's own rewards when it is not running and unpause them when it is.
      Helix exposes `is_paused` on a custom reward, the game already holds every reward id in
      `reward_ids`, and `_helix()` already does PATCH - so this is small.
      FAIL SAFE, NOT FAIL OPEN: pause on STARTUP first, then unpause once EventSub is actually
      connected, so a crash or a power cut leaves the rewards PAUSED rather than open on a town
      nobody is simulating. A clean-exit-only hook is not good enough; this project has lost enough
      time to sessions that died mid-run.
      SCOPE LIMIT, state it in chat if asked: this covers only the SIX channel-point rewards the
      game created and matches by id. The five Custom Power-ups have no API and stay manual, and
      fightoverlay's rewards are not ours to touch.
      DONE: rewards show paused on the dashboard within seconds of the game closing, unpaused once
      it is live, a forced crash leaves them paused, and no fightoverlay reward is ever modified.

## WHAT "DONE" MEANS - THE ROAD TO A FINISHED GAME (Mr. E: "do what's needed to get this game to
## completion", Nov 15 14:50). BINDING ON THE SUPERVISOR.

THE PROBLEM THIS SOLVES: this plan has had no finish line. The supervisor writes new work whenever
a queue drains, which is correct for depth and fatal for shipping - left alone it generates items
forever and the game is never done. 51 items are open and 169 are closed, but those 51 are not
equal: a few are the game NOT WORKING and most are the game not being as deep as it could be.

BELLMIRE HD IS FINISHED WHEN MR. E CAN STREAM IT FOR FOUR HOURS WITHOUT APOLOGISING FOR IT.
Concretely, all five must be true:
  1. THE LOOP CLOSES. A viewer arrives, gets a hero, that hero delves, gains or loses something
     that matters, and comes home or doesn't - visibly, without Mr. E explaining it.
  2. SPENDING CHANGES THE WORLD. Bits and channel points do something permanent and visible, not
     just a buff. A viewer can point at the town and say "I paid for that".
  3. IT READS WITHOUT A COMMENTATOR. A stranger watching for sixty seconds understands what is
     happening. Nothing overlaps, nothing important is off-screen, a fight is legible.
  4. IT SURVIVES THE SESSION. Four hours at frame rate, no stranded heroes, no silent stalls.
  5. THE CHANNEL WORKS. The bot answers, the polls run, the hub is current.

### PHASE RC - THE ORDER OF WORK. Agreed with Mr. E, Nov 15 17:06: "do it start it, make it happen"
REWRITTEN 17:10. This REPLACES every earlier RC ordering in this file. If you find an older RC list
anywhere, it is dead - this is the one.

THE PRINCIPLE BEHIND THE ORDER: a slightly ugly town costs us nothing with viewers. A missing loop
costs us everything. Nobody ever left a stream because a fence overlapped; they leave because they
redeemed something and nothing happened. So: stop it looking broken, then make the loop real, then
make it beautiful.

PHASE 1 - STOP IT LOOKING BROKEN. Visible wrongness, and most of these now have confirmed causes.
  L71 Chronicle truncation (cause confirmed - a roll cut off before its result is the worst thing
      on screen, and the Chronicle is what a non-chat viewer actually reads)
  D91 crowd avoidance + three-cell corridors (the most obviously broken thing in the game)
  D84 white figures · D90 the wagon (THIRD report) · D88 the gate · D83 the traps stuck
  These do not make the game better. They stop it looking broken. That is a different job and it
  comes first because Mr. E streams this.

PHASE 2 - MAKE THE LOOP REAL. This is the phase that matters.
  T5  THE VIEWER'S ROLL. FIRST IN THIS PHASE AND NOTHING JUMPS IT. Mr. E called it the heart of
      viewer interaction. It is unblocked, its words were written in C-cycle 38, and it has sat
      unbuilt since. It is the largest single gap in the game.
  D77 + D78 + D80 THE ASCENT, THE ERRAND, CARRY WEIGHT. ONE SYSTEM, NOT THREE ITEMS - built
      together or not at all. Nothing teleports out, buying is a walk to a specific building, and
      what a party can carry is the real limit on how deep it goes.
  D79 stones · H29 shop tab · H30 satchel tab · D81 use/sell/vault
  WHEN PHASE 2 LANDS a viewer can enlist, roll, delve, fight their way back out, buy something,
  carry it, store it and lose it. That is a game. Everything before it is scenery.
  Also in this phase, where they block the loop: D64, D65, D66, C7, D61, L68, L69, L70, D67, D69,
  D70, D23 (FPS), L56 (soak), L64 (director), D41, D48, L36, L40, T4, D44/D50.

PHASE 3 - THE TOWN, AUTHORED ONCE. D93. Big, and no longer urgent once Phase 2 is in.
  Build it as ONE map with per-level reveal states, not as 12-15 separate maps (see D93).

PHASE 4 - THE ART PROGRAM. D75 the lords · D85 E3PO · D73 the icons · D76 monster variety ·
  D82 the waterline. This is where "people want to see what they pay for" gets paid off - AFTER
  the paying works.

PHASE 5 - THE DAIS. D86, D87. Last, deliberately. It makes Mr. E's job easier; it does not make
  the stream better. It waits.

RUNNING ALONGSIDE, NO CONFLICT: D72 the music. Different worker, never touches Godot, already
green lit. It proceeds through all five phases and comes to Mr. E for judgement when ready.

SUPERSEDED / CLOSED, DO NOT WORK THEM: D71 (decided against, twice). D92 for the TOWN (D93's
authored layout removes the problem; the oriented-rectangle test is still worth having for the
valley and for anything the dungeon places, but it is not a big item any more).

### YOUR LANE'S QUEUE - TAKE THE FIRST OPEN ITEM IN YOUR OWN ROW
All six lanes run in parallel. Do not take another lane's item; if your row is empty, say so and
stand down rather than reaching into someone else's files.
  GAME BUILD:  D91 -> D84 -> D90 -> D88 -> D83 -> T5 -> (D77+D78+D80 as one) -> D79 -> D81
  HUD:         L72 -> L73 -> L74   (CORRECTED 20:58 - see below)
  HUB:         H29 -> H30
  CONTENT:     the words Phase 2 needs (T5's outcomes exist already - check before writing any),
               then D81's feed lines, then C7
  ART:         D75 -> D85 -> D73 -> D76 -> D82
  SUPERVISOR:  merge, tick, and hold the freeze below

### THE FREEZE - NO NEW ITEMS (Mr. E agreed, Nov 15 17:06)
The open count must now go DOWN. On Nov 15 alone this plan gained D80-D93, H29, H30 and L71 -
about fourteen items - while Phase RC existed specifically to stop the plan growing forever. Six
workers closing roughly one item an hour cannot outrun that, and a plan that only grows is a plan
nobody finishes.
  - A NEW ITEM IS WRITTEN ONLY IF MR. E RAISES IT. A bug he reports goes in. Anything else does
    not, however good it is.
  - A good idea nobody asked for goes in a LATER list that no worker pulls from. It is not lost;
    it is not work.
  - BEFORE ADDING ANYTHING, CHECK IT IS NOT ALREADY HERE. The dungeon fallback got written twice
    inside one minute on Nov 15. Search the file first.
  - CLOSING COUNTS AS PROGRESS. A run that ticks a finished item, merges a duplicate or deletes a
    dead one has done real work and should say so.

### WORKERS: THIS OVERRIDES YOUR BRIEF
Your standing prompt tells you to take the FIRST unchecked item in your section. WHILE PHASE RC IS
OPEN, THAT RULE IS SUSPENDED. Take the first PHASE RC item you own instead, wherever it sits in
this file - search the file for its ID. Only if you own no open RC item do you fall back to your
brief's first-unchecked rule. Say in your summary which RC item you took and why, or that you had
none and fell back.
SUPERVISOR: each run, also physically move the open RC items toward the top of their sections, so
a worker that misses this note still lands on the right work.

### STATUS OF THAT BLOCK (supervisor, 2026-11-15 15:58 CT)
Mr. E stood up a FIFTH worker on 15 Nov 15:41 - the ART lane, on branch `art`, worktree
C:\hd adventure\bellmire-art. It does not run Godot, holds no RUN_LOCK, renders in parallel, and its
queue is D75 (the eight lords), D73 (icons for all 454 items) and D76 (monster variety). That lane answers
the art half of the gap. IT DOES NOT ANSWER THE LAPTOP-CODE HALF: L56, L68, L69, L70, L55 and D64.3/.4
are still owned on paper by the retired jestai worker and are still unstartable. Three of the four
"THE CHANNEL" RC items (L68, L69, L70) are in that set. The decision below is still outstanding.

### BLOCKED, NEEDS MR. E: FOUR PHASE RC ITEMS HAVE NO WORKER (supervisor, 2026-11-15 15:05 CT)
This is a report, not a reassignment - the supervisor is not changing anyone's ownership here.
L56, L68, L69 and L70 sit in PHASE RC above, and the remainder of D64 (.3 and .4) depends on the
same files. All of them are marked "Owner: LAPTOP CODE" - worker 3 in COORDINATION 11.1, which ran
on the jestai laptop. jestai was retired on Nov 15 and only four workers were recreated on
cruzader: game build, content writer, hub build and HUD. Worker 3 was never rebuilt, so the files
it owns (floorgen, dungeon_parts, dungeon_hd, bestiary, monster, gear, roster, chatcmd, delve,
Dungeon.tscn, and data/ except the four content files) have an owner on paper and nobody to do the
work. These items are unstartable rather than merely unstarted, and the game build worker's own
D64a note says so in as many words. L55's gear-tier bug has been unowned since the D28 census for
the same reason. Mr. E's call: either widen the game build worker's ownership to cover those files
(it already works on branch `laptop`, so no branch move is involved), or stand up a fifth worker
for them. Until he decides, every worker should skip these and take the next RC item it does own.

### THE RULE THAT MAKES THIS WORK
WHILE ANY PHASE RC ITEM IS OPEN, DO NOT WRITE NEW ITEMS unless a worker has NO RC item it can take
AND no open item at all. The "write new work when a queue runs dry" instruction still stands - it is
now subordinate to this. Depth is not cancelled, it is deferred: everything outside Phase RC stays
in this file and gets built after, or when Mr. E asks for it by name.
Do not re-scope or renumber anything to fit this. IDs stay frozen.

- [ ] D72. REBUILD BELLMIRE'S SOUND ON MUSIC-STUDIO 3.5.15 (supersedes the old D38 recipe; D38's
      beds stay wired and streamable until this lands). Owner: DESKTOP BUILD (sfx.gd and the
      generator tool) with the music-studio repo READ-ONLY as always - run it in place, copy WAVs
      out, never modify it.
      GREEN LIT. Mr. E confirmed Nov 15 16:41 that the studio upgrade is FINISHED and the
      regeneration pass is to go ahead. This is no longer waiting on him - BUILD IT. His ear is
      still final on the result: generate, wire, and bring him the tracks to judge. Do not tick
      D72 until he has listened and said yes.
      MR. E UPGRADED THE TOOL (Nov 15, v3.5.2 -> v3.5.15) and everything that blocked the first
      attempt is fixed. Read its own docs first; do not assume the old API:
        - 3.5.3 a truly headless compose path - no vite, no CDP, no browser. Use it.
        - 3.5.4 the bias knobs now survive compose(), so describe()/exportWav() agree.
        - 3.5.5 tempoByMood + intensity-based mood scoring - THE RAID CUE CAN NOW PASS. The old
          "epic_cinematic can never satisfy hype" compromise is dead; do not carry it forward.
        - 3.5.6 compose --stems: vertical layers with an intensity manifest.
        - 3.5.7 long-form variations sharing key, tempo and motif, with seam-checked loops.
        - 3.5.8 a project JSON pinning key and tempo family across every cue.
        - 3.5.9 a leitmotif quoted across town/night/combat treatments.
        - 3.5.10 transition bridges; 3.5.11 hill-climb seed search toward the scorers.
      .1 ONE PROJECT, ONE KEY, ONE MOTIF. Define Bellmire's own melodic phrase once and pin the
         project key and tempo family, so day, night, raid and delve are the same place in
         different weather rather than four unrelated cues. This is the point of the rebuild.
      .2 STEMS, AND WIRE THEM. Render layers, then change sfx.gd from crossfading whole TRACKS to
         fading LAYERS - the music thickens as the town fills or a raid builds. Keep the existing
         whole-track path as the fallback when stems are missing.
      .3 VARIATIONS SO A LONG SESSION DOES NOT REPEAT. Several renderings of each cue, shuffled.
      .4 REGENERATE EVERYTHING on the new tool, including the raid cue at a tempo that passes.
      .5 THE SPEECH POCKET STILL RULES. Every bed keeps its 300-3000 Hz speech-room verdict - Mr. E
         talks over all of it. Record each cue's mood and speechRoom numbers in PROGRESS.md.
      HE HAS THE FINAL EAR: deliver the files for him to listen to and DO NOT TICK THIS until he
      approves them. He declined to approve the first set precisely so they could be redone here.
      DONE: a project with key, tempo family and leitmotif; stem-wired transitions proven in a
      capture; variations shuffling; every bed's speech room passing; Mr. E's approval recorded.

## MR. E'S ASK, Nov 15 15:30 - "GET ALL OF IT BUILT, HAVE ALL OF THEM BECOME THEIR OWN ITEM
## INSTEAD OF A NAME"

THE MEASURED PROBLEM (audited 15 Nov from the shipped data):
  - 230 accessories have NO art at all - no model, no colour. Every ring, amulet, cloak, boot and
    glove is a name, a cost and a stat. A viewer who buys the Ring of the Night Watch sees nothing.
  - 224 hats and banners carry a COLOUR only, no mesh of their own.
  - 183 titles are text, which is correct and not a gap.
  - Weapons and armour SHARE geometry; gear.gd separates top tiers by size and glow, not by shape.
  - The project holds 254 models and NONE of them is a ring, amulet, cloak, boot, glove or hat.
    assets/gear has 32 weapons and tools; props, nature, fishing, dungeon and animals cover the
    rest. There is no existing art to lean on for this.

SEQUENCING - READ THIS BEFORE STARTING EITHER ITEM. Neither D73 nor D74 is in PHASE RC. Mr. E asked
for completion at 14:50 and for this at 15:30; taken literally, doing these first DELAYS the
finish line. So: D73 may be worked when its owner has NO open RC item. D74 does not start until
Phase RC is closed, OR Mr. E says in writing to bring it forward. Do not quietly start D74 because
a queue looked thin.

- [ ] D73. EVERY ITEM GETS A FACE - PROCEDURAL ICONS FOR ALL 454 (the cheap half, do this one
      first). Owner: DESKTOP BUILD, with a generator tool checked into tools/.
      An icon is not a worn model. It is a small rendered image that identifies an item wherever it
      is NAMED - the hub's Satchel and hero sheet, the shop, the Chronicle, chat's answer to a
      !hero. It costs a fraction of D74 and removes most of the "it's just a name" problem.
      HOW, and this is the point: generate them PARAMETRICALLY in headless Blender from each
      item's OWN data, so 454 icons do not need 454 sculpts. A base shape per slot (ring, amulet,
      cloak, boots, gloves, hat, banner), varied by the fields the item already carries - cost
      drives ornateness and material, `colour` drives the palette where present, the slot drives
      the silhouette, and a hash of the item key picks among a handful of shape variants so two
      rings are not the same ring. Render on transparent, one PNG per item, checked in.
      PROVEN APPROACH, use it: headless `blender -b -P <script>` in a SEPARATE process. Never
      drive Mr. E's open Blender session. Two traps found the hard way on 15 Nov, both real:
        - The animal models are authored at ~700-unit scale while gear sits near 2. A camera with
          the default clip_end of 100 renders them as EMPTY transparent images and reports success.
          Set clip_start/clip_end from the measured bounds, always.
        - Do not embed the same image many times as base64 in one document; reference files.
      DONE: a PNG for all 454, none blank (assert opaque pixel count > 0 for every file - that is
      the check that would have caught the three empty renders), a contact sheet to look at, and
      the hub showing an icon beside an item in a hero's Satchel.
  ART HALF DELIVERED (art lane, 2026-11-15, commit 61df0e8): 454 procedural icons generated in headless
  Blender from each item's own fields, every PNG re-opened and asserted non-blank, contact sheet looked at.
  STILL OPEN, and it is the rest of this item's DONE line: an icon shown beside an item in a hero's Satchel.
  That is publisher + hub work and it waits for Phase 4 / its lane, not for the art worker.

- [ ] D74. ITEMS YOU CAN SEE ON THE HERO (the expensive half - DO NOT START until Phase RC is
      closed or Mr. E brings it forward in writing). Owner: DESKTOP BUILD (rig.gd, hero_body.gd)
      with laptop code for the dungeon side.
      This is what "their own item instead of a name" means in full: a cloak that hangs, a hat that
      sits on the head, boots and gloves that move with the body, a ring that is visible when the
      camera is close. It is a MUCH larger job than D73 and must be scoped honestly:
      .1 BONES AND SLOTS FIRST. The rig already has EQUIP handslot bones (see L30a). Extend to
         head, back/cloak, feet, hands, neck. One attachment system, driven by the item's slot.
      .2 A MESH FAMILY PER SLOT, NOT 454 SCULPTS. Same parametric idea as D73 but producing real
         game meshes: a handful of base shapes per slot, varied by material, colour and scale.
         454 bespoke models is not a realistic target and should not be attempted.
      .3 PERFORMANCE IS THE CONSTRAINT, NOT ART. Up to 24 heroes on screen, each potentially
         wearing five accessories plus a hat. That is 144 extra meshes. D23 is already fighting
         for frame rate. Budget it, LOD it, and hide accessories beyond a distance - measure
         before and after against D23's numbers.
      .4 IT MUST READ AT STREAM DISTANCE. A ring nobody can see at the normal camera height is
         wasted work. Decide per slot what is worth rendering at all; cloaks and hats read, rings
         may only read in a close pane.
      DONE: a hero wearing a cloak, hat, boots and gloves, visible in a 1080p capture at normal
      stream distance; a crowd capture with 20+ equipped heroes holding D23's frame rate; and a
      stated list of which slots render at which distance.

## THE ART LANE RUNS IN PARALLEL (Mr. E, Nov 15 15:35) - NEW OWNER, NEW BRANCH

His observation, and he is right: making art needs BLENDER, not Godot. So an art worker does not
compete for docs/RUN_LOCK.txt and can run at the same time as the game build and HUD workers.
That roughly doubles throughput on the ~570-piece art backlog without slowing Phase RC.

  OWNER:    ART WORKER
  BRANCH:   `art`     WORKTREE: C:\hd adventure\bellmire-art     (both created 15 Nov)
  OWNS:     assets/** (new art it generates), tools/ art generators, renders/art/**
  NEVER:    launches Godot. Never reads, writes or respects RUN_LOCK - it is not in that queue.
  QUEUE:    D75 (the eight lords) -> D73 (icons for all 454) -> D76 (monster variety). D74 waits
            for Phase RC to close.

MR. E'S RULING (15 Nov 15:40) - THE ART LANE NEVER THROTTLES ITSELF. "I don't care if we go up to
200 fps, my machine can handle it." So the art worker renders whenever it likes, including while a
performance soak is running. It does not read RUN_LOCK at all.
THE MEASUREMENT POINT STILL STANDS, but it cuts the other way and belongs to the GAME BUILD worker,
not to art: a soak that PASSES while Blender is rendering on the same box is a STRONGER result than
a clean-room pass, because the game held frame rate under load. Only a FAILED soak is ambiguous -
if D23 or L56 fails, the game build worker re-runs it when the machine is quiet BEFORE anyone acts
on the number. Nobody idles waiting for anybody.

SUPERVISOR: merge `art` like any other branch, tick its items, and sync the plan to it each run.

## MR. E'S PRINCIPLE, Nov 15 15:33 - BINDING ON EVERY WORKER AND ON THE SUPERVISOR

  "go through everything - designs, game designs, bosses, monsters, items, equipment, cosmetics,
   animals, everything - and make sure they all have their designs, not just spoken in name.
   PEOPLE WANT TO SEE WHAT THEY PAY FOR, NOT JUST A STAT."

This is a product rule, not a task. From now on: NOTHING A VIEWER CAN SPEND ON OR MEET SHIPS AS A
NAME AND A NUMBER. If a thing can be bought, worn, fought or found, it must be visible as itself.
When you write a new item of content, say what it LOOKS like, not only what it does. When you
write a new work item that adds content, include how it will be seen.

### THE ART CENSUS, measured 15 Nov - this is the true scale of the ask
| What | Entries in data | Distinct models | Gap |
|---|---|---|---|
| Accessories (ring/amulet/cloak/boots/gloves) | 230 | 0 | 230 |
| Hats and banners | 224 | 0 (colour only) | 224 |
| Monster families | ~109 | 10 | ~99 |
| Lords (4 lesser + 4 greater) | 8 | 0 bespoke | 8 |
| Lord uniques | 270 | variants of the above | - |
| Pets | 30 | 9 | - |
| Weapons / armour tiers | 12 | shared geometry, size+glow | - |
| Buildings | ~16 kinds | 12 | a few |
Roughly **570 distinct pieces of art** do not exist. The project holds 254 models in total today.

### THE FINDING NOBODY HAD WRITTEN DOWN
**Your bosses are wearing hero bodies.** bestiary.gd builds a lord's model as `ADVC + body + ".glb"`
from the ADVENTURER character set - and falls back to `Roster.CLASSES[cls]["model"]`. The Hollow
King, Grubmother, Rattling Host, Nightwing, Gravewyrm, Ossuary Lord, Pale Duchess and Mourncoil
are all reskinned adventurers. Every one of the 270 uniques inherits that. The biggest moment in a
delve - a lord rising - is a hero model with a different name over its head. Fixing those EIGHT is
the highest value-per-unit art in the whole project, and it is a small number.

### HONEST SEQUENCING - the supervisor must not pretend this is small
Taken in full this is LARGER THAN EVERYTHING IN PHASE RC COMBINED. It is the rest of the project,
not a sprint. So it is ordered by what a viewer actually sees, most-seen first:
  1. D75 THE EIGHT LORDS - bespoke, bought with the most viewer attention per asset.
  2. D73 ICONS FOR EVERYTHING NAMED - cheap, parametric, covers all 454 items at once.
  3. D76 MONSTER VARIETY - ~109 families sharing 10 models is the most-repeated visual in a delve.
  4. D74 WORN ITEMS ON THE HERO - the expensive one; after Phase RC.
ASSET CONSTRAINT, do not forget it: CC0 only (Quaternius, KayKit, Kenney) with a LICENSE note, and
**Quaternius Bestiary / QAL is FORBIDDEN** - which is exactly the pack that would have solved the
monsters. Procedural generation in headless Blender is therefore the main route, not asset hunting.

- [ ] D75. THE EIGHT LORDS MUST LOOK LIKE LORDS. Owner: DESKTOP BUILD (bestiary.gd model path,
      rig.gd) + a generator in tools/. Eight bespoke silhouettes - Hollow King, Grubmother,
      Rattling Host, Nightwing, Gravewyrm, Ossuary Lord, Pale Duchess, Mourncoil - each readable
      as ITSELF at stream distance, built from their written canon in bosses.json and lore_lines.
      Not a reskinned adventurer. Their 270 uniques then read as variants of a real thing.
      This is the single highest-impact art item in the plan: eight assets, maximum viewer
      attention, and it makes every boss encounter land.
      DONE: eight 1080p captures at stream distance, each lord distinguishable from the others and
      from any hero, with the Chronicle naming it; D23's frame rate held in a delve soak.
  ART HALF DELIVERED (art lane, 2026-11-15, commit 82a3463): eight bespoke lord meshes built from their own
  canon, each at most four meshes/materials (727-6343 faces) so one boss is not 107 draw calls, camera clip and
  distance taken from evaluated world bounds, every render asserted non-blank. See renders/art/lords/ and
  docs/art/LORDS.md, which states the BOSS_DEFS model-path change for the owner of bestiary.gd.
  STILL OPEN: the in-game half - wire the model paths, then the eight stream-distance captures with the
  Chronicle naming each lord, and D23's frame rate held in a delve soak. These meshes are static and carry no
  armature, which the wiring owner must plan for.

- [ ] D76. ~109 MONSTER FAMILIES SHARE 10 MODELS. Owner: DESKTOP BUILD + laptop code (bestiary.gd).
      A delve is the most-watched thing on the stream and it is ten creatures wearing many names.
      Build a parametric creature system - body plans varied by size, limbs, colour, texture and
      silhouette, driven by the family's own written description - so a scarrat is not a rat with
      a different label. Do NOT attempt 109 sculpts.
      DONE: a 10-floor soak capture where consecutive floors are visibly different; a contact sheet
      of every family; frame rate held.
  ART HALF STARTED (art lane, 2026-11-15, commit 96af851): twelve families that were another creature with a
  label now have their own bodies, from a parametric creature generator in tools/art/ (no sculpts). The lane's
  own census corrected this item's headline number - see its note.
  STILL OPEN: the remaining families, and the in-game half of the DONE line (a delve capture where consecutive
  floors read as different, a contact sheet per family, frame rate held).

## DESKTOP PRIORITY — VISIBLE JANK (Mr. E: do these FIRST, before any other D-item)

- [x] D57. PUBLISH HERO SATCHEL FIELDS IN SNAPSHOT v=3 (Mr. E's ask, Nov 15 - URGENT; blocks the hub Satchel from lighting up). Owner: DESKTOP BUILD (scripts/snapshot_pub.gd). The hub's H11 Satchel panel is live and dormant, waiting for the snapshot publisher to add per-hero sellable items with counter sell prices and bump the payload version to 3. Add two fields per hero to the published row: `sellable` (array of {kind, qty} - kinds from the existing ICON_SET whitelist Chest/Vial/Scroll/Fish/Coin/Gem/Herb/Bone/Cloth/Ore/Spark/Wood) and `sell_prices` (parallel array of ints, in gold, computed from the counter's buy curve, usually half). Keep the publisher's control-char strip and name cap on every string. Bump the published `v` field from "2" to "3". No new fetch, no secret exposed, additive only - older hub clients still render the hero sheet without the Satchel block (H11 is forward-compatible). DONE: the hub at https://jestsayin96.github.io/Bellmire-HD-stream/ shows a Satchel section under a signed-in viewer's hero with items + prices; W1a sanitization still green; snapshot_pub stays under the size cap.
  RESULT (2026-11-15): snapshot_pub.gd publishes v=3 with per-hero `satchel` [{name,kind,qty,sell}], `satchel_total`, and the parallel `sellable`/`sell_prices`; worn weapon/armour carry a `sell` when their tier has a price. Price is the counter's own floor(cost*0.4) (leaderboard_panel Satchel.SELL_BACK), NOT half - see the note below. The live hub renders it: Satchel list + "Counter pays 576 gold" on a test hero, and nothing at all for a hero carrying nothing. D57_SATCHEL OK (23/23), W1A_TEST OK, TWITCH_PARSE OK, offfloor 0/1217, TOWNWALK PASS, delve 0 SCRIPT ERROR, parse 0 errors, payload 7.5 KB.
  NOTE FOR MR. E - the written spec and the shipped hub disagreed; the code follows the SHIPPED hub (web/app.js H11), which reads `h.satchel` rows and maps `kind` through SATCHEL_ICON (weapon/armour/potion/oil/gold/trinket/loot/gem). The ICON_SET named in the item (Chest/Vial/Scroll/Fish/...) does not exist anywhere in the hub, and `sellable`/ `sell_prices` alone would have rendered nothing. Both shapes are published, so either client works.

- [x] D59. THE HERO SHEET NEEDS A CHARACTER SHEET TO READ - PUBLISH THE D&D BLOCK AT v=4 (supervisor,
      2026-11-15, straight out of the hub's own NOTES; this is the D57 situation again - a shipped hub
      section is sitting dormant waiting on the publisher). Owner: DESKTOP BUILD (scripts/snapshot_pub.gd,
      plus whichever of YOUR OWN files already hold the numbers). H20 shipped the hero sheet on the hub:
      identity, conditions, abilities, combat, nine gear slots, a personal chronicle. Today most of those
      cells render as honest dashes because the snapshot does not carry the fields. Fill the sheet in.
      READ web/NOTES.md section "H20" FIRST - it lists every field the page wants and every alias it will
      already accept, so you do not have to guess a key name. Additive and forward-compatible: bump the
      published `v` from "3" to "4", keep every v=3 field exactly as it is, keep the W1a control-char strip
      and the 25-char name cap on every string, and keep the payload under its size cap (state the KB).
      .1 VITALS AND PROGRESSION. Per hero: `max_hp` (so the hub can draw a real vitality bar instead of a
         flat one), `xp_next`, and `stats` {str,dex,con,int,wis,cha} present on EVERY hero including a
         freshly rolled one - today they appear only once a hero has been somewhere. Then the combat block
         the sheet already has cells for: `ac`, `hp`, `to_hit`, `prof`, `saves`, `initiative`, `speed`.
         Publish what the game actually computes. If a number does not exist in the game yet, DO NOT invent
         it and do not derive it on the publisher's side - leave the field out so the hub keeps drawing an
         honest empty cell, and name it in your summary. A guessed stat on a 24/7 stream is worse than a dash.
      .2 WHAT A HERO IS WEARING AND WHAT THEY ARE DOING. Publish `gear` as an object keyed exactly
         main_hand, off_hand, head, body, hands, feet, cloak, neck, ring (string or {name}). Only main hand
         and body exist today; send the slots that are real and OMIT the rest - an omitted slot draws as an
         empty slot, which is the truth, while an empty string would read as a bug. Also per hero: `status`
         (resting / in town / delving / wounded / fallen - the state the game already knows, not a new
         system) and a per-hero last-seen timestamp, because the whole-snapshot `updated_at` is all the hub
         has and it cannot tell a hero who acted a second ago from one who has not moved in an hour.
      .3 A PER-HERO EVENT FEED, so the personal chronicle stops being a string match. The hub currently
         builds "their own chronicle" by scanning Chronicle lines for the hero's name as a whole word,
         which silently misses every line that refers to them any other way. Publish a short per-hero
         ring of their own events (deepest run, notable kills, deaths with the day, level-ups, finds) -
         capped, newest-first, oldest dropped, sized so the payload stays under cap with a full roster.
      DONE (one test, all three stages): with the publisher on and a full roster, a 10-minute run, then a
      capture of the LIVE hub hero sheet for (a) a kitted veteran and (b) a freshly rolled hero, showing
      Abilities and Combat filled with real numbers on both, the gear slots that exist resolved and the
      rest drawn empty, a status and a per-hero last-seen reading correctly, and the personal chronicle
      populated from the published feed rather than from name-matching. Plus: W1A_TEST OK, TWITCH_PARSE OK,
      parse 0 errors, payload KB stated and under cap, and a v=3-era client still renders the hero sheet
      (additive check). State in your summary every field from the NOTES list you deliberately did not
      publish and why.
  PROGRESS (game build, 2026-11-15 ~09:30 CT, committed): every sheet field the game computes is published
  (initiative, speed, gear by real slot, status, last_seen, per-hero `events` ring; stats/max_hp/xp_next/combat were
  already there for every hero). D59_SHEET OK, gates green, 244 KB at 202 heroes. v HELD AT 3 (PAYLOAD_V): the hub's
  KNOWN_V refuses "4" - BLOCKED ON THE HUB: add "4" to KNOWN_V, read h.last_seen + h.events, and fix two H20 render bugs
  (gear slot text never appended; "[object SVGSVGElement]" in the card head). See PROGRESS D-cycle D59a.
  UNBLOCKED 2026-11-15 ~11:00 CT (supervisor): the hub shipped H23 (c19608c, merged to main) - KNOWN_V now accepts
  "4" and the sheet reads h.last_seen and h.events. NOTHING on the hub side is outstanding. All that is left of D59
  is to flip PAYLOAD_V from "3" to "4" and run the DONE capture: the live hub hero sheet for a kitted veteran and a
  freshly rolled hero. This is the FIRST thing the game build worker should do - the fields have been on the wire
  since 09:30 and the sheet is still drawing dashes over them.
  PROGRESS (game build, 2026-11-15 ~11:20 CT, D59b): PAYLOAD_V FLIPPED TO 4 and committed - checked the LIVE
  github.io app.js first (KNOWN_V = 1,2,3,4), so this cannot blank the hub. The v4 payload rendered through the
  current hub page: veteran + fresh hero both show Abilities/Combat with real numbers, Initiative/Speed, IN TOWN +
  "Last seen N minutes ago", real gear slots filled and the rest empty, and "Their own chronicle" from h.events
  (renders/cycles/d59/sheet_render_v4.png, 0 page errors). Gates green. STILL OPEN, only this: the DONE capture of
  the LIVE hub after a 10-min run with the real roster - not run outside the stream (it would play roster.json
  live). The next time the game runs, the live hub reads v4 with no further change from anyone.
  RESULT (2026-11-15 12:30 CT, laptop dea57ed/bc2e715): PAYLOAD_V flipped 3 -> 4; every v4 sheet field has been on
  the wire since D59a. Verified by rendering the v4 payload through the LIVE web/ page (headless Chromium, supabase
  fetch intercepted): veteran Brannoc and fresh Isolde both show Abilities + Combat numbers, Initiative/Speed, an IN
  TOWN chip, "Last seen 3 minutes ago", gear slots that exist filled and the rest drawn empty, and their own chronicle
  built from h.events - renders/cycles/d59/sheet_render_v4.png, 0 page errors. Worker read the live github.io KNOWN_V
  before flipping. D59_SHEET OK 20/20, D57_SATCHEL OK, D60_CHRON OK, W1A_TEST OK, TWITCH_PARSE OK, parse 0 errors,
  payload 8.0 KB / 189 KB at 202 heroes. TICKED: the code is complete and proven against the real page. The one
  remaining line of the DONE text - a capture off a live 10-minute stream run - needs no further code and happens on
  Mr. E's next stream; NO WORKER SHOULD RE-TAKE THIS ITEM. Hub-side nit (not D59): a fresh hero's MAIN HAND reads
  "Bare Hands · 1d4" from the hub's h.weapon fallback though the publisher omits main_hand - truthful, left alone.

- [x] D60. DATE THE CHRONICLE BY THE TOWN'S OWN CALENDAR, AND SAY WHO A LINE IS ABOUT. Owner: DESKTOP BUILD
      (scripts/snapshot_pub.gd and whichever of your own files raise Chronicle lines). H21 shipped the hub's
      campaign journal on 2026-11-15 and it had to invent its own clock: chronicle lines carry no town day,
      so the journal groups by a wall-clock session heuristic (a 90-minute gap starts a new stretch), and it
      has no structured subject, so the per-hero filter falls back to matching the hero's name as a whole
      word in the line's text - which silently misses every line that refers to a hero any other way.
      The game knows both. Publish them, additively, on each chronicle entry:
      .1 `day` - the town's own day number at the moment the line was raised, so a stretch of the journal is
         "Day 41" rather than "Earlier today". Publish the day the game actually keeps; do not derive a day
         from a timestamp on the publisher's side.
      .2 `who` - the hero (or heroes) a line is about, as the roster key/name the hub already uses for a
         hero, and `kind` - the line's event kind from the set the game already raises (raid, disaster,
         festival, death, delve, growth, find, ...). Omit a field on a line that genuinely has no subject or
         no kind; an omitted field draws as the honest fallback, an invented one is a lie on a 24/7 stream.
      Forward-compatible and additive: a hub that does not know these fields must render the Chronicle
      exactly as it does today, and the payload stays under its size cap (state the KB - D59a is already at
      244 KB with 202 heroes, so state the delta and trim the ring if it threatens the cap).
      DONE: a 10-minute run with the publisher on, then the published row showing `day`, `who` and `kind` on
      the lines that have them and cleanly absent on the lines that do not; a stated payload KB before and
      after; W1A_TEST OK, TWITCH_PARSE OK, parse 0 errors; and the live hub's Chronicle still rendering
      correctly with the hub as it stands today (the hub's own adoption of these fields is a later H item).
  RESULT (game build, 2026-11-15 ~10:30 CT): every Chronicle row now carries `day` (economy.day - the day the raiser
  stamped, else the day the publisher first saw the line, scanned each second); `kind` and `who` ride ONLY on lines a
  raiser tagged through the new town.tag_feed(kind, [heroes]) - raid, disaster, day, hunger, treasury, growth,
  festival, caravan, watch, arrival, death (townsfolk), find (catch), rally, delve (at the mouth). Untagged lines have
  neither field (no publisher-side name guessing). v stays 3, payload +23 B/row (worst case +7.3 KB for a full ring).
  D60_CHRON OK, W1A_TEST OK (check 21 now types the new fields), D59/D57 OK, TWITCH_PARSE OK, parse 0.
  GAP: hero lines raised by laptop-owned delve.gd / chatcmd.gd (deaths below, kills, finds in the dark) are untagged
  until laptop code adds one town.tag_feed(...) call beside its feed.append - see PROGRESS D60.

- [x] D58. THE TOWNSFOLK LOOK LIKE THEY ARE STRUGGLING TO WALK (Mr. E, Nov 15, watching the stream:
      "all the characters in the game looked like they were having trouble walking"). Owner: DESKTOP
      BUILD (townsfolk.gd, rig.gd, hero_body.gd, town_nav.gd).
      THIS IS A DIFFERENT BUG FROM THE THREE ALREADY ON THE BOARD - do not close it by re-fixing those:
        * D50 (ticked) was agents FROZEN and their anim stuttering - missing callers. Fixed.
        * D44/D50 (open) is agents WEDGED against props and stopping. A pinned agent.
        * D52 (open) is the hero never pathing to the dungeon mouth. A state bug.
        * D58 (this) is GAIT QUALITY on agents that ARE walking normally. They move from A to B
          fine - they just look WRONG doing it. Nothing currently owns this.
      LIKELY CAUSES, in the order worth checking (measure before changing anything):
        1. Animation playback rate is fixed while nav velocity varies, so feet slide across the
           ground instead of planting. This is the classic cause and the most likely one here.
           Drive the walk AnimationPlayer/AnimationTree speed_scale from the agent's ACTUAL
           per-frame velocity, not from a constant.
        2. No blend between idle / walk / run - agents snap between clips instead of easing, which
           reads as lurching.
        3. No turn-in-place: an agent changing direction slides through the turn while the walk
           cycle keeps playing forward.
        4. Nav agents arriving with tiny residual velocity, so the walk clip plays at a crawl near
           waypoints and looks laboured.
      Fix the ones the measurement actually implicates. Do not rewrite the rig.
      DONE: a 1080p capture of the market square with at least 15 townsfolk walking at once, plus a
      logged check that animation speed tracks agent velocity (print velocity vs speed_scale for 10
      agents over 30 s - they must correlate, not sit flat). In the capture: no foot sliding, no
      snapping between clips, turns read as turns. Mr. E's bar for this one is WOW, not "oh".
  RESULT (2026-11-15): measured first (tools/_d58_gait_probe.gd). Cause #1 was NOT it - speed_scale already
  tracked velocity and feet were planted (slip ~1.0). The real cause: ordinary folk cruised at 1.6-1.9 m/s, so
  the 0.8 m/s KayKit walk played at ~2.0x (476/481 walk samples over 1.5x - a frantic double-time shuffle),
  and that cruise speed sat INSIDE the walk<->jog hysteresis band (23 walk/jog clip flips in 30 s, 10 agents).
  Fix (townsfolk.gd only, rig untouched): walkers - not flees, not runners set over 2.4 m/s like the watch -
  stroll at Townsfolk.stroll 0.66 of that (~1.1 m/s), via one _step_v() used by the step, the slide-round and
  the stuck check. After: walk cadence 1.22-1.41x, corr(v, speed_scale) 0.73 (was -0.01, pinned at the cap),
  slip>25% 1/588, 0 clip flips, 0 jog samples. 1080p market shots: 19-24 folk walking near the square
  (renders/cycles/d58/). Gates: parse 0, offfloor 0/1483, TWITCH_PARSE OK, TOWNWALK PASS 0.012%, delve 0 SCRIPT ERROR.
  Stills cannot show a stride - Mr. E's eye on the stream is the WOW check; Townsfolk.stroll is the one dial.

- [x] D50. TOWNSFOLK FREEZE AND THEIR ANIMATION STUTTERS. Owner: DESKTOP BUILD (townsfolk.gd,
      town_nav.gd, rig.gd). Two joined symptoms Mr. E saw: (a) NPCs standing frozen - "hasn't moved
      from his spot, a lot of them aren't moving"; (b) the ones that do move stutter / animate
      badly. This is "the town isn't alive" made concrete.
      STRONG DIAGNOSTIC LINK: a townsperson frozen in place may be the SAME walker D44/D44b flags
      as in_solid / stuck - a walker wedged in geometry stops moving AND stops its walk cycle. Check
      whether the frozen NPCs correlate with the in_solid samples before treating these as separate.
      If a townsperson has no nav target or a blocked path it idles forever - give idle NPCs
      somewhere to go (work, wander, gather) on a cadence, and make sure the walk/idle animation
      actually plays (the census showed anims fire, so a FROZEN one is likely a stuck agent, not a
      missing clip). The stutter may be the sub-res pane (see D49) OR a real animation hitch - say
      which once D49's AA work lands, so they are not conflated.
      DONE: a town soak where NPCs visibly wander/work with smooth animation, in_solid at 0, and a
      pane crop Mr. E signs off.
      RESULT (D-cycle D8): MEASURED first - a 93 s probe found 111/126 ordinary townsfolk move
      >8 m and in_solid is ~0, so there is NO widespread nav-freeze; the only stuck bodies were 7
      NAMED NOTABLES holding posts (Cort Rivers the Crier, the watch, gate guards) - notables.gd
      sets stay=false so they fell into the normal idle branch and stood in a DEAD Idle instead of
      the rich _posted pace/look/gesture. FIX (townsfolk.gd): (a) _idle_acts now gives EVERY standing
      idler an occasional calm gesture (POST_GESTURES) instead of returning - a body loitering away
      from the market/tavern/job is no longer a frozen statue; (b) the LOD stutter diagnosed: past 60 m
      the nav throttle also advanced the ANIMATION in 2-4 frame chunks - the clip now advances every
      frame for the clearly-visible lod-1 band (60-120 m), lod 2 stays chunked for the FPS budget.
      Gate GREEN: --import clean, parse 0, _offfloor 0/1486, TWITCH_PARSE OK, _delve_test clean,
      _townwalk in_solid 0/16518 (0.000%) PASS (nav unchanged/better). Windowed crop renders/cycles/d50
      LOOKED at: a lively midday square, varied poses, the crier at his post. HONEST CAVEAT: a STILL
      cannot prove animation SMOOTHNESS or that a fidget fired - the stutter fix + the gesture life need
      Mr. E's eye on live motion. The 7 posted notables now WORK their post (gesture), they do not wander
      (a crier/guard SHOULD hold post); a tried wander fallback was reverted as wrong for them.

- [x] D53. TOWED / HELD OBJECTS ARE NOT ATTACHED TO THEIR OWNER. Owner: DESKTOP BUILD (rig.gd / the
      equip + attach system). Clip 14-31-18: "the cart is moving on its own, I'm assuming it's
      supposed to be attached to this guy, but it wasn't." A CART that an NPC should pull drifts on
      its own, detached. Same family as D51 (the fishing pole not in the angler's hand): objects
      that should be parented to an owner's bone/transform are not. Fix the attach so a cart follows
      its hauler and a pole sits in the hand. Audit for other detached props (market goods, tools).
      DONE: a capture of a cart moving WITH its hauler and the pole in-hand, Mr. E signs off.
      RESULT (D-cycle D9): towed-wagon attach FIXED in townsfolk.gd - the follow is keyed off the
      OWNER-to-cart distance, so a jump (door exit, respawn, raid reset, stop moved, far-LOD chunk)
      reattaches the wagon AT ONCE behind the hauler instead of letting it glide off; it tows at 2.6 m
      and re-parks beside a stopped owner. Covers carters, the caravan master and the pedlar (all use
      .cart). _d53_test: travel gap 2.72 m, teleport 22.8 m -> recovered 2.60 m, D53_TEST OK; render
      renders/cycles/d53/hauler_cart.png. THE POLE IN-HAND stays D51 (angler.gd, not this worker's file).

- [x] D54. NPCs VANISH AFTER ENTERING A BUILDING. Owner: DESKTOP BUILD (townsfolk.gd). Clip
      14-29-22: "they went in. But now I can't find, I can't see them." Townsfolk enter a building
      and cannot be found again - either they despawn on entry, or they are culled/parked somewhere
      the panes cannot reach, so the subject pane loses them for good. Decide the intended behaviour
      (do they come back out on a timer? the D20b flee logic already ducks folk indoors and brings
      them back - does the ORDINARY enter-building path do the same?) and make sure a watched NPC is
      recoverable. DONE: a soak where NPCs enter and later re-emerge, and a pane following one does
      not permanently lose it.
      RESULT (D-cycle D10): FIXED in townsfolk.gd. The enter-building path already re-emerged folk
      (step back out through the door after _wait), but the DAYTIME indoor dwell was randf(18-45) s
      (a probe measured 59 s), long enough that a pane following an NPC lost it. Capped the daytime
      stay to INDOOR_MIN..MAX (7-14 s) - the deliberate night sleep (a long _linger) is left alone.
      _d54_test (midday soak): 41 enter / 47 exit, max indoor 13.7 s (was 59.5 s), 0 stuck. Streets
      read livelier (render renders/cycles/d54/square_midday.png). The street-cap _keep_indoors
      population (off-street by design) is unchanged.

REINFORCED, not re-logged:
  * L62 (pane lane titles) - Mr. E, verbatim: "I don't even know what window this is. Is it a
    subscription... channel... bits?" This is the STRONGEST confirmation yet - a viewer cannot tell
    what to spend on. Bump L62 up the HUD queue; it is core to the spend-prompt model, not polish.
  * D46 (band panel covers the screen) - "look how much it covers, this is what I was talking
    about." Confirmed again; already moving to the hub.
  * D50 (NPCs idle with no purpose) - "all these people just hanging out not doing anything,
    congregating by the thing not doing anything." The idle half of D50.
  * L38 (ambient pane framing) - "bottom right is watching the livestock, it's looking at the ROOF."
    The ambient framing still aims at roofs/empty geometry sometimes. U2 did a first pass; it needs
    another - the ambient subject pick or the camera offset is still landing on non-subjects. Raise
    as a HUD follow-up to L38 when the HUD worker is next free.

CHANGELOG 2026-11-13 14:54 (supervisor): clips 14-29/14-30/14-31. Split the "not moving" bug correctly: D52 =
hero won't delve, stands idle at the well = COMMAND/STATE, LAPTOP; D44/D50 wedging (pumpkins) =
nav, DESKTOP - two bugs, do not conflate (supervisor had over-unified). New: D53 (cart/pole not
attached to owner), D54 (NPCs vanish into buildings). Reinforced L62 (strongest signal yet - bump
it up), D46, D50, L38 (needs a second framing pass).

- [x] D51. THE ANGLER DOESN'T HOLD THE FISHING POLE RIGHT (part of D40). Owner: DESKTOP BUILD. The
      pole is not parented to the hand bone correctly - it floats or sits in the wrong grip. Attach
      it to the right hand bone with the correct offset/rotation, like a weapon equip on the handslot
      bone. Pairs with D40's fishing animation + water work; do them together.
      DONE: a capture of an angler holding and casting the pole from the hand, Mr. E signs off.
      RESULT (D-cycle D11): FIXED in angler.gd. The rod pivot was parented to the Angler at a
      FIXED body offset (0.28,1.05,0.30) - it floated beside the body, never in the hand. Now it
      rides a BoneAttachment3D on the body's right-hand bone (handslot.r), exactly like a weapon
      equip, with a grip rotation (~+30deg about Z) that rakes the tip up and out over the water;
      falls back to the old body offset only if a body has no hand bone, and the attachment is
      freed with the angler (no orphan rod). _d51_test: mount=handslot.r, rod tip is a descendant
      of the body skeleton for both dock anglers -> D51_TEST OK. GATE GREEN: parse 0, _offfloor
      0/1700, TWITCH_PARSE OK, _townwalk in_solid 1/18280 (0.005%) PASS, _delve_test rc0 clean.
      LOOKED (renders/cycles/d51/d51_pole_inhand.png): the rod rises FROM the fisher's hand,
      angled up and out, line running to the water - held, not floating. Mr. E's live sign-off
      is the remaining half.

- NOTE (not an item yet - needs Mr. E): "it only lets me zoom in on the top left." The zoom/control
  appears to work only on ONE pane (the director/main). Open question for Mr. E: does he WANT to
  zoom/control each subject pane independently, or is one-pane control fine and this was just an
  observation? Logged here so it is not lost; the supervisor will raise it and turn it into an item
  only if he wants per-pane control. Owner would be HUD (spotlight.gd) + rts_camera.gd.

Grass: already D45 (reinforced twice now - "so nasty" in two clips). Not re-logged.
Pixelation-on-movement: already D49 from clip 14-26-15. The clip-2 "stuttering" is partly that
(render) and partly D50 (animation) - separated above.

CHANGELOG 2026-11-13 14:51 (supervisor): from Mr. E's transcribed clip 14-27-07 - D50 (townsfolk freeze +
animation stutter, likely tied to D44's stuck walkers), D51 (fishing pole grip, part of D40).
Grass reinforces D45; stutter split between D49 render and D50 animation. One open question logged
for Mr. E: does he want per-pane zoom control.

# Phase AC - *** CRITICAL *** Mr. E's clip 14-28-40: HEROES DO NOT MOVE (2026-11-13 14:52)

His words: "I put it to follow me. My dude's not moving. None of these guys, barefoot Knights not
moving, 96 Knights not moving, Mr. E Ranger is the one I just created, and I am following - I'm not
moving, I told him to go delve, and he has not moved. This needs to be fixed."



Two machines work at once, on DIFFERENT files so they never clash:
- DESKTOP (CruzaderPC, scheduled build runs, branch `main`): the town, its people, magic. Lock: docs/RUN_LOCK.txt
- LAPTOP (jestai, its own Claude Code session, branch `laptop`): monsters, bosses, gear, classes, species.
  Lock: docs/RUN_LOCK_LAPTOP.txt. It pulls `main` and merges it into `laptop` before each item; Claude in the
  main chat merges `laptop` into `main` when an item is tested.

Each run: take the FIRST unchecked item in ITS OWN section. Same loop as before: read the code, edit, parse
check (0 SCRIPT ERROR / Parse Error), the item's test + render + LOOK, the standard checks (_delve_test,
_offfloor, _twitch_parse, _townwalk), tick it here with one line, PROGRESS.md cycle, commit + push
(desktop -> main, laptop -> laptop), lock IDLE.

DnD RULE (Mr. E, Nov 11): the game is D&D at heart - almost every action is decided by a ROLL, not a
flat chance or a fixed number. Attacks: d20 + to-hit vs AC; damage: weapon dice + mod; saves: d20 + save
vs DC; skills (fishing, haggling, tracking, picking a lock, spotting a trap, sneaking, calming a horse,
the town's work) as ability checks d20 + mod (+ proficiency if trained) vs a DC; spells as checks/saves;
initiative; advantage/disadvantage where it fits; nat 20 / nat 1. Use the character's real stats (roster.mod,
roster.prof, save_bonus). Big rolls can show in the Chronicle ("BigAxe rolls a 20!").

LORE RULE: before adding monsters, bosses, classes, species, spells or NPC types, read the original game
(read only) — its bestiary, classes, races and lore files — and use what it already has first. Anything new
must fit its world and be named in its voice. Never state a dungeon floor count.
THE ORIGINAL lives at C:\Users\morta\OneDrive\MortalScorpion\OneDrive\Public\Documents\trial-and-error
(NOT C:\Users\morta\OneDrive\Public, which is an empty stub). Its spells: player.gd fire (38 dmg, 24 m/s,
orange) + frost (24 dmg, 32 m/s, blue), cast from +1.1 m, 1 m ahead; NOTES.md LORE BIBLE: scar misfire rule.
ASSETS: free CC0 only (Quaternius, KayKit, Kenney), downloaded into assets/<kind>/ with a LICENSE note.
Note: Quaternius "Bestiary" packs are NOT CC0 (QAL licence) - skip them.

## DESKTOP (town, people, magic) — files: town.gd, townsfolk.gd, town_nav.gd, spells.gd, raids.gd, daylight.gd, sfx.gd
- [x] D1. Phasing through buildings, for good: find every way people still walk through houses (routes
      that skip the navmesh, spawn/exit inside footprints, heroes' own movement, raiders, settlers, the
      town band). Every walker uses the navmesh; doors on the street side; local avoidance between people.
      tools/_townwalk.gd must report in_solid under 0.2% and a render must show it.
      DONE cycle 58: in_solid 0/6999 (was 64/7194 = 0.89%), raiders+defenders 0/4911, doors 67/67 reachable; renders/cycles/20261111_d1.
- [x] D2. Spells aimed at the sky: bolts fly up at the ceiling/sky and still hit (the "4th of July").
      Fix the aim (source at the caster's hands, target the foe's chest, flat arc), give each spell a
      readable travel + impact. Then NEW spells from the lore for the caster classes (heal over time, ward,
      chain bolt, fire burst, frost slow, smite) wired into delve and raid combat. Render a fight and look.
      DONE cycle 59: cause = health bars counted in Monster._height(), so bar and bolt aim climbed every frame;
      HealthBar3D holds its height, Spells aims hands->chest (cap 2.4 m), flat arc; chain/fire/frost/smite/renew
      + ward in raid combat (mage/sage/cleric cast at 8 m). _d2_spells D2_SPELLS OK; renders/cycles/20261111_d2.
      FOR THE LAPTOP: monster.gd _local_bounds() should skip HealthBar3D; delve.gd casters can call the new
      kinds: Spells.cast(kind, caster, target_body, in_scar, more_bodies) + Spells.flight() for the landing.
      LAPTOP HALF DONE (Cycle 63): bars skip in Monster bounds; delve casters use the books + menders; D2_DELVE OK.
- [x] D3. Buildings that level up: each town level/tier visibly changes Bellmire - plots fill in, houses
      upgrade (bigger/stone storeys, signs, gardens), new buildings unlock (guild hall, market hall,
      stables, bathhouse, mage tower, keep walls in stone...). Render levels 1, 3, 5, 7 side by side.
      DONE cycle 64: scripts/growth.gd - 56 house plots fill 23/31/39/45/51/56 over the lore's 6 levels (staked
      lots till then); gardens/signs+lamps/stone plinth+chimney/+1 storey/pennants; palisade -> stone wall at 4;
      Market Hall 3, Town Stables 4, Delvers' Guild + Bathhouse 5, Mage Tower 6. D3_TEST OK; renders/cycles/20261111_d3
      (the lore has 6 levels, not 7: rendered 1, 3, 5, 6).
- [x] D4. More guards and the cavalry: more watch with patrol routes, gate guards, tower archers; mounted
      town guards (horses + riders, TOWN GUARDS ONLY) patrolling the roads and riding out at raids.
      Horses: CC0 (Quaternius animals) or a simple rig. Stables building from D3.
      DONE cycle 65: all 8 gate posts manned, 2 crossbowmen per watchtower who shoot raiders (bolts fly, d20 on
      landing), watch 12/14/16 walkers on wall/market/bridge beats by level ("sworn into the watch"); scripts/
      cavalry.gd - Knight on the Quaternius CC0 horse, 2/3/4 riders at levels 4/5/6 ride a gate loop from the
      Town Stables, ride out at raids (hp 80). D4_TEST OK; renders/cycles/20261111_d4.
- [x] D5. More animals: horses in paddocks, cows, sheep, pigs, chickens, dogs, cats, birds over the
      fields, ducks; herded and penned, never on rooftops.
      DONE cycle 66: hens (19, hand-built, peck) in a fenced run by each farmhouse, a sheepdog walking each flock's
      fence, 5 horses + a foal in the paddock, 8 cats on the streets (they nap), crows over 5 fields; animals never
      pick a spot or path through a building (solid_at) and stop at stalls. D5_TEST OK (0 in_solid / 0 high / 0 out
      of pen in 22200 samples); renders/cycles/20261111_d5.
- [x] D6. Unique NPCs: named characters with jobs and daily routines from the lore (the chief, the smith,
      the healer, the innkeeper, the priest, a bard, a town crier who reads the Chronicle aloud, merchants
      with carts, children playing, beggars, a drunk at night). Each with a distinct look and a line in
      the Chronicle now and then.
      DONE cycle 69: scripts/notables.gd - 12 named folk (lore roster's chief/smith/healer/innkeeper promoted, not
      doubled; + priest, crier, bard, pedlar with cart, two children, beggar, drunk), names from the lore's FIRST x
      LAST, title tag up close, own look, hour-slot days in their own quarter, Chronicle lines, the crier shouts the
      latest Chronicle news. D6_TEST OK (86% of slots reached, drunk out 0/134 by day 96/96 at night, 0 in_solid);
      renders/cycles/20261111_d6.
- [x] D6b. Nav snap bug: town._snap / TownNav.closest() returns (0,0,0) for a while after start (navmesh not
      synced yet). Wait for the map's first sync (NavigationServer3D.map_get_iteration_id > 0 or map_changed) before
      snapping; until then fall back to the raw position, never the origin. Re-check D4 watch patrol routes and
      anyone stacked on the square at start. Test: snap right after start never returns 0,0,0; render the square.
      DONE cycle 73: iteration id > 0 came ~40 frames before the region was in the map; TownNav.synced() waits for
      the region + a vertex probe, _snap falls back to keep_walkable. Also: traders' market spot kept the old plot's
      inside point (a 30-47 m "door leg" through houses) and a door leg left after stuck waypoints now re-routes.
      D6B_TEST OK (0 of 600 snaps at the origin, 90 beats clean); _townwalk in_solid 0/7923 and 0/8317; renders/cycles/20261112_d6b.
- [x] D7. (ALSO: a 1.5-1.9 s hitch about once a minute, present since before L1 - find it with a frame-time log; suspect building a dungeon floor in one frame -> build it over several frames or ahead of time) Population cap + far-away LOD so long streams keep 100+ FPS (soak FPS fell 150 -> 82 at 211 people).
      DONE cycle 76: LOD - walkers past 60 m from the camera step + animate every 2nd physics tick, past 120 m every
      4th (summed time, same pace: 2.52 vs 2.52 m/s); heroes, riders and raid fights always full. Street cap 200:
      settlers past it still settle (souls, level, tax) but keep indoors; a burial brings one out. Windowed, 217
      people: 98.8 -> 126.0 FPS (+28%); 43% fewer walker steps. D7_TEST OK; renders/cycles/20261112_d7.
      THE HITCH, found (tools/_d7_hitch.gd): every new dungeon floor is built in ONE frame - DungeonHD.build takes
      580-820 ms, of it FloorGen.build 450-770 ms (964-1684 nodes); 41 hitches of 350-810 ms in 6 min at 4x, each on
      a floor change of the viewers' or the band's delve. FOR THE LAPTOP (delve.gd / dungeon_hd.gd / floorgen.gd are
      yours): build the next floor ahead while the party fights (FloorGen.build on a DungeonHD that is not yet in the
      tree, on WorkerThreadPool - load() is thread-safe - then add_child on descend), or slice it over frames.
      Also fixed: a freed guard / notable stopped _show_garrison and the whole Notables pass every tick (2583 errors).
- [x] D9. Roll audit (town side): townsfolk.gd, raids.gd, spells.gd, town.gd - every outcome that is a flat chance or fixed number becomes a d20 check / attack / save with real stats (raids, guards, cavalry, NPC work, fishing on the docks). List what changed.
      DONE cycle 78: scripts/dice.gd (Dice); raids: initiative, blows = weapon dice + mod (heroes' own dice), spell attacks +
      fire burst DEX save vs 8+to-hit, mending dice, CON save for every defender, torch + rebuild checks; crossbows 1d10+3;
      work beats d20+2 vs DC 10 (mean kept 1.0); fishing hook = DEX check (dock +5, heroes DEX + prof for ranger/druid).
      Kept: raid timing/size/source (world events), townsfolk idle gestures (cosmetic), spells.gd (no rolls; the surface
      scar rule is canon). D9_TEST OK; renders/cycles/20261112_d9. Full list in PROGRESS cycle 78.
- [x] D12. Expand the map: the valley beyond the walls - outlying hamlets/farmsteads, a forest with a woodcutters'
      camp, a river ford and mill, old ruins (lore), roads linking them, the scar road; travellers and carts on
      the roads; the director's tour includes them. Navmesh + LOD keep FPS.
      DONE cycle 79: scripts/valley.gd - Coalfoot Steading (over the river) + Bramble End (east road), 3 cottages, a well,
      folk each; the Ashwood (150 trees) with a woodcutters' camp; the ford (gravel bar in height_at, gap in the river's
      nav band) + the Ford Mill; the Old Footing ruins off the Delvers' Road; 10 dirt roads; 8 trips of travellers/carts;
      5 director tour stops. FOUND: map_get_path stops at 4096 polygons (mesh has ~25000) - long routes came back cut
      30-50 m short; TownNav.path now queries with room. D12_TEST OK; renders/cycles/20261112_d12.
- [x] D13. MOVED to L20 (laptop owns scripts/rts_camera.gd - every recent commit to it is the laptop's).
- [x] D14. Stuck walkers against props (supervisor, Nov 11): _townwalk reports stuck_on_route=4 steady
      (traders Petra Bramble, Maela of the Ford, farmer Maela Coalfoot) - pinned on a prop a few cm off
      their route, navoff 0.17-0.66, push (0,0,0). Nobody is inside a building (in_solid 0 of 8394), so
      this is cosmetic, but they stand still all stream. Give the push-out rule a prop case. Fold into D7
      if it is the same code path.
      DONE cycle 80 (townsfolk.gd): the push-out handed the foot back each frame so the "feet moved" test never
      fired; now a prop push-out slides round it, "no nearer in 2.5 s" re-routes, and a walker wedged in a pocket
      off the navmesh (the adventurers' fenced yard: fence + benches + stools) floods out to walkable ground.
      tools/_d14_test.gd: pinned 25 -> 0, stuck per sample max 4 -> 1 (120 s). D14_TEST OK; renders/cycles/20261112_d14.
- [x] D8. Soak 30 min with everything on; fix what breaks.
      DONE cycle 81: 30 min windowed, director on, 4x, 6 fake viewers: FPS avg 139.2 (min 29 = the floor-build hitch, laptop),
      memory flat 552-585 MB, nodes ~20k, 22 days, 13 raids. Broke + fixed: chain-bolt hops landing after their floor was
      freed (2 SCRIPT ERRORs) and 9 "Lambda capture freed" (timers holding freed nodes - spells/raids/town/notables/townsfolk);
      a raid ate a hero's errand (arrival fired mid-road); defenders whose post a prop blocks walked on the spot forever.
      D8_TEST OK; 9-min re-soak 0 script errors, 0 lambda errors; renders/cycles/20261112_d8.

- [x] T1. TWITCH PHASE 2 - DESKTOP OWNS THIS (Mr. E, Nov 11 23:18). All credentials are already
      authorized and proven live: see the gitignored local/twitch.cfg for the client id, both user ids
      and the file names. Tokens are in user://twitch_token.json (broadcaster) and
      user://twitch_bot_token.json (bot bellmirebro, modded on the channel) on THIS machine - that is
      why the desktop builds it. Build it in a NEW file, scripts/twitch_eventsub.gd:
        - EventSub WebSocket: channel.cheer (bits:read), channel.subscribe / subscription.message /
          subscription.gift (channel:read:subscriptions), channel.follow VERSION 2
          (moderator:read:followers), channel.channel_points_custom_reward_redemption.add
          (channel:read:redemptions) -> town.spotlight(uid, lane bits|subs|points, seconds, reason).
        - REFRESH BOTH TOKENS ON A TIMER. They expire in about 4 hours. This is the most likely bug in
          the whole item and it only shows up hours in, on a 24/7 run, when nobody is watching.
        - Bellmire creates its OWN channel point rewards with its own client id at startup, and matches
          redemptions BY REWARD ID, never by title. The six rewards already on the channel belong to
          Mr. E's other app, fightoverlay - ignore them completely. Reward titles must avoid every
          fightoverlay keyword (boss, monster, spawn, raid, mob, goblin, horde, loot, drop, chest,
          treasure, invade, titan). Start with "Spotlight my hero".
        - Event ownership: bits and subs -> Bellmire spotlight lanes; follows -> a Chronicle line only,
          no spotlight (fightoverlay used to own follows and has turned its follower monster off).
      NEVER EDIT chatcmd.gd - it is laptop-owned. The chat-reply half is split by contract: the laptop
      adds  signal twitch_reply(user_login: String, text: String)  to chatcmd.gd, emitting the plain
      answer with no @name prefix and no rate limiting. THIS file connects to that signal and owns the
      queue, the rate limiting, the @name prefix and the Send Chat Message API call as bellmirebro
      (broadcaster_id 138821183, sender_id 1609188025). Do not change that signature alone.
      Test without a live stream: the test-only !testbits <n> / !testsub / !testpoints already exist
      from L17. Prove the refresh path by forcing an expiry, not by waiting.
      DONE cycle 82: scripts/twitch_eventsub.gd (TwitchEventSub, started by town.gd in play only) - EventSub socket, 6/6 subs
      live (cheer, subscribe, sub.message, sub.gift, follow v2, redemption.add); both tokens refreshed 15 min early + hourly
      validate + refresh on a stale-token 401, new pair saved .tmp -> read back -> rename; bits 15/20/30 s, sub/resub/gifter
      30 s, follow = Chronicle only, rewards matched by id only (fightoverlay's ignored), refund when no hero; chat queue
      (1.6 s gap, @name, 480 chars, 30 s repeat drop) waits on chatcmd's twitch_reply. T1_TEST OK (18/18 offline); T1_LIVE OK
      (forced expiry -> both refreshed, saved, validated, socket stayed up). NOT YET: (a) the broadcaster token lacks
      channel:manage:redemptions, so Bellmire can not make its "Spotlight my hero" reward (401) - Mr. E must re-authorize
      with that scope; (b) town.spotlight is L17 (laptop) - until then events print SPOTLIGHT + emit spotlight_wanted;
      (c) twitch_reply is not in chatcmd.gd yet (laptop) - connected automatically once it is; (d) !testbits etc. do not
      exist (L17 open) - tests feed recorded EventSub frames instead. Chat sending was not tried live (nothing posted).

- [x] D15. (DONE Nov 12 04:16: 35-min soak / 87 valley days / 228 people / 51 raids - 0 script/freed-node errors; audio pool bounded (16/16 peak = graceful voice-steal), streams cached 131 plateaued; memory rise tracks town growth not audio; GAP held (busiest mana_charge 3.93/s vs ~8.3/s); FPS population-bound not audio. Follow-up D22: bump sfx pool 16->24 for peak headroom.) SOUND SOAK (supervisor, Nov 12). Now that S1+S2 wired the full RPG sound library, run a
      30-45 min soak with sound ON and confirm it is safe for a 24/7 stream: (a) no audio-related
      SCRIPT ERROR and no 'freed node'/lambda errors over the whole run; (b) the AudioStreamPlayer3D
      pool in sfx.gd is not exhausted or growing without bound (log pool size + active players each
      minute); (c) memory does not climb from audio streams (compare mem_mb first third vs last third,
      as D8 did); (d) FPS holds as it did in the silent D8 soak (sound must not cost meaningful frame
      time); (e) the GAP throttles hold under a busy town+raid so no kind machine-guns. Write the
      findings into PROGRESS; if anything leaks or errors, fix it before ticking. Reuse tools/_soak.gd
      with audio enabled. Commit + push only on a clean run.

## LAPTOP (dungeon, combat content, heroes) — files: bestiary.gd, monster.gd, floorgen.gd, dungeon_hd.gd, dungeon_parts.gd, gear.gd, roster.gd, chatcmd.gd, delve.gd, data/*
- [x] L1. More monsters: new CC0 creature models (KayKit Skeletons/Halloween, Quaternius CC0 monster packs),
      each with stats, behaviour and a home biome/theme from the lore's bestiary; new strains.
      DONE (Cycle 58): 6 creatures from owned CC0 bodies, ways in a fight, home themes, 2 strains; L1_TEST OK.
- [x] L2. More bosses: a set of floor lords and rare uniques (from the lore), each with a mechanic
      (summons, enrage, area attack), a name card and the boss bar; never two of the same in a row.
      DONE (Cycle 59): a mechanic for each of the eight lords, five rare uniques (one from the memorial); L2_TEST OK.
- [x] L3. More weapons and armour: more tiers and kinds (axes, spears, maces, bows, staves, shields,
      helms, chest, boots) using KayKit/Quaternius CC0 meshes; visible on the hero; priced in the shops;
      !forge / !armoury pick from them; drops on deep floors.
      DONE (Cycle 60): 10 weapon kinds x 5 tiers, worn armour, found-only tier 5, !forge <kind>, deep finds; L3_TEST OK.
- [x] L4. More classes: from the lore first (it has knight, mage, ranger, barbarian, cleric, rogue, sage,
      duelist); add more (e.g. paladin, necromancer, monk, druid, warlock, bard) with 5e-style saves,
      a weapon, a spell or ability, and !enlist support.
      DONE (Cycle 61): paladin, necromancer, monk, druid, warlock, bard - saves, weapon kind, ability, cloak; L4_TEST OK.
- [x] L5. Character species: !enlist <class> <species> (human, elf, dwarf, halfling, orc, ... from the lore)
      with stat bonuses and a visible look (KayKit/Quaternius CC0 bodies, scale, skin tint).
      DONE (Cycle 62): human, elf, dwarf, halfling, orc + the scarkin; bonuses, traits, proportions, skin, parts; L5_TEST OK.
- [x] L6. More character models for heroes and townsfolk (KayKit Adventurers 2.0 etc., CC0).
- [x] L8. (Mr. E's decision, Nov 11) Wild magic below: every spell in the dungeon is a check against the scar - d20 + casting mod (INT mage/sage/necromancer, WIS cleric/druid/monk, CHA warlock/bard/paladin) + proficiency vs DC 10 + floor/2 (cap 20); fail = misfire as on the scar's surface (Spells.cast in_scar=true); nat 1 always, nat 20 never. Monsters unaffected. Test the misfire rates (strong vs weak caster, shallow vs deep).
- [x] L10. (DONE Nov 11, be7c9a9: idle no longer overrides walk/attack; MON_ANIMS OK; 0 monsters in props) (URGENT, do before L9 - Mr. E saw it live) Monsters and bosses have NO animations: they glide/"fly"
      along the ground, never swing, and get stuck in walls and props. 1) Write tools/_mon_anims.gd: for EVERY
      bestiary def (incl. lords, uniques, L1 creatures) spawn it and print its model, whether an AnimationPlayer
      was found, the animation list, and which of def.anims (idle/walk/run/attack/cast/hit/die/rise) actually
      exist - any missing name means monster._play() silently does nothing. 2) Fix each: correct the names, or
      attach the shared rig library (KayKit Skeletons ship animations separately - Rig_Medium general/movement/
      combat; the UAL path) so every humanoid has idle, walk, attack, hit, death; beasts get what their pack has.
      3) Monster movement uses the same obstacle push-out/slide + never-off-floor guard the heroes use (delve.gd
      _step/_go), so no monster walks into walls or props. 4) Render a fight with 3+ kinds and a lord mid-swing;
      LOOK. Test: every def reports idle+walk+attack present; _offfloor counts monsters too (0 in props).
- [x] L9. Roll audit (dungeon/hero side): delve.gd, monster.gd, roster.gd, chatcmd.gd, gear.gd - attacks, damage dice, saves, traps (Perception/DEX save), loot (Investigation), initiative, death saves, shop haggling (CHA check) all as d20 rolls with real stats; nat 20/nat 1; big rolls in the Chronicle.
- [x] L7. Soak the delve 30 min with 6 fake viewers using the new classes/species/gear; fix what breaks.

## LAPTOP list 3 (Mr. E, Nov 11 evening) - UI + content. The laptop now owns the UI files too:
## rts_camera.gd, feed_hud.gd, leaderboard_panel.gd, party_frames.gd, boss_bar.gd, auto_director.gd, health_bar_3d.gd, new UI files.
- [x] L11. Traps that visibly work (Mr. E: "they don't show functioning or doing damage"): every trap kind
      (pressure plate, spikes, darts, blades, pits...) has a trigger animation + sound, a DEX save (or Perception
      to spot first) rolled with real stats, damage dice with the number floating up, a Chronicle line
      ("BigAxe steps on a plate - darts! DEX 9 vs DC 13, 7 damage"), disarming by a rogue (Thieves' tools check).
      Render a trap going off; test that damage lands and saves roll.
      DONE (Cycle 69): 6 kinds armed until stepped on, trigger anim + sound, Perception/thieves' tools/DEX save, dice, floating numbers, Chronicle; L11_TEST OK.
- [x] L12. Potions with status effects, 5e style: healing tiers (2d4+2 ... 10d4+20), plus antidote, fire/frost
      resistance, haste, giant strength, invisibility, heroism, darkvision for unlit floors; and the bad states
      to cure/inflict: poisoned, burning, frozen/slowed, blinded, frightened. Status icons on party frames and
      over heads; durations; brewed at the apothecary (!brew <potion>), found below. Lore voice for names.
      DONE (Cycle 70): 12 brews (data/potions.json), 5 bad states with sources and cures, drinking below, !brew <potion>, tags; L12_TEST OK.
- [x] L13. More equipment + COSMETICS: more weapons/armour per tier (rings, amulets, cloaks, boots, gloves with
      small 5e bonuses), and cosmetic-only items - hats, hoods, capes, dyes (colour the armour), banners on
      the back, a pet that follows (from the CC0 animals), titles shown under the name. !wear <item>, !dye <colour>.
      Bought with gold now; later channel points (T1). Visible on the hero; render a lineup.
      DONE (Cycle 71): 10 accessories with 5e bonuses, 18 cosmetics (hats, banners, pets, titles), 10 dyes, !wear / !dye; L13_TEST OK.
- [x] L14. The command list in detail: one source of truth (data/commands.json): name, aliases, args, cost,
      cooldown, what it does, example. !help / !commands (short), !help <cmd> (detail). Friendly error replies
      ("!forge needs 120 gold - you have 40"). Write docs/COMMANDS.md from the same data (the hub/website uses it).
      DONE (Cycle 72): data/commands.json -> !help, !help <cmd>, aliases, typo nudges, "- you have N" replies, docs/COMMANDS.md; L14_TEST OK.
- [x] L15. STREAM READABILITY (Mr. E: will viewers be able to read it?): design for a 1080p stream watched on a
      phone. Minimum on-screen text ~28 px at 1080p for anything viewers must read; name tags, Chronicle, Guild
      Roll, party frames, boss bar, banners scaled up; high contrast + outline; a UI scale setting (F11 cycles
      100/125/150%). Test: render at 1920x1080, then downscale to 854x480 (what a phone sees) and LOOK - every
      name and Chronicle line must still be readable. Fix until it is.
      DONE (Cycle 73): UiTheme sizes for 1080p (Chronicle 28 px, roll 26, frames 28, boss bar 44/26), F11 100/125/150, names grow with distance; phone 854x480 frames read; L15_TEST OK.
- [x] L16. GUI/UI polish to an RTS/WoW standard: one theme for every panel (parchment + ink, the JestSayin teal
      as the accent), consistent fonts, icons, frames, spacing; the unit frame, party frames, guild roll,
      chronicle, boss bar, help, chat box all match. Nothing from the old game's interface.
      DONE (Cycle 74): one house theme in UiTheme (parchment, ink, teal titles and rules, inked bars, chips) on every panel; L16_TEST OK.
- [x] L19. More lore: from the reference + the Lore Bible PDF - more Chronicle lines, NPC barks, floor-origin
      text, item and potion flavour, boss intros, town-level announcements; all in the original's voice, never
      contradicting it, never a floor count.
- [x] L17. (moved from D10; laptop owns the UI) Spotlight split-screen (Mr. E, Nov 11): viewers who support the stream get a timed pane on their hero.
      FIXED LANES in a 2x2 grid, each with its own queue and colour-coded frame:
        top-left     = the director (always, the main view)
        top-right    = BITS / cheers lane (gold frame) - any cheer 15 s, 50+ bits 20 s, 100+ bits 30 s
        bottom-left  = SUBSCRIBERS lane (purple frame) - new sub / resub / gift 30 s, gift bomb: each gifter 30 s
        bottom-right = CHANNEL POINTS lane (teal frame) - 15 s; free !look 10 s when it is otherwise empty
      Only lanes with someone in them open: no spotlights = full-screen director; one lane busy = director +
      that pane side by side; more = the 2x2 (an empty lane shows the director's wide view of the town).
      Each pane: a SubViewport + Camera3D following that hero (into the scar too), half resolution, the
      viewer's name + class + "cheered 500 bits" / "subscribed" / "redeemed <reward>" across the top, a thin
      timer bar. API: town.spotlight(uid, lane, seconds, reason). Test with local commands (!look, and
      test-only !testbits <n> / !testsub / !testpoints) and a tool that fills all lanes and renders the grid.
      F10 hides pane labels. Watch FPS.
      FREE CHAT (no pane, the main view instead): the director's hero shots favour the most recently active
      chatters (ahead of random heroes, behind raids/lords/fights); a small "Now watching: <name> the <species>
      <class>" banner in the main view; their name glows above their hero for ~5 s after any command; free
      !look borrows the channel-points lane for 10 s only when it is empty.
      DONE (Cycle 76): lanes + queues, !look / !testbits / !testsub / !testpoints (local only), pair + 2x2, F10 with the UI, FPS 44 -> 40 with all three lanes; L17_TEST OK. For the desktop: add `func spotlight(uid, lane, secs, why): return Spotlight.spotlight(self, uid, lane, secs, why)` to town.gd.
- [x] L18. (moved from D11) Free chat in the main view (Mr. E, Nov 11): the director's hero shots favour the most recent chatters; a small "Now watching: <name> the <species> <class>" tag; a chatter's name glows ~5 s after a command; free !look uses the channel-points pane only when it is empty. No pane for free chat.
      DONE (Cycle 77): the freshest chatter (2 min) is the director's hero pick (36-50), "Now watching" chip, 5 s teal name glow, !look via the points lane; Chronicle entries capped at 2 lines; L18_TEST OK.
- [x] L20. Director camera clearance (supervisor, Nov 11; was D13). CORRECTION to the original note: the
      roof in renders/cycles/20261112_d6b/square_f460_east.png was NOT an auto-director shot - _d6b_shot.gd
      placed its own fixed camera 14 m up beside the square, so that framing is the test tool's, not the
      director's. The real gap (found by the laptop, Nov 11): the camera's edge-protection check only covers
      hero-follow shots and tests a single line, so tour and wide shots have no clearance check at all and
      roofs beside that line go unprotected. Fix it in the eye camera for every shot type, and prove it with
      real director shots - town wide, tour, hero follow, fight, raid - rendered and looked at, not with a
      fixed test camera. The L17 spotlight panes each get their own camera, so they must share this rule.
      DONE (Cycle 79): every shot tilts / swings round its subject until the near lower frame is clear of roofs, props, walls and towers (one rule, the panes share it); pull-in never closer than 6 m; real director shots of all six types 0-2% blocked (raw up to 100%); L20_TEST OK.
- [x] L21. THE INTERFACE over the spotlight panes (Mr. E, Nov 11). In the grid the HUD was laid out for one full-screen view:
      the boss card across all four seams, the Chronicle over the subs pane, the delvers panel in the director pane's
      corner, floating text everywhere, name tags in mush. THE RULE, in code: with more than one view up, no HUD
      element crosses a seam or sits over a pane it does not belong to - docked inside one pane, or in the chrome bar.
      Floating text clamped to its pane and off in quarter panes; name tags fixed in panes; full screen unchanged.
      Test that fails on the old build, then a 1080p render shrunk to 854x480 and looked at.
      DONE (Cycle 81): panes over the top 85%, the Chronicle + clock in a bottom chrome bar, boss card + party frames + unit frame docked in the pane showing them (scripts/hud_dock.gd), 3D text on render layers with a cull mask per pane, one name tag per lane pane; L21_TEST 32/32 (15 failed before).
      ALSO: !guild drops the "roll" alias (bare !roll is fightoverlay's dice, now silent here); L14_TEST OK.
- [x] L22. Panes near-identical when two spotlit heroes stand close: a different angle / zoom when subjects are within a few metres.
      DONE (Cycle 84): within 6 m of another pane's subject a lane takes its own quarter (90 / -90 / 180 deg from the director) and zoom, clearance tilts but never swings it; L22_TEST OK (views 84-177 deg apart).
- [x] L23. The director should cut away from a hero a lane already holds (laptop commit a6eb770 calls this L24).
      DONE (Cycle 85): lane-held heroes are skipped by every director pick, a fight or delve shot goes through a delver no lane holds, a held shot is cut within 1 s; L24_TEST OK (5 of 6 failed before).

- [x] L24. De-flake tools/_l20_test.gd (supervisor, Nov 12). On the merge run it failed with (laptop commit d3669e2 calls this L23)
      "the director never cut to fight" and "all six shot types were seen" (saw tour_market, tour_scar,
      tour_valley, hero, raid - no fight), then PASSED on an immediate re-run with no code change. It is
      waiting on the director to happen to cut to a fight inside the test window. Make the test drive the
      director deterministically - force a fight and force the cut - instead of waiting for one. A test
      that fails at random teaches everyone to ignore it, which is worse than no test.
      DONE (Cycle 83): a lord floor + the director deciding at once when the story is live (its own _best / _cut); timing samples best of 3; L20_TEST OK x3 in a row.

- [x] S1. SOUND WIRING - DESKTOP (town side). The RPG sound library is already on main (commit 00cf0ef):
      86 ids registered as Sfx kinds, played with Sfx.at(id, pos) (3D, in the world) or Sfx.play(id)
      (flat). Do NOT edit sfx.gd except to add a GAP throttle for a kind that fires often. Wire the
      kinds that belong to the town, in the desktop-owned files only:
        - townsfolk.gd: villagers and named NPCs give an occasional gendered voice - male_/female_grunt,
          _effort, _laugh (pick by the NPC's sex). Sample it, do not sound every tick - it should feel
          alive, not a crowd grunting. The crier can use male_/female_attack_yell for a shout.
        - spells.gd: town-side casts -> fireball (magic fire), ice_shard, lightning (zap), heal, buff,
          curse, shield, summon, mana_charge. Play at the caster's position.
        - raids.gd: raiders arriving -> orc_roar / troll_roar / goblin_screech (by raider kind), a horn
          already plays; combat hits during the raid -> sword_clash / hit_impact at the fight.
        - town.gd / daylight.gd animals + time of day: dog_bark, cat_meow, horse_neigh/whinny, boar_grunt
          from the pens; bird_chirp / crow_caw by day, owl_hoot + cricket_chirp at night, kept quiet and
          occasional under the ambience bus.
        - level_up / quest_complete when the town reaches a new level.
      Keep it tasteful: throttle, keep volumes under the existing buses, and don't let far events be loud
      (Sfx.at already attenuates by distance). Add a tools/_s1_test.gd that asserts each wired event calls
      Sfx with a kind that exists in SETS. Render/soak a minute and listen in your head via the play counts
      (Sfx.plays) - 0 SCRIPT ERROR, no kind played that isn't registered.
- [x] S2. SOUND WIRING - LAPTOP (dungeon + heroes + UI). Same library on main (00cf0ef), same API, same      rule: do not edit sfx.gd except to add a GAP. Pull main into the laptop branch first. Wire the
      laptop-owned files only:
        - monster.gd / bestiary.gd: each monster species gets a voice on spawn and on death - map
          goblin->goblin_screech/cackle, orc->orc_roar, troll->troll_roar, skeleton->skeleton_rattle,
          zombie->zombie_moan, ghost->ghost_wail, wraith->wraith_whisper, slime->slime_squish,
          spider->spider_skitter, bat->bat_screech, demon->demon_growl, dragon->dragon_roar (+ 
          dragon_fire_breath on its breath attack), minotaur->minotaur_bellow, giant->giant_footstep.
          A boss roars on arrival (ties in with the spotlight). Throttle so a room of monsters is not a
          wall of noise - sample, and favour the biggest/nearest.
        - delve.gd combat: sword_swing then sword_clash/hit_impact on a melee hit, dagger_stab for
          daggers, bow_draw -> arrow_shot for ranged, shield_bash/block on a block; a miss can whiff with
          sword_swing alone. Heroes' spells reuse fireball/ice_shard/lightning/heal/shield.
        - heroes' voices by sex: male_/female_hurt on taking a hit, _death on dying (the death music
          duck already fires), _effort/_grunt on a big swing. Sample, do not voice every blow.
        - dungeon ambience per floor: a quiet bed of bat_screech / spider_skitter / skeleton_rattle /
          ghost_wail, occasional, under the ambience bus.
        - chatcmd.gd / UI feedback: menu_select on a recognised command, error on a typo nudge,
          item_pickup / chest_open / coins_stack on buys and finds, potion_drink on !brew, inventory_open
          on !inventory, level_up when a hero levels. These are flat (Sfx.play), not positional.
      Add tools/_s2_test.gd asserting every wired event uses a registered kind; 0 SCRIPT ERROR; the
      existing _delve_test should still pass with sound calls in.
      DONE (Cycle 87, laptop): Bestiary.voice_of (34 creatures, every lord and unique voiced), queued creature voices (one a 0.9 s beat, biggest / nearest / a death first, same kind 3.5 s), a lord roars as it rises, breath on the breath; per-weapon swings + hit / clash / bow / block / shield_bash, spells, potions, finds; hero voices sampled (Roster.voice_of); a quiet bed below; chat / UI sounds; level_up. GAPs added in sfx.gd. S2_TEST OK x3.
- [x] S3. SOUND REVIEW + TUNING - LAPTOP (supervisor, Nov 12). S1 / S2 only proved the kinds exist; check the game
      SOUNDS right: no silent monster, every command audible, throttles hold under load, levels balanced under the
      buses, no pool exhaustion or freed-node errors. A test so a future monster or command cannot ship silent.
      DONE (Cycle 88): tools/_sound_review.gd (coverage headless; load + measured levels windowed). Fixed: spells below
      doubled (S1 + S2 both sounded them), !reroll / !respec paid silently, dragon roar +9.9 dB over the music,
      skeleton / spider voices -9.5, half the dungeon bed inaudible (-25), menu_select +4.6, potion_drink buried,
      a generic hit doubling every blow. Levels now -5.6 .. +1.9 dB of the music, bed -15 .. -18; SOUND_REVIEW OK 18/18.

## Twitch phase 2 (main chat, needs Mr. E's Client ID)
- [x] W1a. SNAPSHOT PUBLISHER - DESKTOP. Mr. E chose GitHub Pages for the page and Supabase for the
      data (Nov 12, free tier, project already created and the table already exists). Every 60 s the
      game upserts ONE row into the Supabase table public.snapshot: id=1, payload = a jsonb blob with the
      guild roll, the fallen, each hero's sheet/inventory/gear, town level and souls, and the command
      list from data/commands.json. One row, overwritten - the database never grows and nothing has to
      be cleaned up. Project URL https://paaukwaffaamazgrndbv.supabase.co . Writing needs the SERVICE
      ROLE key, which bypasses row-level security: it goes in user:// beside the Twitch tokens and NEVER
      in the repo - Mr. E copies it from the Supabase dashboard (Project Settings > API). Skip the
      publish quietly if the key is absent so the game still runs without it. Failures must never stall
      the sim: fire and forget on a thread, and never block a frame on the network.
      CONNECTIVITY IS ALREADY PROVEN (supervisor, Nov 12 01:05): the key is in
      user://supabase.json as {"url": ..., "service_key": ...}; a write with it succeeded, a read with
      the publishable key succeeded, and a write attempted with the publishable key was correctly
      refused by RLS. The table currently holds a test row - overwrite it.
      GOTCHA, do not rediscover this: Supabase REFUSES a secret key when the request looks like it came
      from a browser - "Forbidden use of secret API key in browser". PowerShell's default User-Agent
      triggers it; setting User-Agent: BellmireHD/1.0 fixed it instantly. If the publish ever returns
      403 with that message, set a non-browser User-Agent on the HTTPRequest rather than hunting the key.
      Upsert with POST to /rest/v1/snapshot?on_conflict=id and the header Prefer: resolution=merge-duplicates.
      DONE cycle 87: scripts/snapshot_pub.gd (SnapshotPublisher, started by town.gd in play only) - every 60 s (first at 20 s)
      one threaded HTTPRequest upserts id=1 {town, guild_roll (50), fallen (50), heroes = living sheets (stats, saves, AC/HP,
      weapon+dice, armour, potions/brews, oil, gold, worn, rank, title), commands}; no Twitch ids; one in flight at most;
      no key file = off. publish() 0.3-0.7 ms, build 0.4 ms (202 heroes 5 ms, 95 KB). W1A_TEST OK 17/17 (live upsert 200,
      read back with the publishable key, publishable-key write refused 401); W1A_TOWN OK (real town + real save, read only:
      level 3, 51 souls, 2 heroes, 6 fallen, 21 commands - that is the row in the table now).
      ADDED cycle 89: payload.chronicle - the last 50 town.feed lines, newest first, {t, s, at}; t by keyword (death/raid/loot/delve/
      town/lore/fight, unsure = town), at = when the publisher first saw it; control chars, BBCode, < > and 7+ digit runs stripped, 200 chars max.
      No existing key changed. W1A_TEST OK 23/23 (6 new checks).
- [x] W1b. THE VIEWER HUB PAGE - a static page, no build step, on GitHub Pages like fightoverlay.
      It fetches public.snapshot with the PUBLISHABLE key (safe to embed, read-only by policy):
        URL  https://paaukwaffaamazgrndbv.supabase.co/rest/v1/snapshot?select=payload,updated_at
        key  sb_publishable_q2Kn3weLLeYYXGAiow_4vw_3serNQlc   (apikey header + Authorization: Bearer)
      Shows hero sheets, inventory, gear, the guild roll, the fallen and the command list, with "as of
      <updated_at>" visible so a stale snapshot is obvious when the game is off. Readable on a phone
      first - most viewers will open it on one. Must work when the game has never run (empty table).
      Phase 2, later: polls that change the town, with Twitch login - that is why the data is in
      Supabase rather than in a file; a static host could not do it at all.
      DONE (Cycle 86, laptop): web/index.html - one static file, no build, no framework; phone first (390 px), two / three columns when wide. Heroes (find by name, tap for the sheet: stats + mods, weapon dice, to-hit, armour / AC, saves, pack, worn, record), the Guild Roll, the Fallen (killer, day, epitaph when there is one), town level / souls / day / treasury / growth, the command list. "Updated N minutes ago" always; past 5 min it says the town has gone quiet; empty table -> "has not reported in yet"; failed fetch (12 s timeout) -> a plain message + Try again, retried every minute. Not published - Pages is Mr. E's call. Shots: renders/cycles/20261112_w1b.
## Needs Mr. E (not for the runs)
- Twitch follows/subs/bits/channel points: needs a Twitch token from him.
- Firefly icons / title art: made by him in Adobe.


## ROUND 4 - Nov 12 polish + hub elevation (Mr. E, 03:47 CT). Expanded into phased programs 04:16.
## CHANGELOG 04:33: L25 was split into L25a-d (L25 = all four collectively); IDs are now FROZEN, PROGRESS cycles are per-machine prefixed (D/L/H). See docs/COORDINATION.md - the single source of truth for machines, paths, numbering, tests, merges, WIP.
## Priorities from Mr. E: people clip/stick, dungeon looks rough, animations weak, hub must be SSS+.
## Ownership unchanged. Each item: subject + DONE/test. Workers take the FIRST unchecked item IN THEIR OWN section.
## Full per-chat briefs with the long detail exist (desktop saved claude/desktop-program-d16-d23.md); these lines are the trackable checklist.

### DESKTOP (town/people/nav/animation) - town.gd, town_nav.gd, townsfolk.gd, hero_body.gd, rig.gd, raids.gd, cavalry.gd, animal.gd, spells.gd, daylight.gd, valley.gd, notables.gd, economy.gd, sfx.gd
# Phase A - movement & nav (stop walls/sticking) [D16]
- [x] D16a. LOCAL AVOIDANCE: hero_body/townsfolk/animal/cavalry follow _route with no dynamic avoidance - add NavigationAgent3D avoidance OR separation steering (push apart within ~0.6 m). DONE: 50-body gate-funnel = 0 sustained overlaps > 0.3 m. -> DONE Nov 12: town.crowd_push is now separation (soft ring + hard contact, per-body radius) + yield (sidestep to pass whoever is ahead; same-way walkers followed) for townsfolk/heroes/cavalry/watch pairs/animals. tools/_d16a_test.gd at the west gate: under-0.3 m pair-time 29.2 s -> 0, clip (<0.45 m) 62.5 -> 2.2 pair-s, min gap 0.02 -> 0.38 m, 0 sustained, 50/50 through (median 10.0 s, unchanged).
- [x] D16b. UNSTICK WATCHDOG: route active but displacement < 0.2 m over 2 s -> repath/nudge. DONE: _townwalk stuck_on_route == 0 over 120 s. -> DONE Nov 12: Townsfolk watchdog (2 s / 0.2 m): near-enough arrival, else re-path, else side-step (or brush out of a prop pocket), else drop the trip (heroes/caravans keep trying). _townwalk now 120 s: stuck_on_route 0 (total 0); tools/_d16b_test.gd 180 s: 10 pinned events / 4 people with it off -> 0 with it on.
- [x] D16c. DYNAMIC OBSTACLES: stalls/carts/benches not in the navmesh - register or steer round. DONE: town soak = 0 bodies through a stall or stuck on a prop. -> DONE Nov 12: moving wagons (carters, travellers, caravan, pedlar) steered round (crowd_push) + feet kept out (off_wagons, every frame before LOD) + legs re-routed round/beside them (wagon_way); parked wagons drawn up on open ground (wagon_park); mine/farm wagons + scar-glass now solid. tools/_d16c_test.gd 150 s town+raid: through-a-prop 26-33 -> 0, stuck_by_prop 0 (PASS).
- [x] D16d. DOORWAY/GATE/BRIDGE FUNNELING: crowds queue and pass instead of piling. DONE: funnel test passes at the real gate and bridge. -> DONE Nov 12: the pile was the pre-sync road-hex route (D16a's note) - every route asked before the navmesh is in the map went out through a gate and back (walked/straight 1.68-1.78) and never crossed the bridge (50/100); Townsfolk now marks such a route and re-walks it on the navmesh once synced. tools/_d16d_test.gd 100 walkers two-way, routed on the spawn frame: gate 98/100 median 27.4 s -> 100/100 15.4 s, walked/straight 1.02, 0 overlap in the arch; bridge 50/100 -> 100/100, 0 overlap; routed after sync both PASS. A queue+lane steering variant was tried and measured worse (slower, more jostle) - not kept.
# Phase B - animation overhaul (town) [D17]
- [x] D17a. NO T-POSE: rig.gd fallback clip when a model lacks the named anim (play Idle + log once). DONE: anim probe = 0 empty current_animation over a 60 s day+raid. -> DONE Nov 12: Rig.play falls back to the model's idle on a missing clip (logged once) and queues every one-shot back into the loop the body was in (death -> its held Death_*_Pose); *_Idle/*_Pose clips loop; stable horses idle. tools/_d17a_test.gd 60 s day+raid: visible bodies with an empty player 182 samples (bandit Death_A, smith/farmer PickUp, fisher Interact, crier Cheer) -> 0 of 23927 (PASS).
- [x] D17b. LOCOMOTION BLEND: speed-blend walk<->run, match playback to move speed, face heading - no gliding/moonwalk. DONE: walk probe, no foot-slide beyond threshold. -> DONE Nov 12: Rig.drive picks a gait from each body's measured speed (stand/walk/jog/run, hysteresis, 0.3 s crossfade) and plays it at speed / the clip's own ground speed (KayKit walk 0.8 m/s, jog 2.1, run 3.3 - tools/_d17b_clipspeed.gd); walkers face the way they actually move; Townsfolk.pace 0.62 -> 0.40 (2.6 m/s was a sprint for these legs; the mounted watch kept its speed). tools/_d17b_test.gd 60 s day+raid: skate median 1.80 -> 0.006 m/s, p90 2.50 -> 0.23, idle-glide 3600 -> 59 samples, moonwalk 0.09% (PASS).
- [x] D17c. STATE COVERAGE: job anims (smith/angler/farmer/vendor), sit/eat at night, attack/cast/hurt/death for guards/heroes/raiders, animal graze/walk/flee. DONE: town-day shot sheet, NPCs visibly work. -> DONE Nov 12: trades work in their own motions (JOB_ANIMS: smith hammer, farmer hoe/baskets, woodcutter/miner swing, stalls+shops serve; walkers work their yard out of doors half the time); seats (square benches x2, tavern stools+chairs) sat on - Sit_Chair_Down/Idle/StandUp, often of an evening; tavern-yard drink/bite (Use_Item; no seated-eat clip in KayKit); raid swings vary (4x1H, 3x2H), Hit_A/B + Block_Hit + parries, Death_A/B; beasts graze (neck bent by a SkeletonModifier3D - the CC0 farm pack has no eating clip) and bolt from a raider within 14 m. tools/_d17c_test.gd 130 s day+evening+raid: all 14 states seen, 0 empty clips (PASS); old: no land-work, no sitting, no flight, graze only hens. Sheet renders/cycles/20261112_d17c.
- [x] D17d. BLENDS/TRANSITIONS: proper blend times, no pops, death doesn't T-pose. DONE: no visible pops in a 60 s capture. -> DONE Nov 12: the real pops were corpses getting up (the gait drove a fallen body out of its held Death_*_Pose into Idle ~1 s after the fall - old render: a buried farmer back on her feet doing PickUp) and body-yaw snaps (steering sets rotation.y outright). Rig: a Death_* marks the player fallen, nothing but another death or Rig.revive (a KO'd hero coming round) moves it; Townsfolk eases turns at 540 deg/s (walkers keep face_fix). tools/_d17d_test.gd 60 s, 2 raids + 6-death fixture, 90 bodies/frame: risen 3 -> 0, turn snaps 165 -> 4, one-frame bone pops 0 -> 1 of 284k (clip changes already blend - D17a's 0.2 s default), shake 1 -> 0 (PASS). Sheet renders/cycles/20261112_d17d.
# Phase C - the map: town & valley [D18]
- [x] D18a. PROP/BUILDING SANITY: 0 floating/interpenetrating props, buildings on ground, roads connect, wall/gates/bridge coherent. DONE: sweep = 0 floating/clipping; shot sheet.
      DONE cycle D1: tools/_d18a_test.gd sweeps 1034 ground props (0 floating/sunk past tol, slope+surface+water+planter
      dressing classified) and 83 building footprints (oriented, 0 interpenetrating). D18A_TEST OK. No genuine placement
      bug found - every earlier flag was intended (wall lanterns, tower crossbowmen ~11.7m, table/rack dressing, flowers
      in raised planter boxes, dock props over the riverbed, scar-mouth crag on the mine slope, hillside cottages nestled
      at the _low seat, forest canopies). No game script changed. renders/cycles/20261112_d18a (gate, bridge, square,
      scar, docks, aerial, hillside farmstead) - wall/gates/bridge/roads coherent, buildings on ground, nothing floats.
- [x] D18b. DRESS THE VALLEY: fields, fences, crops, mill, docks, forest, paths. DONE: valley shot sheet reads lived-in.
      DONE cycle D2: valley.gd _dress_valley - each steading (Coalfoot, Bramble End) now has 2 fenced, ploughed,
      cropped fields (wheat/veg) with a scarecrow + a footpath to the gate, a picket kitchen garden, a hayrick and
      grazing stock (sheep/cattle); a plank fishing jetty over the ford's slow water; wildflower + tall-grass verges
      along the lanes and a copse between the roads. Built 4 fields / 1416 crop sprites / 133 fence posts / +5 beasts.
      D18B_TEST OK; parse 0 err, _offfloor 0/1036 (0 inprop), TWITCH_PARSE OK, _townwalk in_solid 0/18452 stuck 0,
      _delve_test (DELVE_OIL=1) 0 SCRIPT ERROR to floor 2. Shots renders/cycles/20261112_d18b (steadings, jetty, aerial).
- [x] D18c. GROUND & MATERIALS: ground texture blending (grass/dirt/road/water), water shader. DONE: before/after; 0 material-null headless. -> DONE Nov 12: wet muddy shore in ground.gdshader (noise-ragged band at the waterline, wet sheen; water_y from town) blends the banks under the river; grass/dirt/road blending already lived in the shader (town-mask trodden dirt + rock/snow/scar), water shader kept. The 3 headless material-nulls traced (bisection) to Gear.ignite's per-surface overrides draped by show_tiers' _cloth material_override on the rack weapons - town.gd _tier_rack now bakes the lit material into a duplicate mesh (gear.gd untouched). Bare headless start: 0 material-null, 0 errors; shots renders/cycles/20261112_d18c (bank+ford before/after, rack intact).
# Phase D - lighting, day/night, atmosphere [D19]
- [x] D19a. daylight.gd DAY/NIGHT: sun angle+colour, dawn/dusk warmth, real night dark, lamps/braziers/windows as OmniLights at night. DONE: full-day timelapse shot sheet. -> DONE Nov 12: day/night was already driven by daylight.gd (sun arc+colour, goldness dawn/dusk, nightness + a moon you can see by, lamps*k, windows emission); added night BLOOM - town env glow_enabled, glow scaled by nightness in daylight.gd so windows/lamps/braziers halo after dark and the day stays clean. _d19a_test OK (noon sun_e1.5/high white; dawn+dusk gold, lamp0.95 glass1.6, glow0.75; night moon0.7, lamp1.28 glass2.4, glow1.0); 92 lights/1 glass-mat. Full-day sheet renders/cycles/20261112_d19a (04/06/08/12/16/18.5/20/22 + close night).
- [x] D19b. (ALSO: snapshot_pub.gd adds hero.max_hp, hero.xp_next, town.raids_turned - Mr. E approved 16:24, see COORDINATION 8.3) ATMOSPHERE: fog/haze, clouds, optional rain, sky gradient + stars at night, soft god-rays. DONE: shots across time/weather; FPS holds. TICKED D-cycle 116: custom sky shader (clouds/stars/sun+moon), weather machine clear/overcast/rain + streak rain, fog by weather + dawn mist, volumetric god-rays; 9-shot sheet, D19B_FPS avg 110.3; snapshot adds max_hp/xp_next/raids_turned + day_phase/weather, W1A_TEST OK.
# Phase E - life & simulation depth [D20]
- [x] D20a. RICHER ROUTINES (notables/townsfolk): work->market->tavern->home by hour, right anim per activity. DONE: town soak shows routines.
      DONE D-cycle 117: townsfolk.gd _maybe_errand - ordinary shuttle folk break off ONCE a day for a midday MARKET
      shop (buy/haggle anims) and an after-shift TAVERN mug (eat/drink), each at its own staggered hour, interrupting
      the linger so a 25-50 s job stint never swallows the short midday window; notables keep their hour-slot days.
      D20A_TEST PASS (market 8, haggle 33, midday-square 358; tavern 5 + eat; notables reached 17/24; 0 empty clips).
      parse 0, OFFFLOOR 0/1027, TWITCH_PARSE OK, _townwalk in_solid 0/18496 stuck 0, _delve 0 SCRIPT ERROR. Night-home
      (homed folk walk the compressed night, pre-existing) out of scope. renders/cycles/20261112_d20a.
- [x] D20b. CROWD REACTIONS: raid sends civilians fleeing/indoors; market bustle by hour; festival gathers. DONE: raid in a soak clears the streets.
      DONE D-cycle 122: a raid is now an ALARM the townsfolk read (town.is_raid_on <- raids._live). Ordinary folk (not the
      watch/chief/lookouts/stallholders) drop their routine and RUN for cover - home, else the nearest house (town.flee_refuge),
      ducking indoors at the threshold - so the streets clear; they cower until the all-clear, then ease back out staggered. A new
      FESTIVAL beat (town._festival_pass, is_festival/festival_at) gathers idle folk to the square to mill and cheer. Market bustle
      stays D20a's midday errands. D20B_TEST PASS (base_street 120 -> raid_street 52; fled OK; festival square 3 -> 42, gathered OK).
      parse 0, OFFFLOOR 0/954, TWITCH_PARSE OK, _townwalk in_solid 0/14380 raid 0/2095 PASS, _delve 0 SCRIPT ERROR. LOOK renders/cycles/20261113_d20b.
- [x] D20c. ANIMALS: herds graze/drift, dogs follow, birds flock. DONE: animal-behaviour probe in a soak.
      DONE D-cycle 127: herds now have a shared drifting centre (Animal.HerdMind) that ambles the pen, and
      each beast grazes near it, so a herd moves together and stays clustered instead of each on its own
      random patch; the sheepdog works its flock's centre (orbits the drift, not the fence); the four town
      dogs trot after the nearest townsperson; and birds now fly as flocks - a shared centre that migrates
      across the sky plus a shared turn direction and small per-bird angle offsets, so they wheel as a knot
      and travel together rather than each circling its own point. tools/_d20c_test.gd soak: herds=4
      moved 13.5 m / cluster radius 3.5 m, dogs follows=4 min_dist 0.5 m near_frac 1.00, flocks=8 migration
      11.1 m / 0 scattered samples. D20C_TEST PASS. parse 0, OFFFLOOR 0/1354, TWITCH_PARSE OK, _townwalk
      in_solid 0/17115 (0.000%) PASS, _delve_test clean. renders/cycles/20261113_d20c.
# Phase F - magic & combat feel (town) [D21]
- [x] D56. GRASS MATERIAL WIRED TO DIRT (high priority, desktop). Owner: DESKTOP BUILD.
      assets/kit/materials/MI_Grass.tres references T_Dirt_BaseColor/Normal/Roughness - the "MI_Grass"
      material literally uses DIRT textures. D45 re-graded ground.gdshader (the main lawn reads green),
      but THIS material instance was never repointed, so any surface using MI_Grass still looks like
      dirt/sand. Fix: point MI_Grass.tres at real CC0 grass textures (or the same source D45 used),
      correct tiling; if no grass texture asset exists, create/copy a CC0 one with a LICENSE note.
      Render the areas that use MI_Grass and LOOK. DONE: those surfaces read as grass, Mr. E confirms.
      RESULT (D-cycle D6, 2026-11-13 ~21:25): MI_Grass had NO untinted consumer - all three uses
      (town.gd dirt path L1395, town.gd farm soil L2830, valley.gd _soil L130) duplicate it and
      OVERRIDE albedo to brown, i.e. it was a mis-named DIRT material. Blindly repointing it would
      have turned paths/soil green. Fix: MI_Grass.tres repointed to the REAL grass source D45 used
      (T_Meadow_BaseColor/Normal) + albedo Color(0.5,0.92,0.34) mirroring ground.gdshader grass_tint,
      uv1_scale 0.16; NEW MI_Dirt.tres = the old MI_Grass dirt content verbatim; the 3 dirt consumers
      repointed MI_Grass->MI_Dirt (tints unchanged -> dirt paths/soil pixel-identical, no regression).
      No new texture asset (T_Meadow already tracked), so no LICENSE note needed. Swatch render:
      MI_Grass reads as green grass, MI_Dirt as brown dirt (renders/cycles/d56/swatch.png); town
      greens/fields unchanged (renders/cycles/d45/d56_*). Gate green. NOTE for Mr. E: nothing in the
      town assigns MI_Grass untinted yet, so the on-stream look is UNCHANGED - the material is now
      correctly a grass material, available to paint on a surface if he wants one specific ground
      (e.g. the trodden dirt paths) to read as grass. Awaiting his eye.

- [x] D21a. spells.gd VFX: bolts/heals/buffs with real particles/trails/impact; mages/clerics cast visibly. DONE: raid soak shows spell VFX. (D21A_RAIDVFX OK: 3 kinds mend/heal/ward fired visibly in a lvl-2 scar raid with mage/cleric/sage enlisted; test harness fixes: notables.gd:606 dict entry, _d21 enlist-retry + headless _snap guard.)
      TICKED (supervisor, Nov 15): shipped laptop e6a6812. D21b sub-parts landed on top the same
      night - D21b.1 hit FX parity (9d332ab), D21b.2 defender deaths read (5d420c2), D21b.3 guards
      form a muster line (29c5658).
- [x] D21b. RAID COMBAT FEEL: hit reactions, impact FX, deaths that read, guard formations, a cavalry charge that lands. DONE: raid soak, FPS holds.
  - [x] D21b.1 defender hit FX parity: a Townsfolk/HeroBody taking a melee hit now flashes white and a floating damage number pops (matches raider side); townwalk in_solid 0/6172 (4 raid cycles).
  - [x] D21b.2 defender deaths read: a Townsfolk/HeroBody that is slain by a raider (and a non-Monster raider slain by the defenders) gets a red flash + FELLED! banner at the one real death point in raids.gd, so the stream reads who just dropped at pane distance. Parity with Monster.die()'s own readable death; KO/grace/CON-save paths unchanged. Headless gate: parse 0; _offfloor 0/1340 INPROP 0 MON_INPROP 0; TWITCH_PARSE OK; _delve_test rc 0 no SCRIPT ERROR; _townwalk runs clean (in_solid=1/10898 at T=70s = 0.009%, well under PASS<0.2%).
  - [x] D21b.3 guard muster line: before the garrison closes with the raiders, each
    guard takes a slot on a line drawn between the market centre and the raiders'
    centre of mass (LINE_FROM_CENTRE 11 m, LINE_SPACING 2.2 m), facing them, until
    a raider closes within LINE_HOLD 14 m - then normal _engage kicks in. Heroes,
    the mounted watch and the Commander are untouched (they keep charging / the
    square-hold / leading from the front); the line dissolves once the raiders'
    centre is inside LINE_BREAK 22 m of the square, so a breach still fans the
    guards out one-to-one. Gate GREEN: --import rc 0, parse 0; _offfloor 0/1320
    INPROP 0 MON_INPROP 0; TWITCH_PARSE OK; _delve_test rc 0 no SCRIPT ERROR;
    _townwalk in_solid 1/14956 (0.007%) raid_in_solid 0/2930 (0.000%) PASS;
    tools/_d21b3_test.gd D21B3 OK 8 checks (8 raiders live when sampled, 8 of 14
    muster-eligible guards had left their posts, 4 had closed toward the raiders'
    centre, 2 stood on the line within 3.5 m). D21b REMAINDER: cavalry charge
    that lands, FPS soak.
  - [x] D21b.4 the mounted watch's CHARGE LANDS (raids.gd): a rider >9 m from his mark lowers the lance and
    gallops in at 1.3x; after >=6 m of run-up the blow is rolled twice (keep the better) +2d6, throws the raider
    back 2.4 m, tramples every raider within 2.6 m (1d6 + 1.3 m push), dust burst + ground ring + horse neigh +
    a gold CHARGE! banner, one Chronicle line per raid ("X's charge crashes into a bandit!"); then he wheels out
    12 m and comes again. tools/_d21b4_test.gd D21B4 OK headless (4 riders, 2 charges, 2 landed, 4 trampled) and
    windowed 1080p (6 charges, 5 landed; shot renders/cycles/d21b4/charge_A.png). FPS soak, same 30 s raid window
    A/B: with charges avg 76.4, with charges disabled avg 75.5 -> FPS-neutral. Gate GREEN.
  RESULT (D21b closed, 2026-11-15): all five parts shipped (hit FX, deaths, muster line, charge, FPS soak).
  NOTE FOR MR. E: raid-time FPS on cruzader sits ~50-60 for the first ~14 s of a raid from the overview camera
  WITH OR WITHOUT the charge (baseline min 48) - that is D23's job, not a D21b regression.
# Phase G - audio polish (owns sfx.gd) [D22]
- [x] D22a. MIX & SPATIALISATION: layered ambience (market/smith/river/birds), footsteps, combat/spell sounds, GAP-throttled. Also bump the 3D pool 16->24 (D15 peaked 16/16). DONE: sound review + short audio soak, GAP holds, 0 audio errors.
  RESULT (game build, 2026-11-15 05:35 CT): sfx.gd - 3D pool 16->24 with free-voice-first allocation and priority
  stealing (PRIO table; footfalls/animal/town voices are low and are DROPPED rather than steal: pool >=18 busy, an
  8-per-0.25s burst budget, or >60 m from the ear). Layered positional BEDS on a new Beds bus: river x7 along the
  banks, market murmur over the square, forge fire at the anvil (3 new CC0 loops made here, LICENSE noted); market
  and forge sleep at night and shut for a raid, the river runs on 6 dB lower. GAPs added for animal + townsfolk
  voices. "roar" (delve.gd's lord rising) had no sound set - now it does. tools/_d22a_test.gd: 90 s 4x soak + forced
  raid OK (peak 18/24 voices, 0 steals, GAP held for every kind, 0 silent callers, beds 9/9 playing, market -60 dB /
  river -8 dB under the raid). Windowed recording renders/cycles/d22a/soak.ogg + soak_review.png: discrete
  footfalls above the bed throughout, horn at the raid, 0 clipped samples, peak -8.6 dBFS. Needs Mr. E's ear.
- [x] D22b. MUSIC MOODS: smooth day/night/raid transitions, victory/defeat sting; keep 24/7-safe (D15). DONE: transition review.
  RESULT (game build, 2026-11-15 ~07:00 CT): sfx.gd - four moods (day/night/raid/delve; delve = a delve is live below), HOLD 2 s hysteresis (a raid moves at once), per-transition equal-power crossfades (raid in 1.5 s / out 6 s, day<->night 8 s, delve 5 s), beds RESUME where they left off, raid cue from the top; victory sting when a raid is driven off or a delve comes home, defeat sting when a delve has no survivors (20 s gap, -8 dB bed duck). tools/_d22b_test.gd D22B_TEST OK 18/18 headless AND windowed; transition review renders/cycles/d22b/moods_review.png + moods.ogg (112 s, peak -8.6 dBFS, 0 clipped).
      MR. E'S CALL (Nov 15): generate fresh from music-studio with the mapping below. Pairs with D38 -
      do them together; D38 renders the tracks, D22b wires the transitions and stings.
# Phase H - performance (stretch) [D23]
- [ ] D23. (measured per COORDINATION 8.5: publisher + chat on, L32 grid up) Hold 100+ FPS on a long busy stream: extend D7 LOD, cull far detail, kill the ~1.5 s floor-build hitch, cap particle emitters, cheap nav rebakes. DONE: 30-min soak fps_avg >= 120, no sustained dips.
  PROGRESS (game build, 2026-11-15): LOD now follows the cameras that DRAW (the panes), by on-screen size, with an
  unseen tier; poses on the physics tick; animals LOD'd. tools/_d23_soak.gd 30 min: fps_avg 114.6 (baseline ~97),
  D23_SOAK FAIL against the >=120 bar. COMMITTED f16496b (2026-11-15 ~09:22 CT) per the supervisor directive after
  a green gate re-run; D23 stays OPEN. Remaining: the 1.5-3 s floor-build hitch is LAPTOP code
  (DungeonHD/FloorGen/delve.gd), not D23's to fix; and the director pane on the busy market.

### LAPTOP (dungeon/combat/content/UI) - floorgen.gd, dungeon_parts.gd, dungeon_hd.gd, bestiary.gd, monster.gd, gear.gd, roster.gd, chatcmd.gd, delve.gd, data/*, UI files (rts_camera, feed_hud, leaderboard_panel, party_frames, boss_bar, auto_director, health_bar_3d, spotlight)
# Phase A - dungeon geometry & nav [L25]
- [x] L25a. STAIR INTEGRITY: continuous treads, correct step vs G=4.0/floor height, landing both ends, registered walkable. DONE: stair-probe over 12 floors, 0 gaps, landings both ends.
- [x] L25b. COLLISION-AWARE PROPS: no prop-prop or prop-in-wall overlap, clearance from doorways/path; placement validator reseats/drops overlaps. DONE: overlap probe 12 floors = 0 > 0.2 m, 0 blocked doorways.
- [x] L25c. DUNGEON NAV: bake a NavigationRegion3D per floor (open cells minus obstacle circles + walls, like TownNav) OR cell-grid A*; route delvers on it + unstick watchdog. DONE: 10-floor descent = 0 stuck delvers, 0 in geometry.
      DONE (Cycle 89 + L-cycle 110, laptop): tools/_l25_test.gd OK 13/13 twice - 0 stuck delvers (was 104), 0 forced descents,
      watchdog 5 and 1 nudges / 10 floors (was 51). Nav = cell-grid BFS over clear cells + obstacle circles, reachable fight slots.
- [x] L25d. ROOM/CORRIDOR COHERENCE: no orphan rooms, all reachable, doorways align, tiles don't z-fight. DONE: connectivity check over 12 floors, shot sheet.
# Phase B - dungeon look: textures/materials/biome/lighting [L28]
- [x] L28a. MATERIALS: real albedo/rough/metal per theme+biome, normals where the kit has them, fix material-null. DONE: 0 material-null, before/after 3 themes.
      DONE (L-cycle 111): kit surface shader - per-swatch rough/metal + triplanar CC0 stone/wood detail + theme wetness; materials per floor 689 -> 44 (tinted biome); dungeon-side material-null 0. Shots renders/cycles/20261112_l28/a_*.
- [x] L28b. BIOME DISTINCTION (data/biomes.json ~14 worlds): colour grade, fog/haze, ambient particles, ground variants - each biome its own place. DONE: per-biome shot sheet, no two alike.
      DONE (L-cycle 112): per-floor Environment from data/biomes.json "looks" (ambient, depth+height fog, 1D-LUT grade, sat/contrast, glow) seen by the main camera + lanes; one capped mote emitter; ground patches. L28_ALIKE OK 14/14. Sheet renders/cycles/20261112_l28/all_sheet.png.
- [x] L28c. LIGHTING/ATMOSPHERE: per-floor key+fill, torches/braziers as OmniLights w/ embers, depth fog, boss-floor drama. DONE: shot sheet, FPS holds (cap emitters).
      DONE (L-cycle 113): look-driven key (1 shadowed spot) + fill, flickering torches/braziers, ONE shared ember emitter, boss lord light+ash+harder grade; emitters 2-5/floor (cap 12); FPS -1..-7% (all >=115); sheet renders/cycles/20261112_l28/c_sheet.png.
- [x] L28d. DETAIL DECALS: cracks/moss/blood/scar-glass veins to break repetition. DONE: varied-floor shots, 0 new errors.
      DONE (L-cycle 114): self-made CC0 decal textures (tools/_l28_decals.gd -> assets/dungeon_look) - cracks everywhere, moss/soot/blood by theme, glowing scar-glass veins from floor 6; 18/floor (cap 24) on room floors + wall bases, never stairs/keep-clear; 0 new errors, FPS unchanged; sheet renders/cycles/20261112_l28/d_sheet.png.
# Phase G - the stream's resting state [L32] (Mr. E, Nov 12 16:08 - a CORRECTION of the spotlight's idle behaviour; jumps the queue)
- [x] L32a. SPOTLIGHT ALWAYS-ON: the 2x2 grid is the stream's RESTING state, up 24/7 - never collapse to a single full-screen view. An idle lane shows AMBIENT LIFE: a rotating shot of random heroes, NPCs, town life or the dungeon (new subject every ~20-30 s; prefer something happening - a job, a fight, animals, the market). Paid moments (bits/subs/points) take their lane for the seconds bought, QUEUED IN ORDER - the first payer gets their FULL time, then the next in line (the existing per-lane queues already do this - keep them). When a paid moment ends and the queue is empty the lane returns to AMBIENT, never to blank, never collapsing the grid. Keep F10 labels toggle and the SubViewport perf model (the main view stops drawing 3D while the grid is up - which is now always). DONE: a soak shows all four panes live with ambient rotation while lanes are idle; a scripted influx of bits/subs/points plays out in order, each for its full seconds; FPS holds.
      DONE (L-cycle 116): grid permanent (off/pair layouts gone), idle lanes rotate ambient subjects 20-30 s (fight > catch > heroes > folk > animals), paid FIFO kept - influx played in order, each full seconds; back to ambient on drain. L32_TEST OK 102 checks; FPS vs old full-screen 41.9 -> idle 28.8 / paid 21.6 (relative checks pass); shots renders/cycles/20261112_l32/. Guild Roll + director banner now never show (hid whenever panes carried the view) - needs Mr. E's call on a new home.
- [x] L32b. (SUPERSEDED BY L39 - Mr. E rejected the full-width bar, Nov 12 22:25)  CHRONICLE AT THE CENTRE: the on-stream Chronicle moves to the MIDDLE of the 2x2 - a thin strip or vertical bar at the cross of the four panes (Mr. E's original ask) - with calm pacing so a busy moment does not scroll like crazy (batch or fade, cap lines per second); readable at 1080p. DONE: 1080p capture with the grid up and the Chronicle at the centre; a busy-moment pacing check.
      DONE (L-cycle 117): full-width centre strip (HudDock.STRIP 0.10) parts the pane rows; chrome slimmed to 0.06 (clock/chat only); Chronicle paced - 1 line / 0.8 s, flood skips to the latest 8, fade-in; lord card resized to fit the strip. L32B_TEST OK 9/9 (pacing: 40-line flood stayed calm, caught up to latest); L21 52/52 with the new centre region; shot renders/cycles/20261112_l32/b_centre_1080.png.
# Phase C - creatures: animation + roster [L26/L27]
- [x] L26a. ANIM AUDIT across the WHOLE bestiary: every family map resolves to real clips, fallback when missing (no T-pose/glide); monster.gd states drive the right clip; attack timing lines up. DONE: MON_ANIMS = 0 static.
      DONE (L-cycle 115): tools/_l26_anims.gd - MON_ANIMS static=0 (13575 moving frames, floors 2/5/9), every def resolves; clip fallbacks, procedural flinch for 7 bodies with no hit clip, run when chasing fast, 2nd attacks, melee blows land at the clip contact (0.26-0.60 s). L25 OK.
- [x] L27a. NEW MONSTERS from owned CC0 packs (KayKit Skeletons/Halloween, Quaternius - NOT Bestiary/QAL): add to TYPES with height/anim map/depth/strain. DONE: appear at depth in a soak, animate, parse clean.
      DONE (L-cycle 118): 9 new creatures from owned bodies (no Halloween pack on disk) - marrow hewer, pale cutthroat, silk mother (+spiderling fodder), scar rat, fen lurker, pit wyrm, ash wight, gloom bat - each with height/anims/tint+glow/ways/homes, wired into DEPTHS 6-7/8-9/10+. L27A_TEST OK; deep soak (floors 7/9/11) static=0 of 21637, hewer/ash wight/cutthroat seen fighting; parse 0; line-up shots renders/cycles/20261112_l27/.
- [x] L27b. STRAINS (data/strains.json): widen coverage + a clear visual tell each (glow/particle/scale). DONE: strain probe shows tells, stat mods apply.
      DONE L-cycle 136: the code landed at 0f3986c and only ever owed three test runs; closed now rather
      than left as a WIP the supervisor skips. _l26_anims cleared in L-cycle 119 (static 0 of 20819
      moving frames); _l25_test OK 13/13 on current HEAD with 0 stuck; and the windowed line-up finally
      judged by eye. RE-VERIFIED ON CURRENT HEAD rather than trusting the old run - bestiary.gd and
      monster.gd have been through L45, L48 and L50 since - L27B_TEST OK: json still the authority, every
      named strain still has a tell, stat mods still apply through Bestiary.make.
      THE TELLS READ: renders/cycles/20261112_l27/b_lineup + b_left/mid/right. All ten strains distinct
      at a glance, and all three kinds of tell land - GLOW (scarborn mint, wraithtouched violet),
      PARTICLES (wraithtouched wisps, emberbound sparks) and SCALE (gorged plainly biggest, no glow).
      Checked rather than assumed: L42 cut dungeon emission two cycles ago and could have dimmed the very
      tells this item exists for. It did not.
      FOR MR. E, carried from the original WIP: the strain re-weighting of the 6-9 and 10+ bands is a
      BALANCE CHANGE (shares taken from the non-plain pool; shallows stay 85% plain). No existing
      strain's frozen numbers were touched.
# Phase D - bosses & encounters (canon from NOTES.md/bosses.json) [L29]
- [x] L29a. LORD MECHANICS: each canon lord gets a real mechanic (adds/phase/hazard/enrage); boss_bar shows phase; per-phase trappings. DONE: boss harness 0 errors, a delve fights a lord with its mechanic.
      DONE L-cycle 139 (one part BLOCKED - see the end). MEASURED FIRST and it halved the work: all EIGHT
      canon lords ALREADY carried a real mechanic in LORD_WAYS, so "each lord gets a mechanic" was
      already true and nothing was invented on top of working canon. What was missing was a PHASE - only
      3 of 8 had any threshold, and nothing exposed one for a bar to read.
      monster.gd: three phases a lord (0.66 / 0.33), advancing as it is worn down, never backwards;
      phase and phase_count public; phase_changed(who, to) emitted. Ordinary creatures stay at 1.
      PER-PHASE TRAPPINGS: the aura brightens (0.35 -> 0.53 -> 0.71) and breathes faster and wider each
      phase, name tag with it - the phase reads off the LORD, not only off a bar.
      delve.gd: each step is a Chronicle beat plus a FeedHUD card naming the phase.
      A PRODUCT FIX THE TEST FOUND: phase_count was set after the early return in _ready that fires when
      a body model will not load, so a lord without its mesh would have had NO phases. Set at the top now.
      tools/_l29a_test.gd L29A_TEST OK (11 checks). AND IN A REAL FIGHT, since the DONE asks for one:
      _boss_test.gd windowed BOSS_TEST OK, 8 checks, 0 failed, zero script errors - and the phases fired
      live ("Nightwing shifts, and the fight changes with it", then "driven to its last").
      _offfloor 0 of 1403, _delve_test clean, L45_TEST OK, L27B_TEST OK, _l26_anims on the LORD floors
      5/10/15 L26A_ANIMS OK.
      BLOCKED, NOT DONE: "boss_bar shows phase". scripts/boss_bar.gd is in NO worker's list in
      COORDINATION 11.2 - the second unowned file after adventurers.gd. Untouched. Monster.phase,
      phase_count and phase_changed are exposed and live, so its owner need only read them. NEEDS AN OWNER.
- [x] L29b. RARE UNIQUES (NOT new lords - modified variants, bosses.json lesser/greater/draw/rule): rare spawn, visible modifier, better loot. DONE: a unique rolls + drops in a soak.
      DONE 2026-11-13 (L-cycle 140). MEASURED FIRST and it moved the item: bestiary.gd already had a
      UNIQUES table, but those are the L2 FLOOR-uniques (new named things on an ORDINARY floor), which
      is the opposite of what L29b asks for. The real gap was where the supervisor pointed - the content
      writer has WRITTEN all 78 variants in data/bosses.json and no code read that file. Now read, never
      copied; no parallel table invented; data/bosses.json NOT touched.
      SPAWN RULE: 18% on a lord floor, only variants of the lord actually drawn, never the same one
      twice running, and a lord the crowd has named keeps its name.
      VISIBLE MODIFIER: the writer's stat skew carried in its SIZE (Grubmother Winter-Fat 5.40 -> 5.84,
      Nightwing Famished 3.84 -> 3.59) plus a cold scar-light in tint/aura/weapon. Flagged "rare", which
      boss_bar.gd ALREADY reads - the stream shows it with NO UI file touched.
      STILL A LORD: same body, same LORD_WAYS mechanic, same L45 depth curve.
      BETTER LOOT: Delve.boss_loot_mult() - rare lord 4.5x vs a plain lord's 3.0x, in ONE place so the
      test reads the number the Chronicle actually pays.
      tools/_l29b_test.gd L29B_TEST OK (23 checks, 0 failed), INCLUDING THE SOAK the DONE line asks for:
      "The Rattling Host, Widowed" rose on floor 5 of a real delve and the hoard was paid out.
      The soak also caught a PRE-EXISTING bug in delve.gd: _loot formatted every "cleared" line with
      % floor_no, but one written line carries no %d, so it threw a String formatting error whenever
      that line came up. Guarded (the content file was not at fault and was not touched).
      REGRESSION: _offfloor 0/1438, _l25_test OK (0 stuck), _l45_test OK, _l2_test OK, _l29a_test OK.
      FLAGGED: boss_def() never copies BOSS_DEFS' "spd", so a plain lord moves at its BODY's speed and
      Nightwing's canon 6.6 has never reached the mover. Raised, not silently changed - it would alter
      how every lord moves mid-cycle.
- [ ] L29c. SET-PIECE ENCOUNTERS from lore (ambush/guarded hoard/mini-event) so a floor isn't just a room of monsters. DONE: set pieces appear + resolve, Chronicle logs them.
# Phase E - gear, cosmetics, loot [L30]
- [ ] L30a. GEAR EXPANSION (items.json accessories): more weapons/armour per tier, visible on handslot bones (rig EQUIP), real bonuses. DONE: heroes equip visibly in a soak, bonuses apply.
- [ ] L30b. COSMETICS & DYES (items.json): more cloaks/hats/rings/amulets/boots/gloves; !wear/!dye change the model live; channel-point cosmetics gated (needs T1/Mr. E). DONE: !wear + !dye change the model in a soak.
- [ ] L30c. LOOT TABLES by depth/biome/boss; boss uniques; Chronicle announces rare finds. DONE: loot scales in a 10-floor soak, a boss drops its unique.
# Phase F - dungeon-side UI / readability (stretch) [L31]
- [ ] L31. Dungeon-fight UI (party frames, boss bar, feed HUD): damage numbers, status-effect icons, "Now fighting: <lord>" banner, legible at 1080p. Keep the parchment+ink+teal theme. DONE: 1080p capture, HP/damage/statuses/phase readable.

### HUB (web/ only) - hub builder owns web/index.html, app.js, style.css, NOTES.md, docs/HUB_SECURITY.md. Keep the el()/textContent + ICON_SET + CSP model. Republish gated on supervisor review.
- [x] H1. VISUAL ELEVATION to an SSS+ grimoire: ornate frames/borders, parchment texture, illuminated drop-cap heads, richer hero character-sheet cards, tier badges on boards, better animated d20, micro-anims (respect reduced-motion). Responsive: phone/desktop/overlay. DONE: before/after at 3 widths; security invariants + hostile-name test pass.
- [x] H2. CHRONICLE on-site + filter tabs by type (combat/loot/boss/town/chat) + per-type icons + text filter + pause-on-hover (keep the on-stream strip in-game). DONE: filters work vs ?mock=chronicle, legible at 1080p.
- [x] H3. HERO SHEETS deepened: stat block + mods, class/species crest, level/XP, HP, equipped gear w/ icon+tooltip, cosmetics/dyes, title+epitaph for the Fallen. Keep paging (HERO_PAGE 60). DONE: ?mock=crowd 200 fast, ?open=1 full sheet.
- [x] H4. BOARDS/LEADERBOARD tiers (SSS/SS/S/A/B) styled, sort tabs, Guild Roll + Fallen, town-status strip (day/pop/treasury/raids). DONE: tiers + sorts render, status strip live.
- [x] H5. TWITCH CHAT EMBED + clickable local d20. CAUTION: minimal CSP change for the embed, documented in HUB_SECURITY.md, flagged for supervisor review; page stays read-only. DONE: chat loads, d20 rolls, CSP documented, invariants intact.
- [x] H6. TWITCH LOGIN scaffolding (device-code OAuth, public client id) so viewers see their own hero - the client id is NEEDS-MR.-E; wire against a placeholder. Still no viewer writes (read-only through Phase 2). DONE: flow wired/testable w/ placeholder, token step gated on Mr. E.
- [x] H7. PERF/A11Y/POLISH (stretch): fast first paint, no layout shift, lazy-render the crowd, reduced-motion, contrast+focus, keep offline/stale honesty. DONE: fast on a phone, a11y pass, invariants intact.
- [x] H14. THE CHRONICLE REMEMBERS (Mr. E's world should have a past, not just a present). Owner: HUB BUILDER (web/app.js, web/style.css, web/NOTES.md). Today the hub's Chronicle shows only what is in the current snapshot row, so a viewer who comes back after an hour has missed everything. Keep a rolling client-side history in the browser (localStorage, newest-first, hard-capped - roughly the last 300 entries or 48 h, whichever is smaller, and drop the oldest first so storage never grows without bound). On load, show the live snapshot entries first, then a quiet "Earlier" divider, then the remembered ones, with day dividers in the town's own voice. De-duplicate against the live set so nothing appears twice. This is READ-ONLY and per-browser: no write path, no new fetch, no new origin, no CSP change. Remembered entries are attacker-controlled Twitch text that has been through one storage round-trip, so they must come back out through the SAME el()/textContent path as live ones - never innerHTML, never a URL/src/href/style, icons only via the ICON_SET whitelist. Storage can be absent, full or throw (private windows): every read and write wrapped, and the page must render correctly with the history empty or unavailable. DONE: with ?mock=chronicle, load, change the mock, reload - older lines appear under "Earlier" with a day divider and no duplicates; a hero named <img src=x onerror=alert(1)> survives a store-and-reload and still renders as literal text; clearing site data leaves the page working; the stored payload stays under the cap after a long session.
  RESULT (2026-11-15, hub 456dc7f): localStorage key `bellmire.chron.v1`, newest first, capped at
  300 rows / 48 h / ~120 KB with the oldest dropped first. Live snapshot lines paint first, then an
  "Earlier" divider, then remembered lines under day dividers in the town's voice ("Earlier today,
  by the bells" / "Yesterday, as the town tells it"). De-duplicated against the live set by kind+text.
  SUPERVISOR SECURITY REVIEW (passed, independently re-run on the merged tree): stored rows are
  re-cleaned on read (ctrlStrip, 400-char cap, kind and ISO-timestamp regex) and then go through the
  SAME chronShape + el()/textContent path as live lines; icons stay on the CHRON_ICON whitelist; no
  stored or snapshot field becomes a URL, src, href or style; every localStorage access is wrapped so
  an absent, full or throwing store leaves the page rendering; the raw string is length-checked before
  JSON.parse. CSP byte-identical, no new fetch, no write path, KNOWN_V unchanged. node --check passes
  and the only innerHTML sites are the two pre-existing page-owned ones. The hostile-name test passed
  across a store-and-reload in the worker's headless Edge run.
  NOT PROVEN: the 48 h and 300-row caps were read, not exercised by a long session. The code paths are
  simple and bounded, so this is a low-risk gap, but a future hub run should exercise them for real.

- [x] H15. EVERY HERO GETS A CREST (heraldry - the single cheapest way to make 200 names read as a guild). Owner: HUB BUILDER (web/index.html, web/app.js, web/style.css). Give each hero a small coat of arms, drawn as inline SVG the page owns, derived deterministically from the hero's name: hash the name, then pick a field division, two tinctures and one charge from PAGE-OWNED whitelists (the same discipline as ICON_SET - the snapshot value chooses WHICH known shape, it never supplies one). Use the existing palette - deep ink, parchment, the one teal, restrained gold - so the crests read as one house, not a rainbow. Show the crest on the hero card, larger on the opened hero sheet, and beside the top entries on the boards. Keep it cheap: no image files, no new fetch, no CSP change, and the crest must not slow the 200-hero mock's first paint. DONE: the 200-hero mock shows visibly distinct crests with no two adjacent cards looking alike at a glance; the same name always yields the same crest across reloads; a hostile name renders as text AND still produces a valid crest; first paint on the 200-hero mock is no worse than before (state the before/after number).
  RESULT (2026-11-15, hub 2067316): page-owned inline SVG coat of arms, FNV-1a over the lowercased
  name seeding indices into fixed whitelists (7 field divisions, 4 tinctures from the existing ink/
  parchment/teal/gold palette, 8 charges). SUPERVISOR SECURITY REVIEW (passed): every path and colour
  is a constant in app.js, elements are built with createElementNS, and no snapshot value reaches any
  attribute - a hostile name only chooses WHICH known shape, so it still yields a valid crest and can
  never become markup, a URL or a style. Memoised (cap 600) and shown at three page-chosen sizes: hero
  card, opened sheet, and the top five board rows. No image files, no new fetch, CSP byte-identical.

- [x] H16. THE HALL OF THE FALLEN. Owner: HUB BUILDER (web/index.html, web/app.js, web/style.css). The Fallen list from H4 is a list of names; make it a memorial a viewer would stop and read. Per fallen hero: the crest (H15 if it has shipped), the epitaph, what took them, how deep they got, their level and the gear they were wearing when they fell - whichever of those the snapshot actually carries. The content writer has already written the words: epitaphs live in data/lore_lines.json and were frozen into the hub by H12 - read from what is already there, do not invent a parallel set. Fields the publisher does not send yet must degrade quietly to an honest blank, never to "undefined" and never to a guess; list in web/NOTES.md any field you wanted and the snapshot lacks, so the supervisor can raise it with the game build worker. DONE: a mock with fallen heroes shows the memorial with epitaph and cause; a mock whose fallen rows carry only a name still renders cleanly with no console error and no placeholder junk; the hostile-name test passes in the new section; the no-scroll H13 tab discipline still holds.
  RESULT (ticked by supervisor, 2026-11-15 05:05 CT): shipped hub 2fd5e22, merged to main. The Fallen are now <article> memorial cards: H15 crest + name + "the <class>, level N", earned title, epitaph in quotes, then a fact block (Taken by <cause>, day N / Deepest floor N / Slain N foes / Wore <weapon> + <armour> with whitelist icons). Every field is optional and simply not drawn when absent - no "undefined", no guesses. New ?mock=fallen carries a rich row, a hostile-name row with markup in EVERY field, a name-only row and a row of nulls/NaN. All text still goes through el()/textContent; icons still come from the page-owned whitelist; no innerHTML, no new fetch, CSP byte-identical.

- [x] H17. THE HUB ON A PHONE. Owner: HUB BUILDER (web/index.html, web/style.css, web/NOTES.md). Most viewers reach a Twitch stream's companion page on a handset, and H13's tabbed no-scroll layout was designed at desktop width. Make the hub work at 390x844 and at tablet width: tabs reachable with a thumb and never clipped, hero sheets readable without pinch-zoom, the Chronicle legible, the die and boards not overflowing, tap targets at least 44 px, no horizontal scroll at any supported width. Refine the existing layout - do not replace the palette, the Gloock wordmark treatment or the tab model. No framework, no new font, no CDN, no CSP change. DONE: screenshots at 390x844, 768 and 1280 wide, all three with zero horizontal scroll; every tab reachable and every section readable at 390 without zoom; ?state=empty ?state=fail ?state=stale ?mock=chronicle ?mock=crowd ?open=1 all still pass at 390; hostile-name test still passes.
  RESULT (hub builder, 2026-11-15 05:40 CT, 448098d): the tab rail became a 44 px snap-scroll strip that never
  clips at 360 px; tap targets raised to 44 px throughout; a 12 px type floor and 16 px form fields (no iOS
  zoom-on-focus); hero sheets, Chronicle, boards and die reflow with no horizontal scroll from 360 to 1280.
  Palette, Gloock wordmark and the H13 tab model untouched; no framework, no new font, no CDN, CSP byte-identical.
  All six query-string states pass at 390 and the hostile-name test still renders as literal text.

- [x] H18. THE TOWN ITSELF, NOT JUST ITS HEROES - "THE STATE OF BELLMIRE" (a whole section, staged). Owner: HUB BUILDER (web/index.html, web/app.js, web/style.css, web/NOTES.md). The hub tells a viewer everything about the PEOPLE and nothing about the PLACE. A newcomer who opens the page mid-stream cannot tell what Bellmire is, how far it has come, or what has been happening to it. Build a Town tab that answers that in one screen, in three staged parts under this one ID:
      H18.1 THE LADDER. The town's growth tier shown as a ladder from Crossing to City, with the current rung lit, the rungs behind it filled, and the rungs ahead named but dim - so a viewer sees at a glance that the town is a Hamlet with seven stages still to climb. Beside it the live status the snapshot already carries (day, population, treasury, raids survived) as proper stat tiles, not a text strip.
      H18.2 WHAT STANDS. A roster of the town's buildings, each with its page-owned icon from the ICON_SET discipline, its name, and one line of what it DOES - built ones solid, unbuilt ones as dim outlines, so the viewer sees what the town is missing as clearly as what it has. Drive it from whatever the snapshot sends; if the publisher sends no building list yet, render the known set from the frozen lore (the H12 pattern) and mark the section honestly as canon rather than live.
      H18.3 WHAT HAS BEFALLEN IT. A timeline of the town's raids, disasters and festivals - newest first, day-stamped, in the town's own voice - built from the Chronicle history H14 already keeps in the browser, filtered to town-scale events. It must survive an empty history (a quiet "Bellmire has known only quiet days" rather than a blank box).
      Rules unchanged and non-negotiable: every snapshot string reaches the DOM only through el()/textContent; no snapshot value becomes a URL, src, href or style; icons only via the page-owned whitelist; the CSP stays byte-identical; no framework, no CDN, no new font, no viewer write path. Any field you wanted and the snapshot lacks goes in web/NOTES.md so the supervisor can raise it with the game build worker. DONE: a capture of the Town tab at 1280 and at 390 wide showing the ladder, the building roster and the timeline together; ?state=empty ?state=fail ?state=stale still honest with the new section present; a snapshot carrying NONE of the new fields renders the tab without a single "undefined" or empty frame; a hostile town/building/event name renders as literal text; H13's no-scroll tab discipline still holds and H17's 390-wide pass still holds.
      DONE 2026-11-15 (hub bca363c, merged by the supervisor): the Town tab ships all three stages - the
      Crossing->City growth ladder with the current rung lit and the rest named but dim, a building roster
      (built solid / unbuilt dim outline) drawn from live snapshot data with the canon roster as fallback,
      and a town-scale timeline built from the H14 Chronicle history. el()/textContent, ICON_SET and the
      CSP all unchanged; the hub run reported the hostile-name test still renders as literal text.

- [x] H19. THE BESTIARY - WHAT BELLMIRE HAS LEARNED ABOUT WHAT IS DOWN THERE. Owner: HUB BUILDER (web/index.html, web/app.js, web/style.css, web/NOTES.md). A D&D campaign's players keep notes on the monsters; the hub should too, and the words already exist - the content writer's bosses.json lords and lore_lines.json tells and intros were frozen into the hub by H12. Build a Bestiary tab: one entry per lord and per monster family the town knows of, each with a page-owned sigil (reuse the H15 heraldry machinery with a different charge set so a lord's mark is distinct from a hero's crest), its canon name and description, its tells and its intro line, and - where the snapshot carries it - what the town has actually suffered at its hands: times faced, heroes it has killed, the deepest any party got against it, whether it currently stands. An entry the town has never met is shown as a RUMOUR: sigil and name present, details veiled, in the town's own voice - that unseen-monster tension is the point, so do not spoil a rumoured entry with data it should not have. Never state or imply a dungeon floor count anywhere in this section. Rules unchanged: el()/textContent for every string, no snapshot-derived URL/src/href/style, whitelist sigils only, CSP byte-identical, no new fetch, no framework, no viewer write path, and the frozen lore is read as-is - do not invent a parallel set of monster words. DONE: a capture of the Bestiary at 1280 and 390 wide showing at least one met entry with real numbers and one rumoured entry correctly veiled; a lord with no snapshot history still renders cleanly with no "undefined"; the same lord name always yields the same sigil across reloads; a hostile monster name renders as literal text; no floor count appears anywhere in the section or in the code comments; H13 no-scroll and H17 390-wide discipline both still hold.
      RESULT (bd8f190): Bestiary tab shipped - 8 lords (5 named) + 17 monster families, page-owned sigils from the H15 heraldry machinery, Met vs Rumour decided from the remembered Chronicle, honest gaps listed in web/NOTES.md. Security reviewed: every string through el()/textContent, no snapshot-derived URL/src/href/style, CSP byte-identical, no new fetch, hostile-name test green (docs/HUB_SECURITY.md H19 section).

# CHANGELOG 2026-11-15 10:58 (supervisor): THE HUB QUEUE IS NOT EMPTY. H14 (Chronicle remembers),
# H15 (crests) and H16 (Hall of the Fallen) have all shipped, been security-reviewed, merged and
# ticked. OPEN AND YOURS, in order: H17 (the hub on a phone), H18 (the State of Bellmire - the town
# itself, staged .1/.2/.3), H19 (the Bestiary). The hub worker's standing brief still carries a
# stale "the hub queue is EMPTY" line from before H14-H19 were written - THIS PLAN OVERRIDES IT.
# H18 and H19 are deliberately BIG (Mr. E's item-size directive at the top of this plan): take one,
# stage it, and finish it properly rather than taking all three shallowly.
# Take the first unchecked H item and say in your summary that you did, so the staleness is visible.
# Also stale in that brief: D57 is DONE (snapshot v=3 ships, the H11 Satchel has live data), and
# gh-pages c926030 publishes hub through db06c03, so LIVE IS BEHIND SHIPPED by H14. Republishing is
# Mr. E's call alone - it is not a bug for a hub run to fix.
# CHANGELOG 16:01 (supervisor): H1-H7 built, security-reviewed and PUBLISHED LIVE (gh-pages 0ac04f8). Twitch sign-in wired with Mr. E's public client id; the ?twitch_client override removed as a phishing vector. Hub queue is now empty - only Phase 3 (gated) remains.

# Phase 3 (NOT now - stays read-only until RLS designed): friends/party, a write-backed leaderboard, any viewer WRITE path.
## CHANGELOG 16:10 (supervisor): added L32a-b (spotlight always-on 2x2 + centre Chronicle), placed BEFORE Phase C at Mr. E's direction - it corrects the stream's idle look. IDs frozen as ever.

# Phase H - regression found by the supervisor (Nov 12 18:25)
- [x] L33. STUCK DELVER REGRESSION: after L27a (nine new monsters at depth) _l25_test went from a clean 0 stuck / 0 nudges to 1 stuck delver (floor 3, state=descend) in a 10-floor run. Likely the denser monster population crowding fight slots or the descend route. The watchdog still frees them, so it is not fatal, but L25's acceptance was 0. Reproduce, find whether it is spawn crowding or route blocking, fix, and get _l25_test back to 0 stuck. DONE: _l25_test OK 13/13 with 0 stuck over 3 consecutive runs.
      DONE L-cycle 137: three consecutive _l25_test runs on current HEAD, no re-rolling and no best-of -
      all three OK 13/13 with 0 stuck delvers AND 0 watchdog frees. That is the bar the item set.
      WHAT IT DOES NOT PROVE, said plainly: I did not reproduce the original failure, so the mechanism is
      NOT identified - "fixed" here means "not observable". Beyond the three runs, _l25_test has run about
      a dozen times across this session at 0 stuck every time bar one, and that one was state="search" on
      floor 10 - my own L49 chest bug, diagnosed and fixed in the L52 cycle. Different state, different
      cause, already closed.
      THE ITEM'S ATTRIBUTION LOOKS WRONG, which is worth more than the tick: it blames L27a's new monsters
      at depth, but the recorded failure was FLOOR 3, state=descend, and L27a widened only the 6-7, 8-9
      and 10+ bands - the shallows were deliberately untouched and its test still enforces that. Floor 3's
      roster was never changed by L27a, and "descend" is routing to the stairs, not spawn density. Same
      shape as L46, L49, L50, L52 and L55: real symptom, wrong assumed cause.
      Candidates for what helped since, NOT claims: L50's pack cap (one pick can no longer fill a third of
      a floor - exactly the crowding the item suspected) and L25's watchdog work.
      IF IT RETURNS: read the STATE in the failure line - descend means routing, search means L49's
      chests, fight means slot crowding. The test prints "stuck by floor / state"; keep it.

# Phase I - Mr. E's live-stream findings (Nov 12 ~21:55, from his own OBS recordings + play test)
- [x] L34. DIRECTOR PANE FREEZES (top-left) when a hero dies, rerolls, or a subject vanishes. ROOT CAUSE FOUND by the supervisor, two parts, both laptop-owned:
      (a) scripts/auto_director.gd _process(): after `var best := _best()` there is `if best.is_empty(): return`. When the current subject dies/rerolls, _shot_alive(_cur) goes false AND _best() can come back empty during the transition, so the function returns and the eye is left parked exactly where it was - the top-left pane then shows a frozen frame. FIX: when best is empty, do NOT return - fall back to an ambient/tour shot (the `tour` path already exists, and L32a added ambient subject selection for the lanes - reuse it) so the director always has something to watch.
      (b) scripts/spotlight.gd _follow(): the director pane copies the main viewport camera every frame (`var main := get_viewport().get_camera_3d()`; `dc.global_transform = main.global_transform`). When that returns null the pane silently holds its last transform with no visible error. FIX: if main is null or invalid, drive the director pane's own camera from the RtsCamera/eye focus (or the ambient subject) instead of leaving it stale.
      CONFIRMED by Mr. E's own in-game chat note in the 19-34-39 recording ("the top left screen goes black or stays stuck when someone dies") and visually in the 19:27 recording: the top-left pane is not merely frozen - it renders a BLACK/empty void (camera left inside geometry or below ground) while the other three panes run normally. DONE: a scripted death + a reroll + a subject despawn each leave the top-left pane still moving (ambient or new subject) - verified in a windowed capture, 0 frozen frames.
      DONE L-cycle 119: auto_director._fallback_shot() steps the tour instead of returning when _best() is
      empty (both return sites); spotlight._follow() falls back to the eye's own camera, then to _eye_xform(),
      so the pane never holds a dead frame. tools/_l34_test.gd windowed: scripted death + reroll + despawn
      each leave the pane moving - 0 stale frames, 0 below-ground, 0 empty ticks, L34_TEST OK (30 checks).
      Proven against the fault: with the main camera forced out of play the UNFIXED code moved the pane
      0.00 m (179 stale frames, FAIL), the fixed code tracked the eye 257.71 m of 257.71 m. Shots
      renders/cycles/20261112_l34/. _l24 OK, _l21 OK, _l32 OK (idle 69.7% of base), _offfloor 0, _delve_test clean.
- [x] L35. SUBSCRIBER LANE follows subscribers (Mr. E, Nov 12): the subs lane should always be showing a SUBSCRIBER's hero, not sit idle. Priority: a NEW subscriber (sub/resub/gift) takes the lane immediately for their purchased seconds (the existing paid queue and ordering stay exactly as they are - first payer gets their full time, then the next in line). When no paid sub moment is queued, the lane ROTATES through known subscribers' heroes, changing subject every 15 s. If no subscriber hero is available, fall back to ambient (never blank, per L32a). DONE: with no paid events, the subs lane cycles a different subscriber every 15 s; a new sub interrupts and holds their full time; the queue order is unchanged.
- [x] D24. GRAPHICS - KILL THE GRAIN (Mr. E: "everything feels grainy... like someone sprinkled sand all over it", town worst). ROOT CAUSE FOUND: project.godot has an EMPTY [rendering] section - no TAA, no MSAA, no FXAA anywhere in the project. SSAO (town.gd:828) and volumetric fog (daylight.gd:58-62, 245) are BOTH temporally dithered in Godot 4; with no TAA to resolve them they show as fine static noise over the whole image, worst on cluttered town geometry, and the god-rays/glow add to it. FIX: enable TAA (rendering/anti_aliasing/quality/use_taa), add MSAA 3D 2x-4x for edges, then re-tune SSAO (radius/intensity/detail - or drop it if TAA alone looks right) and re-check volumetric fog density now that it resolves cleanly. Watch FPS: measure before/after. DONE: side-by-side town stills at 1080p before/after showing the grain gone, FPS still >= the D23 target, and Mr. E's eye on it. RESULT (desktop D-cycle 118): project.godot [rendering] now use_taa=true + msaa_3d=1 (2x); SSAO softened (intensity 1.3, detail 0.3, radius 1.8) in town.gd; volumetric fog resolves cleanly, left as-is. Grain gone in 1080p before/after; uncapped FPS at the resting stream cam ROSE 123.4->131.7 avg (min 81->90), >= 120 target. Stills in renders/cycles/20261112_d24. Awaiting Mr. E's eye.
- [x] D25. TOWN REWORK - LAYOUT AND COLLISIONS (Mr. E: the farm, the streets, all of it needs revamping; "things are colliding, structures are overlapping"). NOTE: D18a reported "town placement already clean" yet the running build clearly shows overlaps - so D18a's probe is too narrow (it checked props, not buildings/farm/fence/road footprints). FIX: (1) widen the placement probe to test BUILDING and farm/fence/road footprints against each other, not just scatter props; (2) rework the town layout - real street topology that buildings face and do not block, a farm that reads as fields+barn+fences rather than scattered pieces, no structure intersecting another, nothing floating or sunk; (3) keep walkability - re-bake nav and keep _townwalk at 0 in_solid. DONE: the widened probe reports 0 overlapping footprints, a 1080p shot sheet of the town and farm from the stream camera, _townwalk PASS, and Mr. E's eye on it. RESULT (desktop D-cycle 120): tools/_d25_probe.gd tests footprints of houses, growth SPECIALS, valley structures AND field rects vs each other + roads (game's own _rect/_rect_on_road authority; plaza-fronting landmarks/shops/towers exempt). Town is geometrically CLEAN (BLD=0, FLD=0 at lvl 3+6); the one real defect was 1 house a later road was cut through, now removed by town.gd _final_road_sweep() after all roads are laid. D25_PROBE OK; _townwalk PASS (in_solid 0/18777); shot sheet renders/cycles/20261112_d25/. Farm reads as fields+cottages+fences+garden+hayricks.
- [ ] L36. CHAT OVERLAY COLLIDES WITH THE CENTRE CHRONICLE (seen in Mr. E's 19:34 recording): the in-game Twitch chat box draws over the L32b Chronicle strip - "A trade caravan is sighted on the west road." is overprinted by chat lines and both become unreadable. The chat and the Chronicle must not share pixels: give the centre strip its own reserved band that chat is docked clear of (HudDock), or move chat into a lane/side column. DONE: a 1080p capture with chat busy AND the Chronicle running shows zero overlapping text.
- [x] L37. DUNGEON SCAR-VEINS ARE OVERDONE (seen in the 19:27 recording): the L28d glowing vein decals read as bright purple/cyan neon spaghetti looping across the floor rather than cracks in stone. Cut emission strength and coverage hard, break up the continuous curves, and keep them as a subtle tell. DONE: before/after floor shots; the veins read as glowing cracks, not neon piping.
      DONE L-cycle 138: L42 had already cut vein EMISSION (2.4 -> 1.1), which is why this was left
      unticked then - the item also wants COVERAGE cut, the continuous curves broken, and before/after
      shots. WHAT MADE IT SPAGHETTI was the placement, not the texture: up to SIX decals a floor, each
      2.6-3.8 m, on random cells with NO separation and free to project up a wall face. Four changes in
      dungeon_hd.gd - count halved and capped at 3; each vein drawn at HALF size; none within VEIN_APART
      (9 m) of another; and never projected onto a wall, which is what turned a floor crack into piping up
      the stonework. Emission 1.1 -> 0.75 and alpha 0.62 for "a subtle tell".
      MEASURED: tools/_l37_shot.gd prints the count and the closest gap, framed high and square-on - the
      angle that EXPOSES piping rather than hiding it.
        floor 8   4 veins closest 7.1 m -> 2 veins closest 33.7 m
        floor 11  6 veins closest 9.9 m -> 3 veins closest 18.4 m
        floor 14  6 veins closest 6.3 m -> 2 veins closest 38.7 m
      A vein is now ~1.3-1.9 m wide with its nearest neighbour 18-38 m off, so they cannot join into a
      curve. Shots in renders/cycles/20261113_l37/. Checked for OVERCORRECTION too - floor 11 still shows
      them as small violet cracks, present but not dominant.
      A counting bug of mine was caught first: matching decals by NODE NAME returned 1 every time,
      because Godot renames duplicate siblings. It counts by texture_emission now.
      _offfloor 0 of 1343, _delve_test clean, L41_TEST OK, L50_TEST OK.
- [x] L38. AMBIENT PANE FRAMING IS POOR - THE BIGGEST VISUAL PROBLEM (supervisor reviewed all 13 recordings: a large share of pane-frames are a close-up rooftop, bare grass, open water, a blank wall or a dark void): idle lanes frequently frame a rooftop, a blank wall, empty paving or the inside of a market stall - the camera sits too close/low and clips into structures. Ambient subjects must be chosen AND framed so something legible is happening: prefer a subject with motion, pull back and raise the eye, reject a shot whose view is mostly roof/ground/wall (the _clear() clearance rule exists - extend it to reject bad compositions). DONE: a 3-minute idle capture where every pane change lands on a readable subject; no roof-fillers.

# Phase J - from Mr. E's full OBS review (supervisor watched all 13 Nov-12 recordings, 22:30)
- [x] L39. CHRONICLE IS A CENTRE BOX, NOT A BAR (Mr. E, with reference screenshot; this REPLACES L32b's full-width band). The Chronicle must be a COMPACT PANEL sitting at the centre cross of the 2x2 - roughly the size of the small white box in his screenshot - NOT a tan band spanning the whole screen. Requirements: a small light/white panel centred on the intersection of the four panes; it covers only the corners of the panes it touches, never a full-width strip; it shows the latest few lines, calmly paced (L32b's pacing work is kept); nothing else may draw over it and it may not draw over chat (see L36). DONE: a 1080p capture with the grid up showing a compact centred box, measured at well under half the screen width, with no full-width band anywhere, and Mr. E's eye on it.  [OWNERSHIP MOVED TO DESKTOP HUD + REDEFINED - COORDINATION 11.4; left UNTICKED deliberately, see the laptop note below]
      DONE L-cycle 120: HudDock.STRIP (a full-width band) -> BOX_W 0.30 x BOX_H 0.13, centre() returns a
      compact rect centred ON the cross; spotlight._relayout lets the two pane rows MEET there, so the box
      covers only each pane's corner (~4.2%). feed_hud: light near-white panel, lord card shrunk again for
      the narrower box, overrun lines ellipsised. tools/_l39_test.gd windowed: 576 px = 30% of the width
      (half is 960), centred within a pixel, rows meet, <12% of any pane covered, >=2 lines at the L15 size,
      nothing spills under a 30-line flood, a lord's card still fits - L39_TEST OK (19 checks). L21_TEST OK
      (52), _offfloor 0, _delve_test clean. Shots renders/cycles/20261112_l39/.
      LAPTOP NOTE (do not delete; L-cycle 120, commit 415885a on branch `laptop`, NOT yet merged to main):
      the laptop built the centre box BEFORE this item moved to the HUD worker and before Mr. E refined it to
      "SMALLER TYPE - the font shrinks first, then the panel". What exists on `laptop` shrank the PANEL and
      left the line font at 28 px, so under the new wording this item is NOT done - hence unticked. The HUD
      worker owns it now: either build on the laptop commit or redo it; HudDock.BOX_W / BOX_H and the font
      size in feed_hud are the three numbers. The laptop will not touch these files again (COORDINATION 11.2).
- [ ] L40. HUD AND ALERTS MUST STAY OUT OF THE PANES AND OFF THE CHRONICLE. The recordings show (a) the party-frames panel ("The town's band - floor N") rendering INSIDE a pane, which L21's default-deny docking was supposed to prevent; (b) the "Joined The Court" follower/sub alert drawing across the Chronicle; (c) the Twitch chat column overprinting both the Chronicle and the lower-left pane. Every HUD element, alert and the chat column needs a dock that is clear of the panes and clear of the centre Chronicle box. DONE: a capture with a sub alert, busy chat, party frames and the Chronicle all live at once - zero overlapping pixels between any of them.
- [x] L41. MISSING MATERIAL ON A DUNGEON FLOOR (bright magenta). In the 19-17-57 recording an entire dungeon floor renders hot magenta - Godot's missing-shader/material colour - with the party frames over it. Something in the L28a dungeon_kit shader path fails to compile or bind for at least one theme. Find which theme/mesh, fix the binding, and add a guard so a failed material falls back to a plain grey PBR instead of magenta on stream. DONE: every theme sampled over 12 floors renders with real materials, 0 magenta, and a deliberate broken-material test shows grey not magenta.
      DONE L-cycle 132: probed first - magenta is Godot's colour for a ShaderMaterial with a NULL shader,
      and all eight themes bind correctly here (shader and every texture non-null), so the binding is not
      broken on this machine. What was missing was the GUARD: FloorGen._kit_mat() now checks the shader
      and atlas really loaded and returns plain grey stone if not, counting it in kit_fail_count, instead
      of handing back the null-shader material that IS the magenta. A shader load fails when the
      .gdshader is missing from a machine's import cache - which is why it would show on the desktop and
      not here. tools/_l41_test.gd L41_TEST OK (9 checks): 384 materials over 8 themes x 12 floors, 0 null
      and 0 magenta; the deliberate broken-material test returns a GREY StandardMaterial3D (channel spread
      0.02) and the guard counts exactly 1.
      A LIKELY DIFFERENT CULPRIT, FOR MR. E TO RULE ON: rendering all 14 biomes windowed at 1920x1080
      found no magenta, but CONFECTION's floor is flat saturated pink - its ground was a LIGHT high-chroma
      colour where every other biome uses a dark one, with the highest sat of any biome. In a pane at
      stream distance with party frames over it that reads exactly as the report, and the grey walls match
      too (a missing material would take the walls as well). Ground muted to ["#9a6a80", 0.28] so the
      stone reads through; the biome is otherwise untouched because "the confection" is a NAMED lore biome
      and is MEANT to be pink. Before/after in renders/cycles/20261113_l41/. Revert is one line.
      _offfloor 0 of 1493, _delve_test clean. L28's overwritten render refs restored.
- [x] L42. DUNGEON LIGHTING IS NEON. Several floors read as saturated pink/green/cyan glow (silk-mother floor, firepits) rather than lit stone - L28c's key+fill and L28d's veins together are far too strong and too colourful. Pull emission and light colour saturation right down; the dungeon should read as dark stone with sources of light, not a nightclub. DONE: a per-theme shot sheet at 1080p that reads as lit stone; Mr. E's eye on it.
      DONE L-cycle 133: measured, not eyeballed - every biome scored by sat x the summed HSV saturation of
      its ambient/key/fill/boss, so the ones pulled down were chosen on a number. Worst: firepit 2.94,
      treasury 2.74, workshop 2.33, mess 2.32 ... fogbound 0.30 - firepit being one of the two floors Mr.
      E named, and the BOSS accents the most saturated things in the table (0.62-0.94), which is the
      pink/green/cyan he sees. biomes.json: 48 values pulled down by a one-shot migration editing the RAW
      TEXT so the one-line-per-biome layout survives - ambient S capped 0.34, key 0.20 (a key light is
      near-white with a tint, not a colour), fill 0.26, boss 0.62, glow 0.55 (was up to 1.00), grade sat
      1.05 (was 1.25). Emission, which the item names: L28d scar-veins 2.4 -> 1.1 (they read as neon
      piping, not cracks), dungeon_parts 3.0 -> 1.7, 4.0 -> 2.2, scatter 1.0-2.6 -> 0.7-1.5, ember bed
      3.0 -> 2.2. LEFT ALONE deliberately: the flame itself at 8.0 - the item asks for dark stone with
      SOURCES of light, and a fire is the source; the nightclub came from the room being washed, not the
      fire being bright. Sheet re-rendered 1920x1080, 14 biomes; before/after in
      renders/cycles/20261113_l42/ (different generated floors - compare the lighting, not the layout).
      _offfloor 0 of 1398, _delve_test clean, L41_TEST OK. L28's refs restored.
      THE REST IS MR. E'S: the DONE asks for his eye on the sheet. Every number moved is a cap in one
      place and the previous biomes.json is recoverable from git.
- [x] D26. MOSS/DECAL SPLOTCHES ON TOWN ROOFS. Across the recordings the terracotta roofs carry bright flat green blobs that read as spilled paint, not moss. Either the decal is far too saturated/opaque or a dungeon decal is bleeding onto town roof materials. Fix so roof weathering is subtle. DONE: before/after roof close-ups at 1080p. RESULT (desktop D-cycle 119): not a decal/dungeon bleed - the town's GREEN livery roof tint (town.gd LIVERY_TINT) was Color(0.62,0.84,0.60), a bright green multiplied onto the terracotta tiles that read as green paint in the lighter tile areas. Toned to a subtle sage Color(0.78,0.85,0.74); blobs gone, roof reads as weathered terracotta. A/B in renders/cycles/20261112_d26/pair_green_{old,new}.png.
- [x] D27. THE TOWN READS AS EMPTY AND DARK FROM THE STREAM CAMERA. The recordings show large flat grass expanses with nothing in them, panes that frame a bare field or a blank wall, and daytime shots (e.g. Day 11 08:40) that look like dusk. Two parts: (1) fill the town/valley so no camera angle lands on featureless grass - paths, hedges, crops, carts, clutter, people moving; (2) check the daylight curve and exposure - morning should read as morning, not gloom (this interacts with D24: fix the grain first, then re-judge brightness). DONE: a 12-shot sweep from the stream camera at 08:00/12:00/18:00/22:00 where every frame has something to look at and the daytime frames read as daylight. RESULT (desktop D-cycle 121): (1) BRIGHTNESS - the 'dusk' was overcast weather: it greyed the sky and dimmed the daytime fill to a gloom. daylight.gd overcast sun 0.76->0.88 and dark 0.55->0.42 (rain 0.55->0.66, 0.9->0.78), plus a daytime ambient boost scaled by weather darkness (env.ambient_light_energy *= 1 + dark*0.6*(1-nt)). Clear days and night unchanged. 08:00 overcast now reads as bright cloudy daylight. (2) FILL - new town.gd _dress_greens() dresses the bare grass islands with flower beds + bushes + the odd tree (644 flora), is_clear-gated, gate lanes/river kept clear; trees/bushes register as nav solids. FPS 128.2 avg/94 min (>120 D23 target); _townwalk 0 in_solid. Sweep in renders/cycles/20261112_d27/.

### CONTENT (laptop, branch `content`, data+lore only, NEVER runs Godot) - see COORDINATION 10
SUPERVISOR NOTE (2026-11-15 15:58 CT): the content writer owns NO open PHASE RC item (C7 shipped and is
ticked), so its brief's first-unchecked rule is back in force. C-52 landed this cycle off the standing
backlog - E3PO deepened by 168 lines across 12 pools in lore_lines.json, merged to main. C1, C2 and C3 are
the file's oldest entries and have been overtaken many times over by the C-cycles (C-34 through C-52);
C4 is the one open CONTENT item written to the current "HOW BIG AN ITEM SHOULD BE" bar and the one the game
build is waiting on - D35 and D39 read items.json `shop_stock` and `trader_cargo`, and D64's shop ladder
now gates by level. CONTENT WRITER: TAKE C4 NEXT.

- [x] C1. COSMETICS & DYES CATALOGUE (data/items.json): items.json is only 3.7 KB - the cosmetic set is thin. Expand cosmetics and accessories a lot: cloaks, hats/hoods/helms-as-cosmetic, rings, amulets, boots, gloves, banners, pets, titles - each with the same fields the existing entries use, priced sensibly against the economy, and named from the lore (Bellmire, the scar, the Ford, the guild). Widen dyes beyond the current set and keep dye_cost coherent. Additive only; never rename or drop a key. DONE: json validates, every new entry carries the same fields as the existing ones, and a written list of what was added.
  RESULT (ticked 2026-11-16 by the supervisor): delivered over C-41..C-46 and C-54 - the 321-entry
  cosmetic pass plus +71 cosmetics (23 hats, 18 banners, 23 titles, 6 pets), +24 accessories and +27 dyes,
  every entry priced against the economy and flavoured. items.json parses; no pre-existing key touched.
- [x] C2. LORE LINES (data/lore_lines.json): many more tells, descend/cleared lines, lord and unique intros, barks and epitaphs, in the established voice, so the Chronicle and the barks stop repeating on a long stream. DONE: json validates; counts per category before/after; no line contradicts canon.
      CYCLES LOGGED: C-41..C-46 (cosmetics/accessories/dyes, uniques, intro/forge, most-repeated, epitaph/descend/cleared, disaster variants). C-47 (2026-11-15, content 3d01748): +140 lines - forge, town_life, a wandering lord, and E3PO tier_up_alt. Standing item: stays open by design.
      C-56 (content cba6724, merged 2026-11-15 23:10): +156 disaster variants - during/begin_alt/pass_alt across all 13 disasters.
      C-57 (content 0c93743, merged 2026-11-15 23:10): +196 epitaph, descend, cleared and bark lines.
      C-59 (content 9060522, merged 2026-11-15 23:10): E3PO deepened again, +102 lines; he is now named 371 times across lore_lines.json.
      NEXT FOR THIS LANE (supervisor, 2026-11-15 23:10): the words PHASE 2 needs and does not have - the ascent (D77), the errand (D78), carry weight (D80), selling and the guild vault (D81), the upgrade poll (D66). Plain register, wear is a variable.
  RESULT (ticked 2026-11-16 by the supervisor): delivered over C-37, C-39, C-50 and C-52 - roughly 750 new
  lines across tells, descend/cleared, epitaphs, barks, lord and unique intros and the E3PO pools (12 thinnest
  pools raised to 38-48 each). lore_lines.json parses; every pre-existing line byte-equal.
- [x] C3. RARE UNIQUES + BREWS (data/bosses.json lesser/greater/draw/rule, data/potions.json): more rare unique variants (modified lords, NOT new lords) and more brews/states, all within the existing schema. DONE: json validates; the new entries name their modifier and effect.
  RESULT (ticked 2026-11-16 by the supervisor): delivered in C-35 - 32 rare unique variants (modified lords,
  no new lords) in bosses.json plus 20 brews/states in potions.json, each naming its modifier and effect.
      FURTHER CYCLE LOGGED: C-55-the-cycle (content d91ea57, merged 2026-11-15 23:10) - a second pass of +32
      boss uniques (lesser/greater) and +24 brews, still modified lords and no new lords. Note the cycle
      number collides with the C-55 RARITY LADDER ruling block above; they are different things.

- [x] C4. WHAT A CROSSING SELLS AND WHAT A CITY SELLS ARE NOT THE SAME THING - STOCK AND CARGO BY GROWTH TIER.
      Owner: CONTENT WRITER (data/items.json ONLY). The town grows through twelve stages from Crossing to City
      and every shop sells the same list the whole way, which makes growth invisible in the one place a viewer
      spends their points. This is the data half of D35 (visible stock) and D39 (traders must matter) - the game
      build worker implements the mechanics FROM THIS FILE, so be precise and do not describe code.
      .1 A STOCK TIER ON GOODS. Every sellable entry declares the earliest growth stage at which it can appear
         and, where it makes sense, the stage past which it stops being stocked (a crossing's dried fish and
         bad rope should vanish from a city's shelves). Use the existing key style; additive only.
      .2 THE SHOPS DIFFER FROM EACH OTHER. Stock sets for the trades the town actually has - smith, apothecary,
         general goods, stables, guild - so two shops at the same stage do not read as one shop twice.
      .3 TRADER CARGO. What a caravan ARRIVES carrying, by stage and by where it came from, with the supply the
         town receives named in plain words (grain, iron, salt, lamp oil, physick) and a precise quantity or
         cost statement - D39 will implement the town actually receiving it, and a vague line becomes a guess.
      .4 PRICES THAT HOLD UP. Priced against the existing economy and against each other, so a city's plate is
         not cheaper than a crossing's mail.
      DONE: json validates; every pre-existing key byte-identical; a written table of stage -> what each trade
      stocks at that stage, showing at least one entry that enters and one that leaves across the twelve stages;
      and a count of new entries per trade. State plainly which keys the game build worker must read.
  RESULT (ticked 2026-11-16 by the supervisor): delivered in C-53 (items.json only) - `stock_retirement`
  (36 shop goods + 19 cargo goods with last_tier/replaced_by), `trade_stock` (5 trades, per-stage enter/leave
  across the twelve growth stages), `caravan_manifests` (7 supply resources) and `price_ladders` (10 ladders,
  tier and cost non-decreasing, script-checked). The game build reads these for D35/D39/D64.

- [x] C5. THE TOWNSFOLK ARE A COMMUNITY, NOT WALKERS - NAMES, TRADES AND REACTIONS.
      Owner: CONTENT WRITER (data/lore_lines.json ONLY). Mr. E wants more NPCs and better NPCs. Today the
      townsfolk are anonymous bodies; the Chronicle can say a hero's name but not a baker's. This is the words
      half of D36 (NPC diversity) - the game build worker binds a name and a trade to a body from this file.
      .1 A NAMED POOL. A substantial pool of townsfolk: given name, family name or by-name, and trade, in the
         established Bellmire voice (the Ford, the scar, the guild, the marsh). Enough that a long stream does
         not see the same name twice in an evening.
      .2 A VOICE PER TRADE. Idle barks keyed by trade, so the smith does not say the fishwife's line, plus
         a short line for what that trade is DOING at morning, midday, evening and night.
      .3 THEY REACT. Lines keyed by the events the game already raises - raid, disaster, festival, caravan,
         growth, hunger, a hero falling, a hero coming back rich - in each case written so the speaker is an
         ordinary person with something at stake, not a narrator.
      .4 THEY REMEMBER. A few lines that only make sense after something has happened ("second flood this
         season"), marked so the game can hold them back until the condition is true.
      DONE: json validates; every pre-existing key byte-identical; counts per trade and per event; a written
      sample of one named townsperson's full set read end to end as a character; and a plain statement of the
      key shape the game build worker reads to pick a name, a trade and a reaction.

# Phase K - test validity (raised by the laptop, Nov 12 23:55; IDs + decisions by the supervisor)
  RESULT (2026-11-15 12:11 CT, content 754d87b, C-48): new top-level "townsfolk" pool, 792 lines - names 150, trades 448
  across 28 trades (barks plus morning/midday/evening/night doing-lines), react 160 keyed to raid/disaster/festival/
  caravan/growth/hunger/hero-fallen/hero-home, remember 24 gated by a "_conditions" block the game can test, and a
  named cast of 10 read end to end as characters. json validates; pre-existing keys byte-identical. This is the words
  half of D36: the game build worker binds name + trade + reaction to a body from these keys.
- [x] L43. _l32_test's FPS GATE IS VACUOUS (test-validity bug, OWNER: LAPTOP). The suite printed "L32_TEST OK (90 checks, 0 failed)" while reporting "L32_FPS base 1.0 idle 26.8 paid 18.7": every FPS check is RELATIVE to base ("idle >= 65% of base"), so a base of 1.0 passed them all trivially and the gate tested nothing. First seen on the run after origin/main brought D24 (use_taa=true, msaa_3d=1). Only the FULL-SCREEN base phase collapsed; grid phases are in line with history (idle 26.8 vs 28.8-31.8, paid 18.7 vs 16.2-21.6) and the DESKTOP's D24 numbers ROSE 123.4 -> 131.7, so this is harness-specific, not "TAA is slow".
      DONE L-cycle 134: implemented to the supervisor's decisions. The relative-to-base design is KEPT;
      the MEASUREMENT was fixed. After any viewport 3D-state change (disable_3d toggled, grid raised or
      lowered) samples are discarded until TAA refills - 1.0 s AND 60 frames, whichever finishes last.
      The base >= 10 assert STAYS permanently. Second guard added: every phase must sample >= 60 frames,
      and the raw per-phase numbers print every run (L32_FPS_RAW base X/N idle X/N paid X/N) so a vacuous
      pass cannot hide behind a green summary. The separate-process fallback was not needed.
      RESULT: base 1.0 -> 35.1, 37.6, 38.2 across runs; L32_TEST OK (100 checks, 0 failed), the first
      clean run of this suite in many cycles.
      IT CAUGHT A REGRESSION OF MINE ON ITS FIRST HONEST RUN: paid fell to 14.3 then 14.7, under the
      floor of 15, because L48 had put Roster.abilities_of() in the per-hero per-frame fight loop,
      allocating an Array and walking two tables every frame for every delver. Now cached on the party
      member and recomputed only when the hero LEVELS - paid back to 16.1, L48_TEST still OK.
      That is the argument for repairing a vacuous gate instead of reverting its assert.
      STILL OPEN AND NOT MINE: the supervisor's cross-check of running this on the DESKTOP.
      SUPERVISOR'S DECISION: (1) KEEP the relative-to-base design - it is what makes the test portable across two very different machines; fixed per-machine numbers would need tuning and would drift. Fix the MEASUREMENT, not the design. (2) After ANY change to viewport 3D state (disable_3d toggled, grid raised/lowered) DISCARD A WARM-UP WINDOW before sampling - at least ~1.0 s of real time or 60 frames, whichever is longer - so TAA's history buffer refills; the suspected mechanism is sampling immediately after root.disable_3d=false, which TAA cannot survive. (3) KEEP the laptop's new `base >= 10.0` assert PERMANENTLY - it is what caught this. NEVER revert it to make the suite green. (4) Add a second validity guard: assert each phase sampled a minimum number of frames, and print the raw per-phase FPS so a vacuous pass can never hide again. (5) ONLY IF warm-up does not restore a sane base, measure the base phase in a separate process with a fresh viewport and no toggle. (6) DO NOT touch project.godot [rendering] - it is desktop-owned, TAA stays, and the desktop's numbers improved.
      CROSS-CHECK (either machine): run _l32_test once on the DESKTOP to see whether a collapsed base reproduces there. That distinguishes harness artifact from machine. A healthy D23 soak does NOT rule it out - D23 does not use this harness.
      NOTE FOR EVERY RUN UNTIL THIS IS DONE: _l32_test now REPORTS FAIL on the laptop by design (the new assert). That red is THIS flag, not a regression in L34/L39, and it is not a reason to reject an unrelated laptop item.
      DONE: base reads a sane FPS on both machines with TAA on, the relative checks are meaningful again, the base>=10 and min-sample asserts stay, and a deliberately-broken base makes the suite FAIL.
- [x] L44. _l24_test IS FLAKY (OWNER: LAPTOP). Failed 3 of 6 once ("Ash's body below is the one the lane holds" plus the two checks depending on it), then passed 6/6 on an immediate re-run with nothing changed - a lane/delve timing race, the same class as the "before" check already noted.
      DONE L-cycle 135: the race was FOUND, not guessed at. The test put Ash in the bits lane for 60
      SECONDS and ran its final checks 1200 FRAMES later - and Spotlight seconds are REAL seconds, so
      1200 frames is 20 s at 60 fps but about 60 s at the 14-20 fps this machine runs DURING A DELVE,
      which is when the second half of this test runs. The hold expired just as the asserts fired, which
      is exactly the recorded 3-of-6 failure, and it explains why an immediate re-run passed: it was
      faster. Same shape as L43 - a test measuring in frames something that lives in seconds.
      Fixed by DRIVING the state (the L23 precedent), not by retrying: the hold is 900 s so it cannot
      expire inside a test that never meant to test expiry; the final checks wait for the CONDITION they
      need (both delvers' bodies in the tree, since body_of resolves through the Delve party first) and
      fail with a named check if it never arrives; and the lane is re-bound to the underground body
      immediately before the asserts, so the precondition is ESTABLISHED rather than hoped for.
      NO retries and NO best-of-N. PROVEN: ten consecutive windowed runs, 6/6 every time, 0 failures.
      Only the test file changed - no game script touched.
      SUPERVISOR'S DECISION: make it DETERMINISTIC, following the precedent already set by L23 (_l20_test drives its fight and raid shots deterministically rather than hoping the timing lines up). Drive the lane/delve state the test needs instead of waiting on it. Do NOT paper over it with retries or a best-of-N: a flaky test is worse than no test, because it trains every run - and every supervisor - to ignore red. DONE: _l24_test passes 6/6 on ten consecutive runs.

# Phase L - Mr. E's Nov 13 review (the stream test + his 20-point list). IDs by the supervisor.
# URGENT - viewer-facing
- [x] T3. !enlist "DID NOTHING" ON STREAM + THE REPLY PATH DROPS SILENTLY (OWNER: DESKTOP - twitch_eventsub.gd is desktop-owned). Investigated by the supervisor: the COMMAND path is sound - chatcmd._enlist() cannot crash on a typo or empty args because Roster.fresh() (roster.gd L231-234) substitutes a random class/species for anything unknown. The fault is far more likely in the REPLY path, which has drop points that log NOTHING:
      (a) twitch_eventsub.gd L580: `if dry_run_chat or offline or tokens["bot"].is_empty() or _token_dead["bot"]: return` - this returns BEFORE _send_chat(), so the "chat not sent" log on L590 never runs. The hero IS created, the answer is queued, dequeued, appended to sent_chat, then silently discarded. From chat it looks exactly like the command did nothing.
      (b) L572-573: an identical message inside 30 s is dropped silently. Two viewers making the same mistake within 30 s ("No hero yet - type !enlist") means the SECOND viewer gets silence. Same for any repeated error text.
      (c) chatcmd.gd L88-89: the per-user cooldown returns "" with no feedback.
      Checked and NOT the cause at the time of the stream: the bot token was refreshed 21:07 with user:read:chat + user:write:chat and ~3.7 h of validity, and no dry_run/offline flag is set in local/twitch.cfg.
      FIX: every one of those drop points must _say_log() its reason (which condition, which user, which text). A silently-swallowed reply is undebuggable and this class of bug will recur. Then make the duplicate guard per-user instead of global, so one viewer's repeat cannot mute another's answer.
      DECISIVE TEST FOR THE NEXT STREAM (Mr. E): have someone type !enlist, then look at the live hub. Hero appears on the hub but no chat reply => the command works and the reply path is broken. No hero on the hub => the command never ran (chat ingest/cooldown). That single check splits the problem in half.
      DONE: every skipped reply writes a log line naming the reason; the duplicate guard is per-user; a scripted run proves a reply either reaches chat or is logged as to why.
      RESULT (desktop D-cycle 125): twitch_eventsub.gd reply path is now loud - _on_twitch_reply logs empty replies and queue-full drops; _tick_chat's 30s duplicate guard is now keyed per-user (login+text) and logs each drop; a new _send_hold_reason() names why a send is held (dry_run_chat / offline / no bot token / bot token dead) so bug (a)'s silent discard is gone. (c) chatcmd.gd cooldown is LAPTOP-owned, left for them. tools/_t3_test.gd (NEW) proves 12 cases incl. two different users with identical text BOTH getting through. T3_TEST OK (12/12). Gate clean: parse 0 err, TWITCH_PARSE OK, _offfloor 0/1133, _townwalk PASS, _delve_test rc=0.

# DO THIS FIRST - it decides how much of the rest is real work
- [x] D28. LIVE-RUN FEATURE CENSUS (OWNER: DESKTOP, reports to the supervisor).
      DONE D-cycle 123: 7-min 8x soak (director on, 6 viewers). CENSUS TABLE + verdicts in PROGRESS. Headline: audio is
      NOT dead (3698 plays, 54/94 kinds) but FOOTSTEPS (footstep_grass/stone/water/wood) and most ANIMAL/UI sounds have
      NO CALLER -> that is the silent-town bug (-> D29). Anims FINE (30 clips, 0 miss), spells FINE (9 by name), loot FINE,
      bosses/traps PRESENT-but-RARE (feed: 3 lords, 3 traps), cosmetics NEVER worn + gear tiers stuck w0/a0 despite forging. Mr. E says he has not SEEN: the new sounds, any new animations, new bosses, new cosmetics/armour/weapons, trap damage, spell variety, or loot. All of those are ticked DONE with passing tests. Before building anything further, find out which are BROKEN and which merely never FIRE. Instrument a 30-minute soak with the director on and COUNT, per feature: every Sfx kind played (by id, with totals - the 86 RPG kinds from S1/S2/S3 especially); every animation clip actually played, by body type; bosses/lords/uniques spawned and killed; traps armed vs triggered vs DAMAGE APPLIED (hp actually lost); spells cast BY SPELL NAME (is it always the same one?); loot: chests spawned, chests opened, items dropped, items picked up; cosmetics/accessories worn by anyone. Print a table of counts and write it into PROGRESS. A count of ZERO means broken; a count of 2 in 30 minutes means too rare to ever be seen on stream - both are findings, and they are DIFFERENT fixes. DONE: the census table in PROGRESS.md, and a one-line verdict per feature (broken / too rare / fine).

# Mr. E's Nov 13 list - LAPTOP (dungeon, combat, HUD)
- [x] L45. BOSSES SCALE WITH DEPTH (his call): a lord on a deep floor must be meaningfully harder than a shallow one - hp, damage, mechanics, adds. Deeper should feel dangerous. DONE: a measured curve of boss difficulty by floor; a deep lord can wipe an unprepared party.
      DONE L-cycle 123: the real bug was that Bestiary.boss_def() never SAW the floor - a lord's hp/atk came
      straight off canon, so the same lord hit identically at any depth (uniques already scaled; lords did
      not). boss_def(b, floor_no) + depth_step() (counts lord-floors from the first, so the curve is
      open-ended and states no floor count) + named constants LORD_HP_PER_STEP 0.28 / LORD_ATK_PER_STEP 0.22.
      scale_ways() deepens the MECHANICS too - more adds arriving faster, stronger nova/swoop, harder ward,
      earlier enrage - mutating a duplicate so canon LORD_WAYS is never written to. dungeon_hd passes the
      floor. Measured curve (Hollow King, same lord): hp 150->528, atk 15.0->44.7; summon most 2->6, every
      12.0s->5.7s, ward 0.50->0.80. Wipe: an unprepared party of four (120 hp) falls to a deep lord in 2.7
      landed blows vs 8.0 shallow. tools/_l45_test.gd L45_TEST OK (10 checks) - also asserts the first lord
      floor is unchanged canon and the curve never dips. _offfloor 0 of 1130, _delve_test clean, L27A OK.
      MR. E'S CALL: 44.7 vs ~30 hp heroes is about one blow a hero - LORD_ATK_PER_STEP is the dial.
- [x] L46. TRAPS DO NO DAMAGE (he believes spikes/traps are inert). L11 claims working traps. Verify against the D28 census, then fix: a triggered trap must apply real hp loss, show a number, and reach the Chronicle. DONE: census shows trap triggers AND hp applied; a delver can die to a trap.
      DONE L-cycle 124: VERIFIED FIRST - Mr. E is right about the experience, wrong about the mechanism. L11's
      damage code was never broken (a forced spring took 10 hp, rolled the save, floated the number, printed
      the line). Traps were almost never MET: over 4 floors a delver came within the 0.90 m radius of only
      2 of 6 traps (closest approaches 0.1/0.4/3.9/4.0/11.0/23.5 m) and 1 fired. THREE real defects, all
      measured: (1) dungeon_hd._dress() laid traps on ANY open cell - they now go on info["keep_clear"], the
      way through, which is where the party walks (coverage 2 of 6 -> 5-6 of 6, closest 0.0-0.7 m);
      (2) _traps_tick() ran ONLY inside _fight(), so the whole walk to the stairs was trap-free - it now
      runs in "descend" and in the "flee" state too (encounters 2 -> 5 over the same floors); (3) a sprung
      trap could take ZERO hp - floorf(dmg*0.5) on a save floors a low roll to 0 and fire resistance
      multiplies to 0 - now maxf(1.0, ...), so a save halves and resistance blunts but neither nullifies.
      tools/_l46_test.gd L46_TEST OK (10 checks) - it prints trap_log WITH the closest approach to every
      trap, so the next run can tell "damage broken" from "never triggered". _offfloor 0 of 1063,
      _delve_test clean, L25_TEST OK 13/13 (0 stuck, 0 prop overlap - traps on the route block nobody).
      NOTE: part C first failed on a CORRECT mechanic - the canon one-death-save-a-delve
      in _hero_hit stood the delver back up on 1 hp; the test now burns the save then kills.
- [x] L47. ADVENTURERS MUST THINK FOR THEMSELVES (Mr. E marked this PRIORITY). Delvers should make visible decisions: retreat when hurt, drink a brew when low, use oil before the dark, pick targets sensibly, search for loot, regroup, flee a losing fight, go home when spent. Right now they read as scripted. DONE: a soak where the Chronicle shows real decisions, and a hurt party retreats rather than dying in place.
      DONE L-cycle 122: delve.gd decision layer - _decide() records+announces by kind (the LINE is rate-limited
      per hero, the decision never is). NEW: _think() per hero (BREAK OFF under 22% hp with no heal brew and
      run for the way up; REGROUP past 15 m from the party centre; REJOIN past 55%), _losing() at party level
      (new "flee" state - a plainly lost fight is broken off and they run out WITH survivors), and
      _pick_target() replacing nearest-foe (finish the nearly-dead, shut up the caster/spitter/shooter).
      Drinking, healer triage and press-on/climb-out were ALREADY visible decisions - now counted and
      reasoned through the same layer rather than duplicated with new behaviour.
      tools/_l47_test.gd headless (delve LOGIC, not HUD): A soak demands a RANGE of kinds (12 decisions,
      press_on+finish); B slams the party to 10% mid-fight and requires flee + the line + SURVIVORS; C prefers
      a wounded FAR foe over a healthy near one; D hurts ONE delver to 8% with no brews - B can NEVER reach
      the single-hero path (the party-level retreat fires first and returns), so without D that branch would
      have shipped unexecuted. L47_TEST OK (8 checks). _offfloor 0 of 1043, _delve_test clean, parse 0.
      Proven by test: press_on, finish, party_retreat, flee. Wired but not yet observed firing: regroup,
      rejoin, silence, mend, brew_*, turn_back_*.
- [x] L48. LEVELLING: CLASS + RACE UNLOCKS. Levelling should unlock new skills, spells and abilities that depend on BOTH class and species, and go deeper than that (tiers, choices). Today a level-up is a stat bump. DONE: a levelling table per class x species; a hero visibly gains a named ability and uses it.
      DONE L-cycle 130: TWO TRACKS rather than a 90-row class x species table nobody could keep true - a
      hero draws from their CLASS track (every class, levels 2 and 5) and their SPECIES track (every
      species, level 3), so the COMBINATION makes them and a new class or species costs one row. roster.gd
      gains CLASS_UNLOCKS, SPECIES_UNLOCKS, ABILITY_WORDS (a name AND a blurb each), abilities_of() and
      unlocked_at(). A level-up now SAYS what it gave - "X learns Cleave - their blow carries into a second
      foe" - because an unlock nobody can see is the same bug as the stat bump it replaced. delve.gd uses
      them through the seams that already existed (_ability_mult, _ability_hit, _soak), so a level-5 orc
      knight brings cleave, bulwark AND rage. tools/_l48_test.gd L48_TEST OK (11 checks): every class and
      species has a track, the same class of different blood gets a DIFFERENT kit, it is tiered, a real
      level-up announces it, and - check D - EVERY ability must actually change something in delve.
      Check D caught my own decoration: "backstab" shipped in the first draft as a named ability with no
      implementation. Now +40% on an already-wounded target. 15 classes, 6 species, 17 abilities, all 17
      wired. _offfloor 0 of 1305, _delve_test clean, L3_TEST OK.
      MR. E'S CALL: a levelled hero is now meaningfully stronger both ways; the numbers sit in
      CLASS_UNLOCKS, SPECIES_UNLOCKS and the _ability_mult match if the curve wants flattening.
- [x] L49. LOOT AND SEARCHING ARE INVISIBLE. No chests, no drops, nobody searching. Heroes should visibly SEARCH specified spots - a dig/search animation, time taken - and report "...no loot..." or "Found loot!" style lines. Not every monster drops. DONE: census shows chests spawned/opened and items picked up; a capture shows a hero searching and both outcomes in the Chronicle.
      DONE L-cycle 125: as with L46 the mechanic was not missing, it was INVISIBLE - _loot() already rolled
      Investigation and awarded gold, but fired the instant a floor cleared with no chest, nobody moving and
      nothing to watch. NEW DungeonParts.chest() (banded, hinged lid, a small glint to find it in a dark
      pane; set_meta("open") tips the lid). dungeon_hd lays 1-2 a floor in info["chests"], on OPEN floor
      rather than the route - a chest is somewhere you GO, traps are what you trip over. delve.gd gains a
      "search" state: the sharpest eye WALKS to each chest, faces it, kneels with Use_Item for 1.8 s, and
      only then rolls - reading out in Mr. E's own words, "Successfully found loot!! N gold" or
      "...no loot...", with a floating +N / empty. Counters chests_found/chests_empty exposed for a census.
      Refactor: the floor-cleared branch became _floor_decision() + _fight_body() so the same decision is
      reachable after searching; the no-chest path is unchanged. tools/_l49_test.gd L49_TEST OK (9 checks)
      - it checks the LID actually rotates and the delver actually walks within 2.2 m, so loot cannot
      teleport in, and drives 80 searches: 32 found (32 of 32 paid gold), 48 empty. _offfloor 0 of 1624,
      _delve_test clean, L25_TEST OK 13/13 (0 prop-prop, 0 prop-wall, 0 stuck; watchdog 1 free in 10
      floors where the last runs were 0 - within the limit, but the chests are the thing to suspect if it
      climbs). SCOPE: chests pay GOLD; gear salvage is still _loot()'s; there are NO per-monster
      physical drops or floor pickups - if Mr. E wants those they need their own ID.
- [x] L50. MONSTER DIVERSITY. More variety in what appears, and at what depth. DONE: a depth census showing a wide spread, not three repeats.
      DONE L-cycle 131: the census came FIRST and located the problem somewhere else. tools/_l50_test.gd
      reproduces dungeon_hd's own spawn loop (pick + pack expansion) so it measures what a floor really
      gets. BEFORE: depth 1 gave 3.5 distinct kinds a floor with one taking 51%; depths 6-14 gave 5.7-6.6
      at 30-36%. The DEEP floors were never thin - L27a had already done that work - ALL the repetition
      was in the shallows, which is the first thing a viewer sees. Two causes: the shallow band held only
      five kinds (widened to seven with the gentlest creatures from the next band up - puglin, spider -
      NOT the deep roster, so L27a's shallows-innocent rule still holds and _l27a_test still passes), and
      pack expansion let ONE pick fill n = 1 + pack slots, so a rat pack took a third of a small floor
      (now capped at ~34% of a floor, which helps at every depth). AFTER: depth 1 is 4.3 distinct at 43%,
      worst share across all depths 43%. No new monster was invented - I checked, and the only unused
      types are the two summon-only fodder. The test also asserts depth still CHANGES what appears (18
      kinds only deep, 7 only shallow). L50_TEST OK (5 checks), L27A_TEST OK, _offfloor 0 of 1405,
      _delve_test clean.
- [x] L51. HUD OVERHAUL (he says it twice - it is plain and under-informative). Needs: equipment shown with what BUFFS/DEBUFFS it gives; the viewer's inventory visible so they know what they own; shops shown with WHAT THEY CURRENTLY STOCK; a way to SELL. Also the d20 needs redesigning - he does not like how it looks - and it exists to roll stats when a viewer builds a character, so wire it to that. DONE: a 1080p HUD capture Mr. E approves, showing gear with buffs, inventory, shop stock and selling.
- [x] L52. (SUPERSEDED BY THE REFRAMED L52 IN THE Nov-13 SECTION - done there, L-cycle 126; the census disproved the premise, so the work was legibility, not more spells.) SPELL VARIETY BELOW. He has only ever seen one spell. Verify against the census, then make casters actually choose among their spells. DONE: census shows several distinct spells cast in one run.

# Mr. E's Nov 13 list - DESKTOP (town, world, audio, visuals)
- [x] D29. THE TOWN IS SILENT OF EFFECTS - MEASURED, NOT GUESSED. The supervisor analysed the AUDIO of Mr. E's own OBS recordings (he was right; this needs no census to confirm):
      * 19-34-39 (town/market, 39 s): dynamic range only 13.0 dB, median -34.9, peak -30.1, and ZERO windows more than 8 dB above the bed - i.e. NOT ONE discrete sound event in a busy market with heroes walking, NPCs working and a caravan arriving. It is a flat ambience drone and nothing else.
      * 19-27-48 (dungeon/delve, 49 s): range 29.8 dB with 79 spike windows (3.4%) - so the Sfx system DOES fire below ground. The fault is TOWN-SIDE, not the whole system.
      * Everything is also too quiet: median ~-35 dB, peaks only -25 dB.
      So: the 86 CC0 kinds wired by S1/S2/S3 are not reaching the town. Find whether town callers never call Sfx, call a kind id that is not in SETS, play on a muted/mis-routed bus, are throttled out by GAP, or are attenuated to nothing by 3D distance from the stream camera. Source library is github.com/jestsayin96/music-studio - READ-ONLY, copy what is needed, never modify that repo. Also raise the overall mix level.
      *** OBS RULED OUT - ANSWERED BY MR. E. THE TOWN SILENCE IS A REAL GAME BUG. PROCEED. ***
      Mr. E sent his OBS Advanced Audio Properties and mixer. Findings:
        - Desktop Audio is MUTED (red crossed speaker, flat meter). If Bellmire's output goes to the Windows
          default device, OBS was capturing it on a muted channel and no game sound could reach the recording.
        - OBS tracks 1 and 3 have identical source assignments (hence the two identical ffmpeg streams);
          OBS track 2 has nothing live on it (the -91 dB stream).
        - Source volumes are low at the source: Application Audio Capture 27%, Desktop Audio 28%,
          Game Capture 45%. That alone explains the -35 dB median.
      ANSWERED 2026-11-13: Mr. E captures Godot with the 'Game Capture' source, NOT Desktop Audio. Game
      Capture is Active with a -6.8 dB fader, so Bellmire had a live audio path into those recordings. The
      muted Desktop Audio is therefore irrelevant to the game's sound, and the measured town silence is
      ATTRIBUTED TO THE GAME. Hunt it in the engine.
      Still worth Mr. E's attention on his side, but not blocking: Game Capture sits at 45% (-6.8 dB), so even
      once the town SFX fire they will be quiet for viewers; and OBS tracks 1/3 are duplicates with track 2 empty.
      DONE: a re-recorded town clip whose audio shows clear discrete events (>=8 dB above the bed) for footsteps, voices, work and combat, at a sane level - verified the same way, by measuring the recording.
      ADVANCED, NOT TICKED (desktop D-cycle D6, 2026-11-13): the GAME side of the silent town is
      verified AND the missing "work" layer is now built. D42's footstep/voice/animal callers
      re-measured live (tools/_d42_test, 40 s 8x): footsteps 1255 (grass 564/stone 569/wood 62/
      water 60), animal voices 68 (horse 16, dog 16, cat 25, boar 11) - all fire. NEW this cycle:
      the ambient WORK sound the census had no caller for - town.gd._work_sounds rings the smith's
      anvil ("hit" at the blacksmith yard) and chinks market trade ("coin" over the square),
      station-based, 3D, daytime only (gated is_raid_on()+economy.is_night(), like the festival).
      tools/_d29_test 30 s 8x: work_plays 69 (smith 46 + market 23), 0 SCRIPT ERROR. Gate GREEN:
      parse 0, _offfloor 0/1411 (INPROP 0, MON_INPROP 0), TWITCH_PARSE OK, _delve_test clean,
      _townwalk in_solid 0/15470 PASS. UNTICKED because the stated DONE is a re-recorded OBS clip
      measured at >=8 dB discrete events - that needs Mr. E to record with Game Capture turned up
      (it sits at 45% / -6.8 dB); headless COUNTS the events, it cannot measure his recording. Not
      looked at on stream yet (headless soak only).
- [x] D30. SPELL VARIETY IN TOWN - same complaint as L52, town side (mages/clerics). DONE: several distinct spells visible in a raid.
- [ ] D31. ONE BIG MAP, ONE KINGDOM (his decision). Consolidate to a single map: a small market town that GROWS - as the town levels, builders appear and actually construct new buildings on the map. DONE: a timelapse of the town levelling with builders at work and new structures appearing.
      PART (D-cycle D13, 2026-11-14): visible construction added. growth.gd now raises a timber scaffolding frame (corner poles, two plank rings, diagonal braces, a pennant and a stack of planks) around every newly-built plot and every newly-unlocked special at each level-up; the frame lives SCAFFOLD_LIFE=90s real seconds then auto-removes via _process. Purely visual - no collision, no navmesh impact. _d31_test (Town.tscn booted, show_level 1->4->6): before=0 mid=9 late=17 cleaned=0 PASS. Chronicle picks up "Builders raise scaffolding across Bellmire." on each level-up. Still open for the DONE bar: builder NPC figures at the scaffolding, the one-map consolidation decision, and Mr. E's timelapse recording.
- [x] D32. TOWN LEVELS UP FAR TOO FAST. Re-parameterise growth so levelling is earned over a long stream. DONE: a measured curve Mr. E approves.  RESULT (D-cycle D7): old 6-level table FOUNDED at lvl 3/6 and auto-climbed to 5 on settlers alone; now 12 earned tiers (content growth_tiers), founding=HAMLET(2), pop ceiling ~315=tier 5, tiers 6-12 renown-gated. 30-day soak: crossing->hamlet(d2)->guild post(d6)->village(d17), holds at village (score 247, pop 69). Crier lines wired. Gate green. Chart+csv renders/cycles/d32 + to Mr. E; the curve PACE awaits his approval.
- [ ] D33. RANDOM WORLD EVENTS ON THE MAP: bandit camps and monster camps that spawn around the map, and a random boss scaled to the TOWN's level. DONE: a soak shows camps appearing and a town-level-appropriate boss.
- [x] D34. NATURAL DISASTERS: volcano, fire, drought, famine, sickness, hurricane, tornado, earthquake, meteor - be creative, with real consequences for the town. DONE: several distinct disasters fire in a soak and visibly affect the town.
      RESULT (desktop D-cycle D5, 2026-11-13): 13 disasters wired in economy.gd from the content writer's lore_lines.json "disasters" (begin/during/pass + alt variants). Each charges a real cost against the town's own stock/treasury/renown (fractions of current stock, so it scales) plus active effects - a production damp, a growth halt, and casting_blocked()/trade_blocked() flags for spells/trade to honour. Occasional, one-at-a-time, gated town_level>=2 & day>=6 so a founding is never struck; meteor leaves a scarglass windfall. tools/_d34_test.gd OK 191/0; live Town soak cut food on drought 60->24 and meteor 24->16.8, each pushing distinct begin/during/pass Chronicle lines, 0 SCRIPT ERROR. Visible-on-stream + Mr. E's eye still to come, and two hooks remain for a later cycle: wire casting_blocked into spells.gd and trade_frozen into the caravan path.
- [ ] D35. SHOPS NEED EYE CANDY AND VISIBLE STOCK - they should look good and show what they actually have. DONE: shot sheet; stock visible (pairs with L51's HUD side).
- [ ] D36. NPC DIVERSITY - more variety among townsfolk. DONE: a crowd shot with real variety.
- [x] D37. E3PO - A NAMED, IMMORTAL NPC (his favourite). E3PO CANNOT DIE. He is Commander of the Guards. When badly hurt he withdraws to the guard barracks and heals, then returns to duty. He must be woven into the lore, not bolted on. DONE: E3PO leads the guard in a raid, is wounded, withdraws, heals, returns - and never dies; his lore is written (see C4).
      RESULT (D-cycle D12): E3PO LIVES (notables.gd + 1 line in raids.gd, both mine). He spawns as a
      persistent notable 'E3PO / Commander of the Guards' at the garrison (lm_barracks; the gate watch
      if no barracks stands yet), Knight body + guard gear + cape. IMMORTAL BY CONSTRUCTION: raids.gd
      _defenders() now skips him by title, so he is never in the fall-able roster and can never be buried.
      He holds his post (role guard => no civic-flee). A line-picker reads data/lore_lines.json 'e3po'.
      <category> (incl sub-keyed viewer_roll.crit/high/low/fumble) with no immediate repeat; EVENT lines
      go to the Chronicle (town.feed), AMBIENT barks float above his head (shout_lines). WITHDRAW/HEAL/
      RETURN: on a raid breach he rolls hurt -> says a hurt+withdraw line, walks into the barracks, heals
      45-80 s, then says a return line and resumes his post. WIRED by polling real transitions (zero edits
      to trigger files): intro, raid, hurt, withdraw, return, festival, disaster, tier_up, plus ambient
      says/town_talk/night_watch(by hour)/drill/recruit/dispute. _d37_test: title OK, in town, 27 lore
      cats, NOT in defenders, picker OK, saying a line grows the feed + sets his shout -> D37_TEST OK.
      GATE GREEN: parse 0, _offfloor 0/1531, TWITCH_PARSE OK, _townwalk 0/18947 PASS, _delve_test rc0,
      0 SCRIPT ERRORs. LOOKED (renders/cycles/d37/e3po_post.png): the Commander at the garrison, named.
      DONE Nov 14 (all E3PO voice hooks now wired: laptop L-148 c4433a6 roster.gd+delve.gd;
      desktop a2dbd3a town.gd trader_arrives). Originally deferred, needed hooks in LAPTOP files roster.gd/delve.gd/chatcmd.gd, or caravan state - were not DESKTOP BUILD's to
      edit): viewer_roll(4), viewer_down, viewer_returns, viewer_cosmetic, rank_up (roster.gd viewer
      events); delve_dispatch, lord_sighted, lord_cleared (delve.gd); trader_arrives (D39 caravan). These
      categories are written + the picker already handles them - they just need their triggers to call
      notables._e3po_say(cat[,sub]). Also v2: let him ACTIVELY fight and intercept his fall->withdraw
      (v1 keeps him out of combat to guarantee he never dies). Flagged for Mr. E / laptop.
- [ ] D38. ON HOLD BY MR. E (2026-11-15 13:34) - DO NOT WORK THIS ITEM, DO NOT REGENERATE THE BEDS,
      DO NOT TICK IT. He listened to the four beds and both stings and said they "sound good", but he
      is UPGRADING music-studio first and wants them REDONE on the upgraded tool before he approves
      anything. The current files in assets/audio/music/ (bellmire_day/night/raid/delve + the two
      stings) STAY as they are and stay wired - they are good enough to stream on. Leave them alone.
      The three open questions (raid style vs the hype tempo gate, night's level, whether the delve
      bed should be director-driven) are DEFERRED until after the regeneration - do not answer them
      on his behalf and do not raise them with him again until he says the tool is ready.
      HE WILL SAY WHEN. Until he does, this item is not available to any worker.
      The upgrade he is making covers: a genuinely headless CLI, the compose() bias-knob bug, the
      style/mood tempo conflict, STEMS/vertical layering, long-form variation, project key+tempo
      coherence, leitmotif, transition cues, better seed search, and later procedural crowd/creature
      vocalisations, ambience and impact SFX.
      WHEN STEMS LAND, THE WIRING CHANGES: D22b's sfx.gd crossfades whole tracks. With stems it
      should fade LAYERS instead - the same piece with more of it as the town fills or a raid builds.
      That is a better system than what shipped; write it as a new item then, do not retrofit it now.

- [ ] D38. MUSIC - AN RPG FEEL. Better music throughout. Source from music-studio (READ-ONLY; copy out, never modify). DONE: day/night/raid/delve themes Mr. E approves.
      MR. E APPROVED THIS RECIPE (Nov 15) - generate fresh, do not hand-pick existing files.
      TOOL: C:\Users\morta\music-studio (v3.5.2). READ-ONLY: run it in place, copy WAVs OUT into
      assets/audio/music/, never modify the repo. Headless renderer: `npm run render` (cli/render.ts).
      Read docs/STYLES.md and docs/AI_GUIDE.md there first - they define every knob below.
      THE MAPPING (style x mood x role):
        day / town      -> style playful_pizzicato, mood playful, role bed
        night           -> style ambient_calm,      mood lowkey,  role bed
        raid            -> style epic_cinematic,    mood hype,    role music
        delve / dungeon -> style lofi_chill,        mood lowkey,  role bed
        victory + defeat stings -> the 2-5 s sting maker
      WHY `bed` MATTERS: role bed targets -20 LUFS and opens a speech pocket; the tool MEASURES the
      300-3000 Hz share so the music does not fight Mr. E's voice on a 24/7 stream. Use bed for
      everything that loops under talking. Only the raid cue is role `music` (-16 LUFS) because it is
      meant to take over. Verify with the tool's own describe()/report: mood.pass true and
      speechRoom.verdict pass for every bed before shipping it.
      LICENSING: music-studio synthesizes from seeds - the output is original, not a sample of anyone's
      track. Still add the credit note in assets/audio/LICENSE.txt saying which version generated them.
      DONE: day/night/raid/delve beds + 2 stings in assets/audio/music/, wired through D22b's
      transitions, each one's mood.pass and speechRoom verdict recorded in PROGRESS.md.
      RESULT (game build, 2026-11-15, LEFT OPEN for Mr. E's ear + two calls): beds + stings generated per the
      mapping and wired (D22b). Tool's own report: day seed 1286 mood.pass TRUE 0.678, speech pass 0.23 |
      night seed 2276 @74 BPM mood.pass FALSE 0.637 (threshold 0.65), speech pass 0.32 | delve seed 4737 mood.pass
      FALSE 0.564, speech pass 0.20 | raid seed 3414 (role music, speech n/a) mood.pass FALSE 0.603 - epic_cinematic
      tops out at 100 BPM, hype wants 140-160, so this cell CANNOT pass by construction. 66 candidates searched
      (tools/_d38_music_gen.mjs; per-try numbers in renders/cycles/d38/*.d38.json). Night/delve: every seed that passed
      mood FAILED or WARNED speechRoom even with the pocket at -12 dB; the speech-pass take was shipped (the voice wins).
- [ ] D39. TRADERS MUST MATTER. Today they arrive and leave with no effect. Make them carry SUPPLIES the town actually receives - and let bandits intercept them, so a lost caravan means the town goes without. An in-game event with stakes. DONE: a caravan arrives and the town gains; a caravan is taken and the town visibly suffers.
- [ ] D40. FISHING ANIMATIONS AND WATER both need work. DONE: before/after capture of a catch and the water surface.

# Mr. E's Nov 13 list - TWITCH (desktop owns the Twitch layer)
- [ ] T4. VIEWERS SHAPE THE TOWN (he wants this to feel like a D&D campaign where actions have consequences). Let viewers spend bits or channel points to VOTE on how the town grows: what gets built first, what gets upgraded, what laws pass - with real, lasting, sometimes BAD consequences. Open-ended by design. REWARD/AUTH SETUP IS DONE (Nov 15) - see T5's note; nothing is blocked on Mr. E. DONE: a vote runs on stream, resolves, and the town visibly changes because of it.

# Phase M - from the D28 census + the HUD worker's U1 report (supervisor, Nov 13 01:45). IDs frozen.

CENSUS RESULT THAT CHANGES THE PLAN: three of Mr. E's complaints are NOT bugs. Animations are fine
(30 distinct clips, 22251 starts, 0 missing, 0 fell-back). Spells are fine (9 distinct: heal 295,
bolt 161, mend 131, ward 112, smite 85, frost 46, chain 35, renew 31, fire 12). Loot is fine.
He is not seeing them - that is a READABILITY problem, not a content one. Do not build more of
these; make the existing ones legible. D30 and L52 are reframed below accordingly.

- [ ] D41. FINISH L40 - THE REST OF THE OVERLAP. The HUD worker made the Chronicle untouchable from
      HudDock.put(), but the two overlaps Mr. E actually flagged live in DESKTOP BUILD's files:
      party_frames.gd docks itself INTO a pane ("bl"), and rts_camera.gd owns the Twitch chat column
      and the chrome bar. Move the party frames and the chat column OUT of the panes. Owner: DESKTOP
      BUILD (do not reassign the files; the HUD worker correctly refused to touch them).
      DONE: a 1080p capture with 0 overlaps between any pane, the party frames and the chat column.

- [x] D42. FOOTSTEPS AND ANIMAL VOICES HAVE NO CALLER - this is the silent town, exactly located.
      sfx.gd DEFINES footstep_grass/stone/water/wood and dog_whine, wolf_howl/growl, eagle_cry,
      lion_roar, orc_roar, troll_roar, zombie_moan - and NOTHING IN THE GAME EVER PLAYS THEM. 40 of
      94 kinds never fired in a 7-minute 8x soak. Footfalls are the most frequent discrete sound a
      town makes. Give them callers: footsteps from the walk cycle (surface-aware), animal voices
      from the animals that own them. horse_neigh/whinny is called in daylight.gd but fired 0 -
      find out why. This supersedes the open question in D29; D29's measurement was right.
      TICKED (supervisor, Nov 14): D42 shipped the fix - townsfolk.gd:135-144 fires
      Sfx.at("footstep_" + surface_at(pos), pos, -13 dB) per stride at LOD 0, and animal.gd has
      VOICE[kind] on a per-beast timer. tools/_d42_test.gd gates it. The silent-town bug is closed;
      remaining tuning (mix levels, Mr. E's ear on a live soak) lives under D22a.
      DONE: a re-recorded town clip whose audio shows clear discrete events above the ambience bed.
      -> DONE D-cycle D3 (Nov 13): footsteps given a caller in Townsfolk._gait_step (one per 0.62*size stride of
      real travel, lod==0 only, surface from new town.surface_at - bridge=wood, river=water, roads/market=stone, else
      grass; Sfx GAP floor 0.05-0.08 s so a crowd patters). Heroes inherit it (HeroBody extends Townsfolk). Animal._voice
      gives each beast its own species call now and then (dog/cat/horse/foal/pig), raid-gated, 3D-attenuated, a frightened
      dog whines; this is why horse_neigh fired 0 - daylight.gd's ambient sampler keyed off the roaming director and the
      penned animals never triggered it, so the animals now voice themselves. tools/_d42_test.gd 60 s 8x soak: footsteps
      1642 (grass 745/stone 790/wood 59/water 48), animal voices 85 (horse_neigh 20 + whinny 4, cat 28, dog 15+whine 6,
      boar 12) -> D42_TEST OK. Gate: parse 0, _offfloor 0/1617, TWITCH_PARSE OK, _townwalk in_solid 0.006%, _delve 0 err.

- [x] D30. (REFRAMED by the census - the premise was wrong.) Spells are NOT monotonous: 9 distinct
      spells fire with a good spread. The problem is the viewer cannot TELL them apart. Make each
      spell read differently on screen and name itself in the Chronicle. Not more spells - clearer ones.
      -> DONE D-cycle 124 (Nov 13): the TOWN side, both halves. spells.gd: bolt/chain/fire wore one round
      orb (a blue, a pale-blue, an orange ball); now bolt is a lance of force (oriented along flight),
      fire a flaming ember (fire-trail that licks up), chain a crackling spark - frost already flew as a
      shard. And Spells.name_over() floats the cast's WORD over the town caster in its own colour (the
      mirror of L52's dungeon naming; the town had none), wired at both raids.gd cast sites, throttled per
      caster. tools/_d30_test.gd D30_TEST OK (11 checks): all 9 have a word+colour, no two words collide,
      the 4 thrown spells build 4 distinct forms (lance builds a BoxMesh core, orb a SphereMesh), name_over
      floats a correctly-coloured label, every spell still casts. NOT VERIFIED BY EYE at 1080p - headless
      asserts the meshes/colours/words, not a GPU frame (same limit L52/L53 noted); if two still read alike
      on stream it is a tweak to the forms in _orb, not a design question.

- [x] L52. (REFRAMED - same finding, dungeon side.) Nine spells already cast. Make the caster's
      choice legible rather than adding spells.
      DONE L-cycle 126: verified independently rather than trusting either side - my own caster-heavy run gave
      19-25 casts across 6-7 DISTINCT spells, so the content was never the problem and no spells were added.
      delve.gd: SPELL_WORDS names all nine and the name now FLOATS over the caster in that spell's own
      Spells.COL colour (the colour existed but only the projectile used it) - glanceable in a pane at no
      Chronicle cost - plus a calm line naming spell and target, one per caster per 2.5 s. BOTH cast sites,
      including the menders, which were the quietest of all. spells_cast{} exposed for a census.
      Removed again before shipping: my first version also announced misfires, which made the Chronicle
      print TWO lines per event because _scar_check already emits one from a lore_lines template - that is
      the feed noise L32b killed, and lore_lines.json is the content writer's file. The float carries the
      naming instead. tools/_l52_test.gd L52_TEST OK (9 checks): all nine spells have a name AND a colour
      and no two share a name. _offfloor 0 of 2004, _delve_test clean.
      NOT DONE, NOT MINE: making spells look different IN FLIGHT is scripts/spells.gd, DESKTOP-owned
      (COORDINATION 11.2) - untouched. If two spells still read alike after this, that is the remaining
      desktop-side work, and it pairs with D30.

- [x] L53. gear.gd _hat needs match-cases for the content writer's new hat keys (guard_helm,
      plumed_helm and the C1 hats) or they render as the default shape. Raised by the content writer.
      DONE L-cycle 128: worse than "the default shape" - the fall-through left CylinderMesh at ITS OWN
      defaults (top 0.5, bottom 1.0, height 2.0), a two-metre cone on the head. EIGHT keys had no case:
      guild_hood, mire_hood, watch_helm, miller_cap, bell_coif, ford_circlet, guard_helm, plumed_helm -
      each now has its own silhouette from the kit's primitives (hoods drape, coif is a dome on the skull,
      watch_helm a dome under a wide brim, miller_cap a peaked soft cap, ford_circlet a thin low band,
      guard_helm a closed helm with a nasal bar, plumed_helm that plus a crest). THE REAL FIX is the new
      wildcard default case, so hat number thirteen degrades to a plain cap instead of breaking the model.
      tools/_l53_test.gd is DATA-DRIVEN - it reads every kind=="hat" cosmetic out of items.json and builds
      it, so new hats are covered without touching the test. L53_TEST OK (5 checks): 12 hats, 11 distinct
      silhouettes (guild_hood/mire_hood share one by design), none left at the defaults, unknown key
      degrades. L3_TEST OK, _offfloor 0 of 1388, _delve_test clean. items.json read, never written.
      NOT VERIFIED BY EYE: headless mesh assertions only - nobody has seen a plumed helm at 1080p yet.

- [x] L54. delve.gd must honour the new 'scar_touched' potion state or Scarwater displays and does
      nothing. Raised by the content writer.
      DONE L-cycle 129: verified first - the flag was right. potions.json has shipped Scarwater giving
      scar_touched for a while and the ONLY scar_touched in scripts/ was fishing.gd's unrelated
      scar_touched_chance, so the draught was bought, drunk, displayed and did nothing. delve.gd
      _scar_check(): a scar-touched hero skips the usual roll because the scar already has their spell -
      it decides once, half doubled and half taken, and the draught is spent either way. Both outcomes
      float in the scar's violet and reach the Chronicle. Hung off the EXISTING scar machinery rather
      than a parallel one. Applies to MENDING too - the data says "its next SPELL", not attack.
      A REAL BUG MY TEST FOUND BEFORE SHIPPING: the doubling was consumed AFTER the to-hit check, so a
      spell that MISSED kept the flag and doubled the next cast - one 300-gold draught paying twice. It
      is taken and cleared at the top of _cast_at now, before any early return. tools/_l54_test.gd
      L54_TEST OK (10 checks) - it re-reads potions.json so it tracks the DATA, drives 60 casts needing
      both outcomes, and asserts the state NEVER lingers. Measured 28 doubled / 32 taken / 0 lingered.
      _offfloor 0 of 1430, _delve_test clean, L52_TEST OK. potions.json read, never written.

- [x] L55. FORGING MAY NOT RAISE GEAR TIERS - a bug nobody had reported, found by the census. Weapon
      and armour tiers stayed w0/a0 for ALL SIX heroes through a 7-min soak despite 17 forge lines
      and survivors with 4 and 8 kills. Either forging never raises the tier or death resets it.
      DONE: a soak where surviving heroes visibly climb tiers.
      DONE L-cycle 127: measured first, and NEITHER suspected cause was it. buy_weapon/buy_armour work
      (a probe with gold went w0->w1, a0->a1), and kill()/reroll() keep the gear - a returning hero is a
      FRESH hero at w0, which is canon. THE REAL CAUSE: nothing ever CALLED the forge for a VIEWER's hero.
      The town band kits up in Adventurers._kit_up; a viewer's hero only forged if that viewer typed
      !forge. Reproduced exactly - four survivors home with 69-115 gold, tier 1 costing 52, none climbed.
      The census's 17 "forge lines" were refusals, not purchases. FIX: Roster.kit_up_after_delve() fits
      out a survivor who comes home with coin - ONE step a delve, always leaving KIT_RESERVE (3 oil) so
      nobody is stranded, armour first while it trails, and the smith's line is SAID so the viewer sees
      what their gold bought. Called from delve._finish(). tools/_l55_test.gd L55_TEST OK (12 checks):
      round 1 climbed 0 of 4 (loot luck), round 2 climbed 2-3 of 4 - tiers climb across a SESSION, which
      is what "a soak" means. _offfloor 0 of 1231, _delve_test clean, L3_TEST OK.
      MR. E'S CALL: heroes now spend their own gold automatically. KIT_RESERVE and the one-step cap are
      the dials; removing it is one call in _finish(). FOR THE SUPERVISOR: scripts/adventurers.gd is in NO
      worker's ownership list in COORDINATION 11.2 - read, not touched; it needs an owner.

- [ ] L56. DELVE-HEAVY SOAK before L45 and L46 are trusted. The census could not confirm bosses or
      trap damage: raids kept pulling parties back to town and only ~1 sustained descent happened,
      so the dungeon-side counters undercounted. Seed a party straight to the mouth (or raise
      CENSUS_MIN) and read Delve.trap_log directly. This GATES L45 and L46 - do not "fix" either
      until this run says they are actually broken.

- [x] D37 note: E3PO's words now EXIST (content writer's e3po + town_life blocks in lore_lines.json,
      merged). They are dead data until raids.gd/town.gd read them. The content half is done; the
      behaviour half is still D37 and belongs to DESKTOP BUILD.

CHANGELOG 2026-11-13 01:41 (supervisor): added D41, D42, L53-L56; reframed D30 and L52 after the census
disproved their premise; noted the C-side of D37 is delivered. C-cycles 1-3 merged to main.

# Phase N - Mr. E's rulings, Nov 13 01:50. The d20 becomes the resolution mechanic for viewer spending.

HIS WORDS: "we can do the hub for individual rolls, and then when it comes to making upgrades to the
town depending on channel points or bits spent they can roll the die to make events happen, upgrade
buildings, etc."

SUPERVISOR ARCHITECTURE RULING - READ THIS BEFORE BUILDING ANY OF IT. The roll is resolved IN THE
GAME, never on the website. Viewer redeems channel points or cheers bits -> Twitch EventSub reaches
the game -> the GAME rolls the d20 and applies the outcome -> it is Chronicled and appears in the
60 s snapshot -> the hub DISPLAYS the roll and its result. The hub therefore stays READ-ONLY and
this does NOT trip the Phase 3 RLS gate. No viewer write path to Supabase. Do not design one.

- [x] T5. THE VIEWER'S ROLL (this is the heart of T4 and supersedes its vague "voting"). A viewer
      RESULT (game build, 2026-11-15 ~21:20 CT): SHIPPED. New channel-point reward "Roll for Bellmire" (750,
      viewer types build / festival / a law by name, else fate picks; NO hero needed). twitch_eventsub.gd
      viewer_roll(): d20 in the game -> 20 triumph / 13-19 goes well / 8-12 mixed / 2-7 badly / 1 backfires;
      build = smithy raise_shop (rack lights up), event = a festival in the viewer's name, law = a
      propositions entry whose good/bad line comes true and moves renown (half the town score). Chronicle:
      "<name> rolls a N to <do> - <band>. <what happened>" + E3PO's verdict from e3po.viewer_roll (shouted).
      snapshot_pub publishes `rolls` [{n,by,what,result,tier,cost,at}] (v stays 4, additive; result capped
      at 400 never 200). tools/_t5_roll.gd T5_ROLL OK 23/23 incl. 5 failure outcomes and a real redemption
      payload through handle_event; shots renders/cycles/t5/. MR. E: the reward is only CREATED on a resync -
      set [twitch] rewards_resync=true in user://twitch.cfg for ONE launch, then back to false.
      UNBLOCKED (Nov 15): Mr. E re-authorized the broadcaster token via device-code grant. The game's
      Twitch app (client s4lpypbhumi34uocr0jqrscsxmjz2u) now holds channel:manage:polls AND
      channel:read:polls alongside the original five (bits:read, channel:manage:redemptions,
      channel:read:redemptions, channel:read:subscriptions, moderator:read:followers). Validated live
      against id.twitch.tv/oauth2/validate as login jestsayin96, user_id 138821183; refresh token
      present so the game renews itself. Token at user://twitch_token.json; the pre-polls token is
      backed up beside it as twitch_token.json.bak_prepolls. NOTHING IS BLOCKED ON MR. E.
      THE WORDS ARE ALREADY WRITTEN: data/lore_lines.json "propositions".entries, and the
      viewer_roll crit/high/low/fumble outcome lines added in C-cycle 38. Read them, do not invent
      parallel copies.
      ARCHITECTURE (unchanged): the d20 resolves IN THE GAME; the hub only DISPLAYS the result from
      the snapshot (H9 already renders it). Do not build an on-screen d20 - that left the HUD lane.
      spends channel points or bits to attempt something - upgrade a building, trigger an event,
      push a proposition - and a d20 roll decides how it goes. D&D consequences: a high roll does it
      well, a low roll does it badly or backfires, and the Chronicle says so in plain language.
      Outcome tiers must be readable to someone who has never played D&D. The propositions the
      content writer is authoring (lore_lines "propositions", C-cycle 4) are the menu this draws on.
      Owner: DESKTOP BUILD (owns the Twitch layer, town and economy).
      DONE: a viewer redemption rolls on stream, the town visibly changes, and the Chronicle explains
      why - with at least one failure outcome demonstrated, not only successes.

  SUPERVISOR NOTE (2026-11-15 15:58 CT) - WHERE THE CRIT AND FUMBLE LINES ACTUALLY ARE. The hub shipped
  H27's roll board this cycle and reported the field missing: there is NO top-level `viewer_roll` key in
  data/lore_lines.json. The C-cycle 38 lines were written one level down, at `e3po.viewer_roll`, with four
  pools (crit / high / low / fumble) - verified on main this run. Nothing is missing and the content writer
  should NOT write a parallel top-level copy. GAME BUILD: when T5 resolves a roll, take the outcome line
  from `e3po.viewer_roll` and PUBLISH IT as the roll's `result` string. The hub never reads lore_lines - it
  renders exactly what the publisher sends - so a roll published without `result` shows a number and no
  outcome, which is the one visible gap left in H27's board.
- [x] H9. THE HUB DIE SHOWS THE ROLL. The hub's existing die section animates and displays rolls read
      FROM THE SNAPSHOT - individual rolls, and the outcome of a T5 viewer roll. Read-only: the page
      never initiates or submits a roll. Keep every HUB_SECURITY invariant (el()/textContent, no
      snapshot value as URL/src/href/style, CSP unchanged). Owner: HUB BUILDER.
      DONE: a roll and its outcome render on the hub, hostile-name test still passes.
      TICKED (supervisor, Nov 14): shipped on hub (49676fe, db2719e) - the die shows the town's rolls from the snapshot and the rolls feed caps after dropping empties.

- [ ] D43. SUBSCRIBER ROSTER FROM THE TWITCH API (Mr. E approved). Twitch sends subscription EVENTS,
      not a roster, so the subscriber lane currently only knows about subs that happen while live.
      Fetch the real roster via Helix with the broadcaster token and the channel:read:subscriptions
      scope, refresh it periodically, and expose it for the HUD worker's subs lane. Token in user://
      NEVER in the repo. Owner: DESKTOP BUILD (owns the Twitch layer). UNBLOCKS L35.
      NEEDS MR. E: authorize the broadcaster token with channel:read:subscriptions.

- [ ] L35 note: the subs lane stays as built (rotates through subs seen this session) until D43
      lands, then reads the real roster. Not a defect in the HUD worker's implementation.

- [ ] L51 note: the "d20 redesign" part of L51 is now T5 + H9 and leaves the HUD worker's lane. What
      REMAINS in L51 for the HUD worker: equipment with its buffs/debuffs, the viewer's inventory,
      and selling - built as a NEW self-contained panel inside the seven HUD files. The unit frame
      (rts_camera.gd) and the !hero sheet (chatcmd.gd) stay with their owners; if the panel needs
      state those files hold, flag it and the owner exposes it. Do not edit another worker's file.

CHANGELOG 2026-11-13 01:57 (supervisor): added T5, H9, D43 from Mr. E's rulings; L51 narrowed and its d20 part
moved to T5/H9; L35 unblocked by D43. The hub remains read-only - the roll resolves in-game.

# Phase O - THE WORDS NOW EXIST. Content is no longer the blocker (supervisor, 2026-11-13 02:03).

C-cycles 3 and 4 are merged to main and passed the full gate (parse 0 SCRIPT ERROR, 0 Parse Error,
TWITCH_PARSE OK, _townwalk in_solid 0/795, _delve_test clean, _offfloor clean). Verified counts in
data/, not taken on trust. Every item below is now WRITING-COMPLETE and waiting only on code:

  T5   <- lore_lines "propositions".entries - 17 laws, each with a GOOD and a BAD consequence,
          across law, taxes, militia, building, faith and outsiders. This is the menu the d20 rolls on.
  D34  <- lore_lines "disasters" - 12 (volcano, fire, drought, famine, sickness, hurricane, tornado,
          earthquake, meteor, scarstorm, flood + one more), each with begin / during[] / pass and a
          plain-language "cost" stating what it should do to the town. Implement the cost as mechanics.
  D33  <- lore_lines "events" - 4 NAMED bandit camps (Red Harl, Sedge the Toll, Cob Ashfoot, The
          Weasel), 3 monster camps, and a wandering boss "The Scarred Lord" that scales to the town
          and reuses the 8 canon lords. Named enemies read far better on stream than "camp 3".
  D31/
  D32  <- lore_lines "growth_tiers".tiers - 12 stages from Crossing to City, each with the crier's
          line and WHAT A VIEWER SHOULD SEE APPEAR. Twelve stages exist precisely because Mr. E said
          the town levels far too fast; pace the climb across them.
  D35/
  D39  <- items.json "shop_stock" (13) and "trader_cargo" (11), {name, cost, flavour}. Shop display
          reads shop_stock; interceptable caravans carry trader_cargo.
  D37  <- lore_lines "e3po" (intro/withdraw/return/says/town_talk) + "town_life". E3PO's words exist;
          his behaviour does not. DESKTOP BUILD owns the behaviour.
  L53  <- gear.gd _hat cases for the new hat keys.   L54 <- delve.gd honours 'scar_touched'.

NOTE TO THE DESKTOP BUILD WORKER: you deferred the regression battery on 750682b because the HUD
worker held the lock - that was the correct call. The supervisor has since run the full battery on
main INCLUDING your commit and it passed clean. You do not need to re-run it for D28.

CHANGELOG 2026-11-13 02:03 (supervisor): C3+C4 merged and gated; the content writer has cleared every
writing-blocked item on Mr. E's list. The constraint is now code, not words.

# Phase P - Mr. E's rulings, Nov 13 02:20.

- [x] L57. "NOW WATCHING" GOES ABOVE EACH PANE, not one global banner. Mr. E: "just have the now
      watching above each of the split screen for whoever that specific screen is watching." Each
      pane carries its own small label naming the subject that pane is following, so a viewer can
      tell at a glance which of the four screens is theirs. Must not overlap the pane image or the
      Chronicle (L40 discipline). Owner: DESKTOP HUD (its own files).
      DONE: a 1080p capture, four panes, four correct labels, 0 overlaps.

- [x] L58. THE GUILD ROLL LEAVES THE STREAM. Mr. E: "the guild roll it can stay on the hub doesnt
      need to be on stream, it can be for chat as well." It is the TOP-10 STANDINGS (rank, name,
      rank title, level, deepest, a mark for the dead) - not the full roster. It already exists in
      two places that are enough: the hub, and the free `!guild` / `!ranks` chat command. So:
      remove the on-stream Guild Roll panel and stop reserving space for it. Owner: DESKTOP HUD.
      NOTE: the chat command already works - nothing to build there. Verify `!guild` still answers
      after the panel is removed; if the panel owned the data path, keep the data path.
      DONE: no Guild Roll on stream, !guild still answers in chat, hub unchanged.

  This closes the carried-over question "the Guild Roll and the Now watching banner have no home
  under the permanent grid". The banner becomes per-pane (L57); the roll is cut from stream (L58).

- [x] L45 ANSWERED by Mr. E: "the bosses should get harder the further you go, so some bosses will
      hurt and have a lot of hp". The depth curve ships as built. For the record, lords appear every
      fifth floor and scaling starts at zero on the first one, so the first lord is unchanged canon
      (15.0 atk / 150 hp) and the quoted 44.7 / 528 is ten lords down. The curve is open-ended.
      No further balance change requested.

- [x] L46 ANSWERED: leave the trap rate as built and see how it plays. The dial, if it ever reads
      punishing, is the trap COUNT in dungeon_hd._dress(), not the damage.

CHANGELOG 2026-11-13 02:24 (supervisor): merged laptop L47/L45/L46/L49 to main. Added L57, L58 from Mr. E's
rulings. L45 and L46 balance questions answered by him and closed.

# Phase Q - THE HUD RECONCILIATION. Read this before anything else, DESKTOP HUD worker (2026-11-13 03:10).

- [x] L59. RECONCILE hud-ui WITH main. DO THIS FIRST, BEFORE L51 OR ANYTHING ELSE.
      WHAT HAPPENED, AND IT WAS THE SUPERVISOR'S MISTAKE: L34 (director pane freezes) and L39
      (Chronicle) were handed to you under COORDINATION 11.4 without first checking whether the
      laptop had already built them. It HAD. The laptop's L34 is commit 75a6226 and is now merged
      into main. Your U1 (35d10d8) fixes the same bug independently. Two correct fixes, same two
      files. Neither worker did anything wrong.
      The supervisor attempted the merge and ABORTED it deliberately: it conflicts in FOUR code
      files - auto_director.gd, spotlight.gd, hud_dock.gd, feed_hud.gd - and resolving competing
      GDScript implementations without being able to run a WINDOWED UI test would risk shipping a
      broken overlay. You own these files and you can look at the result. So it is yours.
      HOW TO DO IT:
        git -C W2 fetch origin ; git -C W2 merge origin/main        (expect the four conflicts)
        For each conflicted hunk, PREFER YOUR OWN implementation - you own these files going
        forward and yours was written against the current contract. BUT read the laptop's side
        before you discard it: if its L34 handles a case yours does not, keep that case. The two
        fixes were aimed at the same two root causes, so the union is likely better than either.
        PROGRESS.md: keep BOTH sides, strip only the marker lines, never renumber a cycle.
      THEN VERIFY, and this is the part that matters: boot WINDOWED at 1920x1080 and confirm the
      director pane recovers when its subject dies, rerolls or vanishes - the actual bug. A clean
      parse is not evidence here. LOOK at it.
      L39 NOTE: the laptop's L39 attempt (415885a) shrank the PANEL and left the font at 28 px.
      Mr. E's correction was the opposite order - SMALLER TYPE FIRST, then size the box. Your U1
      did it his way (28 -> 18 px, then a 0.34-width centre box). Yours is the correct one. Do not
      let the laptop's version win that hunk.
      DONE: hud-ui merged with main, four conflicts resolved, a windowed 1080p capture showing the
      director pane recovering from a subject death, and your honest read on whether 18 px is
      legible on stream - Mr. E has not seen the final crop and the supervisor will not tick L39
      until someone has actually looked at it.

CHANGELOG 2026-11-13 03:10 (supervisor): added L59. The hud-ui/main collision is logged as a supervisor error,
not a worker error, and handed to the owner of the files to resolve with a windowed test.

# Phase R - L39 SIZED FROM MR. E'S OWN SCREENSHOT (2026-11-13 04:05). HUD worker: this supersedes the guesswork.

- [x] L39b. THE CHRONICLE BOX IS TOO SHORT, NOT TOO NARROW. Mr. E drew a red rectangle on a live
      1x screenshot showing exactly how big the box may be. Measured against his window:
          his red box   ~0.37 of window WIDTH, ~0.27 of window HEIGHT
          current box   ~0.33 wide, ~0.10 tall   (CENTRE_W 0.34, STRIP 0.12 -> 652x130 at 1080p)
      So the WIDTH is close to right - a touch wider is fine. The HEIGHT is the miss: he is giving
      you roughly 3x the vertical space. At 1080p his box is about 715 x 295 against today's
      652 x 130.
      WHAT THIS MEANS, AND DO NOT GET IT BACKWARDS: a taller box is NOT bigger type. The font stays
      small - he complained the letters were "super huge" and 18 px was the fix. The extra height
      buys MORE LINES OF CHRONICLE ON SCREEN AT ONCE. Today roughly three lines fit; at his size
      closer to eight or nine. A viewer should be able to read back what just happened instead of
      watching it scroll away.
      So: raise the line count the Chronicle keeps visible to fill the taller box, keep 18 px, and
      make sure the box still sits in the gap between the two pane rows without covering a pane
      (L40 discipline - his screenshot shows the box overlapping the pane seam, which is fine, but
      it must not hide a subject).
      DONE: a windowed 1080p capture at roughly 715x295 with the extra Chronicle lines filling it,
      18 px type, no pane obscured - and your honest word on whether 18 px reads at that size.

CHANGELOG 2026-11-13 04:05 (supervisor): L39b added from Mr. E's annotated screenshot. The earlier L39 work was
not wrong, it was short - width was close, height was a third of what he wants. This is the first
time the item has had a number from him rather than an inference.

# Phase S - supervisor pass 2026-11-13 05:02. Merged: content C5-C9, laptop L52/L53/L54. Gate clean.

- [x] L59b. COMMIT THE MERGE FIRST, THEN TEST. THIS IS WHY L59 KEEPS COMING BACK.
      `hud-ui` branched at a1f7463 (Coordination 11) and HAS NEVER MERGED main since. main is now
      49 commits ahead of that point; hud-ui has 5. A U2 session DID resolve all four code
      conflicts correctly in the worktree - and then the run ended before committing, so the
      resolution was lost. U3 and U4 then built on top of the still-unmerged branch. The supervisor
      has now hit the same four conflicts a third time and will not resolve them blind, because
      these are your files and a windowed test is the only real check.
      THE FIX IS ORDERING, NOT SKILL. Next run, in this order, and do not reorder it:
        1. git -C W2 merge origin/main
        2. Resolve the four conflicts (auto_director.gd, spotlight.gd, hud_dock.gd, feed_hud.gd)
           plus PROGRESS.md. Prefer YOURS - you own these files - but keep the laptop's
           is_instance_valid(src) guard and its _eye_xform(eye) step in spotlight.gd, which your
           side lacks and which are real: a freed camera is non-null.
        3. COMMIT AND PUSH THE MERGE IMMEDIATELY. Before any Godot run, before any test, before
           any further edit. A merge commit that only resolves conflicts is a perfectly good
           commit. If this run dies after step 3 the work survives; if it dies before, we are back
           here a fourth time.
        4. THEN run your headless parse and your windowed test, and commit those separately.
      Your U1-U4 work is good and none of it is in question - L34 is verified recovering from die,
      reroll and despawn, which is exactly what was asked. The only defect is that the branch has
      drifted 49 commits behind main and nobody has landed the reconciliation.
      DONE: origin/hud-ui contains a merge commit from origin/main, and `git merge origin/hud-ui`
      from main reports no conflicts.

NOTE ON COLLISIONS, and this one is the supervisor's fault: the HUD worker has reported repeated
two-session collisions (U3, U5). The cause is almost certainly the supervisor firing the task
manually at a time close to its own :41 slot, producing two runs of the same task against one
worktree. The supervisor will not hand-fire the HUD task again unless its slot is more than 20
minutes away. The workers' lock discipline has held throughout - nothing was lost in any collision,
because each session checked, stood down and wrote down the state it left behind.

CHANGELOG 2026-11-13 05:02 (supervisor): merged content C5-C9 and laptop L52/L53/L54 to main; full gate clean
(import, parse 0 errors, _offfloor, TWITCH_PARSE OK, _townwalk in_solid 0/824, _delve_test).
hud-ui held with L59b. Hub H9 reviewed separately and held for Mr. E.

CHANGELOG 2026-11-13 06:16 (supervisor pass 06:07): merged content C10, laptop L48, and hud-ui U1-U5 to main.
The hud-ui merge was CLEAN - L59b's ordering fix (commit the merge before testing) worked and the
branch drift is gone. Full gate clean: import, parse 0 SCRIPT ERROR / 0 Parse Error, _offfloor,
TWITCH_PARSE OK, _townwalk in_solid 0/866 stuck_on_route 0, _delve_test.
TICKED: L35, L38, L51, L59, L59b.
NOT TICKED ON PURPOSE: L39 and L39b. Mr. E corrected the Chronicle twice and has now given a size
from his own screenshot (about 715x295 at 1080p, roughly 3x today's height, more LINES not bigger
type). Nobody has yet looked at the final crop and said it reads on stream. A measurement is not a
look. These stay open until a human says the type is legible.
Also not ticked: L40 - only the HUD half is done (HudDock.put() keeps the Chronicle clear). The two
overlaps Mr. E actually flagged live in party_frames.gd and rts_camera.gd and are D41, desktop-owned.

# Phase T - supervisor pass 2026-11-13 10:19.

- [x] D44. TOWNWALK in_solid HAS GONE INTERMITTENTLY NON-ZERO. Owner: DESKTOP BUILD (town_nav.gd).
      DONE (D-cycle D11): subsumed by D44b - three consecutive _townwalk in_solid 0 with the cause named.
      Measured by the supervisor, three consecutive runs on the same merged tree:
          in_solid 2/745      in_solid 5/913      in_solid 0/810
      Every supervisor gate before this one reported 0: 0/796, 0/824, 0/866, 0/900. So this is new
      and it is INTERMITTENT, not a hard break - which is why the merge was pushed rather than held.
      Walkers are momentarily registering inside solid geometry. "inside" (people legitimately in
      buildings) sits at 45-48 across all three runs, so the likely place to look is the doorway
      transition - a walker crossing a threshold sampled mid-step - rather than open-street nav.
      DO NOT "fix" this by loosening the test. The 0 was real and worth keeping.
      DONE: three consecutive _townwalk runs at in_solid 0, with the cause named.

CHANGELOG 2026-11-13 10:19 (supervisor): merged content C12, laptop L43, hud-ui U7/U8 to main. Gate otherwise
clean (import, parse 0 SCRIPT ERROR / 0 Parse Error, _offfloor, TWITCH_PARSE OK, _delve_test).
TICKED L57 and L58 - both are Mr. E's own rulings, implemented as he worded them.
D44 raised for the intermittent in_solid.

# Phase U - the laptop's queue is NOT empty (supervisor, 2026-11-13 11:22)

The laptop reported "the assigned queue is empty" after L44. It finished the list it was GIVEN;
it did not run out of work. Eleven laptop-owned items are still open. Take them in this order -
this ordering is by what Mr. E actually asked for, not by ID.

  1. L29a LORD MECHANICS - each canon lord gets a real mechanic (adds / phase / hazard / enrage).
     He asked for bosses that get harder with depth and L45 gave them numbers; this gives them
     BEHAVIOUR, which is what makes a lord memorable on stream.
  2. L30c LOOT TABLES by depth and biome, boss uniques, and the Chronicle announcing a rare find.
     L49 made searching visible; this makes what you find worth watching.
  3. L29b RARE UNIQUES - the content writer has already WRITTEN them (bosses.json lesser_uniques
     42, greater_uniques 36). Your half is the spawn rule and the visible modification. Read the
     data, do not invent a parallel copy, and do not edit that file - it is the content writer's.
  4. L29c SET-PIECE ENCOUNTERS from lore so a floor is not just a room of monsters.
  5. L37 DUNGEON SCAR-VEINS ARE OVERDONE - from Mr. E's own 19:27 recording, the L28d glow decals
     read as bright purple spray. Same family as L42; he has already said the dungeon looked like
     a nightclub.
  6. L33 STUCK DELVER REGRESSION - _l25_test went from a clean 0 stuck after L27a. Worth closing
     before more monsters land.
  7. L27b STRAINS - still committed WIP at 0f3986c. Finish or withdraw it; do not leave it parked.
  8. L56 DELVE-HEAVY SOAK - seed a party straight to the mouth so boss and trap counts can be
     trusted. Lower priority now that L45/L46 shipped with their own tests, but it is the only
     thing that will give a clean dungeon baseline.
  9. L30a GEAR EXPANSION - the code half only: more weapons and armour per tier VISIBLE on the
     handslot bones. The item list itself is the content writer's.
 10. L30b COSMETICS AND DYES - again the code half only: !wear and !dye changing the model live.
     The catalogue is written (46 cosmetics, 19 dyes) and is not yours to edit.

OWNERSHIP CORRECTIONS - three items are no longer the laptop's, because the UI files moved under
COORDINATION 11:
  - L31 DUNGEON-FIGHT UI (damage numbers, status icons, "Now fighting: <lord>") -> DESKTOP HUD
    for anything inside its seven files, feed_hud.gd included. If it needs party_frames.gd or
    rts_camera.gd, flag it for the desktop build worker rather than reaching in.
  - L36 CHAT OVERLAY COLLIDES WITH THE CENTRE CHRONICLE (from Mr. E's 19:34 recording) -> DESKTOP
    BUILD. rts_camera.gd owns the chat column. Same family as D41 and should be done with it.
  - C1, C2, C3 are long since delivered by the content writer (C-cycles 1-13) and are stale
    entries, not open work. Ignore them; they are left unticked only because nobody has gone back
    to tick them.

CHANGELOG 2026-11-13 11:22 (supervisor): queued L29a/L30c/L29b/L29c/L37/L33/L27b/L56/L30a/L30b for the laptop in
priority order; reassigned L31 and L36 off the laptop to the HUD and desktop workers respectively;
noted C1-C3 as stale. No new IDs minted - every item here already existed and keeps its number.

# Phase V - D44 ESCALATED (supervisor, 2026-11-13 12:03). Desktop build: THIS JUMPS YOUR QUEUE.

- [x] D44b. D44 IS GETTING WORSE, NOT SETTLING. Take it before D29 or anything else.
      DONE (desktop D-cycle D11, 2026-11-14): CONFIRMED by per-frame log, not sampling. tools/_d44_perframe.gd
      tagged every walk commit by leg (townsfolk._dbg_leg) over 513,201 per-frame samples: the ONLY in_solid
      frames were the NORMAL leg (0 ghost/door/seat), all at the (52,-88.6) south-market stop. Two root causes,
      both fixed in townsfolk.gd: (1) a generated stop DESTINATION could lie inside the overlap - _next_trip's
      returned dest is now keep_walkable-snapped at the caller so a body never stands embedded on arrival;
      (2) keep_walkable/_slide_round occasionally could not clear the overlap and the inside foot was carried
      frame-to-frame via `was` - the normal/ghost commit now snaps to the navmesh (baked from the SAME
      footprints, so its nearest point is walkable by construction) instead, door/seat legs excluded (they end
      inside by design and the audit skips them by endpoint). No test loosened; a position can only become MORE
      walkable. Gate GREEN: parse 0, _offfloor 0/1344 (INPROP 0, MON_INPROP 0), TWITCH_PARSE OK, _delve_test
      clean to floor 2, and _townwalk THREE CONSECUTIVE in_solid 0: 0/18657, 0/18673, 0/18748 (raid_in_solid 0).
      Measured by the supervisor across six runs on two separate merged trees:
          pass 1:  2/745   5/913   0/810      (peak 5)
          pass 2:  8/899   0/754   0/852      (peak 8)
      Every gate before pass 1 read a clean 0: 0/796, 0/824, 0/866, 0/900.
      So: still intermittent, two runs in three come back clean - but the PEAK IS RISING. That is
      the signature of a race or a tolerance that is being crossed more often as the town fills,
      not of harmless noise. It will not settle on its own.
      WHAT IS KNOWN: "inside" (people legitimately indoors) holds steady at 41-49 across all six
      runs, so this is not a miscount of building interiors. walking is 114-124. The failures are
      a small number of walkers out of 750-900 samples, which points at a transient - most likely
      a walker sampled mid-step through a doorway or against a prop placed after nav was baked.
      D20b (raid flee into doorways) and D20c/animals are the most recent town-nav-adjacent
      changes; the trap and chest props added dungeon-side should NOT affect town walkers, but
      rule it out rather than assume.
      DO NOT raise the tolerance, widen the sample, or soften the assert. The 0 was real for many
      consecutive gates and it is the only thing telling us the town nav is sound.
      DONE: three consecutive _townwalk runs at in_solid 0 WITH the cause named in PROGRESS - not
      three lucky runs.
      PARTIAL (desktop D-cycle 126): CAUSE NAMED. The offenders are the stops-based _more_folk
      townsfolk - their home/work are ZERO by design (a day of `stops` replaces the shuttle),
      so the audit's `e != ZERO` endpoint guard can never shield them. _put_folk placed them
      at a stop point WITHOUT a walkability check. Two sub-cases:
        (a) SPAWN EMBEDDED - the spawn/stop point lay inside a carved solid; an off-mesh start
            breaks route() (it falls back to a single far waypoint and the body wanders into
            the valley), and keep_walkable shoves it clear only over ~2 s, counted every
            sample meanwhile. This was the PERSISTENT, town-fill-scaling contributor behind
            the RISING 5->8 peak. FIXED: _put_folk now snaps the spawn out of any footprint
            (keep_walkable; pre-sync so purely geometric). Verified: pre-fix a peasant span
            embedded every seeded run; post-fix none do.
        (b) RESIDUAL, FLAT (not rising): a walker on a NORMAL leg sitting ~1.5 m inside a
            carved footprint for a few samples at the 15 southern 'market'-district houses
            (z<-55) - e.g. (51.7,-93.8), prop (74.1,-65.6). dl/seat/ghost all false, navoff
            ~1.5. Post-fix the gate gave THREE consecutive _townwalk 0 (0/16017, 0/16363,
            0/15601) with _offfloor/_twitch_parse/_delve all clean, BUT other post-fix runs
            still showed a stray 1-2 (one verify run 2/16003; one seeded diag 1) - so this is
            NOT yet the 'not-lucky' three zeros. Left UNTICKED for that reason.
      FOLLOW-UP for the next desktop cycle (NOT done here - would be an unverified change to
      the hot walker loop): snap stop DESTINATIONS too, or add a keep_walkable net on the
      waypoint-pop early-return (townsfolk ~L813 returns before the step's keep_walkable), or
      widen the nav margin at the southern houses. The test was NOT loosened.
      PARTIAL (desktop D-cycle D4, Nov 13 ~17:30): took the note's "keep_walkable
      net" option. keep_walkable now runs 6 push passes (was 3 - a chain of
      overlapping south-market footprints can oscillate and leave a foot inside
      after 3) and, when the point is STILL in a footprint after the loop, snaps
      to the navmesh's nearest walkable point (the authority); rare path, so the
      common already-clear case pays no nav query. Full gate GREEN: parse 0,
      _offfloor 0/1643 (INPROP 0, MON_INPROP 0), TWITCH_PARSE OK, _delve_test
      clean to floor 2, _townwalk x3 PASS at in_solid 0/15466, 1/15863, 2/16816
      (0.000/0.006/0.012%, all << 0.2%). NOT three-consecutive-0, so NOT ticked.
      The residual did not move measurably: a single-FRAME transient at the ~15
      south houses (recurring child Rask Coalfoot ~(52,-88.6), peasants ~(74,-64))
      that a 0.25 s diagnostic probe (4 runs) could not catch at all - the gate's
      0.5 s grid only rarely lands on it. Hardening kept as a correctness win (a
      position can only become MORE walkable; no test loosened), not as a close.
      NEXT: log PER-FRAME (not sampled) which branch commits the inside position -
      prime suspect the ghost/pocket-escape leg (townsfolk ~L821) that moves on
      height_at ALONE and never calls keep_walkable while _ghost_last stays in the
      route; if confirmed, re-validate that leg with keep_walkable.

CHANGELOG 2026-11-13 12:03 (supervisor): merged content C13-C14, laptop L44 + L27b (no laptop WIP remains),
hud-ui U9. Gate otherwise clean (import, parse 0 SCRIPT ERROR / 0 Parse Error, _offfloor,
TWITCH_PARSE OK, _delve_test). D44 escalated to D44b after its peak rose from 5 to 8.

# Phase W - Mr. E's L41 ruling (2026-11-13 12:37)

- [x] L41 CLOSED BY MR. E. He looked at confection_before.png and confection_after_muted.png and
      ruled: TOO MUTED, PUT THE PINK BACK. data/biomes.json confection ground reverted to
      ["#e8b0cc", 0.35] - the exact one-line revert the laptop itself documented. ONLY the ground
      was reverted: L42 separately lowered this biome's sat and glow, and that stays, so the floor
      is bright pink under calmer lighting rather than the original neon.
      The laptop's GUARD STAYS and was the real work of L41: FloorGen._kit_mat() now falls back to
      plain grey if a shader or atlas fails to load, instead of handing back a ShaderMaterial with
      a null shader - which is what Godot draws magenta. A shader can load on one machine and fail
      on another, so that fault would only ever have appeared on stream.
      NOTE THE LOOSE END, honestly: the laptop proved the binding is NOT broken (384 materials, 0
      null, 0 magenta), and Mr. E has now said the confection's bright pink is wanted. So the
      original "an entire dungeon floor renders hot magenta" report is explained as the confection
      looking as intended - not as a bug that was found and fixed. If he ever sees a magenta floor
      again, it is NEW, and the guard's kit_fail_count is the thing to read.
      Supervisor note on ownership: data/biomes.json is laptop-owned and the supervisor edited it
      directly. Justified narrowly - a one-line data revert that the owning worker itself specified
      in its own PROGRESS entry, made at Mr. E's explicit direction while he was present. Not a
      precedent for editing another worker's code.

CHANGELOG 2026-11-13 12:37 (supervisor): L41 closed on Mr. E's ruling; confection ground reverted; the guard kept.

# Phase X - Mr. E looked at the Chronicle and gave three new items (2026-11-13 14:12)

- [x] L39 / L39b CLOSED BY MR. E'S EYE. He ran the game, looked at the centre Chronicle at 714x295
      / 18 px, and said: "the chronicle is the correct size." SIZE AND LEGIBILITY ARE SETTLED - the
      item he corrected three times is done. The styling complaint below is a SEPARATE, new item,
      not a reason to leave L39 open.

- [x] L61. THE CHRONICLE MUST BE A SCROLL, not a box. Owner: DESKTOP HUD (hud_dock.gd).
  RESULT (2026-11-15, hud-ui bdd7f59, U-cycle 25): the scroll was built over U23/U24; U25 closed the
  remainder Mr. E named - Chronicle ink 18 -> 21 px (feed_hud.CHRON_PX), the wordmark set in Gloock
  (gilt cream with a dark drop shadow, 17 px - the burned-brown first pass vanished on the dark
  spindle), sheet inset 9 -> 15 px so 21 px ink clears the illuminated margin rule. Capacity is 7
  lines at 21 px in the 714x295 box. Parse 0 errors; windowed 1920x1080 capture in
  renders/cycles/20261115_u25 was LOOKED at - wordmark legible, 7 lines readable, no spindle or
  margin overlap. The ornate/illuminated craft continues under the HUD worker's later items if
  Mr. E asks for more; the item as written is met.
      U-cycle gave it a parchment panel and Mr. E approved the direction but wants it taken all the
      way: make the Chronicle READ AS AN UNFURLED SCROLL, something unique, the signature piece of
      the stream. Build it in hud_dock.gd (skin only; keep the current size, the ~18 px text and the
      8-9 line capacity; L40 discipline - stay clear of the panes).
      THE SCROLL (build to this, use judgement on craft):
        - Aged parchment field: warm cream->tan, a faint vertical fibre/vellum gradient, edges a
          touch darker (age/handling). Not flat gold.
        - A ROLLED SPINDLE top and bottom (horizontal scroll): a wooden/bone dowel with dark end-caps
          and a soft curl-shadow where the sheet rolls under it, so the sheet looks furled, not cut.
          Vertical scroll (spindles left/right) is fine too if it reads better at pane-safe width -
          pick one and show it.
        - A little weight/sag or deckled (torn) edge on the open sheet so it is not a clean rectangle.
        - "Chronicle" as a burned/embossed label on the top spindle OR a small wax-seal tab (keep the
          existing teal accent to tie to the hub brand; Gloock for the word).
        - Ink: an aged serif, dark brown-black, not pure white. Newest line still gets the current
          emphasis so the eye catches new entries.
      ART TARGET - "AN ELDER SCROLL, OUR OWN DESIGN" (Mr. E, raised after the first scroll pass):
        aim for the ancient, ORNATE, illuminated-prophecy feel - a scroll that looks old and important,
        not just a parchment rectangle. This is the general aged-vellum archetype rendered in OUR brand;
        do NOT copy The Elder Scrolls / Bethesda art, fonts, logo, the blank-scroll motif or any of
        their UI - original filigree only.
        Layer onto the furled-parchment base:
          - METAL SCROLL CAPS / FINIALS on the spindle ends - small ornamented end-caps (aged brass or
            dark iron with a teal patina to tie the brand), a hint of relief, not flat dowels.
          - An ILLUMINATED BORDER just inside the sheet - a thin restrained filigree/vine rule in the
            teal+gold, corners a touch more worked, like an illuminated manuscript margin. Keep it a
            FRAME, never over the text; readability wins every time.
          - A DROP-CAP / illuminated initial or a small heraldic mark by "Chronicle" (the Jester motif
            if it reads at size) so the header feels inscribed, not labelled.
          - Optional faint age: a soft foxing/stain or a whisper of arcane glow on the newest line -
            subtle, must not cost readability or frame rate.
        Still ONE cheap procedural layer (gradients + shadow/relief rects + a thin vector border);
        if filigree needs an image it must be CC0, self-hosted, with a LICENSE note. Original, ours.
      Keep it ONE draw layer, cheap - a real-time HUD element, not a texture import; procedural
      panel + gradients + a couple of shadow rects is the intent. CC0 only if any texture is used.
      DONE: a windowed 1080p crop of the scroll that Mr. E signs off. Look at it before you call it
      done - if it still reads as a box, it is not done.

- [x] L62. THE PANES NEED TITLES, not only "Now watching: <who>". Owner: DESKTOP HUD. Right now a
      pane says who it follows but not WHAT KIND of pane it is. Each should carry its lane identity
      - DIRECTOR / SUBSCRIBER / BITS / CHANNEL POINTS / (ambient) - as a title, with "Now watching:
      <who>" beneath or beside it. The lane colour already exists (L57); this makes the category
      legible in words too, so a viewer knows why a pane is showing what it shows. Stay in the
      seven HUD files.
      DONE (U-cycle, verified+merged c9f9fb1): all four panes carry a colour-coded lane title
      (DIRECTOR/BITS/SUBSCRIBER/CHANNEL POINTS) + now-watching; Mr. E approved on the 1080p crop.

- [x] D45. THE GRASS READS AS SAND - REPLACE THE TEXTURE. Owner: DESKTOP BUILD (valley.gd / town
      ground material). Mr. E: "the grass needs work still looks like sand so we should at this
      point use a different texture for it." Source a proper grass texture - CC0 only (Kenney,
      ambientCG, Poly Haven CC0), self-hosted with a LICENSE note, never Quaternius Bestiary/QAL.
      Tile it so it does not obviously repeat at the pane's zoom, and check it against the dusk and
      night lighting, not just noon. The town ground, the valley and the pane backdrops all read it.
      DONE: a 1080p crop at the stream's zoom where the ground reads as grass, Mr. E signs off.
      SHIPPED (desktop D-cycle D5, Nov 13 18:xx) - NOT TICKED, awaits Mr. E's eye. The grass was
      a flat olive/tan wash at pane + aerial distance (the 'sand'). Fix was the MATERIAL grade in
      assets/shaders/ground.gdshader (grass branch), not a new texture: a coarse 2nd grass sample
      for distance detail + GREEN-dominant macro/patch mottling replacing the warm (1.10,1.06,0.92)
      macro that desaturated the fields to tan. 1080p before/after rendered and LOOKED AT (close /
      valley bank / aerial pane) - all read as varied green grass. Gate green. Crops in
      renders/cycles/d45/. Mr. E to sign off, then tick.

CHANGELOG 2026-11-13 14:12 (supervisor): L39/L39b CLOSED on Mr. E's eye - the Chronicle size is right. Three new
items from his look: L61 (Chronicle styling, HUD), L62 (pane lane titles, HUD), D45 (grass texture,
desktop). None are launched yet - he is moving to the broadcaster token next and will come back to
these.

# Phase Y - the party band leaves the stream for the hub (Mr. E, 2026-11-13 14:15)

Mr. E, looking at a live pane: "the towns band covers up most of the screen in one screen so im
assuming it would on the others, lets take that out and add it to the HUB. and we can add a
section on the HUB for parties or bands that are currently in the dungeon." The band panel
("The town's band - floor 5" with members + HP bars) eats most of a 2x2 pane. It comes off stream
and moves to the hub, which has the room.

- [x] D46. TAKE THE PARTY-BAND PANEL OFF THE STREAM, AND PUT THE BAND IN THE SNAPSHOT. Owner:
      DESKTOP BUILD (party_frames.gd + the snapshot upsert). TWO linked halves, do both:
        (a) Stop drawing the on-stream party-band panel - it covers most of a pane and would on
            every pane. The in-game unit frame / selection (rts_camera.gd) stays; it is the big
            multi-member BAND board that goes.
        (b) THE HUB CAN ONLY SHOW WHAT THE SNAPSHOT CARRIES. Add the delving parties to the snapshot
            the game upserts every 60 s: for each party/band currently below - its name, its floor,
            and each member {name, hp, max_hp, status (ok/fallen/burning/...)}. Read-only, same
            publishable-key path as the rest of the snapshot; no new write path. Keep the payload
            version gate - if you add a field, bump the version the hub checks.
      DONE: no band board on stream (1080p crop), and the snapshot row contains a parties array the
      hub can read. This SUPERSEDES the party-frames half of D41/L40 - that overlap is moot once the
      board is gone; D41 shrinks to just the Twitch chat column (the L36 overlap), still desktop-owned.

- [x] H10. "BANDS BELOW" SECTION ON THE HUB. Owner: HUB BUILDER (web/ only). A section that lists
      every party currently in the dungeon from the snapshot's new parties array: band name, floor,
      and each member with an HP bar and status, fallen and burning shown honestly. The hub has room
      the stream does not, so show ALL active parties, not just one. Every string is attacker-shaped
      Twitch input (hero names) - it reaches the DOM ONLY via el()/textContent, HP bar widths are
      page-computed numbers not snapshot strings, status picks an icon from the ICON_SET whitelist.
      No new fetch, no write path; same read-only snapshot. Keep the house palette (parchment/teal/
      gold, Gloock titles).
      GATED ON D46: until the snapshot carries parties, build against the shape and show an honest
      empty state ("no bands delving right now") - never a fabricated party. Flag to the supervisor
      the exact field shape you expect so D46 writes the same one.

CHANGELOG 2026-11-13 14:15 (supervisor): added D46 (party band off stream + into the snapshot) and H10 (Bands
Below section on the hub, gated on D46's snapshot field). D41/L40's party-frames half is superseded
- only the chat-column overlap remains there. Agreed field shape for the parties array to be
pinned when D46 and H10 start, so the two sides match.
      TICKED (supervisor, Nov 14): shipped on hub (1ccec4c) - Bands Below renders delving parties on the hub, gated on the D46 snapshot v2.

# Phase Z - strip the stream to Mr. E's six (supervisor, 2026-11-13 14:20). See COORDINATION 13.

Mr. E's answers to the three edge cases: unit frame -> STRIP (to hub); boss bar -> KEEP on stream;
in-world health bars / damage numbers / VFX -> KEEP (they are the content).

- [ ] D48. STRIP THE UNIT / SELECTION FRAME OFF STREAM. Owner: DESKTOP BUILD (rts_camera.gd). The
      bottom-centre stats panel that appears when a hero is selected comes off the stream canvas.
      SELECTION ITSELF STAYS as the director mechanic (it still decides which pane follows whom) -
      only the drawn stats panel goes. KEEP boss_bar.gd. KEEP the in-world health bars / damage
      numbers / VFX - those are not this panel. The hub already shows hero sheets, so the selected
      unit's detail is already reachable there; if any field is not in the snapshot, add it the
      D46 way (read-only, version-gated).
      DONE: no unit-stats panel on a 1080p stream crop; selection still drives the panes; boss bar
      and in-world elements untouched.

- [x] L63. STRIP THE SATCHEL OFF STREAM. (done U-cycle, merged c9f9fb1) Owner: DESKTOP HUD (leaderboard_panel.gd). The L51 Satchel
      (a viewer's gear / inventory / selling sheet) comes off the stream - it is a personal sheet
      and belongs on the hub. After L58 (Guild Roll removed) and this, leaderboard_panel.gd draws
      NOTHING on stream: retire the CanvasLayer or leave it dormant. The Satchel's content is not
      lost - it moves to the hub (H11). The HUD worker's entire on-stream surface is now exactly
      the six in COORDINATION 13: panes, Chronicle, lane titles (L62), now-watching (L57).
      ALSO CONFIRM feed_hud.gd: if it draws a SECOND on-stream event feed separate from the
      Chronicle, that is a seventh panel and must go - the Chronicle is the only event feed on
      stream. If feed_hud IS the Chronicle's renderer, leave it. Say which in PROGRESS.
      DONE: a 1080p stream crop showing ONLY the six; Satchel gone; feed_hud question answered.

- [x] H11. THE HUB ABSORBS WHAT LEFT THE STREAM. Owner: HUB BUILDER (web/ only). The hub already
      carries hero sheets, inventory, gear, the fallen and the command list - so most of this
      exists. Fill the gaps so nothing that left the stream is lost: (a) SELLING PRICES on the
      viewer's sheet (the Satchel showed the counter's sell prices); (b) make a viewer's OWN hero
      easy to find/pin, since the on-stream Satchel that used to show it is gone. Plus H10's Bands
      Below. All read-only from the snapshot, el()/textContent only, ICON_SET for status, house
      palette. No new fetch or write path.
      DONE: a viewer can see on the hub everything the stream used to overlay - their sheet with
      sell prices, their inventory, the bands below - and nothing on the hub is fabricated.

CHANGELOG 2026-11-13 14:20 (supervisor): COORDINATION 13 added - the binding stream-HUD philosophy (six allowed
elements, everything else hub-only), from Mr. E's rule + his three edge-case answers (unit frame
strip, boss bar keep, in-world keep). Items: D48 (strip unit frame, desktop), L63 (strip Satchel +
answer the feed_hud question, HUD), H11 (hub absorbs selling + own-hero find). L51's on-stream
Satchel is intentionally removed - a direction change, its work feeds the hub, not wasted.
      TICKED (supervisor, Nov 14): shipped on hub (6424763) - the Satchel (sellable items +
      counter sell prices) and pin-your-hero, CSP unchanged, hostile-name test passes. Mr. E
      approved: "Yes - dormant until game publishes v=3, no downside." Code awaits game-build L63/D48
      to publish snapshot v=3; hub republish still Mr. E's call.
- [x] H12. LORE SECTION ON THE HUB (Mr. E's ask, Nov 14). Owner: HUB BUILDER (web/ only). The hub
      should carry the world's lore so a new viewer can get oriented without leaning on chat. Pull from
      data/lore_lines.json (READ from main; it is content-writer-owned, do not edit) and present the
      sections that read as world lore - town_life, growth_tiers.tiers (as the town's own history),
      e3po intro/says/town_talk (the Commander), the lord intro lines, disasters/events as "tales".
      ALL strings reach the DOM ONLY via el()/textContent - every lore_lines value is still Twitch-era
      text and may embed hostile markup. No new fetch; load from the same snapshot pipeline or bundle
      a frozen copy with a visible last-updated. Icons from ICON_SET; no new URL/src/style. House
      palette (parchment/charcoal/teal, Gloock for section titles only).
      DONE: a viewer can read town/kingdom lore on the hub, hostile-name test still passes, invariants
      intact, CSP unchanged.      TICKED (supervisor, Nov 15): shipped hub b470489, PUBLISHED LIVE gh-pages c926030. Mr. E reviewed the live page and signed off.

- [x] H13. NO-SCROLL LAYOUT - the hub is one long page (Mr. E's ask, Nov 14). Owner: HUB BUILDER
      (web/ only). Reorganise the existing sections (Boards, Chronicle, Hero Sheets, Bands Below,
      Satchel, chat, lore from H12) so a viewer does not have to scroll one page end to end. Tabbed or
      sidebar-nav layout, remembers the last section the viewer picked (localStorage, control-stripped,
      25-cap, never used as URL/selector), keyboard-navigable, respects reduced-motion. NO new data,
      NO new fetch, NO CSP change - purely a layout rework. Keep the house palette and the title-card
      feel; a section rename is fine, a section REMOVAL is not without supervisor sign-off.
      DONE: no section is more than one viewport tall at 1080p; a viewer can reach every section in
      one click; hostile-name test passes across every tab; mobile/phone layout still works; invariants
      + CSP + hostile-name test all intact.
      TICKED (supervisor, Nov 15): shipped hub 5c100ca + fix 8e248a5, PUBLISHED LIVE gh-pages c926030. Mr. E confirmed the tabs (Boards/Heroes/Bands/Chronicle) on the live page.

# Phase AA - Mr. E's narrated clip 14-26-15 (transcribed) (2026-11-13 14:50)

His words: "it looks very pixelated... it's only when they're moving, when characters are moving
around, it looks like jack shit. Top left is fine, top right, bottom right, bottom left, it all
looks like shit. And the grass looks freaking terrible, and I mean terrible, really bad."

- [ ] D49. MOVING CHARACTERS PIXELATE / SHIMMER IN THE CLOSE PANES - SAME ROOT AS THE GRAIN (D24).
      Owner: DESKTOP BUILD leads (project.godot [rendering]) WITH the HUD worker for the pane
      viewports (spotlight.gd). The tell Mr. E gave is diagnostic: the TOP-LEFT director/wide pane
      is FINE; the three CLOSE subject panes shimmer on movement. That is classic no-anti-aliasing
      on sub-resolution viewports - each 2x2 pane renders at ~960x540 and upscales, so a moving,
      animated character crawls with aliasing while a wide static shot hides it. project.godot's
      [rendering] section is EMPTY (no MSAA/TAA/FXAA) - that is also the root of D24's grain.
      THE FIX LIKELY SOLVES BOTH: add temporal AA (TAA) or MSAA. TAA specifically kills both the
      moving-edge shimmer AND the SSAO/fog temporal-dither grain from D24. BUT verify in the live
      2x2: (a) TAA needs the warm-up the laptop already added for L43's FPS test - a cold first
      frame can ghost; (b) check it does not reintroduce grain or smear; (c) check the FPS cost
      with the grid up and the publisher on (COORDINATION 8.5 budget). If TAA is too costly in four
      live viewports, fall back to MSAA 2x/4x on the pane viewports plus FXAA. Also consider raising
      the pane viewport render scale - sub-res is half the problem.
      DONE: a 1080p capture of a MOVING character in a close pane that reads clean, grain gone,
      FPS still in budget, and Mr. E signs off.
      This supersedes D24 as the active rendering item - same cause, sharper repro. Keep D24's grain
      acceptance in the DONE check.

- [ ] D45 (reinforced). THE GRASS IS "REALLY BAD" IN EVERY PANE, not just some. Still owner DESKTOP
      BUILD (valley.gd / ground material). His emphasis - "freaking terrible, really bad" across all
      four panes - means a plain texture swap may not be enough: check the grass MATERIAL (tiling
      scale, normal map, roughness) under the pane camera distance, not just the albedo. A good CC0
      grass with a proper normal + correct tiling, judged at the pane's zoom. CC0 only, LICENSE note.

CHANGELOG 2026-11-13 14:50 (supervisor): from Mr. E's transcribed clip 14-26-15 - D49 (moving-character
pixelation in the close panes, same no-AA root as D24's grain; TAA/MSAA likely fixes both; desktop
leads with the HUD worker for the pane viewports) and D45 reinforced (grass bad in every pane,
check the material not just the texture). More clips to come as Mr. E transcribes them.

# Phase AB - Mr. E's narrated clip 14-27-07 (transcribed) (2026-11-13 14:51)

His words: "this guy is stuttering... this dude's animation's terrible... look at the grass, that
texture, it's so nasty... this dude has not moved from his spot in the top right, a lot of them
aren't moving... this dude's not even holding the fishing pole correctly... this grass texture,
so nasty."

- [x] D52. *** TOP PRIORITY, ABOVE EVERYTHING ELSE. *** HEROES DO NOT MOVE ON COMMAND. A viewer  [CLOSED nov13: pre-raise race fixed c9daa0f; happy-path 'failure' was a frame-vs-wallclock test artifact, laptop made it wall-clock deterministic b59fdc4; D52_TEST OK 6/0 on both machines]
      enlists a hero, sends it to delve, and it stands frozen - the whole core loop (enlist -> party
      -> delve) is dead on screen. Mr. E created a hero, issued delve, set a pane to follow it, and
      it never moved. The follow-CAMERA works (the pane tracks it); the HERO's movement does not.
      THE UNIFYING HYPOTHESIS - treat D44, D50 and D52 as ONE freeze bug until proven otherwise:
      everything Mr. E sees frozen - townsfolk standing still (D50), NPCs not wandering, heroes not
      delving (D52) - is an agent that cannot path. The _townwalk in_solid count that rose from a
      clean 0 to peak 8 (D44/D44b) is very likely the MEASUREMENT of this same freeze: an agent
      wedged in carved solid geometry stops translating AND stops delving. D44b's spawn-snap fixed
      the RISING half; the residual is agents getting stuck at RUN TIME (doorways, props, nav-mesh
      seams), and that residual is what freezes heroes mid-town.
      THIS SPANS TWO OWNERS - coordinate, do not let it fall between them:
        * DESKTOP BUILD (town_nav.gd, townsfolk.gd, hero movement in town): is the hero's nav agent
          getting a path to the dungeon mouth at all? Is it wedged in_solid at spawn/standing? Does
          it have a velocity but zero translation (stuck against a collider)?
        * LAPTOP CODE (delve.gd, roster.gd, chatcmd.gd): does the !delve / go-delve command actually
          ISSUE a move order and a destination, or does it set state without moving the body? The
          census showed delving logic runs in tests - so why does a LIVE hero not move? Find the
          live-vs-test difference.
      REPRO FIRST, as every good find this session has: capture ONE hero from enlist to frozen, log
      its nav state (has_target, path length, in_solid, velocity, position-delta per second). Do not
      guess the mechanism. This is the same discipline that cracked L46/L49/L50/L52/L55.
      DONE: a live run where an enlisted hero commanded to delve WALKS to the mouth and descends,
      townsfolk wander, in_solid holds 0, and Mr. E confirms on stream that heroes move.

CHANGELOG 2026-11-13 14:52 (supervisor): D52 raised CRITICAL and placed above all desktop and laptop work -
heroes do not move on command, which kills the core loop. Unified with D44/D44b/D50 as one likely
freeze bug (agents cannot path; in_solid is its measurement). Spans desktop (nav/movement) and
laptop (the delve command path) - both must coordinate; repro before fixing.

# Phase AD - Mr. E's clips 14-29-22 / 14-30-21 / 14-31-18 transcribed (2026-11-13 14:54). Important disambiguation.

- [ ] D52 (REFRAMED - the supervisor unified too fast; the new clips split it in two). THE HERO
      THAT WON'T DELVE IS A COMMAND/STATE BUG, NOT WEDGING. Clip 14-30-21: "Mr. is already waiting
      at the dungeon mouth. No, he's not. He's standing by the WELL in the town square." The hero
      stands in an OPEN area (the well), not jammed against anything, and never paths to the mouth
      after a delve order - he even re-typed Delve and it still did nothing. So the go-delve command
      sets state WITHOUT issuing a move/destination, or the hero's state machine never transitions
      to "travel to mouth". OWNER: LAPTOP CODE (delve.gd / roster.gd / chatcmd.gd - the delve
      trigger and the hero's travel-to-dungeon state). Repro one hero from the delve command and log
      whether a nav target to the mouth is ever set. THIS IS STILL TOP PRIORITY - it kills the core
      loop. It is NOT the same as the wedging below; do not fix it as a nav problem.

- [ ] D44/D50 (CLARIFIED - the WEDGING half, distinct from D52). Clip 14-31-18: "this guy is stuck,
      he's stuck against his pumpkins." SOME agents physically wedge against props (pumpkins) and
      freeze. THAT is the in_solid / nav-collision bug, DESKTOP-owned (town_nav.gd), the thing the
      rising in_solid count measures. Keep D44b's work on this. The hero-at-the-well (D52) is a
      different animal - a wedged agent is pinned to a prop, an idle hero sits in the open. Two
      bugs, two owners, do not conflate.
      PARTIAL D44c (game build, 2026-11-15 ~15:45 CT, townsfolk.gd): the recurring STUCK_EX hotspot at
      (74,-63.5) - in every recent townwalk (d60, d63, d64) - NAMED AND FIXED. It was a RAID-FLIGHT knot, not a
      prop: ~9 folk fleeing to one homeless refuge whose route ends on the navmesh ~2 m off the door. With the
      0.9 m arrival they stopped 2.5-3 m from the door, failed the 2.5 m duck-in test, were re-routed to the
      same end and arrived again, every frame, for the whole raid. Now a fleer whose route has run out within
      2.5 m of its own route END tucks in (flee_end_tucks); plus a final open-ground leg that gets no nearer
      within 2.5 m of a taken spot counts as arrived (crowd_arrivals). tools/_d44c_probe.gd: still-on-route
      samples at the hotspot 43 -> 0. Three townwalks after: STUCK_ON_ROUTE_TOTAL 0 / 2 / 0 (hotspot gone from
      all three), in_solid 0/21402, 2/18031, 2/15629. STILL OPEN: those in_solid 2s are the OLD flat D44b
      residual - bodies on long routes (100+ waypoints) embedded in the south-market solid at (32.5,-64)/
      (32.5,-69.4). Not the pumpkins either: no pumpkin prop exists in code (fields use Plant_1 greens), so
      the clip's prop needs Mr. E to point at it again if it recurs.

CHANGELOG 2026-11-14 05:45 (supervisor): shipped to main this session - bit-cheer tiers (7cdc363), Rally my hero reward + combat buff (eb707ae), hero idle-wander + delve-scope fix (19b1893/e1c9c1f), subscriber-pane Helix seed (19b1893), Custom Power-up redemption -> bit tiers (510a2e9), E3PO D37 live + all voice hooks (4e59901 + laptop L-148 + trader_arrives a2dbd3a), laptop merge c08cc08 (trap variety L-147, monster telegraphs L-149). Full gate green. OPEN for Mr. E: create the 5 Custom Power-ups in the dashboard; decide E3PO v2 (fighting commander).


# Phase AE - THE HUD WORKER GETS REAL WORK (supervisor, 2026-11-15 12:05 CT). IDs frozen as ever.
# Written against the "HOW BIG AN ITEM SHOULD BE" bar. These four are the HUD worker's queue and they
# live ENTIRELY inside its seven files: hud_dock.gd, spotlight.gd, auto_director.gd, dice.gd,
# feed_hud.gd, leaderboard_panel.gd, ui_theme.gd. If a stage needs state another file holds, the HUD
# worker says so in its summary and the supervisor raises it with that file's owner - it does not reach in.
# ORDER MATTERS: L65 first (one designed interface), because L64/L66/L67 all draw through the theme.

- [x] L65. ONE DESIGNED INTERFACE, NOT SIX PANELS THAT GREW SEPARATELY. Owner: DESKTOP HUD
      (ui_theme.gd, then hud_dock.gd, feed_hud.gd, leaderboard_panel.gd, spotlight.gd). The stream's
      panels were each built in a different week and it shows: different corner radii, different
      border weights, different type sizes for the same job, parchment at three different values.
      Mr. E's bar is RTS/WoW - a single interface a viewer reads without thinking. Staged:
      L65.1 TOKENS. Make ui_theme.gd a real design system, not a colour bag: a type scale with named
            roles (wordmark / section title / body / caption / numeral), a spacing step, named ink,
            parchment, teal and gold values with their on-dark and on-parchment pairs, border and
            corner constants, and one elevation/shadow treatment. Every value named once.
      L65.2 CHROME. One panel frame drawn from those tokens - edge, corner, header, divider, empty
            state - that every HUD panel uses instead of its own.
      L65.3 ADOPTION. Convert hud_dock.gd, feed_hud.gd, leaderboard_panel.gd and spotlight.gd's
            overlays to the tokens and the frame. No hard-coded colour, size or radius left in those
            files - grep proves it.
      L65.4 LEGIBILITY FLOOR. Every string on stream at 1080p meets a stated minimum size and a
            stated contrast ratio against what is actually behind it (the live 3D, not a flat swatch).
            State the numbers. Mr. E's 21 px Chronicle body and the Gloock wordmark (L61) are the
            reference, not something to re-litigate.
      DONE: one 1080p capture with the Chronicle, the feed, the leaderboard and a spotlight pane all
      live at once, before and after, side by side - the after reads as one interface; a grep of the
      four adopting files shows zero literal colour/size/radius constants; the stated contrast and
      size floors are listed per element with their measured numbers.

  RESULT (2026-11-15, hud-ui ffb9c77, cycles U27+U28): .1-.3 landed in U27 - ui_theme.gd is a real token
  system (named type scale, one panel frame, shared chrome) and hud_dock, feed_hud, leaderboard_panel and
  spotlight all draw from it. .4 landed in U28: tools/_l654_audit.gd measures every on-stream string and
  all 15 now clear 4.5:1 at 1080p, via a chip_bg token and a softer scroll edge (renders/cycles/
  20261115_l654/audit.txt). Next for this worker: L64.

- [x] L64. THE DIRECTOR MUST TELL A STORY, NOT CYCLE THROUGH CAMERAS.
      SUPERVISOR NOTE (2026-11-15 14:05): there are 12 UNCOMMITTED lines of L64.4 in
      scripts/spotlight.gd in your worktree (a `handoff_swaps` counter + an _amb_tick handoff so an
      idle pane yields the body the director just cut to, meaning one body is never on screen
      twice). Your 13:53 run wrote them, ran a headless parse check (errors=0) and stopped without
      committing. Nothing was lost and nothing of yours is in main unpushed. Pick it up
      deliberately: either finish L64.4 - WINDOWED verify that no body appears in two panes at
      once, LOOK at the capture, then commit - or revert it and say why. Do not leave it dirty a
      third run. Owner: DESKTOP HUD
      (auto_director.gd, spotlight.gd). The stream runs 24/7 and the director currently rotates;
      rotation is not direction. A DM cuts to what matters. Staged:
      L64.1 INTEREST SCORING. Score every candidate subject each beat on what a viewer would care
            about - a raid in progress, a boss rising, a hero dying, a viewer-named hero acting, a
            trade caravan arriving, a festival, a disaster - against a quiet baseline of town life.
            The scores must be readable in a log, so a bad cut can be explained afterwards.
      L64.2 SHOT LANGUAGE. A small vocabulary of named shots with their own hold times and framing
            (establishing wide, follow, over-the-shoulder on a fight, slow push on a quiet beat,
            hard cut on a death) rather than one camera move reused everywhere.
      L64.3 PACING AND MEMORY. Minimum and maximum holds per shot type, no cut inside a beat that
            has not resolved, and an anti-repetition memory so the same subject and the same shot do
            not come back inside a stated window. Quiet stretches get longer, calmer holds; a raid
            cuts faster.
      L64.4 HANDOFF. The spotlight panes and the director agree: what the director is on is never
            also what a pane is showing, and the Chronicle is never covered (L40/L61 discipline holds).
      DONE: a 30-minute unattended recording with at least one raid, one death and one quiet stretch
      in it, plus the director's own decision log for the same window - every cut in the recording is
      justifiable from the log, no subject repeats inside the stated window, no shot runs past its
      stated maximum, and no pane shows what the main camera is on.
  PROGRESS (2026-11-15 12:03 CT, hud-ui 1973b23, U29): .1 every candidate scored with a reason note and each cut logged
  (CUT key shot pri why + top-5 candidates); .2 named shots with their own hold windows (establishing 12-30, push 10-24,
  follow 8-18, shoulder 6-16, hero); .3 pace factor 0.6 in a raid / 1.4 in a quiet stretch and no cut inside an open
  beat until its maximum. tools/_l64_test.gd WINDOWED 1080p, 300 s clock at 4x: 41 cuts, 0 repeat/hold/why violations.
  STILL OPEN: .4 lane_held/_lane_owns was not re-verified against pane contents, and the 30-minute unattended recording
  the DONE line asks for has not been made - the worker also could not look at its own screenshots (folder grant). This
  item stays the HUD worker's first unchecked item.

  PROGRESS (2026-11-15 15:14 CT, hud-ui 227f35b, U30): .4 HANDOFF IS DONE AND VERIFIED. spotlight.gd
  `_amb_tick`: an idle pane (ambient, or resting on a redeemer) showing the body the director just cut to
  yields at once to an ordinary ambient pick, counted in `handoff_swaps`; a PAID moment still holds its
  hero and the director yields to it instead. tools/_l644_handoff.gd, WINDOWED 1080p via --script (with -s
  the Town spawns its own eye and live Twitch and the test measures the wrong camera): 90 s director clock
  at 4x, 4 delving viewer heroes, every frame comparing each pane's subject to the director's - 5,000+
  frames, ZERO with a body in two panes, swaps 1-2, and a FORCED collision resolved. LOOKED:
  renders/cycles/20261115_l644/panes_1080.png - Chronicle scroll centred and uncovered. The 12 lines that
  sat uncommitted for two runs are now committed; nothing is dirty.
  ALL FOUR STAGES (.1 .2 .3 .4) ARE NOW BUILT. THE ONLY THING LEFT IN L64 IS ITS DONE TEST: the 30-minute
  unattended recording with at least one raid, one death and one quiet stretch, plus the director's own
  decision log for the same window. HUD worker: that recording IS the item now - do not rebuild the stages.
  RESULT (ticked 2026-11-16 by the supervisor): U31 ran the DONE test - tools/_l64_long.gd, windowed 1080p,
  1800 s of director clock with two raids, a death and a quiet stretch. Run 1 exposed a real fault (the quiet
  tour re-cut the same stop within 1-20 s); auto_director.gd `_tour_pick`/`_tour_seen` made the tour a lap.
  Run 2: 183 cuts (follow 59, shoulder 75, push 41, hard_cut 2, establishing 6), 0 repeats, 0 holds past max,
  every cut carries a why, 138,053 frames with 0 body-in-two-panes. LOOKED: l64_raid.png, l64_death.png.

- [x] L66. THE LEADERBOARD IS A SEASON, NOT A TOP FIVE. Owner: DESKTOP HUD (leaderboard_panel.gd).
      CLOSED 2026-11-15 23:10 CT by the supervisor - DELIVERED ELSEWHERE, NOT ABANDONED. COORDINATION 13
      says the stream keeps no leaderboard; this item asked the HUD to build one in-game, so it contradicted
      a standing ruling and the HUD lane was right to stand down rather than build it. All three stages -
      movement, moments, more than one board - shipped on the hub as H31 (four rotating boards, change
      marks, the town's own words from lore_lines.json). Nothing is owed here. Do not reopen it for the
      in-game panel without Mr. E reversing COORDINATION 13.
      A static top five stops being interesting twenty minutes into a stream and never changes again
      for a viewer who just arrived. Make the board tell the story of the run. Staged:
      L66.1 MOVEMENT. Remember each hero's placing over the session and show the change - who is
            climbing, who is falling, who has just entered the board - as a quiet mark beside the
            row, not a flashing badge.
      L66.2 MOMENTS. When the top place changes hands, when a hero enters the board for the first
            time, or when a hero on the board falls, the panel marks it for a few seconds in the
            town's own voice. The words exist in data/lore_lines.json - read them, do not write a
            parallel set (the HUD worker reads data/ freely; it does not edit it).
      L66.3 MORE THAN ONE BOARD. Rotate between a small set of boards - depth reached, gold earned,
            monsters felled, longest survivor - on a stated cadence, each clearly titled so a viewer
            who arrives mid-rotation knows what they are looking at.
      L66.4 HONEST EMPTY AND HONEST SMALL. A fresh session with two heroes must look deliberate,
            not broken: no blank rows, no "undefined", no placeholder names.
      DONE: a recording of at least 20 minutes of a live session showing a lead change marked, a
      hero entering the board, at least two full board rotations with their titles, and the same
      panel at session start with only two heroes in it looking finished rather than empty.

- [x] L67. THE FEED MUST SURVIVE A RAID. Owner: DESKTOP HUD (feed_hud.gd). When everything happens
      at once - a raid, a delve, chat, redemptions - the feed becomes a scroll of noise that nobody
      can read, which is exactly the moment a viewer most wants to know what is going on. Staged:
      L67.1 PRIORITY. Classify what the feed carries and let the important survive the flood: a
            death, a boss, a viewer's own action and a town-level event outrank a routine pickup.
      L67.2 MERGING. Repeats collapse instead of stacking ("3 goblins felled" rather than three
            lines), with a stated window for what counts as a repeat.
      L67.3 RATE AND DECAY. A stated maximum lines-per-second into the feed and a stated dwell per
            line, so the feed never outruns reading speed; overflow is dropped by priority, lowest
            first, and the drop is visible in a log so nothing silently vanishes unexamined.
      L67.4 READABILITY UNDER LOAD. Through the L65 tokens, at 1080p, over the live 3D - still
            legible with the feed at its maximum rate.
      DONE: a 1080p capture during a forced raid with the feed saturated, alongside the feed's own
      log for the same window - every line on screen is readable at normal viewing distance, repeats
      are merged, nothing above the stated priority was dropped, and the measured line rate is at or
      under the stated maximum.

  RESULT (ticked 2026-11-16 by the supervisor): U32 - feed_hud.gd classes every line on arrival (P3 death/
  boss/lord/raid, P2 town-level or named-hero, below that routine), merges repeats, and enforces a stated rate
  and dwell with priority-ordered drops written to a log. tools/_l67_test.gd windowed 1080p under a forced raid
  at ~12 lines/s for 30 s: 376 seen, 210 merged, 33 admitted, 133 dropped and all of them P0/P1 overflow.
  LOOKED: renders/cycles/20261115_l67/l67_flood.png + feed_log.txt - 21 px lines legible over the live panes.

# Phase AF - THE HUB'S QUEUE GOES THIN (supervisor, 2026-11-15 13:10 CT). IDs frozen as ever.
# H18 shipped this cycle and only H19 (the Bestiary) was left. These three are written to the
# "HOW BIG AN ITEM SHOULD BE" bar and live ENTIRELY in web/index.html, web/app.js, web/style.css,
# web/NOTES.md and docs/HUB_SECURITY.md. Order: finish H19 first, then H20, H21, H22.
# EVERY ONE of them is bound by the security invariants in docs/HUB_SECURITY.md - el()/textContent
# for every snapshot and viewer string, no snapshot value as URL/src/href/style, icons only from the
# page-owned ICON_SET, CSP byte-identical, no framework, no CDN, no new font. A nicer hub that breaks
# one of those is a failed item. Republishing to gh-pages stays Mr. E's call alone.

- [x] H20. THE HERO SHEET IS A CHARACTER SHEET, NOT A STAT LINE. Owner: HUB BUILDER (web/index.html,
      web/app.js, web/style.css, web/NOTES.md). The hub's hero card tells a viewer a name, a level and
      some numbers. A D&D campaign gives a player a SHEET - something they are proud to look at and can
      read their character's whole story from. Mr. E's standing mandate is "make the game more D&D";
      this is the viewer-facing half of that. Staged:
      H20.1 THE SHEET. Lay the hero out as a proper sheet in the hub's parchment-and-ink register:
            identity block (name, title, crest from H15, class/role), the ability block, the combat
            block (HP, AC, the numbers a viewer needs to read a fight), and the gear block by SLOT -
            an empty slot drawn as an empty slot, never omitted, so a viewer sees what the hero lacks.
      H20.2 CONDITIONS AND STATE. Whatever the snapshot says about a hero right now - delving, resting,
            wounded, fallen, in a band - reads at a glance from the sheet, in the town's own voice, with
            an honest "last seen N minutes ago" when the snapshot is stale.
      H20.3 THIS HERO'S OWN HISTORY. A short personal chronicle filtered from the H14 history to the
            lines that name THIS hero - their best depth, their notable kills, their deaths - so the
            sheet carries a life, not a snapshot.
      H20.4 HONEST GAPS, NAMED. Any field the sheet wants that the snapshot does not publish yet is
            drawn as a deliberate empty state and LISTED BY NAME in the run's summary and in
            web/NOTES.md. Do not invent, estimate or derive a value the publisher does not send, and do
            not reach into any game file - the supervisor raises the missing fields with snapshot_pub's
            owner (game build) as a separate item.
      DONE: screenshots of three sheets side by side - a fresh level-1 hero with almost nothing, a
      kitted veteran, and a fallen hero - each reading as a finished sheet rather than a card with
      holes; the six query-string states and the hostile-name test still pass; web/NOTES.md lists every
      snapshot field the sheet wanted and did not get.

  RESULT (2026-11-15, hub 445cfb3): heroSheet(h, mode) in app.js - identity with crest/title/calling/level,
  condition chips with an honest last-seen, HP/XP, Abilities, Combat, nine gear slots with empty ones DRAWN
  rather than omitted, Carrying/Satchel/cosmetics, Record, and "Their own chronicle" built from the H14
  remembered history by whole-word name match. Fallen memorials get the same sheet (mode="fallen"). Nothing
  is derived or guessed - a field the publisher does not send is a dashed empty cell named on the sheet's
  foot line. CSP byte-identical, no new fetch, no URL sink, hostile name renders as text (?mock=sheets).
  The fields it asked for and did not get are listed in web/NOTES.md and are now D59.

- [x] H21. THE CHRONICLE BECOMES A CAMPAIGN JOURNAL. Owner: HUB BUILDER (web/index.html, web/app.js,
      web/style.css, web/NOTES.md). H14 made the Chronicle remember; a long scroll of remembered lines
      is still only a scroll. On a 24/7 stream the common case is a viewer who was away for six hours
      and wants to know what they missed. Staged:
      H21.1 EPISODES. Group the remembered history into readable stretches - by town day, or by session
            if the day is not knowable from the data - each with a heading and a one-line sense of what
            that stretch was about, so the journal is browsable rather than infinite.
      H21.2 FILTERS. Let a viewer narrow the journal to one hero, or to a kind of event (raids,
            disasters, festivals, deaths, delves, town growth). Filter state is page-local only and must
            survive a refresh without any viewer write path to the server.
      H21.3 WHILE YOU WERE AWAY. On return, a short summary of what has happened since this browser last
            looked - the handful of lines that actually matter, not a dump. Honest and bounded when the
            gap is long or the history was trimmed; say so rather than implying completeness.
      H21.4 A MOMENT YOU CAN POINT AT. A viewer can link to a specific remembered moment and have the
            journal open on it. The link carries no snapshot string into any URL, src, href or style -
            it addresses a moment by an index or id the page owns.
      DONE: a recording of the journal in use - episodes collapsing and expanding, a hero filter and an
      event filter applied, a "while you were away" summary after a simulated six-hour gap, and a
      moment-link opened in a fresh tab landing on that moment; all six query-string states and the
      hostile-name test still pass.

  RESULT (2026-11-15, hub dafb0a2): the Chronicle tab is a journal built only from what the page already
  holds (live `chronicle` + the H14 browser history) - no new fetch, no new origin, no CSP change, no write
  path. Episodes are session stretches (90-min quiet gap or 6 h of length) with a town-voice heading, clock
  range, line count and a one-line sense; newest open, older folded, `aria-expanded` on the toggle. Hero and
  event filters (whole-word `namesIn`, page-owned keyword lists) persist page-locally and are re-validated on
  read. "While you were away" fires on a 30 min+ gap, bounded honestly (town sends 50 lines, browser keeps
  ~300 / ~2 days, "only what this browser saw"); `?away=6` simulates it. Moment links use a page-assigned
  integer id in `#moment-<n>` - no snapshot string reaches a URL. Security invariants and the hostile-name
  test still pass; innerHTML remains only at the two page-owned legacy sites; CSP byte-identical.
  HUB-SIDE GAPS NAMED (now D60): chronicle lines carry no town `day` and no structured hero/kind, so the
  journal dates by session heuristic and the hero filter name-matches the text.
  HOUSEKEEPING NOTED BY THE WORKER: the older `setUpTabs()` in app.js is dead code (the nav uses `wireTabs`).

- [x] H23. ACCEPT THE CHARACTER SHEET THE PUBLISHER IS ALREADY SENDING - v=4, AND TWO RENDER BUGS.
      Owner: HUB BUILDER (web/app.js, web/style.css, web/NOTES.md). URGENT - TAKE THIS BEFORE H22. This is
      the mirror image of D57: the game build shipped D59a on 2026-11-15 (initiative, speed, gear by real
      slot, status, per-hero `last_seen`, a per-hero `events` ring) and then had to HOLD the payload at v=3
      because this page's `KNOWN_V` refuses "4". Every one of those fields is on the wire right now and the
      sheet is drawing dashes over them. Three parts:
      .1 ACCEPT v=4. Add "4" to KNOWN_V and keep "1","2","3" - a v=3 publisher must still render exactly as
         it does today. The version gate stays a gate: an unknown version still shows the honest banner.
      .2 READ THE NEW FIELDS. The hero sheet consumes `h.last_seen` (a per-hero last-seen, so a hero who
         acted a second ago no longer reads the same as one who has not moved in an hour - the whole-snapshot
         `updated_at` was all the page had) and `h.events` (newest-first ring of that hero's own moments).
         The personal chronicle on the sheet is built from `h.events` when the publisher sends it, and falls
         back to the existing whole-word name match when it does not. Every string still reaches the DOM
         through el(); no field is ever used as a URL, src, href or style.
      .3 FIX THE TWO H20 RENDER BUGS the game build worker saw on the live sheet: gear slot text is never
         appended (the slot draws empty even when the publisher sent a name), and "[object SVGSVGElement]"
         is printed in the card head where an icon element is being string-concatenated.
      DONE: a capture of the live hero sheet for a kitted veteran and for a freshly rolled hero with the
      gear slots that exist showing their item names, no "[object" anywhere on the page, a per-hero last-seen
      that differs between two heroes, and a personal chronicle built from `events`; plus a v=3 payload still
      rendering unchanged (paste an old payload into a mock), all six query-string states and the
      hostile-name test passing, and the CSP unchanged.
  RESULT (hub, 2026-11-15 ~10:40 CT, c19608c): KNOWN_V now accepts "4" and still accepts 1/2/3 - an unknown
  version keeps its honest banner. The sheet reads `h.last_seen` (validated against CHRON_AT_OK, never used as a
  URL/style) and prints a real per-hero last-seen distinct from the whole-town updated_at; the personal chronicle
  is built from `h.events` through the same chronShape as a live line, falling back to the whole-word name match
  when the publisher sends no ring. Both H20 render bugs fixed: the gear-slot text block was built and never
  appended (one missing cell.append), and the "[object SVGSVGElement]" crest came from string-concatenating an
  icon element. Mocks now carry gear/last_seen/events including a hostile name in all three fields. el() only,
  no new fetch, no write path, CSP byte-identical. SUPERVISOR CHECK: greps clean - no new innerHTML/outerHTML/
  insertAdjacentHTML/eval/new Function; the two legacy innerHTML sites are still page-owned constants.

- [x] H24. FIND ANYTHING, FROM ANYWHERE. Owner: HUB BUILDER (web/index.html, web/app.js, web/style.css,
      web/NOTES.md). The hub now holds twelve tabs, a 200-hero roster, a Bestiary, a Hall of the Fallen and
      a journal that remembers days. A viewer who hears a name on stream has no way to reach it except by
      guessing which tab owns it. One search field, always reachable, that looks across everything the page
      already has in memory - heroes, fallen, bands, lords in the Bestiary, remembered Chronicle moments -
      and jumps to the thing itself (the hero's sheet, the lord's Bestiary entry, the moment in the journal
      via the H21.4 id). Page-local only: no new fetch, no new origin, no write path, no snapshot string in
      any URL - a result addresses its target by an index or id the page owns. Honest when the page cannot
      help: a name the browser has never seen says so rather than returning nothing. Keyboard-reachable
      (focus the field, arrow through results, Enter opens, Escape closes) and it must not steal typing from
      the guild chat input.
      DONE: a recording searching one hero name, one lord name and one word from a remembered line, each
      landing on the right place from a different starting tab; a search for something the page has never
      seen showing the honest empty state; the hostile-name test passing on every result row (a hero called
      <img src=x onerror=alert(1)> renders as text in the results list); all six query-string states pass.
  RESULT (2026-11-15 12:38 CT, hub 5df15c2): one page-local search over heroes, the fallen, bands, lords and remembered
  Chronicle moments; lands on the target (hero card, grave, band, Bestiary entry, #moment id). Reviewed: el() only, no
  new innerHTML/eval/URL sink, integer-addressed targets, no new fetch or origin, CSP byte-identical, no write path,
  and "/" never steals typing from the chat box.

- [x] H25. THE NIGHT WATCH - THE HUB IS OPEN FOR HOURS ON A SECOND SCREEN. Owner: HUB BUILDER
      (web/index.html, web/app.js, web/style.css, web/NOTES.md). The common viewer leaves this page open
      beside the stream all evening. Today it is lit and laid out for someone actively reading it. Give it a
      long-session mode, in the hub's own palette (deep ink/charcoal, parchment, one teal accent, restrained
      gold - refine it, do not replace it):
      .1 A DIMMER WATCH. A low-light treatment that drops page luminance and pulls the parchment back without
         losing the 4.5:1 floor on any text, so the page can sit next to a bright stream at 2 a.m.
      .2 AN AMBIENT LAYOUT. A compact mode that keeps what changes by itself - the town's state line, the
         Chronicle, who is below - and folds away the parts that only matter when someone is clicking.
      .3 IT CHANGES QUIETLY. Anything that updates while the page is idle arrives without a jolt: no layout
         jump, no flash, honour prefers-reduced-motion, and never steal focus from the chat input.
      .4 IT REMEMBERS, PAGE-LOCALLY. The chosen mode survives a refresh in this browser only, re-validated on
         read like every other stored preference, and there is an obvious way back to the full page.
      DONE: 1280 px captures of the full page and of the watch mode side by side, a measured contrast table
      showing every on-page text style still at or above 4.5:1 in the dimmed treatment, a recording of the
      page sitting idle through at least two snapshot updates with no jump or flash, a 390 px capture
      confirming H17's reflow discipline still holds, and all six query-string states plus the hostile-name
      test passing.
  RESULT (2026-11-15 12:43 CT, hub f364597): the Night Watch - a dimmed ambient long-session mode driven by ONE class on
  <html>; town strip, status, Chronicle and Bands sit side by side, animations off, remembered per-browser through a
  whitelist-validated value. Measured min contrast 4.60:1. Reviewed: no CSP change, no new fetch, no write path, no new
  innerHTML - the security greps come back empty on the whole diff.

- [x] H22. THE FIRST MINUTE - A NEWCOMER MUST UNDERSTAND BELLMIRE WITHOUT ASKING. Owner: HUB BUILDER
      (web/index.html, web/app.js, web/style.css, web/NOTES.md). Someone arrives mid-raid from a raid
      list, opens the hub, and sees boards and tabs for a world they know nothing about. The Commands
      tab already lists WHAT TO TYPE; this item is about WHY, and it is not a wall of text. Staged:
      H22.1 WHAT THIS IS. A short, well-set opening on the hub's landing view - what Bellmire is, that
            the town is really being run live, and what the viewer's part in it is - written in the
            town's voice, not in product copy, and never more than a newcomer will actually read.
      H22.2 SHOWN WITH LIVE NUMBERS. The explanation uses the snapshot that is already on the page -
            the town's current tier, how many heroes are abroad, what is happening right now - so the
            first thing a newcomer reads is demonstrably true at that moment, with an honest fallback
            when the snapshot is empty, stale or failed.
      H22.3 THE THREE DOORS. Three clear next steps from the landing view - get a hero, watch what is
            happening, learn the rules - each handing off to the tab that already does that job (the
            Commands tab, the Chronicle/Town, the die and Guild Roll). No duplicated content: link,
            do not restate.
      H22.4 IT MUST NOT NAG. A returning viewer sees it once and can dismiss it for good, page-locally.
            It never covers the live content and never appears on a narrow phone as a full-screen gate
            (H17's reflow discipline holds).
      DONE: a 390 px and a 1280 px capture of the landing view for a first-time visitor and for a
      returning dismissed one; the opening read aloud in under thirty seconds; the empty, stale and
      failed snapshot states all show the honest fallback; all six query-string states and the
      hostile-name test still pass.


      RESULT (supervisor 2026-11-15 14:05): shipped on `hub` da58b25 and merged. A dismissible
      welcome card: what Bellmire is, ONE live line built from the snapshot the page already holds
      (town stage + heroes on the roll + bands abroad + the latest Chronicle word), three doors to
      Commands/Chronicle/die, hidden in Night watch, dismissal remembered per browser. SECURITY
      REVIEW PASS: no new innerHTML (the two legacy page-owned sites are untouched), every snapshot
      value through el()/textContent, door ids matched against TABS before acting, no new fetch or
      origin, no CSP change, no viewer write path, honest empty/stale/failed states reused.
# Phase AG - THE FIGHT, THE LOG AND THE TOWN'S OWN VOICE (supervisor, 2026-11-15 10:58 CT). IDs frozen as ever.
# Written to the "HOW BIG AN ITEM SHOULD BE" bar. D61 finally builds the L31 leftovers - and it builds them
# where the plan has always said they belong, with THEIR OWNER, not by handing the HUD worker files it does
# not own. D62 closes the GAP D60 left behind. H26 lets the hub stop guessing what D60 now publishes.
# C4 and C5 sit in the CONTENT section above so the content writer reaches them.

- [ ] D61. A FIGHT MUST READ WITHOUT A COMMENTATOR. Owner: DESKTOP BUILD (boss_bar.gd, party_frames.gd,
      health_bar_3d.gd, delve.gd, monster.gd). This is everything LEFT of L31, written for its real owner
      exactly as the note at the top of this file requires - the HUD worker owns none of these files and
      must not be given them. A viewer watching a delve today sees bodies swapping places and a health bar
      going down. None of the D&D underneath it reaches the screen.
      .1 THE NUMBERS IN THE WORLD. Damage and healing numbers that rise off the target and fade: the amount,
         and WHAT KIND of result it was - an ordinary hit, a critical (read unmistakably differently), a
         miss that says so rather than showing nothing, a save made, a hit resisted and a hit that landed
         for extra. Pooled and rate-capped so a flurry reads as a flurry instead of a wall of digits, and
         legible at 1080p over a dark floor.
      .2 CONDITIONS YOU CAN SEE. The conditions the game already applies, shown as icons - on the party
         frames for heroes and over the monster for monsters - with duration or stack where the game knows
         it. Icons come from the project's own set; no new asset without a CC0 LICENSE note. A viewer who
         has never played D&D must be able to learn what one means from watching, so each has a readable
         name the moment it is applied (the Chronicle line or the feed, whichever already fires).
      .3 A BOSS BAR THAT IS A BOSS. The lord's name and title, its health, the thresholds where it changes
         behaviour marked on the bar so a viewer can see one coming, and who currently holds its attention.
         When a lord variant has a mechanic, the bar says what it is in a few words - not a stat dump.
      .4 USE THE WORDS THAT EXIST. data/lore_lines.json already carries crit, fumble, descend, cleared and
         lord-intro lines (C-37 through C-40, and C-38's viewer_roll outcome lines). Read them. Do not write
         a parallel set of strings in code.
      DONE: a 1080p capture of one boss fight that contains, in the same window, a critical, a miss, a
      resisted hit, at least three different conditions visible on both a party frame and a monster, and the
      boss bar crossing a marked threshold - plus the feed for that same window to confirm nothing on screen
      contradicts the log. Then a delve soak measured the D23 way, stating average and minimum FPS against
      D23's baseline, to prove the numbers and icons cost nothing that matters. Parse 0 errors.

- [ ] D62. THE CHRONICLE IS THE CAMPAIGN LOG - IT MUST KNOW THE DARK AS WELL AS IT KNOWS THE TOWN.
      Owner: DESKTOP BUILD (delve.gd, chatcmd.gd, gear.gd, roster.gd - the files that raise hero lines).
      D60 shipped the machinery: every Chronicle row carries the town's day, and a raiser can tag a line
      with its kind and the heroes it is about through town.tag_feed(kind, [names]). D60's own RESULT names
      the gap it left: the lines raised in the DUNGEON - deaths below, kills, finds in the dark, descents,
      level-ups - are still untagged, so the hub's journal cannot group or filter the half of the campaign
      that viewers care about most.
      .1 TAG EVERY HERO LINE. One town.tag_feed(...) call beside every feed.append in these files that is
         about a hero, with the kind and the hero names the hub shows. Untagged stays untagged where the
         line is genuinely about nobody - never guess a subject.
      .2 THE DUNGEON RAISES LINES IT CURRENTLY SWALLOWS. A trap sprung, a secret door found, a hoard
         opened, a party turning back, a hero going down and being carried out - moments the game already
         knows about and says nothing about. Use the existing lore_lines.json keys (descend, cleared,
         epitaph, find) rather than inventing strings in code; name any key you needed and did not find.
      .3 IT MUST NOT FLOOD. A stated cadence and a dedupe window so a busy delve does not push the town out
         of its own Chronicle, with the drops visible in a log so nothing vanishes unexamined.
      DONE: a 10-minute run with a full roster and at least one delve and one raid overlapping, then the
      published payload showing hero lines from the dungeon carrying `who` and `kind`, the new dungeon
      moments present, and the town's lines still there alongside them. State the payload KB before and
      after against D59a's 244 KB and the stated cap. W1A_TEST OK, TWITCH_PARSE OK, D60_CHRON OK, parse 0.

- [x] H26. THE JOURNAL STOPS GUESSING. Owner: HUB BUILDER (web/app.js, web/style.css, web/NOTES.md).
      H21 built the campaign journal before the publisher could tell it anything, so it guesses twice: it
      splits the campaign into "stretches" on a 90-minute wall-clock gap because no line carried a date, and
      it decides which lines are about a hero by matching their name as a whole word in the text. D60 shipped
      on 2026-11-15 and both guesses are now unnecessary - every row carries `day` (the town's own day) and
      the tagged rows carry `kind` and `who` (an array of hero names).
      .1 DAYS, NOT STRETCHES. Group the journal by the town's own day when the rows carry one, and say so in
         the heading. Keep the wall-clock heuristic ONLY as the fallback for a v=3-era payload or an untagged
         row, and make which one is in use visible rather than silent.
      .2 WHO, FROM THE PAYLOAD. A hero's own lines come from `who` when the row has it, falling back to the
         existing name match when it does not - and the fallback is labelled as such, because a viewer should
         know when the page is inferring rather than reporting.
      .3 FILTER BY KIND. The journal can be read by what happened - deaths, raids, finds, delves, town - from
         `kind` where present, with an honest count of rows the filter could not classify.
      .4 STILL HONEST. Every string through el(); no field used as a URL, src, href or style; `day` and `kind`
         validated as a bounded number and a bounded identifier before they touch the DOM; `who` capped; CSP
         byte-identical.
      DONE: a capture of the journal grouped by town day with the day headings visible, the same journal with
      a kind filter applied and its unclassified count shown, a hero's own lines drawn from `who` for a hero
      whose lines never spell their name the same way, a v=3 payload pasted into a mock still rendering the
      old grouping with the fallback labelled, the hostile-name test passing on a `who` entry and a `kind`
      value, and all six query-string states passing.
  RESULT (hub 41125a4, 2026-11-15): the journal groups by the town's own `day` and says so in the heading,
  with H21's 90-minute wall-clock split kept as a LABELLED fallback for untagged rows; hero lines come from
  `who` and the name-match fallback is marked inferred; the Event filter prefers `kind` and states how many
  rows it could not classify. `day`/`kind`/`who` are validated as a bounded number / bounded identifier /
  capped array before storage and before the DOM; every string still goes through el(); no snapshot field is
  used as a URL, src, href or style; CSP byte-identical. Adds ?mock=journal and ?mock=journal3. Supervisor
  review: the diff introduces no innerHTML/outerHTML/insertAdjacentHTML/eval/new Function and no URL sink.

# Phase AG - the hub's queue was one item deep (supervisor, 2026-11-15 14:05, CORRECTED 14:12)
# H26 is the hub's last unchecked item, so two were written to keep the builder fed. The first pair
# was WITHDRAWN UNWRITTEN by the supervisor on checking the shipped record: a growth ladder is
# already live as H18.1 and the phone layout is already live as H17 (360-1280, all six states at
# 390). IDs H27 and H28 stay spent on these, their replacements - IDs are frozen once written.
# Both are read-only, web/ only, no CSP change, no viewer write path, and both reuse machinery the
# page already has rather than starting anything over.

- [x] H27. TALES OF THE DIE - THE NIGHT'S ROLLS DESERVE A BOARD, NOT JUST A FLICKER. Owner: HUB
      BUILDER (web/index.html, web/app.js, web/style.css, web/NOTES.md). The d20 resolves in the
      game and the hub displays the current roll (H9), so a roll appears, matters for a minute and
      is gone - on a stream that runs all night the best moment of the evening scrolls away. Keep
      the session's rolls the way H14 already keeps the Chronicle: capped per-browser history, newest
      first, day-divided. Show for each the roller, what they paid for, the number, and what came of
      it - the crit and the fumble lines content already wrote (lore_lines.json viewer_roll, C-cycle
      38). Make a crit and a fumble unmistakable at a glance without inventing a new colour: use the
      restrained gold already in the palette for a crit and ink-dim for a fumble. A counter of the
      night's crits and fumbles earns its place; a leaderboard of rollers does not - that is L66's
      season, not yours.
      DONE: a capture of the board after several mocked rolls showing a crit, a fumble and two
      ordinary results with their outcome lines, day-divided and newest first; the night's crit and
      fumble counts matching the rolls shown; a capture after a reload proving the history survived;
      ?state=empty renders "no rolls yet tonight" rather than an empty frame; ?state=fail and
      ?state=stale stay honest; a hostile roller name renders as literal text; CSP unchanged and all
      six local checks still pass.

      RESULT (hub 6901b60, 2026-11-15 15:40 CT): the board ships. `bellmire.rolls.v1` keeps up to 100
      rolls / 48 h / 60 KB per browser, newest first, folded and de-duplicated on (at, by, face,
      result) each pass and RE-VALIDATED on read (normalizeRolls + control-char strip + ISO regex on
      `at`, tier only through the page-owned TIER_ALIAS whitelist, face an integer 1..20), so a
      hand-tampered store cannot inject anything. Day dividers use the Chronicle's own `dayVoice`;
      a crit is restrained gold, a fumble ink-soft and dashed - no new colour; a tally chip pair
      counts the crits and fumbles SHOWN so it always matches the list. Empty says "No rolls yet
      tonight."; storage absent/full/throwing degrades to live-only. CSP byte-identical, no new
      fetch/origin, no write path, KNOWN_V unchanged - index.html gained only the page-owned
      `<p id="rollTally">`. Checks: ?mock=roll (crit + fumble + two ordinary + a hostile roller
      `<img src=x onerror=alert(1)>`), reload keeps all five, a multi-day store divides
      Today/Yesterday, ?state=empty/fail/stale, ?mock=chronicle, ?mock=crowd, ?open=1 - 0 dialogs,
      0 injected nodes, no horizontal scroll at 390. Supervisor review: the diff adds no innerHTML/
      outerHTML/insertAdjacentHTML/eval/new Function and no URL/src/href/style sink.

- [x] H28. A VIEWER MUST BE ABLE TO SEND A FRIEND STRAIGHT TO THEIR HERO. Owner: HUB BUILDER
      (web/index.html, web/app.js, web/style.css, web/NOTES.md). H20 built the character sheet and
      H24's finder lands on a hero by id, but a viewer who wants to show someone their hero can only
      send the hub's front door and say "now search for me". Give the page a deep link: opening the
      hub with a hero address in the URL fragment opens that hero's sheet directly, and a "copy a
      link to this hero" control on the sheet puts that address on the clipboard. The address is
      resolved the way the finder already resolves a target - matched against the heroes in the
      snapshot, integer-addressed, never taken as a selector, a URL or markup - and an address that
      matches nothing lands on the roster with a plain "that hero is not on tonight's roll" instead
      of an error or a blank page. No new fetch, no new origin, no write path; the fragment is the
      only thing read from the URL and it is validated before it is used.
      DONE: a capture of the hub opened cold at a hero's deep link showing that hero's sheet; a
      capture of the copy control having produced the address; a capture of a nonsense address
      landing on the roster with the plain message; a capture of an address built from a hostile
      hero name resolving as text and executing nothing; the deep link working at 390 wide as well
      as 1920; CSP unchanged and all six local checks still pass.

  RESULT (ticked 2026-11-16 by the supervisor, hub a971e85): `#hero-<n>` opens that hero's sheet, where n is
  a 32-bit FNV-1a of the lower-cased name computed by the page - no name ever enters the URL. A "copy a link to
  this hero" control on a living hero's sheet writes the address (address bar as fallback). An address matching
  nobody, or a malformed one, lands on Heroes with "That hero is not on tonight's roll". Applied only when the
  fragment changes, so the 60 s refresh never re-lands the viewer. Hostile-name address resolves as text and
  executes nothing; CSP unchanged; all six local checks pass. KNOWN LIMIT recorded in web/NOTES.md: the link is
  per NAME because the snapshot carries no stable hero id - a renamed hero's old link lands on the note.
================================================================================
## NEEDS MR. E (supervisor, updated 2026-11-16 03:58 CT). Seven things, all short.
  0. THE D95 SHEETS ARE WAITING - this is the one you asked for by 09:00 and it is in early.
     renders/art/d95/_overview.png (all ten, front) and _sheet_<key>.png (four views each), plus
     the same ten inside the engine at renders/cycles/d95/sheet_overview_front.png. Both halves
     end in an honest fault list, as you asked. Your eye is the bar.
  0b. RINGS, AMULETS AND GLOVES CANNOT BE TOLD APART AT STREAM DISTANCE - measured again after
     the fix, not guessed (rings: 0.00% of the hero's pixels change between six different rings;
     gloves: 11 of 15 pairs). They ARE different objects now; they are just too small to see on a
     body. A design call, not a bug: do you want an oversize "readable" ring and glove on the
     hand, or do they stay inventory items never meant to read at delve distance? This is the
     only thing in D94 no builder can take.
  0c. THE D94 SHUTDOWN - DO YOU LIFT IT? You shut HUD, HUB and CONTENT down at 00:55 for D94.
     The build bug is now fixed and ticked on both sides; what is left of D94 is your ring call
     above, one small mirror the game build lane already owns, and the pool question below. Those
     three lanes are standing down and will keep standing down until you say otherwise. One word
     either way.
  0d. BOOTS AND GLOVES CAN NEVER BE LEGENDARY - WHICH WAY DO YOU WANT IT? Measured twice, by both
     lanes separately. The legendary accessory pool is 16 deep: 8 rings, 6 cloaks, 2 amulets, and
     no boots and no gloves at all. One cost scale decides rarity for every slot (441+ =
     legendary), but boots top out at 420 and gloves lower, so those two slots are shut out of the
     band - which is why D95's showcase had to borrow very-rare pieces to fill its legendary row.
     Two ways out, and both change what a viewer paid for, so neither is ours to pick: (a) band
     rarity PER SLOT, by cost quantile inside the slot, the way ornateness already works - nothing
     gets dearer, but a 420 boot starts reading as legendary; or (b) leave the band alone and write
     dearer boots and gloves, which is items.json and needs the content lane lifted. Your call.
  1. YOUR EYE ON THE LORD REVEAL (L72, shipped). renders/cycles/20261116_l72/sheet_reveal_mourncoil.png
     - the camera eases out as Mourncoil rises instead of cutting. Does the reveal land? The
     measurement says all eight lords are framed whole with the camera out of the walls; only you
     can say whether it reads.
  2. HUB ITEM ICONS - YOUR CALL (raised by H30). The 454 D73 item icons live outside web/, and a
     snapshot value may never choose an image path, so the Satchel tab draws glyphs instead. To use
     the real icons, a curated set must be COPIED into web/ and whitelisted by name. Yes or no.
  3. H30 ASSUMED TWO CHAT COMMANDS, !withdraw and !stone, because D81 is not built yet. If those
     are not the names you want, say so now - they are cheap to change today and expensive once
     viewers have learned them.
