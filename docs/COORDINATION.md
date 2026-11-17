# Bellmire HD - machine & coordination contract (SINGLE SOURCE OF TRUTH)
Updated 2026-11-12 by the supervisor. Every build/supervisor run and every pasted brief follows this.
If a brief and this file disagree, THIS FILE WINS - and the brief gets fixed.

## 1. Machines, repos, paths (NEVER hardcode another machine's path)
| Role        | Device     | Repo path                                        | Branch           | Godot |
|-------------|------------|--------------------------------------------------|------------------|-------|
| Desktop     | CruzaderPC | C:\hd adventure\jests-hd-medieval-adventure       | main             | D:\1game\Godot_v4.7.2-stable_win64_console.exe |
| Laptop      | jestai     | C:\Users\Jestsayin96\Project1\Bellmire-HD-stream  | laptop           | the laptop's OWN Godot install (the laptop run knows its path) |
| Hub         | CruzaderPC | C:\hd adventure\bellmire-hub (worktree)           | hub              | n/a - static web, no Godot |
| Supervisor  | CruzaderPC | C:\hd adventure\jests-hd-medieval-adventure       | merges laptop->main | as desktop |
The laptop is jestai, NOT CruzaderPC. A brief to the laptop uses the laptop row only.

## 2. Item numbers (docs/WORK_PLAN.md) - FROZEN once assigned
- The supervisor owns the IDs. An ID is assigned ONCE and is NEVER renumbered after any work has shipped under it.
- If two machines would collide on a number, the NEW/unshipped item gets the suffix; the already-committed one keeps its number.
- Splitting an item (e.g. L25 -> L25a..d) is allowed ONLY with a CHANGELOG line saying what changed; the old ID still resolves (L25 = all its sub-items). Never silently resend a changed brief - say what's new or don't resend.

## 3. PROGRESS.md cycles - per-machine prefix, no shared counter
- Prefix every cycle by machine: desktop "D-cycle N", laptop "L-cycle N", hub "H-cycle N". Counters are per-prefix, so machines never collide. On a merge, keep BOTH sides.

## 4. Tests - UI/visual tests run WINDOWED
- Headless Godot gives a 100x100 window; UI/HUD/panel tests cannot fit and will FALSE-FAIL. Run any UI/visual test WINDOWED, or use the pinned-size variant (e.g. the pinned size now in _l21_test). NEVER call a merge or item broken from a headless UI test. Headless is only for parse checks and non-UI logic tests.

## 5. Merges & the class cache - don't break the other machine
- When a commit/merge adds a NEW class_name script (e.g. TwitchEventSub, SnapshotPublisher), the other machine hangs on a manual --import. The committer MUST either:
  (a) run --headless --import and COMMIT the regenerated .godot/global_script_class_cache.cfg with the change (preferred), OR
  (b) list the new class_name(s) prominently in the commit/merge message so the other run imports deliberately.

## 6. Work-in-progress - commit to your branch, NEVER stash
- "Commit only when the test passes" governs exactly TWO things: TICKING an item in WORK_PLAN, and the SUPERVISOR MERGING a commit into main. It does NOT block saving progress.
- Save WIP by COMMITTING to your OWN branch (laptop/hub) with a "WIP:" prefix and the item left UNTICKED. This is correct and expected. NEVER git stash (stashes are lost across fresh runs). The supervisor merges only commits whose item is ticked + tests pass, and skips "WIP:" commits.

## 7. Outward / public actions - gated on Mr. E
- Hub gh-pages republish: supervisor security-reviews, then HOLDS for Mr. E's explicit go (he can switch it back to auto). First Pages enable, spending, anything first-published under his name, OAuth tokens/secrets, and destructive/irreversible actions are always his.

## 8. Supervisor answers to the desktop's questions (Nov 12, 16:30)

