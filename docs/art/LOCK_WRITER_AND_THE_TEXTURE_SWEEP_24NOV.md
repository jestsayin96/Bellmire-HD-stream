# THE LOCK WRITER THAT COULD NOT BIND, AND THE SWEEP THAT PROVED THE SKIN FAULT IS A SET OF ONE
art lane, 24 Nov 2026, the 23:34 CT firing. All times CT (CST, UTC-6).

## 1. THE 22:42 FAULT WAS NOT A TYPO - THERE WAS NO HELPER

The art lane's 22:42 RUNNING/IDLE pair went into `docs/RUN_LOCK.txt` with four unformatted
percent-s placeholders where the timestamps belong. The prose inside the IDLE carried
claim 22:42:46 / cap 23:07:46 / declared 22:50:46, which is the only reason it was not scored as a
lock fault - but no other lane should have to read art's prose to find art's stamp.

**The cause was structural.** Every art seat retyped the lock template inline in a one-shot bridge
call, so the `%` template and its arguments lived in two places and nothing checked them against
each other. A seat that dropped the argument tail shipped the template and the file took it.

`tools/art/_lock.py` is the fix, and it is not "remember to bind the stamp":

- stamps are bound by f-string from real `datetime`s - **there is no template to forget**;
- `_bound()` REFUSES to return a line carrying `%s`/`%d`/`{name}`/`None`, or a line with fewer
  full ISO stamps than the shape requires, or an empty one (RED ON EMPTY);
- `cap` is **derived** as claim+25, never typed (a sibling lane typed a cap one second over its
  true cap this same evening);
- a declared finish past the cap **raises** - split the job, do not declare a crossing;
- `LOCK_PATH` points at **R**, because W5's own copy of the lock is stale to 20 Nov 12:15.

`selftest()` is GREEN at **8 pass / 0 fail** and it fires **both ways**: four of the eight are RED
arms, including feeding it the literal 22:42 line, which it refuses by name.

**It caught me inside sixty seconds of shipping it.** My first RUNNING line this hour quoted the
old fault in its own prose, the guard saw a percent-s in the body and refused the write. Nothing
went to the file. I reworded the prose rather than loosening the guard - the guard was right.

Proof asked for and delivered: this hour's pair is in `docs/RUN_LOCK.txt`, written through the
helper, claim `2026-11-24T23:46:32-06:00`, cap `00:11:32`, declared `23:56:32`, released
`23:47:13` inside it, and the tail reads back with every stamp legible.

## 2. THE REGISTER SEAM I RECORDED LAST HOUR AND DID NOT FIX

Last hour's §6 recorded, without fixing: `weigher` was in `_fit_report.json` pairs and **not** in
`_report.json.minibosses`. Measured this hour, not assumed:

| | before | after |
|---|---|---|
| `_report.json.minibosses` rows | 69 | **70** |
| `pairs` - `report` | `['weigher']` | **`[]`** |
| `report` - `pairs` | the 9 retired `_chibi` | the 9 retired `_chibi` |
| top-level | ok true, errors 0 | ok true, errors 0 |

`minibossgen.py --only weigher` put the row back (Trueweight, treasury, 4 parts, 816 faces,
span 2.62, height 2.55, CORRIDOR-SAFE margin 8.379, UNDER-LID clear 6.95).

**`weigher.glb` came back BYTE-IDENTICAL** - sha256 `42606fe07450a6d8`, 91,192 bytes, before and
after. The rebuild is deterministic, so closing the seam moved no shipped body. I checked that
rather than hoping for it, because `--only` re-exports the `.glb` as a side effect.

I did NOT chase the 9 `_chibi` rows in the other direction: they are retired bodies with no fit
pair, which is the correct state and was already verified.

## 3. THE SKIN SWEEP - BROODGLUT IS A SET OF ONE, MEASURED

Last hour proved broodglut was shipping skinless by provenance on **one** body. The general lesson
("if a body's skin lives outside the .glb, the PNG must be tracked or the body ships bald") was
stated and never measured. So `tools/art/_tex_path_probe.gd` now takes its body list from
`TEXPATH_BODIES` instead of three hardcoded names, flags any `res://*.png` albedo or normal as
`EXTERNAL-`, and goes **RED ON EMPTY** twice: an empty body list fails, and a body that yields
**zero material slots** fails - that is the shape of a probe that loaded nothing and printed clean.

Swept all **72** `.glb` in `assets/monsters/minibosses/`:

```
TEXPATH_DONE bodies=72 fails=0        72 summaries, so no body was silently skipped
external PNG refs: 6, ALL on broodglut (2 distinct PNGs, both now TRACKED in git)
weigher   4 slots, 0 external    pledgeman 3 slots, 0 external   <- procedural/vertex colour
```

**Broodglut is the only body in the house whose skin lives outside its mesh, and its PNGs are
tracked.** The skinless-clone fault is now closed by measurement over the whole directory rather
than argued for one body. Godot rc 0, 0 ERROR.

**THE LIMIT:** this says where each material resolves *on this machine's import cache*. It is not
a fresh clone. A body whose PNG is untracked would still show `EXTERNAL-` here - which is exactly
why the external flag, not the existence check, is the thing to watch.

## 4. WHAT I LOOKED AT, AND WHAT THE NUMBERS CANNOT SEE

I re-rendered the weigher's three views and looked at `front.png` and the hero pair. The register
is GREEN on every measurable term (ratio 1.04, 3 proving views, seen 1.0, frame_edge all zero).
**Four faults the register cannot see, all pre-existing, none introduced this hour:**

1. **The beam is not held.** It crosses the shoulders while both hands hang empty - nothing in the
   picture carries the load, so the balance reads as passing *through* the figure.
2. The near hanger's two cords cross the forearm silhouette and read tangled from the front.
3. On the hero pair the far pan sits against the figure's own grey and survives only by its pale
   rim; lose that rim to a dark floor and the pan is gone.
4. The whole body is one mid-grey. At stream distance the pans are the only value break, which is
   thin for a treasury body whose wear is 0.30.

These are recorded, not fixed - the body is byte-identical to what ships and fixing #1 is a build
change that needs its own pass and its own render.

## 5. WHAT I DID NOT DO

**I did not invent the 60th miniboss.** The dry-lane permission was live and the clock did not
support it: I measured the existing roster first (59 keys off `BUILDERS`/`ORDER` in
`tools/art/minibosses.py`, and all 59 fight-ideas, so a candidate could be checked against them for
re-skin) and had ~25 minutes left after the lock writer and the two fixes. A body I cannot
fit-prove on a hero in the window is the one thing this lane may not report as done. Said rather
than half-shipped.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
