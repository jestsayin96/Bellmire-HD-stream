# Running Jests HD Medieval Adventure

## Open and play
**Quickest:** double-click `Play Jests HD.bat` in the project folder.

### Controls (the new RTS-style camera)
| Key / mouse | Does |
|---|---|
| WASD or arrows | pan (hold Shift to go fast) |
| mouse wheel | zoom in / out |
| right-drag | rotate and tilt; Q / E turn, R / T tilt |
| middle-drag | pan |
| left-click | select anyone - townsfolk, a hero, the band, a monster: green ring + a unit frame (HP, class, level, gear, potions, oil, gold, kills, where they are) |
| F | follow the selected one - into the scar and back out; with nothing selected, follow your own hero |
| Esc | clear the selection / stop following |
| N | every townsfolk name on / off (heroes always show theirs: viewers gold, the town's band silver) |
| 1 2 3 4 5 6 7 | jump: square, scar mouth, west gate, tavern, smithy, armourer, apothecary |
| Tab | jump into a delve that is running below (again for the next one, then back to the square) |
| Space | pause / resume |
| [ and ] | game speed 1x, 2x, 4x, 8x |
| Enter | type a chat command as yourself ("MrE"), e.g. `!enlist knight`, `!delve`, `!fish`; Esc closes |
| H | hide / show the key help |

1. Godot 4.6.1 lives at `C:\Users\morta\village_assets\godot\Godot_v4.6.1-stable_win64.exe`
   (the `_console.exe` beside it prints the log to a console window).
2. In Godot: **Import** -> pick `C:\hd adventure\jests-hd-medieval-adventure\project.godot` -> **Edit**.
   The first open imports every asset; give it a minute.
3. Press **F5** (or the play arrow). The main scene is `Town.tscn` - Bellmire, the valley, the scar.

From a terminal, without the editor:
```
"C:\Users\morta\village_assets\godot\Godot_v4.6.1-stable_win64_console.exe" --path "C:\hd adventure\jests-hd-medieval-adventure"
```

## Chat
There is **no Twitch connection** in this build. Chat commands come in through `town.chat_line(user_id,
display_name, message)`; the test tools use a fake feed. Nothing is ever posted anywhere.

| Command | What happens |
|---|---|
| `!enlist <class>` | raise a hero (knight, mage, ranger, barbarian, cleric, rogue, sage, duelist); they appear on the square |
| `!inventory` (`!inv`, `!bag`) | what the hero carries: weapon, armour, potions, oil, gold, catches and the best one |
| `!hero` | the hero's sheet: class, rank, level, AC, HP, to-hit, stats, saves, gear, potions, oil, gold, record |
| `!delve` | walk to the scar mouth; the party goes in together once nobody queued is still on the road (or 45 s after the first arrival) |
| `!fish` | walk to a dock and fish (junk to rare catches) |
| `!forge` / `!armoury` | buy the next weapon / armour tier; the hero walks to the smith / armourer |
| `!brew`, `!oil` (`!lamp`, `!torch`) | potions, lamp oil |
| `!reroll`, `!respec` | a new hero after a death (costs gold), reassign stats |
| `!guild` `!memorial` `!deepest` `!deadliest` `!richest` `!patrons` | standings, the fallen, leaderboards |
| `!valley` | the command list |

While a hero is on the scar road, waiting at the mouth or below, `!fish` / `!forge` / `!armoury` / `!brew`
answer "X is waiting at the mouth of the scar" instead of dragging them away. Per-viewer cooldown 1.5 s.

## Saves
Viewers' heroes, the fallen and patrons are saved to **`user://roster.json`** - on Windows:
`%APPDATA%\Godot\app_userdata\Jests HD Medieval Adventure\roster.json`.
It loads at start (living heroes walk back onto the square) and saves every 30 s and on close - the old
game's format. Test tools (anything run with `--script`) never read or write it.
Delete the file to start the valley's roll fresh.

## What runs on its own
- The day clock: 90 s a day, night before 6:00 and after 18:30 (sun, moon, lamps, windows; townsfolk go home).
- Economy: farmers, miners, the smith, the healer... produce by day; souls eat at day's end; tax and wages.
- Caravans on the west road; settlers; the chief hires guards, commissions gear, buys grain.
- The town's own adventurers (a band of eight at the tavern) muster and delve on their own.
- Raids from town level 3 (Bellmire founds at level 3): skeletons out of the scar or bandits on the west
  road; guards, the chief and heroes defend; houses burn and are rebuilt with wood and stone.
- The chronicle (bottom-left parchment) shows the last six lines.
- Town tier: the smiths forge only up to the town's level (1-4); locked tiers hang on the shop racks under a
  dark cloth, "not yet made in Bellmire", and come uncovered when the town grows.
- The wizard's lamp-stand, dead centre of every floor: a hero who reaches it (5 m) sets it burning and the
  floor is lit even with no oil left. It never refills the oil. When the last lantern gutters out, a bell
  with no clapper rings somewhere below.

## Test tools (`tools/*.gd`)
Run any of them with the console exe:
```
"C:\Users\morta\village_assets\godot\Godot_v4.6.1-stable_win64_console.exe" --path "C:\hd adventure\jests-hd-medieval-adventure" --script res://tools/<name>.gd
```
Add `--headless --fixed-fps 60` for the checks that need no window. Pictures land in
`%APPDATA%\Godot\app_userdata\Jests HD Medieval Adventure\`; finished renders are filed in `renders\cycles\`.
After adding a new `class_name` script, run once with `--headless --import` first.

Checks (headless):
- `_stream_soak.gd` - everything together for 10 valley days with six fake viewers; one line per day.
- `_ten_days.gd` - 10 valley days: souls, level, stock, deaths, the chronicle.
- `_delve_test.gd` (`DELVE_OIL=1` for a short one), `_delve_pace.gd` (`PACE_N`, `PACE_TS`, `PACE_L`).
- `_raid_test.gd`, `_raid_dbg.gd` - raids with the level forced to 3.
- `_persist.gd` - roster save/load round trip. It WRITES `user://roster.json`: copy your real save aside first and put it back after.
- `_viewer_dbg.gd`, `_adv_dbg.gd`, `_people_test.gd`, `_fish_rolls.gd`, `_smoke.gd`.

Renders (need a window): `_town.gd` (the town tour), `_clock_shot.gd` (noon/dusk/night),
`_fps_window.gd` (FPS over dusk into night), `_stream_soak.gd`'s companions `_soak_shots.gd`,
`_raid_shot.gd`, `_caravan_shot.gd`, `_settler_shot.gd`, `_band_shot.gd`, `_labels_shot.gd`,
`_return.gd`, `_delve_render.gd`, `_stock.gd`, `_bestiary.gd`, `_dungeon_cat.gd`, `_floors.gd`,
`_spells.gd`, `_fight.gd`, `_fish_shot.gd`, `_heroes.gd`, `_folk_shots.gd`.

Measured (Cycle 41): 1920x1080, RX 9070 XT, the whole town, dusk through night with a raid: 136-152 FPS.

## Not ported yet / known
- **Twitch**: no IRC/EventSub connection (the old `twitchevents.gd` / `user://twitch.cfg`) - by design for now.
- The old game's audio (horn, bells, clash cues).
- **The old interface is NOT being ported** (Mr. E's call, 2026-11-08): no old HUD, menus or `settings.gd` options screen. The HD game gets a new interface of its own - direction: an RTS or WoW style interface, or a mix (Mr. E, 2026-11-08). Not started yet.
- Mixed parties: viewers and the town band delve separately (the old game let viewers fill a town party).
- A memorial monument: the old memorial is the `!memorial` chat list only, and that is what is here.

Logs: `PROGRESS.md` (every cycle), `PLAN.md` (roadmap), `docs/ASSETS.md` (every asset and script).

## State at the pause (2026-11-08, Cycle 43)
Stable. The full 10-day soak (`_stream_soak.gd`) runs with no script errors: viewers enlist, fish, forge
and delve; the town band delves; raids, caravans, settlers, the clock, saves. Picks up Thursday.
Next up when work restarts: the new RTS/WoW-style interface (see docs/PLAN.md).
