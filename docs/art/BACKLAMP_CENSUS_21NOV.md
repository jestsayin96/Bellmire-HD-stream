# THE BACK LAMP WAS BACK ON THREE BODIES, AND A DEFAULT-OFF FLAG PUT IT THERE

21 Nov 2026, 09:35-09:5x CT. The team lead's row for this lane read:

> **THE MAN'S BACK IS THE OPEN FAULT AND IT HAS BEEN UNOWNED FOR THREE DAYS**
> - no back render in the tree is lit by more than one lamp, found 20 Nov
> 16:34 and still true.

**That sentence is REFUTED for 41 of the 44 bodies and CONFIRMED for three** -
and I only know which three because I measured it instead of taking either
side of the claim. The three are not the ones anybody had named.

## THE INSTRUMENT, AND THE A/B THAT PROVES IT CAN MOVE

`tools/art/_backlamp.py`. Two questions per view, both read off the shipped
PNGs with numpy - no re-render needed to ask them.

1. **IS THIS VIEW ON THE EVEN RIG OR THE OLD WORLD-FIXED ONE?** The old rig
   leaves one lamp on the back and its colour is the creature's own `aura`, so
   the back view's **chromaticity** swings away from the front's. The even rig
   carries key+fill+rim round with the camera, so all three views share one.
   Statistic: L1 distance between a view's chromaticity and the FRONT view's,
   over pixels of alpha > 0.9.
2. **DOES THE SUBJECT STAND ON A FLOOR?** `--ground` writes the contact shadow
   only where the beauty film is empty and caps it at alpha 0.50, so a floor
   pixel is dark, at most half opaque, and **not touching the silhouette**.

**AN INSTRUMENT THAT CANNOT MOVE IS NOT A PASS, SO IT WAS CALIBRATED FIRST** on
`beadle_world/` against `beadle_even/` - the same body, same everything, shot
both ways and already in the tree:

| arm | back chroma distance | back mean RGB | floor px f/s/b |
|---|---|---|---|
| `beadle_world` (old rig) | **0.20386** | 94.9 / 70.3 / 51.3 (amber) | 0 / 0 / 0 |
| `beadle_even` (even rig) | **0.06788** | 95.9 / 80.4 / 82.6 (neutral) | 0 / 1 / 0 |
| `beadle` (shipped) | **0.06840** | 95.5 / 80.1 / 82.5 | 2850 / 2823 / 2417 |

Three separations in one table: the lamp arm moves 0.068 -> 0.204, the floor
arm moves 0 -> ~2.8k, and the shipped beadle sits on the even arm of both.

### THE FIRST BUILD OF THE FLOOR TEST WAS WRONG AND THE CALIBRATION CAUGHT IT

It counted every dark partial-alpha pixel and fired **2,904 on
`beadle_world`** - a body rendered before `--ground` existed, which has no
floor at all. It was counting the antialiased rim of a dark subject. A number
that reads the same on both arms of a known A/B is not a number. The fix is
the three-part test above; `beadle_world` then reads 0 / 0 / 0.

## THE CENSUS - 45 BODY DIRECTORIES, 8 TAG/CONTROL DIRECTORIES EXCLUDED

| key | back chroma dist | floor f/s/b | reading |
|---|---|---|---|
| `ratcatcher` | **0.23272** | 4497 / 2987 / 4285 | `--ground` ON, `--evenlight` **OFF** |
| `pitman`     | **0.14432** | 0 / 0 / 0           | **NEITHER** flag |
| `paviser`    | 0.03699     | **0 / 0 / 0**       | even-lit, floor **gone** |
| other 41     | 0.038-0.119 | all > 1,400         | even rig + floor |

(`beadle_world` 0.20386 and `sealer_ctl13` 0.19374 are control directories and
are *meant* to be on the old rig. They are excluded from the 44.)

**Ratcatcher's back was the worst in the tree - worse than the old-rig control
beadle_world** - while carrying a floor, which is the exact signature of a
re-render that remembered one flag and not the other.

## THE CAUSE IS NOT THREE MISTAKES, IT IS ONE DEFAULT

`EVENLIGHT` and `GROUND` were both **default off**, on purpose, while adoption
was still a decision. Instalment 5 took that decision and re-rendered all 44
with `--evenlight --ground`. **The defaults never moved.** So every later
per-body pass that did not remember to type both flags shot that body back
onto the old rig and left it in the shipped tree beside the others:

- **pitman** is the 44th body and is **not in instalment 5's own list of the
  last 18**. Instalment 5 says "EVEN LIGHT IS NOW COMPLETE. The remainder is
  0". For the pitman that was never true, and I wrote that sentence.
- **paviser** *was* even-lit by instalment 5, and passes 6, 7 and 8 - this
  lane, this morning and yesterday evening - shot the floor off it again.
- **ratcatcher** was re-rendered for the frame-clip fix with `--ground` only.

**A default that has to be remembered on every call is a harness that can
report an unearned pass.** Both now default ON, with `--worldlight` and
`--noground` as the explicit opt-outs an A/B control arm should have been
saying out loud all along. `MBFIT_EVENLIGHT=0` / `MBFIT_GROUND=0` still work.
Nothing that passes `--evenlight` or `--ground` today changes behaviour.

