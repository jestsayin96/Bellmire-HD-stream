

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


## Cycle 44 - from Mr. E playing it (2026-11-08)
- Wall-walking in the scar FIXED: a hero closing on a monster aimed for a ring slot (5 m out for casters
  and archers); when that slot fell off the floor the path search found nothing and the old fallback walked
  them straight there - through walls, over the void. Delve._go now snaps any goal to the nearest floor
  cell and never walks a straight line across non-floor. tools/_offfloor.gd: 8 heroes, 4 floors, 0 of 378
  samples off the floor.
- Names: the town's band now wears silver name tags (viewers gold); N toggles every townsfolk name.
- Select / follow (RTS camera): left-click anyone -> green ring + unit frame (WoW/RTS style, bottom
  centre: name, class/role, level, rank, where, HP bar, gear, potions, oil, gold, kills, catches); F follows
  (through a delve and back - the camera cuts when the body changes), F with nothing selected follows your
  own hero, Esc clears. Tilt moved to R / T.
- Chat: !inventory / !inv / !bag - weapon, armour, potions, oil, gold, catches (best catch by rarity).
- Tests: tools/_select_test.gd (real input), tools/_inv_test.gd. Renders: renders/cycles/20261108_1232_select.


## Cycle 45 - moved to Godot 4.7.2 (2026-11-08)
- Saved the last 4.6.1 state as git tag `godot-4.6.1-stable` (pushed); worked on branch `godot-4.7`.
- Full re-import under 4.7.2 (old cache kept as .godot_46_backup/): 53 s, 0 errors, 0 warnings. 522 .import
  files gained 4.7's new default options (mesh_library/use_node_names_as_mesh_names, array_mesh/
  deduplicate_surfaces, gltf/texture_map_mode) - additive only. No script changes needed.
- Checks on 4.7.2, all pass, 0 script errors: delve (normal + dark), off-floor 0/396, raids driven off,
  !inventory, roster save/load identical, 10-day soak (52 souls, level 4, band delving).
- FPS 1920x1080, dusk through night with a raid: min 136, avg 168 (4.6.1: min 136, avg 146).
- Renders (noon/dusk/night, select/follow) look the same as 4.6.1: renders/cycles/20261108_1257_godot47.
- Play Jests HD.bat and RUNNING.md now point at D:\1game\Godot_v4.7.2-stable_win64.exe.


## Cycle 46 - "the dungeons are a hot mess", "the town isn't alive" (2026-11-08)
Dungeon
- Health bars (HealthBar3D, shader billboard): everyone in a fight, heroes and monsters, plus anyone not at
  full HP; raiders/defenders in raids; starving townsfolk. tools/_bars_test.gd: 189 hero / 18 monster samples.
- Nothing stands in anything: FloorGen now returns `obstacles` (every furniture cluster, debris, cell,
  portcullis, scar-glass, lava pool); heroes and monsters push out of them and slide along, spawns move to
  clear floor. tools/_offfloor.gd: 0 off-floor, 0 inside a prop (1129 samples).
- Clutter: no clusters in corridors or on the stairs, furniture pulled to the walls, biome growth only on
  room edges. Trees removed from the confection (the pink hall); boxes and barrels instead.
- The candle carpet on shrine floors was the `floor_tile_small_decorated` tile (it has candles and rubble
  modelled in) used as the MAIN floor; now a rare accent nowhere / plain tiles. Small tiles laid 4 per cell.
- The black holes: `wall_broken` opened a see-through hole onto the void (replaced by `wall_cracked`), and
  the lava pools loaded `res://lava.gdshader`, a path that does not exist - a black square instead of a
  pit. Fixed path; pools only deep inside rooms (a corridor pool walled the passage shut) and are obstacles.
- Party names no longer pile up: laid out on screen, all heroes at once, each lifted until clear.
Town
- Houses in the road: the hex streets zig-zag, so a terrace or back rank could land on another street.
  Every house footprint is now tested against all paving (incl. the scar road and the bridge road).
  0 houses on roads; 67 plots.
- Walking: scripts/town_nav.gd (TownNav) bakes a Godot navmesh over the valley with every solid thing
  carved out - house footprints, every prop's own footprint (stalls, tables, benches, wells, lamps,
  trees), the town wall (gates open), the river (bridge open). route() asks the NavigationServer. People
  leave a house from its door, not through the back wall. Bake 0.2 s. tools/_townwalk.gd: walkers inside a
  house or prop 2.65% (old street routing) -> under 1% (the rest are doorsteps/tight inn yards).
- Ground: the town was one dark dirt disc. A mask painted from streets and plots: dirt where feet go,
  grass greens in the middle of every block.
- Posted people (guards, stallholders) are not statues: they look about, gesture, pace a step and back.
- Test hook: JESTS_NO_NAV=1 uses the old street routing for comparison.
- Renders: renders/cycles/20261108_dungeon_fix3, 20261108_town_walk2. renders/.gdignore added.


## Cycle 47 - from Mr. E's recordings (2026-11-08)
- Watched his 7 OBS clips (9.5 min, no audio) as contact sheets. Fixed what they showed:
- The white thread across the town: a hero's fishing rod stayed on the body after they walked off the dock,
  drawing its line from wherever they were back to the water. The rod is now packed away beyond 14 m, and a
  hero only ever carries one.
- Nights were near black on stream. Moon brighter (0.38 -> 0.7) and at night the ambient comes from a cool
  moonlit colour instead of the black sky. Square at 22:00 now reads clearly (renders/cycles/20261108_night).
- Huge names up close: name tags shrink with nearness (unchanged from 22 m out, down to 40%).
- Two "MrE" tags after a death: the fallen body kept its tag while the re-rolled hero got a new one. A
  body that dies (raid or delve) drops its tag and leaves the name layout.
- The grey window / 75 errors when he pressed Play: the camera read its chat box before the town finished
  building, and Godot's debugger pauses the game on any error. Camera now waits for setup.
- Quaternius Fantasy Props MegaKit (CC0) downloaded: 49 new props into assets/props (+ licence). Not yet
  placed.
- Lesson: a parse error in a class_name script makes the --script tools hang instead of failing; run
  `--headless --quit-after` first after edits.


## Cycle 48 - live Twitch chat, phase 1 (2026-11-08)
- scripts/twitch_chat.gd (class TwitchChat): read-only, anonymous (justinfan) Twitch IRC over
  WebSocketPeer; login sent only once the socket is OPEN; PING/PONG; RECONNECT and drops retry with
  backoff 2-60 s; half lines buffered across packets; only "!" commands; bots ignored by login;
  3 s per-user cooldown; at most 4 commands a frame into town.chat_line(uid, display, text).
  Viewer uid = Twitch user-id. Config: user://twitch.cfg (channel, enabled, ignore), written on first run.
- town.gd starts it next to the RTS camera (Play runs only, never under --script tools).
- tools/_twitch_parse.gd: 8/8 PASS offline. Live: "TWITCH joined #jestsayin96".
- The local model's first draft did not run (Godot 3 connect syntax, read_packet() treated as a String,
  login sent before the socket opened, PRIVMSG never matched because lines start with tags) and it pasted
  a duplicate road block into town.gd that broke the build. Draft kept as scripts/twitch_chat.gd.bak_local;
  town.gd restored from git and only the 5-line hook re-added.


## Cycle 48b - Twitch chat restored on the desktop (2026-11-11)
- twitch_chat.gd, tools/_twitch_parse.gd and the town.gd hook had been deleted (local model); restored.
  Parse test 8/8, live "TWITCH joined #jestsayin96", and Mr. E's own "!enlist knight" from Twitch worked.
  Broken local draft (twitch_chat.gd.bak_local) deleted.

## Cycle 49 - the auto-director (stream mode) (2026-11-11)
- scripts/auto_director.gd (AutoDirector), owned by the RTS camera. V toggles it, F10 hides/shows the
  whole interface for a clean OBS layout. Touching the camera pauses it 20 s, then it resumes.
- Every second it scores shots and cuts: raid 95 > fight below 75-95 (viewer parties +10, more hurt =
  hotter) > a catch being landed 60 > a party walking a floor 45-55 > a viewer's hero in town 30 >
  a slow tour (square, scar mouth, whole valley) 10. Holds 8 s minimum, 20+ hotter cuts early,
  quiet shots move on after 22 s. While on: no selection ring, no unit frame.
- tools/_director_test.gd: real town, 3 viewer knights, director at 4x: cuts hero -> catch -> hero ->
  catch, frames in renders/cycles/20261111_director. 0 script errors.


## Cycle 50 - the Guild Roll panel (2026-11-11)
- scripts/leaderboard_panel.gd (LeaderboardPanel): parchment panel top-right, the roster's standing
  board (top 10, top three in gold, the dead marked +) and the last three of the fallen. Refreshes every
  5 s; L toggles; the director's F10 hides it with the rest. Started next to TwitchChat (Play runs only).
- tools/_board_test.gd: renders/cycles/20261111_board. 0 script errors.
- docs/FINISH_PLAN.md + docs/RUN_LOCK.txt: the deadline checklist the scheduled build runs work through.


## Cycle 51 - party frames (2026-11-11)
- scripts/party_frames.gd (PartyFrames): WoW-style column on the left edge, above the Chronicle, shown
  only while a delve runs. One dark gold-edged block per delve: "Delvers / The town's band · floor N"
  and the party's oil (amber when low, red "no oil - dark"); one HP bar per delver (green/amber/red),
  name gold for viewers' heroes, silver for the town's band, greyed "+ name / fallen" for the dead;
  up to 8 rows then "+N more". Refreshes every 0.4 s real time. Lives in the RtsCamera layer, so
  F10 hides it with the rest.
- tools/_party_test.gd: real town, 3 viewer knights + the band; frames hidden with no delve, then one
  row per delver with oil and floor: PARTY_TEST OK. Renders renders/cycles/20261111_party.
- Note: 12 'Parameter "material" is null' engine errors during the delve render (not script errors,
  not from this change) - worth a look.


## Cycle 52 - sound and music (2026-11-11)
- assets/audio (all CC0, LICENSE.txt lists every file and its page): Kenney RPG Audio / Impact Sounds /
  UI Audio (hits, coins, bell, chimes for spells, clicks); RandomMind (OpenGameArt) medieval loops -
  day: The Old Tower Inn, Minstrel Dance; night: The Bard's Tale, Exploration; raid: Battle; the death
  sting is the first 6 s of his Defeat Theme. Made here with ffmpeg: the raid horn, the fishing splash,
  a 40 s town wind loop. WAVs converted to OGG (~8 MB in all).
