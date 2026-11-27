# 70. THE HAMMERMAN - *IT TAKES EVERY BLOW AND PAYS THEM BACK AT ONCE*

**"Alltold".** `hammerman`, theme `firepit`, h 2.26 m, span 1.86 m, wear 0.55,
static (no armature). Art lane, 27 Nov 2026, 13:35-14:1x CT.

**THE SEVENTIETH, AND BY THE SUPERVISOR'S 13:23 CT DIRECTIVE THE LAST.** The
miniboss body count is capped at 70. After this one the art lane does not make
another miniboss; it pivots to hero gear - weapons first, then armour sets,
then shields.

## WHAT I CHECKED FOR FIRST - MEASURED THIS RUN, NOT REMEMBERED

- **`tools/art/minibosses.py` parsed with `ast`, not a regex.** `BUILDERS` has
  **83** entries, **69 distinct bases** once the 14 `_chibi` / `_tall` variants
  are folded out. `hammerman` is in none of them and
  `assets/monsters/minibosses/hammerman.glb` did not exist. Nothing was rebuilt.
  (The team lead's 12:58 row said a flat regex gave it 43 and that it did not
  believe the number and would not publish it. It was right not to.)
- **THE 69th WAS ALREADY SHIPPED WHEN THE 12:58 ROW GAVE IT TO ME.** The row
  read "THE 69th IS YOURS". `origin/main` already carried the SHEARMAN
  (Cutloose) at `7a4ce41a` (13:00:32 CT) with pass 4 at `85e4fb82` (13:03:54
  CT), both reachable from `origin/art` and `origin/main`. So the 69th was 30
  minutes old when the row was written and the item in front of me was the
  70th. Nobody is at fault for this - the row was written at 13:05-13:22 off a
  tree measured at 12:58 - but it is recorded so the cascade count is not
  carried forward wrong.
- **The cascade, measured by me on `origin/main` this run:**
  `miniboss_feed.by_key` = **68** keys. `Delve.MB_NAME`, brace-matched at depth
  1, = **67** keys. Bodies in `assets/monsters/minibosses/` = 69 distinct named
  bases. `mower` is fed and unnamed; `shearman` is neither fed nor named.
  **69 bodies / 68 feed / 67 names, and this is the 70th body.**
- **Theme chosen by measurement.** `dungeon_hd.gd` `THEME_MINIBOSS` +
  `THEME_MINIBOSS_MORE` parsed: 67 drawn bodies over 14 themes. The thinnest
  six are at four each - barracks, prison, shrine, keep, **firepit**,
  confection. `firepit` is chosen and the reason is in the theme's own prop
  row: it is the one theme that already carries `Anvil.gltf` and
  `Anvil_Log.gltf`. A struck plate belongs in the room with the anvil in it.
- **Firepit's existing four, checked one at a time for a re-skin.** STOKER
  (only as big as the fire), MOULDER (takes your shape), TAPSTER (drinks what
  you brought), FANNER (takes the air). None of them defers damage.
- **Packs before geometry.** `_packs/` was not reached for: there is no
  "struck plate with a lit tally" in any of the forty, and every part of this
  body is a primitive (box, flattened sphere, tube) whose size has to follow
  the mechanic. Nothing third-party is used, so there is no licence row to add.

## THE IDEA, AND WHY IT IS NOT A SEVENTIETH COAT OF AN OLD ONE

Parsed out of the idea phrases this lane has shipped: forty-odd distinct
mechanics, conditioning on what you hit it with, what you carry, where you
stand, who is down, whether one hero can reach another, and the room itself.
**Three of them touch damage taken and all three MITIGATE it** - the
SCRAPWRIGHT replaces the plate you knocked off, the TANNER will not take the
same blow twice, the LEECH will not let a wound close. **Not one BANKS.**

This one does not reduce a blow, resist a blow or heal off one. It KEEPS it.
Every hit goes into the bar strapped across its chest and stays there as a lit
mark, and while the bar fills it does not answer at all. When the seventh mark
lights it turns and pays the whole sum back in one stroke, on whoever put the
most in.

So the party's own damage is the clock they are being timed by, and the
fastest kill is also the biggest bill. **The habit that fails here is the
first one a party learns: that hitting harder is always right.**