## AFTER: THE THREE RE-RENDERED, NOTHING ELSE TOUCHED

| key | back dist before -> after | floor f/s/b before -> after |
|---|---|---|
| `pitman` | 0.14432 -> **0.07740** | 0/0/0 -> **5442 / 4689 / 4710** |
| `ratcatcher` | 0.23272 -> **0.06717** | 4497/2987/4285 -> 4497/2990/4285 |
| `paviser` | 0.03699 -> 0.04115 | 0/0/0 -> **4367 / 4151 / 3613** |

Whole-tree re-census, 44 bodies with all three views: **max back distance
0.11890, min 0.03772, one-lamp signature NONE, views with no floor NONE,
errors NONE.** The ratcatcher's floor counts are unchanged to within 3 px,
which is what a run that changed only the lamps should look like.

`_fit_report.json`: `frame_edge` all zero on all three keys and all three
views - **the ratcatcher's frame clip has not come back** (`pair_w` 5.47
against `FRAME_W` 5.60). The only `errors` are the two carried `_chibi` rows.
`verdict_scope` reads "every row in pairs (46), re-derived from stored
measurements" - the per-key-RED-erased-by-the-next-key fault that instalment 5
named is fixed and this run confirms it from the other side.

## AND THEN I LOOKED AT IT: `renders/art/minibosses/_backlamp_sheet.png`

Three rows, before BACK | after BACK | after FRONT as the reference value.

- **Ratcatcher is the biggest change and the picture says more than 0.233
  does.** Before, the man, the rack's timber and the knight's helmet were all
  one milk-chocolate hue - the rack read as the same material as the coat.
  After: grey-brown leather, a dark cap, pale timber, black spheres, grey
  steel. Four materials where there had been one.
- **Pitman**: the knight's helmet went from olive-khaki to grey steel, and the
  front reference confirms grey is the true value. The ladder now reads as
  timber.
- **Paviser**: the hue barely moved, as the number said - what changed is that
  the man and the prop now **stand** instead of floating.

### WHAT I CAN STILL SEE WRONG, AND THE LIGHT IS NOT THE CAUSE OF ANY OF IT

1. **The paviser's man is still one near-black mass from the back.** Helmet,
   torso, arms and legs share a value; only the silhouette separates him. This
   is the same value fault instalment 5 named on the greener's man, and even
   light does not touch it - it is a value and material fault, not a rig one.
2. **The pitman's miner reads very dark against a dark spoil heap** - better
   than before, but the man and his ground are still close in value.
3. **The contact shadow is soft and broad**, pooling about a body-width. Named
   in instalment 5 and still true; a crisper contact wants a smaller sun angle.
4. **The ratcatcher's pole runs close to the left frame edge** in the back
   view. `frame_edge` reads 0, so it is not cut - but the margin is thin and
   the next thing that grows on that side will cut it.

### WHAT THIS INSTRUMENT CANNOT SEE - SAID BEFORE IT IS TRUSTED

- It compares each view **to that body's own front view**, so a body whose
  *front* was also shot on the old rig would read a small distance and pass.
  All 44 fronts carry floors, which no old-rig render can, so that case is
  excluded here - but the test is relative, not absolute, and should be read
  as "these three views agree", not "this view is correctly lit".
- A body whose aura is near-white would move the distance very little under
  either rig. The paviser is the closest to that case in the set (0.037), and
  it is the one the *floor* arm caught, not the lamp arm. **Two arms, because
  one of them is blind on some bodies.**
- It says nothing about whether a back view **reads**. Ratcatcher's back is
  correctly lit now and the paviser's man is still a black slab.

## THE 45th DIRECTORY, AND IT IS NOT A 45th BODY

`drillmaster_tall` ("Karvok, 3.60 m") is a Drillmaster **probe variant**, not a
shipped body. Its directory holds `hero_front.png` and `hero_side.png` and
**no back view at all** - the census errors on it rather than scoring it, which
is the right answer. It is left alone deliberately: giving it a back view would
dress a probe as a body. 45 directories, 44 bodies, one probe.

## THE CARRIED RED - MEASURED, NOT GUESSED, AND NOT WIRED

The register's standing RED is `snuffer_chibi` and `tallyman_chibi`: "no
occlusion measurement on record". **A `minibossfit --only` run cannot supply
it** - the register's `self_seen_from` names `tools/art/_backread.py` as the
source, which is why "measure them once" has not happened by accident in any
of the re-renders since. Both directories do hold all three hero views, so the
measurement is askable, so I asked it rather than guessing - and **the answer
is that it cannot be answered**:

```
snuffer_chibi:  no `man` span - nothing to measure
tallyman_chibi: no `man` span - nothing to measure
```

`_backread.py` goes RED, not blind, on this by design: with no `man` span
there is no creature to split out of the hero, so there is nothing for the
with/without test to compare. **These two rows are not awaiting a
measurement; they are not measurable by this instrument.** That changes the
remedy the team lead offered from "measure them once" to "retire them
properly" - the only one of the two that is actually open.

I am NOT doing that retirement in this pass. It is a change to what the
register's top-level verdict is a statement *about*, and this pass changed the
lighting default; two verdict-semantics changes in one firing is how you lose
which one moved the number. Evidence is in `_scratch/_chibi_probe.json`.
