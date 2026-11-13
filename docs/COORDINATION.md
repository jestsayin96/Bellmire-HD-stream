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
  - Before launching Godot: read it. If it says RUNNING and the timestamp is under 45 min old, do
    NOT launch. Do file-only work or stop and say "skipped: another run is working".
  - Set "RUNNING <local time> (<worker name>)" before launching, "IDLE <local time> - <what>" after.
  - Never start a second battery while any thread of a previous one may still be alive.
  - If Mr. E is at the machine, say so before launching Godot - he may be playing or streaming.

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
