

## Cycle 33 - the delve (2026-11-08)
- scripts/delve.gd (class Delve): !delve party walks to the scar mouth, drops to DungeonHD floors at y=-400.
  Floors chain 1..n; each floor has a canon chronicle line ("Floor N - <origin>, remade as <biome>: <census>.").
  Lords on 5s rise with their canon line. Fights: 5e d20 + attack bonus vs AC, crit 20/miss 1, casters bolt,
  healers heal, one CON death save. Retreat when mean hp < 35%. Ends -> town feed.
- Pathing: BFS over the FloorGen cell grid, cached 0.5 s; heroes ring the target instead of stacking on one point.
- Fixed: boss "falls to X" fired once per hero that tick (foe list built per tick) -> credit only the killing hit.
- Fixed: hero labels underground: HeroBody.compact() - one small line while delving, name+class back in town.
- Render tool: camera aimed at world origin when party list was briefly empty -> skip those frames;
  midpoint framing fell into the void between rooms -> aim at real bodies; hard frame cap so a run can't hang.
- Renders: renders/cycles/20261108_0938_delve (fight1_v5 knight vs giant rat; lord5_v5 the Rattling Host).
- Still to do: return-to-town shot; loot/purse and lantern oil; on-screen feed HUD.


## Cycle 34 - delve polish (2026-11-08)
- Lantern oil ported from the old expedition.gd (read-only original): each hero empties their own satchel
  at the mouth ("They carry N flasks of oil between them."); a floor burns one flask per two bodies, a search
  half a flask; "The oil is running low." / "The last lantern gutters out. They are fighting blind." In the
  dark heroes roll at disadvantage, monsters at advantage, and the floor's lights sink to embers.
  After a floor won with no oil: "Out of oil, the party feels its way back up from floor N."
- Loot ported (gold is PERSONAL): the finder keeps a floor's gold (floor*11, x3 for a lord's hoard split
  evenly); clearing a floor gives everyone standing floor*5 xp; ore/stone/gear/potions go home to the town
  (town.stores via receive_haul). Return line: "... come home to Bellmire with 39 gold, 1 ore and 1 stone."
- FeedHUD (scripts/feed_hud.gd): parchment "The Chronicle", last 6 lines, older lines fade, panel fades
  after a quiet spell. Lives in town; the delve writes to the same feed.
- Survivors now climb out of the scar mouth and walk home to the square (no teleport).
- Fixed: monster loop stood up foes killed earlier the same tick (90 "kills" for 11 monsters) -> 11.
- Fixed: descend timeout never fired (one straggler held the party 20 s+) -> 6 s cap works.
- Fixed: is_inside_tree errors when a delve starts before it is in the tree (first floor deferred).
- Renders: renders/cycles/20261108_0959_delve_polish (return_mouth_v2, return_square).


## Cycle 35 - the haul matters + saving (2026-11-08)
- scripts/economy.gd (class Economy): a port of the old sim.gd stock (food 60, wood 40, stone 25, ore 18,
  gear 6, potion 5; price/add/take/want verbatim) and villager._produce on the 3.5-6.5 s work beat:
  miners dig ore+stone, the smith turns 1.2 ore + 0.5 wood into 0.38 gear, the healer turns food into
  potions, fletcher/miller/innkeeper/merchant as before. The old stock chatter lines go to the chronicle
  ("The forge sits cold — no ore.", "No gear left on the rack.", "The granary is running low." ...).
- Delve haul goes into the stock; a party at the muster draws half a set of gear each from the rack for
  +2 to every blow (old rule), or goes without.
- Visible stock: an iron-ore heap in the smithy yard (1 rock per 3 ore, up to 14), salvaged swords and
  shields laid out at the armourer's (up to 8), potions on the apothecary shelf (up to 10). Rebuilt only
  when a visible count changes.
- Roster persistence (old rule): user://roster.json, loaded at start (living heroes walk back onto the
  square), saved every 30 s and on close. Test harnesses (--script) never touch the real save.
  Round trip verified (gold, oil, class, alive, fallen).
- Memorial: in the old game the memorial is the !memorial chat list (roster.fallen), not a monument;
  ported as-is, no monument invented.
- Renders: renders/cycles/20261108_1010_stock (ore/gear before and after a haul, potions).


