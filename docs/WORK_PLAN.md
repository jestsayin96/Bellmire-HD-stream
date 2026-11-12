# WORK PLAN 2 — Bellmire HD grows (Nov 11 2026 onward)

Two machines work at once, on DIFFERENT files so they never clash:
- DESKTOP (CruzaderPC, scheduled build runs, branch `main`): the town, its people, magic. Lock: docs/RUN_LOCK.txt
- LAPTOP (jestai, its own Claude Code session, branch `laptop`): monsters, bosses, gear, classes, species.
  Lock: docs/RUN_LOCK_LAPTOP.txt. It pulls `main` and merges it into `laptop` before each item; Claude in the
  main chat merges `laptop` into `main` when an item is tested.

Each run: take the FIRST unchecked item in ITS OWN section. Same loop as before: read the code, edit, parse
check (0 SCRIPT ERROR / Parse Error), the item's test + render + LOOK, the standard checks (_delve_test,
_offfloor, _twitch_parse, _townwalk), tick it here with one line, PROGRESS.md cycle, commit + push
(desktop -> main, laptop -> laptop), lock IDLE.

DnD RULE (Mr. E, Nov 11): the game is D&D at heart - almost every action is decided by a ROLL, not a
flat chance or a fixed number. Attacks: d20 + to-hit vs AC; damage: weapon dice + mod; saves: d20 + save
vs DC; skills (fishing, haggling, tracking, picking a lock, spotting a trap, sneaking, calming a horse,
the town's work) as ability checks d20 + mod (+ proficiency if trained) vs a DC; spells as checks/saves;
initiative; advantage/disadvantage where it fits; nat 20 / nat 1. Use the character's real stats (roster.mod,
roster.prof, save_bonus). Big rolls can show in the Chronicle ("BigAxe rolls a 20!").

LORE RULE: before adding monsters, bosses, classes, species, spells or NPC types, read the original game
(read only) — its bestiary, classes, races and lore files — and use what it already has first. Anything new
must fit its world and be named in its voice. Never state a dungeon floor count.
THE ORIGINAL lives at C:\Users\morta\OneDrive\MortalScorpion\OneDrive\Public\Documents\trial-and-error
(NOT C:\Users\morta\OneDrive\Public, which is an empty stub). Its spells: player.gd fire (38 dmg, 24 m/s,
orange) + frost (24 dmg, 32 m/s, blue), cast from +1.1 m, 1 m ahead; NOTES.md LORE BIBLE: scar misfire rule.
ASSETS: free CC0 only (Quaternius, KayKit, Kenney), downloaded into assets/<kind>/ with a LICENSE note.
Note: Quaternius "Bestiary" packs are NOT CC0 (QAL licence) - skip them.

## DESKTOP (town, people, magic) — files: town.gd, townsfolk.gd, town_nav.gd, spells.gd, raids.gd, daylight.gd, sfx.gd
- [x] D1. Phasing through buildings, for good: find every way people still walk through houses (routes
      that skip the navmesh, spawn/exit inside footprints, heroes' own movement, raiders, settlers, the
      town band). Every walker uses the navmesh; doors on the street side; local avoidance between people.
      tools/_townwalk.gd must report in_solid under 0.2% and a render must show it.
      DONE cycle 58: in_solid 0/6999 (was 64/7194 = 0.89%), raiders+defenders 0/4911, doors 67/67 reachable; renders/cycles/20261111_d1.
- [x] D2. Spells aimed at the sky: bolts fly up at the ceiling/sky and still hit (the "4th of July").
      Fix the aim (source at the caster's hands, target the foe's chest, flat arc), give each spell a
      readable travel + impact. Then NEW spells from the lore for the caster classes (heal over time, ward,
      chain bolt, fire burst, frost slow, smite) wired into delve and raid combat. Render a fight and look.
      DONE cycle 59: cause = health bars counted in Monster._height(), so bar and bolt aim climbed every frame;
      HealthBar3D holds its height, Spells aims hands->chest (cap 2.4 m), flat arc; chain/fire/frost/smite/renew
      + ward in raid combat (mage/sage/cleric cast at 8 m). _d2_spells D2_SPELLS OK; renders/cycles/20261111_d2.
      FOR THE LAPTOP: monster.gd _local_bounds() should skip HealthBar3D; delve.gd casters can call the new
      kinds: Spells.cast(kind, caster, target_body, in_scar, more_bodies) + Spells.flight() for the landing.
      LAPTOP HALF DONE (Cycle 63): bars skip in Monster bounds; delve casters use the books + menders; D2_DELVE OK.
- [x] D3. Buildings that level up: each town level/tier visibly changes Bellmire - plots fill in, houses
      upgrade (bigger/stone storeys, signs, gardens), new buildings unlock (guild hall, market hall,
      stables, bathhouse, mage tower, keep walls in stone...). Render levels 1, 3, 5, 7 side by side.
      DONE cycle 64: scripts/growth.gd - 56 house plots fill 23/31/39/45/51/56 over the lore's 6 levels (staked
      lots till then); gardens/signs+lamps/stone plinth+chimney/+1 storey/pennants; palisade -> stone wall at 4;
      Market Hall 3, Town Stables 4, Delvers' Guild + Bathhouse 5, Mage Tower 6. D3_TEST OK; renders/cycles/20261111_d3
      (the lore has 6 levels, not 7: rendered 1, 3, 5, 6).
- [x] D4. More guards and the cavalry: more watch with patrol routes, gate guards, tower archers; mounted
      town guards (horses + riders, TOWN GUARDS ONLY) patrolling the roads and riding out at raids.
      Horses: CC0 (Quaternius animals) or a simple rig. Stables building from D3.
      DONE cycle 65: all 8 gate posts manned, 2 crossbowmen per watchtower who shoot raiders (bolts fly, d20 on
      landing), watch 12/14/16 walkers on wall/market/bridge beats by level ("sworn into the watch"); scripts/
      cavalry.gd - Knight on the Quaternius CC0 horse, 2/3/4 riders at levels 4/5/6 ride a gate loop from the
      Town Stables, ride out at raids (hp 80). D4_TEST OK; renders/cycles/20261111_d4.
- [x] D5. More animals: horses in paddocks, cows, sheep, pigs, chickens, dogs, cats, birds over the
      fields, ducks; herded and penned, never on rooftops.
      DONE cycle 66: hens (19, hand-built, peck) in a fenced run by each farmhouse, a sheepdog walking each flock's
      fence, 5 horses + a foal in the paddock, 8 cats on the streets (they nap), crows over 5 fields; animals never
      pick a spot or path through a building (solid_at) and stop at stalls. D5_TEST OK (0 in_solid / 0 high / 0 out
      of pen in 22200 samples); renders/cycles/20261111_d5.
- [x] D6. Unique NPCs: named characters with jobs and daily routines from the lore (the chief, the smith,
      the healer, the innkeeper, the priest, a bard, a town crier who reads the Chronicle aloud, merchants
      with carts, children playing, beggars, a drunk at night). Each with a distinct look and a line in
      the Chronicle now and then.
      DONE cycle 69: scripts/notables.gd - 12 named folk (lore roster's chief/smith/healer/innkeeper promoted, not
      doubled; + priest, crier, bard, pedlar with cart, two children, beggar, drunk), names from the lore's FIRST x
      LAST, title tag up close, own look, hour-slot days in their own quarter, Chronicle lines, the crier shouts the
      latest Chronicle news. D6_TEST OK (86% of slots reached, drunk out 0/134 by day 96/96 at night, 0 in_solid);
      renders/cycles/20261111_d6.
