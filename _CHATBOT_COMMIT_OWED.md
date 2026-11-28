# LANDED 2026-11-28 ~10:52 CT (cycle B223). THE BRIDGE CAME BACK AND THIS FILE'S WORK IS COMMITTED.
# Everything below was written while there was NO GIT WRITE PATH (~03:00-10:4x CT). It is kept as the
# record of how the work was held, NOT as an outstanding debt. The stranded B221 `_with_hub` edit and
# the `short` keys are now on `origin/chatbot` with a REAL engine gate behind them: STAGE1 parse rc=0,
# L14_TEST OK (27 checks), COMMANDS_DOC OK wrote 40, docs/COMMANDS.md md5 501e9535 before and after.
# See `_b223_battery.log` and the B223 entry in PROGRESS.md. NOTHING IN THIS FILE IS STILL OWED.

# CHAT BOT - THE ONE OWED FILE. SINGLE NAME, NEWEST LINE AT THE TOP.
## 2026-11-28T09:50:11-06:00 - B222, SIXTH SEAT, NINTH HOUR. I CORRECTED THIS FILE'S OWN VERIFICATION SENTENCE,
## WHICH IS NOW FALSE, AND I PROVED THE GENERATED DOC IS NOT STALE INSTEAD OF ASSERTING IT.
**NO SOURCE EDIT THIS RUN. `scripts/chatcmd.gd` ab57f30e, `data/commands.json` 36a4f3fc,
`docs/COMMANDS.md` 501e9535 - all three byte-identical to B221's measurement. The delta to commit
is UNCHANGED. What changed is what is TRUE ABOUT IT in writing.**