## Cycle 36 - caravans, town level, wall shelves (2026-11-08)
- Caravans ported from the old town._caravan: every 70-120 s a caravan master with a wagon comes in on
  the west road (45 m out from the west gate), stands at the market, and after 16 s settles the trade
  verbatim: sells the town 8 of anything priced over 1.12x base (if treasury > 80), buys up 30% (max 30)
  of anything over 90 in store; then walks back out and is gone. Feed lines are the old ones.
- Town level ported from the old sim.gd: score = souls*3 + renown*2, checked each 90 s day, can fall.
  Souls = the original ROSTER trades only (the HD street life is set dressing) -> "33 souls live here.
  Bellmire stands as a village. (town level 2)", as the original founded. Renown: +1 per floor cleared,
  +6 per lord slain (old rule). Raids (old rule: from town level 3) are the next block.
- Ruins/_rebuild_pass in the original only follow raids (_wreck_a_building) -> ported with raids next.
- Apothecary: Shelf_Simple / Shelf_Small_Bottles are WALL shelves (0.3 m / 0.65 m tall); they now hang
  on the back fence at hand height, potions in one row along the plank (were lying on the dirt).
- Renders: renders/cycles/20261108_1021_caravan (road, market, shelf).


## Cycle 37 - raids, ruins, rebuilding (2026-11-08)
- scripts/raids.gd (class Raids), ported from the old town._raid/_peril_pass/_combat_pass/_wreck_a_building/
  _rebuild_pass and villager.gd's FIGHT state + take_damage:
  - no raids until town level 3 ("a hamlet has nothing to defend itself with and nothing to lose");
    every 110-190 s; 62% from the scar (Bestiary skeleton warrior/rogue/minion as Monster), else bandits
    on the west road; n = min(8, 2 + 0..2 + day/3 + renown/12); raiders hp 30 atk 5.5 speed 4.
  - guards (hp 64 atk 11), the chief (hp 40 atk 6) and heroes (roster stats) defend; targeting 70 m /
    26 m as before; non-fighters within 13 m flee 16 m; d20 + to-hit vs AC (1 misses, 20 doubles),
    swing 1.1 s, reach 2.2 m, chase 1.15x. Heroes get the one CON save. Death lines as before.
  - raiders inside the walls wreck a house every 7-13 s ("A building is burning!"); rebuild every 22 s
    for 12 wood + 8 stone ("The townsfolk raise the ruin again."); "The attack is driven off. The gates hold."
  - Defenders walk back to their posts afterwards.
- Ruin look (HD, not the old hex model): the same house charred black, sagged 38% into its footprint and
  tilted, KayKit rubble + broken wall at its feet, soft fire + smoke particles and a fire light for 45 s.
  Rebuild restores the original materials and transform.
- Economy gains a day counter (90 s days) for the raid size formula.
- Headless: two raids (3 skeletons, 4 bandits) driven off by the garrison with no losses - old balance.
- Renders: renders/cycles/20261108_1031_raid (gate clash, ruin_v2, rebuilt_v2).