- [x] D6b. Nav snap bug: town._snap / TownNav.closest() returns (0,0,0) for a while after start (navmesh not
      synced yet). Wait for the map's first sync (NavigationServer3D.map_get_iteration_id > 0 or map_changed) before
      snapping; until then fall back to the raw position, never the origin. Re-check D4 watch patrol routes and
      anyone stacked on the square at start. Test: snap right after start never returns 0,0,0; render the square.
      DONE cycle 73: iteration id > 0 came ~40 frames before the region was in the map; TownNav.synced() waits for
      the region + a vertex probe, _snap falls back to keep_walkable. Also: traders' market spot kept the old plot's
      inside point (a 30-47 m "door leg" through houses) and a door leg left after stuck waypoints now re-routes.
      D6B_TEST OK (0 of 600 snaps at the origin, 90 beats clean); _townwalk in_solid 0/7923 and 0/8317; renders/cycles/20261112_d6b.
- [x] D7. (ALSO: a 1.5-1.9 s hitch about once a minute, present since before L1 - find it with a frame-time log; suspect building a dungeon floor in one frame -> build it over several frames or ahead of time) Population cap + far-away LOD so long streams keep 100+ FPS (soak FPS fell 150 -> 82 at 211 people).
      DONE cycle 76: LOD - walkers past 60 m from the camera step + animate every 2nd physics tick, past 120 m every
      4th (summed time, same pace: 2.52 vs 2.52 m/s); heroes, riders and raid fights always full. Street cap 200:
      settlers past it still settle (souls, level, tax) but keep indoors; a burial brings one out. Windowed, 217
      people: 98.8 -> 126.0 FPS (+28%); 43% fewer walker steps. D7_TEST OK; renders/cycles/20261112_d7.
      THE HITCH, found (tools/_d7_hitch.gd): every new dungeon floor is built in ONE frame - DungeonHD.build takes
      580-820 ms, of it FloorGen.build 450-770 ms (964-1684 nodes); 41 hitches of 350-810 ms in 6 min at 4x, each on
      a floor change of the viewers' or the band's delve. FOR THE LAPTOP (delve.gd / dungeon_hd.gd / floorgen.gd are
      yours): build the next floor ahead while the party fights (FloorGen.build on a DungeonHD that is not yet in the
      tree, on WorkerThreadPool - load() is thread-safe - then add_child on descend), or slice it over frames.
      Also fixed: a freed guard / notable stopped _show_garrison and the whole Notables pass every tick (2583 errors).
- [x] D9. Roll audit (town side): townsfolk.gd, raids.gd, spells.gd, town.gd - every outcome that is a flat chance or fixed number becomes a d20 check / attack / save with real stats (raids, guards, cavalry, NPC work, fishing on the docks). List what changed.
      DONE cycle 78: scripts/dice.gd (Dice); raids: initiative, blows = weapon dice + mod (heroes' own dice), spell attacks +
      fire burst DEX save vs 8+to-hit, mending dice, CON save for every defender, torch + rebuild checks; crossbows 1d10+3;
      work beats d20+2 vs DC 10 (mean kept 1.0); fishing hook = DEX check (dock +5, heroes DEX + prof for ranger/druid).
      Kept: raid timing/size/source (world events), townsfolk idle gestures (cosmetic), spells.gd (no rolls; the surface
      scar rule is canon). D9_TEST OK; renders/cycles/20261112_d9. Full list in PROGRESS cycle 78.
- [x] D12. Expand the map: the valley beyond the walls - outlying hamlets/farmsteads, a forest with a woodcutters'
      camp, a river ford and mill, old ruins (lore), roads linking them, the scar road; travellers and carts on
      the roads; the director's tour includes them. Navmesh + LOD keep FPS.
      DONE cycle 79: scripts/valley.gd - Coalfoot Steading (over the river) + Bramble End (east road), 3 cottages, a well,
      folk each; the Ashwood (150 trees) with a woodcutters' camp; the ford (gravel bar in height_at, gap in the river's
      nav band) + the Ford Mill; the Old Footing ruins off the Delvers' Road; 10 dirt roads; 8 trips of travellers/carts;
      5 director tour stops. FOUND: map_get_path stops at 4096 polygons (mesh has ~25000) - long routes came back cut
      30-50 m short; TownNav.path now queries with room. D12_TEST OK; renders/cycles/20261112_d12.