1. FILE OVERLAP from the L28b-d + L26a merges: NONE on the town side. Files touched:
   scripts/{bestiary,delve,dungeon_hd,dungeon_parts,floorgen,monster,spotlight,rts_camera}.gd,
   data/biomes.json, NEW assets/dungeon_look/* (decals) and NEW assets/shaders/dungeon_kit.gdshader
   (dungeon kit only). NOT touched: daylight.gd, valley.gd, town.gd, Town.tscn, any
   WorldEnvironment/.tres, any shared shader. One awareness note for D19b: the spotlight panes give
   their PANE cameras a per-floor dungeon Environment via DungeonHD.env_at (spotlight.gd, the
   _lane_env block) - the main/town Environment is untouched, but if D19b swaps or animates the
   town Environment, read that block first so panes framing town subjects stay consistent.

2. LOCK CADENCE: keep FIRST-COME-FIRST-SERVED on docs/RUN_LOCK.txt - today's 16:09 skip was the
   system working, not failing. Two refinements: (a) the supervisor will not TAKE the lock in the
   5 minutes before :08 or :38; (b) a running interactive Godot game process (Mr. E playing)
   counts as the lock held by Mr. E - nobody starts a headless run while one is up (tasklist check).

3. SNAPSHOT PAYLOAD - APPROVED by Mr. E (relayed 16:24): snapshot_pub.gd adds, additively,
   hero.max_hp, hero.xp_next, and a numeric town.raids_turned. The hub already renders all three
   forward-compatibly with NO page change (HP/XP become true gauges, the strip grows a
   "Raids turned back" pill). Bundle into the next desktop item. When D19b lands, also add
   town.day_phase and town.weather (additive; payload v stays "1"; the hub ignores them until a
   hub item uses them). Never remove or rename an existing field without a version bump.

4. HUB PHASE 3 RLS: the supervisor drafts the RLS design doc; Mr. E approves it; NO viewer write
   path ships before the approved design. It becomes a WORK_PLAN item only when Mr. E green-lights
   Phase 3 - not queued yet.

5. D23 FROZEN: the 120 FPS soak average is measured in the stream's REAL resting state - snapshot
   publisher running, Twitch chat connected (or a simulated feed), and once L32 lands, the
   spotlight 2x2 grid UP. A soak without those is not a valid D23 pass.

## 9. Housekeeping answers (Nov 12, 16:50)

1. The stray RUN_LOCK.txt at the repo ROOT was the supervisor's own early artifact - DEAD and now
   deleted. docs/RUN_LOCK.txt is the one and only lock. If a root RUN_LOCK.txt ever reappears,
   delete it; never read it.

2. .uid FILES: the repo tracks tools/*.gd.uid deliberately (commit 3e0e5af) - do NOT gitignore
   them. The rule: WHOEVER COMMITS A SCRIPT COMMITS ITS .uid IN THE SAME COMMIT. The laptop owes
   the .uids for its L25/L26/L28 tools (_l25_measure/_l25_shot/_l25_test, _l26_anims,
   _l28_alike/_l28_decals/_l28_fps/_l28_matcount/_l28_shot) - laptop: commit them on your next
   cycle. Until then, untracked .uid regenerations on another machine are NOISE - delete them
   freely (the supervisor already does before merges); do not commit another machine's .uids.

## 10. The CONTENT writer (laptop, branch `content`) - added Nov 12 22:45

A fourth worker: a plain Claude chat on the laptop that writes DATA and LORE only. It NEVER runs
Godot, so it cannot collide with the laptop's Claude Code session over the .godot import cache.

| Role    | Device | Branch    | Runs Godot |
|---------|--------|-----------|------------|
| Content | jestai | `content` | NEVER      |

OWNS (and nobody else edits these while it is working):
  data/items.json      - accessories, cosmetics, dyes, dye_cost (the gear/cosmetic catalogue)
  data/lore_lines.json - tells, descend, cleared, lord_intros, unique_intros, barks, epitaphs
  data/potions.json    - brews and states
  data/fishing.json    - catches
  data/bosses.json     - lesser/greater/draw/rule variants (rare uniques, NOT new lords)
  data/ranks.json, data/origins.json - flavour and titles

MUST NOT TOUCH: any .gd script, .tscn, .godot/, assets/, web/, and specifically
  data/strains.json  (the laptop is working L27b in it right now)
  data/biomes.json   (dungeon look, L28)
  data/world.json, data/classes.json, data/commands.json (tied tightly to code paths)

RULES: work in a SEPARATE clone or git worktree on the laptop, on branch `content` - never the same
working folder as the laptop's Claude Code session. Follow the LORE RULE (read the reference; do not
invent against canon). Keep each file's existing shape and key names exactly - additive only; never
rename or remove a key, because the .gd loaders read them. Validate before committing: a short Python
script that json.load()s every file it touched and checks the new entries carry the same fields as the
existing ones (python only - no Godot). Commit to `content` and push; the supervisor merges it to main
and runs the Godot battery - authoring is parallel, TESTING IS STILL THE SUPERVISOR'S GATE.

IDs: the content writer's items are the C-block (C1, C2, ...), assigned by the supervisor, and its
PROGRESS entries are prefixed "C-cycle N" (per section 3).


## 11. FOUR WORKERS (Mr. E, Nov 13 2026) - ownership is now split four ways

IDs stay FROZEN. Nothing is renumbered. What changes is WHO OWNS WHICH FILES. The laptop previously
owned the dungeon AND every UI file, which is why every HUD complaint Mr. E raised sat unstarted
behind dungeon work. The UI files move to a new worker.

### 11.1 The four workers

| # | Worker | Machine | Branch / tree | Owns |
|---|--------|---------|---------------|------|
| 1 | DESKTOP BUILD (scheduled :08) | CruzaderPC | main, in R | town/world/audio/visuals |
| 2 | DESKTOP HUD (new chat) | CruzaderPC | `hud-ui`, worktree W2 | the 7 UI files |
| 3 | LAPTOP CODE (Claude Code) | jestai | `laptop` | dungeon/combat/heroes |
| 4 | LAPTOP CONTENT (Claude chat) | jestai | `content` | 4 data files, never runs Godot |

R  = C:\hd adventure\jests-hd-medieval-adventure
W2 = C:\hd adventure\bellmire-hud      (git -C R worktree add -B hud-ui W2 origin/main)

### 11.2 File ownership - EXCLUSIVE. Touching another worker's file is a defect, not a shortcut.

DESKTOP BUILD: town.gd, townsfolk.gd, town_nav.gd, spells.gd, raids.gd, daylight.gd, sfx.gd,
  valley.gd, cavalry.gd, animal.gd, notables.gd, economy.gd, hero_body.gd, rig.gd, Town.tscn.

DESKTOP HUD: hud_dock.gd, spotlight.gd, auto_director.gd, dice.gd, feed_hud.gd,
  leaderboard_panel.gd, ui_theme.gd - and nothing else. These seven have no overlap with town or
  dungeon logic, which is what makes a fourth worker safe.

LAPTOP CODE: floorgen.gd, dungeon_parts.gd, dungeon_hd.gd, bestiary.gd, monster.gd, gear.gd,
  roster.gd, chatcmd.gd, delve.gd, Dungeon.tscn, and data/ EXCEPT the four content files below.

LAPTOP CONTENT: data/items.json, data/lore_lines.json, data/bosses.json, data/potions.json ONLY.
  (Previously both laptop workers were told they owned data/* - that was a collision. This splits it.)

HUB: web/* and docs/HUB_SECURITY.md. Unchanged.

### 11.3 THE GODOT LOCK IS SHARED BY BOTH DESKTOP WORKERS - THIS ONE IS NOT OPTIONAL

Workers 1 and 2 are on the SAME machine and both launch Godot. Two Godot instances at once already
cost us a corrupted run. Both MUST use docs/RUN_LOCK.txt (canonical, in R, on main):
  - TIMESTAMP FORMAT IS BINDING: ISO 8601 with the UTC offset, e.g. 2026-11-15T02:41:00-06:00.
    NEVER write a bare "local time" and never write UTC without its offset. A lock line that does
    not carry an offset cannot be aged reliably - workers run in a cloud session whose own clock is
    UTC while the machine is America/Chicago, so a bare timestamp has been off by six hours in
    practice (seen 2026-11-15: the lock read 08:41 when the machine clock said 02:41).
  - Before launching Godot: read it. If it says RUNNING and the timestamp is under 45 min old, do
    NOT launch. Do file-only work or stop and say "skipped: another run is working".
  - REFRESH THE LOCK ON EVERY RELAUNCH. If your item runs Godot more than once - a second soak,
    a retry, a re-run after a fix - write a NEW RUNNING line with a fresh timestamp each time.
    Observed 2026-11-15 16:31: the HUD worker's 30-minute director soak finished and relaunched
    without touching the lock, so a live run was sitting behind a 42-minute-old RUNNING line and
    was three minutes from being cleared as stale by anyone applying the 45-minute rule. A long
    item is a sequence of runs, not one; the lock must say so.
  - BEFORE CLEARING ANY LOCK ON AGE, CHECK FOR A LIVE GODOT PROCESS FIRST. A running
    Godot_v4.7.2 process whose --path points at a worktree means someone is working, whatever the
    lock's timestamp says. The process is the ground truth; the lock line is only a claim.
  - IF THE LOCK LINE HAS NO OFFSET, its age is UNKNOWN. Do NOT clear it on age alone and do NOT
    treat it as fresh. Check whether a Godot process is actually alive and whether a commit has
    landed since; only then decide. Rewrite the line in the format above once you own the lock.
  - Set "RUNNING <ISO 8601 with offset> (<worker name>)" before launching, and
    "IDLE <ISO 8601 with offset> - <what>" after.
  - Never start a second battery while any thread of a previous one may still be alive.
  - If Mr. E is at the machine, say so before launching Godot - he may be playing or streaming.

#### 11.3a THE HOUR IS DIVIDED - FOUR GODOT LANES, WRITTEN WINDOWS (Mr. E, 2026-11-16 10:24, "okay
#### so fix them"). BINDING ON EVERY LANE. Mirrored in docs/WORK_PLAN.md above TAKE THIS NEXT.

The fleet grew to FOUR lanes that launch Godot and the lock became the bottleneck rather than the
work. Observed, and it is why this exists: the CHAT BOT lane was starved of the engine for FIVE
CONSECUTIVE SLOTS and could not tick two written items for want of a parse run; and the GAME BUILD
twice fired on top of its own still-running session, so a 09:31 battery was alive at 10:08 and the
firing that arrived then stood down and did nothing. Four lanes sharing one engine with no windows
is a fleet fault, not a lane's.

  :07-:40   GAME BUILD. No single Godot claim over 25 MINUTES. HARD RELEASE AT :40.
  :45       CHAT BOT. A PROTECTED ENGINE WINDOW - short gates, a few minutes. No other lane queues
            a battery into it.
  :52-:07   HUD. No single claim over 15 MINUTES. HARD RELEASE AT :07. A long capture is SPLIT
            across firings, with the running total recorded in PROGRESS.md.
  ART takes the lock only to PROVE FIT, which is short, and fits in any gap.

  - EVERY CLAIM NAMES ITS EXPECTED FINISH, in the RUN_LOCK line itself:
      RUNNING 2026-11-16T10:07:00-06:00 (game build D91d, expected finish 10:32)
  - A JOB TOO LONG FOR ITS WINDOW IS SPLIT ACROSS RUNS with a checkpoint commit. It is never run
    over. A battery already in flight is NOT chopped - nobody interrupts a 20-minute soak - but no
    lane STARTS one it cannot finish inside its own window, and the IDLE line is written the moment
    the battery it is already in finishes.
  - ONE DEAD GODOT POLL IS NOT A RELEASED LOCK. A lane running short batteries with gaps looks dead
    between them and is not. Check the process more than once, and check it again immediately
    before writing a clear line. VERIFY BEFORE YOU ACT CUTS BOTH WAYS.
  - The supervisor reports every run who held the lock, for how long, and who overran their window.
    TWO OVERRUNS RUNNING goes to NEEDS MR. E rather than being quietly absorbed.


**THE FUTURE-STAMP DEFECT (supervisor, 2026-11-16 13:58 CT).** A RUN_LOCK stamp must be read off
the machine clock, in real Central Time with the offset. The chat bot lane wrote three lines this hour
(14:02 RUNNING, 14:08 RUNNING, 14:22 IDLE) while the wall clock was 13:59 - seventeen to twenty-seven
minutes in the future. The protocol's safety valve is clearing a lock ON AGE, and an age computed from a
future stamp is NEGATIVE: a dead lock looks live and a live one looks immortal. Never compute a stamp from
an assumed slot time. And BEFORE CLEARING ANY LOCK ON AGE, CHECK FOR A LIVE GODOT PROCESS - the process is
ground truth; a stamp is only a claim about one.

**FOURTH HOUR THE WINDOWS HELD, AND TWO HOUSEKEEPING FAULTS (supervisor, 2026-11-16 14:58 CT).**
The record for 13:00-15:00 CT: game build 13:13-13:35 (22 min, D91f, inside :07-:40 and inside 25
min) and 14:09:09-14:15:03 (6 min, D91 landing + two W-LIVE listener runs); chat bot 14:48:16-
14:56:50 (8 min); HUD claimed 14:58:47 with a named finish of 15:05. NOBODY STARVED AND NOBODY HIT
A HARD RELEASE. The future-stamp defect above is FIXED - every chat bot stamp this hour was real CT
read off the machine. Two faults, both housekeeping, neither an overrun:
  1. A :45 CLAIM MAY NOT NAME A FINISH PAST :52. The chat bot claimed at 14:48 and named 14:58,
     which reaches five minutes into the HUD's window. Declaring a crossing is the correct shape
     for a job already in flight, but a job that CANNOT finish inside the window is SPLIT with a
     checkpoint commit before it starts, not declared past the boundary at claim time. The HUD got
     its slot at 14:58:47, so nothing was lost this time.
  2. START EVERY CLAIM ON ITS OWN LINE. The 13:10:07 game build claim was appended to the end of
     the 12:56:21 IDLE line, so one physical line reads as both an IDLE and a RUNNING. A lane that
     greps the last line of that file gets a wrong answer. If the file does not end in a newline,
     write one before the claim.

### 11.3d LOCK LEDGER - HOUR OF 17:00-18:00 CT, 16 Nov 2026 (supervisor)

SIXTH CONSECUTIVE HOUR THE WINDOWS HELD. No overrun, no starvation, no future stamp, no hard
release approached. Clock read off the machine at 18:02:02 CT before writing this.
  GAME BUILD (:07-:40, 25 min cap): claimed 17:11:26-06:00 (expected finish 17:29), re-claimed
    17:18:50-06:00 after a roster.gd dye-reply fix (expected 17:27), IDLE 17:23:31. TWELVE minutes
    inside a twenty-five minute window, both finishes named on their own lines in real CT.
  CHAT BOT (:45, protected, ends :52): TOOK NO LOCK AND LAUNCHED NO GODOT. Its slot opened at 17:46
    against a :52 boundary; it judged six minutes is not a battery, shipped a file-only checkpoint
    commit (bd9fd83), left :45-:52 free and the HUD lane's :52-:07 untouched, and wrote a NOTE in
    RUN_LOCK saying so with the clock read off the machine. Gates named for 18:45.
    THIS IS THE DIRECT CORRECTION TO ITS OWN 16:57:40 FAULT, made inside one slot by the lane that
    made it. The cross-boundary claim logged at 11.3c is NOT a second occurrence; nothing escalates.
  HUD (:52-:07, 15 min cap): read RUN_LOCK at 17:52, confirmed no Godot alive by tasklist, took
    nothing and launched nothing (file-only stand-down, 23e1dbb). Its window was free this hour.
  ART: took no lock this hour - its conversion work needs none until a fit proof.
  CONTENT, HUB: need no lock; data- and web-only.
  SUPERVISOR: took NO lock and ran NO Godot. Merges and doc syncs only.
NO LIVE TWITCH TEST ON ANY LANE: 0 bits, nothing cheered, nothing redeemed, no reward created,
renamed, re-priced or deleted, nothing posted as any account, no channel setting touched.


### 11.3b LOCK LEDGER - HOUR OF 15:00-16:00 CT, 16 Nov 2026 (supervisor)

FIFTH CONSECUTIVE HOUR THE WINDOWS HELD. Nobody starved, nobody hit a hard release, and there was
NO OVERRUN BY ANY LANE this hour - the first hour with a completely clean overrun column.
  GAME BUILD (:07-:40, 25 min cap): claimed 15:09:38-06:00, expected finish named 15:32, IDLE at
    15:15:11. SIX MINUTES for a dock fix, a constant hunted down in another file and a new gate
    written. Claim on its own line, real CT off the machine. Correct in every respect.
  CHAT BOT (:45, protected, ends :52): claimed 15:48:05-06:00 (expected 15:52), refreshed
    15:49:18-06:00 for the gate battery (expected 15:55), released when it ended. A relaunch got a
    NEW RUNNING line, which is 11.3's refresh rule obeyed. Self-reported fault, and it is the only
    fault this hour: the lane spent :45-:48 READING the plan before claiming, so engine work began
    three minutes into a seven-minute window. The battery still finished inside it. THE RULE IT
    DREW FOR ITSELF AND I AM MAKING GENERAL: CLAIM FIRST, READ SECOND.
  HUD (:52-:07, 15 min cap): three short claims - 15:53:35 (expected 15:59), released 15:55:27;
    15:56:32 (expected 15:59), released 15:57:38; 15:58:11 (expected 16:01), live as I write. A
    capture SPLIT across short batteries with gaps, each one released, inside its own window. THIS
    IS THE SHAPE THE PROTOCOL ASKS FOR. A lane running short batteries with gaps looks dead
    between them and is NOT - nobody may clear this on age.
  ART / CONTENT / HUB: no lock taken, none needed. Art takes it only to prove fit.
NO STALE LOCK WAS CLEARED THIS HOUR, and no clearing was even considered - every RUNNING line was
either released by its own lane or still live with a named finish.

### 11.4 Item reassignment (ownership only - IDs unchanged, nothing renumbered)

MOVED TO DESKTOP HUD: L34 (director pane freezes), L35 (subscriber lane), L38 (ambient pane
framing - the biggest visual problem), L39 (Chronicle is a centre box with SMALLER TYPE - the font
shrinks first, then the panel), L40 (HUD/alerts out of the panes and off the Chronicle),
L51 (HUD overhaul: buffs/debuffs on equipment, the viewer's inventory, selling, the d20 redesign).

STAYS WITH LAPTOP CODE: L41, L42, L43, L44, L45, L46, L47 (PRIORITY - delver AI), L48, L49, L50, L52.

STAYS WITH DESKTOP BUILD: D24 (grain) and D28-D40, T3, T4.

### 11.5 Merging
The supervisor merges `hud-ui`, `laptop` and `content` into main. Same discipline as 9.2: delete
untracked .uid files first, keep BOTH sides on PROGRESS.md conflicts, never renumber anyone's cycle.
PROGRESS prefixes: D (desktop build), U (desktop HUD), L (laptop code), C (content), H (hub),
S (supervisor).


## 12. WORKTREE PATHS ARE PART OF THE CONTRACT (supervisor, 2026-11-13 03:20)

A worker that shares a working folder with another worker WILL rewrite files under a live session.
This already happened once: the content writer's scheduled task was written pointing at the laptop
CODE worker's clone with "git checkout content" in it. That was the SUPERVISOR'S error, caught by
the code worker, which correctly refused to switch the branch back under a possibly-live session
and stopped to flag it instead of guessing. Nothing was lost. The rule below exists so it cannot
recur.

EVERY worker gets its own working folder. One branch, one folder, no exceptions.

  DESKTOP (CruzaderPC)
    desktop build   main      C:\hd adventure\jests-hd-medieval-adventure     (the clone itself)
    desktop HUD     hud-ui    C:\hd adventure\bellmire-hud                    (worktree)
    hub build       hub       C:\hd adventure\bellmire-hub                    (worktree)
    supervisor      -         C:\hd adventure\bellmire-sup                    (worktree, scratch)

  LAPTOP (jestai)
    laptop code     laptop    C:\Users\Jestsayin96\Project1\Bellmire-HD-stream  (the clone itself)
    content writer  content   C:\Users\Jestsayin96\Project1\bellmire-content    (worktree)
    supervisor      -         C:\Users\Jestsayin96\Project1\bellmire-sup        (worktree, scratch)

RULES:
  - Never run `git checkout <branch>` in a folder that is not yours. Read it freely; never switch it.
  - A worker that finds its folder on someone else's branch: do NOT switch it back if that session
    may be live. Check for unpushed commits, push them if there are any, and FLAG it. Stopping and
    reporting beats guessing - that is what happened here and it is why nothing was lost.
  - The supervisor's scratch worktrees are disposable. Any worker may ignore them.
  - When writing a scheduled task's prompt, state the worker's OWN folder and say explicitly which
    folder is not theirs. A prompt that names a shared folder is a defect in the prompt.


## 13. THE STREAM-HUD PHILOSOPHY (Mr. E, Nov 13 2026) - BINDING ON EVERY HUD AND TOWN WORKER

Mr. E's rule for what the on-stream picture may contain: "all we need on the stream screen itself
is the chronicle, the split screen and the titles of each window so people know what to spend their
money on, and which screen is currently watching who. Anything we can push to the hub, push it."

THE STREAM SCREEN SHOWS ONLY THESE, AND NOTHING ELSE:
  1. The 2x2 split-screen panes (spotlight.gd) - the stream's resting state, always up.
  2. The Chronicle centre box (hud_dock.gd).
  3. Each pane's LANE TITLE - DIRECTOR / SUBSCRIBER / BITS / CHANNEL POINTS / (ambient). This is the
     spend prompt: a viewer must be able to read what a pane is for, so they know what to spend on.
  4. Each pane's "Now watching: <who>".
  5. THE BOSS BAR during a lord fight (boss_bar.gd) - the ONE overlay exception Mr. E kept, for the
     tension of a lord's HP draining live. Nothing else gets this exception.
  6. IN-WORLD elements inside the panes: health bars over characters, floating damage numbers,
     spell and combat VFX. These are the CONTENT of the windows, not overlay chrome - they stay.

EVERYTHING ELSE IS HUB-ONLY. No on-stream overlay panel, board, sheet, list or readout beyond the
six above. If a worker is about to draw a new panel on the stream canvas, it is wrong unless it is
one of the six. When in doubt, it goes to the hub.

Already decided under this rule: the Guild Roll is gone (L58), the party band goes to the hub
(D46/H10), the viewer Satchel goes to the hub (L63 below), the unit/selection frame goes (D48
below), the d20 shows on the hub (H9). The hub already carries hero sheets, inventory, gear, the
fallen and the command list, so most of "everything else" is ALREADY there - the work is stripping
the stream and filling the few gaps (selling prices, the band grouping), not rebuilding the hub.


## 14. Laptop two-session collision + the merge-before-lock bug (supervisor ruling, Nov 13 ~16:50)

Two LAPTOP CODE chats ran in the same folder (C:\Users\Jestsayin96\Project1\Bellmire-HD-stream,
branch `laptop`) at once. The older one, on an hourly check-in, ran `git merge origin/main` as step 1
and moved HEAD under the live session. Damage was contained (149 WIP lines intact, D52 c9daa0f present,
nothing pushed/reset/force-pushed) and the older session stood down. Rulings:

1. ONE LAPTOP CODE CHAT AT A TIME IN THAT FOLDER. Branch `laptop` + one folder is a single owner.
   The live (newer) session keeps the folder; the older stays out permanently. If a second laptop
   CODE chat is ever genuinely needed, it gets its OWN worktree on its OWN branch (as the content
   writer already does, COORD 10/12) - never a second chat on `laptop` in the same tree.
2. READ THE LOCK BEFORE YOU MERGE. The check-in ordering that put `git merge origin/main` ahead of
   the lock read is WRONG and caused this. Correct order for every laptop run: (a) git fetch,
   (b) READ docs/RUN_LOCK_LAPTOP.txt - if a live session holds it, do file-only work or stand down,
   (c) only then merge origin/main. Never move HEAD before confirming no one else holds the folder.
3. AN L-PREFIX DOES NOT MEAN LAPTOP OWNS IT. Ownership is whatever the item's own "Owner:" line says.
   (L63 is DESKTOP HUD; leaderboard_panel.gd.) Every worker reads the Owner line, not the prefix.

Two previously-unowned files now have owners (COORD 11.2):
  - scripts/boss_bar.gd   -> LAPTOP. It displays Monster.phase/phase_count/phase_changed (laptop data)
    and completes the "boss_bar shows phase" half of L29a (a laptop item). The HUD worker correctly
    declined it; it belongs with the boss logic, not the 7 stream-UI files.
  - scripts/adventurers.gd -> LAPTOP. The NPC band's _kit_up, tied to gear.gd and L55 (laptop).
  Assigning ownership does NOT change the laptop's ACTIVE task, which is D52 (below).

OPEN FOR MR. E (raised by the laptop, not decided): boss_def() never copies BOSS_DEFS "spd", so plain
lords move at their body speed and Nightwing's canon 6.6 never reaches the mover. A written-speed
unique now does set it. Fixing it for ALL plain lords changes how every lord moves mid-cycle - Mr. E's
call, left unchanged.


## 11.x GODOT LOCK LEDGER - 2026-11-16 16:00-17:00 CT (supervisor)

| Lane | Claimed | Named finish | Released | Held | Verdict |
|------|---------|--------------|----------|------|---------|
| game build | 16:11:02 | 16:37 | 16:17:44 | 6m42s | CLEAN - inside :07-:40, well under 25 min |
| chat bot | 16:45:00 (refreshed 16:50:30, re-claimed 16:57:40) | ~17:04 | 17:04:30 (stamp) | ~19 min | OVERRAN - window ends :52 |
| HUD | - | - | - | - | STARVED - no claim, no commit; the lock was held through :52-:07 |
| art / content / hub | no lock needed | - | - | - | n/a |

TWO FAULTS, BOTH ON THE CHAT BOT LANE, BOTH RECORDED SO A SECOND OCCURRENCE GOES TO MR. E:
1. CROSS-BOUNDARY CLAIM. Its 16:57:40 re-claim named a finish of ~17:04, which is inside the HUD
   lane's :52-:07 window. The HUD lane has no lock line and no commit for its 16:52 slot. It
   behaved correctly by waiting in front of a claim with a named finish on it - the protocol's
   age-based clearing does not apply to a live, named claim - and it was starved for it. This is
   the FIRST starvation since the protocol went in at 10:25 on 16 Nov.
   THE RULE IT BROKE IS ALREADY WRITTEN: a battery that will not finish inside the lane's own
   window is SPLIT with a checkpoint commit and finished next slot. It is never declared past the
   boundary. Declaring an overrun is honest; it is not permission.
2. FUTURE STAMPS, RECURRING ON THE LANE THEY WERE FIRST WRITTEN AGAINST (13:58). At 16:59:02 the
   lock file already read "IDLE 2026-11-16T17:04:30-06:00"; the Windows wall clock read 17:01:53
   when checked directly. The release was stamped three to five minutes ahead of real time.
   WHY IT MATTERS: age-based clearing computed from a future stamp is NEGATIVE, so a dead lock
   stamped forward looks immortal and a live one looks like nothing. READ THE CLOCK OFF THE
   MACHINE and write real Central Time with the offset.

WHAT HELD: no hard release was hit by any lane, no lane landed on another's running Godot session,
every claim named an expected finish on its own line, and no stale lock had to be cleared. The
protocol is working; this hour's fault is one lane's arithmetic, not the design.

## 15. A GATE THAT PRINTS NO VERDICT IS RED (supervisor ruling, 2026-11-16 19:58 CT)
FOUND BY THE CHAT BOT LANE during B14 and promoted here because it binds EVERY lane that runs a
battery, not just that one.

THE DEFECT. The B14 battery ran each gate as `Godot ... --script <gate> --quit`.
`tools/_b11_muster.gd` extends SceneTree and does its work at FRAME 30, so `--quit` ended the
process after one frame: return code 0, the town boot banner printed, and NO VERDICT LINE AT ALL.
An rc=0 with no verdict is one careless read away from being recorded as a pass - and in this case
the verdict it was hiding was the only thing the slot existed to produce.

THE RULE, BINDING ON GAME BUILD, CHAT BOT, HUD, ART AND ANY LANE RUNNING A GODOT GATE:
  1. A FRAME-COUNTING GATE IS RUN WITHOUT `--quit`. It quits itself; `--quit` races it and wins.
  2. A GATE THAT PRINTS NO VERDICT LINE IS RED. Not "inconclusive", not "probably fine", not
     "rc=0 so it passed". RED, until it is re-run and prints one.
  3. A battery REPORTS THE VERDICT LINE ITSELF, not the return code, for every gate it claims.
Gates that finish before frame 1 (L14_TEST, TWITCH_PARSE, D704_ECHO) are unaffected by `--quit`,
but rule 2 applies to them identically.

WHY THIS SITS IN THE CONTRACT AND NOT JUST IN ONE LANE'S PROGRESS.md: the lock protocol, the tick
protocol and every "gates green" line in this project rest on gate output being trustworthy. An
instrument that can report silence as success invalidates all three.
