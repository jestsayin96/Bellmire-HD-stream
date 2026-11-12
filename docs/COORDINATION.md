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
