# FINISH PLAN — Bellmire HD, deadline: before Nov 13 2026

Scheduled build runs work through this list top to bottom. Each run:
1. Reads docs/RUN_LOCK.txt. If it says RUNNING and is under 3 hours old, stop (another run is working).
   Otherwise write "RUNNING <local time>" into it.
2. Reads this file, PROGRESS.md (last 3 cycles) and docs/PLAN.md.
3. Takes the FIRST unchecked item, does it, and only it (or the next one if it finishes early).
4. After every edit: Godot console --headless --path . --quit-after 300 -> 0 SCRIPT ERROR / Parse Error.
   Then the relevant tests in tools/, then a render it LOOKS at, then `git diff --stat`.
5. Ticks the item here ([x] + one line of result), adds a PROGRESS.md cycle, writes "IDLE <time>" to RUN_LOCK.
6. Commits and pushes on its own ONLY when every test passes (Mr. E approved, Nov 11); otherwise leaves the work uncommitted and reports why. Never touches the original "trial and error" folder.
   Never clears the open Blender scene. Never states a dungeon floor count. Follows the lore.

## The list
- [x] 1. (DONE Nov 11, cycle 50: panel top-right, L toggles, F10 hides; render renders/cycles/20261111_board) Leaderboard panel: scripts/leaderboard_panel.gd (CanvasLayer, right side, parchment like FeedHUD).
        "The Guild Roll": roster.leaderboard("standing", 10) rows (rank, name, rank title, level, deepest; "+" for dead),
        then "The Fallen": roster.fallen[0..3]. Refresh every 5 s. L toggles. Hidden by F10 with the rest.
        Hook it in town.gd next to TwitchChat (Play runs only). Test tool + render.
- [x] 2. (DONE Nov 11, cycle 51: scripts/party_frames.gd in the RtsCamera layer, floor + oil header, HP bars; tools/_party_test.gd OK; render renders/cycles/20261111_party) Party frames: while any delve runs, a compact WoW-style column (left edge, above the Chronicle):
        each delver's name, HP bar, and the party's oil. Viewer heroes gold. Part of the RtsCamera layer.
- [x] 3. (DONE Nov 11, cycle 52: scripts/sfx.gd (Sfx) + assets/audio (Kenney CC0 sfx, RandomMind CC0 music, LICENSE.txt); day/night/raid crossfade, bell, horn, sting; tools/_sfx_test.gd SFX_TEST OK) Sound + music: CC0 only (Kenney audio packs: RPG Audio, Impact Sounds, UI Audio; music CC0 e.g.
        OpenGameArt CC0 medieval loops). Download to assets/audio with a LICENSE note. A small Sfx autoload/
        node: sword hits, spell cast, death sting, raid horn, coin, bell at dawn/dusk, splash for fishing;
        day / night / raid music with crossfade; ambience in town. Volume sane for stream (music -14 dB).
- [x] 4. (DONE Nov 11, cycle 53: tavern chairs, chapel stand/candles, landmark banners, themed dungeon props as obstacles; tools/_props_test.gd PROPS_TEST OK; _offfloor 0, _townwalk in_solid 0.85% (was 1.20%); renders/cycles/20261111_props) Place the 49 Quaternius Fantasy Props MegaKit props (assets/props): town (Lantern_Wall by doors,
        barrels/crates by houses, Chair_1 + Table_Large outside the tavern, BookStand/Candle at the chapel,
        Banner_* on landmarks) and dungeons (Chain_Coil, Cage_Small, CandleStick_Stand, Bookcase in themed
        rooms, registered as obstacles). Re-run tools/_offfloor.gd and tools/_townwalk.gd: no clipping regressions.
- [x] 5. (DONE Nov 11, cycle 54: lords 1.2x taller, Chronicle name card on rise and fall, scripts/boss_bar.gd top centre, director cuts to the lord at 100; tools/_boss_test.gd BOSS_TEST OK; renders/cycles/20261111_boss) Bosses: from the original's lore (bestiary/floor lords) — make lord floors feel like events: bigger
        lord, a name card in the Chronicle, a boss bar at the top while the fight lasts, the director at 100.
- [ ] 6. Raid balance: heroes under level 3 hang back (guard the square) unless the town is breached;
        first death of a fresh hero gets a grace (knocked out, not killed) once.
- [ ] 7. Fixes: follow camera never inside walls (raycast pull-in); soft fill light on the followed hero at night;
        offset health bars in tight parties.
- [ ] 8. Soak: 30 min (4x speed) with the director on, 6 fake viewers enlisting/delving; no script errors;
        FPS logged; fix what breaks.
- [ ] 9. Docs: RUNNING.md (keys V, F10, L; Twitch config), PROGRESS.md, this list all ticked.
