# CHAT BOT - B75 STAND-DOWN - 2026-11-20 04:45 CT firing

Written as a NEW FILE because in-place modification of a tracked source file is refused in this
lane, and the 03:58 TAKE THIS NEXT row established that a new file is the door that is open.
Committed through the Blender bridge, which is this lane's standard for git.

## WHAT I ATTEMPTED, ONCE, AT THE TOP OF THE RUN
The 03:58 row's item, unchanged since 02:58: insert into `tools/_l14_test.gd`, immediately before
the single occurrence of `\t# B22 (B21 Faults 3+4): the count is printed`:

```gdscript
	var faults: Array[String] = ChatCmd.guard_faults()
	_ok(faults.is_empty(), "ChatCmd.guard_faults() is empty (faults: %s)" % [faults])
```

(with B74's three comment lines above it; the file is TAB-indented, unlike chatcmd.gd which is
4-space.) Anchor re-verified present exactly once this hour. Placement is after
`ChatCmd.commands()` at line 16 of `_initialize()`, which is what repopulates `_guard_faults`.

## OUTCOME: REFUSED A FOURTH TIME
> Permission for this action was denied by the Claude Code auto mode classifier.
> Reason: [Destructive or Unwanted Actions].

Attempted exactly once, as the row instructed. B72, B73, B74 and now B75: four consecutive
firings unable to write a tracked source file on cruzader. The refusal names the **auto mode
classifier**, not a folder grant and not a device permission - it travels with the firing, not
with the machine.

I did NOT land the patch through the Blender bridge. That standard was set at B72 and the 03:58
row restates it ("do not route around the refusal"). The bridge is used here only for what the
prompt already makes it the standard for: git and the Godot launch.

## WHAT THIS COSTS, SAID PLAINLY
The `ChatCmd.guard_faults()` family - **91 `_guard_faults.append` arms** in `scripts/chatcmd.gd` -
has been decorative to a harness since B49. `grep -rn guard_faults tools/` is still **zero hits**.
B71 planted a real fault (`beadle` -> `zzz_fake_trade`), got two `push_error`s, and the battery
still exited **rc=0**. A `push_error` cannot move an exit status; the two-line `_ok()` above can.
The red proof that takes that same mutation to rc=1 is owed and is also a tracked-file edit, so it
is blocked behind the same gate.

## READ-ONLY AUDIT, ALL RE-MEASURED THIS HOUR
- `data/commands.json` parses. **31 commands, 29 aliases.** Top-level keys: `_source, ask,
  commands, cooldown_s, foreign, hub_url, order, twitch_cooldown_s`.
- `docs/COMMANDS.md` 7080 bytes. **Doc drift ZERO in the data->doc direction**: every one of the
  31 commands appears as `` `!cmd` ``.
- **Verb drift ZERO in both directions.** 71 verb tokens in ChatCmd's match block, **56 unique**;
  3 are the deliberate `!test*` local-only hooks (L17); every remaining verb canonicalises into
  the data, and every data command is answered by a verb or one of its aliases.
- **91 guard arms** in chatcmd.gd - the team lead's corrected figure, unchanged.
- The prompt's `_commands_doc.gd` figure of 26 commands remains stale; it is **31**. A firing
  cannot edit its own prompt.

## MY OWN INSTRUMENT WAS WRONG FIRST, SECOND HOUR RUNNING, IN THE SAME PLACE
My first drift probe reported **28 verbs in code with no data entry** - `inv`, `bag`, `items`,
`party`, `lamp`, `sell`, `beasts` and twenty more. That would have been a catastrophic live drift.
It was my own fault twice over: I scraped a `canonical()` alias map out of chatcmd.gd with a bare
`"a": "b"` regex (which matches unrelated dictionary literals and misses the real mechanism), and
I counted duplicate verb tokens as distinct verbs. `ChatCmd.canonical()` at chatcmd.gd:2398 does
not read a map in code at all - it reads each command's `aliases` array **out of the data**, then
retries after trimming one or two trailing plural characters. Emulating what the function
actually does takes the missing set to EMPTY and the unique count to 56, which agrees with B74.
B74's lesson was that an instrument that FINDS something is no more proof than one that finds
nothing. I hit the same wall one hour later from the other side. Dump the mechanism, do not
pattern-match it.

## GATES
See the firing's summary for the battery run and its verdict lines. No owned file was edited this
hour, so any green battery is a GREEN-ONLY REGRESSION READ and not a gate on new work.

## TWITCH
No live test. No account used, **0 bits**, nothing redeemed, nothing posted, no channel state
touched.

## FOR THE GAME BUILD LANE
Nothing. `twitch_eventsub.gd` untouched; `twitch_reply(user_login, text)` unchanged.

## FOR MR. E - THE ONE DECISION BLOCKING THIS LANE
Four consecutive chat-bot firings cannot write a tracked source file. Reads work, new files land,
the Blender bridge works. The patch is two live lines plus three comments and is verified against
the real file at the real anchor. The lane cannot ship until a firing is permitted that write, or
until a live turn pastes it in.

## BATTERY ACTUALLY RUN THIS HOUR - GREEN-ONLY, AND LABELLED AS SUCH
Lock claimed `RUNNING 2026-11-20T04:49:00-06:00`, cap 05:14, declared finish 04:58. Lock was free
(last line `IDLE 2026-11-20T04:18:23-06:00 ... (game build)`) and **no Godot process was alive** -
checked by process, not by the file alone.

- `--headless --path W6 --quit-after 300` -> **rc=0, ZERO ERROR lines.** Warnings only, and they
  are not mine: `assets/kit/materials/*.tres` ext_resource invalid-UID fallbacks raised from
  `town.gd:826`.
- `tools/_l14_test.gd` -> **L14_TEST OK (22 checks)**, rc=0. Drift zero both directions in the
  engine's own words: `missing []`, `unanswered []`.
- `tools/_commands_doc.gd` -> **COMMANDS_DOC OK wrote 31 commands**, rc=0, and
  `git status docs/COMMANDS.md` is **CLEAN afterwards** - the generator is a true no-op against the
  committed bytes. The prompt's "26 commands" expectation is stale; **31** is the generator's own
  figure and the data's.
- `tools/_twitch_parse.gd` -> **TWITCH_PARSE OK (8 checks)**, rc=0.

**NO RED ARM. THIS IS A GREEN-ONLY READ AND IT CANNOT TELL A WORKING GATE FROM A SLEEPING ONE.**
The red proof this lane owes - `beadle` -> `zzz_fake_trade` - is a tracked-file edit and is behind
the same refusal as the patch. Nobody should read these four verdicts as evidence the guard family
works; B71 already measured that a planted fault leaves this exact battery at rc=0.

## ONE PRECISION ON A NUMBER TWO CYCLES HAVE NOW PRINTED DIFFERENTLY
`L14_TEST` prints **71 verbs**; B74 and my own audit say **56**. Both are right and they count
different things: the test appends every token of every match-block key, so a verb listed in two
arms (`inv`, `bag`, `items`, `armory`, `lamp`, `torch`) is counted twice - 71 TOKENS, **56
UNIQUE**. The `verbs.size() >= 20` bar is a token bar. Not a fault; a figure that needs its unit
said out loud so a later seat does not report a 15-verb drift that is not there.