- scripts/sfx.gd (Sfx), made by town.gd for every run (JESTS_NO_SFX=1 leaves it out). Static helpers
  Sfx.at(kind, pos) / Sfx.play(kind) / Sfx.sting() do nothing when no Sfx is live.
  Buses Music -14 dB, Sfx -6 dB, Ambience -20 dB. World sounds are 3D (a pool of 16), pitch varied, and
  rate-limited per kind so a raid does not machine-gun.
- Music follows the town: raid while raiders are about (the horn blows once as it starts), else night
  (economy.is_night) or day; 3 s crossfade in real seconds at any game speed; a hero's death ducks the
  music 10 dB for 5 s under the sting; the wind drops under raid music. The bell tolls 3 times at dawn
  and at dusk.
- Hooks: Monster.hurt and raid swings (hit / miss swish), a delver struck, Spells.cast, Roster.kill
  (sting), Roster.spend and floor loot (coins), Angler._splash, the L key (click).
- tools/_sfx_test.gd: 15/15 pass, SFX_TEST OK (render renders/cycles/20261111_sfx/town_raid.png and
  waves.png - the waveforms of the music, horn, sting and wind). _delve_test ENDED, _offfloor 0 of 980,
  TWITCH_PARSE OK. Parse check: 0 script errors (the 3 'material is null' engine lines are old).
- The Sfx node first left 8 objects / 4 resources alive at exit (players still holding streams); it now
  stops and drops them in _exit_tree.


## Cycle 53 - Fantasy Props MegaKit placed (2026-11-11)
- Town (town.gd): the doors already had Lantern_Wall + barrels/crates/buckets and the square its stalls;
  added two Chair_1 at the tavern table ends, a BookStand with a Candle_1 on it and two lit
  CandleStick_Stand at the chapel door, and standing Banner_1 / Banner_2 flanking every landmark front
  except the windmill (stepped in from the road when the forecourt is tight). All solid (navmesh carves them).
- Dungeon (dungeon_hd.gd THEME_PROPS): prison Chain_Coil + Cage_Small, crypt CandleStick_Stand (lit) +
  Cage_Small, shrine stands + BookStand, keep/treasury/workshop/mess Bookcase_2 (+ chain / stand),
  barracks Chain_Coil. Each on its own cell, registered in info.obstacles; on a crowded floor (a prison's
  cells) it falls back to any clear cell, edge cells included, never by the stairs.
- tools/_props_test.gd (new, windowed): counts every placement in the town and on six themed floors and
  checks each dungeon piece sits on an obstacle: PROPS_TEST OK. Renders renders/cycles/20261111_props
  (+ contact_sheet.png). The crypt shot's camera ended up inside a wall - the prop is counted, the
  picture is not useful.
- _townwalk in_solid 63/7425 = 0.85% (HEAD before the change: 86/7168 = 1.20%), houses on road 1 (same).
  _offfloor 0 of 1126, _delve_test (DELVE_OIL=1) ENDED, TWITCH_PARSE OK, parse check 0 script errors.
- Note: _delve_test without DELVE_OIL hits its 150 s cap on floor 3 both before and after this change
  (no ENDED); with DELVE_OIL=1 (the documented short run) it ends.


## Cycle 54 - floor lords as events (2026-11-11)
- Bestiary.LORD_SCALE 1.2: every lord stands a fifth taller than its canon height (lift scaled with it).
  Canon untouched: the eight lords, their titles and notes, the floors ending in 5 / every 10th.
- FeedHUD.card(title, sub, colour) / FeedHUD.card_on(town, ...): a dark gold-edged name card at the head
  of the Chronicle, in the lord's own colour - "The Grubmother / Lord of floor 5. Vast, slow, and
  patient." when it rises, "Slain on floor N by ..." when it falls. Held 14 real seconds; the Chronicle
  shows 4 lines instead of 6 while it is up so it stays clear of the party frames.
- scripts/boss_bar.gd (BossBar, tabs): top centre under the key help, in the RtsCamera layer (F10 hides
  it). Lord's name in its colour, a blood-red HP bar with numbers, "Lord of floor N · against the delvers
  (4 standing)". Shown only while Delve.lord_fighting() (risen, alive, the party in a fight); a viewers'
  party's lord before the town's band's.
- AutoDirector: a fighting lord is shot "lord_<id>" at pri 100 (+0.1 for viewers), above the raid (95),
  and cuts in at once, framed 20-42 m out by the lord's height.
- Fix found on the way (rts_camera._track): a freed selection (a slain lord / raider the director was
  following) compares equal to null, so the old null test let `selected is HeroBody` error every frame
  (145 SCRIPT ERRORs in _director_test). Now tests validity; _director_test 0 errors.
- tools/_boss_test.gd (windowed, new): floor 5 straight away; 8/8 checks, BOSS_TEST OK (lord 5.3 m vs
  canon 4.4; card; bar; director on the lord 8 ms after it rose; bar gone when the lord is down).
  Renders renders/cycles/20261111_boss (card.png, fight_0.png, fight_1.png) - looked at: card readable,
  bar clear of the help, camera on the lord with the selection ring.
- _delve_test (DELVE_OIL=1) ENDED, _offfloor 0 of 1174, TWITCH_PARSE OK, PARTY_TEST OK, parse check
  0 script errors (the 3 old 'material is null' engine lines remain).


## Cycle 55 - raid balance (2026-11-11)
- raids.gd (backup raids.gd.bak_c55): GREEN_BELOW 3. A hero under level 3 no longer charges the raiders
  across the valley: while no raider is inside the walls they hold the market square (a ring 5-8 m out,
  facing outward) and only take a raider within HOLD_REACH 9 m. Once any raider is inside the walls
  (Raids.breached) they fight like everyone else. Guards, the chief and veterans are unchanged.
- The grace: a green hero's first fall in a raid (after the CON save, if that fails) is a knock-out -
  down, out of the fight, raiders leave them be, "X is knocked senseless, but lives. The guild's grace -
  once."; "X comes round." when the raid is over. Stored on the hero (graced) so it is once ever.
  Delve deaths are untouched (the item is about raids).
- tools/_raid_balance_test.gd (windowed, new): 3 fresh knights + a level 5 knight, a scar raid: green
  heroes 0 far chases before the breach, 312 samples on the square, the veteran goes out; a second raid
  dropped inside the walls: green heroes fight; first fall = knock-out (alive, graced), second = death,
  a level 5 hero gets no grace. RAIDBAL_TEST OK, 0 script errors. Renders renders/cycles/20261111_raidbal
  (hold_square, breach_fight, knocked_out) - looked at: heroes on the square, Chronicle lines readable.
- _delve_test (DELVE_OIL=1) ENDED, _offfloor 0 of 969, TWITCH_PARSE OK, parse check 0 script errors
  (the 3 old 'material is null' engine lines remain).


## Cycle 56 - camera and bar fixes (2026-11-11)
- rts_camera.gd (backup .bak_c56): the follow camera (F, and the director, which follows too) can no
  longer sit inside a wall. No physics bodies in this game, so the "raycast" marches the line from the
  followed one's head out to the camera through what is solid: every house box up to its roof in town
  (town.gd _house_box now carries the roof top as [2]; backup town.gd.bak_c56), and anything off the
  floor cells below wall top (4.6 m) in a dungeon. First hit: the camera snaps in front of it; when the
  view clears it eases back out. A followed one standing in a doorway: the march starts where the line
  leaves that footprint. Only houses whose footprint circle touches the line are tested (cheap).
- A soft cool fill light (OmniLight 0.9, range 7 m, no shadows) rides above and toward the camera from
  the followed one at night in town; fades in/out with the clock. Not underground: the dungeon's dark is
  the lore's dark (oil, the lamp).
- health_bar_3d.gd (backup .bak_c56): bars whose owners stand within 0.9 m of each other step up 0.21 m
  one above the next (by instance id, up to 4 steps), re-checked every 0.25 s; a lone bar stays put.
- tools/_camfix_test.gd (new, windowed): town follow orbiting low - camera in a house 38 frames with the
  pull-in off, 0 of 305 with it on; dungeon follow orbiting low - in a wall 266 frames off, 0 of 355 on;
  night fill 0.90 on, gone by day; four tight bars at 2.05/2.26/2.47/2.68, a lone bar 2.05. CAMFIX_TEST
  OK, 0 script errors. Renders renders/cycles/20261111_camfix (town_follow_low, night_follow,
  tight_bars, dungeon_pull_off, dungeon_pull_on) - looked at: town and night views clear of the houses
  (the night one pulled in tight between two houses), the dungeon one pulled in close behind the hero at
  that very low test pitch (at the normal -48 pitch the camera is above the walls anyway).
- _delve_test (DELVE_OIL=1) ENDED, _offfloor 0 of 1000, TWITCH_PARSE OK, _director_test (windowed) 0
  script errors, parse check 0 script errors (the 3 old 'material is null' engine lines remain).


## Cycle 57 - the soak, the docs; the finish list is done (2026-11-11)
- Soak (tools/_soak.gd, real window, director on, 4x, six fake viewers): ran 22 wall minutes = 56 valley
  days before the window was closed. 0 script errors. Memory flat (443 -> 485 MB). 34 raids driven off,
  21 delves home, 0 wipes, 9 viewer deaths and 8 rerolls; the director cut between raids, fights, lords,
  catches. FPS avg fell 150 -> 82 while settlers grew the town from 148 to 211 people - watch this on long
  streams (a population cap or cheaper far-away townsfolk is the next lever).
- Frame soak_02: the follow camera sat inside the scenery underground. When the followed hero stood on a
  cell the grid calls solid, the doorway rule parked the camera 4 m off their head. Underground it now
  skips the pull-in in that case (the camera is high above the walls there anyway).
- Fishers with a rod no longer fidget (a pace walked them off the dock).
- RUNNING.md: V director, F10 clean screen, L guild roll, the live Twitch section and twitch.cfg.
- Checks: parse 0 errors, _offfloor 0/904 off-floor, _twitch_parse OK, _delve_test progressing (floor 2).