**IT IS THE DELIBERATE OPPOSITE OF THE STOKER, ITS OWN THEME-MATE, and that is
written down rather than hidden.** The Stoker shrinks when the room is starved.
This one grows the harder you work. A party that learned firepit by starving
the Stoker arrives here and does the one thing that loses.

**The counter-play is all on the body**, which is the whole point of drawing
it: seven marks, filling left to right, so the bill is countable from the
doorway. Stop striking and the marks go dull. Spread the blows and nobody is
the mark. Cut the two straps and the bar comes off.

## SIX PASSES, ONE NAMED FAULT EACH, EVERY ONE DRIVEN BY A PICTURE

| pass | the fault, found by looking | the change |
|---|---|---|
| 1 | **Both legs rendered PALE.** `_legs` calls `creatures.limb` with no slot and limb's default is `slot='bone'` - the slot this body reserves for the one pale object. Three pale things, so the count stopped being what the eye lands on. | legs written out locally in the smock slot; `_legs` left alone, it is shared with 69 shipped bodies |
| 2 | **The lit marks came back CREAM** - a white hole, not a hot one. This is the DYER's pass-3 finding (weld at strength 2.30 read cream, dropped to 1.05). I had read that note and repeated the fault. | glow strength 2.60 -> 1.00, hue deepened to (1.00, 0.33, 0.07) |
| 3 | **The figure was a POST.** Plate wider than the man, legs longer than the trunk, head a knob - authored at human proportions beside a 2.45 x 1.32 m chibi hero. Its own gen report had already said so in a number I had not used: span **1.33 m, the narrowest body in a house of seventy**. | every landmark lowered and every mass widened at the same final height (minibossgen normalises to CANON's 2.26): span 1.33 -> **1.86** |
| 4 | **The tally read as A CLOCK FACE.** Seven evenly spaced circles round a pale dish is a dial, and at pass 3 with the colour and mass fixed it read as a slot machine. A dial says "a value", not "a count of blows", and it is theatrical, which breaks Mr. E's first art rule. | the dish goes DARK and becomes the boss; the pale moves to a **bar of bright stock** with the marks punched along it in a ROW |
| 5 | **The row was a DASHED LINE at hero scale** - each mark about six pixels. The body's whole claim is that the bill is countable from the doorway, so a tally nobody can count is the claim failing quietly. | bar 0.56 x 0.15 -> 0.76 x 0.19, marks 0.030 -> 0.042, spacing 0.075 -> 0.105 |
| 6 | **Three pale objects again, in a milder coat** - the tally, the MID straps and the MID hickory shaft, which reads pale against a near-black smock. And the straps started above and inboard of the bar, so they read as two rods crossing behind the head rather than as straps entering the thing they hold. | the shaft joins the iron (`dark`); the straps re-anchored to the bar's own top corners. The straps KEEP mid - they are the back's only cue |

**THE THING WORTH KEEPING OUT OF THIS RUN: THE LUMA GUARDS PASSED EVERY PASS,
INCLUDING THE ONE WITH PALE LEGS.** This body carries the house's three luma
guards (bone/body >= 1.30, bone/mid >= 2.00, mid/body >= 1.80) and all three
were green at pass 1 while both legs were in the pale slot. **A palette test is
not an assignment test:** the guards check what the three values ARE and say
nothing about WHICH GEOMETRY GOT WHICH SLOT. The hero render is what caught it,
and the same family of fault came back at pass 6 with the sledge shaft. The
guards are kept because they catch a different thing; they are not sufficient
and the docstring now says so.

## THE FIT PROOF - RENDERED ON A BODY, AND I LOOKED

Rendered on the posed KayKit Knight (hero h 2.45, w 1.32, d 1.253), front,
side and back, `renders/art/minibosses/hammerman/hero_{front,side,back}.png`.
I opened all three at every pass; passes 1, 3, 4, 5 and 6 were each decided by
one of those pictures and not by a number.

- verdict **GREEN**, `ok: true`, errors `[]`, blind_views `[]`
- ratio **0.92**, margin **3.72**, 3 proving views
- blank-and-border: **210 view PNGs opened, 0 failures, 0 frame clips**,
  70 cells, scope whole_house
- `red_summary`: rows `[]`, shipped_red `[]`, `ok_shipped: true`
- gen: `ok: true`, 0 blanks, span **1.86 m CORRIDOR-SAFE** (three-cell clear
  span 11.0 m), **UNDER-LID**, not room-locked, 4 materials

**THE SELF-SEEN CENSUS WENT RED FIRST AND IT WAS TELLING THE TRUTH.** The first
fit run after the body landed came back RED with
`hammerman: in the register and in NO self_seen census list - the census was
never ASKED about this body`. That is the right answer: an instrument that has
not been asked about a body cannot green it. `tools/art/_selfseen_census.py`
was re-run and the register went green honestly, not by softening the gate.

### THE FAULTS I CAN SEE. SEVEN, NONE SWEPT.

1. **The straps still read as a carrying frame, not as shoulder straps.** They
   now visibly enter the bar's top corners (pass 6), but from the front they go
   straight up before bending back, so they read as two uprights. A viewer
   gets "the bar is held on", which is the meaning, by a shape that is not
   quite the right one.
2. **The face reads as a skull** - a pale wedge with two round dark eyes on a
   dark ball. It is a hood over a lit-from-nowhere face, and it is closer to a
   plague mask than to a smith.
3. **Edge-on, the bar and boss make a shelf** standing out from the chest. The
   side silhouette has a horizontal ledge at chest height that nothing on a man
   would have.
4. **The left mitt is lost behind the apron** in the front and three-quarter
   views. The left arm reads as a block that ends.
5. **The sledge head reads as a dark brick** on the floor rather than as a
   sledge; at hero scale the shaft plus head can read as a crutch.
6. **The dark boss behind the bar is nearly invisible** against the smock -
   it is a slightly lighter dome and does little work for its face count.
7. **The boots are oversized blocks**, which is the house's shared `_legs`
   convention and is kept deliberately, but on this body they are the second
   heaviest thing in the silhouette after the tally.

### WHAT THE REGISTER STILL CANNOT SEE

`seen: 1.0` on three views says the creature survives the hero in front of it.
It says **nothing about whether the seven marks can be told apart**, and that
is this body's entire mechanic. Pass 5 existed only because I opened the hero
render and counted; no number in the register moved between pass 4 and pass 5.
If anyone changes the bar, the mark size or the spacing, **count them in
`hero_front.png` before trusting the verdict.**

## WHAT THE GAME BUILD LANE MUST DO - I DO NOT DO IT, AND I TOUCHED NO .gd

The art lane touched only `tools/art/minibosses.py`, `docs/art/` and
`renders/art/`. All of the following are the game build's:

1. **`scripts/bestiary.gd`** - a `model` path for `hammerman` pointing at
   `res://assets/monsters/minibosses/hammerman.glb`, and **NO `anims` entry**:
   the body is static, there is no armature.
2. **`scripts/dungeon_hd.gd`** - add `"hammerman"` to
   `THEME_MINIBOSS_MORE["firepit"]`, which takes firepit from 4 to 5 and off
   the thin list. `miniboss_for` will correctly hold it out until content's
   `by_key.hammerman` lands, which is the gate working.
3. **`scripts/delve.gd`** - the `MB_NAME` row, when content has fed it:
   `"hammerman": "Alltold"`. One line. Do not write it before the feed row
   exists; `tools/_s51_names.gd` requires every `MB_NAME` key to be in
   `by_key`.
4. **MB_FIT** - the measured ratio is **0.92**. Use it; do not re-derive it.

## CONTENT

Needs `miniboss_feed.by_key.hammerman` arrive / act / broken / fall lines. The
arrive line the generator carries is *"Something ahead is taking it and not
answering."* Plainness is the voice; the thing to write around is that he does
not hit back while the bar fills, and that the marks are a bill.

## STILL OWED, SMALL AND UNCHANGED

`assets/monsters/minibosses/snarer_chibi.glb` is committed with no
`.glb.import` sibling, so that body cannot load until a Godot run generates
one. The game build loads the base `snarer.glb` and is not blocked either way.
**Say whether the chibi is wanted at all** - if it is not, deleting it is one
line and the register row retires with it.

## LICENCE

Nothing third-party. Every vertex here is generated procedurally by
`tools/art/minibosses.py` (raw vertex maths, `lordlib` primitives). No pack was
read, so `docs/art/ASSET_SOURCES.md` needs no new row.