- [x] D13. MOVED to L20 (laptop owns scripts/rts_camera.gd - every recent commit to it is the laptop's).
- [x] D14. Stuck walkers against props (supervisor, Nov 11): _townwalk reports stuck_on_route=4 steady
      (traders Petra Bramble, Maela of the Ford, farmer Maela Coalfoot) - pinned on a prop a few cm off
      their route, navoff 0.17-0.66, push (0,0,0). Nobody is inside a building (in_solid 0 of 8394), so
      this is cosmetic, but they stand still all stream. Give the push-out rule a prop case. Fold into D7
      if it is the same code path.
      DONE cycle 80 (townsfolk.gd): the push-out handed the foot back each frame so the "feet moved" test never
      fired; now a prop push-out slides round it, "no nearer in 2.5 s" re-routes, and a walker wedged in a pocket
      off the navmesh (the adventurers' fenced yard: fence + benches + stools) floods out to walkable ground.
      tools/_d14_test.gd: pinned 25 -> 0, stuck per sample max 4 -> 1 (120 s). D14_TEST OK; renders/cycles/20261112_d14.
- [x] D8. Soak 30 min with everything on; fix what breaks.
      DONE cycle 81: 30 min windowed, director on, 4x, 6 fake viewers: FPS avg 139.2 (min 29 = the floor-build hitch, laptop),
      memory flat 552-585 MB, nodes ~20k, 22 days, 13 raids. Broke + fixed: chain-bolt hops landing after their floor was
      freed (2 SCRIPT ERRORs) and 9 "Lambda capture freed" (timers holding freed nodes - spells/raids/town/notables/townsfolk);
      a raid ate a hero's errand (arrival fired mid-road); defenders whose post a prop blocks walked on the spot forever.
      D8_TEST OK; 9-min re-soak 0 script errors, 0 lambda errors; renders/cycles/20261112_d8.

- [x] T1. TWITCH PHASE 2 - DESKTOP OWNS THIS (Mr. E, Nov 11 23:18). All credentials are already
      authorized and proven live: see the gitignored local/twitch.cfg for the client id, both user ids
      and the file names. Tokens are in user://twitch_token.json (broadcaster) and
      user://twitch_bot_token.json (bot bellmirebro, modded on the channel) on THIS machine - that is
      why the desktop builds it. Build it in a NEW file, scripts/twitch_eventsub.gd:
        - EventSub WebSocket: channel.cheer (bits:read), channel.subscribe / subscription.message /
          subscription.gift (channel:read:subscriptions), channel.follow VERSION 2
          (moderator:read:followers), channel.channel_points_custom_reward_redemption.add
          (channel:read:redemptions) -> town.spotlight(uid, lane bits|subs|points, seconds, reason).
        - REFRESH BOTH TOKENS ON A TIMER. They expire in about 4 hours. This is the most likely bug in
          the whole item and it only shows up hours in, on a 24/7 run, when nobody is watching.
        - Bellmire creates its OWN channel point rewards with its own client id at startup, and matches
          redemptions BY REWARD ID, never by title. The six rewards already on the channel belong to
          Mr. E's other app, fightoverlay - ignore them completely. Reward titles must avoid every
          fightoverlay keyword (boss, monster, spawn, raid, mob, goblin, horde, loot, drop, chest,
          treasure, invade, titan). Start with "Spotlight my hero".
        - Event ownership: bits and subs -> Bellmire spotlight lanes; follows -> a Chronicle line only,
          no spotlight (fightoverlay used to own follows and has turned its follower monster off).
      NEVER EDIT chatcmd.gd - it is laptop-owned. The chat-reply half is split by contract: the laptop
      adds  signal twitch_reply(user_login: String, text: String)  to chatcmd.gd, emitting the plain
      answer with no @name prefix and no rate limiting. THIS file connects to that signal and owns the
      queue, the rate limiting, the @name prefix and the Send Chat Message API call as bellmirebro
      (broadcaster_id 138821183, sender_id 1609188025). Do not change that signature alone.
      Test without a live stream: the test-only !testbits <n> / !testsub / !testpoints already exist
      from L17. Prove the refresh path by forcing an expiry, not by waiting.
      DONE cycle 82: scripts/twitch_eventsub.gd (TwitchEventSub, started by town.gd in play only) - EventSub socket, 6/6 subs
      live (cheer, subscribe, sub.message, sub.gift, follow v2, redemption.add); both tokens refreshed 15 min early + hourly
      validate + refresh on a stale-token 401, new pair saved .tmp -> read back -> rename; bits 15/20/30 s, sub/resub/gifter
      30 s, follow = Chronicle only, rewards matched by id only (fightoverlay's ignored), refund when no hero; chat queue
      (1.6 s gap, @name, 480 chars, 30 s repeat drop) waits on chatcmd's twitch_reply. T1_TEST OK (18/18 offline); T1_LIVE OK
      (forced expiry -> both refreshed, saved, validated, socket stayed up). NOT YET: (a) the broadcaster token lacks
      channel:manage:redemptions, so Bellmire can not make its "Spotlight my hero" reward (401) - Mr. E must re-authorize
      with that scope; (b) town.spotlight is L17 (laptop) - until then events print SPOTLIGHT + emit spotlight_wanted;
      (c) twitch_reply is not in chatcmd.gd yet (laptop) - connected automatically once it is; (d) !testbits etc. do not
      exist (L17 open) - tests feed recorded EventSub frames instead. Chat sending was not tried live (nothing posted).

- [x] D15. (DONE Nov 12 04:16: 35-min soak / 87 valley days / 228 people / 51 raids - 0 script/freed-node errors; audio pool bounded (16/16 peak = graceful voice-steal), streams cached 131 plateaued; memory rise tracks town growth not audio; GAP held (busiest mana_charge 3.93/s vs ~8.3/s); FPS population-bound not audio. Follow-up D22: bump sfx pool 16->24 for peak headroom.) SOUND SOAK (supervisor, Nov 12). Now that S1+S2 wired the full RPG sound library, run a
      30-45 min soak with sound ON and confirm it is safe for a 24/7 stream: (a) no audio-related
      SCRIPT ERROR and no 'freed node'/lambda errors over the whole run; (b) the AudioStreamPlayer3D
      pool in sfx.gd is not exhausted or growing without bound (log pool size + active players each
      minute); (c) memory does not climb from audio streams (compare mem_mb first third vs last third,
      as D8 did); (d) FPS holds as it did in the silent D8 soak (sound must not cost meaningful frame
      time); (e) the GAP throttles hold under a busy town+raid so no kind machine-guns. Write the
      findings into PROGRESS; if anything leaks or errors, fix it before ticking. Reuse tools/_soak.gd
      with audio enabled. Commit + push only on a clean run.

## LAPTOP (dungeon, combat content, heroes) — files: bestiary.gd, monster.gd, floorgen.gd, dungeon_hd.gd, dungeon_parts.gd, gear.gd, roster.gd, chatcmd.gd, delve.gd, data/*
- [x] L1. More monsters: new CC0 creature models (KayKit Skeletons/Halloween, Quaternius CC0 monster packs),
      each with stats, behaviour and a home biome/theme from the lore's bestiary; new strains.
      DONE (Cycle 58): 6 creatures from owned CC0 bodies, ways in a fight, home themes, 2 strains; L1_TEST OK.
- [x] L2. More bosses: a set of floor lords and rare uniques (from the lore), each with a mechanic
      (summons, enrage, area attack), a name card and the boss bar; never two of the same in a row.
      DONE (Cycle 59): a mechanic for each of the eight lords, five rare uniques (one from the memorial); L2_TEST OK.
- [x] L3. More weapons and armour: more tiers and kinds (axes, spears, maces, bows, staves, shields,
      helms, chest, boots) using KayKit/Quaternius CC0 meshes; visible on the hero; priced in the shops;
      !forge / !armoury pick from them; drops on deep floors.
      DONE (Cycle 60): 10 weapon kinds x 5 tiers, worn armour, found-only tier 5, !forge <kind>, deep finds; L3_TEST OK.
- [x] L4. More classes: from the lore first (it has knight, mage, ranger, barbarian, cleric, rogue, sage,
      duelist); add more (e.g. paladin, necromancer, monk, druid, warlock, bard) with 5e-style saves,
      a weapon, a spell or ability, and !enlist support.
      DONE (Cycle 61): paladin, necromancer, monk, druid, warlock, bard - saves, weapon kind, ability, cloak; L4_TEST OK.
- [x] L5. Character species: !enlist <class> <species> (human, elf, dwarf, halfling, orc, ... from the lore)
      with stat bonuses and a visible look (KayKit/Quaternius CC0 bodies, scale, skin tint).
      DONE (Cycle 62): human, elf, dwarf, halfling, orc + the scarkin; bonuses, traits, proportions, skin, parts; L5_TEST OK.
- [x] L6. More character models for heroes and townsfolk (KayKit Adventurers 2.0 etc., CC0).
- [x] L8. (Mr. E's decision, Nov 11) Wild magic below: every spell in the dungeon is a check against the scar - d20 + casting mod (INT mage/sage/necromancer, WIS cleric/druid/monk, CHA warlock/bard/paladin) + proficiency vs DC 10 + floor/2 (cap 20); fail = misfire as on the scar's surface (Spells.cast in_scar=true); nat 1 always, nat 20 never. Monsters unaffected. Test the misfire rates (strong vs weak caster, shallow vs deep).
- [x] L10. (DONE Nov 11, be7c9a9: idle no longer overrides walk/attack; MON_ANIMS OK; 0 monsters in props) (URGENT, do before L9 - Mr. E saw it live) Monsters and bosses have NO animations: they glide/"fly"
      along the ground, never swing, and get stuck in walls and props. 1) Write tools/_mon_anims.gd: for EVERY
      bestiary def (incl. lords, uniques, L1 creatures) spawn it and print its model, whether an AnimationPlayer
      was found, the animation list, and which of def.anims (idle/walk/run/attack/cast/hit/die/rise) actually
      exist - any missing name means monster._play() silently does nothing. 2) Fix each: correct the names, or
      attach the shared rig library (KayKit Skeletons ship animations separately - Rig_Medium general/movement/
      combat; the UAL path) so every humanoid has idle, walk, attack, hit, death; beasts get what their pack has.
      3) Monster movement uses the same obstacle push-out/slide + never-off-floor guard the heroes use (delve.gd
      _step/_go), so no monster walks into walls or props. 4) Render a fight with 3+ kinds and a lord mid-swing;
      LOOK. Test: every def reports idle+walk+attack present; _offfloor counts monsters too (0 in props).
- [x] L9. Roll audit (dungeon/hero side): delve.gd, monster.gd, roster.gd, chatcmd.gd, gear.gd - attacks, damage dice, saves, traps (Perception/DEX save), loot (Investigation), initiative, death saves, shop haggling (CHA check) all as d20 rolls with real stats; nat 20/nat 1; big rolls in the Chronicle.
- [x] L7. Soak the delve 30 min with 6 fake viewers using the new classes/species/gear; fix what breaks.

