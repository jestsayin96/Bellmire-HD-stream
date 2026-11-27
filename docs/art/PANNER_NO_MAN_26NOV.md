# THE PANNER RED WAS THE INSTRUMENT'S, NOT THE BODY'S

**26 Nov 2026, 18:3x - 19:0x CT. Art lane.** Clock read off the machine
(`TZ=America/Chicago date`) at 18:34:40 CST and again at 18:40:20 while writing.

The team lead's 17:58 row gave this lane one item: the single error in
`renders/art/minibosses/_backread/_selfseen_all.json` -
`panner: the man span merged to no object` - the only thing holding that
harness at `ok: false`. The row said either answer closes it: a body fault
fixed, or a harness fault named and fixed.

**IT IS A HARNESS FAULT. The body is right and has been right since 24 Nov.**

## 1. WHAT THE INSTRUMENT WAS ACTUALLY SAYING

`panner` pass 4 removed its operator **deliberately**, after an A/B it
documents in full inside its own builder - *"a part whose removal changes a
view by nothing was contributing nothing to that view"* - and left

    P.spans["man"] = (len(P.items), len(P.items))

an **EMPTY** span, as the marker. A machine with no operator cannot fail a
can-you-see-the-man test.

Two places in the house already knew this and honoured it:

* `minibosses.man_ranges`, whose docstring names the panner marker by name;
* the register's self-seen census, which has reported three states since
  24 Nov - measurable / **no_man** / not_measurable - and lists `panner` under
  `no_man`, GREEN, after the same unearned red was caught one level up
  (`docs/art/SELFSEEN_AUDIT_24NOV.md` section 6).

`tools/art/_backread.py` - the instrument that WRITES the file - never got the
matching branch. So it kept reporting a fault in a body the house had already
ruled correct, and `_selfseen_all.json` has read `ok: false` on it for two
days. **An instrument that cannot report an unearned PASS can still report an
unearned FAIL, and they are the same fault.** That sentence is already in this
lane's own audit; it took two days to apply it one file over.

## 2. THE FIX, AND THE DISCRIMINATOR IT RESTS ON

`_backread.py` now reads a declared-empty `man` span as a **third state**:

* **NO_MAN** - the empty span is the builder's LAST statement
  (`a == b == len(P.items)`). The row carries `no_man: true`,
  `verdict: "NO_MAN"` and a reason string. **It claims NOTHING.** No view is
  rendered, no cell is written, `views` stays `{}`, and the register goes on
  counting `panner` in `no_man` and **not** in `measured_bodies`. It is the
  honest absence, stated out loud, in place of a wrong red.
* **RED** - an empty span with items authored after it
  (`a == b < len(P.items)`), i.e. an `_open()/_close("man")` pair that wrapped
  zero items. That is a real defect and stays red.
* Everything else is unchanged. A **non-empty** span that merges to no object
  still goes red on the original line, untouched.

**WHAT THIS BRANCH CANNOT SEE, SAID PLAINLY.** An empty span is a
DECLARATION, and this file cannot read a builder's mind. A body that meant to
split a figure and wrapped zero items would also declare an empty span. The
only discriminator available is WHERE the empty span sits, and it does **not**
catch a builder whose accidental empty `_close("man")` happens to be its final
statement. That case would read NO_MAN and should not. It is written into the
file's own docstring so the next seat does not over-read the branch.

## 3. BOTH BRANCHES WERE FIRED AND WATCHED

An assertion nobody has seen fire is not an assertion. `--prove-empty-mid
<key>` moves the marker into the middle **in memory only**, so the new red can
be watched on the very body the new green exists for:

| arm | file | result |
|---|---|---|
| `--prove-empty-mid panner` | `_selfseen_prove_emptymid.json` | `ok: false`, `verdict: RED`, one error naming the span, `prove_empty_mid: true` |
| plain `--keys panner` | `_selfseen_prove_noman.json` | `ok: true`, `verdict: NO_MAN`, `errors []` |

Both states observed this run, on the real body, through the shipped code path.

**A NUMBER THAT MEANT SOMETHING OTHER THAN ITS LABEL, CAUGHT BEFORE IT
SHIPPED.** The first cut of the RED message printed `n_items` - the builder's
TOTAL item count - under the words *"items authored after it"*, which is the
tail. Both branches were re-fired after the correction so that what ships is
what was watched; the message now prints the tail and the row carries
`items_after_span`.

## 4. HOW GENERAL IS IT - MEASURED, NOT ASSUMED

Writing a branch and saying how many bodies reach it are different acts, and
only the second can be checked. `tools/art/_emptyspan_census.py` (new, this
run) walks **every** builder in `M.ORDER` through the shipped `M.man_ranges`:

    bodies 63 | no_man 1 | empty_mid 0 | nonempty 61 | no_declaration 1
    no_man ['panner']   empty_mid []   declaration_errors {}   build_failed {}

`no_declaration` is `crimp`, which agrees with the register's
`not_measurable`. **The new RED branch is reached by ZERO shipped bodies
today** - it fired only under the force flag. It is a guard for the future,
not a measurement of the present, and must not be cited as one.

## 5. THE DECLARATION WAS CHECKED BY EYE, NOT TAKEN ON TRUST

The NO_MAN branch accepts a builder's word. That is exactly the kind of number
this lane has been wrong about before, so the word was checked against the
picture: `renders/art/minibosses/panner/hero_{front,side,back}.png`, looked at
at hero scale.

**There is no human figure on the panner in any of the three views.** The
declaration is true. Front reads drum, pale rim, hopper, mouth and crank, with
the crank plainly visible - which is the gain pass 4 bought by removing him.

**WHAT I CAN SEE THAT IS STILL WRONG WITH THE BODY** (reported, not opened -
the panner is shipped and ticked, and the freeze means I do not raise it as an
item):

1. **SIDE is the weak view and it is a construction fault, not a lighting
   one.** The drum goes nearly edge-on and the three legs collapse to a single
   post, so the silhouette reads as a dark disc on a pole - a mirror or a sign,
   not a machine. The crank disappears entirely in side.
2. **BACK is one near-featureless black mass.** The crank survives and is the
   only cue; the hopper reads as a small lump on top. Value separation is
   poorest here.
3. The drum reads **top-heavy** against the thin legs in side, where the foot
   is a single small block.

None of this is what the row asked about and none of it is new work.

## 6. STATE AT THE END

* `_selfseen_all.json`: **`ok: true`, `errors []`**, 62 rows. The panner row was
  **REPLACED row-by-row, never with `--out`**, which overwrites and would have
  destroyed the other 61 - the wholesale-wipe shape this file's carry rule
  exists to prevent. The other **61 rows were verified byte-identical** across
  the merge by hashing every row before and after: exactly one row changed.
  The new row carries its own `measured_at` and a `supersedes` string naming
  the old error.
* `_fit_report.json`: re-derived this run. **`ok: true`, `verdict: GREEN`,
  `errors []`**, 65 pairs, `unproved_cells []`, `blind_views []`,
  `stale_margin []`, `rows_unstamped []`, `red_summary.rows []`,
  `ok_shipped true`, blank check **189 files / 0 failures**.
  `self_seen`: `verdict GREEN`, **`instrument_errors []`** (it was carrying the
  panner error through), 61 measured bodies, 183 cells, `no_man ['panner']`,
  `uncovered []`, `uncensused []`, `build_failed []`.
* The derive reported **`rendered_this_run: 63`** and **not one of those 63
  PNGs changed a byte** - `git status` on the render directories is empty.
  The register's render path is reproducible, which is worth having measured.