## Cycle 38 - settlers, the chief's purse, hunger, the clock (2026-11-08)
- Ported from the old town._peril_pass / _settlers / _chief_spends / _hunger / _arrive and sim._end_of_day:
  - End of day (90 s): souls eat 1.15 food each; an empty granary counts hungry days ("Day N — the
    granary is empty. Hunger bites (N days)."); demand decays x0.55; tax 1.8 / wages 1.9 a soul; level
    check; "Day N begins — S souls, G gold, <town> (lvl L, standing a/b)".
  - Settlers every 45-80 s while souls < homes*3, food >= 35 and treasury >= 120: a TRADES role walks in at
    the west gate and gets a home and work exactly as the founding ROSTER did (town.arrive).
  - Chief every 40 s: swears in a guard (180 g) while guards < 3 + raids/2; commissions gear (150 g) when
    the rack is under 4; buys 40 grain (120 g) when food is under 25.
  - Hunger every 20 s after 2 hungry days: a soul (not the chief) takes 14; at 0 "X has starved.", renown -2.
  - The old day clock (night before 6:00 / after 18:30): villagers produce in daylight only (the old
    WORK state). The HD sky does not show night yet.
  - NOT ported yet: the town's own adventurers (old _make_adventurer / npcs Roster) - their settler and
    bounty branches are skipped; gear piles up without them.
- town.bury(): one death path (line, fall, body cleared after 25 s) for raids and hunger.
- Raids fix: the old 70 m defender range covered the whole little hex town; HD guards are posted at gates
  ~350 m apart, so the horn now turns the whole garrison out (tower lookouts keep their towers).
- 10-day headless run: 33 -> 41 souls, market town by day 3, raids cost guards and once the chief, the
  chief swears in new watchmen; treasury ~600-3700. Matches the old records (27-42 souls over 10 days).
- Render: renders/cycles/20261108_1047_settlers/settler_gate.png.


## Cycle 39 - the town's own adventurers (2026-11-08)
- scripts/adventurers.gd (class Adventurers), ported from the old _make_adventurer / _apply_hero /
  _send_party / _kit_up / _check_pending and the adventurer branches of _settlers / _chief_spends:
  - the town's own roll (npcs Roster, same classes and rules as viewers), founded with a band of eight
    (one sage), living at the tavern; HeroBody gains `npc` (no viewer gold name/ring, keeps wandering).
  - every 20-36 s idle adventurers muster (<= 10, <= 100 underground); _kit_up from their own purse
    (armour/weapon alternately, oil to 3, the guild dole of 2, rank stores, a potion with spare change);
    half a set of gear each from the town rack (+2 to every blow) or the want is noted.
  - gather at the mouth (11 m); after the patience they go with whoever is there if >= 3, else they stand
    down "and wait for the next muster". Patience counts from the first arrival at the door (the old 45 s
    assumed a tavern a short walk from the mine; Bellmire HD's is ~300 m away).
  - they delve through the same Delve (npc_party, own lane: parallel delves sit 700 m apart); survivors
    climb out and walk back to the tavern; the fallen leave the roll.
  - settlers: renown >= 3 and < 6 adventurers -> 55% "X the <class> arrives at the tavern, drawn by tales
    of the deep." (renown -1); chief bounty (240 g) when < 3, a sage if the band has no healer.
  - adventurers count as souls (the old founding: 30 trades + 8 adventurers = 38 -> a market town).
- Fixed: raids looked town adventurers up in the viewers' roster (script error every frame of a raid).
- 10-day run: 42 -> 48 souls; the band delves floors 1-3 with 24 flasks; no script errors.
- KNOWN: the band's delve runs slow (about a game-day per floor vs ~40 s in the solo delve test) -> next.
- Render: renders/cycles/20261108_1100_band/band_mouth.png.


## Cycle 40 - the band's slow delve, and the clock made visible (2026-11-08)
- Slow delve FOUND: dungeon_hd._people mixed the floor root's world offset into floor-local spawn points.
  It cancelled out for a floor at x = 0 and threw every monster a whole lane (700 m) away in a side lane,
  so the town band (always lane >= 1) walked ~600 m to each fight. Everything is floor-local now (spawns,
  open cells, the lord's farthest-cell search). tools/_delve_pace.gd: 8 heroes, 8x, lane 1 -> floor 4 in
  53 game-s (was 330+), same as lane 0.
- Band muster fixes: the night rule no longer sends a hero on an errand home; members who stop short of
  the mouth are sent on again.
- scripts/daylight.gd (class Daylight): the old clock (economy.clock, 90 s days; night before 6:00 and
  after 18:30) drives the sun arc (up at 6:00, highest mid-day, down at 18:30), warm dawn/dusk light and
  sky, a low cold moon at night, ambient and fog colour; all 73 founding town lights burn low by day and
  full at night; MI_WindowGlass glows at night. Night ambient kept at 0.30 so a stream stays watchable.
- Townsfolk: at night the old villagers' WORK ended and they went home to REST - ported in _next_trip
  (home, indoors, until 6:00); stops-based folk (carters, crier, watch) and posted guards keep their beat.
- 10-day run: the band delves three times and comes home with hauls (277-411 gold, ore, stone, gear),
  loses four; renown 31; Bellmire grows into a walled town (level 4) on day 10-11; no script errors.
- Renders: renders/cycles/20261108_1111_clock (noon_v2, dusk_v2, night_v2).


## Cycle 41 - full-stream soak (2026-11-08)
- tools/_stream_soak.gd (FAKE CHAT, nothing posted): the real town, six viewers (!enlist, !fish, !forge,
  !delve, !reroll) alongside the town band, raids, caravans, settlers and the clock for 10 valley days at 8x.
  Day 11: 53 souls, a walled town (level 4), 3.8k treasury, food 128, the band delved 3x and came home,
  5 raids / 2 deaths, viewers alive 6/6, 11 catches, no script errors.
- Fixed: Roster.describe (ported verbatim from the original) passed 17 arguments to 16 placeholders - the
  oil count had no slot -> "... %d potions, %d oil, %d gold ...". (!hero / !enlist reply errored.)
- Fixed: a lone delver read "JestFan descend into the scar" -> descends / comes home, kill(s).
- Verified end to end (tools/_viewer_dbg.gd): !delve -> gate -> guild post -> mouth -> descend -> floor ->
  out of oil -> climbs out -> walks home to the square. The soak's own fault: it handed new errands to a
  hero waiting at the mouth.
- FPS, real 1920x1080 window, RX 9070 XT, 1x, 17:00 -> 05:00 (dusk and the whole night), a raid going,
  142 people: min 136, avg 146 (tools/_fps_window.gd).
- Renders: renders/cycles/20261108_1128_soak (night_raid, dawn_return_v2).
- Open: viewer name labels stack when a party bunches up (Name/Class pairs overlap).


## Cycle 42 - polish from the soak; RUNNING.md (2026-11-08)
- Viewer muster: the per-arrival 4 s timer split parties (the first arrivals went in; later ones were
  stranded at the mouth for good). Now the town musters the viewers' party like the old game: in together
  once nobody queued is still on the road and 4 s have passed since the last arrival, or 45 s after the
  first arrival; never while their last delve is below. tools/_labels_shot.gd: four go in together.
- Chat: `away` state per hero (on the road to the scar / waiting at the mouth of the scar / below, in the
  scar); !fish !forge !armoury !brew answer "X is waiting at the mouth of the scar." instead of dragging the
  hero (or moving their hidden body while below). delve_queue and away are cleared when the delve ends -
  before, a viewer's second !delve would have answered "already waiting" forever.
- Labels: a crowd of viewers' heroes (within 3.5 m) shows names only, a size smaller, stepped through three
  rows by their order along the ground - all four names legible at the mouth.
- docs/RUNNING.md: open/run, chat commands, the save (user://roster.json), what runs on its own, every
  test tool and how to run it, measured FPS, and what is not ported yet.
- Renders: renders/cycles/20261108_1137_labels (labels_mouth_v5 = final).


## Note (2026-11-08 11:48)
- Mr. E: do not bring the old interface over; the HD game needs a new one. Recorded as a rule in docs\PLAN.md; RUNNING.md updated. Nothing from the old UI had been ported (the chronicle panel, labels and name tags are new HD pieces).


## Cycle 43 - town tier unlocks, the wizard's lamp-stand; STABLE PAUSE (2026-11-08)
- Town tier (old Roster.town_tier / tier_for_town / sim.sync_unlocks): economy.check_town_level sets
  Roster.town_tier = clamp(level, 1, 4) for every roll (viewers' and band's - one static), and the shop
  racks show locked tiers under a dark cloth, unlit, "not yet made in Bellmire" (town.show_tiers).
  Bellmire founds at level 3 -> dragontooth (tier 4) locked until a walled town.
- Lamp-stand (old expedition._check_lamp / _light_check / _ring_the_bells): the stand FloorGen already puts
  dead centre of every floor; a hero within 5 m sets it burning (light 11 / range 26), the floor counts as
  lit even with an empty satchel (never refills it); 1 in 6 lightings "A brass hand-bell rests against the
  stand..."; "<hero> sets the wizard's lamp burning. The dark pulls back from floor N." when it beats the
  dark; going dark rings "Somewhere below, a bell with no clapper rings once..." before the lantern line.
- Mr. E: the old interface is NOT ported; the new one should follow an RTS or WoW style, or a mix
  (docs/PLAN.md). Not started.
- Final soak (renders/soak_final.log): 10 days, 0 script errors, 52 souls, level 4, viewers and band delving.
- Renders: renders/cycles/20261108_1150_tiers_lamp (rack_before, rack_after, lamp_lit).
- PAUSED here at Mr. E's request until Thursday. No scheduled blocks are pending.


## Cycle 43b - a player camera (2026-11-08)
- There was NO player camera: the main scene had none (every picture came from the test tools' own
  cameras), so pressing Play showed nothing to navigate. scripts/rts_camera.gd (class RtsCamera, NEW, RTS
  style per Mr. E's interface direction): WASD/arrows pan, wheel zoom, right-drag rotate/tilt, Q/E R/F,
  middle-drag pan, 1-7 jump to places, Tab into running delves, Space pause, [ ] speed 1-8x, Enter local
  chat as "MrE", H help. Added by town only when played (never under test tools).
- tools/_eye_test.gd drives it with real input events: pans, zooms, jumps, chat (!enlist knight) - works.
- `Play Jests HD.bat` in the project folder: double-click to play.