### 1. THE CORRECTION, AND IT IS AGAINST THIS FILE: B217's SEMANTIC-DIFF SENTENCE IS NOW FALSE.
B217's section 2 (preserved below) reads: *"Semantic diff is EXACTLY 11 added `short` lines and
nothing else. No pre-existing key is altered, moved or reformatted."* **That was true at 04:45 and
it is NOT true of the delta a committing seat will now stage.** Measured this run by `json.load`
on both sides and a field-by-field compare against `chatbot:data/commands.json` (md5 **a065936a**,
the same before-image B216 and B217 used):

  **22 `short` changes, not 11. ELEVEN ADDED and ELEVEN PRE-EXISTING `short` VALUES MODIFIED.**
  Modified (each gains one trailing sentence, nothing else): `armoury, brew, dye, forge, party,
  repair, reroll, respec, satchel, specialize, wear` - all eleven gain `" On the hub too"`, nine of
  them with `", under <Shops|Gear|Hero|Party>"`. `satchel` gets the bare form.
  Added (B216's eleven): `deadliest, deepest, delve, fish, guild, help, inventory, memorial, oil,
  patrons, richest`.
  **STILL TRUE AND RE-MEASURED: no key added or removed (40 -> 40), `order` identical and still 40,
  `order` == the key set, every top-level key outside `commands` byte-identical, all 40 commands
  carry a `short` and all 40 carry an `example`, `json.load` clean.**
  **The eleven modifications are B219's 06:55 edit and they are the hub pointer, in the one field
  no gate reads** - which is exactly what B219 wrote down as "structurally ungatable". They are
  sound and nothing is to be reverted. THE DEFECT IS ONLY THE RECORD: a seat that verifies the
  staged diff against B217's sentence finds twice the changes it was promised and has to decide,
  with no help, whether the tree was tampered with. It was not. **Verify against THIS section.**

### 2. docs/COMMANDS.md 501e9535 IS NOT STALE, AND NOW FOR A MEASURED REASON.
B221 asserted no regeneration is owed because "the generator reads neither of the two things I
touched". True for B221's own edit, but it says nothing about B219's - which DID touch the data
file **after** B216's real generator run produced 501e9535. So the live question is whether the
committed doc still matches the data it is generated from, and the answer is yes, proven:
**GENERATOR-VISIBLE FIELD CHANGES AGAINST a065936a: ZERO.** `tools/_commands_doc.gd` reads
`what, aliases, args, cost, example, needs_hero, order, cooldown_s, twitch_cooldown_s`. All 22
changes are in `short`, and **nothing in `tools/` reads `short`** (B219's section 3, which I did
not re-derive from scratch but did re-check against the generator's own field list).
**NO REGENERATION IS OWED. Do not re-run COMMANDS_DOC to "be safe" - it would rewrite the same
bytes and cost the house a Godot slot it has not got.**

### 3. B221's `_with_hub` IS SOUND BY INSPECTION. STILL UNPARSED - THAT IS THE ONLY THING OWED.
B221 shipped it with the gate UNRUN and asked the next seat to parse it first. I cannot parse
(no bridge, ninth hour), so I audited the three ways it could be wrong and none of them is:
  - **Bound.** `_cut(body, REPLY_MAX - t.length()) + t` is at most `(440 - |t|) + |t| = 440`. `t`
    is `"  |  Full sheet: " + 49-char url` = 66, so the body budget is 374.
  - **It cannot be re-cut downstream.** `safe_line()` is length-NON-INCREASING - `_declaw` maps one
    character to one character, the `/`/`.` strip and `strip_edges` only shrink - so a 440-char
    `_with_hub` result reaches `_reply` untouched and `twitch_reply.emit` carries the whole URL.
  - **No-op when it fits, as the docblock claims:** `_cut` returns its input with no strip at all
    when `s.length() <= n`, so a short `!hero` is byte-identical to what it was before B221.
  - **No doubled tail:** `roster.describe()` contains no `hub`/`Full sheet` string, so
    `_with_hub(describe() + _dur_tail())` appends the pointer exactly once.
  **This is an inspection, NOT an engine gate. `chatcmd.gd` is still UNPARSED since B221 and the
  first act of whoever gets the bridge back is still a parse check.**

### 4. DRIFT, BOTH DIRECTIONS, AND MY OWN MATCHER WAS WRONG FIRST.
My first pass reported **13 published words with no dispatch arm** (`armor, commands, me, mend,
path, reputation, roads, sheet, spec, spotlight, stats, steel, watch`). **THAT WAS MY MATCHER, NOT
DRIFT, AND I CAUGHT IT BEFORE WRITING IT DOWN AS A FINDING.** `canonical()` runs at
`chatcmd.gd:156`, BEFORE the `match verb:` block, so an alias resolves to its key and never needs
an arm of its own. All 13 are aliases and all 13 resolve (`armor->armour`, `me/sheet/stats->hero`,
`mend->repair`, `path/roads->paths`, `reputation->rep`, `spec->specialize`, `spotlight/watch->look`,
`steel->weapon`, `commands->help`). **Zero of the 40 keys is missing an arm.**
Other direction: the only code-side verbs with no published entry are `testbits, testpoints,
testsub` - dev-only, deliberately unpublished, the documented B156 shape. **DRIFT IS ZERO.**

### 5. STATE OF THE HOUSE, MEASURED NOT REPEATED.
- **Bridge down a NINTH hour.** Two attempts, trivial `result={"alive":"yes"}`:
  `Cannot connect to Blender at localhost:9876.` Nothing listening. Same fault B217 first named.
- **Refs unmoved, by my own `ls-remote` from R:** `chatbot bbbc7439`, `main 1906a5d3`,
  `laptop ecad1a37` - byte-identical to the 04:58 through 08:45 measurements. No lane since 02:07.
- **`docs/RUN_LOCK.txt` last written 2026-11-28T02:56:06-06:00 (HUD U219)** - ~6h50m, no line from
  any of six lanes. House-wide. The lock is FREE and worth nothing without a bridge.
- **I DID NOT CLAIM THE LOCK and no lock line is owed.** There was nothing to launch.
- **THE MOUNT IS FLAT and the plan already says so** (`$HOME/mnt/bellmire-bot`,
  `$HOME/mnt/jests-hd-medieval-adventure`, no `hd adventure` parent). One `ls $HOME/mnt/` settled
  it and **I did not call `device_request_folder_access`.**
- **MY PROMPT'S QUEUE IS SPENT AND THE PLAN SAYS SO.** Its items 1 and 2 - make `!help` point at
  the hub, and the stale `_rank` docblock - are **both credited to B214 on `origin/main`**
  (WORK_PLAN.md:212-214). `help_line("")` already ends `"Manage your hero on the page: <url>"` at
  428 of 440. The live row (01:58 block, CHAT BOT 02:45) asked for the real gate and then the
  eleven `short`s: **both delivered, B216 green, B219 shipped.** Nothing in my three files is owed
  but the parse. So I audited my own shipped work, which the deadline directive allows outright.
- **NO Twitch message, nothing redeemed, nothing cheered, ZERO BITS.**

### 6. ADD TO THE COMMIT (unchanged from B221, restated so this section is the whole recipe):
`scripts/chatcmd.gd`, `data/commands.json`, `docs/COMMANDS.md`, `PROGRESS.md`,
`_b216_battery.log`, `_b221_verify.log`, this file - and `git rm` the four dated copies
(`_CHATBOT_COMMIT_OWED_nov28_0308.md`, `_0445`, `_0545`, `_0655`), which this shell cannot delete.

---
## 2026-11-28 08:45 CT - B221. FIFTH CYCLE WITH NO WRITE PATH. THE DELTA IS NOW FIVE COMMITS' WORTH.
**NEW THIS CYCLE, AND IT IS THE FIRST CODE CHANGE SINCE B219:** `scripts/chatcmd.gd` md5
**695102f0 -> ab57f30e** (294,389 -> 295,900 B). TWO hunks, nothing else - verified by `diff`
against a backup taken before the edit:
  1. `L185` `!hero` now calls `_with_hub(describe() + _dur_tail())` instead of appending
     `_hub_tail()` raw.
  2. NEW `static func _with_hub()` after `_hub_tail()` (L702-704) + its docblock.
**WHY:** the hub pointer sits at the TAIL, which is the first thing `safe_line()`'s `_cut`
discards - and `_cut` backtracks to a word boundary, so the WHOLE 49-char URL goes. `!hero` worst
case measured 504 against REPLY_MAX 440; a MODEST hero measured 434, **six characters of spare**.
`!hero` is one of the three commands directive sup-nov27-2340 KEEPS in chat, so the pointer that
must survive was the one being dropped. The fix is `_catchup`'s own shipped idiom (reserve the
tail, cut the body) applied to the one other site that can overflow. **Wording unchanged. No new
command, no new verb, no new surface.**
`data/commands.json` **36a4f3fc UNCHANGED** and `docs/COMMANDS.md` **501e9535 UNCHANGED** - the
generator reads neither of the two things I touched, so **NO regeneration is owed.**
**GATE: UNRUN.** Blender is not running (`computer_list_apps` -> isRunning false) so Godot cannot
be launched and `chatcmd.gd` is **UNPARSED**. `_b221_verify.log` (NEW, 4,014 B) is a string-budget
measurement and an emulation of the new helper against the real data - **not an engine gate.**
Whoever gets the bridge back: parse-check `chatcmd.gd` FIRST, then `!hero` on a live hero.
**ADD TO THE COMMIT:** `_b221_verify.log`.


**THIS FILE REPLACES THE FOUR DATED COPIES** (`_CHATBOT_COMMIT_OWED_nov28_0308.md`, `_0445`,
`_0545`, `_0655`). It is the whole commit recipe; nothing else needs reading. Per the team lead's
06:58 housekeeping row (6): keep exactly `_CHATBOT_COMMIT_OWED.md`, no date in the filename,
update IN PLACE with a dated line at the TOP. **The four dated files are left on disk on purpose -
this shell cannot delete, and the row says a half-deleted file is worse than a stale one. Whoever
gets the bridge back should `git rm` the four dated names in the same commit as this one.**

---
## 2026-11-28T07:45-06:00 - B220, FIFTH SEAT, SEVENTH HOUR. FOLDED THE FILE; AUDITED; NO SOURCE EDIT.
- **Bridge still down.** `Cannot connect to Blender at localhost:9876`. Refs unmoved a seventh hour,
  by my own `ls-remote` from R: `chatbot bbbc7439`, `main 1906a5d3`, `laptop ecad1a37` -
  byte-identical to the 04:58, 05:58 and 07:0x measurements. No lane has pushed since 02:07 CT.
- **I DID THE ROWED ITEM: this file.** The 06:58 row's CHAT BOT line is "B219 stands; fold the owed
  file to the single name (6)". Done, and B219's delta is untouched.
- **NO EDIT TO `data/commands.json` OR `scripts/chatcmd.gd` THIS RUN.** The delta to commit is still
  exactly B219's. Nothing was owed and the audit found nothing to fix - see below.
- **QUEUE ITEM 2's NAMED ITEM IS ALREADY DONE AND I DID NOT "FIX" CORRECT CODE.** My prompt still
  says the `_rank` docblock claims the ladder "is NOT on `origin/main`". **It does not** - B214
  corrected it (`chatcmd.gd:588-598`) and B217 reported so. I verified the *substance* from
  `origin/main` itself rather than trusting either: `git show origin/main:scripts/roster.gd` carries
  `letter_score()` at **1392**, `letter_rank()` at **1408**, `letter_next()` at **1412**, exactly as
  the corrected paragraph states. **Nothing owed. The prompt's queue item 2 is spent.**
- **AUDIT OF MY OWN SHIPPED DATA - `_b220_audit.log`, all 40 commands, five checks never run here
  before. EVERYTHING CLEAN:**
  - `example` verb resolves to its own command through `canonical()`: **all 40 OK**. (A broken
    example tells a viewer to type a command that does not exist; nothing in `tools/` checks it.)
  - `example` against the `args` spec: **all 40 consistent** - no command with `args` shows an
    argument-free example, none with empty `args` passes one.
  - `short` grounded in its own `what`: **every section name a `short` names is present in that
    command's `what`**; no `short` mentions the hub where `what` does not; **no `short` states a
    number absent from `what`/`cost`** - so no numeric drift arm has a second authority to disagree.
  - alias table: **41 aliases over 40 commands, ZERO collisions**, no alias shadows a command name.
  - `!help <cmd>` over all 40 vs budget 440: **none over**; worst `repair` **251** (189 spare), then
    `forge` 209, `party` 180, `wear` 166, `armoury` 164. Bare `!help` **428 of 440, headroom 12,
    unchanged**. This is the whole check that exists - `help_line()` is pure string formatting.
- **MY MATCHER OVER-REACHED ONCE AND I PROVED IT WRONG BEFORE REPORTING A NUMBER.** Pass 1 required
  a dispatch arm for every command *and every alias*, and listed **14 aliases as unrouted** -
  `mend`, `armor`, `sheet`, `stats`, `spec`, `standing`... **That would have libelled 14 live
  aliases.** It is wrong because **`canonical()` runs at `chatcmd.gd:156` - `var verb := canonical(...)`
  - BEFORE `match verb`**, so an alias is folded to the command name and never needs an arm.
  Corrected: **COMMAND NAME with no dispatch arm: none, all 40 route.** Fifth seat running to get
  this matcher wrong first; the sanity assertion (it must see every known-live verb before I trust
  either direction) is again what caught it.
- **ONE STRUCTURAL NOTE WORTH A LINE, NOT A CHANGE:** 27 match-arm keys are *documented aliases*
  (`inv`, `bag`, `items`, `parties`, `ranked`, `ladder`, `alone`...) and are therefore
  **unreachable** - `canonical()` folds them first. Benign redundancy, and the data file is the
  single source of truth. Worth knowing before anyone "tidies" either side: removing an arm key
  changes nothing, but removing an alias from the data file stops `!help` documenting it while the
  arm key keeps it live. **No edit made.**
- **DRIFT BOTH DIRECTIONS, CLEAN.** Arm with no entry: **`testbits`/`testpoints`/`testsub` only** -
  the L17 test-only arms gated to `local_*` ids (`chatcmd.gd:250`), unpublished by design.
  (`testsub` is the sanctioned **synthetic** path for a sub event - no real purchase is ever needed.)
  `json.load` clean, 40 commands / 40 `order`, key order identical, all 40 carry `short` + `example`.
- **NEVER CLAIMED THE GODOT LOCK, NEVER LAUNCHED GODOT** - the 06:58 row forbids a claim while the
  bridge is down ("Godot cannot start, so a claim is a false claim"). **No lock line is owed.**
- **NO Twitch message, nothing redeemed, nothing cheered, ZERO BITS, no account touched.**
- Mount is **FLAT** (`$HOME/mnt/bellmire-bot`, `$HOME/mnt/jests-hd-medieval-adventure`). **I did NOT
  call `device_request_folder_access`.**

---
## THE COMMIT, WHEN THE BRIDGE RETURNS - FOUR COMMITS, ONE GIT OP PER BLENDER CALL
**NEVER `-F -`** (B216 hung the bridge that way: `-F -` reads stdin and blocks forever).
**Always `-F <file>` with `stdin=subprocess.DEVNULL`.** Verify state before retrying any op - a
Blender call that times out at ~80 s has very often already succeeded.

1. `_scratch/b216_msg1.txt` - **the owed gate** (B216). Files: `_b216_battery.log`, `PROGRESS.md`.
2. `_scratch/b216_msg2.txt` - **the eleven missing `short` fields** (B216). File: `data/commands.json`.
3. **B219** - the eleven hub-action clauses + `_b219_verify.log`. No message file pre-written:
   compose it from B219's own scope note below, in your own words.
4. **B220** - `_CHATBOT_COMMIT_OWED.md`, `_b220_audit.log`, `PROGRESS.md`, and **`git rm` the four
   dated `_CHATBOT_COMMIT_OWED_nov28_*.md` names**.

`docs/COMMANDS.md` is **unchanged at md5 `501e9535`** and needs no add. `scripts/chatcmd.gd` is
**untouched** by B217, B218, B219 and B220.

## THE DELTA ON DISK, RE-MEASURED BY ME AT 07:45 (FIFTH SEAT, NOT QUOTED)
| thing | measured | prior claim |
|---|---|---|
| `data/commands.json` md5 / bytes | **36a4f3fc** / **27867** | B219 - matches |
| `docs/COMMANDS.md` md5 | **501e9535** | B216/B219 - matches |
| `scripts/chatcmd.gd` md5 | `695102f0` | untouched since B214 |
| commands / order / short / example | 40 / 40 / all / all | matches |

## WHAT IS PROVEN AND MUST NOT BE RE-RUN
**B216's gate is GREEN and recorded** (`_b216_battery.log`): STAGE1 parse rc=0,
**`L14_TEST OK (27 checks)`**, **`COMMANDS_DOC OK wrote 40 commands`** rewriting `docs/COMMANDS.md`
to **md5 `501e9535`** - byte-identical to B215's emulation, so **B215's emulation caveat is
discharged**. `DYE COLOURS GHOST` fires **zero** times. **DO NOT RE-RUN THAT GATE.**

**AND `short` IS STRUCTURALLY UNGATABLE, PERMANENTLY** (B219's correction of B216, re-confirmed by
me): **nothing in `tools/` reads `short` at all.** `_commands_doc.gd` reads
what/aliases/args/cost/example/needs_hero/order/cooldowns; `_l14_test.gd` reads
aliases/args/cost/example/needs_hero/what; its single REPLY_MAX help arm (`:217`) tests the **bare**
`!help` line, built from `order` + `hub_url()`, which never touches `short`. So a `short` edit is
**never** "awaiting the real gate" - a Python measurement of `help_line()` is the entire check that
will ever exist. (This is also why eleven added `short` fields left `docs/COMMANDS.md` byte-identical.)

## B219's SCOPE, FOR COMMIT 3's MESSAGE
Eleven `short` values in `data/commands.json`, nothing else. Clause by group, section names lifted
from each command's own `what` (already published in `docs/COMMANDS.md`, not invented):
`forge, armoury, brew, repair` -> " On the hub too, under Shops." | `wear, dye` -> "...under Gear."
| `reroll, respec, specialize` -> "...under Hero." | `party` -> "...under Party." | `satchel` ->
" On the hub too." (its `what` names no section, so nor does its clause).

**WHY ELEVEN AND NOT THE SIXTEEN THREE SEATS PROPOSED** - the sixteen are not one set. **(a) a
viewer ACTION the hub does instead of chat** = the eleven above, the 23:40 directive's own verbs.
**(b) a RECORD TO READ, not an action** = `catchup`, `caravan` (**a world event, not a viewer action
at all**), `town`, `bestiary`, `miniboss`. The standing rule is "if a viewer **action** can be done
on the hub, it SHOULD be"; it does not reach a lookup, and a `!help` line is read in one second on
stream. **Those five are left alone deliberately** - I re-measured the split this run and it still
reads that way: **17 commands name the hub in `what`, 12 of them in `short`, the remaining five are
exactly those five.** If the team lead wants them too it is one more pass over the same field.

## STILL FOR THE TEAM LEAD, ROUTED NOT TAKEN (THREE SEATS NOW)
**There is no L14 arm covering the per-command `!help <cmd>` line's length** - only the bare list at
`_l14_test.gd:217`. That is the widest ungated surface this lane publishes, and it would have covered
B219's edit and this run's audit. **The gap is in `tools/`, which is NOT this lane's.** An arm looping
`help_line(k)` over `order` against `REPLY_MAX` closes it in a few lines. **B220 adds: the same arm
could also assert each `example` resolves through `canonical()` to its own command** - I checked all
40 by hand this run and they pass, but nothing in `tools/` would catch it if one stopped.

## WHAT MR. E HAS TO DO - UNCHANGED, AND HE HAS BEEN PINGED FIVE TIMES ALREADY
**Open Blender on cruzader and start the MCP addon server on 9876.** The device itself reports
"Blender 5.2", `isRunning: FALSE` (team lead, 06:58) - nothing is misconfigured, no repo is broken,
no lane is at fault. **I SENT NO NOTIFICATION THIS RUN**: the 06:58 row says nobody sends a sixth
unless there is something genuinely new that only he can act on, and there is not.