## LAPTOP list 3 (Mr. E, Nov 11 evening) - UI + content. The laptop now owns the UI files too:
## rts_camera.gd, feed_hud.gd, leaderboard_panel.gd, party_frames.gd, boss_bar.gd, auto_director.gd, health_bar_3d.gd, new UI files.
- [x] L11. Traps that visibly work (Mr. E: "they don't show functioning or doing damage"): every trap kind
      (pressure plate, spikes, darts, blades, pits...) has a trigger animation + sound, a DEX save (or Perception
      to spot first) rolled with real stats, damage dice with the number floating up, a Chronicle line
      ("BigAxe steps on a plate - darts! DEX 9 vs DC 13, 7 damage"), disarming by a rogue (Thieves' tools check).
      Render a trap going off; test that damage lands and saves roll.
      DONE (Cycle 69): 6 kinds armed until stepped on, trigger anim + sound, Perception/thieves' tools/DEX save, dice, floating numbers, Chronicle; L11_TEST OK.
- [x] L12. Potions with status effects, 5e style: healing tiers (2d4+2 ... 10d4+20), plus antidote, fire/frost
      resistance, haste, giant strength, invisibility, heroism, darkvision for unlit floors; and the bad states
      to cure/inflict: poisoned, burning, frozen/slowed, blinded, frightened. Status icons on party frames and
      over heads; durations; brewed at the apothecary (!brew <potion>), found below. Lore voice for names.
      DONE (Cycle 70): 12 brews (data/potions.json), 5 bad states with sources and cures, drinking below, !brew <potion>, tags; L12_TEST OK.
- [x] L13. More equipment + COSMETICS: more weapons/armour per tier (rings, amulets, cloaks, boots, gloves with
      small 5e bonuses), and cosmetic-only items - hats, hoods, capes, dyes (colour the armour), banners on
      the back, a pet that follows (from the CC0 animals), titles shown under the name. !wear <item>, !dye <colour>.
      Bought with gold now; later channel points (T1). Visible on the hero; render a lineup.
      DONE (Cycle 71): 10 accessories with 5e bonuses, 18 cosmetics (hats, banners, pets, titles), 10 dyes, !wear / !dye; L13_TEST OK.
- [x] L14. The command list in detail: one source of truth (data/commands.json): name, aliases, args, cost,
      cooldown, what it does, example. !help / !commands (short), !help <cmd> (detail). Friendly error replies
      ("!forge needs 120 gold - you have 40"). Write docs/COMMANDS.md from the same data (the hub/website uses it).
      DONE (Cycle 72): data/commands.json -> !help, !help <cmd>, aliases, typo nudges, "- you have N" replies, docs/COMMANDS.md; L14_TEST OK.
- [x] L15. STREAM READABILITY (Mr. E: will viewers be able to read it?): design for a 1080p stream watched on a
      phone. Minimum on-screen text ~28 px at 1080p for anything viewers must read; name tags, Chronicle, Guild
      Roll, party frames, boss bar, banners scaled up; high contrast + outline; a UI scale setting (F11 cycles
      100/125/150%). Test: render at 1920x1080, then downscale to 854x480 (what a phone sees) and LOOK - every
      name and Chronicle line must still be readable. Fix until it is.
      DONE (Cycle 73): UiTheme sizes for 1080p (Chronicle 28 px, roll 26, frames 28, boss bar 44/26), F11 100/125/150, names grow with distance; phone 854x480 frames read; L15_TEST OK.
- [x] L16. GUI/UI polish to an RTS/WoW standard: one theme for every panel (parchment + ink, the JestSayin teal
      as the accent), consistent fonts, icons, frames, spacing; the unit frame, party frames, guild roll,
      chronicle, boss bar, help, chat box all match. Nothing from the old game's interface.
      DONE (Cycle 74): one house theme in UiTheme (parchment, ink, teal titles and rules, inked bars, chips) on every panel; L16_TEST OK.
- [x] L19. More lore: from the reference + the Lore Bible PDF - more Chronicle lines, NPC barks, floor-origin
      text, item and potion flavour, boss intros, town-level announcements; all in the original's voice, never
      contradicting it, never a floor count.
- [x] L17. (moved from D10; laptop owns the UI) Spotlight split-screen (Mr. E, Nov 11): viewers who support the stream get a timed pane on their hero.
      FIXED LANES in a 2x2 grid, each with its own queue and colour-coded frame:
        top-left     = the director (always, the main view)
        top-right    = BITS / cheers lane (gold frame) - any cheer 15 s, 50+ bits 20 s, 100+ bits 30 s
        bottom-left  = SUBSCRIBERS lane (purple frame) - new sub / resub / gift 30 s, gift bomb: each gifter 30 s
        bottom-right = CHANNEL POINTS lane (teal frame) - 15 s; free !look 10 s when it is otherwise empty
      Only lanes with someone in them open: no spotlights = full-screen director; one lane busy = director +
      that pane side by side; more = the 2x2 (an empty lane shows the director's wide view of the town).
      Each pane: a SubViewport + Camera3D following that hero (into the scar too), half resolution, the
      viewer's name + class + "cheered 500 bits" / "subscribed" / "redeemed <reward>" across the top, a thin
      timer bar. API: town.spotlight(uid, lane, seconds, reason). Test with local commands (!look, and
      test-only !testbits <n> / !testsub / !testpoints) and a tool that fills all lanes and renders the grid.
      F10 hides pane labels. Watch FPS.
      FREE CHAT (no pane, the main view instead): the director's hero shots favour the most recently active
      chatters (ahead of random heroes, behind raids/lords/fights); a small "Now watching: <name> the <species>
      <class>" banner in the main view; their name glows above their hero for ~5 s after any command; free
      !look borrows the channel-points lane for 10 s only when it is empty.
      DONE (Cycle 76): lanes + queues, !look / !testbits / !testsub / !testpoints (local only), pair + 2x2, F10 with the UI, FPS 44 -> 40 with all three lanes; L17_TEST OK. For the desktop: add `func spotlight(uid, lane, secs, why): return Spotlight.spotlight(self, uid, lane, secs, why)` to town.gd.
- [x] L18. (moved from D11) Free chat in the main view (Mr. E, Nov 11): the director's hero shots favour the most recent chatters; a small "Now watching: <name> the <species> <class>" tag; a chatter's name glows ~5 s after a command; free !look uses the channel-points pane only when it is empty. No pane for free chat.
      DONE (Cycle 77): the freshest chatter (2 min) is the director's hero pick (36-50), "Now watching" chip, 5 s teal name glow, !look via the points lane; Chronicle entries capped at 2 lines; L18_TEST OK.
- [x] L20. Director camera clearance (supervisor, Nov 11; was D13). CORRECTION to the original note: the
      roof in renders/cycles/20261112_d6b/square_f460_east.png was NOT an auto-director shot - _d6b_shot.gd
      placed its own fixed camera 14 m up beside the square, so that framing is the test tool's, not the
      director's. The real gap (found by the laptop, Nov 11): the camera's edge-protection check only covers
      hero-follow shots and tests a single line, so tour and wide shots have no clearance check at all and
      roofs beside that line go unprotected. Fix it in the eye camera for every shot type, and prove it with
      real director shots - town wide, tour, hero follow, fight, raid - rendered and looked at, not with a
      fixed test camera. The L17 spotlight panes each get their own camera, so they must share this rule.
      DONE (Cycle 79): every shot tilts / swings round its subject until the near lower frame is clear of roofs, props, walls and towers (one rule, the panes share it); pull-in never closer than 6 m; real director shots of all six types 0-2% blocked (raw up to 100%); L20_TEST OK.
- [x] L21. THE INTERFACE over the spotlight panes (Mr. E, Nov 11). In the grid the HUD was laid out for one full-screen view:
      the boss card across all four seams, the Chronicle over the subs pane, the delvers panel in the director pane's
      corner, floating text everywhere, name tags in mush. THE RULE, in code: with more than one view up, no HUD
      element crosses a seam or sits over a pane it does not belong to - docked inside one pane, or in the chrome bar.
      Floating text clamped to its pane and off in quarter panes; name tags fixed in panes; full screen unchanged.
      Test that fails on the old build, then a 1080p render shrunk to 854x480 and looked at.
      DONE (Cycle 81): panes over the top 85%, the Chronicle + clock in a bottom chrome bar, boss card + party frames + unit frame docked in the pane showing them (scripts/hud_dock.gd), 3D text on render layers with a cull mask per pane, one name tag per lane pane; L21_TEST 32/32 (15 failed before).
      ALSO: !guild drops the "roll" alias (bare !roll is fightoverlay's dice, now silent here); L14_TEST OK.
- [x] L22. Panes near-identical when two spotlit heroes stand close: a different angle / zoom when subjects are within a few metres.
      DONE (Cycle 84): within 6 m of another pane's subject a lane takes its own quarter (90 / -90 / 180 deg from the director) and zoom, clearance tilts but never swings it; L22_TEST OK (views 84-177 deg apart).
- [x] L23. The director should cut away from a hero a lane already holds (laptop commit a6eb770 calls this L24).
      DONE (Cycle 85): lane-held heroes are skipped by every director pick, a fight or delve shot goes through a delver no lane holds, a held shot is cut within 1 s; L24_TEST OK (5 of 6 failed before).

- [x] L24. De-flake tools/_l20_test.gd (supervisor, Nov 12). On the merge run it failed with (laptop commit d3669e2 calls this L23)
      "the director never cut to fight" and "all six shot types were seen" (saw tour_market, tour_scar,
      tour_valley, hero, raid - no fight), then PASSED on an immediate re-run with no code change. It is
      waiting on the director to happen to cut to a fight inside the test window. Make the test drive the
      director deterministically - force a fight and force the cut - instead of waiting for one. A test
      that fails at random teaches everyone to ignore it, which is worse than no test.
      DONE (Cycle 83): a lord floor + the director deciding at once when the story is live (its own _best / _cut); timing samples best of 3; L20_TEST OK x3 in a row.

- [x] S1. SOUND WIRING - DESKTOP (town side). The RPG sound library is already on main (commit 00cf0ef):
      86 ids registered as Sfx kinds, played with Sfx.at(id, pos) (3D, in the world) or Sfx.play(id)
      (flat). Do NOT edit sfx.gd except to add a GAP throttle for a kind that fires often. Wire the
      kinds that belong to the town, in the desktop-owned files only:
        - townsfolk.gd: villagers and named NPCs give an occasional gendered voice - male_/female_grunt,
          _effort, _laugh (pick by the NPC's sex). Sample it, do not sound every tick - it should feel
          alive, not a crowd grunting. The crier can use male_/female_attack_yell for a shout.
        - spells.gd: town-side casts -> fireball (magic fire), ice_shard, lightning (zap), heal, buff,
          curse, shield, summon, mana_charge. Play at the caster's position.
        - raids.gd: raiders arriving -> orc_roar / troll_roar / goblin_screech (by raider kind), a horn
          already plays; combat hits during the raid -> sword_clash / hit_impact at the fight.
        - town.gd / daylight.gd animals + time of day: dog_bark, cat_meow, horse_neigh/whinny, boar_grunt
          from the pens; bird_chirp / crow_caw by day, owl_hoot + cricket_chirp at night, kept quiet and
          occasional under the ambience bus.
        - level_up / quest_complete when the town reaches a new level.
      Keep it tasteful: throttle, keep volumes under the existing buses, and don't let far events be loud
      (Sfx.at already attenuates by distance). Add a tools/_s1_test.gd that asserts each wired event calls
      Sfx with a kind that exists in SETS. Render/soak a minute and listen in your head via the play counts
      (Sfx.plays) - 0 SCRIPT ERROR, no kind played that isn't registered.
- [x] S2. SOUND WIRING - LAPTOP (dungeon + heroes + UI). Same library on main (00cf0ef), same API, same      rule: do not edit sfx.gd except to add a GAP. Pull main into the laptop branch first. Wire the
      laptop-owned files only:
        - monster.gd / bestiary.gd: each monster species gets a voice on spawn and on death - map
          goblin->goblin_screech/cackle, orc->orc_roar, troll->troll_roar, skeleton->skeleton_rattle,
          zombie->zombie_moan, ghost->ghost_wail, wraith->wraith_whisper, slime->slime_squish,
          spider->spider_skitter, bat->bat_screech, demon->demon_growl, dragon->dragon_roar (+ 
          dragon_fire_breath on its breath attack), minotaur->minotaur_bellow, giant->giant_footstep.
          A boss roars on arrival (ties in with the spotlight). Throttle so a room of monsters is not a
          wall of noise - sample, and favour the biggest/nearest.
        - delve.gd combat: sword_swing then sword_clash/hit_impact on a melee hit, dagger_stab for
          daggers, bow_draw -> arrow_shot for ranged, shield_bash/block on a block; a miss can whiff with
          sword_swing alone. Heroes' spells reuse fireball/ice_shard/lightning/heal/shield.
        - heroes' voices by sex: male_/female_hurt on taking a hit, _death on dying (the death music
          duck already fires), _effort/_grunt on a big swing. Sample, do not voice every blow.
        - dungeon ambience per floor: a quiet bed of bat_screech / spider_skitter / skeleton_rattle /
          ghost_wail, occasional, under the ambience bus.
        - chatcmd.gd / UI feedback: menu_select on a recognised command, error on a typo nudge,
          item_pickup / chest_open / coins_stack on buys and finds, potion_drink on !brew, inventory_open
          on !inventory, level_up when a hero levels. These are flat (Sfx.play), not positional.
      Add tools/_s2_test.gd asserting every wired event uses a registered kind; 0 SCRIPT ERROR; the
      existing _delve_test should still pass with sound calls in.
      DONE (Cycle 87, laptop): Bestiary.voice_of (34 creatures, every lord and unique voiced), queued creature voices (one a 0.9 s beat, biggest / nearest / a death first, same kind 3.5 s), a lord roars as it rises, breath on the breath; per-weapon swings + hit / clash / bow / block / shield_bash, spells, potions, finds; hero voices sampled (Roster.voice_of); a quiet bed below; chat / UI sounds; level_up. GAPs added in sfx.gd. S2_TEST OK x3.
- [x] S3. SOUND REVIEW + TUNING - LAPTOP (supervisor, Nov 12). S1 / S2 only proved the kinds exist; check the game
      SOUNDS right: no silent monster, every command audible, throttles hold under load, levels balanced under the
      buses, no pool exhaustion or freed-node errors. A test so a future monster or command cannot ship silent.
      DONE (Cycle 88): tools/_sound_review.gd (coverage headless; load + measured levels windowed). Fixed: spells below
      doubled (S1 + S2 both sounded them), !reroll / !respec paid silently, dragon roar +9.9 dB over the music,
      skeleton / spider voices -9.5, half the dungeon bed inaudible (-25), menu_select +4.6, potion_drink buried,
      a generic hit doubling every blow. Levels now -5.6 .. +1.9 dB of the music, bed -15 .. -18; SOUND_REVIEW OK 18/18.

## Twitch phase 2 (main chat, needs Mr. E's Client ID)
- [x] W1a. SNAPSHOT PUBLISHER - DESKTOP. Mr. E chose GitHub Pages for the page and Supabase for the
      data (Nov 12, free tier, project already created and the table already exists). Every 60 s the
      game upserts ONE row into the Supabase table public.snapshot: id=1, payload = a jsonb blob with the
      guild roll, the fallen, each hero's sheet/inventory/gear, town level and souls, and the command
      list from data/commands.json. One row, overwritten - the database never grows and nothing has to
      be cleaned up. Project URL https://paaukwaffaamazgrndbv.supabase.co . Writing needs the SERVICE
      ROLE key, which bypasses row-level security: it goes in user:// beside the Twitch tokens and NEVER
      in the repo - Mr. E copies it from the Supabase dashboard (Project Settings > API). Skip the
      publish quietly if the key is absent so the game still runs without it. Failures must never stall
      the sim: fire and forget on a thread, and never block a frame on the network.
      CONNECTIVITY IS ALREADY PROVEN (supervisor, Nov 12 01:05): the key is in
      user://supabase.json as {"url": ..., "service_key": ...}; a write with it succeeded, a read with
      the publishable key succeeded, and a write attempted with the publishable key was correctly
      refused by RLS. The table currently holds a test row - overwrite it.
      GOTCHA, do not rediscover this: Supabase REFUSES a secret key when the request looks like it came
      from a browser - "Forbidden use of secret API key in browser". PowerShell's default User-Agent
      triggers it; setting User-Agent: BellmireHD/1.0 fixed it instantly. If the publish ever returns
      403 with that message, set a non-browser User-Agent on the HTTPRequest rather than hunting the key.
      Upsert with POST to /rest/v1/snapshot?on_conflict=id and the header Prefer: resolution=merge-duplicates.
      DONE cycle 87: scripts/snapshot_pub.gd (SnapshotPublisher, started by town.gd in play only) - every 60 s (first at 20 s)
      one threaded HTTPRequest upserts id=1 {town, guild_roll (50), fallen (50), heroes = living sheets (stats, saves, AC/HP,
      weapon+dice, armour, potions/brews, oil, gold, worn, rank, title), commands}; no Twitch ids; one in flight at most;
      no key file = off. publish() 0.3-0.7 ms, build 0.4 ms (202 heroes 5 ms, 95 KB). W1A_TEST OK 17/17 (live upsert 200,
      read back with the publishable key, publishable-key write refused 401); W1A_TOWN OK (real town + real save, read only:
      level 3, 51 souls, 2 heroes, 6 fallen, 21 commands - that is the row in the table now).
      ADDED cycle 89: payload.chronicle - the last 50 town.feed lines, newest first, {t, s, at}; t by keyword (death/raid/loot/delve/
      town/lore/fight, unsure = town), at = when the publisher first saw it; control chars, BBCode, < > and 7+ digit runs stripped, 200 chars max.
      No existing key changed. W1A_TEST OK 23/23 (6 new checks).
- [x] W1b. THE VIEWER HUB PAGE - a static page, no build step, on GitHub Pages like fightoverlay.
      It fetches public.snapshot with the PUBLISHABLE key (safe to embed, read-only by policy):
        URL  https://paaukwaffaamazgrndbv.supabase.co/rest/v1/snapshot?select=payload,updated_at
        key  sb_publishable_q2Kn3weLLeYYXGAiow_4vw_3serNQlc   (apikey header + Authorization: Bearer)
      Shows hero sheets, inventory, gear, the guild roll, the fallen and the command list, with "as of
      <updated_at>" visible so a stale snapshot is obvious when the game is off. Readable on a phone
      first - most viewers will open it on one. Must work when the game has never run (empty table).
      Phase 2, later: polls that change the town, with Twitch login - that is why the data is in
      Supabase rather than in a file; a static host could not do it at all.
      DONE (Cycle 86, laptop): web/index.html - one static file, no build, no framework; phone first (390 px), two / three columns when wide. Heroes (find by name, tap for the sheet: stats + mods, weapon dice, to-hit, armour / AC, saves, pack, worn, record), the Guild Roll, the Fallen (killer, day, epitaph when there is one), town level / souls / day / treasury / growth, the command list. "Updated N minutes ago" always; past 5 min it says the town has gone quiet; empty table -> "has not reported in yet"; failed fetch (12 s timeout) -> a plain message + Try again, retried every minute. Not published - Pages is Mr. E's call. Shots: renders/cycles/20261112_w1b.
## Needs Mr. E (not for the runs)
- Twitch follows/subs/bits/channel points: needs a Twitch token from him.
- Firefly icons / title art: made by him in Adobe.


## ROUND 4 - Nov 12 polish + hub elevation (Mr. E, 03:47 CT). Expanded into phased programs 04:16.
## CHANGELOG 04:33: L25 was split into L25a-d (L25 = all four collectively); IDs are now FROZEN, PROGRESS cycles are per-machine prefixed (D/L/H). See docs/COORDINATION.md - the single source of truth for machines, paths, numbering, tests, merges, WIP.
## Priorities from Mr. E: people clip/stick, dungeon looks rough, animations weak, hub must be SSS+.
## Ownership unchanged. Each item: subject + DONE/test. Workers take the FIRST unchecked item IN THEIR OWN section.
## Full per-chat briefs with the long detail exist (desktop saved claude/desktop-program-d16-d23.md); these lines are the trackable checklist.

### DESKTOP (town/people/nav/animation) - town.gd, town_nav.gd, townsfolk.gd, hero_body.gd, rig.gd, raids.gd, cavalry.gd, animal.gd, spells.gd, daylight.gd, valley.gd, notables.gd, economy.gd, sfx.gd
# Phase A - movement & nav (stop walls/sticking) [D16]
- [x] D16a. LOCAL AVOIDANCE: hero_body/townsfolk/animal/cavalry follow _route with no dynamic avoidance - add NavigationAgent3D avoidance OR separation steering (push apart within ~0.6 m). DONE: 50-body gate-funnel = 0 sustained overlaps > 0.3 m. -> DONE Nov 12: town.crowd_push is now separation (soft ring + hard contact, per-body radius) + yield (sidestep to pass whoever is ahead; same-way walkers followed) for townsfolk/heroes/cavalry/watch pairs/animals. tools/_d16a_test.gd at the west gate: under-0.3 m pair-time 29.2 s -> 0, clip (<0.45 m) 62.5 -> 2.2 pair-s, min gap 0.02 -> 0.38 m, 0 sustained, 50/50 through (median 10.0 s, unchanged).
- [x] D16b. UNSTICK WATCHDOG: route active but displacement < 0.2 m over 2 s -> repath/nudge. DONE: _townwalk stuck_on_route == 0 over 120 s. -> DONE Nov 12: Townsfolk watchdog (2 s / 0.2 m): near-enough arrival, else re-path, else side-step (or brush out of a prop pocket), else drop the trip (heroes/caravans keep trying). _townwalk now 120 s: stuck_on_route 0 (total 0); tools/_d16b_test.gd 180 s: 10 pinned events / 4 people with it off -> 0 with it on.
- [x] D16c. DYNAMIC OBSTACLES: stalls/carts/benches not in the navmesh - register or steer round. DONE: town soak = 0 bodies through a stall or stuck on a prop. -> DONE Nov 12: moving wagons (carters, travellers, caravan, pedlar) steered round (crowd_push) + feet kept out (off_wagons, every frame before LOD) + legs re-routed round/beside them (wagon_way); parked wagons drawn up on open ground (wagon_park); mine/farm wagons + scar-glass now solid. tools/_d16c_test.gd 150 s town+raid: through-a-prop 26-33 -> 0, stuck_by_prop 0 (PASS).
- [x] D16d. DOORWAY/GATE/BRIDGE FUNNELING: crowds queue and pass instead of piling. DONE: funnel test passes at the real gate and bridge. -> DONE Nov 12: the pile was the pre-sync road-hex route (D16a's note) - every route asked before the navmesh is in the map went out through a gate and back (walked/straight 1.68-1.78) and never crossed the bridge (50/100); Townsfolk now marks such a route and re-walks it on the navmesh once synced. tools/_d16d_test.gd 100 walkers two-way, routed on the spawn frame: gate 98/100 median 27.4 s -> 100/100 15.4 s, walked/straight 1.02, 0 overlap in the arch; bridge 50/100 -> 100/100, 0 overlap; routed after sync both PASS. A queue+lane steering variant was tried and measured worse (slower, more jostle) - not kept.
# Phase B - animation overhaul (town) [D17]
- [x] D17a. NO T-POSE: rig.gd fallback clip when a model lacks the named anim (play Idle + log once). DONE: anim probe = 0 empty current_animation over a 60 s day+raid. -> DONE Nov 12: Rig.play falls back to the model's idle on a missing clip (logged once) and queues every one-shot back into the loop the body was in (death -> its held Death_*_Pose); *_Idle/*_Pose clips loop; stable horses idle. tools/_d17a_test.gd 60 s day+raid: visible bodies with an empty player 182 samples (bandit Death_A, smith/farmer PickUp, fisher Interact, crier Cheer) -> 0 of 23927 (PASS).
- [x] D17b. LOCOMOTION BLEND: speed-blend walk<->run, match playback to move speed, face heading - no gliding/moonwalk. DONE: walk probe, no foot-slide beyond threshold. -> DONE Nov 12: Rig.drive picks a gait from each body's measured speed (stand/walk/jog/run, hysteresis, 0.3 s crossfade) and plays it at speed / the clip's own ground speed (KayKit walk 0.8 m/s, jog 2.1, run 3.3 - tools/_d17b_clipspeed.gd); walkers face the way they actually move; Townsfolk.pace 0.62 -> 0.40 (2.6 m/s was a sprint for these legs; the mounted watch kept its speed). tools/_d17b_test.gd 60 s day+raid: skate median 1.80 -> 0.006 m/s, p90 2.50 -> 0.23, idle-glide 3600 -> 59 samples, moonwalk 0.09% (PASS).
- [x] D17c. STATE COVERAGE: job anims (smith/angler/farmer/vendor), sit/eat at night, attack/cast/hurt/death for guards/heroes/raiders, animal graze/walk/flee. DONE: town-day shot sheet, NPCs visibly work. -> DONE Nov 12: trades work in their own motions (JOB_ANIMS: smith hammer, farmer hoe/baskets, woodcutter/miner swing, stalls+shops serve; walkers work their yard out of doors half the time); seats (square benches x2, tavern stools+chairs) sat on - Sit_Chair_Down/Idle/StandUp, often of an evening; tavern-yard drink/bite (Use_Item; no seated-eat clip in KayKit); raid swings vary (4x1H, 3x2H), Hit_A/B + Block_Hit + parries, Death_A/B; beasts graze (neck bent by a SkeletonModifier3D - the CC0 farm pack has no eating clip) and bolt from a raider within 14 m. tools/_d17c_test.gd 130 s day+evening+raid: all 14 states seen, 0 empty clips (PASS); old: no land-work, no sitting, no flight, graze only hens. Sheet renders/cycles/20261112_d17c.
- [x] D17d. BLENDS/TRANSITIONS: proper blend times, no pops, death doesn't T-pose. DONE: no visible pops in a 60 s capture. -> DONE Nov 12: the real pops were corpses getting up (the gait drove a fallen body out of its held Death_*_Pose into Idle ~1 s after the fall - old render: a buried farmer back on her feet doing PickUp) and body-yaw snaps (steering sets rotation.y outright). Rig: a Death_* marks the player fallen, nothing but another death or Rig.revive (a KO'd hero coming round) moves it; Townsfolk eases turns at 540 deg/s (walkers keep face_fix). tools/_d17d_test.gd 60 s, 2 raids + 6-death fixture, 90 bodies/frame: risen 3 -> 0, turn snaps 165 -> 4, one-frame bone pops 0 -> 1 of 284k (clip changes already blend - D17a's 0.2 s default), shake 1 -> 0 (PASS). Sheet renders/cycles/20261112_d17d.
# Phase C - the map: town & valley [D18]
- [x] D18a. PROP/BUILDING SANITY: 0 floating/interpenetrating props, buildings on ground, roads connect, wall/gates/bridge coherent. DONE: sweep = 0 floating/clipping; shot sheet.
      DONE cycle D1: tools/_d18a_test.gd sweeps 1034 ground props (0 floating/sunk past tol, slope+surface+water+planter
      dressing classified) and 83 building footprints (oriented, 0 interpenetrating). D18A_TEST OK. No genuine placement
      bug found - every earlier flag was intended (wall lanterns, tower crossbowmen ~11.7m, table/rack dressing, flowers
      in raised planter boxes, dock props over the riverbed, scar-mouth crag on the mine slope, hillside cottages nestled
      at the _low seat, forest canopies). No game script changed. renders/cycles/20261112_d18a (gate, bridge, square,
      scar, docks, aerial, hillside farmstead) - wall/gates/bridge/roads coherent, buildings on ground, nothing floats.
- [x] D18b. DRESS THE VALLEY: fields, fences, crops, mill, docks, forest, paths. DONE: valley shot sheet reads lived-in.
      DONE cycle D2: valley.gd _dress_valley - each steading (Coalfoot, Bramble End) now has 2 fenced, ploughed,
      cropped fields (wheat/veg) with a scarecrow + a footpath to the gate, a picket kitchen garden, a hayrick and
      grazing stock (sheep/cattle); a plank fishing jetty over the ford's slow water; wildflower + tall-grass verges
      along the lanes and a copse between the roads. Built 4 fields / 1416 crop sprites / 133 fence posts / +5 beasts.
      D18B_TEST OK; parse 0 err, _offfloor 0/1036 (0 inprop), TWITCH_PARSE OK, _townwalk in_solid 0/18452 stuck 0,
      _delve_test (DELVE_OIL=1) 0 SCRIPT ERROR to floor 2. Shots renders/cycles/20261112_d18b (steadings, jetty, aerial).
- [ ] D18c. GROUND & MATERIALS: ground texture blending (grass/dirt/road/water), water shader. DONE: before/after; 0 material-null headless.
# Phase D - lighting, day/night, atmosphere [D19]
- [ ] D19a. daylight.gd DAY/NIGHT: sun angle+colour, dawn/dusk warmth, real night dark, lamps/braziers/windows as OmniLights at night. DONE: full-day timelapse shot sheet.
- [ ] D19b. ATMOSPHERE: fog/haze, clouds, optional rain, sky gradient + stars at night, soft god-rays. DONE: shots across time/weather; FPS holds.
# Phase E - life & simulation depth [D20]
- [ ] D20a. RICHER ROUTINES (notables/townsfolk): work->market->tavern->home by hour, right anim per activity. DONE: town soak shows routines.
- [ ] D20b. CROWD REACTIONS: raid sends civilians fleeing/indoors; market bustle by hour; festival gathers. DONE: raid in a soak clears the streets.
- [ ] D20c. ANIMALS: herds graze/drift, dogs follow, birds flock. DONE: animal-behaviour probe in a soak.
# Phase F - magic & combat feel (town) [D21]
- [ ] D21a. spells.gd VFX: bolts/heals/buffs with real particles/trails/impact; mages/clerics cast visibly. DONE: raid soak shows spell VFX.
- [ ] D21b. RAID COMBAT FEEL: hit reactions, impact FX, deaths that read, guard formations, a cavalry charge that lands. DONE: raid soak, FPS holds.
# Phase G - audio polish (owns sfx.gd) [D22]
- [ ] D22a. MIX & SPATIALISATION: layered ambience (market/smith/river/birds), footsteps, combat/spell sounds, GAP-throttled. Also bump the 3D pool 16->24 (D15 peaked 16/16). DONE: sound review + short audio soak, GAP holds, 0 audio errors.
- [ ] D22b. MUSIC MOODS: smooth day/night/raid transitions, victory/defeat sting; keep 24/7-safe (D15). DONE: transition review.
# Phase H - performance (stretch) [D23]
- [ ] D23. Hold 100+ FPS on a long busy stream: extend D7 LOD, cull far detail, kill the ~1.5 s floor-build hitch, cap particle emitters, cheap nav rebakes. DONE: 30-min soak fps_avg >= 120, no sustained dips.

### LAPTOP (dungeon/combat/content/UI) - floorgen.gd, dungeon_parts.gd, dungeon_hd.gd, bestiary.gd, monster.gd, gear.gd, roster.gd, chatcmd.gd, delve.gd, data/*, UI files (rts_camera, feed_hud, leaderboard_panel, party_frames, boss_bar, auto_director, health_bar_3d, spotlight)
# Phase A - dungeon geometry & nav [L25]
- [x] L25a. STAIR INTEGRITY: continuous treads, correct step vs G=4.0/floor height, landing both ends, registered walkable. DONE: stair-probe over 12 floors, 0 gaps, landings both ends.
- [x] L25b. COLLISION-AWARE PROPS: no prop-prop or prop-in-wall overlap, clearance from doorways/path; placement validator reseats/drops overlaps. DONE: overlap probe 12 floors = 0 > 0.2 m, 0 blocked doorways.
- [x] L25c. DUNGEON NAV: bake a NavigationRegion3D per floor (open cells minus obstacle circles + walls, like TownNav) OR cell-grid A*; route delvers on it + unstick watchdog. DONE: 10-floor descent = 0 stuck delvers, 0 in geometry.
      DONE (Cycle 89 + L-cycle 110, laptop): tools/_l25_test.gd OK 13/13 twice - 0 stuck delvers (was 104), 0 forced descents,
      watchdog 5 and 1 nudges / 10 floors (was 51). Nav = cell-grid BFS over clear cells + obstacle circles, reachable fight slots.
- [x] L25d. ROOM/CORRIDOR COHERENCE: no orphan rooms, all reachable, doorways align, tiles don't z-fight. DONE: connectivity check over 12 floors, shot sheet.
# Phase B - dungeon look: textures/materials/biome/lighting [L28]
- [x] L28a. MATERIALS: real albedo/rough/metal per theme+biome, normals where the kit has them, fix material-null. DONE: 0 material-null, before/after 3 themes.
      DONE (L-cycle 111): kit surface shader - per-swatch rough/metal + triplanar CC0 stone/wood detail + theme wetness; materials per floor 689 -> 44 (tinted biome); dungeon-side material-null 0. Shots renders/cycles/20261112_l28/a_*.
- [x] L28b. BIOME DISTINCTION (data/biomes.json ~14 worlds): colour grade, fog/haze, ambient particles, ground variants - each biome its own place. DONE: per-biome shot sheet, no two alike.
      DONE (L-cycle 112): per-floor Environment from data/biomes.json "looks" (ambient, depth+height fog, 1D-LUT grade, sat/contrast, glow) seen by the main camera + lanes; one capped mote emitter; ground patches. L28_ALIKE OK 14/14. Sheet renders/cycles/20261112_l28/all_sheet.png.
- [x] L28c. LIGHTING/ATMOSPHERE: per-floor key+fill, torches/braziers as OmniLights w/ embers, depth fog, boss-floor drama. DONE: shot sheet, FPS holds (cap emitters).
      DONE (L-cycle 113): look-driven key (1 shadowed spot) + fill, flickering torches/braziers, ONE shared ember emitter, boss lord light+ash+harder grade; emitters 2-5/floor (cap 12); FPS -1..-7% (all >=115); sheet renders/cycles/20261112_l28/c_sheet.png.
- [ ] L28d. DETAIL DECALS: cracks/moss/blood/scar-glass veins to break repetition. DONE: varied-floor shots, 0 new errors.
# Phase C - creatures: animation + roster [L26/L27]
- [ ] L26a. ANIM AUDIT across the WHOLE bestiary: every family map resolves to real clips, fallback when missing (no T-pose/glide); monster.gd states drive the right clip; attack timing lines up. DONE: MON_ANIMS = 0 static.
- [ ] L27a. NEW MONSTERS from owned CC0 packs (KayKit Skeletons/Halloween, Quaternius - NOT Bestiary/QAL): add to TYPES with height/anim map/depth/strain. DONE: appear at depth in a soak, animate, parse clean.
- [ ] L27b. STRAINS (data/strains.json): widen coverage + a clear visual tell each (glow/particle/scale). DONE: strain probe shows tells, stat mods apply.
# Phase D - bosses & encounters (canon from NOTES.md/bosses.json) [L29]
- [ ] L29a. LORD MECHANICS: each canon lord gets a real mechanic (adds/phase/hazard/enrage); boss_bar shows phase; per-phase trappings. DONE: boss harness 0 errors, a delve fights a lord with its mechanic.
- [ ] L29b. RARE UNIQUES (NOT new lords - modified variants, bosses.json lesser/greater/draw/rule): rare spawn, visible modifier, better loot. DONE: a unique rolls + drops in a soak.
- [ ] L29c. SET-PIECE ENCOUNTERS from lore (ambush/guarded hoard/mini-event) so a floor isn't just a room of monsters. DONE: set pieces appear + resolve, Chronicle logs them.
# Phase E - gear, cosmetics, loot [L30]
- [ ] L30a. GEAR EXPANSION (items.json accessories): more weapons/armour per tier, visible on handslot bones (rig EQUIP), real bonuses. DONE: heroes equip visibly in a soak, bonuses apply.
- [ ] L30b. COSMETICS & DYES (items.json): more cloaks/hats/rings/amulets/boots/gloves; !wear/!dye change the model live; channel-point cosmetics gated (needs T1/Mr. E). DONE: !wear + !dye change the model in a soak.
- [ ] L30c. LOOT TABLES by depth/biome/boss; boss uniques; Chronicle announces rare finds. DONE: loot scales in a 10-floor soak, a boss drops its unique.
# Phase F - dungeon-side UI / readability (stretch) [L31]
- [ ] L31. Dungeon-fight UI (party frames, boss bar, feed HUD): damage numbers, status-effect icons, "Now fighting: <lord>" banner, legible at 1080p. Keep the parchment+ink+teal theme. DONE: 1080p capture, HP/damage/statuses/phase readable.

### HUB (web/ only) - hub builder owns web/index.html, app.js, style.css, NOTES.md, docs/HUB_SECURITY.md. Keep the el()/textContent + ICON_SET + CSP model. Republish gated on supervisor review.
- [ ] H1. VISUAL ELEVATION to an SSS+ grimoire: ornate frames/borders, parchment texture, illuminated drop-cap heads, richer hero character-sheet cards, tier badges on boards, better animated d20, micro-anims (respect reduced-motion). Responsive: phone/desktop/overlay. DONE: before/after at 3 widths; security invariants + hostile-name test pass.
- [ ] H2. CHRONICLE on-site + filter tabs by type (combat/loot/boss/town/chat) + per-type icons + text filter + pause-on-hover (keep the on-stream strip in-game). DONE: filters work vs ?mock=chronicle, legible at 1080p.
- [ ] H3. HERO SHEETS deepened: stat block + mods, class/species crest, level/XP, HP, equipped gear w/ icon+tooltip, cosmetics/dyes, title+epitaph for the Fallen. Keep paging (HERO_PAGE 60). DONE: ?mock=crowd 200 fast, ?open=1 full sheet.
- [ ] H4. BOARDS/LEADERBOARD tiers (SSS/SS/S/A/B) styled, sort tabs, Guild Roll + Fallen, town-status strip (day/pop/treasury/raids). DONE: tiers + sorts render, status strip live.
- [ ] H5. TWITCH CHAT EMBED + clickable local d20. CAUTION: minimal CSP change for the embed, documented in HUB_SECURITY.md, flagged for supervisor review; page stays read-only. DONE: chat loads, d20 rolls, CSP documented, invariants intact.
- [ ] H6. TWITCH LOGIN scaffolding (device-code OAuth, public client id) so viewers see their own hero - the client id is NEEDS-MR.-E; wire against a placeholder. Still no viewer writes (read-only through Phase 2). DONE: flow wired/testable w/ placeholder, token step gated on Mr. E.
- [ ] H7. PERF/A11Y/POLISH (stretch): fast first paint, no layout shift, lazy-render the crowd, reduced-motion, contrast+focus, keep offline/stale honesty. DONE: fast on a phone, a11y pass, invariants intact.
# Phase 3 (NOT now - stays read-only until RLS designed): friends/party, a write-backed leaderboard, any viewer WRITE path.