## Cycle 58 - L1, more monsters (laptop, 2026-11-11)
- Lore read first (old bestiary.gd, NOTES.md bestiary/strains/biomes, data/*.json): the old game's creatures
  are undead, ooze, beasts, fiends and the wyrm; strains rename and recolour; 14 themes. Everything new
  keeps to those families and that plain voice; no lord was added (the eight are canon).
- New creatures, all from CC0 bodies already in the project (no new download - see note):
  bone bowman (KayKit Skeleton_Minion + the skeleton pack's own crossbow; keeps 8.5 m off and shoots a bone
  bolt), bone sentinel (Skeleton_Warrior, blade, large shield; +3 to be hit), gravecaller (Skeleton_Mage +
  staff; casts from 7 m and raises up to 2 "risen dead" that climb out of the floor with the KayKit awaken),
  lost delver (KayKit Knight / Barbarian / Rogue_Hooded, pale and cold-glowing - the guild's own dead; goes
  for the weakest delver), grave-whelp (the Quaternius dragon at 2.3 m; its breath splashes everyone within
  2.8 m of its mark at half), slimeling (what a slime divides into when it dies).
- Ways for the old creatures (Bestiary.WAYS): slimes split, spiders/snakes/adders/wasps leave venom that
  keeps hurting, rats/wasps/bats/puglins come in packs, the skeleton mage and imp shoot from range, the
  skeleton rogue holds a grudge. Delve reads them; numbers per hit are unchanged.
- Home themes (Bestiary.HOMES / NEW_TYPES homes): a creature at home on the floor's FloorGen theme is three
  times as likely there (pool_for). Depth bands widened: bowmen from floor 3, sentinels 5, gravecallers 6,
  lost delvers 8, whelps 10. Nothing new on floors 1-2.
- Two strains: scarborn (from floor 8 half the plain roll; its glow wanders the hue wheel like the scar's
  motes), mossbacked (the drowned of meadow and wood floors). The old strain bands are unchanged.
- tools/_l1_test.gd (headless, new): all 21 bodies load, every mapped animation exists, weapons on, heights
  right; strains appear where they should; home weighting; a real floor-4 delve sees an ooze divide, a
  gravecaller raise the dead, a bowman shoot, a whelp breathe, venom. L1_TEST OK.
  Renders renders/cycles/20261111_l1 (new_creatures, new_strains, ways_shot_breath) - looked at: first pass the
  lost delvers were flat blue silhouettes and the whelp was hidden by its own breath; tints lightened, whelp
  scaled up, breath puffs smaller and from the mouth - second pass all read.
- Note: Quaternius "Ultimate Monsters" (CC0: orc, ghost, yeti, mushroom king, demon...) is on Google Drive,
  which refused every download today ("quota exceeded"). Worth a retry; they would slot in as more bodies.
- Checks: parse 0 script errors (the 3 old 'material is null' lines), _delve_test (DELVE_OIL=1) ENDED all
  four home, _offfloor 0 of 434, TWITCH_PARSE OK.


## Cycle 59 - L2, lords with mechanics and rare uniques (laptop, 2026-11-11)
- Lore: the eight lords stay canon (names, titles, notes, floors ending 5 / every 10th, the two bags). Each
  now fights the way its own note says (Bestiary.LORD_WAYS, read by Delve like any creature's ways):
  The Hollow King, "wreathed in cold fire" - casts from 6 m and rolls a ring of cold fire (6 m, DEX save
  halves). The Grubmother, "vast, slow, and patient" - broods slimelings, up to 4. The Rattling Host, "a
  hundred dead men in one harness" - drops two dead men at 2/3 and at 1/3 of its hp. Nightwing, "too fast to
  see coming" - swoops across the room onto the weakest (x1.6) and calls bats. The Gravewyrm - breath that
  splashes 4 m, enraged under 30%. The Ossuary Lord, "it does not hurry" - calls its bones up out of the
  floor and takes half damage while any stand. The Pale Duchess, "she opens throats" - bleeding cuts, goes
  for the weakest, enraged under 35%. Mourncoil, "frost comes off it in sheets" - breath, and sheets of frost
  that slow the delvers' swings to half for 3 s. Mechanics start when a delver is within 16 m.
- Enraged: aura, ring, crown and light go red, the body swells a tenth, a Chronicle line and a red card.
- Never two of the same lord in a row: a fresh bag never opens with the lord that closed the last.
- Rare uniques (Bestiary.UNIQUES): on an ordinary floor from floor 2, 12% of the time, from a bag, never the
  same twice running. Each gets the name card ("A rare thing on floor N."), the boss bar and the director,
  a mechanic, two-thirds of a lord's hoard and +3 renown. Gnawbone (the rats' queen; calls rats), Mother
  Silk (venom, calls spiders), The Weeping Bowman (volleys at everyone in reach), Cinderjack (an imp the
  firepits let out; a fire ring), and "<name>, Kept by the Scar": a hero from the memorial who fell below,
  in their class's body, with a grudge and an enrage. Only once someone has fallen down there.
- Fixes found on the way: a creature with a grudge measured its 16 m mechanic range to its far-off mark
  instead of the nearest delver (mechanics stalled); a called slimeling had no ways entry (script error);
  the 7th and 8th heroes of a big party were set down past the wall at a new floor's entry (the off-floor
  samples since L1) - they now land on the floor.
- tools/_l2_test.gd (headless, new): 60 lord draws never repeat back to back, all eight drawn, each has a
  mechanic; uniques never on a lord floor, never twice running, all five turn up, the memorial names the
  kept one; then all 13 fought in real delves - each one holds its floor, the boss bar sees it, and every
  mechanic fires (summon, nova, shed, swoop, enrage, ward, breath, volley). L2_TEST OK.
  tools/_l2_shot.gd (windowed, new; L2_WHO=<lord or unique>): renders/cycles/20261111_l2 - looked at the
  Hollow King's card and his cold-fire ring with the bar, the Grubmother's brood line in the Chronicle,
  Wren Kept by the Scar with its card line and bar.
- For whoever owns boss_bar.gd (on neither list): its subtitle is hardcoded "Lord of floor N", so a unique
  reads "Lord of floor 7". A one-line change there could say "on floor N" when lord.def.unique is true.
- Checks: parse 0 script errors, _delve_test (DELVE_OIL=1) ENDED all four home, _offfloor 0 of 444-587 in
  four runs (after the entry fix), TWITCH_PARSE OK, L1_TEST OK.


## Cycle 60 - L3, weapons and armour (laptop, 2026-11-11)
- Weapon KINDS (Gear.KINDS): blade - sword, greatsword, dagger, spear; axe - axe, mace; arcane - staff,
  wand; ranged - crossbow, bow. Each has its own mesh at every tier from the CC0 kits already here (KayKit
  Adventurers, the KayKit weapon bits in assets/gear scaled x0.62 for the hand, the KayKit skeleton pack's
  grave-steel for tier 5). A kind is look and name only - every tier's numbers are unchanged, so the
  measured balance holds. A hero with no kind chosen keeps the old family progression and looks as before.
- !forge <kind> buys the next tier in that kind ("Ashe takes up a plain steel spear"); at the forge's best
  the smith reworks it into the new kind for a quarter of the tier price; !forge list names the kinds and
  the next price. Wrong kind for the class is refused with the list. Prices are the old tier prices.
- Tier 5, found only below: scarforged steel (atk 34, smoulders the scar's violet) and scarwoven mail
  (hp 110, AC 8). No smith sells them (the rack and town tiers are untouched: 1-4).
- Deep floors give up gear (Roster.find_gear, one roll per cleared floor for whoever searched): from
  floor 6, 5% + 1%/floor (+20% for a lord), one tier above what they carry up to the forge's best; from
  floor 10 someone already at the top can find tier 5. "Cass prises a scarforged mace from the dead on
  floor 12." The hero's body is re-dressed at once.
- Armour is worn (Gear.dress_armour on the KayKit bones): leather boots; chainmail adds pauldrons;
  plate adds a crested kettle-hat helm (only on heads with no helmet, hat or hood of their own - so the
  plain rogue/duelist); warded plate glows faintly blue; scarwoven is deep violet. Hooked through
  Roster.offhand_bone -> Gear.rank_trim, the two calls HeroBody.refresh already makes (hero_body.gd is on
  neither list, so it is not touched; a direct Gear.dress_armour call there would be cleaner).
- tools/_l3_test.gd (headless, new): every kind has a mesh at every tier; tier tables agree; the forge
  (kind buy, keep kind, wrong kind refused, rework at the top, tier 5 never sold, no gold = no change);
  finds by depth; tier 5 in the numbers; chat !forge bow / !forge list; pieces worn per tier and through
  rank_trim. L3_TEST OK. tools/_l3_shot.gd: renders/cycles/20261111_l3 - looked at: first pass the helm
  sat high like a bowl and the violet blew out; helm lowered with a brim, glows toned down; second pass reads.
- Checks: parse 0 script errors, _delve_test ENDED all home, _offfloor 0 of 483, TWITCH_PARSE OK, L1_TEST OK.


## Cycle 61 - L4, six more callings (laptop, 2026-11-11)
- Lore first: the old game's nine callings (knight, warden, barbarian, rogue, duelist, ranger, mage, sage,
  cleric) stay as they are. Six more, built the old way - a KayKit body + a weapon family + an offhand +
  a stat profile - each with 5e saves, a default weapon kind, one ability Delve reads, and a cloak colour:
  paladin (Knight, sword + badge shield, STR, saves WIS/CHA; lays on hands when someone is near falling,
  smites the dead and the lost x2), necromancer (Mage, staff + closed book, INT, INT/WIS; drinks back 30%
  of what its bolts do), monk (Rogue, quarterstaff or bare wraps - a new "open" family, DEX, STR/DEX;
  flurry: swings 0.6x the interval for 0.7x the hit; unarmoured defence adds WIS in leather or less),
  druid (Mage, staff, WIS, INT/WIS; thorns: its bolt hits whatever stands within 2.5 m of the mark at
  half), warlock (Rogue_Hooded, wand + book, CHA, WIS/CHA; hex: everyone's blows land 25% harder on its
  mark for 6 s), bard (Rogue, dagger, CHA, DEX/CHA; the whole party +1 to hit while the bard stands).
- Roster.CASTERS: necromancer, druid and warlock throw bolts from range like the mage, sage and cleric.
- The calling's colour goes on the cloak AND the hat or hood (the KayKit texture is dropped there so the
  colour shows true), so two Mage bodies (necromancer, druid) differ face-on.
- !enlist takes them all (the class list was already data); "Kept by the Scar" now uses each calling's
  own body. RUNNING.md: the new callings and !forge [kind|list].
- tools/_l4_test.gd (headless, new): each enlists by chat, two saves, primary rolls best, a weapon of its
  family, an ability and a cloak; lay on hands, unarmoured defence, smite on the dead only, flurry, hex in
  the numbers; a party of all six delves 3 floors (home, 13 kills). L4_TEST OK.
  tools/_l4_shot.gd: renders/cycles/20261111_l4 - looked at: first pass the cloaks came out in the kit's
  own colours and the staves were tiny; texture dropped on cloak/hat, KayKit staff for tiers 1-3; the
  back view now reads paladin pale, necromancer black, monk saffron, druid green, warlock violet, bard red.
- Checks: parse 0 script errors, _delve_test ENDED all home, _offfloor 0 of 427, TWITCH_PARSE OK,
  L1_TEST OK, L3_TEST OK.
## Cycle 58 - D1: nobody walks through houses (2026-11-11, desktop)
- The cause: the navmesh CARVED every footprint (add_projected_obstruction carve=true), and a carved
  obstruction skips the agent-radius margin - paths ran along the very walls, the 0.5 m cells and the
  1.6 m edge simplification put feet inside houses, stalls and fences; thin fences (0.32 m) slipped
  between cell centres altogether. town_nav.gd (backup .bak_d1): carve=false (0.5 m margin), edge error
  0.4, footprints at least 0.6 m across. Bake 176 -> ~700 ms, once at start.
- town.gd (backup .bak_d1): keep_walkable(p) pushes a foot back out of any house, stall, table or wall
  section on a 4 m grid of footprints (nav.closest() scans all 13k polygons, 0.35 ms a call - too dear
  per walker per frame); crowd_push(v): people give each other 0.75 m (2 m grid rebuilt once a physics
  frame, posted folk count as obstacles); route() finishes on a door spot that sits inside the navmesh
  margin when nothing solid is between.
- townsfolk.gd (backup .bak_d1): corners taken at 0.45 m (0.9 cut house corners), wobble halved, every
  step through keep_walkable + the crowd shove except the last door -> inside leg; in only through a door
  the street reaches (else wait outside); an unreachable corner is given up; the watch's second man too.
- raids.gd (backup .bak_d1): raiders and defenders walked a straight line at their mark - now they follow
  the navmesh (re-asked when the mark moves 1 m or every 0.7 s) and come in by the gates; fleeing folk
  route away instead of running 16 m through whatever is behind them.
- tools/_townwalk.gd: also starts a raid and samples raiders + defenders, checks every door, counts
  walkers stuck on a route, prints TOWNWALK ... PASS/FAIL. Result: in_solid 0/6999 (before 64/7194 =
  0.89%), raid 0/4911, doors 67 (0 off the street, 0 legs through another house), stuck 0-3 of 139.
- tools/_walk_shot.gd (new, windowed): renders/cycles/20261111_d1 market_above, street (looked at: the
  crowd walks between the stalls and benches, nobody on a stall or a roof; folk on the street side of
  the houses). The raid was driven off before reaching the gate, so raid_gate/raid_inside show the street
  at dusk, not the gate. tools/_d1_diag.gd (new): uncarved footprints, door distances, closest() cost.
- Checks: parse 0 script errors (the 3 old 'material is null' lines remain), _offfloor 0 of 978,
  TWITCH_PARSE OK, _delve_test ENDED (4 survivors, 0 script errors), _perf 6.9 ms (145 fps headless),
  _fps_window min 149 avg 172 at 139 people.



## Cycle 62 - L5, the peoples of the valley (laptop, 2026-11-11)
(Cycle numbers: the desktop's D1 entry is also "Cycle 58"; the laptop cycles run 58-62 today.)
- Lore: the old game names no races - its folk (Garm of the Ford, Tove Ashwood...) read as valley humans.
  So the peoples are new, kept in its plain voice and tied to its places: human ("valley-born, like most
  of Bellmire"), elf ("out of the old woods past the fields"), dwarf ("down from the hill mines"), halfling
  ("from the field-farms"), orc ("came over the west road and stayed"), and one only this world has - the
  scarkin, "born too near the scar; its light in the eyes".
- Roster.SPECIES: 5e-style bonuses (human +1 all; elf +2 DEX +1 INT; dwarf +2 CON +1 WIS; halfling +2 DEX
  +1 CHA; orc +2 STR +1 CON; scarkin +2 CHA +1 INT; capped at 20) and one trait: darkvision (elf, dwarf,
  orc, scarkin - no disadvantage when the oil is gone) or lucky (halfling - a natural 1 is rolled again).
  Rerolls keep the people; a hero saved before today reads as human. The sheet says "dwarf knight".
- !enlist <class> <species> in either order; an unknown people is refused with the list; no people given
  draws one by weight (human most often, scarkin least).
- The look (Gear.species_look, through the same dressing hook): body proportions (dwarf broad and short,
  halfling small, orc big, elf slender and tall), skin of head and arms tinted from the mesh's own material
  (orc green, scarkin violet), and parts on the head bone: elven ears, a dwarf's beard, an orc's tusks, a
  glowing scar-shard on a scarkin brow. Set, never multiplied, so re-dressing does not compound.
- Fix on the way (L3): a respec drops a weapon kind that is not of the new calling's family.
- tools/_l5_test.gd (headless, new): both enlist orders, unknown refused, a drawn people, every people
  drawn, bonuses, traits, old saves, the sheet, reroll keeps the people, respec drops the kind, each look's
  scale and parts and no compounding. L5_TEST OK. _l4_test's "primary rolls best" now allows a species +2.
  tools/_l5_shot.gd: renders/cycles/20261111_l5 - looked at: first pass the orc's tusks hung like fangs
  and the beard read as a mask; tusks now rise from the jaw, beard lowered.
- Merged origin/main (desktop D1) before the item; PROGRESS.md append conflict resolved keeping both.
- Checks: parse 0 script errors, _delve_test ENDED all home, _offfloor 0 of 438, TWITCH_PARSE OK,
  L1_TEST OK, L3_TEST OK, L4_TEST OK.
## Cycle 59 - D2: spells at the chest, not the sky; battle spells in raids (2026-11-11, desktop)
- The "4th of July": HealthBar3D is a MeshInstance3D child of its owner, and Monster._height() measures
  every visible mesh under the monster - the bar included. delve.gd and raids.gd asked for the bar at
  _height() + 0.25 EVERY FRAME, so the bar climbed ~0.25 m a frame and the bolt aim (_height() * 0.5, then
  Spells added another +1.0) went up with it into the ceiling / sky.
- health_bar_3d.gd (backup .bak_d2): a bar never goes higher than the first height asked for. Test: 120
  asks with _height() + 0.25 -> bar stays at 1.75 m.
- spells.gd (backup .bak_d2): aim from the caster's HANDS (half its height, 0.45 m toward the mark) at the
  foe's CHEST (0.62 of its height, measured from its own meshes, health bars left out, cached); a point
  target on the ground is lifted 1.1 m; nothing is aimed more than 2.4 m over the caster's feet; thrown
  spells fly a flat arc (<= 0.45 m rise) at 16 m/s. Spells.cast takes a body or a point (old callers
  unchanged) and the chain's further bodies. New kinds: CHAIN (bolt + jagged leaps), FIRE (ember, flame
  burst, scorch ring), FROST (ice shard, rime ring, snow), SMITE (a shaft of light drops on the mark),
  RENEW (motes cling to the body for 5 s). They join the scar's misfire order. Spells.flight() = landing time.
- raids.gd (backup .bak_d2): heroes of the arcane callings (mage, sage, cleric) fight at 8 m with spells:
  mage bolt/bolt/chain/fire (chain leaps to 2 more raiders within 5 m at 65%/42%, fire hits every raider
  within 2.6 m at 80%); sage lays RENEW on the worst-hurt defender (30% of max over 5 s) else FROST (70%,
  half pace for 4 s); cleric WARDS the worst-hurt (soaks 35% of max for 8 s) else SMITE (x1.5 on the scar's
  dead). Damage lands after the flight; a misfire into a mending spell mends the raider. Raider health bars
  use the measured height (no climb). Delve casting is delve.gd (laptop) - noted in WORK_PLAN for it.
- Lore: the original trial-and-error folder could not be found on this PC this run (OneDrive Public is
  empty / not synced); the spells follow the canon already ported in spells.gd (the four spells, the scar
  misfire rule) and the classes in roster.gd.
- tools/_d2_spells.gd (new, windowed): bar holds; 36 aim checks (9 spells x body/feet/sky) all within
  +0.5..+2.4 m, 0.000 m off target; mage 4 casts 90 -> 24 hp; ward 22.4 soaks 10 -> 0; smite; renew
  12 -> 16.7; frost slow 4.0 -> 2.0 speed; scar misfire bolt -> heal. D2_SPELLS OK.
  Renders renders/cycles/20261111_d2 (raid_bolt, chain, fire, smite, ward, frost, renew) - looked at: the
  bursts sit at the skeletons' chests on the meadow, the smite shaft and ward shell on the guard, nothing
  streaks upward. The chain and fire frames caught the end of the effect (faint); worth a closer shot later.
- Checks: parse 0 script errors (3 old 'material is null' lines), _offfloor 1 of 1001 on the first run (a
  hero in a delve fight - delve code, untouched), then 0/903 and 0/1018 on two reruns; TWITCH_PARSE OK;
  TOWNWALK in_solid 0/6965 raid 0/3867 PASS; _delve_test ENDED 4 survivors, 0 script errors.


## Cycle 63 - D2's laptop half: monster bars, spells below (laptop, 2026-11-11)
- Merged origin/main (desktop D2 spells); PROGRESS.md append conflict resolved keeping both.
- monster.gd: _local_bounds() and the _height() fallback skip HealthBar3D. Delve placed each bar at
  _height() + 0.25 and _height() measured the bar - it climbed every frame (D2's cause, in the dungeon).
- delve.gd: casters fight with the D2 spells the way raids.gd does. Books: mage bolt-bolt-chain-fire,
  sage frost-bolt, cleric smite-bolt, necromancer bolt-chain, druid frost-bolt, warlock bolt-fire. Menders
  lay their own spell on the lowest delver: sage renew (heal over Spells.RENEW_T), cleric ward (half a heal
  now, then soaks 35% of max for 8 s), paladin heal. Spells.cast(kind, caster, target BODY, false, more)
  and the damage lands after Spells.flight(): chain leaps to two more within 5 m at x0.65 each, fire
  catches all within 2.6 m at x0.8, frost x0.7 and the creature moves and swings at half pace 4 s, smite
  x1.5 on the dead and the lost. The L4 abilities (drain, hex, thorns) ride on the landing. Ward soaks
  every way a creature hurts a delver (blow, breath, nova, swoop, volley). In-scar misfire stays off below
  as before (Spells' in_scar = false) - a call for the desktop/lore if the dungeon should misfire too.
- tools/_d2_delve_test.gd (headless, new): a party of all six casters and a knight; the delve casts bolt,
  chain, fire, frost, smite, renew, ward; renew and ward land on delvers; frost slows; bars hold (worst rise
  0.00 m over 15 bars); kills. D2_DELVE OK (twice). tools/_d2_delve_shot.gd: renders/cycles/20261111_d2_delve
  - looked at: the Rattling Host with a fire burst at its feet, bolts flat from the casters, bar steady.
- Checks: parse 0 script errors, _delve_test ENDED all home, _offfloor 0 of 458, TWITCH_PARSE OK, L1, L4,
  L5 OK.
- Cycle 59 follow-up: the original was found (path now in WORK_PLAN LORE RULE). It has fire + frost as its
  spells and the scar misfire rule - D2's fire/frost match it; the other D2 spells come from the plan's list.


## Cycle 64 - D3: buildings that level up (desktop, 2026-11-11)
- Lore: the town ladder is the original sim.gd's six levels (a hamlet, a village, a market town, a walled town,
  a free city, the seat of the valley) - six, so the renders are levels 1, 3, 5 and 6 (the plan said 7).
  "A walled town" is level 4, so that is where the stone wall comes; below it the wall is a timber palisade.
  The original's named places are the Chief's Hall, Chapel, Tavern, Market Row and the towers; the new halls
  are the plan's list named plainly in that voice (the Delvers' Guild after the Delvers' Road).
- scripts/growth.gd (new, no class_name, preloaded by town.gd): built ONCE at the founding, then only shown or
  hidden, so a level change is free and the navmesh never moves (every new building stands inside a house
  plot's own footprint). House plots (not landmarks/shops) fill nearest the market first, front rank before
  back: 23/31/39/45/51/56 of 56 at levels 1-6; the rest are staked lots (cleared earth, pegs, line, a timber
  stack, a crate). Upgrades hang off each house node: planters at the door (2), a hanging sign in the
  district colour + door lamp (3), stone plinth + chimney (4), a storey more (5, scale.y x1.2), ridge pennant (6).
  New buildings, each on a house plot: Market Hall (3, open hall on stone pillars, stalls), Town Stables (4,
  open-fronted barn, horses in the stalls - for D4), Delvers' Guild (5, the house raised, banners, notice
  board), Bathhouse (5, stone, copper dome, steam), Mage Tower (6, stone drum, MegaKit round tiled cap,
  violet windows, turning crystal + light). Feed lines on each rise ("8 new houses go up in Bellmire." ...).
  Falling back hides them again.
- town.gd (backup .bak_d3): wall_parts (wall blocks, merlons, towers, gate arches) for the palisade/stone
  swap; growth set up at the end of _build at level 1 (quiet); show_level(lv, quiet); _home_for skips lots
  and raised halls. economy.gd (.bak_d3): check_town_level calls town.show_level (quiet at the founding).
  raids.gd (.bak_d3): raiders never "burn" a staked lot or a hall.
- tools/_d3_test.gd (headless): levels 1..6 up, houses only ever increase, specials exactly as planned per
  level, every house's visibility right, wall palisade < 4 <= stone, 18 news lines, falling back to 2 closes
  the halls and brings lots back. D3_TEST OK (twice).
- tools/_d3_shot.gd (windowed) -> renders/cycles/20261111_d3: overview_level1/3/5/6 + levels_1_3_5_6.png,
  each new building, house_level1/3/4/6, lot, wall_level3/4, montages new_buildings.png, house_and_wall.png.
  Looked at: lots on the hamlet's outer streets fill with houses by level 6, the palisade is brown timber at 3
  and stone at 4, the Market Hall reads (pillars, tiled roof, stalls, sign), the Stables show horses in open
  stalls (moved forward + prism roofs tiled world-triplanar after the first look), Guild banners/sign/board,
  Bathhouse dome, Mage Tower with its cap. Weak spot: on a single house the plinth/sign changes are small from
  a street-level eye; the chimneys and pennants read best from above.
- Checks: parse 0 script errors (the 3 old 'material is null'), _offfloor 0 of 934, TWITCH_PARSE OK, TOWNWALK
  in_solid 5/6482 (0.077%) raid 0/4102 PASS, _delve_test ran with 0 script errors.


## Cycle 65 - D4: more guards and the mounted watch (desktop, 2026-11-11)
- Lore: the original town.gd _chief_spends grows the standing garrison with the danger ("3 + raids/2" guards,
  each "%s is sworn into the watch."). Bellmire HD grows it with the town level instead. Horsemen are the plan's
  ask (town guards only); named "the mounted watch". (D3's box in WORK_PLAN was left unticked last run - ticked.)
- town.gd (.bak_d4) _spawn_garrison() after _spawn_animals, own rng (seed 4404) so the old townsfolk are unchanged:
  every gate/scar post manned (8 posts, was 5 guards); a second crossbowman on each of the 3 watchtowers; four
  more watch pairs on new beats - inside the curtain wall (from level 1), the market ring + tavern (1), market ->
  bridge -> far bank (3), the wall the other way (5): watch walkers 12/12/14/14/16/16 at levels 1-6.
  Riders: 2 at level 4 (the Town Stables open), 3 at 5, 4 at 6; they wait in the stable yard, then ride every gate
  (in, out 18 m, back), the market and the bridge; odd riders the other way round. town.show_level ->
  _show_garrison shows/hides them (hidden ones stop processing) with feed lines. Trader/innkeeper market spots are
  now snapped to open ground.
- scripts/cavalry.gd (new, class_name Cavalry extends Townsfolk): the Quaternius CC0 Horse (assets/animals, now with
  a LICENSE.txt) under a Knight in garrison livery, seated (Sit_Chair_Idle) at 0.6 of the horse's height; the
  horse's gait (Idle/Walk/Run + speed scale) comes from how fast the pair really moves; walking uses Townsfolk's
  navmesh routes. raids.gd (.bak_d4): riders fight as guards (hp 80, atk 13, AC 13, +4, speed 9), the rider only
  swings the sword (no running legs on a horse), "The mounted watch rides out to meet them - N riders."
  Tower archers: every ~2.4 s each lookout looses a bolt at the nearest raider within 42 m; the bolt flies and
  the d20 (+3, 9 dmg) is rolled on landing.
- tools/_d4_test.gd (headless): posts manned, 2 per tower, watch grows, riders 0/0/0/2/3/4, news, riders seated,
  3000 frames of riding (270-350 m each, 0/600 samples inside a building after moving the stable stop off the
  barn's footprint - first runs had 4-13/600 from riders waiting at the door), a west-road raid: all 4 riders
  engage, archers loose 4-5 bolts, the raid is driven off. D4_TEST OK.
- tools/_d4_shot.gd -> renders/cycles/20261111_d4: rider_front/side/road, patrol_above, tower_archers, gate_post,
  raid_start/ride/fight/fight2. Looked at: the riders sit astride and gallop in file at the raid, two crossbowmen
  on the tower top, gate post. Weak spots: the first rider shots caught them still in the stable yard (the shot
  waits only 300 frames); the chibi Knight is big for the horse - reads as mounted, but a smaller rider body
  (L6 models) would look better.
- Checks: parse 0 script errors (the 3 old 'material is null'), _offfloor 0 of 1042, TWITCH_PARSE OK, TOWNWALK
  PASS (0.095%, 0.102%, final 0.081% raid 0%; one run before the fixes was 0.288% FAIL - the same trader/innkeeper
  pressing into a house by the market, a D1 leftover, not the new walkers), _delve_test ran with 0 script errors.



## Cycle 64 - L7, the soak with the new content (laptop, 2026-11-11)
- tools/_soak_l7.gd (new, from _soak.gd): six fake viewers on the new callings and peoples - dwarf paladin,
  scarkin necromancer, halfling monk, elf druid, orc warlock, human bard - forging their own kinds (spear,
  wand, wraps, staff, staff, sword); also counts finds, uniques, lords and enrages. Window, director on, 4x.
- Run 1 got a window close request at 7.75 min (not from the tool); run 2, after the D2 laptop fix, ran the
  full 30 wall minutes = 68 valley days: 0 script errors; memory flat 470-527 MB; 24 delves in, 23 home, 0
  wipes; 31 lords risen (5 enraged), 14 rare uniques, 10 deep-floor gear finds; 7 viewer deaths, 6 rerolls;
  39 raids driven off; the director cut to lords 45 times, fights 56, raids 45. Frames
  renders/cycles/20261111_l7_soak - looked at: the band splitting the Rattling Host's hoard below; the Pale
  Duchess's red "Enraged." card while the camera follows a viewer on the square; nothing broken.
- Not mine, for the record: FPS here (this laptop's GPU) slid 35 -> 26 as settlers grew the town 148 -> 214
  (the D7 issue). Every minute has one ~1.5 s frame - the same before L1 (measured headless, old scripts
  1.46 s vs now 1.43-1.69 s), so it predates this work (likely a floor being built in one frame). Only 3
  fishing trips were ordered in 30 min and no catch line reached the Chronicle.
- L6 stays open: no new CC0 character bodies are reachable from here (see WORK_PLAN).


## Cycle 65 - L6, new character bodies (laptop, 2026-11-11)
- Mr. E asked for the pack to be fetched: KayKit Adventurers 2.0 FREE (CC0, licence checked) from Kay's own itch.io
  page through its free-download flow, 13 MB; kept Characters + the Rig_Medium animations + the licence in
  assets/characters/kaykit_adv2 (SOURCE.txt records where it came from).
- The 2.0 bodies ship with no animations and the free tier has no attacks or casts - but Rig_Medium has the same
  bones and rest poses as the 1.0 rig. tools/_bake_adv2.gd re-paths all 76 1.0 animations onto it (IK-only tracks
  dropped), lays 2.0's own idle/walk/run/hit/death/jump over them (Idle_A plays as "Idle"), saves one shared
  adv2_anims.res and six hero_<Name>.tscn scenes. Nothing outside the laptop's files changed: Roster.CLASSES
  model points at them through the 1.0 folder HeroBody already prefixes (Roster.ADV2).
- Every calling now wears a 2.0 body; the ranger gets the new Ranger body (scarf, own look). Gear: the hooded
  rogue's hood is part of its 2.0 head mesh, so only separate "...Hat" meshes take a calling's colour (the warlock's
  face had gone solid violet); the 2.0 RogueHooded_Mask is kept as body, not stripped as a prop.
- Renders renders/cycles/20261111_l6 (callings front/close/back, a Hollow King fight) - looked at: 2.0 detail
  reads, weapons in the hands, species parts and armour sit right, attacks and casts play in the delve.
- Townsfolk still wear the 1.0 bodies (townsfolk.gd is the desktop's): the same scenes are ready for it.
- Checks: parse 0 script errors, _delve_test ENDED all home, _offfloor 0 of 528, TWITCH_PARSE OK, L3, L4, L5,
  D2_DELVE OK.


## Cycle 66 - D5, more animals (desktop, 2026-11-12)
- No CC0 hen or cat in the packs we hold (lore has none either: one "named livestock" note), so scripts/animal.gd
  (.bak_d5) builds them from shapes: "proc:hen" (4 feather colours, comb, beak, legs that step, pecks when idle)
  and "proc:cat" (5 coats, ears, green eyes, swaying tail, settles low and naps 8-30 s). Animal.kind / .edge added.
- Every animal now refuses a wander target, or a straight walk to one, that crosses a building footprint
  (town.solid_at, 0.35 m margin) and stops if a stall/house is in the next step; town._animal() starts each
  one with keep_walkable() (the market dogs used to start inside stalls: 6-8 in_solid samples before the fix).
- town.gd (.bak_d5) _spawn_more_animals(), own rng 5055 so the old herds stay put: a 7x6 m fenced hen run beside
  each farmhouse (5-7 hens, 19 in all; the farm yard is in _objs so is_clear() refused everything - tested against
  footprints 6.5 m, pens, fields, road, river instead); a Corgi sheepdog that walks the edges of each sheep pen;
  two more horses and a Foal (Horse.glb at 0.17) in the paddock; 8 cats on street edges within 62 m of the
  square; 3 crows wheeling over each of 5 fields.
- tools/_d5_test.gd: 74 animals (Hen 19, Cat 8, Horse 5, Foal 1, Duck 19, sheepdog 1 per flock...), 3000 frames
  at 4x: in_solid 0, on a roof 0, out of pen 0 of 22200 samples; hens and cats wander. D5_TEST OK.
- tools/_d5_shot.gd -> renders/cycles/20261111_d5 (hens_close, hen_run, cat_close, cat_street, sheepdog_flock,
  paddock_foal, paddock, crows_field, farm_above). Looked at: hens read as hens, the black and ginger cats sit by
  houses, horses + foal graze, crows over a field, sheepdog among the flock. Weak spots: the shapes are simple next
  to the Quaternius animals; the sheepdog is a little small for the sheep; only 3 farmsteads so 3 hen runs.
- Checks: parse 0 script errors (the 3 old 'material is null'), _offfloor 0 of 1039, TWITCH_PARSE OK, TOWNWALK
  PASS (0.098%, raid 0%), _delve_test ran with 0 script errors.

## Cycle 66 - L8, wild magic below (laptop, 2026-11-11)
- Merged origin/main (desktop D3; Mr. E's DnD RULE, L8, L9). WORK_PLAN conflict: kept L6 ticked (done in
  Cycle 65 - the pack is in assets/characters/kaykit_adv2) and the new L8/L9. A --headless --import was needed
  for the desktop's new Cavalry class before the parse check was clean.
- Delve._scar_check: every spell a delver casts below is a check against the scar - d20 + casting mod +
  proficiency vs DC 10 + floor/2 (cap 20). Casting mod per Mr. E: INT mage/sage/necromancer, WIS
  cleric/druid/monk, CHA warlock/bard/paladin. A fail calls Spells.cast(..., in_scar = true): the next spell in
  the order goes off, with the scar's crackle. A natural 1 always misfires, a natural 20 never. Monsters' spells
  are not checked. What the misfire does: a blow turned into a mending mends the creature (half the caster's
  attack); a mending turned into a blow (renew -> bolt) hurts the friend it was meant for (half the heal).
  One Chronicle line per caster per floor: "MossyMage's bolt goes wrong - the scar answers (12 vs DC 15)."
  Note: the sage's own sheet uses WIS (to-hit, healing); for this check it is INT, as written in the plan.
- tools/_l8_test.gd (headless, new): 12000 checks per case against the exact 5e odds - floor 1/6/14/30 (DC 10/13/
  17/20), a strong caster (+9) and a weak one (+1): every rate within 1% (e.g. weak at DC 10: 0.402 vs 0.400,
  strong at DC 20: 0.500 vs 0.500); the DC caps at 20; an unbeatable caster still misfires ~5% (nat 1), a hopeless
  one at DC 20 still lands ~5% (nat 20); each calling checks its own ability; a real floor-6 delve checks and
  misfires. L8_TEST OK. (First run used an unseeded RNG and one rate came out 4 sigma low; seeded, all match.)
  tools/_l8_shot.gd: renders/cycles/20261111_l8 - looked at: Mourncoil on floor 10, two misfire lines in the
  Chronicle beside its frost line.
- _d2_delve_test's "every spell seen" checks are now chance-dependent (misfires swap kinds); it failed once in
  three runs, passed twice. Checks: parse 0 script errors, _delve_test ENDED all home, _offfloor 0 of 459,
  TWITCH_PARSE OK, L4 OK.


## Cycle 67 - L9, the roll audit, dungeon side (laptop, 2026-11-11)
Per Mr. E's DnD RULE, everything a delver does below is now a d20 or dice roll on the hero's real numbers.
- Damage dice: each weapon tier has dice (bare 1d4, plain 1d6, fine 1d8, runed 1d10, dragontooth 1d12,
  scarforged 2d8; Roster/Gear WEAPONS "dice"). A blow = the dice + the ability mod + a flat part that keeps the
  average exactly where it was (0.75 x Roster.attack + kit), so the measured balance holds; a crit rolls the
  dice twice (5e). Creatures hit on 2d6 of their base (same mean 0.8). The hero sheet shows the dice.
- Creature attacks: d20 + to-hit vs the delver's AC, a natural 1 always misses, a natural 20 always hits and
  doubles. Spell saves: fire burst DEX save for half, frost CON save against the slow, both vs the caster's
  spell DC (8 + prof + casting mod); creature save d20 + floor/3 (+2 a lord), nat 1/20.
- Initiative each floor: d20 + DEX for delvers, d20 + 1 creatures; the high roll swings first.
- Traps are live: dungeon_hd records them (info["traps"]); the first delver to step within 0.9 m rolls
  Perception (d20 + WIS, + prof for rogue/ranger/monk, disadvantage in the dark without darkvision) vs DC 10 +
  floor/2 - spotted, stepped round; missed, it goes off: a DEX save halves 2d6 + floor (spikes), 2d8 + floor
  (fire), 1d10 + floor (pressure plate's stone). Each a Chronicle line.
- Loot: the party's sharpest eye makes an Investigation check (d20 + INT, + prof for rogue/ranger/mage/sage/
  necromancer) vs DC 10 + floor/2 - it sets the gold (fail x0.8, beat it up to x1.35, nat 20 x1.6, nat 1 x0.6),
  the salvage and potions, and whether deep gear turns up (nat 20, or a total of 25 - floor/2, -5 for a lord).
- Death save: still one per delve (old rule), DC 10 CON; a natural 20 stands them up with a quarter of their
  life, a natural 1 is death.
- Shops: CHA no longer cuts every price flat. Each purchase is a Persuasion check at the counter (d20 + CHA,
  + prof for bard/warlock/paladin/rogue) vs DC 12: 10% off +1% a point over (max 20%); nat 20 a quarter off;
  nat 1 a tenth over; the line says so ("Haggled 11% off (13)."). The guild-rank discount stays on the list price.
- Big rolls in the Chronicle, once per delver per floor: a natural 20 that kills ("rolls a 20 - and the drowned
  skeleton mage is gone.") or lands on a lord ("BigAxe rolls a 20 - Gnawbone reels."), 20s on initiative,
  searching and death saves. (First pass announced every 20: four lines a floor - cut to kills and lords.)
- Mr. E: the sage's scar check (L8) uses WIS, its own sheet - Delve.CAST_STAT changed; L8_TEST OK with it.
- tools/_l9_test.gd (headless, new): every tier's mean equals the old (e.g. runed 25.05 vs 25.05) with the dice's
  exact spread; crits; creature 2d6 mean; haggling odds for CHA +0 (5/5/40/50%); spell save odds (0.493 vs 0.500);
  the sheet; a real delve: initiative swings, every trap on a floor rolled for, traps across the run. L9_TEST OK.
  tools/_l9_shot.gd: renders/cycles/20261111_l9 - looked at: Gnawbone with the misfire, the brood and the 20 lines.
- Checks: parse 0 script errors, _delve_test ENDED all home, _offfloor 0 of 453, TWITCH_PARSE OK, L1, L3, L4,
  L5, L8 OK. (The town side - fishing, the town's work - is the desktop's part of the rule.)


## Cycle 68 - monsters walk and swing again (laptop, 2026-11-11, urgent from the live stream)
- Mr. E saw it live: creatures and lords glided along the floor and never swung. tools/_mon_anims.gd (new) spawns
  every def - all 21 creatures, the eight lords, the five uniques - and reports model, AnimationPlayer, its list,
  and which of idle/walk/run/attack/cast/hit/die/rise exist. Every def HAD its names (34 of 34 idle+walk+attack).
  Then it watches a real fight: walking skeletons showed their walk on 0 of 821 moving frames, and nothing was
  ever seen swinging. The cause was in Monster, not the assets: Delve drives each creature (state IDLE, then
  _play("walk") / _play("attack")), but Monster._process replayed "idle" every frame in state IDLE - so every
  walk and swing was undone the next frame and the body slid along in a frozen blend.
- monster.gd: outside calls go through _play (stamps the time); the body's own idle only plays when nobody has
  driven it for 0.3 s; a one-shot (attack, cast, hit, summon, rise) owns the body until it ends (only death
  cuts it short), so a swing finishes. busy() says so, and Delve no longer walks a creature mid-swing, mid-rise
  or reeling (the raised dead slid while climbing out of the floor).
- Walls and props: creature centres were never in a prop or off the floor (MON_INPROP 0 of 315 in three runs
  before the fix), but a creature was moved as a point - a lord's or a wide beast's body hung half into the wall
  beside it. Delve._step now keeps a creature its own half-width (height x 0.2, 0.3-1.8 m) off any wall cell.
  Nightwing's swoop lands on the floor beside its mark, never in the wall behind it.
- tools/_offfloor.gd also counts monsters inside props (MON_INPROP) now.
- Checks: _mon_anims MON_ANIMS OK on floor 5 and floor 8 (every def idle+walk+attack; every moving creature plays
  its walk, e.g. risen bones 1373 of 1373 frames; every creature seen swinging); _offfloor 0 of 486, INPROP 0,
  MON_INPROP 0 of 110; _delve_test ENDED all home; TWITCH_PARSE OK; L1 (twice), L2, L8, L9, D2_DELVE OK.
- Render renders/cycles/20261111_monanims (tools/_mon_fight_shot.gd, new): the real town's light, floor 5, the
  Rattling Host with a bone bowman, a sentinel and a spider called beside it; frames taken only while the lord
  is playing its attack - looked at: the Host's axe raised high over the knight, the bowman and sentinel by it.
- Mr. E's other note (the sage's scar check on WIS) was already done in Cycle 67.


## Cycle 69 - D6, Bellmire's named people (desktop, 2026-11-11)
- Lore first (reference town.gd ROSTER + FIRST/LAST): the old valley already had the chief in his hall, the smith,
  the chapel healer, the innkeeper. Those bodies are PROMOTED (same role and work door, so the economy counts them as
  before - no doubles); the crier and priest already on the square/chapel steps too. New, named in the same voice:
  the bard, a pedlar with her cart, two children, a beggar, the town drunk.
- scripts/notables.gd (new, class Notables; town.notables): 12 people - Aldric Ashwood (Chief of Bellmire, lives in
  his hall), Garm Coalfoot (the Smith), Ysolde of the Ford (Healer), Rolf Thatcher (Keeper of the Tavern), Osric
  Hollow (Priest), Cort Rivers (Crier), Wren Bramble (Bard), Petra Fenwick (Pedlar + wagon), Tove Bramble (the bard's
  girl), Dunn the Younger, Harl Quarryman (Beggar), Rask Stonehand (the Town Drunk). Each: own body/tint/size/cape,
  a kit (bard pipe + songbook, beggar's empty mug, drunk's full one), a gold "Name / title" tag shown up close even
  with names off (N still shows all), gestures while at their spot (sermon, playing, begging).
- Days: hour slots [from, to, place, tag] read off the town clock; on a new slot they get Townsfolk.stops, so every
  step is still the navmesh + doors (D1). Bellmire is wide (square -> tavern ~120 m is half a town day on foot), so
  each day keeps to one quarter and they live near their work (nearest house whose door the streets reach); the
  drunk sleeps in the tavern's back room by day, staggers round it 1-6 at night.
- Chronicle: one named line every 28-55 s from whoever's slot has lines ("Garm Coalfoot quenches a blade and swears
  at it."); the crier shouts the latest Chronicle news ("Hear ye! Floor 2 cleared."), his shout now sits above a
  named person's two-line tag. No other townsfolk keeps a named person's name (rechecked as settlers arrive).
- Found on the way: TownNav.closest() (town._snap) answers (0,0,0) for a while after start - the square's spots all
  snapped onto one point and stacked four people; Notables._ground() falls back to keep_walkable(). Worth a look for
  D4's _snap beats (not changed here).
- townsfolk.gd (.bak_d6): notable_title, sway (the drunk's weave), _tag, make_notable(); rts_camera.gd (.bak_d6): N
  keeps named tags; town.gd (.bak_d6): notables hook after _more_folk, spawn_wagon().
- tools/_d6_test.gd (headless, new): 12 named, unique names and looks, lore roles promoted not doubled, 2.2 town days
  at 4x: 71 slot changes, 86% reached in their slot, 4-5 named Chronicle lines, crier read news, drunk out 0/134 by
  day and 96/96 at night, 0 in_solid of 7106 (townwalk's test). D6_TEST OK. tools/_d6_shot.gd -> renders/cycles/
  20261111_d6 (square_named, crier_reads, bard_plays, pedlar_cart, chief_east_market, smith_at_smithy,
  priest_chapel_steps, healer_rounds, drunk_at_night) - looked at: tags readable, smith at his forge, the square's
  four apart (first pass: two shots inside walls and the stack - fixed).

## Cycle 69 - L11, traps that visibly work (laptop, 2026-11-11)
- Merged origin/main (desktop D4/D5; LAPTOP list 3; the UI files are the laptop's now). Import pass, parse clean.
- Mr. E: traps "don't show functioning or doing damage". They looped their animation forever whoever was near.
  Now every trap is armed until something steps on it and carries meta "fire" (its trigger). dungeon_parts.gd:
  spikes, pressure plate, fire grate made armed; new dart trap (darts fly across from two posts), blade trap
  (a scything blade sweeps up out of a floor slot), pit (two boards drop open over a dark shaft). All six are
  laid by dungeon_hd and recorded by kind.
- Delve._meet_trap: Perception (d20 + WIS, + prof rogue/ranger/monk, disadvantage in the dark without
  darkvision) vs DC 10 + floor/2. Spotted by a rogue or bard: thieves' tools, d20 + DEX + prof - disarmed, or
  failing by 5+ sets it off on them; spotted by anyone else: stepped round. Missed: the trap plays, the sound,
  a DEX save halves the dice (spikes 2d6, darts 3d4, fire 2d8, blade 2d8, pit 2d6, a plate's stone 1d10; + floor/2),
  the damage floats up red over the hero (amber if halved), and the Chronicle: "BigAxe steps on a loose
  flagstone - darts! DEX 7 vs DC 11, 10 damage." Ward soaks it; a fall can kill (death save as ever).
- Found on the way: a Label3D under a HeroBody is renamed to the hero's name by its own label code - the floating
  numbers came out as giant names. They hang off the floor now.
- tools/_l11_test.gd (headless, new): all six kinds play their trigger and do damage when sprung; DEX saves at
  0.459 vs the exact odds 0.450; a rogue disarms 273 of 400 spotted traps; a barbarian who spots one steps round.
  L11_TEST OK. tools/_l11_shot.gd: renders/cycles/20261111_l11 - looked at: the blade sweeping through BigAxe,
  fire under the mage, the pit's boards open, -7 / -9 / -10 floating, the six lines in the Chronicle.
- Checks: parse 0 script errors, _delve_test ENDED all home, _offfloor 0 of 413 (MON_INPROP 0), TWITCH_PARSE OK,
  L9_TEST OK.


## Cycle 70 - L12, potions and states (laptop, 2026-11-11)
- data/potions.json (one source): 12 brews in Bellmire's voice - Draught of Mending 2d4+2, Greater 4d4+4, Superior
  8d4+8, Supreme 10d4+20 (the 5e tiers), Bitterleaf Tincture (antidote), Emberward / Hearthwarm (resist fire /
  frost), Quickwater (haste), Ogre's Draught (giant strength), Shadowcloak (invisibility), Bravecup (heroism),
  Owl-eye Drops (darkvision) - each with a cost, the town tier its apothecary needs, aliases and a flavour line;
  and the states, each with its word, colour and what it does.
- The bad states and where they come from: poisoned (venom: now disadvantage too), burning (fire traps, the
  grave-fire breath, the Hollow King's and Cinderjack's rings; 1d4 a second), slowed (frost), blinded (Nightwing's
  swoop, CON save DC 12; foes get advantage), frightened (a lord rising: WIS save vs DC 10 + floor/2). Emberward /
  Hearthwarm halve fire / frost and stop burning / slowing; Bravecup stops fear (+10 temporary hp); any Mending
  puts a fire out. Good states: hasted (swings a third faster), ogre-strong (+2 to hit, +4 damage), unseen (foes
  cannot pick them; advantage on the first blow, which ends it), heroic, owl-eyed (no disadvantage in the dark).
- Heroes finally drink below (the HD delve never had): the best Mending under a third of their life; the cure for
  what ails them; Ogre's / Quickwater / Shadowcloak / Bravecup when a lord fights; Owl-eye in the dark. A drink
  costs the swing and floats its number or word; the Chronicle names any brew but plain Mending.
- !brew [n] buys Mending as before; !brew <potion> [n] any brew (names or aliases: !brew haste 2), haggled, locked
  by the town's tier ("Bellmire's apothecary cannot brew it yet"). !inventory lists them. A good Investigation
  below finds a vial ("X finds a vial of Quickwater."), better ones deeper.
- Shown: coloured state tags under each delver's bar in the party frames, and under each name below. First pass
  the overhead tag sat on the name; moved into the billboard's own plane just under the name.
- Found on the way: a Godot editor open on this laptop saved delve.gd from its buffer (all tabs, one of this
  cycle's fixes lost); re-applied. A typed lookup of a tag freed with the last floor errored; untyped now.
- tools/_l12_test.gd (headless, new): data and aliases; tier lock; !brew haste 2; !brew 3; !inventory; Supreme
  heals 35-56; poisoned -> disadvantage -> Bitterleaf cures; Bravecup; Emberward; burning 1d4/s; unseen advantage;
  a low delver drinks Mending; a real lord floor: frightened at the rise, Ogre's Draught drunk. L12_TEST OK.
  tools/_l12_shot.gd: renders/cycles/20261111_l12 - looked at: Nightwing, the party frames with "ogre-strong heroic",
  the tags under the names.
- Checks: parse 0 script errors, _delve_test ENDED all home, _offfloor 0 of 422, TWITCH_PARSE OK, L3, L9, L11 OK.


## Cycle 70b - L11 test fix (laptop, 2026-11-11)
- Mr. E: tools/_l11_test.gd spammed "Condition !is_inside_tree() is true" (get_global_transform). The test's save
  and disarm loops hand Delve trap nodes that are never added to the tree, and _spring read their position for the
  sound, _float_text the body's. Delve now plays the trap sound and floats text only for nodes in the tree (a real
  floor's traps and delvers always are). _l11_test: L11_TEST OK with 0 errors / 0 "Condition" lines.


## Cycle 71 - L13, more equipment and cosmetics (laptop, 2026-11-11)
- data/items.json (one source). Accessories, a small 5e bonus each, named in the valley's voice: Ring of the Night
  Watch (+1 AC), Ferryman's Ring (+1 saves), Hearthstone Amulet (+12 hp), Lamplighter's Amulet (+1 saves), Guild
  Cloak (+1 AC), Mire-walker's Cloak (+1 saves), Boots of the West Road (+0.6 speed), Soft Boots (+1 to hit),
  Smith's Gauntlets (+2 damage), Fletcher's Gloves (+1 to hit) - one per slot (ring, amulet, cloak, boots, gloves).
  Roster.acc_bonus feeds armour_class, save_bonus, max_hp, speed, attack_bonus and the damage dice.
- Cosmetics (look only): four hats (wide-brimmed, feathered cap, straw, ash-wood circlet; they hide the body's own
  hat or helmet), four district banners on the back (keep blue, market red, craft yellow, homes green), four pets
  from the CC0 farm animals (corgi, pug, duck, fox - scripts/hero_pet.gd heels beside the hero, walks to catch up,
  idles when they stand), six titles shown under the name (the Lamplighter, Keeper of the Door, Friend of the Ford,
  Scarwalker, Counter of Grain, Bell without a Clapper), and ten dyes for the armour pieces and the cloak.
- !wear <item> (any unique word of its name: !wear corgi, !wear night watch) buys it once (haggled) and wears it;
  owned items are worn again for nothing; !wear off <slot>; !dye <colour> (25 gold). !inventory shows the title,
  the accessories and the dye. Gold now; channel points later (T1).
- Visible: a ring at the left wrist, an amulet on the chest, gloves, boots where no armour boots are, the cloak's
  colour, the hat, the banner, the pet, the title (a Label3D one level under the hero so its label code leaves it).
- First render: the corgi stood 120 m tall - the farm-animal models are authored ~100x (the town scales them
  0.0019); pets now use the town's scales. Titles came down to a smaller size.
- tools/_l13_test.gd (headless, new): the data; AC / saves / hp / speed / to-hit / +2 damage in the numbers; the
  ring slot; owned is free; pet, title, dye, unknown colour, unknown item, !wear off, no gold; !inventory; every
  piece on a dressed body; one pet after re-dressing. L13_TEST OK. tools/_l13_shot.gd: renders/cycles/20261111_l13
  - looked at: six heroes front and back in their hats, banners, dyes, pets and titles.
- Checks: parse 0 script errors, _delve_test ENDED all home, _offfloor 0 of 441, TWITCH_PARSE OK, L3, L5, L12 OK.


## Cycle 72 - L14, the command list from one source (laptop, 2026-11-11)
- data/commands.json: every chat command - name, aliases, arguments, list cost, what it does (and a short stream
  line for the long ones), an example, whether it needs a hero - plus the cooldowns and the order.
- ChatCmd reads it: aliases resolve from the data (new: !stats / !sheet for !hero, !commands / !valley for !help);
  !help is the short list; !help <command> one line in detail for the Chronicle (short line, cost, example). A
  near miss of a real command gets a nudge ("No !forg here - did you mean !forge?"); other bots' commands
  (!discord, !so) are left alone. Gold replies all read "X needs 43 gold for leather - you have 30."
- tools/_commands_doc.gd writes docs/COMMANDS.md from the same data (the hub / website can read the JSON).
- tools/_l14_test.gd (headless, new): all 29 verbs in ChatCmd's match are in the data and all 20 commands are
  answered; aliases; !help names every command; typo nudge; other bots ignored; friendly gold; the doc carries every
  command. L14_TEST OK. tools/_l14_shot.gd: renders/cycles/20261111_l14 - looked at: the replies in the Chronicle;
  first pass !help forge took seven lines, the short stream line brings it to three.
- Checks: parse 0 script errors, TWITCH_PARSE OK, L3, L13 OK.


## Cycle 73 - D6b, the nav snap and the long door legs (desktop, 2026-11-11)
- Cause: the server's map reports iteration id > 0 about 40 frames before the town's region is in it; in that window
  map_get_closest_point answers (0,0,0) for everything (420 of 600 probes at the origin in the first second).
- TownNav.synced(): the region is in the map AND one of the mesh's own vertices (one well away from the origin) snaps
  back onto itself; cached once true. closest() / path() give no opinion until then (flat p / []), and town._snap
  falls back to keep_walkable (the town's own push-out of solids) - never the origin.
- Found while re-checking: traders get an open-air spot on the square, but kept the old plot's inside point, so their
  "door leg" ran 30-47 m straight through the houses (Maela of the Ford, Petra Bramble). work_in is cleared now.
  And a door leg left after the stuck-waypoint give-up (Harl of the Ford, 17 m to the tavern door) re-routes along
  the street to the door once, else leaves the house be. _townwalk had drifted 1-23 bad samples run to run; now 0.
- tools/_d6b_test.gd (headless, new): _snap + closest probed every frame for the first second - 0 at the origin, 0
  far; the watch's 90 beats and the traders' spots - none at the origin, none collapsed; people stacked on one spot
  (63 pairs at frame 61, at shared doors) clear within 15 s (3). D6B_TEST OK. tools/_d6b_shot.gd:
  renders/cycles/20261112_d6b - looked at: the square at frame 60, just after the sync, people spread over it.
- Checks: parse 0 script errors, _townwalk in_solid 0/7923 and 0/8317 PASS, _offfloor 0 of 1120, TWITCH_PARSE OK, _delve_test
  runs (0 script errors), D4_TEST OK, D6_TEST OK.

## Cycle 74 - L15, stream readability (laptop, 2026-11-11)
- scripts/ui_theme.gd (new, UiTheme): sizes are written for 1920x1080 and follow the window height; F11 cycles a
  UI scale of 100 / 125 / 150% (a Chronicle line says which); panels watch it and restyle.
- At 1080p, 100%: Chronicle lines 28 px (title 24, the lord's card 46 / 28), 5 lines, wider (760), darker ink on
  the older lines; Guild Roll title 30, lines 26, fallen 22, higher-contrast gold and grey; party frames names 28,
  numbers and states 22, 400 wide - moved to the top-left under the key help (the Chronicle owns the bottom-left);
  boss bar title 44, numbers and subtitle 26, 780 wide, under the help; unit frame name 32, text 24; key help 19.
- Bigger scales adapt instead of colliding: the Chronicle shows 5 / 4 / 3 lines, the Guild Roll sits on the right
  below the boss bar's band with fewer rows (and no Fallen at 150%), the boss bar keeps its width (text grows),
  the party frames leave the states to the overhead tags at 150%.
- Names in the world: a hero's name tag now grows with camera distance past 16 m (up to 3x) so it stays readable
  from the high stream camera - one line in hero_body.gd (on neither machine's list; L15 asks for name tags). The
  same rule for creature names (monster.gd) and the state tags under the names (delve.gd).
- tools/_l15_shot.gd (new; --resolution 1920x1080): the town, a lord fight below, the Chronicle, the roll, saved at
  1080p and shrunk to 854x480 - LOOKED at the phone frames: at 100% every panel line and hero name reads; at 150%
  first pass everything overlapped, after the adaptations nothing does. renders/cycles/20261111_l15.
- tools/_l15_test.gd (headless, new): a Chronicle line 28 px and a roll line 26 px at 1080p; px() maths; F11
  100 -> 125 -> 150 -> 100; the Chronicle restyles bigger at 150%. L15_TEST OK.
- Checks: parse 0 script errors, _delve_test ENDED all home, _offfloor 0 of 458, TWITCH_PARSE OK, L12 OK, BOSS_TEST OK.


## Cycle 75 - L16, one theme for every panel (laptop, 2026-11-11)
- UiTheme now carries the house style: parchment (0.93, 0.86, 0.69) with an inked edge, ink / soft ink / red-brown
  ink text, the JestSayin teal as the one accent (a teal diamond before every title and a teal rule under it, the
  chat box's focus edge), viewers' names in deep gold and the town's band in slate, inked HP bars (green / amber /
  red), and TITLE / BODY / SMALL sizes. Nothing from the old game's interface.
- Every panel built from it: the Chronicle and the Guild Roll (house titles); the party frames (parchment block,
  house title "Delvers · floor 5", oil in ink, name and numbers riding on the inked bar, states under it, darkened
  to read on parchment); the boss bar on a parchment plate whose edge is the lord's own colour, its name in that
  colour inked dark; the unit frame on parchment; the key help and the speed as parchment chips; the chat box a
  parchment chip with a teal focus edge, moved bottom-right, clear of the Chronicle.
- First render: the party frames with a bar under each name grew into the Chronicle's title - back to the compact
  row (name on the bar); the chat box sat on the Chronicle - moved.
- tools/_l16_test.gd (headless, new): the Chronicle, the roll and the boss bar on the house parchment; titles carry
  the teal; the unit frame, chips, chat and party frames build from the theme. L16_TEST OK. tools/_l16_shot.gd:
  renders/cycles/20261111_l16 - looked at the whole interface at 1080p: one design, nothing overlapping.
- _l15_test reads the roll's first row (its title is a themed block now). Checks: parse 0 script errors, _delve_test
  ENDED all home, _offfloor 0 of 431, TWITCH_PARSE OK, L15 OK, BOSS_TEST OK.


## Cycle 75b - L16 phone test fixes (laptop, 2026-11-11, Mr. E)
- Phone test on the themed UI: tools/_l16_phone.gd (new; --resolution 1920x1080) - the market square, four heroes
  with cosmetic titles, the crier calling - saved at 1080p and shrunk to 854x480, LOOKED at, then F9.
- 1. Titles: shown only on the selected hero (the director's focus selects too); F9 shows every hero's. A shown
  title rides one line under its hero's name label - same size rule and lift as the name, so the names' own
  spread keeps titles apart and inside the view; long titles shortened to 22 characters. (First pass they sat tiny
  at the heroes' feet.)
- 2. Speech bubbles (townsfolk shout lines, the crier): UiTheme.style_bubble / fit_plate - ink on a parchment plate
  sized to the words, FIXED on-screen size (~28 px glyphs at 1080p at any distance), drawn over the ground. Two
  calls in townsfolk.gd (the desktop's file), at Mr. E's request; nothing else there changed.
- 3. The key strip: hidden by default (H shows it), on its parchment chip, scaled with the UI scale (L15/L16).
- Also: the hero unit frame moved bottom-right (it sat on the Chronicle in the phone frame).
- Checks: L13, L15, L16 OK, TWITCH_PARSE OK.

## Cycle 75a - L19 in progress: barks as speech bubbles (laptop, 2026-11-11)
- Hero barks ("Count the flasks.", "Bottoms up.") now show as the same parchment speech plate as the crier's in town (UiTheme.style_bubble / fit_plate), over the delver's head for 3 s, instead of floating words that piled up with the state words.
- The state word on a new status (e.g. "frightened") no longer floats; states show in the party frames and under each hero.
- Looked at: renders/cycles/20261111_l19/pale_duchess_fight_2.png (bubble readable, no pile-up).
- L16 (Cycles 74, 74b) is committed and pushed (8d9c295).

## Cycle 75 - L19, more lore (laptop, 2026-11-11) - done
- data/lore_lines.json: origin tells (one per delve, first floor only), lord and unique intros, hero barks (enter, lord, trap, hurt, drink, misfire), varied descend/cleared/misfire Chronicle lines, epitaphs on the fallen (!memorial reads them), forge words per tier, town-level lines offered to the desktop. All in the original's voice (the Chief's Hall inscription, the architect's toys, the bell with no clapper, the scar); no line states a floor count (tested).
- Barks are parchment speech bubbles (Cycle 75a); _hero_hit no longer touches a body that has left the tree.
- Tests: _l19_test (checks + FEED: tell on the first floor only, Grubmother intro), _l12_test OK, _delve_test, _offfloor, _twitch_parse OK.
- For the desktop: "Lambda capture at index 0 was freed" (1-3 per delve test, also before L19) comes from spells.gd timers/tweens firing after a floor is freed (chain hops, _fly callbacks capture root).
